function [grid, cfg] = net_prepare_sourcemodel(cfg)

% NET_PREPARE_SOURCEMODEL constructs a source model, for example a 3D grid or a
% cortical sheet. The source model that can be used for source reconstruction,
% beamformer scanning, linear estimation and MEG interpolation.
%
% Use as
%   grid = ft_prepare_sourcemodel(cfg)
%

NET_path=net('path');

% start with an empty grid

unit=cfg.grid.unit;
thres=cfg.threshold;

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % construct a grid based on the segmented MRI that is provided in the
  % configuration, only voxels in gray matter will be used
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  if ischar(cfg.mri)
    mri = ft_read_mri(cfg.mri);
  else
    mri = cfg.mri;
  end

  % ensure the mri to have units
  if ~isfield(mri, 'unit')
    mri = ft_convert_units(mri);
  end

 
head=zeros(size(mri.seg));
head(mri.seg>0)=1;

  % convert the source/functional data into the same units as the anatomical MRI
  scale = ft_scalingfactor(cfg.grid.unit, mri.unit);

  ind                 = find(head(:));
  fprintf('%d from %d voxels in the segmentation are marked as ''inside'' (%.0f%%)\n', length(ind), numel(head), 100*length(ind)/numel(head));
  [X,Y,Z]             = ndgrid(1:mri.dim(1), 1:mri.dim(2), 1:mri.dim(3));  % create the grid in MRI-coordinates
  posmri              = [X(ind) Y(ind) Z(ind)];                            % take only the inside voxels
  poshead             = ft_warp_apply(mri.transform, posmri);                 % transform to head coordinates
  resolution          = cfg.grid.resolution*scale;                                        % source and mri can be expressed in different units (e.g. cm and mm)
  xgrid               = floor(min(poshead(:,1))):resolution:ceil(max(poshead(:,1)));      % create the grid in head-coordinates
  ygrid               = floor(min(poshead(:,2))):resolution:ceil(max(poshead(:,2)));      % with 'consistent' x,y,z definitions
  zgrid               = floor(min(poshead(:,3))):resolution:ceil(max(poshead(:,3)));
  [X,Y,Z]             = ndgrid(xgrid,ygrid,zgrid);
  pos2head            = [X(:) Y(:) Z(:)];
  pos2mri             = ft_warp_apply(inv(mri.transform), pos2head);        % transform to MRI voxel coordinates
  pos2mri             = round(pos2mri);
  



Vt.dim      = [length(xgrid) length(ygrid) length(zgrid)];
Vt.pinfo    = [0.000001 ; 0 ; 0];
Vt.dt       = [16 0];
Vt.fname    = [NET_path filesep 'others' filesep 'mask.nii'];
Vt.mat      = net_pos2transform(pos2head/scale, Vt.dim);
data_mask=zeros(Vt.dim);
spm_write_vol(Vt,data_mask);


Vt.dim      = mri.dim;
Vt.pinfo    = [0.000001 ; 0 ; 0];
Vt.dt       = [16 0];
Vt.fname    = [NET_path filesep 'others' filesep 'gray.nii'];
Vt.mat      = mri.transform;
data_gray=zeros(mri.dim);
data_gray(round(mri.gray)==1)=1;
spm_write_vol(Vt,data_gray);

clear matlabbatch;

matlabbatch{1}.spm.spatial.coreg.write.ref = {[NET_path filesep 'others' filesep 'mask.nii']};
matlabbatch{1}.spm.spatial.coreg.write.source = {[NET_path filesep 'others' filesep 'gray.nii']};
matlabbatch{1}.spm.spatial.coreg.write.roptions.interp = 1;
matlabbatch{1}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.coreg.write.roptions.mask = 0;
matlabbatch{1}.spm.spatial.coreg.write.roptions.prefix = 'r';

spm_jobman('run',matlabbatch);

V=spm_vol([NET_path filesep 'others' filesep 'rgray.nii']);
gray_res=spm_read_vols(V);
gray_res(gray_res>thres)=1;
spm_write_vol(V,gray_res);




grid=[];
grid.pos            = pos2head/scale;                                     % convert to source units
grid.xgrid          = xgrid/scale;                                        % convert to source units
grid.ygrid          = ygrid/scale;                                        % convert to source units
grid.zgrid          = zgrid/scale;                                        % convert to source units
grid.dim            = [length(grid.xgrid) length(grid.ygrid) length(grid.zgrid)];
grid.unit           = unit;
grid.inside         = gray_res(:)==1;

% making grid tight
xmin = min(grid.pos(grid.inside,1));
ymin = min(grid.pos(grid.inside,2));
zmin = min(grid.pos(grid.inside,3));
xmax = max(grid.pos(grid.inside,1));
ymax = max(grid.pos(grid.inside,2));
zmax = max(grid.pos(grid.inside,3));
xmin_indx = find(grid.xgrid==xmin);
ymin_indx = find(grid.ygrid==ymin);
zmin_indx = find(grid.zgrid==zmin);
xmax_indx = find(grid.xgrid==xmax);
ymax_indx = find(grid.ygrid==ymax);
zmax_indx = find(grid.zgrid==zmax);
sel =       (grid.pos(:,1)>=xmin & grid.pos(:,1)<=xmax); % select all grid positions inside the tight box
sel = sel & (grid.pos(:,2)>=ymin & grid.pos(:,2)<=ymax); % select all grid positions inside the tight box
sel = sel & (grid.pos(:,3)>=zmin & grid.pos(:,3)<=zmax); % select all grid positions inside the tight box
% update the grid locations that are marked as inside the brain
grid.pos   = grid.pos(sel,:);
grid.inside = grid.inside(sel);
grid.xgrid   = grid.xgrid(xmin_indx:xmax_indx);
grid.ygrid   = grid.ygrid(ymin_indx:ymax_indx);
grid.zgrid   = grid.zgrid(zmin_indx:zmax_indx);
grid.dim     = [length(grid.xgrid) length(grid.ygrid) length(grid.zgrid)];


fprintf('the full grid contains %d grid points\n', numel(grid.inside));
fprintf('%d grid points are marked as inside the brain\n',  sum(grid.inside));


delete([NET_path filesep 'others' filesep 'mask.nii']);
delete([NET_path filesep 'others' filesep 'gray.nii']);
delete([NET_path filesep 'others' filesep 'rgray.nii']);

