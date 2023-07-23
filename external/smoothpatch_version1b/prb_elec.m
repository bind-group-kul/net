clear all; close all; clc

load('prev_data_3.mat');

NET_folder=net('path');

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

options_leadfield = options.leadfield;
conductivity=load([NET_folder filesep 'template' filesep 'tissues_MNI' filesep options_leadfield.conductivity '.mat']);

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
cmp(2,:) = [132 134 136]/255;
cmp(5,:) = [230 231 232]/255;
cmp(1,:) = [  0 175 239]/255; %csf
cmp(4,:) = [242 216 186]/255;
cmp(3,:) = [255 181 130]/255;
cmp(6,:) = [1 1 1];
cmp(7,:) = [1 1 0];
cmp(8,:) = [1 0 1];
cmp(9,:) = [1 0 0];
cmp(10,:) = [0 1 1];
cmp(11,:) = [0 1 0];
cmp(12,:) = [0 0 1];

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
patch('Vertices', mesh.pos, 'Faces', mcub, 'FaceColor', 'flat', 'FaceVertexCData', mcol, 'EdgeColor', [0.0 0.0 0.0] );
% patch('Vertices', mesh.pos, 'Faces', mcub, 'FaceColor', 'flat', 'FaceVertexCData', mcol, 'EdgeColor', 'none' );
axis equal
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
load('prb_1.mat');
    %%% ARDRM - ECM, 24/04/2017
elseif strcmpi(options_leadfield.method, 'afdrm')

    % if ~load_prec_lead
    cfg                 = [];
    cfg.folder          = [NET_folder filesep 'others'];
    cfg.resolution      = [1 1 1]; % In mm
    cfg.method          = 'reciprocity';
    %cfg.conductivity    = conductivity;
    %cfg.conductivity.Ntissues = length(conductivity.cond_value);
    cfg.segmentation = mri_subject.anatomy;
    cfg.conductivity_map=cond_image;
    cfg.tensor_map = tensor;
    cfg.write_binary = true;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Build the Stiffnes matrix  %%%
    %%%     C++ rutine callback    %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    vol  = afdm_prepare_headmodel(cfg);   % in cm
end





