function [tf_real,tf_complex] = net_timefrequency(sig,Fs,freqs)

ntp = size(sig,2);

margin = 0.5*mean(diff(freqs));
nfreq  = length(freqs);


[X,f_sst] = net_wsst(sig,Fs,'bump','ExtendSignal',1,'FreqScale','linear');  % f_sst x ntp

mat = zeros(length(freqs),length(f_sst));
for i = 1:length(freqs)
    int = find(f_sst>=freqs(i)-margin & f_sst<=freqs(i)+margin);
    if isempty(int)                                                         % modified by JS, 19.10
        [~,int] = min(abs(f_sst-freqs(i)));
    end
    mat(i,int) = 1;
end

tf_complex=mat*X;

tf_real = zeros(nfreq,ntp);
for i = 1:nfreq
   tf_real(i,:) = net_iwsst(X,f_sst,[min(f_sst(mat(i,:)==1)) max(f_sst(mat(i,:)==1))],'bump');
end
