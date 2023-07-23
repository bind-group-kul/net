function net_preprocess_sMRI(img_filename,anat_filename,tpm_filename)
% Description: Pre-process the individual sMRI to remove background noise
% Step:
%   1. Smooth and remove background noise
%   2. Segmentation to get iy_ and y_ .nii
%   3. Deformation and transform wMIDA into subject space.
%
% Inputs:
% img_filename  - The filename of the sMRI image
% tpm_filename    = '/Users/quanyingliu/Documents/NET_updated/template/tissues_MNI/tpm_17.nii';
% tissue_filename = '/Users/quanyingliu/Documents/NET_updated/template/tissues_MNI/wMIDA.nii';
% voxel_size      = 1.5;


% Notice:
% Please add the NET and SPM12 into path
% 
%
% Authors:  Quanying Liu & Dante Mantini
%           quanying.liu@hest.ethz.chs
% Last version: 28.04.2016


voxel_size=1;

spm('Defaults','fMRI');

V=spm_vol(tpm_filename);
ntissues=length(V);

[dd,ff,ext] = fileparts(img_filename);


% =============================================================
% 1. Smooth and reslice the sMRI


V       = spm_vol([dd filesep ff ext ',1']);
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


spm_smooth([img_filename ',1'],[dd filesep 's' ff ext ',1'], [1 1 1], 0);


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

movefile([dd filesep 'mrs' ff '.nii'],[dd filesep ff '_prepro.nii']);
delete([dd filesep 'rs' ff '.nii']);
delete([dd filesep 'rs' ff '_seg8.mat']);
delete([dd filesep 's' ff '.nii']);
