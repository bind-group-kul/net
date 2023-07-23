function D = net_bandfilt(D,filtering_options)
% Filtra i dati tra lowfq e highfq con ordine ordfilt e passo di campionamento smpfq
if isfield(filtering_options, 'highpass')
    lowfq = filtering_options.highpass;
else
    lowfq = 0.5;
end

if isfield(filtering_options, 'lowpass')
    highfq = filtering_options.lowpass;
else
    highfq = 40;
end


if isfield(filtering_options, 'order')
    ordfilt = filtering_options.order;
else
    ordfilt = 2;
end

EEGlist = selectchannels(D,'EEG');
data = D(EEGlist,:,1);

smpfq = fsample(D);

halfsmpfq=smpfq/2;
filtdata=zeros(size(data));
[nraw,ncolumns]=size(data);

[A,B] = butter(ordfilt,[lowfq/halfsmpfq highfq/halfsmpfq]);

for(k=1:nraw)
    filtdata(k,:)=filtfilt(A,B,data(k,:));
end

D(EEGlist,:,1) = filtdata;


return

