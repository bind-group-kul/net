function [newEEG] = net_unripple_filter(EEG,hp,lp,ntp)
% zero-phase distortion finite impulse response (FIR) filters
% 
% 30.11.2015

newEEG   = EEG;
EEG.data = [fliplr(EEG.data(:,1:ntp)) EEG.data fliplr(EEG.data(:,end-ntp+1:end))];
EEG.pnts = size(EEG.data,2);
EEG.xmax = (EEG.pnts-1)/EEG.srate;
EEG.times= 1:size(EEG.data,2);
EEG      = pop_eegfiltnew(EEG, hp, lp, ntp, 0, [], 0);
newEEG.data = EEG.data(:,ntp+1:end-ntp);