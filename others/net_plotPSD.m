function [] = net_plotPSD(raweeg_filename,processedeeg_filename)
% Camillo's plot

%% Raw data
D    = spm_eeg_load( raweeg_filename );
list_eeg = selectchannels(D,'EEG');
data = D(list_eeg,:,:);
Fs   = fsample(D);
ntp  = size(data,2);
nfft = 1024;
df   = [1 100];

figure;
subplot(1,2,1)
performPSD1(data,nfft,Fs,@hanning,60,1,df);
title('Raw data')
xlim([0 80]), xlabel('Hz')
ylim([0 100]), ylabel('psd')

%% NET cleaning
D    = spm_eeg_load( processedeeg_filename );
data2 = D(list_eeg,:,:);

subplot(1,2,2)
performPSD1(data2,nfft,Fs,@hanning,60,1,df);
title('NET')
xlim([0 80]), xlabel('Hz')
ylim([0 100]), ylabel('psd')
end