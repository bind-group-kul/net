function net_coregister_dwi(dwi_filename_orig,img_filename)


if exist(dwi_filename_orig,'file')


tpm_filename=[img_filename(1:end-4) '_tpm.nii'];

V=spm_vol(tpm_filename);
ntissues=length(V);

[dd,ff,ext]=fileparts(dwi_filename_orig);

Vx=spm_vol(dwi_filename_orig);
T=spm_read_vols(Vx);


[FA,ADC,Y]=net_fit_dwi(T);

Vx(1).fname=[dd filesep 'fa.nii'];
Vx(1).pinfo=[0.0000001 ; 0; 0];
Vx(1).dt=[16 0];
spm_write_vol(Vx(1),FA);

Vx(1).fname=[dd filesep 'adc.nii'];
Vx(1).pinfo=[0.0000001 ; 0; 0];
Vx(1).dt=[16 0];
spm_write_vol(Vx(1),ADC);

Vx(1).fname=[dd filesep 'md.nii'];
Vx(1).pinfo=[0.0000001 ; 0; 0];
Vx(1).dt=[16 0];
spm_write_vol(Vx(1),mean(Y,4));


clear matlabbatch;

matlabbatch{1}.spm.spatial.preproc.channel.vols = {[dd filesep 'adc.nii']};
matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.001;
matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = Inf;
matlabbatch{1}.spm.spatial.preproc.channel.write = [0 0];
for kk=1:ntissues
matlabbatch{1}.spm.spatial.preproc.tissue(kk).tpm = {[tpm_filename ',' num2str(kk)]};
matlabbatch{1}.spm.spatial.preproc.tissue(kk).ngaus = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(kk).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(kk).warped = [0 0];
end
matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;
matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 0;
matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;
matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;
matlabbatch{1}.spm.spatial.preproc.warp.write = [1 1];


spm_jobman('run',matlabbatch);

[bb_t,vox_t]=net_world_bb(img_filename);

clear matlabbatch

matlabbatch{1}.spm.util.defs.comp{1}.def = {[dd filesep  'iy_adc.nii']};
matlabbatch{1}.spm.util.defs.out{1}.push.fnames = {dwi_filename_orig};
matlabbatch{1}.spm.util.defs.out{1}.push.weight = {''};
matlabbatch{1}.spm.util.defs.out{1}.push.savedir.savesrc = 1;
matlabbatch{1}.spm.util.defs.out{1}.push.fov.bbvox.bb = bb_t;
matlabbatch{1}.spm.util.defs.out{1}.push.fov.bbvox.vox = vox_t;
matlabbatch{1}.spm.util.defs.out{1}.push.preserve = 0;
matlabbatch{1}.spm.util.defs.out{1}.push.fwhm = [0 0 0];
matlabbatch{1}.spm.util.defs.out{1}.push.prefix = 'w';

spm_jobman('run',matlabbatch);

Vx=spm_vol([img_filename(1:end-4) '_segment.nii']);
segment=spm_read_vols(Vx);

switch ntissues
    
    case 6
        
        img_wm=zeros(size(segment));
        img_wm(segment==2)=1; 
        
     case 12
        
        img_wm=zeros(size(segment));
        img_wm(segment==3 | segment==4)=1; 
             
end

Vm=spm_vol([dd filesep 'wdwi_tensor.nii']);
datam=spm_read_vols(Vm);

for i=1:length(Vm)
    Vm(i).fname=[dd filesep 'dwi_tensor_prepro.nii'];
    spm_write_vol(Vm(i),datam(:,:,:,i).*img_wm);
end


movefile([dd filesep 'iy_adc.nii'],[dd filesep 'iy_dwi_tensor.nii']);
movefile([dd filesep 'y_adc.nii'],[dd filesep 'y_dwi_tensor.nii']);
movefile([dd filesep 'adc_seg8.mat'],[dd filesep 'dwi_tensor_seg8.mat']);
delete([dd filesep 'c*adc.nii']);
delete([dd filesep 'wdwi_tensor.nii']);

Vn=spm_vol([dd filesep 'dwi_tensor_prepro.nii']);
Tn=spm_read_vols(Vn);

[FAn,ADCn,Yn]=net_fit_dwi(Tn);

Vn(1).fname=[dd filesep 'fa_prepro.nii'];
Vn(1).pinfo=[0.0000001 ; 0; 0];
Vn(1).dt=[16 0];
spm_write_vol(Vn(1),FAn);

Vn(1).fname=[dd filesep 'adc_prepro.nii'];
Vn(1).pinfo=[0.0000001 ; 0; 0];
Vn(1).dt=[16 0];
spm_write_vol(Vn(1),ADCn);

Vn(1).fname=[dd filesep 'md_prepro.nii'];
Vn(1).pinfo=[0.0000001 ; 0; 0];
Vn(1).dt=[16 0];
spm_write_vol(Vn(1),mean(Yn,4));

end