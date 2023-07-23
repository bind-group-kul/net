function [fid1_head, fid2_head, fid3_head] = net_set_fiducials_general(img_filename, fiducials_mni,template_filename)

fid1_mni=fiducials_mni.fid1;
fid2_mni=fiducials_mni.fid2;
fid3_mni=fiducials_mni.fid3;
%zpoint_mni=fiducials_mni.zpoint;


%spm_dir=spm('Dir');


sn_filename = [img_filename(1:end-4) '_sn.mat'];

% Running 'Normalise: Estimate'
% Smoothing by 0 & 4mm..
% Coarse Affine Registration..
% Fine Affine Registration..
% Saving Parameters..
spm_jobman('initcfg');

matlabbatch{1}.spm.tools.oldnorm.estwrite.subj.source = {[img_filename ',1'] };
matlabbatch{1}.spm.tools.oldnorm.estwrite.subj.wtsrc = '';
matlabbatch{1}.spm.tools.oldnorm.estwrite.subj.resample = {[img_filename ',1'] };
matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.template = {[template_filename ',1'] };
matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.weight = '';
matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.smosrc = 4;
matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.smoref = 4;
matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.regtype = 'mni';
matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.cutoff = 25;
matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.nits = 0;
matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.reg = 1;
matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.preserve = 0;
matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.bb = [-78 -112 -70
                                                         78 76 85];
matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.vox = [2 2 2];
matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.interp = 1;
matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.prefix = 'w';



spm('defaults', 'EEG');
spm_jobman('run', matlabbatch);

[dd,ff,ext] = fileparts(img_filename);
delete([dd,filesep,'w',ff,ext]);

load( sn_filename );
delete( sn_filename );

Q = VG.mat*inv(Affine)/VF.mat;
M = inv(Q);

fid1_head = (M(1:3,1:3)*fid1_mni(1:3)+M(1:3,4))';  % in mm
fid2_head = (M(1:3,1:3)*fid2_mni(1:3)+M(1:3,4))';
fid3_head = (M(1:3,1:3)*fid3_mni(1:3)+M(1:3,4))';
%zpoint_head = (M(1:3,1:3)*zpoint_mni(1:3)+M(1:3,4))';



