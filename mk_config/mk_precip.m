% DESCRIPTION
%
% Precipitations computed by cheapaml generate a important negative drift in salt, 
% but also make the model crash due to fast growing SSS anomalies
% Precipitations are made upon daily DFS5.2 rather than the monthly DFS4.4 data.
% Both DFS4.4 and DFS5.2 precipitations are climatologic
%
% To prepare precip for the chaocean runs, DFS5.2 precip needs to be:
%	1/ spatially interpolated on the chaocean grid
%	2/ smooth the transition over land
%	3/ time-interpolated to 6-hours field at 3am, 9am, 3pm and 9pm
%	4/ extended with 2 additional time records at the end for time interpolation
%	   during the computation (see mk_extended_flx.m). 
%	   Although precipitations are climatologic, 
%	   they need to be extended for consistency in the computation. 
% 
% step 3/ and 4/ are made outside of this script

clear all; close all


%------------------------
% Global parameters
%------------------------


ieee='b';
accu='real*4';

%-- Directories --

%- output dir -
%dir_o = '/tank/chaocean/trash_atmo_cond_12/precip/';
dir_o = '/tank/chaocean/qjamet/Config/Test_cheapAML0.25/data_in/atm_cd/';

%- atmospheric data -
dir_atm = '/tank/chaocean/atmospheric_data/DFS5.2_NorthAtl/';


%-- generate the chaocean grid --
global xLon yLat mask_mit mask_topo x_cut ybc
mk_grid(4,0,0)
[nx,ny] = size(yLat);

%-- load mask for smoothing over land --
% only needed for the 1/12 reshaped grid
%fid = fopen('/tank/chaocean/climatologies/smoothmask','r',ieee);
%smoothmask = fread(fid,[1000 900],accu);
%fclose(fid);

%-- Get dimension of inputs --
lat_atm = double(ncread([dir_atm 'precip_DFS5.2_y1958_chaO.nc'],'lat'));
lon_atm = double(ncread([dir_atm 'precip_DFS5.2_y1958_chaO.nc'],'lon'));
lon_atm(lon_atm>180) = lon_atm(lon_atm>180) - 360;
[yLat_atm,xLon_atm] = meshgrid(lat_atm,lon_atm);
[nx_atm,ny_atm] = size(yLat_atm);
time_atm = double(ncread([dir_atm 'precip_DFS5.2_y1958_chaO.nc'],'time'));

%-- generate a new interpolant --
tmp1 = zeros(nx_atm,ny_atm);
fprintf('Creating new interpolant\n')
[tmp2,tri,wei] = my_griddata1(xLon_atm,yLat_atm,tmp1,xLon,yLat,{'QJ'}); 
clear tmp1 tmp2




%-- Loop over years --
for iiYear = 2003:2004

  fprintf('Year: %i\n', iiYear)


  %-- load data and interpolate --
  time_atm = ncread([dir_atm 'precip_DFS5.2_y' num2str(iiYear) '_chaO.nc'],'time');
  [nt_atm] = size(time_atm,1);
  
  tmp_precip = ncread([dir_atm 'precip_DFS5.2_y' num2str(iiYear) '_chaO.nc'],...
      'precip'); %[kg.m-2.s-1] 

  %- discard leap year (not considered in other variables) -
  if nt_atm == 366
    nt_atm = 365;
    time_atm = time_atm(1:365);
    tmp_precip = tmp_precip(:,:,1:365);
  end

%  data_tmp = zeros(x_cut,ny,nt_atm);
  data_tmp = zeros(nx,ny,nt_atm);

  %- loop over time step for interpolation -
  for iit=1:nt_atm
    tmpvar = my_griddata2(xLon_atm,yLat_atm,tmp_precip(:,:,iit),...
        xLon,yLat,tri,wei);
%    %- rearrange on the reshaped grid, and smooth transition over land  -
%    tmp1_precip = cut_gulf(tmpvar,mask_mit,x_cut,1,10);
%    tmp1_precip(end,:) = tmpvar(end,:);
%    tmp2_precip = zeros(1000,900);
%    tmp2_precip(1:nx-x_cut,:) = tmp1_precip;
%    tmp2_precip(nx-x_cut+1:end,:) = repmat(tmp2_precip(nx-x_cut,:),[x_cut-(nx-x_cut) 1]);
    
%    data_tmp(:,:,iit) = tmpvar(1:x_cut,:) .* (1-smoothmask) + ...
%                        tmp2_precip .* smoothmask;
    data_tmp(:,:,iit) = tmpvar;
  end %iit


  %-- write file --
  fid=fopen([dir_o 'precip_daily_' num2str(iiYear) '.box'] ,'w',ieee);
  fwrite(fid,data_tmp,accu); fclose(fid);


end % for iiYear

