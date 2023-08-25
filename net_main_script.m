% net_main_script.m
%
clear, clc
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

%% Read all the parameters in the processing_directory
% fprintf('Select file (*.xlsx; *.xls) with datasets and parameters: \n');
fprintf(['NET - Select processing directory containing the excel files: *_dataset.xlsx, *_parameters_prepro.xlsx, *_parameters_analysis.xlsx) \n']);

% [filename, pathname, filterindex] = uigetfile( ...
%        {'*.xlsx','XLS-file (*.xlsx)'; ...
%         '*.xls','XLS-file (*.xls)'}, ...
%         'Pick a file', ...
%         'MultiSelect', 'on');

pathx = uigetdir( ...
       NET_folder,...
       'NET - Select processing directory');

dirname = strsplit(pathx,filesep);
pathdata = [pathx filesep dirname{end} '_dataset.xlsx'];
pathprepro = [pathx filesep dirname{end} '_parameters_prepro.xlsx'];
pathanalysis = [pathx filesep dirname{end} '_parameters_analysis.xlsx'];
if ~exist(pathdata)
    error('No dataset file in the selected directory! NET stops running.')
elseif ~exist(pathprepro)
    error('No preprocessing parameters file in the selected directory! NET stops running.')
elseif ~exist(pathanalysis)
    error('No analysis parameters file in the selected directory! NET stops running.')
end

% pathx=[pathname filename];
% if filterindex == 0
%     error('No file selected! NET stops running.')
% else
%     fprintf(['\nSelected file: ' pathx '\nReading parameters...\n\n'])
% end

fprintf(['\nNET - Reading datasets... \nSelected file: ' pathdata '\n\n'])
xls_data = net_read_data(pathdata);

fprintf(['\nNET - Reading parameters...\nSelected files: ' pathprepro '\nand \n' pathanalysis '\n\n'])
opt1 =net_gui_read_options(pathprepro,'prepro'); opt2 = net_gui_read_options(pathanalysis,'analysis');
options = cell2struct([struct2cell(opt1);struct2cell(opt2)],[fieldnames(opt1);fieldnames(opt2)]); clear opt1 opt2


%% Pre-processing data
[dd2,ff2,ext]=fileparts(pathx);
% pathy=[dd2 filesep ff2];
% if ~isdir(pathy)
%     mkdir(pathy);  % Create the output folder if it doesn't exist..
%     disp(['NET - Generating output_folder: ' pathy]);
% end

% options.stats.subjects=[];
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
    dd=[pathx filesep 'dataset' num2str(subject_i)];
    if ~isdir(dd)
        mkdir(dd);  % Create the output folder if it doesn't exist..
        fprintf(['NET - Generating output_folder: ' dd '\n\n']);
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

        %% coregister electrodes to MRI
        net_coregister_sensors(xls_data(subject_i).markerpos_filename,ddx,ddy,anat_filename,options.pos_convert);
        
        %% calculate head model
         net_calculate_leadfield(segimg_filename,elec_filename,options.leadfield);
        fprintf('\n*** HEAD MODELLING: DONE! ***\n')
    end
  
    if strcmp(xls_data(subject_i).signal_processing, 'on')
        fprintf('\n*** SIGNAL PROCESSING: START... ***\n')
        %% NET - Detecting and Repairing the bad channels    
        net_repair_badchannel(processedeeg_filename, options.badchannel_detection);

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
        
        %% Movement artifact attenuation using BSS
        net_movement_correction_wSampEn(processedeeg_filename, options.mov_correction);
        
        %% Myogenic artifact removal using BSS
        net_muscle_correction_gamma_ratio(processedeeg_filename, options.muscle_correction);
        
        %% Cardiac artifact removal using BSS
        net_cardiac_correction_skew(processedeeg_filename, options.cardiac_correction);
        
        %% De-spiking EEG data
        net_despiking(processedeeg_filename,options.despiking);
        
        %% Re-referencing EEG data
        net_reference(processedeeg_filename,options.reference);
        
        %% resampling EEG data for source localization
        net_resampling(processedeeg_filename,options.resampling_src);

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
        net_seed_connectivity(source_filename,options.seeding);
        
        fprintf('\n*** CONNECTIVITY ANALYSIS: DONE! ***\n')
    end
    
end

net_statistical_analysis(pathx,options.stats,nsubjs);

fprintf('\n*** END OF PROCESSING. ***\n')
rmpath( genpath(net('path')) )