%% Purpose
% 1. Main function that converts EEGLAB files to SPM format.
% 2. Create sensor information compatible to field trip structure.
% 3. Add EOG, EMG signals.
% 4. Do the notch filtering at 50 Hz and detrending.

%%
function D = net_eeglab2spm(X)

% Main function for converting different M/EEG formats to SPM8 format.
% FORMAT D = spm_eeg_convert(S)
% S                - can be string (file name) or struct (see below)
%
% If S is a struct it can have the optional following fields:
% X.raweeg_filename        - file name
% X.output_file     -


%Check if both raw data and position files are specified

if ~isfield(X, 'raweeg_filename'),    error('EEG filename must be specified!');
else
    raweeg_filename = X.raweeg_filename;
end

output_file=X.output_filename;

disp('Data Conversion: Reading data...');
EEG=pop_loadset(raweeg_filename);

%Supply details in a struct format for the SPM function to start the file
%conversion

% load(raweeg_filename);
D = [];
D.Fsample = EEG.srate;
% nsampl = size(EEG.data,2);

dat=double(EEG.data);
[nchan,nsampl,ntrial]=size(dat);

if ntrial>1
    dat2=zeros(nchan,nsampl*ntrial);
    for i=1:ntrial
        dat2(:,(i-1)*nsampl+1:i*nsampl)=dat(:,:,i);
    end
    
    nsampltot = nsampl*ntrial;
    
    for i=1:length(EEG.event)
        EEG.event(i).time=-EEG.times(1)/1000+(i-1)*nsampl/EEG.srate;
    end
else
    nsampltot=nsampl;
    dat2=dat;

    for i=1:length(EEG.event)
        EEG.event(i).time=EEG.event(i).latency/EEG.srate;
    end
end

% amp=mean(abs(dat),2);
% dat=dat(amp>0,:);
% chansel = 1:size(dat,1);
% nchan=length(chansel);

D.channels = repmat(struct('bad', 0), 1, nchan);
D.Nsamples = nsampltot;

%[D.channels(:).label] = deal(hdr.label{chansel});
% for i=1:length(EEG.event)
%     EEG.event(i).time=(EEG.event(i).sample)/EEG.srate;
% end

D.trials(1).label  = 'triggers';
D.trials(1).events = EEG.event;
D.trials(1).onset  = 0;

[folder,filename]=fileparts(output_file);

D.path = folder;
D.fname = [filename '.mat'];

label=cell(1,nchan);
for i=1:nchan
    label{i}=EEG.chanlocs(i).labels;
%     label{i}=['E' num2str(i)];
end

D.chanlabels=label;
D.data = file_array([output_file(1:end-4) '.dat'], [nchan nsampltot], 'float32-le');
% D.data = file_array([output_file(1:end-4) '.dat'], [nchan nsampl], 'float32-le');

initialise(D.data);

D = meeg(D);
D = chanlabels(D, 1:nchan, label);
D(:,:,1) = dat2;
% D(:,:,1) = dat;
D.save;

%%
% Revision history:
%{
2014-04-13
    v0.1 Updated the file based on initial versions from Dante and
    Quanying(Revision author : Sri).
2024-01-24
    v0.1 Dante Mantini
%}