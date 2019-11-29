function mk_grid(hzRes,saveGrd,flag_cut)
% function mk_grid(hzRes,saveGrd,flag_cut)
%
% DESCRIPTION:
%
% Generate the chaocean horizontal and vertical grid, the associated bathymetry
% and some usefull parameters to compute interpolation
%
% INPUT:
%	- hzRes		- 4 -> 1/4 degree	; 12 -> 1/12 degree
%	- saveGrd	- 1 -> save into dir_o ; 0 -> do not save
%	- flag_cut	- 1 -> reshape the bathymetry to reduce the domain size ; 0 -> do not use cut_gulf.m
%

global w_z xLon yLat rC rF drF mask_mit mask_topo x_cut ybc h2 

%------------
% Directories
%------------

%- output dir -
%$dir_o = '/tank/users/qjamet/MatLab/Test_flx/';
dir_o = '/tank/chaocean/qjamet/Config/north_alt_025/data_in/';
%dir_o = '/tank/chaocean/grid_chaO/';

%- Bathymetry (take the bathymetry associated with initial conditions) -
dir_bathy = '/tank/chaocean/initial_data/';




%---------------
% Specific flags 
%---------------

ieee='b';
accuracy='real*4';

flag_plot = 0;




%-------------------------
% Define the chaocean grid
%-------------------------

%-- Horizontal grid --
if hzRes == 12
  dla = 1/12.;
  dlo = 1/11.62;% to end up with 1000 grid point in x-dir
elseif hzRes == 4
  dla = 1/4.;
  dlo = 1/4.;
else
  error('-- horizontal resolution not set --')
end
  
latS = -20+dla;
latN = 55.0;
%latS = -20;
%latN = 55.0-dla;
lonW = -98;
lonE = 14-dlo;

yy = [latS:dla:latN];
xx = [lonW:dlo:lonE];
[yLat,xLon]=meshgrid(yy,xx);
[nx_MIT,ny_MIT] = size(xLon);

dla_km = dla*2*pi*6370/360;

dxC = dlo*ones(nx_MIT,1);
dyC = dla*ones(ny_MIT,1);



%-- Vertical grid (46 layers from NEMO config) --
rC = ncread([dir_bathy '1987/CI-MJM88_y1987m01d05_gridT.nc'],'deptht');
drC = rC(2:end)-rC(1:end-1);
drF = zeros(size(rC));
drF(1) = 2*rC(1);
for iir = 2:size(rC,1)
  drF(iir) = 2*(drC(iir-1) - drF(iir-1)/2);
end

nr_MIT = size(drF,1);
rC = -rC;
rF = [0 ; rC-drF/2];

%-- Save grid --
if saveGrd
    fid=fopen([dir_o,'dx.box'],'w',ieee);  fwrite(fid,dxC,accuracy); fclose(fid);
    fid=fopen([dir_o,'dy.box'],'w',ieee);  fwrite(fid,dyC,accuracy); fclose(fid);
    fid=fopen([dir_o,'dz.box'],'w',ieee);  fwrite(fid,drF,accuracy); fclose(fid);
end


fprintf('MIT max depth %f m \n',sum(drC));
fprintf('nx: %i \n',nx_MIT);
fprintf('ny: %i \n',ny_MIT);
fprintf('nr: %i \n',nr_MIT);

% ybc : variable for north-south BC cut
ybc = 1;
if flag_cut
  % which lat to cut
  lat_cut = -12.;
  [argvalue, x_cut] = min(abs(xx-lat_cut));

  if x_cut > 0.5*nx_MIT
    x_c1 = x_cut;
    x_c2 = nx_MIT;
    % cut west
    flag_cut = 2;
  else
    x_c1 = 1;
    x_c2 = x_cut;
    % cut east
    flag_cut = 1;
  end    
  
  nx_MIT2 = nx_MIT-(x_c2-x_c1);
  
  % if it is a regular grid: doesn't matter which dx you pick
  if saveGrd
      fid=fopen([dir_o,'dx.box'],'w',ieee);  fwrite(fid,dxC(1:nx_MIT2),accuracy); fclose(fid);  
  end
  fprintf('*******************\n');
  fprintf('new nx: %i \n',nx_MIT2);
  fprintf('lon cut: %6.2f \n',xx(x_cut+1));
  fprintf('*******************\n');
end

fprintf('===== For the MITgcm =======\n')
fprintf('ygOrigin = %3.4f\n',latS-dla/2)
fprintf('xgOrigin = %3.4f\n',(360+lonW) - dlo/2)
fprintf('============================\n')

fprintf('Building oceanic files \n');
  



%-----------
% Bathymetry 
%-----------

fprintf('Bathymetry \n');

filetopo = '/grid/CI-MJM88_bathy_meter.nc';

%-- Initial bathymetry and horizontal grid --  
bathy   = double(ncread([dir_bathy,filetopo],'Bathymetry'));
nav_lat = double(ncread([dir_bathy,filetopo],'nav_lat'));
nav_lon = double(ncread([dir_bathy,filetopo],'nav_lon'));

% do some checks
fprintf('check grid: \n');
fprintf('min lat (old, new): %f %f \n', min(min(nav_lat)), min(min(yLat)));
fprintf('max lat (old, new): %f %f \n', max(max(nav_lat)), max(max(yLat)));

fprintf('min lon (old, new): %f %f \n', min(min(nav_lon)), min(min(xLon)));
fprintf('max lon (old, new): %f %f \n', max(max(nav_lon)), max(max(xLon)));

%- PLOT -
if flag_plot
figure(01)
clf
pcolor(nav_lon,nav_lat,-bathy);shading flat 
hold on
contour(nav_lon,nav_lat,-bathy,[0 0],'k')
title('Native topography')
xlabel('Longitude')
ylabel('Latitude')
saveas(gcf,'/tank/users/qjamet/Figures/Native_topo.png');
end

%-- interpolate initial bathymetry on the native grid (with no cut_gulf) --
xlo_t = xLon;
yla_t = yLat;
h = griddata(nav_lon,nav_lat,bathy,xlo_t,yla_t); 
h(isnan(h)) = 0;

% sign for mitgcm
h = -h;





%------------------------------------------------------------------------------
% Modify the initial chaocean grid in order to reduce the number of grid points
%
% may not work at all resolutions 
%-------- WARNING --------


mask_topo = h;
mask_topo(mask_topo ~= 0) = 1;
label = bwlabel(mask_topo);

% pacific
lab_pacific = label(1,1);
mask_topo(label == lab_pacific) = 0;

% mediterranean
%gibraltar
% lat first because the grid is not regular
[argvalue, ila_gib] = min(abs(yy-35.9));
[argvalue, ilo_gib] = min(abs(xx+5.7));
djgib = floor(70.0/dla_km)+1;

% straight line across gibraltar 
mask_topo(ilo_gib,ila_gib-djgib:ila_gib+djgib) = -0;

label = bwlabel(mask_topo);
% hopefully this is a sea point
lab_med = label(ilo_gib+2,ila_gib);
mask_topo(label == lab_med) = 0;

% fill up the rest (North of Gibralar)
%-- MAY BE DANGEROUS -- (remove Baltic sea -- QJ 04/07/2017 change ny_MIT to 850)
% -> this was made on purpose due to spurious SSH anomalies in that region (BD 04/11/2017)
for ny = ila_gib:ny_MIT
  if mask_topo(nx_MIT,ny) ~= 0
    lab_o = label(nx_MIT,ny);
    mask_topo(label == lab_o) = 0;
  end
end

% northern canada
[argvalue, ila_can] = min(abs(yy-51.0));
[argvalue, ilo_can] = min(abs(xx+71.3));
mask_topo(1:ilo_can,ila_can:ny_MIT) = 0;

% apply mask
h = h.*mask_topo;

mask_mit = 0*h;
if flag_cut
  % gulf of mexico
  for nx = x_c1:x_c2
    for ny = 1:ny_MIT
      if  h(nx,ny) ~=0
        mask_mit(nx,ny) = 1;
        % buffer zone
        if flag_cut == 1
          mask_mit(max(nx-3,1):min(nx+3,x_cut),max(ny-3,1):min(ny+3,ny_MIT)) = 1;
        else
          mask_mit(max(nx-3,x_cut):min(nx+3,nx_MIT),max(ny-3,1):min(ny+3,ny_MIT)) = 1;
        end
      end
    end
  end
%else
%  %- store the bathymetry without Med sea, Pacific and others -
%  mask_mit = mask_topo;
end


mask_check = cut_gulf(mask_topo,mask_mit,x_cut,flag_cut,ybc);

h2 = cut_gulf(h,mask_mit,x_cut,flag_cut,ybc);

%-- Make some modification on bathymetry to avoid too shallow layers --
%-- at the surface (might cause the model to crash )                 --

hfacMin = 1;
topo_nan = h2;
topo_nan(topo_nan == 0) = NaN;
topo_nan(topo_nan <= -drF(1)) = NaN;
topo_nan(topo_nan <= -drF(1)*hfacMin) = -drF(1);
topo_nan(topo_nan > -drF(1)*hfacMin)   = 0;
toto = find(topo_nan == -drF(1));
length(toto)

%- put into h2 -
h2(~isnan(topo_nan)) = topo_nan(~isnan(topo_nan));

%-- treat specific regions --
%- Saint-Laurent -
h2(320:328,808:817) = 0;

%- north boundary -
h2(456:464,898:900) = 0;



% make a plot with the tile subdivision
if (flag_plot == 1)
  msk = h2;
  msk(msk ~= 0) = 1;
  msk(msk == 0) = NaN;
  load('/tank/users/qjamet/MatLab/MyCmap_redBlue.mat')
  dir_fig = '/tank/users/qjamet/Figures/';

  figure(02);clf
  set(gcf,'position',[50 400 1000 700])

  if flag_cut
    [C,h]=contourf(xLon(1:nx_MIT2,:),yLat(1:nx_MIT2,:),h2.*msk);
    set(gca,'Color',[0.6 0.6 0.6])
    set(gcf,'Color',[1 1 1])
    set(h,'lineStyle','none')
    colormap(mycmap)
    colorbar
    caxis([-7000 0])
    hold on;
    nxp = 20; %1/12 degree resolution
    nyp = 12;
    si_xp = floor(nx_MIT2/nxp);
    si_yp = floor(ny_MIT /nyp);
    for nx = 1:nxp
      plot([xLon(1+(nx-1)*si_xp,1),xLon(1+(nx-1)*si_xp,1)],...
          [yLat(1+(nx-1)*si_xp,1),yLat(1+(nx-1)*si_xp,end)],'k--')
    end
    for ny = 1:nyp
      plot([xLon(1,1),xLon(nx_MIT2,1)],[yLat(1,1+(ny-1)*si_yp),yLat(1,1+(ny-1)*si_yp)],'k--')
    end
    xlabel('Longitude')
    ylabel('Latitude')
    fig=gcf;
    fig.InvertHardcopy = 'off';
    %saveas(figure(02),[dir_fig 'topo12_240tiles.png'])
    exportfig(figure(02),[dir_fig 'topo12_240tiles.pdf'],...
        'width',6,'color','rgb','resolution',300);
  else
    contourf(xLon,yLat,h2.*msk)
    hold on
    nxp = 4; %1/4 degree resolution
    nyp = 4;
    si_xp = floor(nx_MIT/nxp);
    si_yp = floor(ny_MIT /nyp);
    for nx = 1:nxp
      plot([xLon(1+(nx-1)*si_xp,1),xLon(1+(nx-1)*si_xp,1)],...
          [yLat(1+(nx-1)*si_xp,1),yLat(1+(nx-1)*si_xp,end)],'r')
    end
    for ny = 1:nyp
      plot([xLon(1,1),xLon(nx_MIT,1)],[yLat(1,1+(ny-1)*si_yp),yLat(1,1+(ny-1)*si_yp)],'r')
    end
    title(['MITgcm choacean grid ' num2str(dla,'%.2f') 'x' num2str(dla,'%.2f')])
    saveas(gcf,'/tank/users/qjamet/Figures/topo_0.25x0.25_tiles.png');
  end
end

%-- replace h2 at N/S bdy as a repeat of adjacent lat
%   for consistency with the obcs --
h2(:,end)=h2(:,end-1);
h2(:,1)=h2(:,2);

%-- Save --
if saveGrd
    fid=fopen([dir_o,'topo2.bin'],'w',ieee); fwrite(fid,h2,accuracy); fclose(fid);
end

fprintf('end topo \n');


