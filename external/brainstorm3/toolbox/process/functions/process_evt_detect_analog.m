function varargout = process_evt_detect_analog( varargin )
% PROCESS_EVT_DETECT_ANALOG: Detect the trigger on an analog channel
%
% USAGE:  OutputFiles = process_evt_detect_analog('Run', sProcess, sInputs)
%                 evt = process_evt_detect('Compute', F, TimeVector, OPTIONS, Fmask)
%                 evt = process_evt_detect('Compute', F, TimeVector, OPTIONS)
%             OPTIONS = process_evt_detect('Compute')                                : Get the default options structure

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
% Authors: Elizabeth Bock, Francois Tadel, 2013

macro_methodcall;
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Events: Detect analog triggers';
    sProcess.FileTag     = '';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Import recordings';
    sProcess.Index       = 14;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'raw', 'data'};
    sProcess.OutputTypes = {'raw', 'data'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    % Event name
    sProcess.options.eventname.Comment = 'Event name: ';
    sProcess.options.eventname.Type    = 'text';
    sProcess.options.eventname.Value   = 'AnalogEvent';
    % Separator
    sProcess.options.separator.Type = 'separator';
    sProcess.options.separator.Comment = ' ';
    % Channel name
    sProcess.options.channelname.Comment = 'Channel name: ';
    sProcess.options.channelname.Type    = 'channelname';
    sProcess.options.channelname.Value   = 'UADC001';
    % Time window
    sProcess.options.timewindow.Comment = 'Time window:';
    sProcess.options.timewindow.Type    = 'timewindow';
    sProcess.options.timewindow.Value   = [];
    % Threshold
    sProcess.options.threshold.Comment = 'Threshold: ';
    sProcess.options.threshold.Type    = 'value';
    sProcess.options.threshold.Value   = {2, ' x std', 2};
    % Blanking period
    sProcess.options.blanking.Comment = 'Min duration between two events: ';
    sProcess.options.blanking.Type    = 'value';
    sProcess.options.blanking.Value   = {1, 's', []};
    % Separator
    sProcess.options.sep2.Type = 'separator';
    sProcess.options.sep2.Comment = ' ';
    % Filter
    sProcess.options.bandpass.Comment = 'Filter before detection (0=none): ';
    sProcess.options.bandpass.Type    = 'range';
    sProcess.options.bandpass.Value   = {[], 'Hz', 2};
    % Channel name
    sProcess.options.refEvent.Comment = 'Reference event (empty=none): ';
    sProcess.options.refEvent.Type    = 'text';
    sProcess.options.refEvent.Value   = '';
    % Enable pullup offset
    sProcess.options.ispullup.Comment = 'Remove DC Offset';
    sProcess.options.ispullup.Type    = 'checkbox';
    sProcess.options.ispullup.Value   = 1;
    % Enable classification
    sProcess.options.isclassify.Comment = 'Enable classification';
    sProcess.options.isclassify.Type    = 'checkbox';
    sProcess.options.isclassify.Value   = 0;    
end

%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    Comment = ['Detect: ', sProcess.options.eventname.Value];
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>   
    % ===== GET OPTIONS =====
    % Event name
    evtName = strtrim(sProcess.options.eventname.Value);
    chanName = strtrim(sProcess.options.channelname.Value);
    if isempty(evtName) || isempty(chanName)
        bst_report('Error', sProcess, [], 'Event and channel names must be specified.');
        OutputFiles = {};
        return;
    end

    % Ignore bad segments
    % => Consider that if the event name contains "bad", we need to include the bad segments. If not, we ignore them.
    isIgnoreBad = isempty(strfind(lower(evtName), 'bad'));
    % Prepare options structure for the detection function
    OPTIONS = Compute();
    OPTIONS.threshold    = sProcess.options.threshold.Value{1};
    OPTIONS.blanking     = sProcess.options.blanking.Value{1};
    OPTIONS.ispullup     = sProcess.options.ispullup.Value;
    OPTIONS.isclassify   = sProcess.options.isclassify.Value;
    OPTIONS.refEvent     = strtrim(sProcess.options.refEvent.Value);
    OPTIONS.bandpass     = sProcess.options.bandpass.Value{1};
    
    % Time window to process
    if isfield(sProcess.options, 'timewindow') && isfield(sProcess.options.timewindow, 'Value') && iscell(sProcess.options.timewindow.Value) && ~isempty(sProcess.options.timewindow.Value)
        TimeWindow = sProcess.options.timewindow.Value{1};
        if (TimeWindow(1) >= TimeWindow(2)) 
            bst_report('Error', sProcess, [], 'Invalid time definition.');
            OutputFiles = {};
            return;
        end
    else
        TimeWindow = [];
    end
    
    % Get current progressbar position
    progressPos = bst_progress('get');
    nEvents = 0;
    nTotalOcc = 0;
    
    % For each file
    iOk = false(1,length(sInputs));
    for iFile = 1:length(sInputs)
        % ===== GET DATA =====
        % Progress bar
        bst_progress('text', 'Reading channel to process...');
        bst_progress('set', progressPos + round(iFile / length(sInputs) / 3 * 100));
        % Load the raw file descriptor
        isRaw = strcmpi(sInputs(iFile).FileType, 'raw');
        if isRaw
            DataMat = in_bst_data(sInputs(iFile).FileName, 'F', 'Time');
            sFile = DataMat.F;
        else
            DataMat = in_bst_data(sInputs(iFile).FileName, 'Time');
            sFile = in_fopen(sInputs(iFile).FileName, 'BST-DATA');
        end
        % Process only continuous files
        if ~isempty(sFile.epochs)
            bst_report('Error', sProcess, sInputs(iFile), 'This function can only process continuous recordings (no epochs).');
            continue;
        end
        % Get channel to process
        iChannel = find(strcmpi({sFile.channelmat.Channel.Name}, chanName));
        if isempty(iChannel)
            bst_report('Error', sProcess, sInputs(iFile), 'Channel name not found in the channel file.');
            continue;
        elseif (length(iChannel) > 1)
            bst_report('Error', sProcess, sInputs(iFile), 'Found more than one channel with this name in the channel file.');
            continue;
        end
        % Read channel to process
        if ~isempty(TimeWindow)
            SamplesBounds = sFile.prop.samples(1) + bst_closest(TimeWindow, DataMat.Time) - 1;
        else
            SamplesBounds = [];
        end
        [F, TimeVector] = in_fread(sFile, 1, SamplesBounds, iChannel);
        % If nothing was read
        if isempty(F)
            bst_report('Error', sProcess, sInputs(iFile), 'Time window is not valid.');
            continue;
        end
        
        % ===== Reference event =====
        EventSamps = [];
        if ~isempty(OPTIONS.refEvent)
            ind = find(strcmp({sFile.events.label},OPTIONS.refEvent));
            EventSamps = sFile.events(ind).samples;
        end
        
        % ===== BAD SEGMENTS =====
        % If ignore bad segments
        Fmask = [];
        if isIgnoreBad
            % Get list of bad segments in file
            badSeg = panel_record('GetBadSegments', sFile);
            % Adjust with beginning of file
            badSeg = badSeg - sFile.prop.samples(1) + 1;
            if ~isempty(badSeg)
                % Create file mask
                Fmask = true(size(F));
                % Loop on each segment: mark as bad
                for iSeg = 1:size(badSeg, 2)
                    Fmask(badSeg(1,iSeg):badSeg(2,iSeg)) = false;
                end
            end
        end
        
        % ===== DETECT PEAKS =====
        % Progress bar
        bst_progress('text', 'Detecting peaks...');
        bst_progress('set', progressPos + round(2 * iFile / length(sInputs) / 3 * 100));
        % Perform detection
        detectedEvt = Compute(F, TimeVector, EventSamps, OPTIONS, Fmask);

        % ===== CREATE EVENTS =====
        sEvent = [];
        % Basic events structure
        if ~isfield(sFile, 'events') || isempty(sFile.events)
            sFile.events = repmat(db_template('event'), 0);
        end
        % Process each event type separately
        for i = 1:length(detectedEvt)
            % Event name
            if (i > 1)
                newName = sprintf('%s%d', evtName, i);
            else
                newName = evtName;
            end
            % Get the event to create
            iEvt = find(strcmpi({sFile.events.label}, newName));
            % Existing event: reset it
            if ~isempty(iEvt)
                sEvent = sFile.events(iEvt);
                sEvent.epochs  = [];
                sEvent.samples = [];
                sEvent.times   = [];
                sEvent.reactTimes = [];
            % Else: create new event
            else
                % Initialize new event
                iEvt = length(sFile.events) + 1;
                sEvent = db_template('event');
                sEvent.label = newName;
                % Color
                ColorTable = panel_record('GetEventColorTable');
                iColor = mod(iEvt - 1, length(ColorTable)) + 1;
                sEvent.color = ColorTable(iColor,:);
            end
            % Times, samples, epochs
            sEvent.times   = detectedEvt{i};
            sEvent.samples = round(sEvent.times .* sFile.prop.sfreq);
            sEvent.epochs  = ones(1, size(sEvent.times,2));
            % Add to events structure
            sFile.events(iEvt) = sEvent;
            nEvents = nEvents + 1;
            nTotalOcc = nTotalOcc + size(sEvent.times, 2);
        end
        
        % ===== SAVE RESULT =====
        % Progress bar
        bst_progress('text', 'Saving results...');
        bst_progress('set', progressPos + round(3 * iFile / length(sInputs) / 3 * 100));
        % Only save changes if something was detected
        if ~isempty(sEvent)
            % Report changes in .mat structure
            if isRaw
                DataMat.F = sFile;
            else
                DataMat.Events = sFile.events;
            end
            DataMat = rmfield(DataMat, 'Time');
            % Save file definition
            bst_save(file_fullpath(sInputs(iFile).FileName), DataMat, 'v6', 1);
            % Report number of detected events
            bst_report('Info', sProcess, sInputs(iFile), sprintf('%s: %d events detected in %d categories', chanName, nTotalOcc, nEvents));
        else
            bst_report('Warning', sProcess, sInputs(iFile), ['No event detected on channel "' chanName '".']);
        end
        iOk(iFile) = true;
    end
    % Return all the input files
    OutputFiles = {sInputs(iOk).FileName};
end


%% ===== PERFORM DETECTION =====
% USAGE:      evt = Compute(F, TimeVector, OPTIONS, Fmask)
%             evt = Compute(F, TimeVector, OPTIONS)
%         OPTIONS = Compute()                              : Get the default options structure
function evt = Compute(F, TimeVector, EventSamps, OPTIONS, Fmask)
    % Options structure
    defOptions = struct('bandpass',     [], ...   % Filter the signal before performing the detection, [highpass, lowpass]
                        'threshold',    1, ...         % Create an event if the value goes > threshold * standard deviation
                        'blanking',     1, ...         % No events can be detected during the blanking period
                        'ispullup',     1, ...         % Pullup resistor was used during acquisition, remove this offset before detection
                        'isclassify',   0, ...         % If 1, classify the events in different morphological categories
                        'corrval',      .8, ...        %    => Correlation threshold
                        'refEvent',     []);
    % Parse inputs
    if (nargin == 0)
        evt = defOptions;
        return;
    end
    if (nargin < 4)
        Fmask = [];
    end
    % Copy the missing parameters
    OPTIONS = struct_copy_fields(OPTIONS, defOptions, 0);
    % Sampling frequency
    sFreq = round( 1 ./ (TimeVector(2) - TimeVector(1)));
    % Convert blanking period to number of samples
    blankSmp = round(OPTIONS.blanking * sFreq);
    % Initialize output
    evt = {};
    % If blanking period longer than the signal to process: exit
    if (blankSmp >= length(F))
        bst_report('Warning', 'process_evt_detect', [], 'The blanking period between two events is longer than the signal. Cannot perform detection.');
        return;
    end
    
    %% ===== FILTER RECORDINGS =====
    %Photodiode signal has pull-up resistor and we need to remove the
    %offset (first 1 second of recording)
    if OPTIONS.ispullup
        F = F - mean(F(1:sFreq));
    end
    
     % Filter recordings
    if ~isempty(OPTIONS.bandpass)
        LP = OPTIONS.bandpass(1);
        HP = OPTIONS.bandpass(2);
        if LP == 0
            LP = [];
        end
        if HP == 0
            HP = [];
        end
        F = process_bandpass('Compute', F, TimeVector, LP, HP);
            
    end
    
    % Absolute value
    Fabs = abs(F);

    % Standard deviation
    if ~isempty(Fmask)
        stdF = std(F(Fmask));
    else
        stdF = std(F);
    end
    
    % ===== DETERMINE THRESHOLD =====
    % Theshold, in number of times the std
    threshVal = OPTIONS.threshold * stdF;
    % Find all the indices that are above the threshold
    iThresh = find(Fabs(1:end-blankSmp) > threshVal);
    % Nothing detected: exit
    if isempty(iThresh)
        return;
    end

    % ===== FIND EVENTS =====
    events = repmat(struct('index',[], 'rms',0),0);
    
    if isempty(EventSamps)
        i = 1;
        while ~isempty(i)
            % Get window
            iWindow = iThresh(i) + (0:blankSmp-1);
            % Find the point of first threshold crossing
            iCross = iThresh(i) + 1;
            % Don't save events in the bad segments
            if (isempty(Fmask) || (Fmask(iCross) == 1))
                iEvt = length(events) + 1;
                events(iEvt).rms   = sqrt(mean(Fabs(iWindow).^2));
                events(iEvt).index = iCross;
            end
            % Skip ahead past blank period
            i = find(iThresh > iCross + blankSmp, 1);
        end
    else
        for ii = 1:length(EventSamps)
            iWindow = EventSamps(ii) + (0:blankSmp-1);
            ind = find(ismember(iThresh, iWindow), 1);
            iCross = iThresh(ind) + 1;
            if (isempty(Fmask) || (Fmask(iCross) == 1)) && (iWindow(end) < length(Fabs))
                %iEvt = length(events) + 1;
                try
                events(end+1).index = iCross;
                events(end).rms = sqrt(mean(Fabs(iWindow).^2));
                catch
                    events
                end
            end
        end
    end
            
    % Nothing detected: exit
    if isempty(events)
        return;
    end
    
    events = [events.index];

    % ===== SORT BY MORPHOLOGY =====
    if OPTIONS.isclassify
        % Time window: [-200,200]ms
        iWindow = [round(-.2 .* sFreq), round(.2 .* sFreq)];
        % We need to remove all the events that are before or after this time window
        iRmEvt = find((events <= -iWindow(1)) | (events >= length(F) - iWindow(2)));
        if ~isempty(iRmEvt)
            events(iRmEvt) = [];
        end
        % No events left: exit
        if isempty(events)
            bst_report('Warning', 'process_evt_detect', [], 'The classification removed all the possible events.');
            return;
        end
        % Create first ref event type
        refEvt = F(events(1) + (iWindow(1):iWindow(2)));
        evtType = -1 * ones(size(events));
        evtCount = 1;
        % Loop through all events
        for i = 1:length(events)
            newEvt = F(events(i) + (iWindow(1):iWindow(2)));
            % Loop through all types
            for j = 1:size(refEvt,1)
                c = corrcoef(newEvt, refEvt(j,:));
                if (c(1,2) > OPTIONS.corrval)
                    evtType(i)  = j;
                    evtCount(j) = evtCount(j) + 1;
                    break;
                end
            end
            % If no match create a new type
            if (evtType(i) == -1)
                j = size(refEvt,1) + 1;
                refEvt(j,:) = newEvt;
                evtType(i)  = j;
                evtCount(j) = 1;
            end
        end
        % Keep only the bigger clusters
        if any(evtCount > 5)
            iOkType = find(evtCount > 5);
        else
            iOkType = 1:length(evtCount);
        end
        % Order by cluster size
        [tmp__, iSort] = sort(evtCount(iOkType), 'descend');
        iOkType = iOkType(iSort);

        % Create output cell array
        for i = 1:length(iOkType)
            evt{i} = TimeVector(events(evtType == iOkType(i)));
        end
    else
        evt = {TimeVector(events)};
    end
end




