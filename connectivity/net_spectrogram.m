function [F_T_all] = net_spectrogram(brain_signals,freq_spctrgrm,Fs,win)
%NET_SPECTROGRAM     Compute the spectrogram of all brain sources
%
%Input:              BRAIN_SIGNALS - matrix containing one time course per
%                    voxel, organized as [time_samples x n_voxel]
%                    FREQ_SPCTRGRM - vector of frequencies used to compute
%                    the spectrogram
%                    FS            - sampling frequency
%                    WIN           - structure with window features
%
%Output:             F_T_ALL - spectrogram of all brain sources

step     = round(Fs*win.step);       % in points;
[N_time, N_dipole] = size(brain_signals); % P: time * dipole
nwin    = fix((N_time-win.samples)/step);

F_T_all  = zeros(length(freq_spctrgrm), nwin+1, N_dipole);

for dipole_i = 1:N_dipole
    F_T_all(:,:,dipole_i) = spectrogram(brain_signals(:,dipole_i), win.samples, win.overlaptp, freq_spctrgrm, Fs);
end
end
