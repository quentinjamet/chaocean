% DESCRIPTION: 
%
% Generate open boundary conditions for climatology and forced runs on the chaocean grid
%
% extracted fields are :
%	U_NORTH.box
%	V_NORTH.box
%	T_NORTH.box
%	S_NORTH.box
%	U_SOUTH.box
%	V_SOUTH.box
%	T_SOUTH.box
%	S_SOUTH.box
%

clear all; close all

addpath('/tank/chaocean/MITgcm/utils/matlab/')

%------------
% Directories
%------------

%- output dir -
dir_o = '/tank/chaocean/boundary_conditions_12/';

%- Boundary conditions data -
dir_obcs = '/tank/chaocean/boundary_data/';

%- grid parameters directory -
dirGrd = '/tank/chaocean/grid_chaO/gridMIT/';


%------------------
% Specific flags
%------------------

ieee='b';
accuracy='real*4';

flg_cut = 1;
flag_save = 1;
flag_bdy = 'GIB';	%'NORTH', 'SOUTH' of 'GIB'  depending on the boundary considered
Resol = 12;


%---------------------------
% generate the chaocean grid
%---------------------------
global xLon yLat mask_mit mask_topo x_cut ybc rC rF h2
mk_grid(Resol,0,flg_cut)	

[nLon,nLat] = size(xLon);

%-- load the land mask used by the MITgcm to field oceanic NaN points after interpolation --
hFacC = rdmds([dirGrd 'hFacC']);
mskLnd = cut_gulf_NaN(hFacC,-1,0);
mskLnd(mskLnd ~= 0) = 1;


%-- list of variables --
%var = {'T','S','U','V'};
var = {'vN','uE'};
nVar = length(var);
varName = {'votemper','vosaline','vozocrtx','vomecrty'};
%def_val = [20.0 30.0 0.0 0.0];	%used to replace NaN for [t,s,u,v]
def_val = [0.0 0.0];	%used to replace NaN for [t,s,u,v]



for iVar = 1:nVar

  disp(['Variable: ' var{iVar}])

  %-- load grid parameters from initial datas --
  zDepth = ncread([dir_obcs flag_bdy 'BDY-MJM88/1961/' flag_bdy ...
      'BDY-MJM88_y1961m01d05_gridT.nc'],'deptht');
  nr = length(zDepth);
  
 xLon_NEMO = ncread([dir_obcs flag_bdy 'BDY-MJM88/1961/' flag_bdy ...
   'BDY-MJM88_y1961m01d05_gridT.nc'],'nav_lon');
 yLat_NEMO = ncread([dir_obcs flag_bdy 'BDY-MJM88/1961/' flag_bdy ...
   'BDY-MJM88_y1961m01d05_gridT.nc'],'nav_lat');
 %- original NEMO velocities are at u,v-grd pts, East/North velocities are cell-centered -   
 if strcmp(var{iVar},'U') 
    disp('-- Load NEMO u-pts grid --')
    xLon_NEMO = ncread([dir_obcs flag_bdy 'BDY-MJM88/1961/' flag_bdy ...
      'BDY-MJM88_y1961m01d05_gridU.nc'],'nav_lon');
    yLat_NEMO = ncread([dir_obcs flag_bdy 'BDY-MJM88/1961/' flag_bdy ...
      'BDY-MJM88_y1961m01d05_gridU.nc'],'nav_lat');
  elseif strcmp(var{iVar},'V') 
    disp('-- Load NEMO v-pts grid --')
    xLon_NEMO = ncread([dir_obcs flag_bdy 'BDY-MJM88/1961/' flag_bdy ...
      'BDY-MJM88_y1961m01d05_gridV.nc'],'nav_lon');
    yLat_NEMO = ncread([dir_obcs flag_bdy 'BDY-MJM88/1961/' flag_bdy ...
      'BDY-MJM88_y1961m01d05_gridV.nc'],'nav_lat');
  end
  xLon_NEMO = double(xLon_NEMO);
  yLat_NEMO = double(yLat_NEMO);
  [nLon_NEMO,nLat_NEMO] = size(xLon_NEMO);




 
  %========================
  %	FULLY FORCED	
  %========================
  
  yYear = [1958:2012];
  nYr = length(yYear);

  for iiYr = 1:nYr

    fprintf('---- Year: %i -----\n',yYear(iiYr))

    %-- get file name --
    if strcmp(var{iVar},'T') | strcmp(var{iVar},'S')
      fileN = dir([dir_obcs flag_bdy 'BDY-MJM88/' num2str(yYear(iiYr)) '/*_gridT.nc']);
      nFile = length(fileN);
    elseif strcmp(var{iVar},'U')
      fileN = dir([dir_obcs flag_bdy 'BDY-MJM88/' num2str(yYear(iiYr)) '/*_gridU.nc']);
      nFile = length(fileN);
    elseif strcmp(var{iVar},'V')
      fileN = dir([dir_obcs flag_bdy 'BDY-MJM88/' num2str(yYear(iiYr)) '/*_gridV.nc']);
      nFile = length(fileN);
    end

    if strcmp(var{iVar},'uE') | strcmp(var{iVar},'vN')
      fid = fopen([dir_obcs flag_bdy 'BDY-MJM88/' num2str(yYear(iiYr)) '/' ...
          var{iVar} '_' flag_bdy 'BDY-MJM88_y' num2str(yYear(iiYr)) '.box'],'r',ieee);
      tmp1 = fread(fid,accuracy);
      [nFile] = numel(tmp1) / (nLon_NEMO*nLat_NEMO*nr);
      tmp1 = reshape(tmp1,[nLon_NEMO nLat_NEMO nr nFile]);
    end
    

    
    %-- Loop over file name --
    for iiFile = 1:nFile
      if strcmp(var{iVar},'uE') | strcmp(var{iVar},'vN')
        tmp = tmp1(:,:,:,iiFile);
      else
        tmp = ncread([dir_obcs flag_bdy 'BDY-MJM88/' num2str(yYear(iiYr)) '/' ...
            fileN(iiFile).name],varName{iVar});
      end

      if strcmp(var{iVar},'uE') | strcmp(var{iVar},'vN') 
        tmp(isnan(tmp)) = 0;
      end
      if strcmp(var{iVar},'U') | strcmp(var{iVar},'V') 
        tmp(isnan(tmp)) = 0;
      end
        
      %- interpolate onto the MITgcm grid 
      % 1D linear interpolation with the closest NEMO section for 'SOUTH' and 'GIB',
      % but 2D linear interpolation for 'NORTH' because of the curvilinear NEMO grid -

      switch flag_bdy
        case 'NORTH'
          jLat_bdy = nLat-1;         %Interpolate boundary conditions at
        case 'SOUTH'
          jLat_bdy = 2;
        case 'GIB' 
          iLon_bdy = 1073;	% (1074,670:673) -> on land ; (1073,670:673) -> on sea
          iLon_NEMO = 6;
      end

    if strcmp(flag_bdy,'GIB')
      %- 1D linear interpolation with the closest section -
      data_tmp = zeros(nLat,nr);
      for iiZ = 1:nr
        data_tmp(:,iiZ) = interp1(yLat_NEMO(iLon_NEMO,:),tmp(iLon_NEMO,:,iiZ),yLat(iLon_bdy,:));
      end %iiZ = 1:nr
 
    else		% 'NORTH', 'SOUTH' 
      data_tmp = zeros(nLon,nr);
      for iiZ = 1:nr
        if iiFile == 1 & iiZ == 1
          fprintf('Creating new interpolant\n')
          [t_mit,tri,wei] = my_griddata1(xLon_NEMO,yLat_NEMO,tmp(:,:,iiZ),...
              xLon(:,jLat_bdy),yLat(:,jLat_bdy),{'QJ'});
        end
        data_tmp(:,iiZ) = my_griddata2(xLon_NEMO,yLat_NEMO,tmp(:,:,iiZ),...
            xLon(:,jLat_bdy),yLat(:,jLat_bdy),tri,wei);
      end %iiZ = 1:nr
    end %if 'GIB'
        
    if strcmp(var{iVar},'T') | strcmp(var{iVar},'S')
      %-- resolve the problem of NaNs in the ocean --
      if Resol == 4 & strcmp(flag_bdy,'SOUTH')
        jLat_bdy = 2;
      end
      if strcmp(flag_bdy,'GIB')
        msktmp = squeeze(mskLnd(iLon_bdy,:,:));
        msktmp(yLat(iLon_bdy,:)<35,:) = 0;
        msktmp(yLat(iLon_bdy,:)>37,:) = 0;
      else
        msktmp = squeeze(mskLnd(:,jLat_bdy,:));
      end
      
      testNaN = 0;
      while testNaN <= 3
        for iiZ = 1:nr
          tmp = data_tmp(:,iiZ);
          tmp(msktmp(:,iiZ) == 0) = def_val(iVar);       % all these grid points are on land
          [ii] = find(isnan(tmp));
          if ~isempty(ii)
            for iii = 1:length(ii)
              if ii(iii) == 1
                data_tmp(ii(iii),iiZ) = data_tmp(ii(iii)+1,iiZ);
              elseif ii(iii) == nLon
                data_tmp(ii(iii),iiZ) = data_tmp(ii(iii)-1,iiZ);
              else
                data_tmp(ii(iii),iiZ) = nanmean([data_tmp(ii(iii)-1,iiZ) data_tmp(ii(iii)+1,iiZ)]);
              end
            end %iii
          end %if
        end %iiZ
        testNaN = testNaN+1;
      end
        
      %- repeate on the vertical for remaining NaN -
      tmp = data_tmp;
      tmp(msktmp == 0) = def_val(iVar);       % all these grid points are on land
      tmp = mean(tmp,2);
      ii = find(isnan(tmp));
      for iii = 1:length(ii)
        tmp = data_tmp(ii(iii),:);
        tmp(msktmp(ii(iii),:) == 0) = def_val(iVar);       % all these grid points are on land
        [kk] = find(isnan(tmp));
        data_tmp(ii(iii),kk) = data_tmp(ii(iii),kk(1)-1);
      end %ii


        
    end % if var{iVar}
        
      %-- set NaN to 'def_val' --
      data_tmp(isnan(data_tmp(:))) = def_val(iVar);
     
      %- reshape on the chaocean grid -
      if flg_cut & ~strcmp(flag_bdy,'GIB')
        data_tmp(1:nLon-x_cut,:) = data_tmp(x_cut+1:nLon,:);
        data_tmp = data_tmp(1:x_cut,:);
      end
    

      
        
      %- Save -
      fprintf('Variable: %s // boundary: %s // Year: %i // File: %i \n',...
          var{iVar},flag_bdy,yYear(iiYr),iiFile)
      if iiFile==1 
        fid = fopen([dir_o num2str(yYear(iiYr)) '/' var{iVar}  '_' flag_bdy '_' ...
            num2str(yYear(iiYr)) '.box'],'w',ieee);
      else
        fid = fopen([dir_o num2str(yYear(iiYr)) '/' var{iVar}  '_' flag_bdy '_' ...
            num2str(yYear(iiYr)) '.box'],'a',ieee);
      end %iiFile
      fwrite(fid,data_tmp,accuracy);
      fclose(fid);
        
    end %iiFile
    
  end %iiYr


end %iVar
