function [ leadfield ] = net_headmodel_3sphere( D, img_filename )
%
% [ leadfield ] = net_headmodel_3sphere( D, img_filename )
% description: get leadfield matrix based on fieldtrip
% last version: 21.04.2014
%
%
% D = spm_eeg_load('/Users/quanyingliu/Documents/EEG_oddball_josh/josh_oddball_4_clean.mat');
% img_filename = '/Users/quanyingliu/Documents/Zurich EEG toolbox/head_model/Josh.nii';

% 1. Caculate the leadfield matrix
% =============================================================
disp('Head Model: Get MRI positions...');
options.headmodel.resolution=2;
fid = fiducials(D);
options.mrifiducials.label = fid.fid.label(1:3);
clear fid;

[nas_head,lpa_head,rpa_head] = net_set_fiducials(img_filename);

mrifiducials.label = options.mrifiducials.label;
mrifiducials.pnt = [nas_head ; lpa_head ; rpa_head];

val = 1;

% Obtain the individual cortical mesh
% -------------------------------------------------------------------
disp('Head Model: Obtain the individual cortical mesh...');
D.inv{val}.method = 'Imaging';

D.inv = {struct('mesh', [])};
D.inv{val}.date    = strvcat(date,datestr(now,15));
D.inv{val}.comment = {'Infinity Reference'};

D.inv{val}.mesh = spm_eeg_inv_mesh(img_filename, options.headmodel.resolution);


% To register the sensor locations to the head model meshes.
%--------------------------------------------------------------------------
disp('Head Model: Register the sensor locations...');
D = net_inv_datareg(D, mrifiducials);


% Prepare head model to get VOL
%---------------------------------------------------------------------------
disp('Head Model: Prepare head model to get VOL...');
D.inv{val}.forward = struct([]);
mesh = spm_eeg_inv_transform_mesh(D.inv{val}.datareg(1).fromMNI*D.inv{val}.mesh.Affine, D.inv{val}.mesh);

% '3-Shell Sphere (experimental)'
% -----------------------------------------------------------------------
cfg                        = [];
cfg.feedback               = 'yes';
cfg.showcallinfo           = 'no';
cfg.headshape(1) = export(gifti(mesh.tess_scalp),  'ft');
cfg.headshape(2) = export(gifti(mesh.tess_oskull), 'ft');
cfg.headshape(3) = export(gifti(mesh.tess_iskull), 'ft');

% determine the convex hull of the brain, to determine the support points
pnt  = mesh.tess_ctx.vert;
tric = convhulln(pnt);
sel  = unique(tric(:));

% create a triangulation for only the support points
cfg.headshape(4).pnt = pnt(sel, :);
cfg.headshape(4).tri = convhulln(pnt(sel, :));

cfg.method = 'concentricspheres';

vol  = ft_prepare_headmodel(cfg);
vert = spm_eeg_inv_mesh_spherify(mesh.tess_ctx.vert, mesh.tess_ctx.face, 'shift', 'no');
mesh.tess_ctx.vert = vol.r(1)*vert + repmat(vol.o, size(vert, 1), 1);



% Coregister the sensor locations to the head model meshes.
% -----------------------------------------------------------------------
disp('Head Model: Coregister the sensor locations...');
headshape = vol.r(4)*vert + repmat(vol.o, size(vert, 1), 1);   % get skin model

elec = D.inv{val}.datareg(1).sensors;
chanpos_aligned = elec.chanpos;
elecpos_aligned = elec.elecpos;

figure('Name','Before Coregister');
ft_plot_vol(vol, 'facecolor', 'cortex', 'edgecolor', 'none'); alpha 0.5; camlight;
hold on; ft_plot_sens(elec,'style', 'k.');

chanpos_coreg = chanpos_aligned;
for j = 1:size(chanpos_aligned,1);
    coord = chanpos_aligned(j,:);
    dist = sum((headshape-ones(size(headshape,1),1)*coord).^2,2);
    [~,pos] = min(dist);
    chanpos_coreg(j,:)=headshape(pos,:);
end

elecpos_coreg = elecpos_aligned;
for j = 1:size(elecpos_aligned,1);
    coord = elecpos_aligned(j,:);
    dist = sum((headshape-ones(size(headshape,1),1)*coord).^2,2);
    [~,pos]=min(dist);
    elecpos_coreg(j,:)=headshape(pos,:);
end

elec_coreg=elec;
elec_coreg.chanpos=chanpos_coreg;
elec_coreg.elecpos=elecpos_coreg;

figure('Name','After Coregister');
ft_plot_vol(vol, 'facecolor', 'cortex', 'edgecolor', 'none'); alpha 0.5; camlight;
hold on; ft_plot_sens(elec_coreg,'style', 'k.');

D.inv{val}.datareg(1).sensors = elec_coreg;
D.inv{val}.datareg(1).fid_eeg.pnt = elec_coreg.chanpos;
D.inv{val}.datareg(1).fid_eeg.fid.pnt = elec_coreg.chanpos(1:3,:);
D.save;


% Caculate lead-field matrix
%-------------------------------------------------------------------
nchan = length(elec_coreg.elecpos);

vol = ft_convert_units(vol, 'cm');
elec_coreg = ft_convert_units(elec_coreg, 'cm');

% %%%%%%%%%%%%%%%%%%%%%%
% % 2. Create the grid and Calulate the Leadfield Matrix
% %%%%%%%%%%%%%%%%%%%%%%
cfg = [];
cfg.grid.xgrid  = -8:0.8:8;
cfg.grid.ygrid  = -8:0.8:8;
cfg.grid.zgrid  = -8:0.8:8;
cfg.grid.unit   = 'cm';
cfg.grid.tight  = 'yes';
cfg.inwardshift = 0;  % the negative inwardshift means an outward shift of the brain surface for inside/outside detection
cfg.vol = vol;
template_grid  = ft_prepare_sourcemodel(cfg);

disp('Calculate LEAD FIELD matrix...');
cfg = [];
cfg.channel = elec_coreg.label;
cfg.vol = vol;
cfg.elec = elec_coreg;
cfg.grid = template_grid;
cfg.grid.tight  = 'yes';
cfg.reducerank =  'no'; %                % remove the weakest orientation, 3 for EEG, 2 for MEG
cfg.normalize = 'no';                   % modify the leadfields by normalizing each column
% cfg.normalize = 'yes';               % modify the leadfields by normalizing each column
% cfg.normalizeparam  = 0.5;      % depth normalization parameter
leadfield = ft_prepare_leadfield(cfg);