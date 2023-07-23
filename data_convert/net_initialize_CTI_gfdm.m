% net_initialize_CTI_gfdm.m
% Ernesto Cuartas M (ECM), 16/06/2020
% Email:  ecuartasm@gmail.com

function net_initialize_CTI_gfdm(img_filename,output_file)

if not(isnan(img_filename))

V = ft_read_mri(img_filename);
    
xdim = V.dim(1);
ydim = V.dim(2);
zdim = V.dim(3);

mat = V.transform;

A           = mat(1:3,1:3);
B           = -A*[xdim;ydim;zdim]/2;
mat(1:3,4)  = B;
V.transform = mat;

ft_write_mri_N(output_file, V, 'dataformat', 'nifti');

end