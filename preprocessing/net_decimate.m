function Dnew=net_decimate(D,options_decimation)

samples_process = D.samples_process;
fs = fsample(D);
samples_process_new = resample(samples_process,options_decimation.fsample,fs);
samples_process_new(samples_process_new<0.5) = 0;
samples_process_new(samples_process_new>=0.5)= 1;


S = [];
S.D = D;
S.fsample_new = options_decimation.fsample;
S.prefix = 'd_';
Dnew = spm_eeg_downsample(S);

Dnew.samples_process=samples_process_new;

Dnew.save;