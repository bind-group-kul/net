function [nas_head, lpa_head, rpa_head, zpoint_head] = net_set_fiducials(img_filename, fiducials_mni)

nas_mni=fiducials_mni.nas;
lpa_mni=fiducials_mni.lpa;
rpa_mni=fiducials_mni.rpa;
zpoint_mni=fiducials_mni.zpoint;


spm_dir=spm('Dir');


sn_filename = [img_filename(1:end-4) '_sn.mat'];

% Running 'Normalise: Estimate'
% Smoothing by 0 & 4mm..
% Coarse Affine Registration..
% Fine Affine Registration..
% Saving Parameters..
spm_jobman('initcfg');

clear matlabbatch;
matlabbatch{1}.spm.spatial.normalise.estwrite.subj.source = {img_filename};
matlabbatch{1}.spm.spatial.normalise.estwrite.subj.wtsrc = '';
matlabbatch{1}.spm.spatial.normalise.estwrite.subj.resample = {img_filename};
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.template = { [spm_dir filesep 'templates' filesep 'T1.nii'] };
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.weight = '';
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.smosrc = 8;
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.smoref = 0;
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.regtype = 'mni';
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.cutoff = 25;
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.nits = 0;
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.reg = 1;
matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.preserve = 0;
matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.bb = [-78 -112 -70; 78 76 85];
matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.vox = [2 2 2];
matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.interp = 1;
matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.prefix = 'w';


% matlabbatch{1}.spm.spatial.normalise.estwrite.subj.vol = {img_filename};   % using spm12, revised by QL, 17.12.2014
% matlabbatch{1}.spm.spatial.normalise.estwrite.subj.resample = {img_filename};
% matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.biasreg = 0.0001;
% matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.biasfwhm = 60;
% matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.tpm = {[spm_dir filesep 'tpm' filesep 'TPM.nii'};
% matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.affreg = 'mni';
% matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.reg = [0 0.001 0.5 0.05 0.2];
% matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.fwhm = 0;
% matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.samp = 3;
% matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.bb = [-78 -112 -70
%                                                              78 76 85];
% matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.vox = [2 2 2];
% matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.interp = 1;

spm('defaults', 'EEG');
spm_jobman('run', matlabbatch);


load( sn_filename );

Q = VG.mat*inv(Affine)/VF.mat;
M = inv(Q);

nas_head = (M(1:3,1:3)*nas_mni(1:3)+M(1:3,4))';  % in mm
lpa_head = (M(1:3,1:3)*lpa_mni(1:3)+M(1:3,4))';
rpa_head = (M(1:3,1:3)*rpa_mni(1:3)+M(1:3,4))';
zpoint_head = (M(1:3,1:3)*zpoint_mni(1:3)+M(1:3,4))';



