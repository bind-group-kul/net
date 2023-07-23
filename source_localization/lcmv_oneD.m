%% Purpose -- Perform Source reconstruction based on a subsample of the data
% 1. Load SPM data
% 2. Select only a subsample of the data
% 3. Replace the data with this downsampled data
% 4. Solve the inverse problem, given the components find the source
% 5. Save the source configuration as nifti files
% 6. Convert the units to mm..
% 7. Perform spatial normalization
% 8: Select voxels only within the mask
% 9: Save the source information and reconstruct the brain activity at the source space
% http://fieldtrip.fcdonders.nl/reference/ft_datatype_comp

%% Start afresh by clearing all command windows and variables
clc;clear;warning off

%% Set the path for the ZET toolbox folder and add it to MATLAB search directory


toolbox_folder = '/Users/dante/Documents/MATLAB/ZET_17_07_2014';
addpath( genpath(toolbox_folder) );

%%  Step 1: Load the necessary files..

img_filename = '/Users/dante/Documents/MATLAB/ZET_17_07_2014/testing_data/danman.img'; %Load the structural MRI file
spm_filename = '/Users/dante/Documents/EEG_test/resting state August 08/spm_dante resting 20140123 1032_prepro_clean_infRef.mat'; %Load the preprocessed data
mask_filename= '/Users/dante/Documents/MATLAB/ZET_17_07_2014/template/masks/brain_mask.nii';



options.filter.band='wideband';   % 'theta', 'alpha', 'beta', 'gamma', 'wideband'
options.downsampling.sampleSize = 1;%
options.source.method = 'lcmv';     % 'mne' , 'lcmv', 'sam', 'rv', 'music', 'wmne', 'dspm' , 'sloreta', 'lcmvbf','gls_p','glsr','glsr_p','mnej','mnej_p'



load([img_filename(1:end-4) '_leadfield.mat'], 'leadfield');%Load the leadfield matrix file
load([img_filename(1:end-4) '_EEG_BEM.mat'], 'vol'); %Load the volume conduction model file



D=spm_eeg_load(spm_filename);
EEG = pop_fileio([path(D) filesep fname(D)]);
freq_band=options.filter.band;
switch freq_band
    case {'delta','theta', 'alpha', 'beta', 'gamma', 'lowerbeta', 'higherbeta' 'wideband'}
        options.filter.highpass=1;
        options.filter.lowpass=49.9;
        EEG=zet_unripple_filter(EEG,options.filter.highpass,options.filter.lowpass,6600); % EEG.data type is single, better to be changed to double as is required in some functions
end

%Take only the actual channel data..
data=spm2fieldtrip(D);
sens=sensors(D,'EEG');
list_eeg=meegchannels(D,'EEG');
data.label=data.label(list_eeg);
sigs=double(EEG.data(list_eeg,:,1));
data.trial{1}=sigs;

cov_matrix=diag(diag(cov(bst_bsxfun(@minus, sigs', mean(sigs')))));
noisecov_matrix=double(D.noisecov_matrix);
% cov_matrix=eye(length(list_eeg));

%disp('Get the EEG sensors locations.');

%% Step 2: Select only a subsample of the data..
numSamples = size(sigs,2);
sampleSize = options.downsampling.sampleSize;

ntp_sel=fix(numSamples*sampleSize);
samples=[1:numSamples];

datasub = sigs(:, zet_getrandsamples(samples, ntp_sel,'homogeneous'));
timesub = data.time{1}(:,1:size(datasub,2));


%% Step 3: Now we will now replace the data with this downsampled data and use it for localization..
temptrial = data.trial{1};
temptime = data.time{1};
data.trial{1}= datasub;
data.time{1} = timesub;

%%  Step 4: Solve the inverse problem, given the components find the source?

disp('The inverse solution.');


%%for wmne
% options.source.wmne.weightlimit=10;
% options.source.wmne.snr=5;
% options.source.wmne.deflect=1;% use deflect leakage correction


%%for mne
% options.source.mne.prewhiten = 'yes'; % prewhiten the leadfield matrix with the sensor noise covariance matrix C.
% options.source.mne.snr = 5; %scalar, signal to noise ratio
% options.source.mne.scalesourcecov = 'yes'; % scale the source covariance matrix R such that trace(leadfield*R*leadfield')/trace(C)=1
% options.source.mne.noisecov = noisecov_matrix; %Nchan x Nchan matrix with sensor noise covariance. CAREFULL: should be double 
% options.source.mne.noiselambda = 0.1; %scalar value, regularisation parameter for the sensor noise covariance matrix. (default=0)
% options.source.mne.deflect=1;% use deflect leakage correction

%%for lcmv
% % %Suggestion for tikhonov parameter: datasubtimefraction*length(timesub)<=400, otherwise very time consuming
% datasubtimefraction=0.01;
% tikhonov_par = zet_tikhonov_estimate(leadfield,datasub,datasubtimefraction); % datasubtimefraction should be between 0 and 1. 
options.source.lcmv.lambda=1; %regularisation parameter (use zet_tikhonov to compute)
options.source.lcmv.powmethod = 'lambda1'; %can be 'trace' or 'lambda1'(svd decomposition)
options.source.lcmv.fixedori= 'yes'; % yes to keep only optimal dipole orientation, should be used for brookes et. al 2012 leakage correction paper. comment it otherwise.
options.source.lcmv.keepfilter = 'yes'; %this gives systemmatrix or imaging kernel
options.source.lcmv.keepmom = 'no'; % should be 'no' if sampleSize>0.1, comment this line otherwise


%%for lcmvbf
% % %Suggestion for tikhonov parameter: datasubtimefraction*length(timesub)<=500
% datasubtimefraction=0.01;
% tikhonov_par = zet_tikhonov_estimate(leadfield,datasub,datasubtimefraction); % datasubtimefraction should be between 0 and 1. 
% options.source.lcmvbf.BaselineSegment=[];
% options.source.lcmvbf.Tikhonov=tikhonov_par*100; % computed using zet_tikhonov
% options.source.lcmvbf.OutputFormat=0;
% options.source.lcmvbf.DataBaseline=datasub;
% options.source.lcmvbf.isConstrained=0;

%%for sloreta
% options.source.sloreta.depth = 0;
% options.source.sloreta.snr=5;


% ATTENTION: for 'mne' , 'lcmv', 'sam', 'rv', 'music' localisations, if leadfield is NOT pre-computed the following options could be included:
%  'reducerank'       = reduce the leadfield rank, can be 'no' or a number (e.g. 2), if you don't define this parameter, default would be 2 for MEG, 3 for EEG
%  'normalize'        = normalize the leadfield
%  'normalizeparam'   = parameter for depth normalization (default = 0.5)

sourcemethod='lcmv_oneD';%options.source.method;

cfg=options.source;
cfg.grid = leadfield;
cfg.vol = vol;
cfg.sens=sens;
cfg.computekernel = 1;
cfg.noisecov=noisecov_matrix;
cfg.nAvg=1; %1 for resting state, number of events for ERP
if sampleSize <=0.1
    cfg.imgridamp=1;
end


downsampledsource = lcmv_oneD_sourceanalysis(data,cfg);


%% for imaging kernel demeaning
% S=zeros(size(downsampledsource.imagingkernel));
% ik=downsampledsource.imagingkernel;
% ikdemean=ik-repmat(mean(ik,2),1,size(ik,2));
% downsampledsource.imagingkernel=ikdemean;

%% for imaging kernel orthogonalising 
% % % jj=0;
% % % for ii=1:3:size(S,1)
% % % jj=jj+1
% % % s2=ik(1:3:size(S,1),:);s2(jj,:)=[];
% % % s1=ik(ii,:);
% % % % % % b=glmfit(s2,s1,'normal', 'constant', 'off');
% % % % % % S(:,ii)=s1-s2*b;
% % % s3=(sum((repmat(s1,size(s2,1),1).*s2),2)./(sqrt(sum(s2.^2,2)).^2));
% % % S(ii,:)=s1-sum(repmat(s3,1,size(s2,2)).*s2);
% % % end
% % % 
% % % jj=0;
% % % for ii=2:3:size(S,1)
% % % jj=jj+1
% % % s2=ik(2:3:size(S,1),:);s2(jj,:)=[];
% % % s1=ik(ii,:);
% % % % % % b=glmfit(s2,s1,'normal', 'constant', 'off');
% % % % % % S(:,ii)=s1-s2*b;
% % % s3=(sum((repmat(s1,size(s2,1),1).*s2),2)./(sqrt(sum(s2.^2,2)).^2));
% % % S(ii,:)=s1-sum(repmat(s3,1,size(s2,2)).*s2);
% % % end
% % % jj=0;
% % % for ii=3:3:size(S,1)
% % % jj=jj+1
% % % s2=ik(3:3:size(S,1),:);s2(jj,:)=[];
% % % s1=ik(ii,:);
% % % % % % b=glmfit(s2,s1,'normal', 'constant', 'off');
% % % % % % S(:,ii)=s1-s2*b;
% % % s3=(sum((repmat(s1,size(s2,1),1).*s2),2)./(sqrt(sum(s2.^2,2)).^2));
% % % S(ii,:)=s1-sum(repmat(s3,1,size(s2,2)).*s2);
% % % end
% % % Smn=[mean(S(1:3:end,:));mean(S(2:3:end,:));mean(S(3:3:end,:))];
% % % Sorth=S-repmat(Smn,size(S,1)/3,1);
% % % downsampledsource.imagingkernel=Sorth;

%Compute the system matrix
systemmatrix = downsampledsource;
systemmatrix.time = 1:size(datasub,1);
systemmatrix.avg.pow=nan(size(leadfield.pos,1),size(sigs,1));
systemmatrix.avg.pow(leadfield.inside',:) = downsampledsource.imagingkernel;

%%  Step 5: Save the source configuration

delete(['w' spm_filename(1:end-4) '_' sourcemethod '_' freq_band '_systemmatrix*']);
delete([spm_filename(1:end-4) '_' sourcemethod '_' freq_band '_systemmatrix*']);

disp('saving images');


cfg = [];
cfg.filename = [spm_filename(1:end-4) '_' sourcemethod '_' freq_band '_systemmatrix_power'];
cfg.parameter = 'avg.pow';
cfg.coordsys = 'ctf';
cfg.unit = 'cm'; 
ft_sourcewrite(cfg,systemmatrix); %Save the dipole power

mri = ft_read_mri(img_filename, 'format', 'nifti_spm');
mri = ft_convert_units(mri, 'cm');
cfg = [];
cfg.filename = [spm_filename(1:end-4)  '_anatomy'];
cfg.filetype = 'nifti';
cfg.parameter = 'anatomy';
cfg.unit = 'cm'; 
ft_volumewrite(cfg, mri);

%%  Step 6: The below step is to set the nans to zero, and convert the transformation matrix into mm units..

list_img{1}=[spm_filename(1:end-4)  '_anatomy.nii'];
list_img{2}=[spm_filename(1:end-4) '_' sourcemethod '_' freq_band '_systemmatrix_power.nii'];

for k=1:length(list_img)
    Vx=spm_vol(list_img{k});
for i=1:length(Vx)
    img=1000*spm_read_vols(Vx(i));
    img(isnan(img))=0; %Setting all locations with nans to zero
    Vx(i).mat=Vx(i).mat*10; %Convert the units of the transformation matrix to mm
    Vx(i).mat(4,4)=1;
    Vx(i).pinfo=[0.000001 ; 0 ; 0];
    spm_write_vol(Vx(i),img);
end
end


%%  Step 7: Perform spatial normalization..
disp('trasnforming images to MNI space');

spm_jobman('initcfg');

clear matlabbatch;

spm_folder=spm('dir');

matlabbatch{1}.spm.spatial.normalise.estwrite.subj.source{1} = [spm_filename(1:end-4)  '_anatomy.nii']; %This is the image that will be matched to the template
matlabbatch{1}.spm.spatial.normalise.estwrite.subj.wtsrc = '';
matlabbatch{1}.spm.spatial.normalise.estwrite.subj.resample =list_img; %These are the images to which the transformation will be applied
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.template{1} = [spm_folder filesep 'templates' filesep 'T1.nii']; %This is the template image
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.weight = '';
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.smosrc = 8;
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.smoref = 0;
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.regtype = 'mni';
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.cutoff = 25;
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.nits = 16;
matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.reg = 1;
matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.preserve = 0;
matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.bb = [-82 -116  -64; 82   88   94]; %This is the bounding box parameter
matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.vox = [4 4 4]; %This is the voxel size for the warped output images
matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.interp = 1;
matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.prefix = 'w'; %The prefix for the output files


spm_jobman('run', matlabbatch);

%%  Step 8: Select voxels only within the mask..

[folder,file,ext]=fileparts(spm_filename);
V1=spm_vol([folder filesep 'w' file '_' sourcemethod '_' freq_band '_systemmatrix_power.nii']); %Load the normalized source components
Vm=spm_vol(mask_filename); %This is for computing the dimensions for the brain mask
xdim=Vm.dim(1);
ydim=Vm.dim(2);
zdim=Vm.dim(3);

mask=spm_read_vols(Vm);
vect=find(mask(:)>=0.5); %Find the regions where the mask exists?
datap=spm_read_vols(V1);
datap(isnan(datap))=0; %Setting all locations with nans to zero
datap=reshape(datap,xdim*ydim*zdim,numel(datap)/(xdim*ydim*zdim));%Collapse the spatial dimension
datap=datap(vect,:); %Store only data within the mask


%%  Step 9: Save the source information and reconstruct the brain activity at the source space..

newdir=[folder filesep 'w' file '_' sourcemethod '_' freq_band '_brain_activity_cleandata'];
mkdir(newdir);

source_info.name=['w' file '_' sourcemethod '_' freq_band '_brain_activity_cleandata'];
source_info.dim=[xdim ydim zdim];
source_info.time=data.time;
source_info.inside=find(mask(:)>=0.5);
source_info.outside=find(mask(:)<0.5);
source_info.trialinfo=1;
source_info.cfg=systemmatrix.cfg; 

cntz=0;
cntnz=0;
zero_voxs=[];
nonzero_voxs=[];
max_i=length(vect);
for i=1:max_i %Looping for each voxel..
    disp([num2str(i) '/' num2str(max_i)]);
    sig=datap(i,:)*temptrial; %Compute the dipole moment in x-direction for a single voxel across time by using this system matrix..
    
    num=['0000' num2str(i)];
    num=num(end-4:end);
    if sum(abs(sig))==0
        cntz=cntz+1;
        zero_voxs(cntz)=i;
    else
        cntnz=cntnz+1;
        nonzero_voxs(cntnz)=i;
    end
    save([newdir filesep 'voxel_' num '.mat'],'sig'); %Store the dipole moments for that voxel..
end
source_info.nonzero_voxs=nonzero_voxs;
save([newdir filesep 'source_info'],'source_info');
%%

