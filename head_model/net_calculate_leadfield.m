function net_calculate_leadfield(segimg_filename,elec_filename,options_leadfield)

NET_folder=net('path');

[ddx,ffx,ext]=fileparts(segimg_filename);

mri_subject = ft_read_mri(segimg_filename, 'dataformat', 'nifti_spm');  % in mm
c = ft_convert_units(mri_subject, 'mm'); % in mm
elec = ft_read_sens(elec_filename);

conductivity=load([NET_folder filesep 'template' filesep 'tissues_MNI' filesep options_leadfield.conductivity '.mat']);

nlayers=max(mri_subject.anatomy(:));

cond_image=zeros(size(mri_subject.anatomy));
for i=1:nlayers
    cond_image(mri_subject.anatomy==i)=conductivity.cond_value(i);
end

disp(['NET - Get vol with ' options_leadfield.method ' method...']);

if strcmpi(options_leadfield.method, 'bemcp') || strcmpi(options_leadfield.method, 'dipoli') || strcmpi(options_leadfield.method, 'openmeeg')
    
    cfg = [];
    cfg.tissue = lower(conductivity.tissuelabel);
    cfg.numvertices = [3000 2000 1000];
    cfg.spmversion='spm12';
    mri_bem=mri_subject;
   
    for i=1:length(conductivity.tissuelabel)
        image=zeros(size(mri_subject.anatomy));
        image(mri_subject.anatomy==i)=1;
        eval(['mri_bem.' lower(conductivity.tissuelabel{i}) '=image;']);
    end
    mri_bem = ft_convert_units(mri_bem, 'mm');
    vol = ft_prepare_mesh(cfg, mri_bem);
   
    % create the BEM system matrix
    cfg = [];
    cfg.method       = options_leadfield.method ;
    cfg.conductivity = conductivity.cond_value;
    cfg.showcallinfo = 'no';
    vol              = ft_prepare_headmodel(cfg, vol);  % in cm
    
elseif strcmpi(options_leadfield.method, 'simbio')
    tic
    % Create a hexahedral mesh..
    cfg                 = [];
    cfg.resolution      = 1; % Determines the resolution of the mesh, here resliced to 4mm..
    cfg.method          = 'hexahedral';          % tetrahedral, hexahedral mesh generation
    cfg.spmversion      = 'spm12';
    cfg.tissue          = lower(conductivity.tissuelabel);
    for i=1:length(conductivity.tissuelabel)
        image=zeros(size(mri_subject.anatomy));
        image(mri_subject.anatomy==i)=1;
        eval(['mri_subject.' lower(conductivity.tissuelabel{i}) '=image;']);
    end
    clear image;
    cfg.downsample      = options_leadfield.input_voxel_size;
    mesh             = ft_prepare_mesh(cfg, mri_subject);
    
    cfg = [];
    cfg.downsample      = options_leadfield.input_voxel_size;
    mri_ds              = ft_volumedownsample(cfg, mri_subject);
    
    cfg = [];
    cfg.method       = 'simbio';
    cfg.conductivity = conductivity.cond_value;
    cfg.tissue       = conductivity.tissuelabel;
    vol              = ft_prepare_headmodel(cfg,mesh);   % in cm
    vol.ttclc = toc;

elseif strcmpi(options_leadfield.method, 'gfdm')
    tic
    
    gm_idx = 1;
    switch nlayers
        case 12
            gm_idx = [1 2];
        case 6
            gm_idx = 1;
        case 3
            gm_idx = 1;
    end
    
    for i=1:length(conductivity.tissuelabel)
        image=zeros(size(mri_subject.anatomy));
        image(mri_subject.anatomy==i)=1;
        eval(['mri_subject.' lower(conductivity.tissuelabel{i}) '=image;']);
    end
    clear image;
    
    cfg = [];
    cfg.spmversion = 'spm12';
    cfg.downsample      = options_leadfield.input_voxel_size;
    mri_ds              = ft_volumedownsample(cfg, mri_subject);
    
    
    cfg                  = [];
    cfg.downsample       = options_leadfield.input_voxel_size;
    cfg.resolution       = [1 1 1]*cfg.downsample; % In mm
    cfg.method           = options_leadfield.method;
    cfg.type             = options_leadfield.method;
    cfg.segmentation     = mri_ds;
    cfg.conductivity     = conductivity;
    
    cfg.gm_idx           = gm_idx;
    vol                  = gfdm_prepare_headmodelMex(cfg);   % in cm 
    vol.ttclc = toc;
   
% elseif strcmpi(options_leadfield.method, 'fns')
%     
%     cfg=[];
%     cfg.method      = 'fns';
%     cfg.conductivity= [0 conductivity.cond_value]; % revised by QL, 19.01.2016
%     cfg.tissueval   = [0:1:length(conductivity.cond_value)];
%     cfg.sens        = elec;
%     cfg.tissue      = [{'bd'},conductivity.tissuelabel];
%     cfg.mri         = mri_subject;  % in cm
%     vol = net_headmodel_fns(cfg.mri, 'tissue', cfg.tissue, 'tissueval', cfg.tissueval, 'tissuecond', cfg.conductivity, 'sens', cfg.sens);
    
    %%% ARDRM - ECM, 24/04/2017

end

%% prepare source space - % ECM Changed the mri_subject for the downsampled mri_ds

mri_ds.gray=zeros(size(mri_ds.anatomy));

switch nlayers
    case 12
        mri_ds.gray(mri_ds.anatomy == 1 | mri_ds.anatomy == 2) = 1;
    case 6
        mri_ds.gray(mri_ds.anatomy == 1) = 1;
    case 3
        mri_ds.gray(mri_ds.anatomy == 1) = 1;    
end

cfg = [];
cfg.mri             = mri_ds;
cfg.grid.resolution = options_leadfield.output_voxel_size/10; % mm
cfg.threshold     =   0.5;
cfg.smooth          = 'no';
cfg.spmversion     = 'spm12';
cfg.grid.unit      = 'cm';
cfg.grid.tight     = 'yes';
subject_grid        = ft_prepare_sourcemodel(cfg);

% -----------------------------------------------------
%% Put dipole grid (template_grid) in gray matter
% Calculate Leadfield matrix (leadfield)

disp('Calculate LEAD FIELD matrix...');

tic
vol = ft_convert_units(vol, 'cm');

cfg                  = [];
cfg.ddx              = ddx;
cfg.channel          = elec.label;
cfg.vol              = vol;
cfg.elec             = elec;
cfg.grid             = subject_grid;
cfg.conductivity     = conductivity;
cfg.mri              = mri_subject;
 
leadfield       = net_prepare_leadfield(cfg);
leadfield.ttclc = toc;
leadfield_file=[ddx filesep 'anatomy_prepro_headmodel.mat'];
save(leadfield_file, '-v7.3', 'vol','leadfield');  % to save the matrix bigger than 2GB, added by QL, 04.12.2014

