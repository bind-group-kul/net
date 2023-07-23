function [matching,rsn_name,corr_value]=net_rsn_match(ica_filename, template_dir)
% Match the ica_maps with the RSN template
%
%
% by Quanying Liu
% last version: 21.06.2016

NET_folder=net('path');

tpm_file=[NET_folder filesep 'template' filesep 'tissues_MNI' filesep 'eTPM12.nii'];

[dd,ff,ext] = fileparts(ica_filename);

template_subs = dir([template_dir,filesep,'*.nii']);

rsn_name=cell(1,length(template_subs));

for isub=1:length(template_subs) %started from 15, modifiedby JS 05.2023
    rsn_name{isub}=template_subs(isub).name(1:end-4);
    V=spm_vol([template_dir,filesep,template_subs(isub).name]);
    data = spm_read_vols( V);
    if isub==1
        [xdim,ydim,zdim]=size(data);
        template_data=zeros(xdim,ydim,zdim,length(template_subs));
    end
    template_data(:,:,:,isub)=data;
end
template_data(isnan(template_data)) = 0;
template_data((template_data)<0.5) = 0;  % mask the template with 1
template_data((template_data)>=0.5) = 1;

Vt=spm_vol([tpm_file ',1']);
tpm_img=sqrt(spm_read_vols(Vt));
Vt.fname=[dd filesep 'mask.nii'];
spm_write_vol(Vt,tpm_img);


clear matlabbatch

matlabbatch{1}.spm.spatial.coreg.write.ref = {[template_dir,filesep,template_subs(1).name]};
matlabbatch{1}.spm.spatial.coreg.write.source = {[dd filesep 'mask.nii']};
matlabbatch{1}.spm.spatial.coreg.write.roptions.interp = 0;
matlabbatch{1}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.coreg.write.roptions.mask = 0;
matlabbatch{1}.spm.spatial.coreg.write.roptions.prefix = 'r';

spm_jobman('run',matlabbatch);
  
Vm=spm_vol([dd filesep 'rmask.nii']);
mask = spm_read_vols(Vm);
mask=round(mask);


clear matlabbatch;

matlabbatch{1}.spm.spatial.coreg.write.ref = {[template_dir,filesep,template_subs(1).name]};
matlabbatch{1}.spm.spatial.coreg.write.source = {ica_filename};
matlabbatch{1}.spm.spatial.coreg.write.roptions.interp = 1;
matlabbatch{1}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.coreg.write.roptions.mask = 0;
matlabbatch{1}.spm.spatial.coreg.write.roptions.prefix = 'r';


spm_jobman('run', matlabbatch);


Vx=spm_vol([dd filesep 'r' ff ext]);
ICA_data=spm_read_vols(Vx);
ICA_data(isnan(ICA_data)) = 0; 



templ_map = reshape(template_data, xdim*ydim*zdim, size(template_data, 4));
templ_sel = templ_map(mask==1,:);

ica_map = reshape(ICA_data, xdim*ydim*zdim, size(ICA_data, 4));
ica_sel = ica_map(mask==1,:);

%cc_IC = corr(ica_sel, templ_sel,'type','Spearman');
cc_IC = corr(ica_sel, templ_sel,'type','Pearson');



val=zeros(1,length(template_subs));
matching = zeros(size(cc_IC));
cc_IC_tmp=cc_IC;
cont=0;

while cont < length(template_subs)

     cont=cont+1;
     
     vv = max(abs(cc_IC_tmp),[],1);
%      vv = max(cc_IC_tmp,[],1);
     [~,q]=min(vv);
     
     [~,pos]=max(abs(cc_IC_tmp(:,q)));
%      [~,pos]=max(cc_IC_tmp(:,q));
     val(q) = sign(cc_IC_tmp(pos,q));
     
     disp(['IC' num2str(pos) ' matches ' template_subs(q).name(1:end-4) ' network - correlation:' num2str(cc_IC_tmp(pos,q))]);
     matching(pos,q)=val(q);  % select pos 
     corr_value=abs(cc_IC_tmp(pos,q));
     cc_IC_tmp(pos,:)=NaN;
     cc_IC_tmp(:,q)=NaN;
end


delete([dd filesep 'mask.nii']);
delete([dd filesep 'rmask.nii']);
delete([dd filesep 'r' ff ext]);
