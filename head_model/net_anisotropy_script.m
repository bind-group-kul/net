
clear all;

bvec_file='/Users/dantemantini/Documents/NET_v2.1/testing_data/sMRI/DTI_45d.bvec';

bval_file='/Users/dantemantini/Documents/NET_v2.1/testing_data/sMRI/DTI_45d.bval';

dwi_file='/Users/dantemantini/Documents/NET_v2.1/testing_data/sMRI/GUARNIERI_DTI.nii';

freeze=[1 1 1 1 1 1 0 1 0 1 1 0];


dummy_write=1;

dummy_disp=0;


DD=load(bvec_file);

bvalues=load(bval_file);

[tmp,pos]=min(bvalues);


[dd,ff,ext]=fileparts(dwi_file);

dx=[dd filesep 'tmp'];

if isdir(dx)
    rmdir(dx,'s');
end
mkdir(dx);

clear matlabatch;

matlabbatch{1}.spm.util.split.vol = {dwi_file};
matlabbatch{1}.spm.util.split.outdir = {dx};

spm_jobman('run',matlabbatch);

dd=dir([dx filesep '*.nii']);

nimgs=length(dd);

rP=[];
for i=1:nimgs
    rP=strvcat(rP,[dx filesep dd(i).name]);
end

EC_MO_correction(rP(pos,:),rP,freeze,dummy_write,dummy_disp);


PInd=[];
for i=1:nimgs
    PInd=strvcat(PInd,[dx filesep 'r' dd(i).name]);
end

for i=1:nimgs
    V=spm_vol([dx filesep 'r' dd(i).name]);
    data=spm_read_vols(V);
    if i==1
        datat=data;
    else
        datat=data+datat;
    end
end
    
mask=zeros(size(datat));
mask(datat>0.01*max(datat(:)))=1;
mask=imfill(mask,'holes');


DTIdata=[];
for i=1:nimgs
    V=spm_vol([dx filesep 'r' dd(i).name]);
    data=spm_read_vols(V);
    DTIdata(i).VoxelData=data.*mask;
    DTIdata(i).Gradient=DD(:,i);
    DTIdata(i).Bvalue=bvalues(i);
end
    

parameters.textdisplay=1;
parameters.BackgroundTreshold=0;
parameters.WhiteMatterExtractionThreshold=0;

[ADC,FA,VectorF,DifT]=net_tensor_calc(DTIdata,parameters);

V.fname=[dwi_file(1:end-4) '_tensor.nii'];
for i=1:6
    V.n=[i 1];
    V.dt=[16 0];
    V.pinfo=[0.000001;0;0];
    spm_write_vol(V,DifT(:,:,:,i));
end

rmdir(dx,'s');