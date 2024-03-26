% net_main_script.m

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
pathx = [NET_folder filesep 'net_results'];
if ~isdir(pathx)
    mkdir(pathx);  % Create the output folder if it doesn't exist..
end

pathdata = [pathx filesep 'template_dataset.xlsx'];
pathprepro = [pathx filesep 'template_parameters_prepro.xlsx'];
pathanalysis = [pathx filesep 'template_parameters_analysis.xlsx'];

if ~exist(pathdata)
    error('No dataset file in the selected directory! NET stops running.')
elseif ~exist(pathprepro)
    error('No preprocessing parameters file in the selected directory! NET stops running.')
elseif ~exist(pathanalysis)
    error('No analysis parameters file in the selected directory! NET stops running.')
end

fprintf(['\nNET - Reading datasets... \nSelected file: ' pathdata '\n\n'])
xls_data = net_read_data(pathdata);

fprintf(['\nNET - Reading parameters...\nSelected files: ' pathprepro '\nand \n' pathanalysis '\n\n'])
opt1 = net_gui_read_options(pathprepro,'prepro'); opt2 = net_gui_read_options(pathanalysis,'analysis');
options = cell2struct([struct2cell(opt1);struct2cell(opt2)],[fieldnames(opt1);fieldnames(opt2)]); clear opt1 opt2


%% Pre-processing data
[dd2,ff2,ext]=fileparts(pathx);
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
        fprintf('\n*** DATA CONVERSION: START... ***\n')
        f = waitbar(0,'Data conversion...');
        f.Name = ['Dataset ' num2str(subject_i) ' - DATA CONVERSION'];

        %% Initialize structural MR image 
        waitbar(.2,f,'...MR data (1/3)');
        net_initialize_mri(xls_data(subject_i).anat_filename,[ddx filesep 'anatomy.nii']);
        
        %% Convert raw EEG data to SPM format
        waitbar(.4,f,'...EEG data (2/3)');
        net_initialize_eeg(xls_data(subject_i).eeg_filename,xls_data(subject_i).experiment_filename,raweeg_filename,options.eeg_convert,options.pos_convert);
        
        %% initializing the preprocessed EEG file
        waitbar(.9,f,'...EEG data (3/3)');
        net_eegprepro_initialize(raweeg_filename, processedeeg_filename);
        
        close(f)
        fprintf('\n*** DATA CONVERSION: DONE! ***\n')
    end
    
    if strcmp(xls_data(subject_i).head_modelling, 'on')
        fprintf('\n*** HEAD MODELLING: START... ***\n')
        f = waitbar(0,'Head modelling...');
        f.Name = ['Dataset ' num2str(subject_i) ' - HEAD MODELLING'];

        if contains(xls_data(subject_i).anat_filename, 'mni_template.nii') % copy headmodel folder when using template Sensor position and MRI, JS 02.2024
            copyfile([NET_folder filesep 'template' filesep 'headmodels' filesep 'mr_data'], ddx)
            [~,str] = fileparts(xls_data(subject_i).markerpos_filename);
            hmd = dir([NET_folder filesep 'template' filesep 'headmodels' filesep '**' filesep str]);
            copyfile(hmd(1).folder, ddx)

        else % otherwise calculate the headmodel

        %% remove image bias
        waitbar(.05,f,'...MRI preprocessing (1/4)'); 
        net_preprocess_sMRI(img_filename_orig,anat_filename,tpm_filename);
         
        %% perform tissue segmentation
        waitbar(.23,f,'...MRI segmentation (2/4)');
        net_segment_sMRI(img_filename,tpm_filename,options.sMRI);

        %% creating tissue classes
        net_tissues_sMRI(img_filename,tpm_filename,options.sMRI);

        %% coregister electrodes to MRI
        waitbar(.52,f,'...electrodes coregistration (3/4)');
        net_coregister_sensors(xls_data(subject_i).markerpos_filename,ddx,ddy,anat_filename,options.pos_convert);
        
        %% calculate head model
        waitbar(.55,f,'...headmodel computation (4/4)');
        net_calculate_leadfield(segimg_filename,elec_filename,options.leadfield);
        end
        
        close(f)
        fprintf('\n*** HEAD MODELLING: DONE! ***\n')
    end
  
    if strcmp(xls_data(subject_i).signal_processing, 'on')
        fprintf('\n*** SIGNAL PROCESSING: START... ***\n')
        f = waitbar(0,'Signal processing...');
        f.Name = ['Dataset ' num2str(subject_i) ' - SIGNAL PROCESSING'];

        %% NET - Detecting and Repairing the bad channels    
        waitbar(.05,f,'...bad channel detection (1/12)');
        net_repair_badchannel(processedeeg_filename, options.badchannel_detection);

        %% filtering EEG data
        waitbar(.15,f,'...EEG filtering (2/12)');
        net_filtering(processedeeg_filename,options.filtering);
        
        %% Attenuating fMRI gradient artifacts (for EEG/fMRI data only)
        waitbar(.17,f,'...fMRI gradient artefact attenuation (3/12)');
        net_rmMRIartifact(processedeeg_filename, options.fmri_artifacts);
        
        %% Attenuating BCG artifacts (for EEG/fMRI data only)
        waitbar(.2,f,'...BCG artefact attenuation (4/12)');
        net_rmBCGartifact(processedeeg_filename, options.bcg_artifacts);
        
        %% filtering EEG data
        net_filtering(processedeeg_filename,options.filtering);
        
        %% resampling EEG data for artifact correction
        waitbar(.25,f,'...EEG resampling (5/12)');
        net_resampling(processedeeg_filename,options.resampling_bss);
        
        %% Ocular artifact attenuation using BSS
        waitbar(.3,f,'...ocular artefact attenuation (6/12)');
        net_ocular_correction_wKurt(processedeeg_filename, options.ocular_correction);
        
        %% Movement artifact attenuation using BSS
        waitbar(.4,f,'...movement artefact attenuation (7/12)');
        net_movement_correction_wSampEn(processedeeg_filename, options.mov_correction);
        
        %% Myogenic artifact attenuation using BSS
        waitbar(.5,f,'...myogenic artefact attenuation (8/12)');
        net_muscle_correction_gamma_ratio(processedeeg_filename, options.muscle_correction);
        
        %% Cardiac artifact attenuation using BSS
        waitbar(.6,f,'...cardiac artefact attenuation (9/12)');
        net_cardiac_correction_skew(processedeeg_filename, options.cardiac_correction);
        
        %% De-spiking EEG data
        waitbar(.7,f,'...EEG despiking (10/12)');
        net_despiking(processedeeg_filename,options.despiking);
        
        %% Re-referencing EEG data
        waitbar(.8,f,'...EEG re-referencing (11/12)');
        net_reference(processedeeg_filename,options.reference);
        
        %% resampling EEG data for source localization
        waitbar(.9,f,'...EEG resampling (12/12)');
        net_resampling(processedeeg_filename,options.resampling_src);

        close(f)
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
        net_ica_connectivity(source_filename,options.ica_conn);
        
        %% seed-based connectivity analysis
        net_seed_connectivity(source_filename,options.seeding);
        
        fprintf('\n*** CONNECTIVITY ANALYSIS: DONE! ***\n')
    end
    
end

net_statistical_analysis(pathx,options.stats,nsubjs);

fprintf('\n*** END OF PROCESSING. ***\n')
rmpath( genpath(net('path')) )