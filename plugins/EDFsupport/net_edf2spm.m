function D = net_edf2spm( X )
%NET_EDF2SPM Convert a EDF format to SPM MEEG object
%   Detailed explanation goes here
%    
%   OUTPUT:
%       D: SPM12 MEEG object
%   INPUT:
%       X: input parameter structure
%          X.raweeg_filename: full path of the raw EDF data file
%          X.output_filename: path of the output SPM MEEG object path

% by Mingqi Zhao

%% check
if (~isfield(X, 'raweeg_filename'))
    error('EEG filename must be specified!');
end
if (~isfield(X, 'output_filename'))
    error('Output filename must be specified!');
end

%% load EDF data
edf_file = X.raweeg_filename;
[data, header, ~] = lab_read_edf(edf_file);

%% create and write a SPM MEEG object
%output_file = X.output_filename;
    
    % convert
    S = [];
    S.dataset = X.raweeg_filename;
    S.channels = 'all';
    S.checkboundary = 1;
    S.usetrials = 1; %we don't use a trail definition file
    S.datatype = 'float32-le'; %input data is of 32 bit float format
    S.eventpadding = 0; %This is for trial borders, we don't use them
    S.saveorigheader = 0; % Don't keep the original header
    S.inputformat = 'edf'; % we don't use it
    S.outfile = X.output_filename; %Save the converted file with a prefix spm_
    S.continuous = true; %The data is not epoched it is continuous

    disp('Data Conversion: Reading data...');
    D = spm_eeg_convert(S);
    
    % process events
    trigger_num = length(header.events.POS);
    triggers = [];
    for iter_trig = 1:trigger_num
        triggers(iter_trig).type = [];
        triggers(iter_trig).value = header.events.TYP{iter_trig};
        triggers(iter_trig).duration = header.events.DUR(iter_trig);
        triggers(iter_trig).time = header.events.POS(iter_trig);
        triggers(iter_trig).offset = header.events.OFF(iter_trig);
    end
    
    % add triggers
    D = D.events(D, triggers);
    
    % process chantype and chanlabel
    ch_num = D.size(1);
    for iter_ch = 1:ch_num
        tmp_chanlabel = header.channels(iter_ch, :);
        for iter_l = length(tmp_chanlabel):-1:1
            if(strcmp(tmp_chanlabel(iter_l), ' '))
                tmp_chanlabel(iter_l) = [];
            else
                break;
            end
            
        end
        
        loc = find(tmp_chanlabel == ' ');
        if(isempty(loc))
            disp('Warning: could not determin channel type according to EDF file, further check may be needed!');
        else
            ch_types{1, iter_ch} = tmp_chanlabel(1:loc(1)-1);
            ch_labels{1, iter_ch} = tmp_chanlabel(loc(1)+1:end);
        end
    end
    D = D.chantype(D, ch_types);
    D = D.chanlabels(D, ch_labels);
    
    D.save;

end


function [data,header,cfg] = lab_read_edf(filename,cfg)
% lab_read_edf() - read eeg data in EDF+ format.
%
% Orignal Code-file:
% Jeng-Ren Duann, CNL/Salk Inst., 2001-12-21
%
% Modifications:
% 03-21-02 editing hdr, add help -ad 
% 09-17-12 FHatz Neurology Basel (Support for edf+)
%
% Usage: 
%    >> [data,header] = read_edf(filename);
%
% Input:
%    filename - file name of the eeg data
% 
% Output:
%    data   - eeg data in (channel, timepoint)
%    header - structured information about the read eeg data
%      header.events - events (structure: .POS .DUR .TYP)
%      header.numtimeframes - length of EEG data
%      header.samplingrate = samplingrate
%      header.numchannels - number of channels
%      header.numauxchannels - number of non EEG channels (only ECG channel is recognized)
%      header.channels - channel labels
%      header.year - timestamp recording
%      header.month - timestamp recording
%      header.day - timestamp recording
%      header.hour - timestamp recording
%      header.minute - timestamp recording
%      header.second - timestamp recording
%      header.ID - EEG number
%      header.technician - responsible investigator or technician
%      header.equipment - used equipment
%      header.subject.ID - local patient identification
%      header.subject.sex - M or F
%      header.subject.name - patients name
%      header.subject.year - birthdate
%      header.subject.month - birthdate
%      header.subject.day - birthdate
%      header.aux - auxillary channels / samplingrates auf auxillary channels
%      header.hdr - original header
if ~exist('cfg','var')
    cfg = [];
end

if nargin < 1
    help readedf;
    return;
end;
    
fp = fopen(filename,'r','ieee-le');
if fp == -1,
  error('File not found ...!');
end

hdr.intro = setstr(fread(fp,256,'uchar')');
hdr.length = str2num(hdr.intro(185:192));
hdr.records = str2num(hdr.intro(237:244));
hdr.duration = str2num(hdr.intro(245:252));
hdr.channels = str2num(hdr.intro(253:256));
hdr.channelname = setstr(fread(fp,[16,hdr.channels],'char')');
hdr.transducer = setstr(fread(fp,[80,hdr.channels],'char')');
hdr.physdime = setstr(fread(fp,[8,hdr.channels],'char')');
hdr.physmin = str2num(setstr(fread(fp,[8,hdr.channels],'char')'));
hdr.physmax = str2num(setstr(fread(fp,[8,hdr.channels],'char')'));
hdr.digimin = str2num(setstr(fread(fp,[8,hdr.channels],'char')'));
hdr.digimax = str2num(setstr(fread(fp,[8,hdr.channels],'char')'));
hdr.prefilt = setstr(fread(fp,[80,hdr.channels],'char')');
hdr.numbersperrecord = str2num(setstr(fread(fp,[8,hdr.channels],'char')'));

if isempty(hdr.length)
    disp('   Abort edf-read: no valid edf-file')
    data = [];
    header = [];
    return
end
fseek(fp,hdr.length,-1);
data = fread(fp,'int16');
fclose(fp);
clearvars fp

header.hdr = hdr;
header.samplingrate = hdr.numbersperrecord(1) / hdr.duration;
header.numchannels = hdr.channels;
header.numauxchannels = 0;
header.channels = hdr.channelname;
tmp = textscan(hdr.intro(89:168),'%s');
tmp = tmp{1,1};
try %#ok<TRYNC>
    [header.year, header.month, header.day] = datevec(tmp(2,1));
    header.hour = str2num(hdr.intro(177:178));
    header.minute = str2num(hdr.intro(180:181));
    header.second = str2num(hdr.intro(183:184));
    header.ID = tmp{3,1};
    header.technician = tmp{4,1};
    header.equipment = tmp{5,1};
    tmp = textscan(hdr.intro(9:88),'%s');
    tmp = tmp{1,1};
    header.subject.ID = tmp{1,1};
    header.subject.sex = tmp{2,1};
    header.subject.name = tmp{4,1};
    if ~strcmp(tmp(3,1),'X')
        [header.subject.year, header.subject.month, header.subject.day] = datevec(tmp(3,1));
    end
    clearvars tmp
end

% reshape data
data = reshape(data,sum(hdr.numbersperrecord),hdr.records);

% Look for annotations
m = size(hdr.channelname,1);
header.events.TYP = {};
header.events.POS = [];
header.events.DUR = [];
header.events.OFF = [];
while strcmp(hdr.channelname(m,1:15),'EDF Annotations')
    header.numchannels = header.numchannels -1;
    header.channels = header.channels(1:end-1,:);
    eventstmp = data((end - hdr.numbersperrecord(m) + 1):end,:);
    data = data(1:end-hdr.numbersperrecord(m),:);
    for i = 1:hdr.records
        tmp_eventsall = typecast(int16(eventstmp(:,i)),'uint8')';
        
        frame_start = find(tmp_eventsall == 43);
        frame_stop = find(tmp_eventsall == 00);
        
        if(length(frame_start) <= 1) % this offset do not contain any events;
            continue;
        end
        
        if(length(frame_start) > length(frame_stop))
            error('Events data corrupted in EDF+ file, please check your data.');
        end
        frame_start = frame_start(2:end);
        frame_stop = frame_stop(2:end);
        frame_num = length(frame_start);
        for iter_f = 1:frame_num
            tmp_frame = tmp_eventsall(frame_start(iter_f)+1:frame_stop(iter_f)-1);
            
            % find POS segment
            sep_POS = find(tmp_frame == 20 | tmp_frame == 21);
            if(isempty(sep_POS))
                continue;
            else
                tmp_POS = str2double(native2unicode(tmp_frame(1:sep_POS(1)-1)));
                if(isnan(tmp_POS))
                    disp('Warning: event time can not be NaN, please check your data');
                    continue;
                end
                
                % find DUR segment
                tmp_frame = tmp_frame(sep_POS(1):end);
                sep_DUR = find(tmp_frame == 21);
            
                if(tmp_frame(1) == 21) % DUR contained
                    end_DUR = find(tmp_frame == 20);
                    if(sep_DUR+1 > end_DUR-1)
                        disp('Warning: this frame duration corrupted');
                        continue;
                    else
                        tmp_DUR = str2double(native2unicode(tmp_frame(sep_DUR+1:end_DUR-1)));
                        if(isnan(tmp_DUR))
                            tmp_DUR = [];
                        end
                    end
                    tmp_frame = tmp_frame(end_DUR+1:end);
                    
                elseif(tmp_frame(1) == 20) % no DUR
                    tmp_DUR = [];
                    tmp_frame = tmp_frame(2:end);
                end
                
                % find TPY
                if(tmp_frame(end) == 20)
                    tmp_frame(tmp_frame == 20) = [];
                    tmp_TPY = native2unicode(tmp_frame);
                else
                    tmp_TPY = native2unicode(tmp_frame);
                end
                if(isempty(tmp_TPY))
                    tmp_TPY = 'NoName';
                end
                
                % all elements found frome the frame, fill this event to
                % structure;
                header.events.TYP = cat(2, header.events.TYP, {tmp_TPY});
                header.events.POS = [header.events.POS, tmp_POS];
                header.events.DUR = [header.events.DUR, tmp_DUR];
                header.events.OFF = [header.events.OFF, i-1]; 
            end
        end
        m = m - 1;
    end
end

auxchannel = 0;
while m > 1 && ~(sum(hdr.numbersperrecord(1:m)) == hdr.numbersperrecord(1)*m)
    header.numchannels = header.numchannels -1;
    header.channels = header.channels(1:end-1,:);
    header.aux{auxchannel+1,1} = reshape(data((end - hdr.numbersperrecord(m) + 1):end,:),[1 (hdr.numbersperrecord(m)*size(data,2))]);
    header.aux{auxchannel+1,2} = hdr.numbersperrecord(m) / hdr.duration;
    data = data(1:end-hdr.numbersperrecord(m),:);
    m = m - 1;
    auxchannel = auxchannel + 1;
end

data = reshape(data,hdr.numbersperrecord(1),m,hdr.records);
if exist('time_stamp','var')
    tmp = zeros(m,max(time_stamp) + hdr.numbersperrecord(1) -1);
    time_stamp = round(time_stamp);
    for i=1:hdr.records,
        tmp(:,time_stamp(i):(time_stamp(i)+ hdr.numbersperrecord(1)-1)) = data(:,:,i)';
    end
    data = tmp;
    clearvars tmp
else
    data = permute(data,[2 1 3]);
    data = reshape(data,m,hdr.numbersperrecord(1)*hdr.records);
end

% Scale data
Scale = (hdr.physmax-hdr.physmin)./(hdr.digimax-hdr.digimin);
DC = hdr.physmin - Scale .* hdr.digimin;
Scale = Scale(1:size(data,1),:);
DC = DC(1:size(data,1),:);
tmp = find(Scale < 0);
Scale(tmp) = ones(size(tmp));
DC(tmp) = zeros(size(tmp));
clearvars tmp
data = (sparse(diag(Scale)) * data) + repmat(DC,1,size(data,2));

% Look for extra channels
m = size(data,1);
extrachannel = zeros(1,m);
includeref = false;
haveref = false;
while m > 1
    if ~isempty(strfind(upper(header.channels(m,:)),'ECG')) | ~isempty(strfind(upper(header.channels(m,:)),'EKG'))
        extrachannel(1,m) = 1;
        header.ecg_ch = m;
    elseif ~isempty(strfind(upper(header.channels(m,:)),'EOG'))
        extrachannel(1,m) = 1;
        header.eog_ch = m;
    elseif ~isempty(strfind(upper(header.channels(m,:)),'PHOTIC'))
        extrachannel(1,m) = 1;
    elseif ~isempty(strfind(upper(header.channels(m,:)),'REF')) & ~strcmpi(header.channels(m,1:3),'REF')
        includeref = true;
    elseif ~isempty(strfind(upper(header.channels(m,:)),'REF')) & strcmpi(header.channels(m,1:3),'REF')
        haveref = true;
    end
    m = m - 1;
end
if includeref == true & haveref == false
    extrachannel(1,end+1) = 0;
    data(end+1,:) = zeros(1,size(data,2));
    header.channels(end+1,1:3) = 'REF';
    header.ref_chan = size(data,1);
end
[~,sortchans] = sort(extrachannel);
data = data(sortchans,:);
header.channels = header.channels(sortchans,:);
if isfield(header,'ecg_ch')
    header.ecg_ch = find(sortchans == header.ecg_ch);
end
if isfield(header,'eog_ch')
    header.eog_ch = find(sortchans == header.eog_ch);
end
if isfield(header,'ref_chan')
    header.ref_chan = find(sortchans == header.ref_chan);
end
header.numchannels = size(data,1);
header.numauxchannels = sum(extrachannel);
header.numdatachannels = header.numchannels - header.numauxchannels;
header.numtimeframes = size(data,2);
header.version=[];
header.millisecond=0;
end
