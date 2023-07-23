function net_initialize_CTI(img_filename,output_file)

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