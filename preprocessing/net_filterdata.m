function filtered_data=net_filterdata(sensor_data,Fs,hp,lp)

EEG.data=single(sensor_data);
EEG.pnts = size(EEG.data,2);
EEG.srate=Fs;
EEG.nbchan= size(EEG.data,1);
EEG.trials=1;
EEG.xmin=0;
EEG.xmax=max(EEG.data(:));
EEG.times= 1:size(EEG.data,2);
EEG.event=[];
nsamples=6600;
newEEG=net_unripple_filter(EEG,hp,lp,nsamples);
filtered_data=newEEG.data;