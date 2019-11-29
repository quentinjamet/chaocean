% DESCRIPTION: 
%
% Generate initial conditions from NEMO runs to chaocean grid
% Suppose on the same vertical grid (no vertical interpolation)
% uE and vN are inteprolated on a staggered grid, South for vN and West for uE



clear all; close all

addpath('/tank/users/qjamet/MatLab/mk_Config/')


%------------
% Directories
%------------

%- output dir -
dir_o = '/tank/chaocean/initial_conditions_12/';
%dir_o = '/tank/chaocean/qjamet/Config/Test_cheapAML0.25/run_CheapAML/input/';

%- Initial conditions data -
dir_ini = '/tank/chaocean/initial_data/1958/';

%- grid parameters directory -
%dirGrd = '/tank/chaocean/qjamet/RUNS/Test_cheapAML0.25/grid025/';
dirGrd = '/tank/chaocean/grid_chaO/gridMIT/';

%------------------
% Specific flags
%------------------

ieee='b';
accuracy='real*4';

flg_cut = 1;
flag_interp = 0; 	%1: matlab original interpolation (slower), 0: mygriddata
flag_save = 1;


%---------------------------
% generate the chaocean grid
%---------------------------
global xLon yLat rC mask_mit mask_topo x_cut ybc
mk_grid(12,0,flg_cut)

[nLon,nLat] = size(xLon);

%-- compute U-pts and V-pts for velocity interpolation --
xu = zeros(nLon,nLat);
xu(2:nLon,:) = (xLon(1:nLon-1,:) + xLon(2:nLon,:)) ./2;
xu(1,:) = xu(2,:) - (xu(3,:)-xu(2,:));
yu = yLat;

xv = xLon;
yv = zeros(nLon,nLat);
yv(:,2:nLat) = (yLat(:,1:nLat-1) + yLat(:,2:nLat)) ./2;
yv(:,1) = yv(:,2) - (yv(:,3)-yv(:,2));

%-- compute cell face area --
rEarth = 6370000; %[m]
dxu = zeros(nLon,nLat);
dxu(1:nLon-1,:) = deg2rad(xu(2:nLon,:)-xu(1:nLon-1,:)) .* rEarth .* cosd(yLat(1:nLon-1,:));
dxu(nLon,:) = dxu(nLon-1,:);
dyv = zeros(nLon,nLat);
dyv(:,1:nLat-1) = deg2rad(yv(:,2:nLat)-yv(:,1:nLat-1)) .* rEarth;
dyv(:,nLat) = dyv(:,nLat-1);
cellSurf = dxu .* dyv;



%-- list of variables --
var = {'T','S','uE','vN','ETA'};
nVar = length(var);
varName = {'votemper','vosaline','','','sossheig'};
def_val = [20.0 30.0 0.0 0.0 0.0];	%used to replace NaN for [t,s,u,v,e]
%- uE,vN have been interpolated at T-pts for rotation -
fileN = {'CI-MJM88_y1958m01d05_gridT.nc',
         'CI-MJM88_y1958m01d05_gridT.nc',
         'CI-MJM88_y1958m01d05_gridT.nc',
         'CI-MJM88_y1958m01d05_gridT.nc',
         'CI-MJM88_y1958m01d05_SSH.nc'};




%-- loop over variables --
for iVar = 3:nVar
disp(['Variable: ' var{iVar}])
%- disociate uE,vN to T,S,ETA -
if strcmp(var{iVar},'uE') || strcmp(var{iVar},'vN')
  flag_uv = 1;
else
  flag_uv = 0;
end 

%- Vertical grid (assumed to be the same for NEMO and chaocean) -
if strcmp(var{iVar},'ETA')
  nr = 1;
else
  nr = length(rC);
end %if 'ETA'

%- load variables -
xLon_ini = double(ncread([dir_ini fileN{iVar}],'nav_lon'));
yLat_ini = double(ncread([dir_ini fileN{iVar}],'nav_lat'));
[nLon_ini,nLat_ini] = size(yLat_ini);

if flag_uv
  fid = fopen([dir_ini var{iVar} '_CI-MJM88_1958m01d05.box'],'r',ieee);
  data_ini = fread(fid,accuracy);
  data_ini = reshape(data_ini,[nLon_ini nLat_ini nr]);
  %- set uE,vN to 0 on land -
  data_ini(isnan(data_ini)) = 0;
  tmpmsk = mask_topo;
else
  data_ini = ncread([dir_ini fileN{iVar}],varName{iVar});
  %- set to NaN land points -
  tmpmsk = mask_topo;
  tmpmsk(tmpmsk == 0) = NaN;
end
 




%-- loop over vertical level for interpolation onto chaocean grid --
data_tmp2 = zeros(nLon,nLat,nr);

for iiZ = 1:nr

  if flg_cut
    data_tmp = zeros(nLon,nLat);	%change size when reshaping; need to be reset
  end

  %- interpolate onto the MITgcm grid -
  if flag_interp  | strcmp(var{iVar},'ETA') 	%MatLab interpolation
    data_tmp(:,:) = griddata(xLon_ini,yLat_ini,data_ini(:,:,iiZ),xLon,yLat);

  else                    %BD interpolation
    if iiZ == 1
      fprintf('Creating new interpolant\n')
      if strcmp(var{iVar},'uE') 
        [t_mit,tri,wei] = my_griddata1(xLon_ini,yLat_ini,data_ini(:,:,iiZ),xu,yu,{'QJ'});
      elseif strcmp(var{iVar},'vN')
        [t_mit,tri,wei] = my_griddata1(xLon_ini,yLat_ini,data_ini(:,:,iiZ),xv,yv,{'QJ'});
      else
        [t_mit,tri,wei] = my_griddata1(xLon_ini,yLat_ini,data_ini(:,:,iiZ),xLon,yLat,{'QJ'});
      end
    end
    if strcmp(var{iVar},'uE')
      data_tmp(:,:) = my_griddata2(xLon_ini,yLat_ini,data_ini(:,:,iiZ),xu,yu,tri,wei);
    elseif strcmp(var{iVar},'vN')
      data_tmp(:,:) = my_griddata2(xLon_ini,yLat_ini,data_ini(:,:,iiZ),xv,yv,tri,wei);
    else
      data_tmp(:,:) = my_griddata2(xLon_ini,yLat_ini,data_ini(:,:,iiZ),xLon,yLat,tri,wei);
    end
  end %if flag_interp

  %- remove grid points that are not considered (Med sea, Pacific, ...) -
  data_tmp2(:,:,iiZ) = data_tmp .* tmpmsk;

end %for iiZ




%-- resolve the problem of NaNs in the ocean --
%-- no need for uE,vN because set to 0 on land before interpolation --

if ~flag_uv

  %- load 3D mask generated with outputs of the MITgcm to get land grid points -
  if nLat == 300		%1/4 degree
    load('/tank/users/qjamet/MatLab/mk_Config/Mask025_3D.mat')
    mskLnd = msk025_3D; 
  elseif nLat == 900	%1/12 degree
    load('/tank/users/qjamet/MatLab/mk_Config/Mask12_3D.mat')
    mskLnd = cut_gulf_NaN(msk12_3D,-1,0);
    mskLnd(mskLnd == 20) = 1;
  end

  %- for surface grid points  -
  kDepth = find(rC>-1000);
  if iVar == 5 	%Eta
    nkD = 1;
  else
    nkD = length(kDepth);
  %  nkD = nr; 
  end
  %nkD = 1;


  for iiZ = 1:nkD
    testNaN = 1;
    while testNaN <=3
     tmp = data_tmp2(:,:,iiZ);
     tmp(mskLnd(:,:,iiZ) == 0) = def_val(iVar);       % all these grid points are on land
     %exclude boundary points for now
     [ii,jj] = find(isnan(tmp(2:nLon-1,2:nLat-1)));
     if ~isempty(ii)
      ii = ii+1;	% add 1 because boundaries are not considere
      jj = jj+1;	% add 1 because boundaries are not considere
      for ij = 1:length(ii)
        tmpIJ = data_tmp2(ii(ij)-1:ii(ij)+1,jj(ij)-1:jj(ij)+1,iiZ);
        tmpCell = cellSurf(ii(ij)-1:ii(ij)+1,jj(ij)-1:jj(ij)+1);
        tmpCell = [1/sqrt(2) 1 1/sqrt(2) ; 1 NaN 1 ; 1/sqrt(2) 1 1/sqrt(2)] .* tmpCell;
        tmpCell(find(isnan(tmpIJ))) = NaN;
        data_tmp2(ii(ij),jj(ij),iiZ) = nansum(tmpIJ(:) .* tmpCell(:)) ./ ...
             nansum(tmpCell(:));
%        data_tmp2(ii(ij),jj(ij),iiZ) = nansum([data_tmp2(ii(ij)+1,jj(ij),iiZ) ...
%            data_tmp2(ii(ij)-1,jj(ij),iiZ) data_tmp2(ii(ij),jj(ij)+1,iiZ) ...
%            data_tmp2(ii(ij),jj(ij)-1,iiZ) ...
%            (1/sqrt(2)) .* [data_tmp2(ii(ij)-1,jj(ij)-1,iiZ) ...
%            data_tmp2(ii(ij)-1,jj(ij)+1,iiZ) data_tmp2(ii(ij)+1,jj(ij)-1,iiZ) ...
%            data_tmp2(ii(ij)+1,jj(ij)+1,iiZ)]  ]) ./ (4*(1+1/sqrt(2)));
      end
     end
     testNaN = testNaN + 1;
    end %testNaN

    if iiZ == 1
    %if some grid points remains, they have no connection with open ocean ->  set them to 'def_val'
    tmp = data_tmp2(:,:,iiZ);
    tmp(mskLnd(:,:,iiZ) == 0) = def_val(iVar);       % all these grid points are on land
    [ii,jj] = find(isnan(tmp(2:nLon-1,2:nLat-1)));
    fprintf('-- Level %i: %i grid points filled with def_val --\n',iiZ,length(ii))
    data_tmp2(ii+1,jj+1,iiZ) = def_val(iVar);
    end
 
 
    %western boundary
    tmp = data_tmp2(1,:,iiZ);
    tmp(mskLnd(1,:,iiZ) == 0) = def_val(iVar);       % all these grid points are on land
    jj = find(isnan(tmp(2:nLat-1)));
    if ~isempty(jj)
      jj = jj+1;	% add 1 because boundaries are not considere
      for jjj = 1:length(jj)
       data_tmp2(1,jj(jjj),iiZ) = nanmean([data_tmp2(2,jj(jjj),iiZ) ...
    	  (1/sqrt(2)) .* [data_tmp2(2,jj(jjj)-1,iiZ) data_tmp2(2,jj(jjj)+1,iiZ)] ]);
      end% %jjj
    end %if 


    %eastern boundary
    tmp = data_tmp2(nLon,:,iiZ);
    tmp(mskLnd(nLon,:,iiZ) == 0) = def_val(iVar);       % all these grid points are on land
    jj = find(isnan(tmp(2:nLat-1)));
    if ~isempty(jj)
      jj = jj+1;  % add 1 because boundaries are not considere
      for jjj = 1:length(jj)
       data_tmp2(nLon,jj(jjj),iiZ) = nanmean([data_tmp2(nLon-1,jj(jjj),iiZ) ...
          (1/sqrt(2)) .* [data_tmp2(nLon-1,jj(jjj)-1,iiZ) data_tmp2(nLon-1,jj(jjj)+1,iiZ)] ]);
      end %jjj
    end %if


  


  end %iiZ



  %- for grid points below the surface -

  if ~strcmp(var{iVar},'ETA')
    % first get hz locations where problem occurs
    tmp = data_tmp2;
    tmp(mskLnd == 0) = def_val(iVar);
    tmp = mean(tmp,3);
    [ii,jj] = find(isnan(tmp(:,2:nLat-1)));
    jj = jj+1;

    nkk = 0;
    for ij = 1:length(ii)
      tmp = squeeze(data_tmp2(ii(ij),jj(ij),:));
      tmp(mskLnd(ii(ij),jj(ij),:) == 0) = def_val(iVar);
      kk = find(isnan(tmp));
      nkk = nkk + length(kk);
      data_tmp2(ii(ij),jj(ij),kk) = data_tmp2(ii(ij),jj(ij),kk(1)-1);
    end %ij
    fprintf('-- %i NaN points with vertical repetition at %i location--\n',nkk,length(ii))
  end % if 'ETA'


  %-- set land points to def_val --
  data_tmp2(isnan(data_tmp2)) = def_val(iVar);

end % if 'T', 'S', 'ETA'



%-- repeat data for N/S boundary conditions --
data_tmp2(:,1,:) = data_tmp2(:,2,:);
data_tmp2(:,end,:) = data_tmp2(:,end-1,:);


%- reshape onto the chaocean grid -
if flg_cut
  data_tmp2 = cut_gulf_NaN(data_tmp2,1,def_val(iVar));
end % flg_cut




%- SAVE -
if flag_save
  fid = fopen([dir_o var{iVar} '_ini.box'],'w',ieee);
  fwrite(fid,data_tmp2,accuracy);
  fclose(fid);
end


end %iVar






