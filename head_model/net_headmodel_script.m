%% Purpose
% 1. Transform the fiducial locations from the MNI space to the individual anatomical space.
% 2. Generate a mesh structure from the anatomical image (inner skull,
% outer skull, scalp etc.)
% 3. Register the fiducials, sensors in the EEG space(source space) to the MRI space
% (target space); Sensor location to head model mesh locations.
% 4. This step is done to make sure that all the sensor positions are
% located on the skin compartment of the headmodel
% 5. Prepare the headmodel using field trip, for this you need the
% surface file exported to field trip format, provide the headmodel method
% too..
% 6. Calculate the lead-field matrix (G)

%%
clc;clear;warning off



% img_filename = '/Users/quanyingliu/Documents/sMRI/qy/qy_T1.nii';
% spm_filename = '/Users/quanyingliu/Documents/EEG_sti/qy/spm_qy_left.mat';

% img_filename = '/Users/quanyingliu/Documents/sMRI/Snow/rsnow.img';
% spm_filename = '/Users/quanyingliu/Documents/EEG_sti/snow/spm_snow_left.mat';

img_filename = '/Users/quanyingliu/Documents/sMRI/Dante/danman.img';
spm_filename = '/Users/quanyingliu/Documents/EEG_sti/dante/spm_dante_left.mat';

options.forward.method   ='bemcp'; % Type of head model - boundary element method: 'bemcp','dipoli', 'openmeeg', 'simbio','fns'

options.headmodel.cond   = [0.3300 0.0041 0.3300]; % Conductivity of different layers
options.simbio.conductivity = [0.33 0.14 1.79 0.01 0.43];   % order follows {'gray','white','csf','skull','scalp'};
options.fns.conductivity = [0.33 0.14 1.79 0.01 0.43];

options.fiducials_mni.nas=[0 ; 85 ; -30];
options.fiducials_mni.lpa=[-86 ; -16; -40];
options.fiducials_mni.rpa=[86 ; -16; -40];
options.fiducials_mni.zpoint=[0 ; 0; 40];

% =============================================================

% Step 1: Transform the fiducial locations from the MNI space to
% individual anatomical space


D = spm_eeg_load(spm_filename);% Load data
disp('Get MRI fiducial positions...');
fid = fiducials(D);
options.mrifiducials.label = fid.fid.label(1:3);

%find out the locations of fiducials in the head-space

[nas_head,lpa_head,rpa_head] = net_set_fiducials(img_filename,options.fiducials_mni);

mrifiducials.label = options.mrifiducials.label;
mrifiducials.pnt = [nas_head ; lpa_head ; rpa_head];


% =============================================================

% Step 2:Generate a mesh structure from the anatomical image (inner skull,
% outer skull, scalp etc.), done by applying a inverse transformation to a
%  template cortical mesh.


val = 1;
D.inv{val}.method = 'Imaging';

if ~isfield(D, 'inv') || ~isfield(D.inv{val}, 'comment')
    D.inv = {struct('mesh', [])};
    D.inv{val}.date    = strvcat(date,datestr(now,15));
    D.inv{val}.comment = {'net'};
else
    inv = struct('mesh', []);
    inv.comment = D.inv{val}.comment;
    inv.date    = D.inv{val}.date;
    D.inv{val} = inv;
end


resolution=3;
D.inv{val}.mesh = spm_eeg_inv_mesh(img_filename, resolution); %Size of the mesh);
D.save;


% =============================================================

% Step 3: Register the fiducials, sensors in the EEG space(source space) to the MRI space
% (target space); Sensor location to head model mesh locations.


disp('Register the sensor locations...');
D = net_inv_datareg(D, mrifiducials);

D.save;


% =============================================================

% Step 4: The following step is done to make sure that all the sensor positions are
% located on the skin compartment of the headmodel


% projecting the electrode locations over the skin
skin = export(gifti(D.inv{val}.mesh.tess_scalp),  'ft');
headshape = skin.pnt;      % Collect the vertices of the skin model

elec = D.inv{val}.datareg(1).sensors; %Get the channel and electrode positions
chanpos_aligned = elec.chanpos;
elecpos_aligned = elec.elecpos;

chanpos_coreg = chanpos_aligned;
for j = 1:size(chanpos_aligned,1);
    coord = chanpos_aligned(j,:);
    dist = sum((headshape-ones(size(headshape,1),1)*coord).^2,2);%Compute the distance from each vertices to the sensor position
    [~,pos] = min(dist);%Find the vertice that is close to the sensor position
    chanpos_coreg(j,:)=headshape(pos,:);%Now use that vertices as the sensor position
end

elecpos_coreg = chanpos_coreg;


elec_coreg=elec;
elec_coreg.chanpos=chanpos_coreg;
elec_coreg.elecpos=elecpos_coreg;


D.inv{val}.datareg(1).sensors = elec_coreg;
D.inv{val}.datareg(1).fid_eeg.pnt = elec_coreg.chanpos;
D.inv{val}.datareg(1).fid_eeg.fid.pnt = elec_coreg.chanpos(1:3,:);
D.save;

% =============================================================

% Step 5: Prepare the headmodel using field trip, for this you need the
% surface file exported to field trip format, provide the headmodel method
% too..

disp('Prepare head model to get VOL...');
D.inv{val}.forward = struct([]);
%The following step applies an affine transformation, but in reality no
%transformation is done, as the transformation matrix is diagonal; only
%helps to unfold the tess field
mesh = spm_eeg_inv_transform_mesh(D.inv{val}.datareg(1).fromMNI*D.inv{val}.mesh.Affine, D.inv{val}.mesh);

[p, f] = fileparts(mesh.sMRI);




volfile = fullfile(p, [f '_EEG_' options.forward.method '.mat']);

if ~exist(volfile, 'file')
    
    if strcmp(options.forward.method, 'bemcp') || strcmp(options.forward.method, 'dipoli') || strcmp(options.forward.method, 'openmeeg')
        
        disp('Infinity Reference: Calculating the VOL now...It is time-consuming.');
        
        vol = [];
        vol.cond    =  options.headmodel.cond;
        vol.source  = 1; % index of source compartment
        vol.skin    = 3; % index of skin surface
        % brain
        vol.bnd(1) = export(gifti(D.inv{val}.mesh.tess_iskull), 'ft');  % Export the GIFTI surface file into a fieldtrip format
        % vol.bnd(1) = export(gifti(D.inv{val}.mesh.tess_ctx), 'ft');  % revised by QL, 14.11.2014
        % skull
        vol.bnd(2) = export(gifti(D.inv{val}.mesh.tess_oskull), 'ft');
        % skin
        vol.bnd(3) = export(gifti(D.inv{val}.mesh.tess_scalp),  'ft');
        
        % create the BEM system matrix
        cfg = [];
        cfg.method = options.forward.method ;
        cfg.showcallinfo = 'no';
        
        vol = ft_prepare_headmodel(cfg, vol);
        % D.inv{val}.forward(1).mesh      = mesh.tess_ctx;
        save(volfile, 'vol');
        
        
        %The below methods are based on FEM and hence need hexahedral meshes and
        %hence the seperation..
    elseif strcmp(options.forward.method, 'simbio')
        
        %        mri = ft_read_mri(img_filename);
        %        cfg             = [];
        %        cfg.output = {'scalp', 'skull', 'gray'};
        %        cfg.label =   {'tissue_1','tissue_2','tissue_3'};
        %        % [pathstr,name,ext] = fileparts(img_filename);
        %        % cfg.name = [pathstr filesep name '_ftseg'];   % revised by QL, 14.11.2014
        %        % cfg.write = 'yes';  % c1, for the gray matter segmentation
        %        segmentation    = ft_volumesegment(cfg, mri);
        
        mri = ft_read_mri(img_filename);
        cfg             = [];
        cfg.output = {'gray','white','csf','skull','scalp'};  % revised by QL, 14.11.2014
        segmentation    = ft_volumesegment(cfg, mri);
        
        seg_i = ft_datatype_segmentation(segmentation,'segmentationstyle','indexed');     
        % mri_template.CSF = zeros(mri_template.dim);
% mri_template.CSF( find(mri_template.anatomy == 1) ) = 1;  % find gray matter
% mri_template.CSF( find(mri_template.anatomy ~= 1) ) = 0;
% mri_template.gray = zeros(mri_template.dim);
% mri_template.gray( find(mri_template.anatomy == 2) ) = 1;  % find gray matter
% mri_template.gray( find(mri_template.anatomy ~= 2) ) = 0;
% mri_template.white = zeros(mri_template.dim);
% mri_template.white( find(mri_template.anatomy == 3) ) = 1;  % find gray matter
% mri_template.white( find(mri_template.anatomy ~= 3) ) = 0;
% mri_template.fat = zeros(mri_template.dim);
% mri_template.fat( find(mri_template.anatomy == 4) ) = 1;  % find gray matter
% mri_template.fat( find(mri_template.anatomy ~= 4) ) = 0;
% mri_template.muscle = zeros(mri_template.dim);
% mri_template.muscle( find(mri_template.anatomy == 5) ) = 1;  % find gray matter
% mri_template.muscle( find(mri_template.anatomy ~= 5) ) = 0;
% mri_template.skin = zeros(mri_template.dim);
% mri_template.skin( find(mri_template.anatomy == 6) ) = 1;  % find gray matter
% mri_template.skin( find(mri_template.anatomy ~= 6) ) = 0;
% mri_template.skull = zeros(mri_template.dim);
% mri_template.skull( find(mri_template.anatomy == 7) ) = 1;  % find gray matter
% mri_template.skull( find(mri_template.anatomy ~= 7) ) = 0;
% mri_template.seg( find(mri_template.skull(:)~=0) )= 7;
% mri_template.glial = zeros(mri_template.dim);
% mri_template.glial( find(mri_template.anatomy == 8) ) = 1;  % find gray matter
% mri_template.glial( find(mri_template.anatomy ~= 8) ) = 0;
% mri_template.CC = zeros(mri_template.dim);
% mri_template.CC( find(mri_template.anatomy == 9) ) = 1;  % find gray matter
% mri_template.CC( find(mri_template.anatomy ~= 9) ) = 0;
        
        
%        segmentation.seg = zeros(segmentation.dim);
%        segmentation.seg(segmentation.gray(:))= 1; 
%        segmentation.seg(segmentation.white(:))= 2; 
%        segmentation.seg(segmentation.csf(:))= 3; 
%        segmentation.seg(segmentation.skull(:))= 4; % oskull
%        segmentation.seg(segmentation.scalp(:))= 5; % scalp: 
%   
%        segmentation.seg = reshape(segmentation.seg, segmentation.dim(1),segmentation.dim(2),segmentation.dim(3));
%        segmentation = rmfield(segmentation, 'gray');
%        segmentation = rmfield(segmentation, 'white');
%        segmentation = rmfield(segmentation, 'csf');
%        segmentation = rmfield(segmentation, 'skull');
%        segmentation = rmfield(segmentation, 'scalp');
       
        %Create a hexahedral mesh..
        cfg             = [];
        cfg.resolution = 4; % Determines the resolution of the mesh, here resliced to 4mm..
        cfg.method = 'hexahedral';          % option for hexahedral mesh generation
        hexmesh = ft_prepare_mesh(cfg, seg_i.seg);
        
        % check the validity of the mesh
        parcellation = ft_datatype_parcellation(hexmesh);
        assert(ft_datatype(parcellation,'parcellation'),'the conversion to a parcellation failed');
        
        
        cfg=[];
        cfg.method = 'simbio';
        cfg.conductivity = options.simbio.conductivity;
        vol = ft_prepare_headmodel(cfg,hexmesh);
        
        vol.segmentation = segmentation;
        
        save(volfile, 'vol');
        
        
    elseif strcmp(options.forward.method, 'fns')
        
        mri = ft_read_mri(img_filename);
        cfg             = [];
        cfg.output = {'gray','white','csf','skull','scalp'};  % revised by QL, 14.11.2014
%         cfg.write = 'yes';
%         [pathstr,name,ext] = fileparts(img_filename);
%         cfg.name = [pathstr filesep name '_ftseg'];   % the filename of segmented file
        segmentation    = ft_volumesegment(cfg, mri);
        
%        
%        segmentation.seg = zeros(segmentation.dim);
%        segmentation.seg(segmentation.gray(:))= 1; 
%        segmentation.seg(segmentation.white(:))= 2; 
%        segmentation.seg(segmentation.csf(:))= 3; 
%        segmentation.seg(segmentation.skull(:))= 4; % oskull
%        segmentation.seg(segmentation.scalp(:))= 5; % scalp: 
%   
%        segmentation.seg = reshape(segmentation.seg, segmentation.dim(1),segmentation.dim(2),segmentation.dim(3));
        seg_i = ft_datatype_segmentation(segmentation,'segmentationstyle','indexed');        


        cfg=[];
        cfg.method = 'fns';
        cfg.conductivity = options.fns.conductivity;
        cfg.tissueval = [1:9];
        cfg.sens.chanpos = elec_coreg.chanpos;
        cfg.sens.elecpos = elec_coreg.elecpos;
        cfg.sens.label = elec_coreg.label;
        cfg.sens.type = 'eeg';
        cfg.tissue = {'gray','white','csf','skull','scalp'};
        cfg.mri_filename = mri.transform;
        %cfg.unit = mri.unit;
        
        vol = ft_headmodel_fns(seg_i.seg, 'tissue', cfg.tissue, 'tissueval', cfg.tissueval, 'tissuecond', cfg.conductivity, 'sens', cfg.sens);
        
        % project the electrodes on the volume conduction model
        vol.dim = mri.dim;
        [vol, sens] = ft_prepare_vol_sens(vol, sens);
        
        vol.segmentation = segmentation;
        
    end
    
else
    load(volfile, 'vol');
end

% =============================================================

% Step 6: Create the grid and calculate the leadfield matrix

%mri256 = ft_read_mri(img_filename, 'format', 'nifti_spm');


%Convert the units to cm for use in the grid
vol = ft_convert_units(vol, 'cm');
elec_coreg = ft_convert_units(elec_coreg, 'cm');
mri256 = ft_convert_units(mri256, 'cm');



disp('Prepare source model...');

if strcmp(options.forward.method, 'bemcp') || strcmp(options.forward.method, 'dipoli') || strcmp(options.forward.method, 'openmeeg')
    
    cfg = [];
    cfg.grid.xgrid  = -10:0.4:10; %The size of the boxing grid
    cfg.grid.ygrid  = -10:0.4:10;
    cfg.grid.zgrid  = -15:0.4:15;
    cfg.grid.unit   = 'cm';
    cfg.grid.tight  = 'yes';
    cfg.inwardshift = 0;  % the negative inwardshift means an outward shift of the brain surface for inside/outside detection
    cfg.vol = vol;
    template_grid  = ft_prepare_sourcemodel(cfg); %Prepare the grid
    
    % % to get the subject specific grid based on sMRI
    % smri = ft_read_mri(img_filename, 'format', 'nifti_spm');
    % smri = ft_convert_units(smri, 'cm');
    % cfg = [];
    % cfg.grid.warpmni   = 'yes';
    % cfg.grid.template  = template_grid;
    % cfg.grid.nonlinear = 'yes'; % use non-linear normalization
    % cfg.mri = smri;
    % subject_grid = ft_prepare_sourcemodel(cfg);
    
elseif strcmp(options.forward.method, 'simbio')
    % to get the grid based on sMRI
    cfg = [];
    cfg.mri = vol.segmentation;
    cfg.grid.resolution = 0.4;  % unit: cm
    %cfg.threshold     = 0.1;
    %cfg.smooth        = 5;
    template_grid = ft_prepare_sourcemodel(cfg);
    
    
end


disp('Calculate LEAD FIELD matrix...');
cfg = [];
cfg.channel = elec_coreg.label;
cfg.vol = vol;
cfg.elec = elec_coreg;
cfg.grid = template_grid;   % or subject_grid
cfg.grid.tight  = 'yes';
cfg.reducerank =  'no'; %                % remove the weakest orientation, 3 for EEG, 2 for MEG
cfg.normalize = 'yes';               % modify the leadfields by normalizing each column
cfg.normalizeparam  = 0.5;      % depth normalization parameter
leadfield = ft_prepare_leadfield(cfg);




%Plot the leadfield positions(position of each source)
figure;       % just for test the vol, grid and sens
ft_plot_vol(vol, 'facecolor', 'cortex', 'edgecolor', 'none');alpha 0.5; camlight;
ft_plot_mesh(leadfield.pos(leadfield.inside,:));
hold on; ft_plot_sens(elec_coreg,'style', 'sk');

save([img_filename(1:end-4) '_leadfield_' options.forward.method '.mat'], 'leadfield'); %Save the leadfield matrix

%%
% Revision history:
%{
2014-05-05
    v0.1 Updated the file based on initial versions from Dante
    (Revision author : Sri).

2014-11-14
    v0.2 locate grid in gray matter
    (Revision author : Quanying).

%}

