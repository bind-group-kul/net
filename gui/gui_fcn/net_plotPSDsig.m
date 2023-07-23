function [] = net_plotPSDsig(raweeg_filename,processedeeg_filename)
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
subplot(2,2,1)
plot(data(3,100000:110000))
subplot(2,2,3)
performPSD1(data,nfft,Fs,@hanning,60,1,df);
title('Raw data')
xlim([0 80]), xlabel('Hz')
ylim([0 100]), ylabel('psd')

%% NET cleaning
D    = spm_eeg_load( processedeeg_filename );
data2 = D(list_eeg,:,:);

subplot(2,2,2)
plot(data2(3,100000:110000))
subplot(2,2,4)
performPSD1(data2,nfft,Fs,@hanning,60,1,df);
title('NET')
xlim([0 80]), xlabel('Hz')
ylim([0 100]), ylabel('psd')
end