function [fitting_channels,gof] = net_classify_ic_fitting(IC,thres,Fs)
% Description: checks the spectrum has a 1/f curve 
% Notice: recommend to set it off if you didn't high-pass filter data to a relative high frequency
% QL, 21.04.2015

g = fittype({'1/x','1'});
frq_interval=[1 13];
res=1000;

[Nc, ntp]=size(IC);

gof=zeros(1,Nc);

for k=1:Nc
    [spectrum_sig,freq]=net_spectrum(IC(k,:),Fs);
    sp = double(spectrum_sig);
    freq_interp = (interp1(1:length(freq),freq',1:length(freq)/res:length(freq)))';
    sp_interp = (interp1(1:length(sp),sp',1:length(sp)/res:length(sp)))';
    vec = find(freq_interp > frq_interval(1) & freq_interp < frq_interval(2));
    [~,goodness] = fit(freq_interp(vec),sp_interp(vec),g);
    gof(k) = goodness.rsquare;
       
end

fitting_channels=find(gof>thres);