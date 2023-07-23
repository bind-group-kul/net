function [options]=net_read_options(pathx)

xls_convert      = xls2struct(pathx,2); % 'conversion');
xls_head         = xls2struct(pathx,3); % 'head_modelling');
xls_preprocessing= xls2struct(pathx,4); % 'signal_processing');
xls_source       = xls2struct(pathx,5); % 'source_localization');
xls_activity     = xls2struct(pathx,6); % 'activity_analysis');
xls_connectivity = xls2struct(pathx,7); % 'connectivity_analysis');
xls_stats        = xls2struct(pathx,8); % 'statistical_analysis');

%% Define parameters for data convertion
parameters_i = 1;
options.eeg_convert.format       = char(xls_convert(parameters_i).parameters_data); parameters_i = parameters_i+1;

options.eeg_convert.timedelay    = excel_str2num(xls_convert(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.eeg_convert.chunck_start = excel_str2num(xls_convert(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.eeg_convert.chunck_end   = excel_str2num(xls_convert(parameters_i).parameters_data); parameters_i = parameters_i+1;

options.eeg_convert.eeg_channels = char(xls_convert(parameters_i).parameters_data); parameters_i = parameters_i+1;

options.eeg_convert.eog_channels = char(xls_convert(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.eeg_convert.emg_channels = char(xls_convert(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.eeg_convert.ecg_channels = char(xls_convert(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.eeg_convert.kinem_channels = char(xls_convert(parameters_i).parameters_data); parameters_i = parameters_i+1;

options.eeg_convert.physio_channels = char(xls_convert(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.eeg_convert.behav_channels = char(xls_convert(parameters_i).parameters_data); parameters_i = parameters_i+1;
clear parameters_i;

%% Define parameters for head model
parameters_i = 1;
options.pos_convert.fiducial_labels = char(xls_head(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.pos_convert.template        = char(xls_head(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.pos_convert.alignment       = char(xls_head(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.sMRI.template               = char(xls_head(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.sMRI.tpm                    = char(xls_head(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.sMRI.normalization_mode     = char(xls_head(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.sMRI.segmentation_mode      = char(xls_head(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.leadfield.conductivity      = char(xls_head(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.sMRI.Nifti_scale            = excel_str2num(xls_head(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.leadfield.method            = char(xls_head(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.leadfield.input_voxel_size  = excel_str2num(xls_head(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.leadfield.output_voxel_size = excel_str2num(xls_head(parameters_i).parameters_data); parameters_i = parameters_i+1;

clear parameters_i;

%% read parameters for EEG artifacts removal
parameters_i = 1;
options.badchannel_detection.enable      = char(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.badchannel_detection.badchannels = char(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.badchannel_detection.n_range     = excel_str2num(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;

options.filtering.enable   = char(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.filtering.highpass = excel_str2num(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.filtering.lowpass  = excel_str2num(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;

options.fmri_artifacts.enable      = char(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.fmri_artifacts.event_code  = char(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.fmri_artifacts.dummy_scans = excel_str2num(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.fmri_artifacts.slices      = excel_str2num(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.fmri_artifacts.lpf         = excel_str2num(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.fmri_artifacts.L           = excel_str2num(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.fmri_artifacts.window      = excel_str2num(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.fmri_artifacts.strig       = excel_str2num(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;

options.bcg_artifacts.enable       = char(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.bcg_artifacts.ecg_channel  = excel_str2num(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;

options.resampling_bss.enable = char(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.resampling_bss.new_fs = excel_str2num(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;

options.ocular_correction.enable = char(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.ocular_correction.bss_method = char(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.ocular_correction.sampleSize = excel_str2num(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.ocular_correction.kurtosis_enable = char(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.ocular_correction.kurtosis_window = excel_str2num(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.ocular_correction.kurtosis_thres = excel_str2num(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.ocular_correction.reference_enable = char(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.ocular_correction.reference_thres = excel_str2num(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;

options.mov_correction.enable = char(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.mov_correction.bss_method = char(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.mov_correction.sampleSize = excel_str2num(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.mov_correction.low_pass = excel_str2num(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.mov_correction.sampEn_enable = char(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.mov_correction.sampEn_window = excel_str2num(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.mov_correction.sampEn_thres = excel_str2num(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.mov_correction.reference_enable = char(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.mov_correction.reference_thres = excel_str2num(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;

options.muscle_correction.enable = char(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.muscle_correction.bss_method = char(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.muscle_correction.sampleSize = excel_str2num(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.muscle_correction.gammaRatio_enable = char(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.muscle_correction.gammaRatio_thres = excel_str2num(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.muscle_correction.reference_enable = char(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.muscle_correction.reference_thres = excel_str2num(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;

options.cardiac_correction.enable = char(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.cardiac_correction.bss_method = char(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.cardiac_correction.sampleSize = excel_str2num(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.cardiac_correction.skewness_enable = char(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.cardiac_correction.skewness_thres = excel_str2num(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.cardiac_correction.reference_enable = char(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.cardiac_correction.reference_thres = excel_str2num(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;

options.despiking.enable = char(xls_preprocessing(parameters_i).parameters_data);  parameters_i = parameters_i+1;
options.despiking.window = excel_str2num(xls_preprocessing(parameters_i).parameters_data);  parameters_i = parameters_i+1;

options.reference.enable = char(xls_preprocessing(parameters_i).parameters_data);  parameters_i = parameters_i+1;
options.reference.type   = char(xls_preprocessing(parameters_i).parameters_data);  parameters_i = parameters_i+1;

options.resampling_src.enable = char(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.resampling_src.new_fs = excel_str2num(xls_preprocessing(parameters_i).parameters_data); parameters_i = parameters_i+1;

clear parameters_i;

%% read parameters for source localization
parameters_i = 1;
options.source.lead_demean        = char(xls_source(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.source.lead_normalize     = char(xls_source(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.source.lead_normalizeparam= excel_str2num(xls_source(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.source.mni_initialize     = char(xls_source(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.source.mni_output_res     = excel_str2num(xls_source(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.source.mni_smoothing      = excel_str2num(xls_source(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.source.method             = char(xls_source(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.source.eloreta.lambda     = excel_str2num(xls_source(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.source.sloreta.depth      = excel_str2num(xls_source(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.source.sloreta.snr        = excel_str2num(xls_source(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.source.mne.prewhiten      = char(xls_source(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.source.mne.snr            = excel_str2num(xls_source(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.source.mne.scalesourcecov = char(xls_source(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.source.mne.noiselambda    = excel_str2num(xls_source(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.source.mne.deflect        = excel_str2num(xls_source(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.source.wmne.weightlimit   = excel_str2num(xls_source(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.source.wmne.snr           = excel_str2num(xls_source(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.source.wmne.deflect       = excel_str2num(xls_source(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.source.lcmv.lambda        = excel_str2num(xls_source(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.source.lcmv.powmethod     = char(xls_source(parameters_i).parameters_data); parameters_i = parameters_i+1;

clear parameters_i;

%% read parameters for activity analysis
parameters_i = 1;

options.erp.sensor_enable  = char(xls_activity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.erp.roi_enable 	   = char(xls_activity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.erp.seed_file      = char(xls_activity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.erp.mapping_enable = char(xls_activity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.erp.highpass       = excel_str2num(xls_activity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.erp.lowpass        = excel_str2num(xls_activity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.erp.triggers       = char(xls_activity(parameters_i).parameters_data); parameters_i = parameters_i+1;

options.ers_erd.sensor_enable  = char(xls_activity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.ers_erd.roi_enable 	   = char(xls_activity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.ers_erd.seed_file      = char(xls_activity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.ers_erd.mapping_enable = char(xls_activity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.ers_erd.highpass 	   = excel_str2num(xls_activity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.ers_erd.lowpass 	   = excel_str2num(xls_activity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.ers_erd.triggers       = char(xls_activity(parameters_i).parameters_data); parameters_i = parameters_i+1;

clear parameters_i;

%% read parameters for connectivity analysis
parameters_i = 1;
options.ica_conn.enable             = char(xls_connectivity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.ica_conn.highpass           = excel_str2num(xls_connectivity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.ica_conn.lowpass            = excel_str2num(xls_connectivity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.ica_conn.window_duration    = excel_str2num(xls_connectivity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.ica_conn.window_overlap     = excel_str2num(xls_connectivity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.ica_conn.smooth_fwhm        = excel_str2num(xls_connectivity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.ica_conn.decomposition_type = char(xls_connectivity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.ica_conn.frequency_bands    = char(xls_connectivity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.ica_conn.mapping_type       = char(xls_connectivity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.ica_conn.triggers           = char(xls_connectivity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.seeding.map_enable          = char(xls_connectivity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.seeding.matrix_enable       = char(xls_connectivity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.seeding.window_duration     = excel_str2num(xls_connectivity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.seeding.window_overlap      = excel_str2num(xls_connectivity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.seeding.connectivity_measure= char(xls_connectivity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.seeding.orthogonalize       = char(xls_connectivity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.seeding.fs                  = excel_str2num(xls_connectivity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.seeding.seed_file           = char(xls_connectivity(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.seeding.triggers           = char(xls_connectivity(parameters_i).parameters_data); parameters_i = parameters_i+1;

clear parameters_i;

%% read parameters for statistical analysis
parameters_i = 1;
options.stats.flag           = char(xls_stats(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.stats.subjects       = xls_stats(parameters_i).parameters_data; parameters_i = parameters_i+1;
options.stats.demean         = char(xls_stats(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.stats.global_demean  = char(xls_stats(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.stats.global_scaling = char(xls_stats(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.stats.ffx            = char(xls_stats(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.stats.rfx            = char(xls_stats(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.stats.mult_comp      = char(xls_stats(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.stats.permutations   = excel_str2num(xls_stats(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.stats.p_thres        = excel_str2num(xls_stats(parameters_i).parameters_data); parameters_i = parameters_i+1;
options.stats.overwrite      = char(xls_stats(parameters_i).parameters_data); parameters_i = parameters_i+1;

clear parameters_i;
