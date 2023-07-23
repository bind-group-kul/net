% gfdm_prepare_headmodel.m
% Ernesto Cuartas M (ECM), 06/04/2017
% Updated: 02/06/2020
% Email:  ecuartasm@gmail.com

function vol = gfdm_prepare_headmodel(cfg)
% gfdm_prepare_headmodel.m
% Ernesto Cuartas M (ECM), 06/04/2017
% Updated: 02/06/2020
% Email:  ecuartasm@gmail.com
% 
% GFDM_PREPARE_HEADMODEL calculates the sparse stiffness matrix to solve the 
% linear system. The function also finds the boundary box enclosing the head 
% volume, labeling the voxel positions excluding the air. The output is a 
% structure including the stiffness matrix and the boundary box array for 
% the head volume. The gFDM method allows arbitraries voxel-size, a rectangular 
% 1mm^3 voxel size is not mandatory, and the user can define not rectangular 
% voxels. Also, using a down-sampling function (as �ft_volumedownsample�) 
% the forward calculations can be drastically reduced using a low-resolution 
% head volume. In the cfg structure, one can choose between a labeled map, 
% where the cond_value array corresponds to the isotropic conductivities for 
% the N layers in the MRI segmentation, or a CTI including a conductivity 
% tensor definition for every single voxel in the head volume.
% 
% INPUT: ( cfg ) The cfg argument is a structure containing:
% cfg.downsample               = downsample value (integer);
% cfg.resolution               = voxel size in mm; % In mm
% cfg.segmentation             = structural segmented MRI;
% cfg.conductivity             = structure holding the conductivity paremeters;
%     conductivity.tissuelabel = array holding the tissue names;
%     conductivity.cond_value  = vector holding the tissue conductivity values;
% cfg.conductivity_map         = (optional) structural CTI isotropic map;
% cfg.gm_idx                   = label value of the grey matter;
% vol  = gfdm_prepare_headmodel(cfg); 
% 
% OUTPUT: ( vol ) structure containing the stiff matrix
% vol.box          = structure holding the boundary box;
% vol.stiff        = sparse stiffness matrix
% vol.c_idx        = 3D array holding the non-zero index.
% vol.Cidx         = 1D array holding the non-zero index.
% vol.Nz           = Number of non-zeros.
% 
% EXAMPLE: example using a CTI map
% cfg                  = [];
% cfg.resolution       = [1 1 1];
% cfg.segmentation     = segmented_mri;
% cfg.conductivity_map = CTI;
% cfg.gm_idx           = 2;
% vol = gfdm_prepare_headmodel(cfg);

mribx = CalculateSegmentationBox(cfg.segmentation);

nlayers  = max(mribx.anatomy(:));
segment  = mribx.anatomy;

cond_image = zeros(size(segment));
for i=1:nlayers
    cond_image(segment == i) = cfg.conductivity.cond_value(i);
end

cmap_flg   = 0;
tensor_flg = 0;
cti_flg    = 0;
if isfield(cfg, 'conductivity_map')
    cmap = SetBox(cfg.conductivity_map, mribx.box);
    cond_image = cmap.anatomy;
    cmap_flg = 1;
elseif isfield(cfg, 'tensor')
    tensor_flg = 1;
    tensor = cfg.tensor_map;  
elseif isfield(cfg, 'CTI')
    cti_n   = SetBoxCTI(cfg.CTI, mribx.box);
    cti_flg = 1;
    cti_tensor = cti_n.anatomy;
else
    cmap_flg   = 0;
    tensor_flg = 0;
    cti_flg    = 0;
end

NET_folder=net('path');

cfg.folder = [NET_folder filesep 'others'];

tmp_dir=[cfg.folder filesep 'tmp'];
if exist(tmp_dir,'dir')
    rmdir(tmp_dir,'s');
end
mkdir(tmp_dir);

model = 'head_model';

mask = zeros(size(segment));
switch nlayers    
    case 4        
        mask(segment==1)=1;
    case 6        
        mask(segment==2)=1;
    case 12           
        mask(segment==3)=1;
        mask(segment==4)=1;        
end

vox = cfg.resolution;
numdata = 0;
cent_pos = [floor(size(segment,1)/2), floor(size(segment,2)/2), floor(size(segment,3)/2)];
cfg.cent_pos = cent_pos;

    filename = [cfg.folder filesep 'tmp' filesep model '.hdr'];
    fwriteid = fopen(filename,'w+');

    M = zeros(1,6);
ft_progress('init', 'text',    'Building Binary Tensors...');
for a = 1:size(segment,1)
ft_progress(a/size(segment,1), 'Building Binary Tensors %d/%d\n', a, size(segment,1));
    for b = 1:size(segment,2)
        for c = 1:size(segment,3)  
            if(segment(a,b,c))
                numdata = numdata + 1;
                if(tensor_flg)
                    M = squeeze(tensor(a,b,c,:));                    
                    % Anisotropi white matter
                    if( mask(a,b,c) == 1 && abs(sum(M))> 0)
                        DTI = [M(1) M(2) M(3);
                               M(2) M(4) M(5);
                               M(3) M(5) M(6)];                        
                        anisotropy_matrix = VolCon( DTI, cond_image(a,b,c) );
                    else
                        anisotropy_matrix = cond_image(a,b,c)*eye(3);
                    end
                elseif(cti_flg)
                    M = squeeze(cti_tensor(a,b,c,:));
                    if(abs(sum(M))> 0)
                        Tnsr = [M(1) M(2) M(3);
                                M(2) M(4) M(5);
                                M(3) M(5) M(6)];
                        anisotropy_matrix = Tnsr;
                    else
                        anisotropy_matrix = cond_image(a,b,c)*eye(3);
                    end
                else
                    anisotropy_matrix = (cond_image(a,b,c)+1e-6)*eye(3);
                end
                fwmodel(fwriteid, a, b, c, segment(a,b,c), anisotropy_matrix(1,1), anisotropy_matrix(2,2), anisotropy_matrix(3,3), anisotropy_matrix(1,2), anisotropy_matrix(1,3), anisotropy_matrix(2,3));
            end
         end
    end
end
ft_progress('close');
fclose(fwriteid);

dirf = mfilename('fullpath');
filn = 'gfdm_prepare_headmodel';
dirDOS = dirf(1:length(dirf)-length(filn)-1);

% l-156
if ispc
    cfg.name_DOS = [dirDOS filesep 'BioCalc.exe'];
elseif ismac    
    cfg.name_DOS = [dirDOS filesep 'BioCalc'];
elseif isunix
    cfg.name_DOS = [dirDOS filesep 'BioCalc.unix'];
end
%cfg.name_DOS = [dirDOS filesep 'BioCalc.exe'];

cfg.fnameP = [cfg.folder filesep 'tmp' filesep model '_P.txt'];
cfg.Size = size(segment);
cfg.VoxelSize = vox;
cfg.NoElements = size(segment,1)*size(segment,2)*size(segment,3);
cfg.NoNonZeros = numdata;

W_modelP(cfg);

% Callback BioCalc.exe C++ routine
% system([cfg.name_DOS ' ' cfg.folder filesep 'tmp' ' ' cfg.folder filesep 'tmp' ]);

% l-177
if isunix
    unix(['"' cfg.name_DOS '"' ' ' '"' cfg.folder filesep 'tmp' '"' ' ' '"' cfg.folder filesep 'tmp' '"']);
else
    system(['"' cfg.name_DOS '"' ' ' '"' cfg.folder filesep 'tmp' '"' ' ' '"' cfg.folder filesep 'tmp' '"']);
end

vol.Size             = cfg.Size;
vol.VoxelSize        = cfg.VoxelSize;

vol.box              = mribx;
if(cmap_flg)   
    vol.conductivity_map = cmap; 
elseif(tensor_flg)
    vol.tensor_map       = cfg.tensor_map;
elseif(cti_flg)
    vol.CTI = cti_n;
else           
    vol.conductivity     = cfg.conductivity;  
    vol.conductivity.cond_image = cond_image; 
end
vol.unit     = cfg.segmentation.unit;
vol.cent_pos = cent_pos;
vol.method   = cfg.method;
vol.type     = cfg.type;

% l-203
if ispc
    [mA, c_idx, Cidx, Nz] = SetStiffnessMatrix(cfg);
elseif isunix
    [mA, c_idx, Cidx, Nz] = SetStiffnessMatrixMac(cfg);
elseif ismac
    [mA, c_idx, Cidx, Nz] = SetStiffnessMatrixMac(cfg);
end

vol.stiff = mA;
vol.c_idx = c_idx;
vol.Cidx = Cidx;
% vol.gm_idx;
vol.Nz = Nz;
vol.cfg      = cfg;
vol.gm_idx = cfg.gm_idx;

rmdir(tmp_dir,'s');
