% net_preprocess_sMRI_gfdm.m
% Ernesto Cuartas M (ECM), 16/06/2020
% Email:  ecuartasm@gmail.com

function net_preprocess_sMRI_gfdm(img_filename,anat_filename,tpm_filename,cti_filename_orig)
% Description: Pre-process the individual sMRI to remove background noise
% Step:
%   1. Smooth and remove background noise
%   2. Segmentation to get iy_ and y_ .nii
%   3. Deformation and transform wMIDA into subject space.
%
% Ernesto Cuartas M (ECM), 16/06/2020
% Email:  ecuartasm@gmail.com
%
% Quanying Liu & Dante Mantini
% quanying.liu@hest.ethz.chs

voxel_size = 1;
spm('Defaults','fMRI');
V=spm_vol(tpm_filename);
ntissues=length(V);
[dd,ff,ext] = fileparts(img_filename);


if exist(cti_filename_orig,'file')
    % 1. Smooth and reslice the sMRI - changed from spm to fieltrip
    sMRI = ft_read_mri(img_filename);
    cfg     = [];
    cfg.dim = sMRI.dim;
    sMRI_rs = ft_volumereslice(cfg,sMRI);
    data = sMRI_rs.anatomy;
    
    bx_sMRI = gfdm_BoxMri(data);
    dist_bx = [bx_sMRI(1,2) - bx_sMRI(1,1); bx_sMRI(2,2) - bx_sMRI(2,1); bx_sMRI(3,2) - bx_sMRI(3,1)];
    lon_sd = round(0.15*max(dist_bx));
    mri_bx = gfdm_SetBox( data, bx_sMRI, lon_sd);
    
    xval=squeeze(sum(sum(mri_bx,2),3));
    yval=squeeze(sum(sum(mri_bx,1),3))';
    zval=squeeze(sum(sum(mri_bx,1),2));
    
    dim = size(mri_bx);
    sMRI_rs.dim = dim;
    
    mat = sMRI_rs.transform;
    xorig=sum([1:length(xval)]'.*xval/sum(xval));
    yorig=sum([1:length(yval)]'.*yval/sum(yval));
    zorig=sum([1:length(zval)]'.*zval/sum(zval));
    mat(1:3,4)=-mat(1:3,1:3)*([xorig; yorig; zorig]);
    sMRI_rs.transform = mat;
    
    sMRI_rs.anatomy = mri_bx;
    gs_fill = imgaussfilt3(sMRI_rs.anatomy);
    sMRI_rs.anatomy = gs_fill;
    ft_write_mri_N([dd filesep 's' ff ext], sMRI_rs, 'dataformat', 'nifti');
    ft_write_mri_N([dd filesep 'as' ff ext], sMRI_rs, 'dataformat', 'nifti');
    
    Box_s.bx        = bx_sMRI;
    Box_s.lon_sd    = lon_sd;
    Box_s.transform = mat;
    save([dd filesep 'bx_sMRI.mat'], 'Box_s');
    % V    = spm_vol([dd filesep 'as' ff ext]);
    % data = spm_read_vols(V);
    % V.fname = [dd filesep 's' ff ext];
    % spm_write_vol(V,data);
    % ft_write_mri([dd filesep ff '_prepro.nii'], sMRI_rs, 'dataformat', 'nifti');
    
    clear matlabbatch    
    matlabbatch{1}.spm.spatial.coreg.estimate.ref = {[anat_filename ',1']};
    matlabbatch{1}.spm.spatial.coreg.estimate.source = {[dd filesep 's' ff ext ',1']};
    matlabbatch{1}.spm.spatial.coreg.estimate.other = {''};
    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];    
    spm_jobman('run',matlabbatch);
    
    [bb,vox]=net_world_bb([dd filesep 's' ff ext ',1']);
    
    sMRI_s = ft_read_mri([dd filesep 's' ff ext]);
    ft_write_mri_N([dd filesep 'rs' ff ext], sMRI_s, 'dataformat', 'nifti');   
    
else
    % 1. Smooth and reslice the sMRI
    spm_smooth([img_filename ',1'],[dd filesep 's' ff ext ',1'], [1 1 1], 0);
    
    V       = spm_vol([dd filesep 's' ff ext ',1']);
    data   = spm_read_vols(V);
    max_val = prctile(data(:),99.5);
    thres   = 0.1*max_val;
    
    mask=zeros(size(data));
    mask(data>thres)=1;
    mask=imfill(mask,4);
    %mask=imopen(mask,strel('sphere',3));
    mask = bwareaopen(mask,3);
    img=bwlabeln(mask);
    nvox=zeros(1,max(img(:)));
    for i=1:max(img(:))
        nvox(i)=sum(img(:)==i);
    end
    [val,pos]=max(nvox);
    mask=zeros(size(data));
    mask(img==pos)=1;
    
    %V.pinfo=[1;0;0];
    %spm_write_vol(V,mask);
    
    data(mask==0) = 0;
    xval=squeeze(sum(sum(data,2),3));
    yval=squeeze(sum(sum(data,1),3))';
    zval=squeeze(sum(sum(data,1),2));
    
    datax=data(xval>0,yval>0,zval>0);
    dim=size(datax);
    V.dim=dim;
    mat=V.mat;
    xorig=sum([1:length(xval)]'.*xval/sum(xval));
    yorig=sum([1:length(yval)]'.*yval/sum(yval));
    zorig=sum([1:length(zval)]'.*zval/sum(zval));
    mat(1:3,4)=-mat(1:3,1:3)*([xorig; yorig; zorig]);
    V.mat=mat;
    spm_write_vol(V,datax);
    
    clear matlabbatch
    matlabbatch{1}.spm.spatial.coreg.estimate.ref = {[anat_filename ',1']};
    matlabbatch{1}.spm.spatial.coreg.estimate.source = {[dd filesep 's' ff ext ',1']};
    matlabbatch{1}.spm.spatial.coreg.estimate.other = {''};
    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
    matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];
    spm_jobman('run',matlabbatch);
        
    [bb,vox]=net_world_bb([dd filesep 's' ff ext ',1']);
    
    % bbx=bb;
    % bbx(1,:)=-max(abs(bb),[],1);
    % bbx(2,:)=+max(abs(bb),[],1);
    
    %net_resize_img([dd filesep 's' ff ext ',1'],[voxel_size voxel_size voxel_size],[NaN NaN NaN; NaN NaN NaN]);
    net_resize_img([dd filesep 's' ff ext ',1'],[voxel_size voxel_size voxel_size],1.2*bb); 
end

% =============================================================
% 2. Bias correction 

clear matlabbatch

matlabbatch{1}.spm.spatial.preproc.channel.vols     = {[dd filesep 'rs' ff ext ',1']};
matlabbatch{1}.spm.spatial.preproc.channel.biasreg  = 0.001;
matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 30;
matlabbatch{1}.spm.spatial.preproc.channel.write    = [0 1];
for kk=1:ntissues
matlabbatch{1}.spm.spatial.preproc.tissue(kk).tpm = {[tpm_filename ',' num2str(kk)]};
matlabbatch{1}.spm.spatial.preproc.tissue(kk).ngaus = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(kk).native = [0 0];
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

V    = spm_vol([dd filesep 'mrs' ff '.nii']);
data = spm_read_vols(V);
V.fname = [dd filesep ff '_prepro.nii'];
spm_write_vol(V,data);

% movefile([dd filesep 'mrs' ff '.nii'],[dd filesep ff '_prepro.nii']);
delete([dd filesep 'rs' ff '.nii']);
delete([dd filesep 'rs' ff '_seg8.mat']);
delete([dd filesep 's' ff '.nii']);

