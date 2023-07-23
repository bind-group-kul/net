function net_warp(input_images,def_field)


output_res=3;

smooth_fwhm=8;


[dd,ff,ext]=fileparts(input_images);

filelist=dir(input_images);

images=cell(length(filelist)+1,1);
images2=cell(length(filelist)+1,1);
for i=1:length(filelist)
    
    images{i,1}=[dd filesep filelist(i).name];
    images2{i,1}=[dd filesep 'r' filelist(i).name];
    
end

Vx=spm_vol([dd filesep filelist(1).name ',1']);
datax=spm_read_vols(Vx);
cortex=zeros(size(datax));
cortex(abs(datax)>0)=1;
Vx.fname=[dd filesep 'cortex.nii'];
spm_write_vol(Vx,cortex);

images{length(filelist)+1,1}=[dd filesep 'cortex.nii'];
images2{length(filelist)+1,1}=[dd filesep 'rcortex.nii'];


spm('Defaults','fMRI');

net_path=net('dir');

tpm_image_mni=[net_path filesep 'template' filesep 'tissues_MNI' filesep 'eTPM12.nii']; 

% tpm_image_mni=[net_path filesep 'template' filesep 'tissues_MNI' filesep 'eTPM6.nii']; 

pos=strfind(dd,'eeg_source');

tpm_image_ind=[dd(1:pos-2) filesep 'mr_data' filesep 'anatomy_prepro_tpm.nii']; 


bb=net_world_bb([tpm_image_mni ',1']);


Vx=spm_vol([tpm_image_mni ',1']);
data=spm_read_vols(Vx);
Vx(1).fname=[dd filesep 'mask_mni.nii'];
spm_write_vol(Vx(1),data);

clear matlabbatch;

matlabbatch{1}.spm.util.defs.comp{1}.def = {def_field};
matlabbatch{1}.spm.util.defs.out{1}.push.fnames = images;
matlabbatch{1}.spm.util.defs.out{1}.push.weight = {''};
matlabbatch{1}.spm.util.defs.out{1}.push.savedir.saveusr = {dd};
matlabbatch{1}.spm.util.defs.out{1}.push.fov.bbvox.bb = bb;
matlabbatch{1}.spm.util.defs.out{1}.push.fov.bbvox.vox = [output_res output_res output_res];
matlabbatch{1}.spm.util.defs.out{1}.push.preserve = 0;
matlabbatch{1}.spm.util.defs.out{1}.push.fwhm = [smooth_fwhm smooth_fwhm smooth_fwhm];
matlabbatch{1}.spm.util.defs.out{1}.push.prefix = 'w';


spm_jobman('run', matlabbatch);

clear matlabbatch;

matlabbatch{1}.spm.spatial.coreg.write.ref = {[dd filesep 'w' filelist(i).name ',1']};
matlabbatch{1}.spm.spatial.coreg.write.source = {[dd filesep 'mask_mni.nii']};
matlabbatch{1}.spm.spatial.coreg.write.roptions.interp = 0;
matlabbatch{1}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.coreg.write.roptions.mask_mni = 0;
matlabbatch{1}.spm.spatial.coreg.write.roptions.prefix = 'r';

spm_jobman('run', matlabbatch);


Vy=spm_vol([dd filesep 'rmask_mni.nii']);
maskx=spm_read_vols(Vy);
mask_new=zeros(size(maskx));
mask_new(maskx>0.3)=1;

Vx=spm_vol([dd filesep 'wcortex.nii']);
density=spm_read_vols(Vx);
%density(density<0.2)=0;
%density=sqrt(density);

if not(isdir([dd filesep 'mni']))
    mkdir([dd filesep 'mni']);
end

for i=1:length(filelist)
V=spm_vol([dd filesep 'w' filelist(i).name]);
%data=spm_read_vols(V);
for kk=1:length(V)
    data=spm_read_vols(V(kk));
    V(kk).fname=[dd filesep 'mni' filesep filelist(i).name(1:end-4) '_mni.nii'];
    %spm_write_vol(V(kk),mask_mni_new.*(data./density));
    %spm_write_vol(V(kk),mask_mni_new.*(data./density));
    %spm_write_vol(V(kk),data);
    %spm_write_vol(V(kk),mask_mni_new.*data);
    spm_write_vol(V(kk),(data./density).*mask_new);
end
delete([dd filesep 'w' filelist(i).name]);
end


if not(isdir([dd filesep 'ind']))
    mkdir([dd filesep 'ind']);
end


Va=spm_vol(tpm_image_ind);
tpm=spm_read_vols(Va);
if length(Va)>6
    tpm=sum(tpm(:,:,:,1:2),4);
else
    tpm=tpm(:,:,:,1);
end

Vb=Va(1);
Vb.fname=[dd filesep 'mask_ind.nii'];
spm_write_vol(Vb,tpm);

[bb,res]=net_world_bb([dd filesep 'mask_ind.nii']);
resize_img([dd filesep 'mask_ind.nii'], [output_res output_res output_res], bb);


clear matlabbatch;

matlabbatch{1}.spm.spatial.coreg.write.ref = {[dd filesep 'imask_ind.nii']};
matlabbatch{1}.spm.spatial.coreg.write.source = images;
matlabbatch{1}.spm.spatial.coreg.write.roptions.interp = 0;
matlabbatch{1}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.coreg.write.roptions.mask_mni = 0;
matlabbatch{1}.spm.spatial.coreg.write.roptions.prefix = 'r';

spm_jobman('run', matlabbatch);


clear matlabbatch;


matlabbatch{1}.spm.spatial.smooth.data = images2;
matlabbatch{1}.spm.spatial.smooth.fwhm = [smooth_fwhm smooth_fwhm smooth_fwhm];
matlabbatch{1}.spm.spatial.smooth.dtype = 0;
matlabbatch{1}.spm.spatial.smooth.im = 0;
matlabbatch{1}.spm.spatial.smooth.prefix = 's';


spm_jobman('run', matlabbatch);


Vy=spm_vol([dd filesep 'imask_ind.nii']);
maskx=spm_read_vols(Vy);
mask_new=zeros(size(maskx));
mask_new(maskx>0.3)=1;

Vx=spm_vol([dd filesep 'srcortex.nii']);
density=spm_read_vols(Vx);


for i=1:length(filelist)
V=spm_vol([dd filesep 'sr' filelist(i).name]);
for kk=1:length(V)
    data=spm_read_vols(V(kk));
    V(kk).fname=[dd filesep 'ind' filesep filelist(i).name(1:end-4) '_ind.nii'];
    spm_write_vol(V(kk),(data./density).*mask_new);
end
delete([dd filesep 'sr' filelist(i).name]);
delete([dd filesep 'r' filelist(i).name]);
delete([dd filesep filelist(i).name]); % delete images in the original folder (not ind nor mni)
end




delete([dd filesep '*mask_*.nii']);
delete([dd filesep '*cortex.nii']);

