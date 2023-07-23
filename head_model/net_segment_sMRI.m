function net_segment_sMRI(img_filename,tpm_filename,options)

[bb_i,vox_i]=net_world_bb(img_filename);

[dd,ff,ext]=fileparts(img_filename);

V=spm_vol(tpm_filename);
ntissues=length(V);

V1=spm_vol(img_filename);
xdim=V1.dim(1);
ydim=V1.dim(2);
zdim=V1.dim(3);

switch options.normalization_mode
    
    case 'basic'
        
        
        clear matlabbatch;
        
        matlabbatch{1}.spm.spatial.preproc.channel.vols = {[img_filename ',1']};
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
        
        clear matlabbatch
        
        matlabbatch{1}.spm.util.defs.comp{1}.def = {[dd filesep  'iy_' ff '.nii']};
        matlabbatch{1}.spm.util.defs.out{1}.push.fnames = {img_filename};
        matlabbatch{1}.spm.util.defs.out{1}.push.weight = {''};
        matlabbatch{1}.spm.util.defs.out{1}.push.savedir.savesrc = 1;
        matlabbatch{1}.spm.util.defs.out{1}.push.fov.bbvox.bb = bb_i;
        matlabbatch{1}.spm.util.defs.out{1}.push.fov.bbvox.vox = vox_i;
        matlabbatch{1}.spm.util.defs.out{1}.push.preserve = 1;
        matlabbatch{1}.spm.util.defs.out{1}.push.fwhm = 2*abs(vox_i);
        matlabbatch{1}.spm.util.defs.out{1}.push.prefix = 'w';
        
        spm_jobman('run',matlabbatch);
        
        movefile([dd filesep 'w' ff ext],[dd filesep ff '_mni' ext]);
        
        
    case 'advanced'
        
        net_path=net('path');
        
        template=[net_path filesep 'template' filesep 'tissues_MNI' filesep 'mni_template.nii'];
        
        tpm=[net_path filesep 'template' filesep 'tissues_MNI' filesep 'eTPM6.nii'];
        
        net_normalize_sMRI(img_filename,template,tpm);
        
    
        clear matlabbatch;
        
        matlabbatch{1}.spm.spatial.preproc.channel.vols = {[img_filename(1:end-4) '_mni.nii,1']};
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
        matlabbatch{1}.spm.spatial.preproc.warp.write = [0 0];
        
        
        spm_jobman('run',matlabbatch);
        
        filenames=cell(ntissues,1);
        for i=1:ntissues
            filenames{i}=[dd filesep 'c' num2str(i) ff '_mni.nii'];
        end
        
        
        clear matlabbatch
        
        matlabbatch{1}.spm.util.defs.comp{1}.def = {[dd filesep  'y_' ff '.nii']};
        matlabbatch{1}.spm.util.defs.out{1}.push.fnames = filenames;
        matlabbatch{1}.spm.util.defs.out{1}.push.weight = {''};
        matlabbatch{1}.spm.util.defs.out{1}.push.savedir.savesrc = 1;
        matlabbatch{1}.spm.util.defs.out{1}.push.fov.bbvox.bb = bb_i;
        matlabbatch{1}.spm.util.defs.out{1}.push.fov.bbvox.vox = vox_i;
        matlabbatch{1}.spm.util.defs.out{1}.push.preserve = 0;
        matlabbatch{1}.spm.util.defs.out{1}.push.fwhm = 2*abs(vox_i);
        matlabbatch{1}.spm.util.defs.out{1}.push.prefix = 'w';
        
        spm_jobman('run',matlabbatch);
        
        
        for kk=1:ntissues
            
            movefile([dd filesep 'wc' num2str(kk) ff '_mni' ext],[dd filesep 'c' num2str(kk) ff ext]);
            delete([dd filesep 'c' num2str(kk) ff '_mni' ext]);
            
        end
end


if ntissues==12
    
    
    for kk=7:8
        
        V=spm_vol([tpm_filename ',' num2str(kk)]);
        
        data=spm_read_vols(V);
        
        V.fname=[dd filesep 'tmp.nii'];
        
        V.n=[1 1];
        
        spm_write_vol(V,data);
        
        clear matlabbatch
        
        matlabbatch{1}.spm.util.defs.comp{1}.def = {[dd filesep  'y_' ff '.nii']};
        matlabbatch{1}.spm.util.defs.out{1}.push.fnames = {[dd filesep 'tmp.nii']};
        matlabbatch{1}.spm.util.defs.out{1}.push.weight = {''};
        matlabbatch{1}.spm.util.defs.out{1}.push.savedir.savesrc = 1;
        matlabbatch{1}.spm.util.defs.out{1}.push.fov.bbvox.bb = bb_i;
        matlabbatch{1}.spm.util.defs.out{1}.push.fov.bbvox.vox = vox_i;
        matlabbatch{1}.spm.util.defs.out{1}.push.preserve = 0;
        matlabbatch{1}.spm.util.defs.out{1}.push.fwhm = 2*abs(vox_i);
        matlabbatch{1}.spm.util.defs.out{1}.push.prefix = 'w';
        
        spm_jobman('run',matlabbatch);
        
        delete([dd filesep  'c' num2str(kk) ff '.nii']);
        movefile([dd filesep 'wtmp.nii'],[dd filesep  'c' num2str(kk) ff '.nii']);
        delete([dd filesep 'tmp.nii']);
        
    end
    
end


datatot=zeros(xdim,ydim,zdim,ntissues);

flags.which=1;
flags.mean=0;


for kk=1:ntissues
    spm_reslice({img_filename,[dd filesep 'c' num2str(kk) ff ext]},flags);
    Vt=spm_vol([dd filesep 'rc' num2str(kk) ff ext]);
    datatot(:,:,:,kk)=spm_read_vols(Vt);
end


datax=1-sum(datatot(:,:,:,1:ntissues-1),4);
datax(datax<0)=0;
datatot(:,:,:,ntissues)=datax;


delete([dd filesep ff '_tpm' ext]);

Vx=Vt;
for kk=1:ntissues
    Vx.fname=[dd filesep ff '_tpm' ext];
    Vx.n=[kk 1];
    spm_write_vol(Vx,datatot(:,:,:,kk));
end



for kk=1:ntissues
    delete([dd filesep 'c' num2str(kk) ff ext]);
    delete([dd filesep 'rc' num2str(kk) ff ext]);
end

