% net_main_script.m
%

addpath( genpath(net('path')) )

%% Set the path for the NET toolbox folder and add it to MATLAB search directory
try
    NET_folder = net('path');
    addpath( genpath(NET_folder) );   % add the path
catch
    
    ButtonName = questdlg('Please select the path for NET', ...
        'Please select the path for NET','okay','okay');
    if strcmp(ButtonName,'okay')
        NET_folder = uigetdir('/Users', 'Choose the path of NET');  % select the path of your NET
           addpath( genpath(NET_folder) );   % add the path
     end
end

%% Read all the parameters from Preprocessing_parameters.xls
fprintf('Select file (*.xlsx; *.xls) with datasets and parameters: \n');

[filename, pathname, filterindex] = uigetfile( ...
       {'*.xlsx','XLS-file (*.xlsx)'; ...
        '*.xls','XLS-file (*.xls)'}, ...
        'Pick a file', ...
        'MultiSelect', 'on');

pathx=[pathname filename];
if filterindex == 0
    error('No file selected! NET stops running.')
else
    fprintf(['Selected file: ' pathx '\nReading parameters...\n\n'])
end

xls_data = net_read_data(pathx);
options=net_read_options(pathx);

%% Pre-processing data
[dd2,ff2,ext]=fileparts(pathx);
pathy=[dd2 filesep ff2];
if ~isdir(pathy)
    mkdir(pathy);  % Create the output folder if it doesn't exist..
    disp(['NET - Generating output_folder: ' pathy]);
end

options.stats.subjects=[];
nsubjs = size(xls_data,1);
      
for subject_i = 1:nsubjs
    
 
    if nodata(xls_data(subject_i).anat_filename) || nodata(xls_data(subject_i).eeg_filename) || nodata(xls_data(subject_i).markerpos_filename)
        disp(['Subject ' num2str(subject_i) ': MISSING REQUIRED DATA (EEG, sensors position or structural MRI). Subject skipped.']);
        continue
    end
    if nopath(xls_data(subject_i).anat_filename) || nopath(xls_data(subject_i).experiment_filename) || nopath(xls_data(subject_i).eeg_filename) || nopath(xls_data(subject_i).markerpos_filename)
        disp(['Subject ' num2str(subject_i) ': INPUT FILE(S) NOT FOUND. Subject skipped.']);
        continue
    end
    
    %% initialize directories
    dd=[pathy filesep 'dataset' num2str(subject_i)];
    if ~isdir(dd)
        mkdir(dd);  % Create the output folder if it doesn't exist..
        disp(['NET - Generating output_folder: ' dd]);
    end
    
    ddx=[dd filesep 'mr_data'];
    if ~isdir(ddx)
        mkdir(ddx);  % Create the output folder if it doesn't exist..
    end
    
    ddy=[dd filesep 'eeg_signal'];
    if ~isdir(ddy)
        mkdir(ddy);  % Create the output folder if it doesn't exist..
    end
    
    ddz=[dd filesep 'eeg_source'];
    if ~isdir(ddz)
        mkdir(ddz);  % Create the output folder if it doesn't exist..
    end
    
    save([dd filesep 'options.mat'],'options')
    
    %% initialize filenames
    net_initialize_filenames;

    %% data conversion and processing
    if strcmp(xls_data(subject_i).conversion, 'on')
        %% Initialize structural MR image 
        net_initialize_mri(xls_data(subject_i).anat_filename,[ddx filesep 'anatomy.nii']);
        
        %% Initialize DWI image (if available)
        net_initialize_mri(xls_data(subject_i).dwi_filename,[ddx filesep 'dwi_tensor.nii']);
        
        %% Initialize CTI image (if available)
        net_initialize_mri(xls_data(subject_i).cti_filename,[ddx filesep 'cti.nii']);
        
        %% Convert raw EEG data to SPM format
        net_initialize_eeg(xls_data(subject_i).eeg_filename,xls_data(subject_i).experiment_filename,raweeg_filename,options.eeg_convert,options.pos_convert);
        
        %% initializing the preprocessed EEG file
        net_eegprepro_initialize(raweeg_filename, processedeeg_filename);
    end
    
    if strcmp(xls_data(subject_i).head_modelling, 'on')
        fprintf('\n*** HEAD MODELLING: START... ***\n')
        %% remove image bias
         net_preprocess_sMRI(img_filename_orig,anat_filename,tpm_filename);
         
        %% perform tissue segmentation
         net_segment_sMRI(img_filename,tpm_filename,options.sMRI);

        %% creating tissue classes
         net_tissues_sMRI(img_filename,tpm_filename,options.sMRI);

        %% coregister dwi_tensor to MRI
        net_coregister_dwi(dwi_filename_orig,img_filename);

        %% coregister electrodes to MRI
        net_coregister_sensors(xls_data(subject_i).markerpos_filename,ddx,ddy,anat_filename,options.pos_convert);
        
        %% calculate head model
%         save('head_model_simbio.mat', '-v7.3');
%         save('cti_test.mat', '-v7.3');
%         load('head_model_simbio.mat');
%         options.leadfield.method = 'gfdm';
         net_calculate_leadfield(segimg_filename,dwi_filename,cti_filename,elec_filename,options.leadfield);
%         net_calculate_leadfield(segimg_filename,dwi_filename,elec_filename,options.leadfield);
        fprintf('\n*** HEAD MODELLING: DONE! ***\n')
    end
  
    if strcmp(xls_data(subject_i).signal_processing, 'on')
        fprintf('\n*** SIGNAL PROCESSING: START... ***\n')
        %% NET - Detecting and Repairing the bad channels    
        net_repair_badchannel(processedeeg_filename, options.badchannel_detection);
     %   net_plotPSD(raweeg_filename,processedeeg_filename)
        %% filtering EEG data
        net_filtering(processedeeg_filename,options.filtering);
        
        %% Attenuating fMRI gradient artifacts (for EEG/fMRI data only)
        net_rmMRIartifact(processedeeg_filename, options.fmri_artifacts);
        
        %% Attenuating BCG artifacts (for EEG/fMRI data only)
        net_rmBCGartifact(processedeeg_filename, options.bcg_artifacts);
        
        %% filtering EEG data
        net_filtering(processedeeg_filename,options.filtering);
        
        %% resampling EEG data for artifact removal
        net_resampling(processedeeg_filename,options.resampling_bss);
        
        %% Ocular artifact attenuation using BSS
        net_ocular_correction_wKurt(processedeeg_filename, options.ocular_correction);
        %net_plotPSD(raweeg_filename,processedeeg_filename)
        
        %% Movement artifact attenuation using BSS
        net_movement_correction_wSampEn(processedeeg_filename, options.mov_correction);
        %net_plotPSD(raweeg_filename,processedeeg_filename)
        
        %% Myogenic artifact removal using BSS
        net_muscle_correction_gamma_ratio(processedeeg_filename, options.muscle_correction);
        %net_plotPSD(raweeg_filename,processedeeg_filename)
        
        %% Cardiac artifact removal using BSS
        net_cardiac_correction_skew(processedeeg_filename, options.cardiac_correction);
        %net_plotPSD(raweeg_filename,processedeeg_filename)
        
        %% De-spiking EEG data
        net_despiking(processedeeg_filename,options.despiking);
        
        %% Re-referencing EEG data
        net_reference(processedeeg_filename,options.reference);
        
        %% resampling EEG data for source localization
        net_resampling(processedeeg_filename,options.resampling_src);
       % net_plotPSD(raweeg_filename,processedeeg_filename)
       % saveas(gcf,[dd filesep 'psd.jpg'])
       % close all
       fprintf('\n*** SIGNAL PROCESSING: DONE! ***\n')
    end
   
    if strcmp(xls_data(subject_i).source_localization, 'on')
        fprintf('\n*** SOURCE LOCALIZATION: START... ***\n')
        %% perform source localization
        net_sourceanalysis(processedeeg_filename,headmodel_filename,source_filename,options.source);
        fprintf('\n*** SOURCE LOCALIZATION: DONE! ***\n')
    end
    
    if strcmp(xls_data(subject_i).activity_analysis, 'on')
        fprintf('\n*** ACTIVITY ANALYSIS: START... ***\n')
        %% ERP analysis
        net_erp_analysis(source_filename,options.erp);
        
        %% ERS/ERD analysis
        net_ers_erd_analysis(source_filename,options.ers_erd);
        
        fprintf('\n*** ACTIVITY ANALYSIS: DONE! ***\n')
    end
 
    if strcmp(xls_data(subject_i).connectivity_analysis, 'on')
        fprintf('\n*** CONNECTIVITY ANALYSIS: START... ***\n')
        %% ICA connectivity analysis
        net_ica_connectivity_revised(source_filename,options.ica_conn);
        
        %% seed-based connectivity analysis
%         net_seed_connectivity(source_filename,options.seeding);
        
        fprintf('\n*** CONNECTIVITY ANALYSIS: DONE! ***\n')
    end
    
    if strcmp(xls_data(subject_i).statistical_analysis, 'on')
        options.stats.subjects=[options.stats.subjects subject_i];
    end
    
end

if not(isempty(options.stats.subjects))
    fprintf('\n*** STATISTICAL ANALYSIS: START... ***\n')
    if length(options.stats.subjects) >= 2
        net_group_analysis(pathy,options.stats);
    else
        fprintf('At least 2 SUBJECTS NEEDED to perform statistical analyses!')
    end
else
    fprintf('No statistical analyses to run.')
end

fprintf('\n*** END OF PROCESSING. ***\n')
rmpath( genpath(net('path')) )