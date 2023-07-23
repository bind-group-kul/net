% afdm_prepare_headmodel.m
% Ernesto Cuartcond_image M (ECM), 24/04/2017
% Email:  ecuartcond_imagemo@unal.edu.co

function vol = gfdm_prepare_headmodel_Sph(cfg)

tmp_dir=[cfg.folder '\' 'tmp'];
if exist(tmp_dir)
    rmdir(tmp_dir,'s');
end
mkdir(tmp_dir);

model = 'head_model';

segment = cfg.segmentation;
cond    = cfg.cond;

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
    s_iso_wm = cond.cond_val(cond.wm_idx);
    fac_wm = cond.wm_Arat;
    [swm_r, swm_t] = VolConSph(s_iso_wm, fac_wm);
    swm_ev = [ swm_r 0 0; 0 swm_t 0; 0 0 swm_t ];
    wm_map = cfg.wm_map;
end

data_w = cfg.write_binary;

if data_w
    filename = [cfg.folder filesep 'tmp' filesep model '.hdr'];
    fwriteid = fopen(filename,'w+');
end

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
                        vec = [wm_map(a,b,c,1) wm_map(a,b,c,2) wm_map(a,b,c,3)];
                        anisotropy_matrix = single(ConTenV2(vec, swm_ev));
                    else
                        anisotropy_matrix = cond.cond_val(Nlabel)*eye(3);
                    end
                    
                elseif(strcmp(label, 'air'))
                    anisotropy_matrix = cond.cond_val(Nlabel)*eye(3);
                end
                
                if data_w
                    fwmodel(fwriteid, a, b, c, segment(a,b,c), anisotropy_matrix(1,1), anisotropy_matrix(2,2), anisotropy_matrix(3,3), anisotropy_matrix(1,2), anisotropy_matrix(1,3), anisotropy_matrix(2,3));
                end
                
             end
         end
    end
end
ft_progress('close');
if data_w
    fclose(fwriteid);
end

cfg.fnameP = [cfg.folder filesep 'tmp' filesep model '_P.txt'];
cfg.name_DOS = ['D:\D\AFDRM\Net_AFDRM' filesep 'BioCalc.exe'];
cfg.Size = size(segment);
cfg.VoxelSize = vox;
cfg.NoElements = size(segment,1)*size(segment,2)*size(segment,3);
cfg.NoNonZeros = numdata;

W_modelP(cfg);

% Callback BioCalc.exe C++ routine
system(['"' cfg.name_DOS '"' ' ' '"' cfg.folder filesep 'tmp' '"' ' ' '"' cfg.folder filesep 'tmp' '"']);

vol.Size = cfg.Size;
vol.VoxelSize = cfg.VoxelSize;
vol.NoElements = cfg.NoElements;
vol.NoNonZeros = cfg.NoNonZeros;
vol.segmentation = cfg.segmentation;
vol.cond = cond;
vol.unit = 'mm';
vol.type = 'AFDRM';
vol.cfg = cfg;
vol.cent_pos = cent_pos;

% Set Stiffness Matrix in Matlab
[mA, c_idx, Cidx, Nz] = SetStiffnessMatrix(cfg);
vol.stiff = mA;
vol.c_idx = c_idx;
vol.Cidx = Cidx;
vol.Nz = Nz;
% vol.conditional = condest(mA);

rmdir(tmp_dir,'s');