function net_origspace_sMRI(structural_file_mni,structural_file)

[dd1,ff1,ext1]=fileparts(structural_file_mni);
[dd2,ff2,ext2]=fileparts(structural_file);


[bb_i,vox_i]=net_world_bb(structural_file);


ddx=dir([dd1 filesep 'c*' ff1 '.nii']);
ntissues=length(ddx);

filelist=cell(ntissues,1);
for i=1:ntissues
    filelist{i,1}=[ddx(i).folder filesep ddx(i).name];
end


clear matlabbatch

matlabbatch{1}.spm.util.defs.comp{1}.def = {[dd2 filesep  'iy_' ff2 '.nii']};
matlabbatch{1}.spm.util.defs.out{1}.push.fnames = filelist;
matlabbatch{1}.spm.util.defs.out{1}.push.weight = {''};
matlabbatch{1}.spm.util.defs.out{1}.push.savedir.savesrc = 1;
matlabbatch{1}.spm.util.defs.out{1}.push.fov.bbvox.bb = bb_i;
matlabbatch{1}.spm.util.defs.out{1}.push.fov.bbvox.vox = vox_i;
matlabbatch{1}.spm.util.defs.out{1}.push.preserve = 0;
matlabbatch{1}.spm.util.defs.out{1}.push.fwhm = 2*abs(vox_i);
matlabbatch{1}.spm.util.defs.out{1}.push.prefix = 'w';

spm_jobman('run',matlabbatch);

for i=1:ntissues
    movefile([dd1,filesep,'wc',num2str(i),ff1,ext1],[dd2,filesep,'c',num2str(i),ff2,ext2]);
    delete([dd1,filesep,'c',num2str(i),ff1,ext1]);
end

clear matlabbatch

matlabbatch{1}.spm.util.defs.comp{1}.def = {[dd1 filesep 'y_' ff1 ext1]};
matlabbatch{1}.spm.util.defs.comp{2}.def = {[dd2 filesep 'y_' ff2 ext2]};
matlabbatch{1}.spm.util.defs.out{1}.savedef.ofname = 'to_subj';
matlabbatch{1}.spm.util.defs.out{1}.savedef.savedir.saveusr = {dd2};

spm_jobman('run',matlabbatch);


clear matlabbatch

matlabbatch{1}.spm.util.defs.comp{1}.def = {[dd1 filesep 'iy_' ff1 ext1]};
matlabbatch{1}.spm.util.defs.comp{2}.def = {[dd2 filesep 'iy_' ff2 ext2]};
matlabbatch{1}.spm.util.defs.out{1}.savedef.ofname = 'to_mni';
matlabbatch{1}.spm.util.defs.out{1}.savedef.savedir.saveusr = {dd2};

spm_jobman('run',matlabbatch);

delete([dd1 filesep 'y_' ff1 ext1]);
delete([dd2 filesep 'y_' ff2 ext2]);
movefile([dd2 filesep 'y_to_subj.nii'],[dd2 filesep 'y_' ff2 ext2]);

delete([dd1 filesep 'iy_' ff1 ext1]);
delete([dd2 filesep 'iy_' ff2 ext2]);
movefile([dd2 filesep 'y_to_mni.nii'],[dd2 filesep 'iy_' ff2 ext2]);
