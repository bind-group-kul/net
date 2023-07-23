function sFile = in_fopen_edf(DataFile)
% IN_FOPEN_EDF: Open a BDF/EDF file (continuous recordings)
%
% USAGE:  sFile = in_fopen_edf(DataFile)

% @=============================================================================
% This software is part of the Brainstorm software:
% http://neuroimage.usc.edu/brainstorm
% 
% Copyright (c)2000-2014 University of Southern California & McGill University
% This software is distributed under the terms of the GNU General Public License
% as published by the Free Software Foundation. Further details on the GPL
% license can be found at http://www.gnu.org/copyleft/gpl.html.
% 
% FOR RESEARCH PURPOSES ONLY. THE SOFTWARE IS PROVIDED "AS IS," AND THE
% UNIVERSITY OF SOUTHERN CALIFORNIA AND ITS COLLABORATORS DO NOT MAKE ANY
% WARRANTY, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
% MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, NOR DO THEY ASSUME ANY
% LIABILITY OR RESPONSIBILITY FOR THE USE OF THIS SOFTWARE.
%
% For more information type "brainstorm license" at command prompt.
% =============================================================================@
%
% Authors: Francois Tadel, 2012
        

%% ===== READ HEADER =====
% Open file
fid = fopen(DataFile, 'r', 'ieee-le');
if (fid == -1)
    error('Could not open file');
end
% Read all fields
hdr.version    = fread(fid, [1  8], '*char');  % Version of this data format ('0       ' for EDF, [255 'BIOSEMI'] for BDF)
hdr.patient_id = fread(fid, [1 80], '*char');  % Local patient identification
hdr.rec_id     = fread(fid, [1 80], '*char');  % Local recording identification
hdr.startdate  = fread(fid, [1  8], '*char');  % Startdate of recording (dd.mm.yy)
hdr.starttime  = fread(fid, [1  8], '*char');  % Starttime of recording (hh.mm.ss) 
hdr.hdrlen     = str2double(fread(fid, [1 8], '*char'));  % Number of bytes in header record 
hdr.unknown1   = fread(fid, [1 44], '*char');             % Reserved ('24BIT' for BDF)
hdr.nrec       = str2double(fread(fid, [1 8], '*char'));  % Number of data records (-1 if unknown)
hdr.reclen     = str2double(fread(fid, [1 8], '*char'));  % Duration of a data record, in seconds 
hdr.nsignal    = str2double(fread(fid, [1 4], '*char'));  % Number of signals in data record
% Check file integrity
if isnan(hdr.nsignal) || isempty(hdr.nsignal) || (hdr.nsignal ~= round(hdr.nsignal)) || (hdr.nsignal < 0)
    error('File header is corrupted.');
end
% Read values for each nsignal
for i = 1:hdr.nsignal
    hdr.signal(i).label = strtrim(fread(fid, [1 16], '*char'));
end
for i = 1:hdr.nsignal
    hdr.signal(i).type = strtrim(fread(fid, [1 80], '*char'));
end
for i = 1:hdr.nsignal
    hdr.signal(i).unit = strtrim(fread(fid, [1 8], '*char'));
end
for i = 1:hdr.nsignal
    hdr.signal(i).physical_min = str2double(fread(fid, [1 8], '*char'));
end
for i = 1:hdr.nsignal
    hdr.signal(i).physical_max = str2double(fread(fid, [1 8], '*char'));
end
for i = 1:hdr.nsignal
    hdr.signal(i).digital_min = str2double(fread(fid, [1 8], '*char'));
end
for i = 1:hdr.nsignal
    hdr.signal(i).digital_max = str2double(fread(fid, [1 8], '*char'));
end
for i = 1:hdr.nsignal
    hdr.signal(i).filters = strtrim(fread(fid, [1 80], '*char'));
end
for i = 1:hdr.nsignal
    hdr.signal(i).nsamples = str2double(fread(fid, [1 8], '*char'));
end
for i = 1:hdr.nsignal
    hdr.signal(i).unknown2 = fread(fid, [1 32], '*char');
end
% Close file
fclose(fid);


%% ===== RECONSTRUCT INFO =====
% Individual signal gain
for i = 1:hdr.nsignal
    switch (hdr.signal(i).unit)
        case 'mV',  hdr.signal(i).gain = 1e3;
        case 'uV',  hdr.signal(i).gain = 1e6;
        otherwise,  hdr.signal(i).gain = 1;
    end
    hdr.signal(i).sfreq = hdr.signal(i).nsamples ./ hdr.reclen;
end
% Preform some checks
if (hdr.nrec == -1)
    error('Cannot handle files where the number of recordings is unknown.');
end
% Find annotations channel
iAnnotChan  = find(strcmpi({hdr.signal.label}, 'EDF Annotations'), 1);
iStatusChan = find(strcmpi({hdr.signal.label}, 'Status'), 1);
iOtherChan = setdiff(1:hdr.nsignal, [iAnnotChan iStatusChan]);
if isempty(iOtherChan)
    error('This file does not contain any data channel.');
end
% Read events preferencially from the EDF Annotations track
if ~isempty(iAnnotChan);
    iEvtChan = iAnnotChan;
elseif ~isempty(iStatusChan);
    iEvtChan = iStatusChan;
else
    iEvtChan = [];
end
% Detect channels with inconsistent sampling frenquency
iErrChan = find([hdr.signal(iOtherChan).sfreq] ~= hdr.signal(iOtherChan(1)).sfreq);
if ~isempty(iErrChan)
    error('Files with mixed sampling rates are not supported yet.');
end
% Detect interrupted signals (time non-linear)
hdr.interrupted = ischar(hdr.unknown1) && (length(hdr.unknown1) >= 5) && isequal(hdr.unknown1(1:5), 'EDF+D');
if hdr.interrupted
    warning('Interrupted EDF file ("EDF+D"): requires conversion to "EDF+C"');
end


%% ===== CREATE BRAINSTORM SFILE STRUCTURE =====
% Initialize returned file structure
sFile = db_template('sfile');
% Add information read from header
sFile.byteorder  = 'l';
sFile.filename   = DataFile;
if (uint8(hdr.version(1)) == uint8(255))
    sFile.format = 'EEG-BDF';
    sFile.device = 'BDF';
else
    sFile.format = 'EEG-EDF';
    sFile.device = 'EDF';
end
sFile.channelmat = [];
sFile.header     = hdr;
% Comment: short filename
[tmp__, sFile.comment, tmp__] = bst_fileparts(DataFile);
% Consider that the sampling rate of the file is the sampling rate of the first signal
sFile.prop.sfreq   = hdr.signal(iOtherChan(1)).sfreq;
sFile.prop.samples = [0, hdr.signal(iOtherChan(1)).nsamples * hdr.nrec - 1];
sFile.prop.times   = sFile.prop.samples ./ sFile.prop.sfreq;
sFile.prop.nAvg    = 1;
% No info on bad channels
sFile.channelflag = ones(hdr.nsignal,1);


%% ===== CREATE EMPTY CHANNEL FILE =====
ChannelMat.Comment = [sFile.device ' channels'];
ChannelMat.Channel = repmat(db_template('channeldesc'), [1, hdr.nsignal]);
% For each channel
for i = 1:hdr.nsignal
    % If is the annotation channel
    if ~isempty(iAnnotChan) && (i == iAnnotChan)
        ChannelMat.Channel(i).Type = 'EDF';
        ChannelMat.Channel(i).Name = 'Annotations';
    elseif ~isempty(iStatusChan) && (i == iStatusChan)
        ChannelMat.Channel(i).Type = 'BDF';
        ChannelMat.Channel(i).Name = 'Status';
    % Regular channels
    else
        % Label format: "Type Name" or "Name"
        iSpace = find(hdr.signal(i).label == ' ', 1);
        if ~isempty(iSpace)
            ChannelMat.Channel(i).Name = hdr.signal(i).label(iSpace+1:end);
            if (iSpace < 3)
                ChannelMat.Channel(i).Type = 'EEG';
            else
                ChannelMat.Channel(i).Type = hdr.signal(i).label(1:iSpace-1);
            end
        else
            ChannelMat.Channel(i).Name = hdr.signal(i).label;
            ChannelMat.Channel(i).Type = 'EEG';
        end
        % Overwrite type using the "type" field (not always filled)
        if ~isempty(hdr.signal(i).type)
            if (length(hdr.signal(i).type) == 3)
                ChannelMat.Channel(i).Type = hdr.signal(i).type;
            elseif isequal(hdr.signal(i).type, 'Active Electrode')
                ChannelMat.Channel(i).Type = 'EEG';
            else
                ChannelMat.Channel(i).Type = 'Misc';
            end
        end
    end
    ChannelMat.Channel(i).Loc     = [0; 0; 0];
    ChannelMat.Channel(i).Orient  = [];
    ChannelMat.Channel(i).Weight  = 1;
    ChannelMat.Channel(i).Comment = hdr.signal(i).type;
end
% If there are only "Misc" and no "EEG" channels: rename to "EEG"
iMisc = find(strcmpi({ChannelMat.Channel.Type}, 'Misc'));
iEeg  = find(strcmpi({ChannelMat.Channel.Type}, 'EEG'));
if ~isempty(iMisc) && isempty(iEeg)
    [ChannelMat.Channel(iMisc).Type] = deal('EEG');
end
% Return channel structure
sFile.channelmat = ChannelMat;


%% ===== READ EDF ANNOTATION CHANNEL =====
if ~isempty(iEvtChan)
    % Set reading options
    ImportOptions = db_template('ImportOptions');
    ImportOptions.ImportMode = 'Time';
    ImportOptions.UseSsp     = 0;
    ImportOptions.UseCtfComp = 0;
    % Read EDF annotations
    if strcmpi(ChannelMat.Channel(iEvtChan).Type, 'EDF')
        % Read annotation channel epoch by epoch
        evtList = {};
        for irec = 1:hdr.nrec
            % Sample indices for the current epoch (=record)
            SampleBounds = [irec-1,irec] * sFile.header.signal(iEvtChan).nsamples - [0,1];
            % Read record
            F = char(in_fread(sFile, 1, SampleBounds, iEvtChan, ImportOptions));
            % Split after removing the 0 values
            Fsplit = str_split(F(F~=0), 20);
            % Get first time stamp
            if (irec == 1)
                t0 = str2double(char(Fsplit{1}));
            end
            % If there is an initial time: 3 values (ex: "+44.00000+44.47200Event1)
            if (mod(length(Fsplit),2) == 1) && (length(Fsplit) >= 3)
                iStart = 2;
            % If there is no initial time: 2 values (ex: "+44.00000Epoch1)
            elseif (mod(length(Fsplit),2) == 0)
                iStart = 1;
            else
                continue;
            end
            % If there is information on this channel
            for iAnnot = iStart:2:length(Fsplit)
                % If there are no 2 values, skip
                if (iAnnot == length(Fsplit))
                    break;
                end
                % Split time in onset/duration
                t_dur = str_split(Fsplit{iAnnot}, 21);
                % Get time and label
                t = str2double(t_dur{1});
                label = Fsplit{iAnnot+1};
                if (length(t_dur) > 1)
                    duration = str2double(t_dur{2});
                else
                    duration = 0;
                end
                if isempty(t) || isnan(t) || isempty(label) || (~isempty(duration) && isnan(duration))
                    continue;
                end
                % Add to list of read events
                evtList(end+1,:) = {label, (t-t0) + [0;duration]};
            end
        end

        % If there are events: create a create an events structure
        if ~isempty(evtList)
            % Initialize events list
            sFile.events = repmat(db_template('event'), 0);
            % Events list
            [uniqueEvt, iUnique] = unique(evtList(:,1));
            uniqueEvt = evtList(sort(iUnique),1);
            % Build events list
            for iEvt = 1:length(uniqueEvt)
                % Find all the occurrences of this event
                iOcc = find(strcmpi(uniqueEvt{iEvt}, evtList(:,1)));
                % Concatenate all times
                t = [evtList{iOcc,2}];
                % If second row is equal to the first one (no extended events): delete it
                if all(t(1,:) == t(2,:))
                    t = t(1,:);
                end
                % Set event
                sFile.events(iEvt).label   = uniqueEvt{iEvt};
                sFile.events(iEvt).times   = t;
                sFile.events(iEvt).samples = round(t .* sFile.prop.sfreq);
                sFile.events(iEvt).epochs  = 1 + 0*t(1,:);
                sFile.events(iEvt).select  = 1;
            end
        end
        
    % BDF Status line
    elseif strcmpi(ChannelMat.Channel(iEvtChan).Type, 'BDF')
        % Process it bit by bit
        events = process_evt_read('Compute', sFile, ChannelMat.Channel(iEvtChan).Name, 'bit');
        sFile.events = events;
        % Remove the 'Status: ' string in front of the events
        for i = 1:length(sFile.events)
            sFile.events(i).label = strrep(sFile.events(i).label, 'Status: ', '');
        end
        % Group events by time
        sFile.events = process_evt_grouptime('Compute', sFile.events);
    end
end

    
    

