function [cc_scans,shifted_A,shift_decim]=net_shift_scans(A,A_ref,i_factor,method,onset,maxshift)
%Here segments are interpolated 
%Due to memory reasons it is only a single segment (A)

baseline_A=mean(A(1:-onset));


A_interp(1,:)=interp1([0:size(A,2)-1],A(1,:),[0:(1/i_factor):size(A,2)-1],method);

A=A_interp;




% Here the interval is defined, which defines maximum shift  
shift_interval=2*round(i_factor)-round(1/2*i_factor)+7*i_factor/(1/maxshift);

n=[(-shift_interval):(shift_interval)];

n(1)=0;
n(2:2:length(n))=[1:shift_interval];
n(3:2:length(n))=-1*([1:shift_interval]);

cc_scans=zeros(length(n),size(A,1));
corr_1=A_ref(1,1+shift_interval:end-shift_interval); % mit 1. scan korrellieren


% shifting procedure
for j=1:length(n)
    corr_2=A(1,1+shift_interval+n(j):end-shift_interval+n(j)); 
    cc=corrcoef(corr_1,corr_2);
    cc_scans(j,1)=cc(1,2);
end

max_cc=max(cc_scans);

for j=1:size(A,1),
    shift(j)=n(find(max_cc(j)==cc_scans(:,j)));
    shift_decim(j)=shift(j)/i_factor;
end



% scans are shifted
shifted_A=A;
if shift~=0
    for k=1:size(A,1),
        shifted_A(k,1+shift_interval-shift(k):end-shift_interval-shift(k))=A(k,1+shift_interval:end-shift_interval);
    end 
else
    shifted_A=A;
end




% downsampling of artifact epochs
for j=1:size(shifted_A,1)
    shifted_A_small(j,:)=resample(shifted_A(j,:),1,i_factor);
    baseline_A_shift=mean(shifted_A(j,1:-onset));
end

%This shall compensate for baseline-changes due to resampling with
%filtering
shifted_A=shifted_A_small+(baseline_A-baseline_A_shift);