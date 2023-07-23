clear
clc
close all
warning off
%% set folders


%
% file_eeg{1} = '/Volumes/Quanying/EEG_resting/andrea/spm_andrea_resting_prepro_clean_avgRef.mat';
% file_eeg{2} = '/Volumes/Quanying/EEG_resting/dan/spm_dan_resting_prepro_clean_avgRef.mat';
% file_eeg{3} = '/Volumes/Quanying/EEG_resting/dante/spm_dante_resting_prepro_clean_avgRef.mat';
% file_eeg{4} = '/Volumes/Quanying/EEG_resting/ellen/spm_ellen_resting_prepro_clean_avgRef.mat';
% file_eeg{5} = '/Volumes/Quanying/EEG_resting/nici/spm_nici_resting_prepro_clean_avgRef.mat';
% file_eeg{6} = '/Volumes/Quanying/EEG_resting/qy/spm_qy_resting_prepro_clean_avgRef.mat';
% file_eeg{7} = '/Volumes/Quanying/EEG_resting/sarah/spm_sarah_resting_prepro_clean_avgRef.mat';
% file_eeg{8} = '/Volumes/Quanying/EEG_resting/snow/spm_snow_resting_prepro_clean_avgRef.mat';
% file_eeg{9} = '/Volumes/Quanying/EEG_resting/subject1/spm_subject1_resting_prepro_clean_avgRef.mat';
% file_eeg{10} = '/Volumes/Quanying/EEG_resting/subject2/spm_subject2_resting_prepro_clean_avgRef.mat';
% file_eeg{11} = '/Volumes/Quanying/EEG_resting/subject3/spm_subject3_resting_prepro_clean_avgRef.mat';
% file_eeg{12} = '/Volumes/Quanying/EEG_resting/subject4/spm_subject4_resting_prepro_clean_avgRef.mat';
% file_eeg{13} = '/Volumes/Quanying/EEG_resting/subject5/spm_subject5_resting_prepro_clean_avgRef.mat';
% file_eeg{14} = '/Volumes/Quanying/EEG_resting/subject6/spm_subject6_resting_prepro_clean_avgRef.mat';
% file_eeg{15} = '/Volumes/Quanying/EEG_resting/subject7/spm_subject7_resting_prepro_clean_avgRef.mat';
% file_eeg{16} = '/Volumes/Quanying/EEG_resting/subject8/spm_subject8_resting_prepro_clean_avgRef.mat';
% file_eeg{17} = '/Volumes/Quanying/EEG_resting/subject9/spm_subject9_resting_prepro_clean_avgRef.mat';
% file_eeg{18} = '/Volumes/Quanying/EEG_resting/subject10/spm_subject10_resting_prepro_clean_avgRef.mat';
% file_eeg{19} = '/Volumes/Quanying/EEG_resting/toon/spm_toon_resting_prepro_clean_avgRef.mat';


file_eeg{1} = '/Users/quanyingliu/Documents/EEG_resting/andrea/spm_andrea_resting_prepro_clean_avgRef.mat';
file_eeg{2} = '/Users/quanyingliu/Documents/EEG_resting/dan/spm_dan_resting_prepro_clean_avgRef.mat';
file_eeg{3} = '/Users/quanyingliu/Documents/EEG_resting/dante/spm_dante_resting_prepro_clean_avgRef.mat';
file_eeg{4} = '/Users/quanyingliu/Documents/EEG_resting/ellen/spm_ellen_resting_prepro_clean_avgRef.mat';
file_eeg{5} = '/Users/quanyingliu/Documents/EEG_resting/nici/spm_nici_resting_prepro_clean_avgRef.mat';
file_eeg{6} = '/Users/quanyingliu/Documents/EEG_resting/qy/spm_qy_resting_prepro_clean_avgRef.mat';
file_eeg{7} = '/Users/quanyingliu/Documents/EEG_resting/sarah/spm_sarah_resting_prepro_clean_avgRef.mat';
file_eeg{8} = '/Users/quanyingliu/Documents/EEG_resting/snow/spm_snow_resting_prepro_clean_avgRef.mat';
file_eeg{9} = '/Users/quanyingliu/Documents/EEG_resting/subject1/spm_subject1_resting_prepro_clean_avgRef.mat';
file_eeg{10} = '/Users/quanyingliu/Documents/EEG_resting/subject2/spm_subject2_resting_prepro_clean_avgRef.mat';
file_eeg{11} = '/Users/quanyingliu/Documents/EEG_resting/subject3/spm_subject3_resting_prepro_clean_avgRef.mat';
file_eeg{12} = '/Users/quanyingliu/Documents/EEG_resting/subject4/spm_subject4_resting_prepro_clean_avgRef.mat';
file_eeg{13} = '/Users/quanyingliu/Documents/EEG_resting/subject5/spm_subject5_resting_prepro_clean_avgRef.mat';
file_eeg{14} = '/Users/quanyingliu/Documents/EEG_resting/subject6/spm_subject6_resting_prepro_clean_avgRef.mat';
file_eeg{15} = '/Users/quanyingliu/Documents/EEG_resting/subject7/spm_subject7_resting_prepro_clean_avgRef.mat';
file_eeg{16} = '/Users/quanyingliu/Documents/EEG_resting/subject8/spm_subject8_resting_prepro_clean_avgRef.mat';
file_eeg{17} = '/Users/quanyingliu/Documents/EEG_resting/subject9/spm_subject9_resting_prepro_clean_avgRef.mat';
file_eeg{18} = '/Users/quanyingliu/Documents/EEG_resting/subject10/spm_subject10_resting_prepro_clean_avgRef.mat';
file_eeg{19} = '/Users/quanyingliu/Documents/EEG_resting/toon/spm_toon_resting_prepro_clean_avgRef.mat';



file_img{1} = '/Users/quanyingliu/Documents/sMRI_resting/Andrea/t1_seg_andrea.nii';
file_img{2} = '/Users/quanyingliu/Documents/sMRI_resting/Dan/t1_seg_dan.nii';
file_img{3} = '/Users/quanyingliu/Documents/sMRI_resting/Dante/t1_seg_dante.nii';
file_img{4} = '/Users/quanyingliu/Documents/sMRI_resting/Ellen/t1_seg_ellen.nii';
file_img{5} = '/Users/quanyingliu/Documents/sMRI_resting/Nici/t1_seg_nici.nii';
file_img{6} = '/Users/quanyingliu/Documents/sMRI_resting/Quanying/t1_seg_qy.nii';
file_img{7} = '/Users/quanyingliu/Documents/sMRI_resting/Sarah/t1_seg_sarah.nii';
file_img{8} = '/Users/quanyingliu/Documents/sMRI_resting/Snow/t1_seg_snow.nii';
file_img{9} = '/Users/quanyingliu/Documents/sMRI_resting/subject05/t1_seg_05.nii';
file_img{10} = '/Users/quanyingliu/Documents/sMRI_resting/subject18/t1_seg_18.nii';
file_img{11} = '/Users/quanyingliu/Documents/sMRI_resting/Josh/t1_seg_josh.nii';
file_img{12} = '/Users/quanyingliu/Documents/sMRI_resting/subject04/t1_seg_04.nii';
file_img{13} = '/Users/quanyingliu/Documents/sMRI_resting/subject26/t1_seg_26.nii';
file_img{14} = '/Users/quanyingliu/Documents/sMRI_resting/subject23/t1_seg_23.nii';
file_img{15} = '/Users/quanyingliu/Documents/sMRI_resting/subject17/t1_seg_17.nii';
file_img{16} = '/Users/quanyingliu/Documents/sMRI_resting/subject03/t1_seg_03.nii';
file_img{17} = '/Users/quanyingliu/Documents/sMRI_resting/subject24/t1_seg_24.nii';
file_img{18} = '/Users/quanyingliu/Documents/sMRI_resting/subject22/t1_seg_22.nii';
file_img{19} = '/Users/quanyingliu/Documents/sMRI_resting/Toon/t1_seg_toon.nii';



delete(gcp)
matlabpool open 6

for sub=1:19
    [PATH_eeg, NAME_eeg, EXT_eeg] = fileparts( file_eeg{sub} );
    [PATH_img, NAME_img, EXT_img] = fileparts( file_img{sub} );
    
%     load([PATH_eeg filesep 'signal_spectrogram.mat']);  % F_T_all
    load([PATH_eeg filesep 'signal_spectrogram_S.mat']);  % F_T_all
    
    N = size(F_T_all, 3);

%% to get correlation in orthogalized signals
    frequencies = 1:1:80;
    corr_orth = zeros(length(frequencies), N, N);
    
    for dipole_i = 1:N
        S_i = F_T_all(:,:,dipole_i);
        parfor dipole_j = 1:dipole_i
            S_j = F_T_all(:,:,dipole_j);
            corr_orth(:, dipole_i, dipole_j) = net_orthogonalize_corr(S_i, S_j);
        end
    end
    load(['/Users/quanyingliu/Documents/corr_orth/' NAME_eeg(5:end-28) '_corr_orth.mat'], 'corr_orth', '-v7.3'); 
    clear F_T_all corr_orth
   
%% to get spatial Map
%     corr_all = corr(P_MFC, P_all);
%         
%     ica_image   = zeros(source_info.dim(1)*source_info.dim(2)*source_info.dim(3),1);
%     ica_image( source_info.inside ) = corr_all;
%     ica_image   = reshape(ica_image, source_info.dim(1), source_info.dim(2), source_info.dim(3) );
%     clear Vf
%     Vf.dim      = source_info.dim;
%     Vf.n        = [1 1];
%     Vf.pinfo    = [0.0001 ; 0 ; 0];
%     Vf.dt       = [8 0];
%     Vf.fname    = ['/Users/quanyingliu/Documents/RSN_wideband/DSM_SMA_orth/' NAME_eeg(5:end-28) '_' num2str(frequencies(f)) 'Hz.nii'];
%     Vf.mat      = source_info.transform;
%     spm_write_vol(Vf, ica_image);
          
end
     


