clc;clear;close all;warning off


%% Set the path for the NET toolbox folder and add it to MATLAB search directory
try
    NET_folder = net('path');
    addpath( genpath(NET_folder) );   % add the path
catch
    
    ButtonName = questdlg('Please select the path for NET', ...
        'Please select the path for NET','okay','okay');
    if strcmp(ButtonName,'okay')
        NET_folder = uigetdir('/Users', 'Choose the path of NET');  % select the path of your NET
           addpath( genpath(NET_folder) );   % add the path
     end
end

p  = genpath('C:\SoliD\KU\GFDARM\Libs\fieldtrip-20180504');
addpath(p);


load('prev_data_3.mat');

[ddx,ffx,ext]=fileparts(segimg_filename);

mri_subject = ft_read_mri(segimg_filename, 'dataformat', 'nifti_spm');  % in mm
mri_subject = ft_convert_units(mri_subject, 'mm'); % in mm
%mri_subject.seg = mri_subject.anatomy;
elec = ft_read_sens(elec_filename);

cfg = [];
cfg.method = 'ortho';
ft_sourceplot(cfg, mri_subject)

seg_mri = [];
seg_mri.dim       = mri_subject.dim;
seg_mri.transform = mri_subject.transform;
seg_mri.coordsys  = 'ctf';
seg_mri.unit      = mri_subject.unit;
seg_mri.skin      = (mri_subject.anatomy == 12);
cfg             = [];
cfg.tissue      = {'skin'};
cfg.numvertices = [10000];
bnd_seg             = ft_prepare_mesh(cfg,seg_mri);
% save('seg_mri.mat', 'seg_mri');
figure
ft_plot_mesh(bnd_seg(1), 'facecolor',[0.2 0.2 0.2], 'facealpha', 1.0, 'edgecolor', [1 1 1], 'edgealpha', 0.05);


figure
ft_plot_mesh(bnd_seg(1), 'edgecolor',[0.8 0.8 0.8],'facealpha',0.5,'facecolor',[0.6 0.6 0.8]); 
hold on
% ft_plot_sens(elec_alig);
plot3(elec.chanpos(:,1), elec.chanpos(:,2), elec.chanpos(:,3), 'sk')
for a = 1:length(elec.elecpos)
    text(elec.elecpos(a,1), elec.elecpos(a,2), elec.elecpos(a,3), num2str(a))        
end

%     p  = genpath('C:\SoliD\KU\Net\NET_v2.20\external\fieldtrip');
%     addpath(p);

nlayers=max(mri_subject.anatomy(:));

options_leadfield = options.leadfield;
conductivity=load([NET_folder filesep 'template' filesep 'tissues_MNI' filesep options_leadfield.conductivity '.mat']);

cond_image=zeros(size(mri_subject.anatomy));
for i=1:nlayers
    cond_image(mri_subject.anatomy==i)=conductivity.cond_value(i);
end

% save('prev_data_models.mat', '-v7.3')

if strcmpi(options_leadfield.method, 'simbio')
    % Create a hexahedral mesh.
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
    %mri_subject = rmfield(mri_subject,'seg');
    clear image;
    cfg.downsample      = options_leadfield.input_voxel_size;
    %cfg.numvertices=5000*ones(1,length(conductivity.tissuelabel));
    mesh             = ft_prepare_mesh(cfg, mri_subject);
    %mesh.tissue = lower(conductivity.tissuelabel);
    %mesh.tissuelabel = lower(conductivity.tissuelabel)
    

% cmp = colormap(jet(5));
cmp = zeros(12,3);
cmp(1,:)  = [120 120 120]/255;
cmp(2,:)  = [230 231 232]/255;
cmp(3,:)  = [220 220 220]/255; %csf
cmp(4,:)  = [242 216 186]/255;
cmp(5,:)  = [255 181 130]/255;
cmp(6,:)  = [85 188 255]/255;
cmp(7,:)  = [159 215 159]/255;
cmp(8,:)  = [138 110 94]/255;
cmp(9,:)  = [192 104 88]/255;
cmp(10,:) = [255 244 77]/255;
cmp(11,:) = [255 181 130]/255;
cmp(12,:) = [255 181 130]/255;

%%
close all
pi = 3.20238e5;
pf = pi+5.78e3;
% pi = 3.20238e5;
% pf = pi+5.78e3;

mcub = mesh.hex(pi:pf,1:4);
col  = mesh.tissue(pi:pf);

mcol = zeros(length(col),3);
for a = 1:length(col)
    mcol(a,:) = cmp(col(a),:);
end

figure
patch('Vertices', mesh.pos, 'Faces', mcub, 'FaceColor', 'flat', 'FaceVertexCData', mcol, 'EdgeColor', 'none' );
% patch('Vertices', mesh.pos, 'Faces', mcub, 'FaceColor', 'flat', 'FaceVertexCData', mcol, 'EdgeColor', 'none' );
axis equal
view(180,-90)
cameratoolbar
axis off
    
%%
    cfg = [];
    cfg.method       = 'simbio';
    cfg.conductivity = conductivity.cond_value;
    cfg.tissue       = conductivity.tissuelabel;
    vol              = ft_prepare_headmodel(cfg,mesh);   % in cm
%    vol.segmentation = mri_subject.seg;
% save('prb_1.mat', '-v7.3');
% load('prev_data_fem.mat', 'vol');
save('vol_FEM.mat','-v7.3', 'vol_FEM')
    %%% ARDRM - ECM, 24/04/2017
elseif strcmpi(options_leadfield.method, 'gfdm')
    
    load('prev_data_models.mat');
    options_leadfield.method = 'gfdm';
    
    for i=1:length(conductivity.tissuelabel)
        image=zeros(size(mri_subject.anatomy));
        image(mri_subject.anatomy==i)=1;
        eval(['mri_subject.' lower(conductivity.tissuelabel{i}) '=image;']);
    end
    %mri_subject = rmfield(mri_subject,'seg');
    clear image;

    cfg = [];
    cfg.downsample      = options_leadfield.input_voxel_size;
    mri_ds = ft_volumedownsample(cfg, mri_subject);
    
    cfg = [];
    ft_sourceplot(cfg, mri_ds)
    
    cfg                  = [];
    cfg.downsample       = options_leadfield.input_voxel_size;
    cfg.resolution       = [1 1 1]*cfg.downsample; % In mm
    cfg.method           = options_leadfield.method;
    cfg.segmentation     = mri_ds;
    cfg.conductivity     = conductivity;
    cgf.gm_idx = [1 2];
%     cfg.conductivity_map = cond_image;
%     cfg.tensor_map       = tensor;
    vol  = gfdm_prepare_headmodel(cfg);   % in cm
    % save('prb_vol_gfdm.mat', '-v7.3');
end
% load('prb_vol_gfdm.mat');
% save('vol_FDM.mat','-v7.3', 'vol');
%% prepare source space

load('vol_FDM.mat');
load('vol_FEM.mat');

nlayers=max(mri_subject.anatomy(:));
mri_subject.gray=zeros(size(mri_subject.anatomy));

switch nlayers
    
    case 12
        mri_subject.gray(mri_subject.anatomy == 1 | mri_subject.anatomy == 2) = 1;
    case 6
        mri_subject.gray(mri_subject.anatomy == 1) = 1;
    case 3
        mri_subject.gray(mri_subject.anatomy == 1) = 1;    
end

cfg = [];
cfg.mri             = mri_subject;
cfg.grid.resolution = options_leadfield.output_voxel_size/10; % mm
cfg.threshold     =   0.5;
cfg.smooth          = 'no';
cfg.spmversion     = 'spm12';
cfg.grid.unit      = 'cm';
cfg.grid.tight     = 'yes';
subject_grid        = ft_prepare_sourcemodel(cfg);

[psa psb] = find(subject_grid.inside);
posi = subject_grid.pos(psa,:);
figure
plot3(posi(:,1), posi(:,2), posi(:,3), '*b')
axis equal


% save('prev_data_fem.mat', '-v7.3');
save('prev_data_fdm.mat', '-v7.3');

% -----------------------------------------------------
%% Put dipole grid (template_grid) in gray matter
% Calculate Leadfield matrix (leadfield)
load('prev_data_fdm.mat');

vol = ft_convert_units(vol, 'cm');

cfg                  = [];
cfg.ddx              = ddx;
cfg.channel          = elec.label;
cfg.vol              = vol;
cfg.elec             = elec;
cfg.grid             = subject_grid;
cfg.grid.tight       = 'yes';
cfg.conductivity     = conductivity;
cfg.gm_idx           = [1 2];
cfg.mri              = mri_subject;

tic;
leadfield       = net_prepare_leadfield(cfg);
tbexp = toc;
leadfield.time = tbexp;
leadfield_file=[ddx filesep 'anatomy_prepro_headmodel.mat'];
save(leadfield_file, '-v7.3', 'vol','leadfield');  % to save the matrix bigger than 2GB, added by QL, 04.12.2014

lead_fdm = leadfield;
% load('out_data_fem.mat', 'leadfield');
lead_fem = leadfield;

% save('out_data_fem.mat', '-v7.3');


% save('leads_cmp.mat', '-v7.3', 'lead_fdm', 'lead_fem')
load('leads_cmp.mat');

[nonz val] = find(lead_fdm.inside == 1);
Nnz = length(nonz);
Nec = length(lead_fdm.cfg.elec.elecpos);
L_fdm = zeros(Nnz, Nec, 3);
L_fem = L_fdm;

for a = 1:length(nonz)
    L_fdm(a,:,:) = lead_fdm.leadfield{nonz(a)};
    L_fem(a,:,:) = lead_fem.leadfield{nonz(a)};
end

mna = min(L_fem(:));
mxa = max(L_fem(:));
span_fem = mxa - mna;

mnb = min(L_fdm(:));
mxb = max(L_fdm(:));
span_fdm = mxb - mnb;

L_fdmI = L_fdm;
L_fdm = 1.8*L_fdmI*(span_fem/span_fdm);

src = 1000;
figure
subplot(2,2,1), hold on
plot(L_fdm(src,:,1), '-b')
plot(L_fem(src,:,1), '-r')
subplot(2,2,2), hold on
plot(L_fdm(src,:,2), '-b')
plot(L_fem(src,:,2), '-r')
subplot(2,2,3), hold on
plot(L_fdm(src,:,3), '-b')
plot(L_fem(src,:,3), '-r')
subplot(2,2,4), hold on
plot( sqrt(L_fdm(src,:,1).^2 + L_fdm(src,:,2).^2 + L_fdm(src,:,3).^2 ), '-b')
plot( sqrt(L_fem(src,:,1).^2 + L_fem(src,:,2).^2 + L_fem(src,:,3).^2 ), '-r')


