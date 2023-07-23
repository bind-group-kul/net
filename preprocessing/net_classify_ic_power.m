function [power_channels,ratio] = net_classify_ic_power(IC, threshold, Fs)
% Description: Check the ratio of the power between EEG_bands and wide_bands. 
% Notice: You can adjust the specified bands in preprocessing/net_classify_ic_power.m Line 5 and Line 6 
%           based on the interesting bands of your study. 
%           Otherwise we suggest you not to change it.


alpha_band = [7 13];
gamma_band = [40 80];

dt = 1/Fs;
[IC_num, N] = size(IC);

ratio=zeros(1,IC_num);
for i = 1:IC_num
    [spectrum, base] =  net_spectrum(IC(i,:),Fs);
    pow_alpha=mean(spectrum(base>alpha_band(1) & base<alpha_band(2)));
    pow_gamma=mean(spectrum(base>gamma_band(1) & base<gamma_band(2)));
    ratio(i) = pow_gamma / pow_alpha;
end

power_channels=find( ratio>threshold );
