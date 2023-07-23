function vol = gfdm_prepare_headmodel_5T(cfg)
% gfdm_prepare_headmodel.m
% Developed by Ernesto Cuartas, 24/04/2017
% Email:  ernesto.cuartas@kuleuven.be, ecuartasm@gmail.com
% 
% GFDM_PREPARE_HEADMODEL builds a volume conduction model from the geometry 
% of the head to estimate the propagation of electric neural activity from 
% the brain cortex. This routine calculates the stiff matrix for the finite 
% differences linear solver system. The linear system is solved for a single 
% current dipole position/moment.
%
% INPUT: The cfg argument is a structure containing:
%   cfg.resolution        a vector containing the resolution of the structural MRI in mm
%   cfg.segmentation      a 3D array containing the segmented and labeled MRI
%   cfg.conductivity      a structure with the conductivity parameters
%       conductivity.label                      a vector of strings holding the names of the segmented tissues
%       conductivity.isotropic_values           a vector containing the isotropic conductivity values
%       conductivity.skull_aniso                boolean flag (true->anisotropic skull, false->isotropic skull)
%       conductivity.skull_idx                  segmenteation label index for the skull tissue in the MRI
%       conductivity.skull_anisotropic_ratio    radial to tangential skull anisotropic ratio
%       conductivity.wm_aniso                   boolean flag (true->anisotropic WM, false->isotropic WM)
%       conductivity.wm_idx                     segmenteation label index for the WM tissue in the MRI
%       conductivity.gm_idx                     segmenteation label index for the GM tissue in the MRI
%   cfg.dti_map      a 4D array->(x,y,z,6) containing voxelwize DTI tensors (xx, xy, yy, xz, yz, zz)
%   cfg.skull_map    a 4D array->(x,y,z,6) holding the radial eigenvector (:,:,:,[1,3]) for the skull tissue
%                    position (:,:,:,4) corresponds to a 1/0 flag (1->skull tissue position, 0->No skull position)
%
% OUTPUT: structure containing the stiff matrix
%   vol.Size            vector containing the size of the FDM grid array
%   vol.VoxelSize       vector containing the voxel size of the FDM grid
%   vol.NoElements      integer value for the elements in the structural MRI label volume = Size(1)*Size(2)*Size(3)
%   vol.NoNonZeros      integer value for the Non-zero elemnts in the structural MRI label volume
%   vol.segmentation 	3D array containing the segmented and labeled MRI
%   vol.conductivity    structure holding the conductivity parameters
%   vol.unit            string with the metric units of the FDM model
%   vol.type            string with the type of finite difference coefficients
%   vol.cent_pos        vector holding the central position of the conductivity volume
%   vol.stiff           sparce 2D array for the FDM stiff matrix
%   vol.c_idx           3D array holding the Non-zero indexation
%   vol.Cidx            1D array holding the Non-zero index
%   vol.Nz              integer value holding the number of rows and no zero potential for the FDM stiff matrix
%   vol.cfg             INPUT configuration parameters
%
% EXAMPLE: example using a 5 layer segmented MRI, isotropic conductivities
%   conductivity = [];
%   conductivity.label       = { 'wm' 'gm' 'csf' 'skull' 'skin'};
%   conductivity.cond_val    = [ 0.14 0.33 1.79 0.0105 0.43 ];
%   conductivity.skull_aniso = false;
%   conductivity.skull_idx   = 4;
%   conductivity.wm_aniso    = false;
%   conductivity.wm_idx      = 1;
%   conductivity.gm_idx      = 2;
%   cfg                 = [];
%   cfg.conductivity    = conductivity;
%   cfg.resolution      = [1 1 1];
%   cfg.segmentation    = mri.img;
%   vol                 = gfdm_prepare_headmodel(cfg);

dirf = mfilename('fullpath');
filn = 'gfdm_prepare_headmodel';
dirDOS = dirf(1:length(dirf)-length(filn)-1);
folder = cd;

tmp_dir=['tmp'];
if exist(tmp_dir)
    rmdir(tmp_dir,'s');
end
mkdir(tmp_dir);

model = 'head_model';

segment = cfg.segmentation;
cond    = cfg.conductivity;

vox = cfg.resolution;
numdata = 0;
cent_pos = [floor(size(segment,1)/2), floor(size(segment,2)/2), floor(size(segment,3)/2)];
cfg.cent_pos = cent_pos;

if(cond.skull_aniso)
    s_iso_sk = cond.cond_val(cond.skull_idx);
    fac_sk = cond.skull_Arat;
    [ssk_r, ssk_t] = VolConSph(s_iso_sk, fac_sk);
    ssk_ev = [ ssk_r 0 0; 0 ssk_t 0; 0 0 ssk_t ];
    skull_map = cfg.skull_map;
end

if(cond.wm_aniso)
    dti = cfg.dti_map;
end

filename = ['tmp' filesep model '.hdr'];
fwriteid = fopen(filename,'w+');

ft_progress('init', 'text',    'Building Binary Tensors...');
for a = 1:size(segment,1)
ft_progress(a/size(segment,1), 'Building Binary Tensors %d/%d\n', a, size(segment,1));
    for b = 1:size(segment,2)
        for c = 1:size(segment,3)  
            Nlabel = segment(a,b,c);
            if(Nlabel > 0)
                label = cond.label{Nlabel};                
                numdata = numdata + 1;
                
                if(strcmp(label, 'skin'))
                    anisotropy_matrix = cond.cond_val(Nlabel)*eye(3);
                    
                elseif(strcmp(label, 'skull'))
                    if(cond.skull_aniso)
                        vec = [skull_map(a,b,c,1) skull_map(a,b,c,2) skull_map(a,b,c,3)];
                        anisotropy_matrix = single(ConTenV2(vec, ssk_ev));
                    else
                        anisotropy_matrix = cond.cond_val(Nlabel)*eye(3);                    
                    end
                    
                elseif(strcmp(label, 'csf'))
                    anisotropy_matrix = cond.cond_val(Nlabel)*eye(3);
                    
                elseif(strcmp(label, 'gm'))
                    anisotropy_matrix = cond.cond_val(Nlabel)*eye(3);
                    
                elseif(strcmp(label, 'wm'))                    
                    if( cond.wm_aniso )       
                        M = squeeze(dti(a,b,c,:));
                        DTI_T = [M(1) M(2) M(4);
                                 M(2) M(3) M(5);
                                 M(4) M(5) M(6)];                        
                        anisotropy_matrix = VolCon( DTI_T, cond.cond_val(Nlabel) );
                    else
                        anisotropy_matrix = cond.cond_val(Nlabel)*eye(3);
                    end
                end
                
                fwmodel(fwriteid, a, b, c, segment(a,b,c), anisotropy_matrix(1,1), anisotropy_matrix(2,2), anisotropy_matrix(3,3), anisotropy_matrix(1,2), anisotropy_matrix(1,3), anisotropy_matrix(2,3));
             end
         end
    end
end
ft_progress('close');
fclose(fwriteid);

cfg.fnameP = ['tmp' filesep model '_P.txt'];
cfg.name_DOS = [dirDOS filesep 'BioCalc.exe'];
cfg.Size = size(segment);
cfg.VoxelSize = vox;
cfg.NoElements = size(segment,1)*size(segment,2)*size(segment,3);
cfg.NoNonZeros = numdata;

W_modelP(cfg);

% Callback BioCalc.exe C++ routine
system(['"' cfg.name_DOS '"'  ' ' '"'  folder filesep 'tmp' '"'  ' ' '"'  folder filesep 'tmp' '"']);

vol.Size = cfg.Size;
vol.VoxelSize = cfg.VoxelSize;
vol.NoElements = cfg.NoElements;
vol.NoNonZeros = cfg.NoNonZeros;
vol.segmentation = cfg.segmentation;
vol.conductivity = cond;
vol.unit = 'mm';
vol.type = 'GFDRM';
vol.cfg = cfg;
vol.cent_pos = cent_pos;

% Set Stiffness Matrix in Matlab
[mA, c_idx, Cidx, Nz] = SetStiffnessMatrix(cfg);
vol.stiff = mA;
vol.c_idx = c_idx;
vol.Cidx = Cidx;
vol.Nz = Nz;

rmdir(tmp_dir,'s');