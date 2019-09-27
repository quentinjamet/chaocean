% DESCRIPTION
%
% Extend the forcing (atm & obcs) fluxes with 2 additional
% time records at the end of each file.
% The last (second last) additional time record
% corresponds to the last (first) time step of the preceding (following) year.
%
% (07/18/2017):
%       externForcingCycle has to be kept to 365 d (or whatever the cycle is).
%       the script get_periodic_interval.F is modified (hard coded for now)
%       to take into account the 2 extra time-records,
%       and to handle the time interpolation at the begin and at the end of
%       the external forcing cycle.


clear all; close all

flag_obcs = 1;
flag_cheap = 0;


ieee = 'b';
accu = 'real*4';
if strcmp(accu,'real*4')
  accu2 = 4;
else
  accu2 = 8;
end

[nx] = 1000;
[ny] = 900;
[nr] = 46;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%				OBCS						%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_obcs

dirIN = '/tank/chaocean/boundary_conditions_12/';

[nClim] = 73;

vvar = {'S_SOUTH_', 'T_SOUTH_', 'U_SOUTH_', 'V_SOUTH_',...
        'S_NORTH_', 'T_NORTH_', 'uE_NORTH_', 'vN_NORTH_',...
        'S_GIB_',   'T_GIB_',   'uE_GIB_',   'vN_GIB_'};
nVar = length(vvar);

for yYr = 1958:2012

  fprintf('-- OBCS Year %i --\n',yYr)

  for iVar = 1:nVar

    %-- get appropriate dimension and check --
    if iVar > 8 	% GIB bdy
      [nxynr] = ny*nr;
    else		% NORTH or SOUTH bdy
      [nxynr] = nx*nr;
    end
    %- current year -
    data = dir([dirIN num2str(yYr) '/' vvar{iVar} ...
        num2str(yYr) '_interp.box']);
    if data.bytes/accu2 ~= nxynr*nClim
      error('-- Dimensions mismatch --')
    end
    %- preceding year -
    if yYr ~= 1958
      data = dir([dirIN num2str(yYr-1) '/' vvar{iVar} ...
          num2str(yYr-1) '_interp.box']);
      if data.bytes/accu2 ~= nxynr*(nClim+2)	%precceding year has been extended
        error('-- Dimensions mismatch --')
      end
    end
    %- following year -
    if yYr ~= 2012
      data = dir([dirIN num2str(yYr+1) '/' vvar{iVar} ...
          num2str(yYr+1) '_interp.box']);
      if data.bytes/accu2 ~= nxynr*nClim
        error('-- Dimensions mismatch --')
      end
    end


    %-- load next year data --
    if yYr == 2012
      fid = fopen([dirIN num2str(yYr) '/' vvar{iVar} ...
         num2str(yYr) '_interp.box'],'r',ieee);
      tmp1 = fread(fid,accu);
      fclose(fid);
      %- repeat last time step -
      fid = fopen([dirIN num2str(yYr) '/' vvar{iVar} ...
         num2str(yYr) '_interp.box'],'a',ieee);
      fwrite(fid,tmp1(nxynr*(nClim-1)+1:nxynr*nClim),accu);
      fclose(fid);

    else
      %- loading -
      fid = fopen([dirIN num2str(yYr+1) '/' vvar{iVar} ...
          num2str(yYr+1) '_interp.box'],'r',ieee);
      tmp2 = fread(fid,[nxynr 1],accu);
      fclose(fid);
      %- write first time step of the following year at the end of the current year -
      fid = fopen([dirIN num2str(yYr) '/' vvar{iVar} ...
         num2str(yYr) '_interp.box'],'a',ieee);
      fwrite(fid,tmp2,accu);
      fclose(fid);

    end    %if yYr == 2012



    %-- load previous year data --
    if yYr == 1958
      fid = fopen([dirIN num2str(yYr) '/' vvar{iVar} ...
         num2str(yYr) '_interp.box'],'r',ieee);
      tmp1 = fread(fid,[nxynr 1],accu);
      fclose(fid);
      %- repeat first time step at the end -
      fid = fopen([dirIN num2str(yYr) '/' vvar{iVar} ...
         num2str(yYr) '_interp.box'],'a',ieee);
      fwrite(fid,tmp1,accu);
      fclose(fid);

    % !!! previous data have already been extended to nClim+2 !!! 
    else
      fid = fopen([dirIN num2str(yYr-1) '/' vvar{iVar} ...
          num2str(yYr-1) '_interp.box'],'r',ieee);
      tmp0 = fread(fid,accu);
      fclose(fid);
      %- repeat lats time step at the end -
      % using nClim for index discard the extended data of the previous year
      fid = fopen([dirIN num2str(yYr) '/' vvar{iVar} ...
         num2str(yYr) '_interp.box'],'a',ieee);
      fwrite(fid,tmp0(nxynr*(nClim-1)+1:nxynr*nClim),accu);
      fclose(fid);

    end  %if yYr == 1958


  end % for iVar
end % for yYr

end % if flag_obcs



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%				CHEAPAML					%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_cheap

dirIN = '/tank/chaocean/atmospheric_conditions_12/';

%vvar = {'q2_'  'radlw_' 'radsw_' 't2_'  'u10_'  'v10_'};
vvar = {'precip_'};	%prior 1979, precipitations are climatological

nVar = length(vvar);

[nxy] = nx*ny;
[nClim] = 1460;


for yYr = 1979:2012

  fprintf('-- Cheap Year %i --\n',yYr)

  for iVar = 1:nVar

    %-- check dimension --
    %- current year -
    data = dir([dirIN num2str(yYr) '/' vvar{iVar} ...
        num2str(yYr) '.box']);
    if data.bytes/accu2 ~= nxy*nClim
      error('-- Dimensions mismatch --')
    end
    %- preceding year -
%    if yYr ~= 1958
    if yYr ~= 1979
      data = dir([dirIN num2str(yYr-1) '/' vvar{iVar} ...
          num2str(yYr-1) '.box']);
      if data.bytes/accu2 ~= nxy*(nClim+2)	%preceeding year has been extended
        error('-- Dimensions mismatch --')
      end
    end
    %- following year -
    if yYr ~= 2012
      data = dir([dirIN num2str(yYr+1) '/' vvar{iVar} ...
          num2str(yYr+1) '.box']);
      if data.bytes/accu2 ~= nxy*nClim
        error('-- Dimensions mismatch --')
      end
    end


    %-- load next year data --
    if yYr == 2012
      fid = fopen([dirIN num2str(yYr) '/' vvar{iVar} ...
         num2str(yYr) '.box'],'r',ieee);
      tmp1 = fread(fid,accu);
      fclose(fid);
      %- repeat last time step -
      fid = fopen([dirIN num2str(yYr) '/' vvar{iVar} ...
         num2str(yYr) '.box'],'a',ieee);
      fwrite(fid,tmp1(nxy*(nClim-1)+1:nxy*nClim),accu);
      fclose(fid);

    else
      %- loading -
      fid = fopen([dirIN num2str(yYr+1) '/' vvar{iVar} ...
          num2str(yYr+1) '.box'],'r',ieee);
      tmp2 = fread(fid,[nxy 1],accu);
      fclose(fid);
      %- write first time record of the following year at the end of the current file -
      fid = fopen([dirIN num2str(yYr) '/' vvar{iVar} ...
         num2str(yYr) '.box'],'a',ieee);
      fwrite(fid,tmp2,accu);
      fclose(fid);

    end    %if yYr == 2012



    %-- load previous year data --
    if yYr == 1958
      fid = fopen([dirIN num2str(yYr) '/' vvar{iVar} ...
         num2str(yYr) '.box'],'r',ieee);
      tmp1 = fread(fid,[nxy 1],accu);
      fclose(fid);
      %- repeat first time step at the end -
      fid = fopen([dirIN num2str(yYr) '/' vvar{iVar} ...
         num2str(yYr) '.box'],'a',ieee);
      fwrite(fid,tmp1,accu);
      fclose(fid);

    % !!! previous data have already been extended to nClim+2 !!! 
    else
      if yYr == 1979	%precip for 1958-1978 are climatological 
        fid = fopen([dirIN '/' vvar{iVar} ...
            'climExtd.box'],'r',ieee);
      else
        fid = fopen([dirIN num2str(yYr-1) '/' vvar{iVar} ...
            num2str(yYr-1) '.box'],'r',ieee);
      end
      tmp0 = fread(fid,accu);
      fclose(fid);
      %- repeat lats time step at the end -
      % using nClim for index discard the extended data of the previous year
      fid = fopen([dirIN num2str(yYr) '/' vvar{iVar} ...
         num2str(yYr) '.box'],'a',ieee);
      fwrite(fid,tmp0(nxy*(nClim-1)+1:nxy*nClim),accu);
      fclose(fid);

    end  %if yYr == 1958


  end % for iVar
end % for iYr

end % if flag_cheap









