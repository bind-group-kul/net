clear
clc
close all
warning off
%% set folders
ZET_folder = '/Users/quanyingliu/Documents/ZET_updated';

% datadir = '/Users/quanyingliu/Documents/EEG_resting/dante/connectivity';
% newdir  = '/Users/quanyingliu/Documents/EEG_resting/dante/spm_dante_resting_prepro_clean_avgRef_sloreta_wideband_cleandata';
% spm_filename = '/Users/quanyingliu/Documents/EEG_resting/dante/spm_dante_resting_prepro_clean_avgRef.mat'; %Load the preprocessed data

% datadir = '/Users/quanyingliu/Documents/EEG_resting/qy/connectivity';
% newdir  = '/Users/quanyingliu/Documents/EEG_resting/qy/spm_qy_resting_prepro_clean_avgRef_sloreta_wideband_cleandata';
% spm_filename = '/Users/quanyingliu/Documents/EEG_resting/qy/spm_qy_resting_prepro_clean_avgRef.mat'; %Load the preprocessed data

% datadir = '/Users/quanyingliu/Documents/EEG_resting/andrea/connectivity';
% newdir  = '/Users/quanyingliu/Documents/EEG_resting/andrea/spm_andrea_resting_prepro_clean_avgRef_sloreta_wideband_cleandata';
% spm_filename = '/Users/quanyingliu/Documents/EEG_resting/andrea/spm_andrea_resting_prepro_clean_avgRef.mat'; %Load the preprocessed data

% datadir = '/Users/quanyingliu/Documents/EEG_resting/ellen/connectivity';
% newdir  = '/Users/quanyingliu/Documents/EEG_resting/ellen/spm_ellen_resting_prepro_clean_avgRef_sloreta_wideband_cleandata';
% spm_filename = '/Users/quanyingliu/Documents/EEG_resting/ellen/spm_ellen_resting_prepro_clean_avgRef.mat'; %Load the preprocessed data


datadir = '/Users/quanyingliu/Documents/EEG_resting/snow/connectivity';
newdir  = '/Users/quanyingliu/Documents/EEG_resting/snow/spm_snow_resting_prepro_clean_avgRef_sloreta_wideband_cleandata';
spm_filename = '/Users/quanyingliu/Documents/EEG_resting/snow/spm_snow_resting_prepro_clean_avgRef.mat'; %Load the preprocessed data


options.new_fs  = 40;   % in Hz
options.overlap = 0;   % default 0.75

addpath( genpath(ZET_folder) );
D = spm_eeg_load(spm_filename);
load([newdir filesep 'source_info.mat'])

%% set initial values
list_eeg = meegchannels(D,'EEG');
data = D(list_eeg,:,1);
Scalemat = pinv(data);
Nvoxels  = length(source_info.inside);

winsize = fix(D.fsample/options.new_fs);
overlap = options.overlap;   % default 0.75

t = D.time;
t_ds = net_movavg(t,t,winsize,overlap,0); 
source_info.time_ds{1} = t_ds;
save([newdir filesep 'source_info.mat'],'source_info');

Ndata = size(data, 2);
%% run over voxels: take power hilbert envelope, filter to 5 bands, downsample using osl moving average
delete(gcp)
matlabpool open 8  % in parallel
parfor i=1:Nvoxels
    
    disp([num2str(i) '/' num2str(Nvoxels)]);
    num=['0000' num2str(i)];
    num=num(end-4:end);
    
    filename = [newdir filesep 'voxel_' num '.mat'];
    sig = load(filename);
   
    %% hilbert power envelope:
    % without orthogonalisation
    sighilp= abs(hilbert(sig.sigx))+abs(hilbert(sig.sigy))+abs(hilbert(sig.sigz));
    
% %     %with orthogonalisation
% %     sighilp= abs(hilbert(sig));
    
    % downsampling
    % %             sighilp_delta_ds(i,:)=downsample(sighilp_delta(i,:),winsize_delta);
    sighilp_ds = net_movavg(sighilp,t,winsize,overlap,0); 
    delta_weights = sighilp*Scalemat/Ndata;  % revised by QL, 10.02.2015, delta_weights = sighilp*Scalemat;
    sighilp_ds_norm = sighilp_ds/sqrt(delta_weights*delta_weights');
    
    % substitute nans with zeros
    %sighilp_ds(isnan(sighilp_ds))=0;
    sighilp_ds_norm(isnan(sighilp_ds_norm))=0;
    
    % save([newdir filesep 'voxel_' num '.mat'],'sighilp_ds_norm','-append');
    
    net_save_sighilp(filename, sighilp_ds_norm);
end
matlabpool close

disp(['Finished ' num2str(Nvoxels) ' voxels!']);