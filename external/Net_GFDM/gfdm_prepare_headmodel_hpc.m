% afdm_prepare_headmodel.m
% Ernesto Cuartcond_image M (ECM), 24/04/2017
% Email:  ecuartcond_imagemo@unal.edu.co

function vol = gfdm_prepare_headmodel(cfg)

mribx = CalculateSegmentationBox(cfg.segmentation);

tensor_flg = 0;
if isfield(cfg, 'tensor')
    tensor_flg = 1;
    tensor = cfg.tensor_map;
end

nlayers  = max(mribx.anatomy(:));
segment  = mribx.anatomy;
cmap_flg = 0;
if isfield(cfg, 'conductivity_map')
    cmap = SetBox(cfg.conductivity_map, mribx.box);
    cond_image = cmap.anatomy;
    cmap_flg = 1;
else
    cond_image = zeros(size(segment));
    for i=1:nlayers
        cond_image(segment == i) = cfg.conductivity.cond_value(i);
    end    
    cmap_flg = 0;
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
                        anisotropy_matrix=cond_image(a,b,c)*eye(3);
                    end
                else
                    anisotropy_matrix=(cond_image(a,b,c)+1e-6)*eye(3);
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
% folder = cd;


% if ispc
%     cfg.name_DOS = [dirDOS filesep 'BioCalc.exe'];
% elseif ismac
%     cfg.name_DOS = [dirDOS filesep 'BioCalc'];
% end
cfg.name_DOS = [dirDOS filesep 'BioCalc.exe'];

cfg.fnameP = [cfg.folder filesep 'tmp' filesep model '_P.txt'];
cfg.Size = size(cond_image);
cfg.VoxelSize = vox;
cfg.NoElements = size(cond_image,1)*size(cond_image,2)*size(cond_image,3);
cfg.NoNonZeros = numdata;

W_modelP(cfg);

% Callback BioCalc.exe C++ routine
% system([cfg.name_DOS ' ' cfg.folder filesep 'tmp' ' ' cfg.folder filesep 'tmp' ]);
system(['"' cfg.name_DOS '"' ' ' '"' cfg.folder filesep 'tmp' '"' ' ' '"' cfg.folder filesep 'tmp' '"']);

vol.Size             = cfg.Size;
vol.VoxelSize        = cfg.VoxelSize;
% vol.NoElements       = cfg.NoElements;
% vol.NoNonZeros       = cfg.NoNonZeros;
% vol.segmentation     = cfg.segmentation;
vol.box              = mribx;
if(cmap_flg),   vol.conductivity_map = cmap; 
else,           vol.conductivity     = cfg.conductivity;  vol.conductivity.cond_image = cond_image; end
if(tensor_flg), vol.tensor_map       = cfg.tensor_map; end
vol.unit     = cfg.segmentation.unit;
% vol.type     = 'GFDARM';
vol.cent_pos = cent_pos;
vol.method   = cfg.method;
vol.type     = cfg.type;

% Set Stiffness Matrix in Matlab
% if ispc
%     [mA, c_idx, Cidx, Nz] = SetStiffnessMatrix(cfg);
% elseif ismac
%     [mA, c_idx, Cidx, Nz] = SetStiffnessMatrixMac(cfg);
% end
[mA, c_idx, Cidx, Nz] = SetStiffnessMatrix(cfg);

vol.stiff = mA;
vol.c_idx = c_idx;
vol.Cidx = Cidx;
% vol.gm_idx;
vol.Nz = Nz;
vol.cfg      = cfg;
vol.gm_idx = cfg.gm_idx;

rmdir(tmp_dir,'s');
