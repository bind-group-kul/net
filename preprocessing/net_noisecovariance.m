function net_noisecovariance(processedeeg_filename)


D=spm_eeg_load(processedeeg_filename);

EEG = pop_fileio([path(D) filesep fname(D)]);


if nargin==2

nsamples=6600;

hp=round(min(EEG.srate/2.5,200));
lp=round(min(EEG.srate/2.1,250));

if lp>fsample(D)/2
    error('sampling frequency too low for noise covariance matrix filtering');
end

EEG=net_unripple_filter(EEG,hp,lp,nsamples);

end


list_eeg = selectchannels(D,'EEG');
sigs = double(EEG.data(list_eeg,:,1));
sigs = sigs-ones(length(list_eeg),1)*mean(sigs,1);
noisecov_matrix = diag(diag(cov(bsxfun(@minus, sigs', mean(sigs')))));


D.noisecov_matrix = noisecov_matrix;

D.save;
