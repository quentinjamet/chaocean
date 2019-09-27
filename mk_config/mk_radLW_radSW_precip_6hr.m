% DESCRIPTION: 
%
% Interpolate the daily short and long wave radiation into 6-hourly fields.
% Inteprolation: time = 6h, 12h, 18h, 24h;
%		radWS(12h,18h) = 2* daily value;
%		radSW(6h,24h)  = 0;

clear all; close all

addpath('/tank/users/qjamet/MatLab/mk_Config/')


%------------
% Directories
%------------

%- atmospheric -
dir_precip = '/tank/chaocean/atmospheric_data/DFS5.2_NorthAtl/';
dir_rad = '/tank/chaocean/atmospheric_data/DFS4.4_NorthAtl/';
dir_out = '/tank/chaocean/atmospheric_data/6hr_precip_radlw_radsw/';

%--------------------
% set local variables
%--------------------

ieee='b';
accu='real*4';

yYr = 2003:2004;
[nYr] = length(yYr);

%vVar = {'radlw','radsw','precip'};
vVar = {'precip'};
[nVar] = length(vVar);

lon = double(ncread([dir_rad 'radlw_DFS4.4_y1963_chaO.nc'],'lon'));
lat = double(ncread([dir_rad 'radlw_DFS4.4_y1963_chaO.nc'],'lat'));
[yC_rad,xC_rad] = meshgrid(lat,lon);
[nx_rad,ny_rad] = size(xC_rad);
lon = double(ncread([dir_precip 'precip_DFS5.2_y1963_chaO.nc'],'lon'));
lat = double(ncread([dir_precip 'precip_DFS5.2_y1963_chaO.nc'],'lat'));
[yC_precip,xC_precip] = meshgrid(lat,lon);
[nx_precip,ny_precip] = size(xC_precip);

%- get days and hours -
time_day = ncread([dir_rad 'radsw_DFS4.4_y1963_chaO.nc'],'time');
[nTime_d] = length(time_day);
time_6hr= ncread([dir_rad 't2_DFS4.4_y1987_chaO.nc'],'time');
[nTime_6h] = length(time_6hr);
dDay = floor(time_6hr);
hHour = time_6hr - dDay;


%----------------
% Loop over years 
%----------------
for iYr = 1:nYr
 for iVar = 1:nVar
  tmp_var = vVar{iVar};
  fprintf('-- year %i, var %s --\n',yYr(iYr),tmp_var)
 
  if strcmp(tmp_var,'precip')
   tmp_dir = dir_precip;
   dfs='5.2';
   nx = nx_precip;
   ny = ny_precip;
  else
   tmp_dir = dir_rad;
   dfs='4.4';
   nx = nx_rad;
   ny = ny_rad;
  end

  tmpdata = zeros(nx,ny,nTime_d+1);
  tmpdata1 = ncread([tmp_dir tmp_var '_DFS' dfs '_y' num2str(yYr(iYr)) ...
                '_chaO.nc'],tmp_var);
  if yYr(iYr) > 1958
    tmpdata0 = ncread([tmp_dir tmp_var '_DFS' dfs '_y' num2str(yYr(iYr)-1) ...
                  '_chaO.nc'],tmp_var);
    tmpdata(:,:,1) = tmpdata0(:,:,nTime_d);
  else
    tmpdata(:,:,1) = tmpdata1(:,:,1); 
  end
  tmpdata(:,:,2:nTime_d+1) = tmpdata1(:,:,1:nTime_d);

  %- reshape incoming variable -
  data_daily = reshape(tmpdata,[nx*ny nTime_d+1]);
  clear tmpdata;

  %- initialize -
  data_6h = zeros(nx*ny,nTime_6h);

  %- interpolate -
  if strcmp(tmp_var,'radsw')
   %- data at 12h = 2*data_daily -
   iiDay = find(hHour == .5);
   data_6h(:,iiDay) = 2.*data_daily(:,1:nTime_d);
   %- data at 18h = 2*data_daily -
   iiDay = find(hHour == .75);
   data_6h(:,iiDay) = 2.*data_daily(:,1:nTime_d);
  else
   for ij = 1:nx*ny
     data_6h(ij,:) = interp1([0; time_6hr(4:4:nTime_6h)],...
         data_daily(ij,:),time_6hr);
   end
  end

  %- save -
  fid = fopen([dir_out tmp_var '_6hr_' num2str(yYr(iYr)) '.box'],'w',ieee);
  fwrite(fid,data_6h,accu);
  fclose(fid);


 end %- for iVar 
end %- for iYr


return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-- Make some test to insure that the integrated radSW/LW is conserved --

%- daily -
tmp_d = data_daily(1,:);
dt_d = 1;	%[day]
time_d = 0:dt_d:364;

%- 6-hourly -
tmp_6h = data_6h(1,:);
dt_6h = 1/4;
time_6h = 0:dt_6h:365-dt_6h;

nDay = 364;
int_d = sum(tmp_d(1:nDay).*dt_d);
int_6h = sum(tmp_6h(1:nDay*(1/dt_6h)) .* dt_6h);

figure(02)
clf
plot(time_6h(1:nDay*(1/dt_6h)),tmp_6h(1:nDay*(1/dt_6h)),'b.-')
hold on
plot(time_d(1:nDay),tmp_d(1:nDay),'r.')
grid on
title(['int_{d} - int_{6h} = ' num2str(int_d - int_6h)])
xlabel('Time (days)')
ylabel([var{iiVar} ' (W.m^{-2})'])
legend(['6-hourly values: int=' num2str(int_6h)],...
    ['Daily values: int=' num2str(int_d)])
set(gca,'Xlim',[1 10])
%saveas(figure(02),'/tank/users/qjamet/Figures/int_6hr_daily.png')





%-- what does the MITgcm with data --
%- time step MIT -
dt_MIT = 450/86400;
time_MIT = 0:dt_MIT:365-dt_MIT;

%- interpolation from daily values -
tmp_MIT = interp1(time_d,tmp_d,time_MIT);
int_MIT = sum(tmp_MIT(1:nDay*(1/dt_MIT)) .* dt_MIT);

figure(10)
clf
plot(time_MIT(1:nDay*(1/dt_MIT)),tmp_MIT(1:nDay*(1/dt_MIT)))
hold on
plot(time_d(1:nDay),tmp_d(1:nDay),'r.')
grid on
title(['MITgcm linear interp daily values; int_{d} - int_{MIT} = '...
     num2str(int_d - int_MIT)])
xlabel('Time (days)')
ylabel([var{iiVar} ' (W.m^{-2})'])
legend(['MIT interp: int=' num2str(int_MIT)],...
    ['Daily values: int=' num2str(int_d)])
set(gca,'Xlim',[1 10])
%saveas(figure(10),'/tank/users/qjamet/Figures/int_MITgcm_daily.png')


%- interpolation from 6-hourly values -
tmp2_MIT = interp1(time_6h,tmp_6h,time_MIT);
int2_MIT = sum(tmp2_MIT(1:nDay*(1/dt_MIT)) .* dt_MIT);

figure(20)
clf
plot(time_MIT(1:nDay*(1/dt_MIT)),tmp2_MIT(1:nDay*(1/dt_MIT)))
hold on
plot(time_6h(1:nDay*(1/dt_6h)),tmp_6h(1:nDay*(1/dt_6h)),'r.')
grid on
title(['MITgcm linear interpolation 6-hr values ; int_{d} - int_{MIT} = '... 
     num2str(int_6h - int2_MIT)])
xlabel('Time (days)')
ylabel([var{iiVar} ' (W.m^{-2})'])
legend(['MIT interp: int=' num2str(int2_MIT)],...
    ['6-hourly values: int=' num2str(int_6h)])
set(gca,'Xlim',[1 10])
%saveas(figure(20),'/tank/users/qjamet/Figures/int_MITgcm_6hr.png')





if flag_save
  fid = fopen([dir_clim var{iiVar} '_climatology_6hr_DFS4.4'],'w',ieee);
  fwrite(fid,[nLon nLat nTime_6h],accuracy);
  fid = fopen([dir_clim var{iiVar} '_climatology_6hr_DFS4.4'],'a',ieee);
  fwrite(fid,data_6h,accuracy);
  fclose(fid);
end %flag_save

%end %iiVar
