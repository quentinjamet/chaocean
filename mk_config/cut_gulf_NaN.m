function field_out = cut_gulf_NaN(field_in,fb,defVal)
% DESCRIPTION:
% 
% function field_out = cut_gulf_NaN(field_in,fb,defVal)
%
% Input: 
%	- field_in	: Field to be reshape on a modified grid
%	- fb		: +1 forward, -1 backward 
%	- defdVal	: default value used for land (0, 20, 30, NaN, ...)
%			  NB: Note used in the backward computation (fb=-1)
%
% Output:
%	- field_out	: reshaped field


%-- predefined parameters (to be changed if the original mask use to reshape
%   the grid is modified) --
if fb == 1
  x_cut = 1000;
  load('/tank/chaocean/scripts/mask_cut_gulf_forward.mat')
elseif fb == -1
  x_cut = 301;
  load('/tank/chaocean/scripts/mask_cut_gulf_backward.mat')
end
%------------------------------------------------------------------------------

[nx,ny,nr] = size(field_in);

%-- consistency check --
if numel(mask_mit) ~= nx*ny
  [d1,d2] = size(mask_mit);
  fprintf('--- Incoming field is (nx=%i,ny=%i) ---\n',nx,ny)
  fprintf('--- Mask is (nx=%i,ny=%i) ---\n',d1,d2)
  error('--- Incoming field and mask do not match ---\n')
end


if ~isnan(defVal)
  field_in(field_in == defVal) = NaN;
end


if fb == 1

  xReplace = nx-x_cut;

  %-- extract points to move --
  toMove = reshape(field_in(x_cut+1:nx,:,:),[xReplace*ny nr]);
  toCut = mask_mit(x_cut+1:nx,:);
  [ij] = find(toCut(:) == 1);

  %- check that these points will be placed on land -
  tmp = reshape(field_in(1:xReplace,:,:),[xReplace*ny nr]);
  if ~isnan(tmp(ij,1))
    error('--- At leat 1 moved point will be placed at an ocean grid point ---')
  end
  tmp(ij,:) = toMove(ij,:);



  %-- generate the output field --
  field_out = nan(x_cut,ny,nr);
  field_out(1:xReplace,:,:) = reshape(tmp,[xReplace ny nr]);
  field_out(xReplace+1:x_cut,:,:) = field_in(xReplace+1:x_cut,:,:);


elseif fb == -1

  %-- extract points to move --
  toMove = reshape(field_in(1:x_cut,:,:),[x_cut*ny nr]);
  toCut = mask_mit(1:x_cut,:);
  [ij] = find(toCut(:) == 1);

  tmp = nan(x_cut*ny,nr);
  tmp(ij,:) = toMove(ij,:);
  toMove(ij,:) = NaN;
  
  %-- generate the output field --
  field_out = nan(nx+x_cut,ny,nr);
  field_out(1:nx,:,:) = field_in;
  field_out(1:x_cut,:,:) = reshape(toMove,[x_cut ny nr]);
  field_out(nx+1:nx+x_cut,:,:) = reshape(tmp,[x_cut ny nr]);


end %if  fb

if ~isnan(defVal)
  field_out(isnan(field_out)) = defVal;
end



