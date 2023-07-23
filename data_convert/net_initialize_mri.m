function net_initialize_mri(img_filename,output_file)

if not(isnan(img_filename))
    
    copyfile(img_filename,output_file);
    
end

%{
V=spm_vol(img_filename);
data=spm_read_vols(V);

xdim=V(1).dim(1);
ydim=V(1).dim(2);
zdim=V(1).dim(3);

for i=1:length(V)
mat=V(i).mat;
A=mat(1:3,1:3);
B=-A*[xdim;ydim;zdim]/2;
mat(1:3,4)=B;
V(i).mat=mat;
V(i).fname=output_file;
spm_write_vol(V(i),data(:,:,:,i));
%}

end