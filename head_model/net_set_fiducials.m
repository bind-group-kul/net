function [fiducials_orig] = net_set_fiducials(fiducials_mni,img_filename,template_filename)



sn_filename = [img_filename(1:end-4) '_sn.mat'];


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

%spm('defaults', 'EEG');
spm_jobman('run', matlabbatch);

[dd,ff,ext] = fileparts(img_filename);
delete([dd,filesep,'w',ff,ext]);

load( sn_filename );
delete( sn_filename );

Q = VG.mat*inv(Affine)/VF.mat;
M = inv(Q);

translations= repmat(M(1:3,4)',length(fiducials_mni),1)'; % MM 11.12.17
fiducials_orig = (M(1:3,1:3)*fiducials_mni'+translations)';  % in mm
 
% fiducials_orig = (M(1:3,1:3)*fiducials_mni'+M(1:3,4))';  % in mm




