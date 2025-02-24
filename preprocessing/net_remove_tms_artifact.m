function new_EEG=net_remove_tms_artifact(processedeeg_filename,options_tms_artifact)

if strcmp(options_tms_artifact.enable, 'on')

% load EEG
D=spm_eeg_load(processedeeg_filename);
list_eeg=selectchannels(D,'EEG');

EEG = pop_fileio([path(D) filesep fname(D)]);
EEG.data = double( EEG.data );

sig=mean((EEG.data).^2,1);

% find artefact
[pks,locs] = findpeaks(sig,'MinPeakHeight',options_tms_artifact.rel_peak_height*median(sig),'MinPeakDistance',round(0.001*options_tms_artifact.peak_distance*EEG.srate));
vect=ones(1,length(sig));
ntp=round(0.001*options_tms_artifact.ntp_artifact*EEG.srate/2);
new_EEG=EEG;

% remove artefact
for i=1:length(locs)

    start=max(locs(i)-ntp,1);
    stop=min(locs(i)+ntp,length(sig));

    if locs(i)-3*ntp > 0
        new_EEG.data(:,start:stop)=EEG.data(:,locs(i)-3*ntp:locs(i)-ntp);
    else
        new_EEG.data(:,start:stop)=EEG.data(:,locs(i)+ntp:locs(i)+3*ntp);
    end
end

D(list_eeg,:,:)= new_EEG.data;
D.save;

end
end
