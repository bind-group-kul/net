function [ ratios ] = net_get_power_ratio( IC, Fs, band_1, whole_band )
%GET_POWER_RATIO Summary of this function goes here
%   Detailed explanation goes here
    nfft = 2048;
	[freq,spectr]=net_psd(IC,nfft,Fs,@hanning,50,whole_band,'off');
	
    freq = freq(:,1);
    
    band_power_whole = sum(spectr(freq>whole_band(1) & freq<whole_band(2), :), 1);
	band_power_delta = sum(spectr(freq>band_1(1) & freq<band_1(2), :), 1);   
    
    ratios = band_power_delta./band_power_whole;
end

