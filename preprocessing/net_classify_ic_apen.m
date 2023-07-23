function apen_channels=net_classify_ic_apen(IC,n_std,Fs)


Lp = 43 ;
Lp= 2*Lp/Fs;

[b,a] = cheby2(14,40,Lp);

Fsnew=100;

ICx=(filtfilt(b,a,IC'))';

ICx=(resample(ICx',round(100*Fsnew),round(100*Fs)))';


Nc=size(IC,1);

ApEn=zeros(1,Nc);

for i=1:Nc
    
    % disp(i);
    
    sig=ICx(i,:);
    
    N=length(sig);
    
    cluster=1024;
    
    apenv=zeros(1,fix(N/cluster));
    
    for k=1:fix(N/cluster)
        sigx=sig((k-1)*cluster+1:k*cluster);
        apenv(k)=net_apen_code(sigx,2,0.2);
    end
    
    ApEn(i)=median(apenv);
    
end


apen_channels=find(ApEn < mean(ApEn)-n_std*std(ApEn));    % | ApEn > mean(ApEn)+n_std*std(ApEn));
 