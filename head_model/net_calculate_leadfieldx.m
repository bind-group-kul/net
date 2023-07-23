function net_calculate_leadfield(segimg_filename,dwi_filename,elec_filename,options_leadfield)

NET_folder=net('path');
filsep = '/';

[ddx,ffx,ext]=fileparts(segimg_filename);

mri_subject = ft_read_mri(segimg_filename, 'dataformat', 'nifti_spm');  % in mm
mri_subject = ft_convert_units(mri_subject, 'mm'); % in mm
mri_subject.seg = mri_subject.anatomy;
elec=ft_read_sens(elec_filename);

if not(isempty(dwi_filename))
    
    Vx=spm_vol(dwi_filename);
    tensor=spm_read_vols(Vx);
    
end


disp(['NET - Get vol with ' options_leadfield.method ' method...']);

conductivity=load([NET_folder filesep 'template' filesep 'tissues_MNI' filesep options_leadfield.conductivity '.mat']);

if strcmp(options_leadfield.method, 'bemcp') || strcmp(options_leadfield.method, 'dipoli') || strcmp(options_leadfield.method, 'openmeeg')
    
    cfg = [];
    cfg.tissue = {'tissue 1','tissue 2','tissue 3'};
    cfg.numvertices = [3000 2000 1000];
    cfg.spmversion='spm12';
    mri_bem=mri_subject;
    mri_bem.seg(mri_bem.seg==nlayers)=nlayers-1;
    vol = ft_prepare_mesh(cfg, mri_bem);
    
    % create the BEM system matrix
    cfg = [];
    cfg.method       = options_leadfield.method ;
    cfg.showcallinfo = 'no';
    vol              = ft_prepare_headmodel(cfg, vol);  % in cm
    vol.segmentation = mri_subject.seg;
    
    
    
elseif strcmp(options_leadfield.method, 'simbio')
    
    % Create a hexahedral mesh..
    cfg                 = [];
    cfg.resolution      = 1; % Determines the resolution of the mesh, here resliced to 4mm..
    cfg.method          = 'hexahedral';          % tetrahedral, hexahedral mesh generation
    mesh             = ft_prepare_mesh(cfg, mri_subject);
%     cfg.spmversion      = 'spm12';
    cfg.tissue          = lower(conductivity.tissuelabel);
    for i=1:length(conductivity.tissuelabel)
        image=zeros(size(mri_subject.anatomy));
        image(mri_subject.anatomy==i)=1;
        eval(['mri_subject.' lower(conductivity.tissuelabel{i}) '=image;']);
    end
    clear image;
    cfg.downsample      = 3;
    %cfg.numvertices=5000*ones(1,length(conductivity.tissuelabel));
    
    %mesh.tissue = lower(conductivity.tissuelabel);
    %mesh.tissuelabel = lower(conductivity.tissuelabel);
    
    cfg = [];
    cfg.method       = 'simbio';
    cfg.spmversion      = 'spm12';
    cfg.conductivity = conductivity.cond_value;
    cfg.tissue       = conductivity.tissuelabel;
    vol              = ft_prepare_headmodel(cfg,mesh);   % in cm
    vol.segmentation = mri_subject.seg;
    
    
elseif strcmp(options_leadfield.method, 'fns')
    
    cfg=[];
    cfg.method      = 'fns';
    cfg.conductivity= [0 conductivity.cond_value]; % revised by QL, 19.01.2016
    cfg.tissueval   = [0:1:length(conductivity.cond_value)];
    cfg.sens        = elec;
    cfg.tissue      = [{'bd'},conductivity.tissuelabel];
    cfg.mri         = mri_subject;  % in cm
    vol = net_headmodel_fns(cfg.mri, 'tissue', cfg.tissue, 'tissueval', cfg.tissueval, 'tissuecond', cfg.conductivity, 'sens', cfg.sens);
    
    %%% ARDRM - ECM, 24/04/2017
elseif strcmp(options_leadfield.method, 'afdrm')

    
    Ntissues=length(conductivity.cond_value);
    cond_image=zeros(size(mri_subject.seg));
    for i=1:Ntissues
        cond_image(mri_subject.seg==i)=conductivity.cond_value(i);
    end
    
    % if ~load_prec_lead
    cfg                 = [];
    cfg.folder          = [NET_folder filesep 'others'];
    cfg.resolution      = [1 1 1]; % In mm
    cfg.method          = 'reciprocity';
    %cfg.conductivity    = conductivity;
    %cfg.conductivity.Ntissues = length(conductivity.cond_value);
    cfg.segmentation = mri_subject.seg;
    cfg.conductivity_map=cond_image;
    cfg.tensor_map = tensor;
    cfg.write_binary = true;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Build the Stiffnes matrix  %%%
    %%%     C++ rutine callback    %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    vol              = afdm_prepare_headmodel(cfg);   % in cm

    %    end
    
    
end

%% prepare source space

mri_subject.gray=zeros(size(mri_subject.anatomy));
nlayers=max(mri_subject.anatomy(:));

switch nlayers
    
    case 12
        
        mri_subject.gray(mri_subject.seg == 1 | mri_subject.seg == 2) = 1;
        
    case 6
        
        mri_subject.gray(mri_subject.seg == 1) = 1;
        
    case 4
        
        mri_subject.gray(mri_subject.seg == 1) = 1;
        
end


cfg = [];
cfg.mri             = mri_subject;
cfg.grid.resolution = options_leadfield.output_voxel_size/10; % unit: cm
cfg.threshold     =   0.1;
cfg.smooth          = 'no';
subject_grid        = ft_prepare_sourcemodel(cfg);
vol = ft_convert_units(vol, 'cm');

% -----------------------------------------------------
%% Put dipole grid (template_grid) in gray matter
% Calculate Leadfield matrix (leadfield)

disp('Calculate LEAD FIELD matrix...');
%         save('prep_elec_data.mat')
%         load('prep_elec_data.mat')
if strcmp(options_leadfield.method, 'afdrm')

        cfg             = [];
        cfg.ddx         = ddx;
        cfg.channel     = elec.label;
        cfg.vol         = vol;
        cfg.elec        = elec;
        cfg.elec.nelec  = length(elec.elecpos);
        cfg.grid        = subject_grid;
        cfg.solver.tol  = 1e-10;
        cfg.solver.maxit  = 500;
        cfg.grid.tight    = 'yes';
        cfg.conductivity  = conductivity;
        cfg.conductivity.map = cond_image;
%        cfg.reducerank      = options_leadfield.reducerank;	    % remove the weakest orientation, 3 for EEG, 2 for MEG
%        cfg.normalize       = options_leadfield.normalize;  	% modify the leadfields by normalizing each column
%        cfg.normalizeparam  = options_leadfield.normalizeparam;	% depth normalization parameter
        cfg.mri    = mri_subject;
        cfg.folder = [NET_folder filsep 'others'];
        
        % Projecting electrodes to the Volume, ensuring that every single 
        % electrode voxel is surrounded by Non Zero data

        cfg.elec_OK = afdm_prepare_elecs( cfg );
        
        % Precalculate and store Leadfields
        cfg.save_lead = 1;
        cfg.save_lead_pair = 0;
        cfg.gmask = 'source';
        lead = afdm_precalculate_leadsM( cfg );

    
    leadfield = afdm_calculate_pots(lead, lead.grid);

    else
    
    cfg             = [];
    cfg.channel     = elec.label;
    cfg.vol         = vol;
    cfg.elec        = elec;
    cfg.grid        = subject_grid;   % or subject_grid 
    cfg.grid.tight  = 'yes';
    cfg.reducerank  = options_leadfield.reducerank;	% remove the weakest orientation, 3 for EEG, 2 for MEG
    cfg.normalize       = options_leadfield.normalize;  	% modify the leadfields by normalizing each column
    cfg.normalizeparam  = options_leadfield.normalizeparam;	% depth normalization parameter
    
    leadfield       = ft_prepare_leadfield(cfg);
    
    end
    
    leadfield_file=[ddx filesep 'anatomy_prepro_headmodel.mat'];
    save(leadfield_file, '-v7.3', 'vol','leadfield');  % to save the matrix bigger than 2GB, added by QL, 04.12.2014



