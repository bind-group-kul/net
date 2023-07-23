function D=net_initialize_eeg(eeg_filename,experiment_filename,output_filename,options_eegconvert,options_posconvert)

NET_folder=net('path');

S = [];
S.output_filename        =  output_filename;
S.raweeg_filename       = eeg_filename;

switch lower(options_eegconvert.format)
    case 'egi'
        D = net_egi2spm(S);
    case 'ant'
        D = net_ant2spm(S);
    case 'bp'
        D = net_bp2spm(S);
    case 'spm'
        D = net_spm2spm(S);
    case 'eeglab'
        D = net_eeglab2spm(S);
    case 'edf'
        D = net_edf2spm(S); %% updated by Mingqi
end


D = chantype(D,[1:size(D,1)],'Other'); %initialize all channels to Other

% added by JS on 06.2022, after initializing all channels to "others"
if not(isempty(options_eegconvert.eeg_channels))
     tmp = str2num(options_eegconvert.eeg_channels);
     if ~isempty(tmp) % for run no_gui
        if ~isnan(tmp) % for run with_gui
            D = chantype(D,str2num(options_eegconvert.eeg_channels),'EEG');
        end
     end
end
if not(isempty(options_eegconvert.eog_channels))
     tmp = str2num(options_eegconvert.eog_channels);
     if ~isempty(tmp) % for run no_gui
        if ~isnan(tmp) % for run with_gui
            D = chantype(D,str2num(options_eegconvert.eog_channels),'EOG');
        end
     end
end
if not(isempty(options_eegconvert.emg_channels))
     tmp = str2num(options_eegconvert.emg_channels);
     if ~isempty(tmp) % for run no_gui
        if ~isnan(tmp) % for run with_gui
            D = chantype(D,str2num(options_eegconvert.emg_channels),'EMG');
        end
     end
end
if not(isempty(options_eegconvert.ecg_channels))
     tmp = str2num(options_eegconvert.ecg_channels);
     if ~isempty(tmp) % for run no_gui
        if ~isnan(tmp) % for run with_gui
            D = chantype(D,str2num(options_eegconvert.ecg_channels),'ECG');
        end
     end
end

% changed by Mingqi 07.2022
if not(isempty(options_eegconvert.kinem_channels))
     tmp = str2num(options_eegconvert.kinem_channels);
     if ~isempty(tmp) % for run no_gui
        if ~isnan(tmp) % for run with_gui
            D = chantype(D,str2num(options_eegconvert.kinem_channels),'KINEM');
        end
     end
end
if not(isempty(options_eegconvert.physio_channels))
     tmp = str2num(options_eegconvert.physio_channels);
     if ~isempty(tmp) % for run no_gui
        if ~isnan(tmp) % for run with_gui
            D = chantype(D,str2num(options_eegconvert.physio_channels),'PHYSIO');
        end
     end
end
if not(isempty(options_eegconvert.behav_channels))
     tmp = str2num(options_eegconvert.behav_channels);
     if ~isempty(tmp) % for run no_gui
        if ~isnan(tmp) % for run with_gui
            D = chantype(D,str2num(options_eegconvert.behav_channels),'BEHAV');
        end
     end
end


D.save;


S = [];
S.D = D;
S.task = 'loadeegsens'; %Loading eeg sensors will be the task to be done
S.source = 'locfile';   % Use a location file for doing the above task
S.sensfile = [NET_folder filesep 'template' filesep 'electrode_position' filesep options_posconvert.template '.sfp'];
S.save = true;
D = spm_eeg_prep(S);



start_t=options_eegconvert.chunck_start;
if isempty(start_t) %isnan
    start_t=0;
end
    
end_t=options_eegconvert.chunck_end;
if isempty(end_t) %isnan
    end_t=0;
end

if start_t>0 || end_t>0

t = time(D);  
clear job
job.data                     = {output_filename};
job.chunk(1).chunk_beg.t_rel = net_secs2hms(start_t);
job.chunk(1).chunk_end.t_rel = net_secs2hms(t(end)-end_t);  % chunking from 2s to end-5 seconds
job.options.overwr           = 1;
job.options.fn_prefix        = 'chk';
job.options.numchunk         = 1;
crc_run_chunking(job);

[ddx,ffx,ext]=fileparts(output_filename);

S         = [];  % changed by DM 26.11.13
S.D       = [ddx filesep 'chk1_' ffx ext]; 
S.outfile = output_filename; % revised by QL, 16.01.2016, for SPM 12;  S.newname = raw_filename; for SPM 8
S.newname = output_filename;
D         = spm_eeg_copy(S); % The function that creates a copy of the mat and dat file and creates a MEEG SPM object-



delete([ddx filesep 'chk1_' ffx '.mat']);
delete([ddx filesep 'chk1_' ffx '.dat']);

end


% converting events to triggers
event=events(D);

%% check existence of .csv file %% This part changed by MZ Sep 27 2022, line 104-135
event_table = [];
if(~isnan(experiment_filename))
    if(exist( experiment_filename, 'file' ))
        if(strcmp(experiment_filename(end-2:end), 'csv'))
            event_table = readtable(experiment_filename);
        else
            error('NET data conversion: experiment events file should be a *.csv file! please check');
        end
    else
        error('NET data conversion: invalid experiment events file!');
    end
else
    fprintf('no external events file found, skip loading external events\n');
end


% check existence of variable external_events
if(~isempty(event_table))
    fprintf('start loading external events... ');
    external_events_num = length(event_table.Event_time);
    initial_events_num=length(event);
    % add external events to event, could not find a way without using for loop
    for iter_event = 1:1:external_events_num
        event(initial_events_num+iter_event).type = event_table.Event_type{iter_event};
        event(initial_events_num+iter_event).value =  event_table.Event_name{iter_event};
        event(initial_events_num+iter_event).duration = event_table.Event_duration(iter_event);
        event(initial_events_num+iter_event).time = event_table.Event_time(iter_event) - start_t;  %deal with chunk_start option for external events
        event(initial_events_num+iter_event).offset = event_table.Offset(iter_event);
    end
    fprintf('completed\n');
end
%%
D = D.events(D, event);
D.triggers = event;
D.save;

if not(options_eegconvert.timedelay==0)
    D = net_timedelay_correct(D, options_eegconvert.timedelay);
end

%This is to eliminate the drift..

D(:,:,1)=detrend(D(:,:,1)')';

%[S,F,T,P]=spectrogram(D(13,:,1),fsample(D),0,fsample(D),fsample(D));

% basic preprocessing steps  (added by DM 23.10.13)
%Send the channel data and sampling frequency as input for performing notch
%filtering at 50 Hz (to remove AC power signal)
D(:,:,1)=net_filter50(D(:,:,1),fsample(D));
D.save;

