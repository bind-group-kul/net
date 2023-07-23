% segment individual MRI into 9 compartments
% @ Quanying
% 16.02.2015

clc; clear;

img_filename = '/Users/quanyingliu/Documents/sMRI/Ellen/rellen_T1.nii';
ZET_folder = '/Users/quanyingliu/Documents/ZET_updated';
output_filename = 't1_seg_ellen.nii';


spm_dir=spm('Dir');
clear matlabbatch
matlabbatch{1}.spm.tools.preproc8.channel.vols = {img_filename};
matlabbatch{1}.spm.tools.preproc8.channel.biasreg = 0.0001;
matlabbatch{1}.spm.tools.preproc8.channel.biasfwhm = 40;
matlabbatch{1}.spm.tools.preproc8.channel.write = [1 1];  % [1 1];
matlabbatch{1}.spm.tools.preproc8.tissue(1).tpm = {[ZET_folder filesep 'template' filesep 'masks' filesep 'phantom_csf.nii']};
matlabbatch{1}.spm.tools.preproc8.tissue(1).ngaus = 2;
matlabbatch{1}.spm.tools.preproc8.tissue(1).native = [1 0];
matlabbatch{1}.spm.tools.preproc8.tissue(1).warped = [0 0];
matlabbatch{1}.spm.tools.preproc8.tissue(2).tpm = {[ZET_folder filesep 'template' filesep 'masks' filesep 'phantom_gry.nii']};
matlabbatch{1}.spm.tools.preproc8.tissue(2).ngaus = 2;
matlabbatch{1}.spm.tools.preproc8.tissue(2).native = [1 0];
matlabbatch{1}.spm.tools.preproc8.tissue(2).warped = [0 0];
matlabbatch{1}.spm.tools.preproc8.tissue(3).tpm = {[ZET_folder filesep 'template' filesep 'masks' filesep 'phantom_wht.nii']};
matlabbatch{1}.spm.tools.preproc8.tissue(3).ngaus = 2;
matlabbatch{1}.spm.tools.preproc8.tissue(3).native = [1 0];
matlabbatch{1}.spm.tools.preproc8.tissue(3).warped = [0 0];
matlabbatch{1}.spm.tools.preproc8.tissue(4).tpm = {[ZET_folder filesep 'template' filesep 'masks' filesep 'phantom_fat.nii']};
matlabbatch{1}.spm.tools.preproc8.tissue(4).ngaus = 2;
matlabbatch{1}.spm.tools.preproc8.tissue(4).native = [1 0];
matlabbatch{1}.spm.tools.preproc8.tissue(4).warped = [0 0];
matlabbatch{1}.spm.tools.preproc8.tissue(5).tpm = {[ZET_folder filesep 'template' filesep 'masks' filesep 'phantom_ms.nii']};
matlabbatch{1}.spm.tools.preproc8.tissue(5).ngaus = 2;
matlabbatch{1}.spm.tools.preproc8.tissue(5).native = [1 0];
matlabbatch{1}.spm.tools.preproc8.tissue(5).warped = [0 0];
matlabbatch{1}.spm.tools.preproc8.tissue(6).tpm = {[ZET_folder filesep 'template' filesep 'masks' filesep 'phantom_skn.nii']};
matlabbatch{1}.spm.tools.preproc8.tissue(6).ngaus = 4;
matlabbatch{1}.spm.tools.preproc8.tissue(6).native = [1 0];
matlabbatch{1}.spm.tools.preproc8.tissue(6).warped = [0 0];
matlabbatch{1}.spm.tools.preproc8.tissue(7).tpm = {[ZET_folder filesep 'template' filesep 'masks' filesep 'phantom_skl.nii']};
matlabbatch{1}.spm.tools.preproc8.tissue(7).ngaus = 3;
matlabbatch{1}.spm.tools.preproc8.tissue(7).native = [1 0];
matlabbatch{1}.spm.tools.preproc8.tissue(7).warped = [0 0];
matlabbatch{1}.spm.tools.preproc8.tissue(8).tpm = {[ZET_folder filesep 'template' filesep 'masks' filesep 'phantom_gli.nii']};
matlabbatch{1}.spm.tools.preproc8.tissue(8).ngaus = 2;
matlabbatch{1}.spm.tools.preproc8.tissue(8).native = [1 0];
matlabbatch{1}.spm.tools.preproc8.tissue(8).warped = [0 0];
matlabbatch{1}.spm.tools.preproc8.tissue(9).tpm = {[ZET_folder filesep 'template' filesep 'masks' filesep 'phantom_mit.nii']};
matlabbatch{1}.spm.tools.preproc8.tissue(9).ngaus = 2;
matlabbatch{1}.spm.tools.preproc8.tissue(9).native = [1 0];
matlabbatch{1}.spm.tools.preproc8.tissue(9).warped = [0 0];
matlabbatch{1}.spm.tools.preproc8.tissue(10).tpm = {[ZET_folder filesep 'template' filesep 'masks' filesep 'phantom_bck.nii']};
matlabbatch{1}.spm.tools.preproc8.tissue(10).ngaus = 2;
matlabbatch{1}.spm.tools.preproc8.tissue(10).native = [0 0];
matlabbatch{1}.spm.tools.preproc8.tissue(10).warped = [0 0];
matlabbatch{1}.spm.tools.preproc8.warp.mrf = 0;
matlabbatch{1}.spm.tools.preproc8.warp.reg = 4;
matlabbatch{1}.spm.tools.preproc8.warp.affreg = 'mni';
matlabbatch{1}.spm.tools.preproc8.warp.samp = 3;
matlabbatch{1}.spm.tools.preproc8.warp.write = [1 1];

spm('defaults', 'FMRI');
spm_jobman('run', matlabbatch);



[path_f name_f ext] = fileparts(img_filename);
V = spm_vol( [path_f filesep 'C1' name_f '.nii'] );
d(:,:,:,1) = spm_read_vols( spm_vol([path_f filesep 'C1' name_f '.nii']) );
d(:,:,:,2) = spm_read_vols( spm_vol([path_f filesep 'C2' name_f '.nii']) );
d(:,:,:,3) = spm_read_vols( spm_vol([path_f filesep 'C3' name_f '.nii']) );
d(:,:,:,4) = spm_read_vols( spm_vol([path_f filesep 'C4' name_f '.nii']) );
d(:,:,:,5) = spm_read_vols( spm_vol([path_f filesep 'C5' name_f '.nii']) );
d(:,:,:,6) = spm_read_vols( spm_vol([path_f filesep 'C6' name_f '.nii']) )/2;
d(:,:,:,7) = spm_read_vols( spm_vol([path_f filesep 'C7' name_f '.nii']) );
d(:,:,:,8) = spm_read_vols( spm_vol([path_f filesep 'C8' name_f '.nii']) );
d(:,:,:,9) = spm_read_vols( spm_vol([path_f filesep 'C9' name_f '.nii']) );
d(:,:,:,10) = 0.2*ones(221, 241, 241);


[a,b] = max(d,[], 4);
b( find(b==10) ) = 0;

V.dt = [4 0];
V.pinfo = [1 0 0]';
V.fname = output_filename;
spm_write_vol(V, b);

