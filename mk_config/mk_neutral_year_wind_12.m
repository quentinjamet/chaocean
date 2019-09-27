% DESCRIPTION
%
% Compute the 'climatological winds' as a neutral year.
% The neutral year is considerd as the period Aug 2003 - July 2004, 
% with the exact day of looping being the 210.5 of the year 
% (which correspond to the 07/28-29, 
% see ./publis/note_bams/find_low_std_clim.m for definition of this period).
% The transition is smoothed with a 30 days centered linear transition 
% (15 days on each side, i.e. from day 195 to day 225).
%

clear all; close all;

ieee='b';
accu='real*4';

%-- directories --
dir_in = '/tank/chaocean/atmospheric_conditions_12/';

%-- dimensions --
nx = 1000;
ny = 900;
nt = 1460;

%-- transition parameters and mask --
it_trans = 185.25*4;		% time-record of transition
trans_width = 15*4;		% width if the transition between July 2004 to August 2003
%- define masks for 2004 -
tmp = zeros(1,1,nt);
tmp(1:it_trans-trans_width) = 1;
tmp(it_trans-trans_width+1:it_trans+trans_width-1) = ...
    1-1/(2*trans_width):-1/(2*trans_width):1/(2*trans_width);
msk_trans_2004 = repmat(tmp,[nx ny 1]);
clear tmp
%- define masks for 2003 -
tmp = zeros(1,1,nt);
tmp(it_trans+trans_width:nt) = 1;
tmp(it_trans-trans_width+1:it_trans+trans_width-1) = ...
       1/(2*trans_width):1/(2*trans_width):1-1/(2*trans_width);
msk_trans_2003 = repmat(tmp,[nx ny 1]);



vvar = {'u10','v10','t2','q2','radlw','precip','radsw'};
nVar = length(vvar);


%-- loop over variables --
wind_neutral_yr = zeros(nx,ny,nt);
for iVar = 1:nVar
  tmp_var = vvar{iVar};

  %- 2003 -
  fid = fopen([dir_in '2003/' tmp_var '_2003.box'],'r',ieee);
  tmp_2003 = fread(fid,accu);
  tmp_2003 = reshape(tmp_2003,[nx ny nt+2]);	% data have been extended
  tmp_2003 = tmp_2003(:,:,1:1460);		% remove extension
  fclose(fid);

  %- 2004 -
  fid = fopen([dir_in '2004/' tmp_var '_2004.box'],'r',ieee);
  tmp_2004 = fread(fid,accu);
  tmp_2004 = reshape(tmp_2004,[nx ny nt+2]);	% data have been extended
  tmp_2004 = tmp_2004(:,:,1:1460);		% remove extension
  fclose(fid);

  %-- make connection ... --
  wind_neutral_yr = tmp_2003.*msk_trans_2003 + tmp_2004.*msk_trans_2004;

  %-- save --
  fid = fopen([dir_in tmp_var '_neutral_yr.box'],'w',ieee);
  fwrite(fid,wind_neutral_yr,accu);
  fclose(fid);

end % for iVar

