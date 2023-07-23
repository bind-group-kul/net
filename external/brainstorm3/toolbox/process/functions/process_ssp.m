function varargout = process_ssp( varargin )
% PROCESS_SSP: Artifact rejection for a group of recordings file
%
% USAGE:  OutputFiles = process_ssp('Run', sProcess, sInputs)
%                proj = process_ssp('Compute', F, chanmask)
%           Projector = process_ssp('BuildProjector', ListSsp, ProjStatus)
%           Projector = process_ssp('ConvertOldFormat', oldProj)

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
% Authors: Francois Tadel, 2011-2013

macro_methodcall;
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription()
    % Description the process
    sProcess.Comment     = 'Compute SSP: Generic';
    sProcess.FileTag     = '| ssp';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Artifacts';
    sProcess.Index       = 112;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'raw'};
    sProcess.OutputTypes = {'data', 'raw'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    sProcess.nMinFiles   = 1;
    sProcess.isSeparator = 1;
    % Event name
    sProcess.options.eventname.Comment = 'Event name: ';
    sProcess.options.eventname.Type    = 'text';
    sProcess.options.eventname.Value   = 'cardiac';
    sProcess.options.eventname.InputTypes = {'raw'};
    % Event time window
    sProcess.options.eventtime.Comment = 'Time window: ';
    sProcess.options.eventtime.Type    = 'range';
    sProcess.options.eventtime.Value   = {[-.040, .040], 'ms', []};
    sProcess.options.eventtime.InputTypes = {'raw'};
    % Filter
    sProcess.options.bandpass.Comment = 'Frequency band: ';
    sProcess.options.bandpass.Type    = 'range';
    sProcess.options.bandpass.Value   = {[13, 40], 'Hz', 2};
    % Sensor types
    sProcess.options.sensortypes.Comment = 'Sensor types or names (empty=all): ';
    sProcess.options.sensortypes.Type    = 'text';
    sProcess.options.sensortypes.Value   = 'MEG, EEG';
    % Examples: EOG, ECG
    sProcess.options.example.Comment = ['<HTML>Examples:<BR>' ...
                                        '&nbsp;&nbsp;&nbsp;- EOG: [-200,+200] ms, [1.5-15] Hz<BR>' ...
                                        '&nbsp;&nbsp;&nbsp;- ECG: [-40,+40] ms, [13-40] Hz<BR><BR>'];
    sProcess.options.example.Type    = 'label';
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess)
    if isfield(sProcess.options, 'eventname') && ~isempty(sProcess.options.eventname.Value)
        Comment = ['SSP: ' sProcess.options.eventname.Value];
    else
        Comment = 'SSP';
    end
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs)
    % ===== RECURSIVE CALL =====
    % RAW: process each file separately
    isRaw = strcmpi(sInputs(1).FileType, 'raw');
    if isRaw && (length(sInputs) > 1)
        OutputFiles = {};
        % Call recursively the function on each RAW file
        for iFile = 1:length(sInputs)
            OutputFiles = cat(2, OutputFiles, Run(sProcess, sInputs(iFile)));
        end
        return;
    end
    OutputFiles = {};
    
    % ===== GET OPTIONS =====
    % Get options values
    if isfield(sProcess.options, 'eventname')
        % Event name
        evtName = strtrim(sProcess.options.eventname.Value);
        if isempty(evtName)
            bst_report('Error', sProcess, [], 'Event name must be specified for continuous raw files.');
            return;
        end
        % Event time window (only used if event is a point in time, not a window)
        evtTimeWindow = sProcess.options.eventtime.Value{1};
        % Ignore bad segments
        % => Consider that if the event name contains "bad", we need to include the bad segments. If not, we ignore them.
        isIgnoreBad = isempty(strfind(lower(evtName), 'bad'));
    else
        evtName = [];
        isIgnoreBad = 0;
    end
    bandpass = sProcess.options.bandpass.Value{1};

    % ===== GET CHANNEL FILE =====
    % We consider that the channel definition is equivalent for all the files...
    ChannelFile = sInputs(1).ChannelFile;
    if (length(sInputs) > 1) && ~all(strcmpi(sInputs(1).ChannelFile, {sInputs.ChannelFile}))
        bst_report('Error', sProcess, sInputs, 'All the files used to compute the projector should relate to the same channel file.');
        return;
    end
    % Load channel file
    ChannelMat = in_bst_channel(ChannelFile);
    % Get channels to process
    iChannels = channel_find(ChannelMat.Channel, sProcess.options.sensortypes.Value);
    if isempty(iChannels)
        bst_report('Error', sProcess, sInputs, 'No channels to process.');
        return;
    end
    % Warning if more than one channel type
    allTypes = unique({ChannelMat.Channel(iChannels).Type});
    if (length(allTypes) > 1) && ~isequal(allTypes, {'MEG GRAD', 'MEG MAG'})
        for i = 1:length(allTypes)-1
            allTypes{i} = [allTypes{i}, ', '];
        end
        bst_report('Warning', sProcess, sInputs, ...
            ['Mixing different channel types to compute the projector: ' [allTypes{:}], '.' 10 ...
             'You should compute projectors separately for each sensor type.']);
    end
        
    % ===== GET DATA =====
    bst_progress('text', 'Reading recordings...');
    progressPos = bst_progress('get');
    % Initialize concatenated data matrix
    F = {};
    nSamples = 0;
    nMaxSamples = 100000;
    % RAW: Get all the events
    if isRaw
        % Load the raw file descriptor
        DataMat = in_bst_data(sInputs(1).FileName, 'F', 'ChannelFlag');
        sFile = DataMat.F;
        % Get list of bad channels
        iBad = find(DataMat.ChannelFlag == -1);
        % Get list of bad segments in file
        [badSeg, badEpochs] = panel_record('GetBadSegments', sFile);
        % Get the event to process
        events = sFile.events;
        iEvt = find(strcmpi({events.label}, evtName));
        nOcc = size(events(iEvt).times, 2);
        if isempty(iEvt) || (nOcc == 0)
            bst_report('Error', sProcess, sInputs, ['Event type "' evtName '" not found, or has no occurrence.']);
            return;
        end
        % Extended / simple event
        isExtended = (size(events(iEvt).samples, 1) == 2);
        % Simple events: get the samples to read around each event
        if ~isExtended
            % Window to process for the SSP
            evtSmpRange = round(evtTimeWindow .* sFile.prop.sfreq);
            % Minimum length for the bandpass filter to perform correctly
            minLength = 1 / bandpass(1) * sFile.prop.sfreq;
            % Window to read and filter
            missingSmp = minLength - (evtSmpRange(2)-evtSmpRange(1)+1);
            if (missingSmp <= 0)
                readSmpRange = evtSmpRange;
                iEvtSmpRange = [];
            else
                readSmpRange = evtSmpRange + ceil(missingSmp/2) * [-1,1];
                iEvtSmpRange = ceil(missingSmp/2)+1 + (0:(evtSmpRange(2)-evtSmpRange(1)));
            end
        end
        % Reading options
        % NOTE: FORCE READING CLEAN DATA (Baseline correction + CTF compensators + Previous SSP)
        ImportOptions = db_template('ImportOptions');
        ImportOptions.ImportMode = 'Event';
        ImportOptions.EventsTimeRange = evtTimeWindow;
        ImportOptions.UseCtfComp = 1;
        ImportOptions.UseSsp = 1;
        ImportOptions.RemoveBaseline = 'all';
        ImportOptions.DisplayMessages = 0;
        % Loop on each occurrence of the event
        for iOcc = 1:nOcc
            % Progress bar
            bst_progress('set', progressPos + round(iOcc / nOcc * 100));
            % Simple event: read a time window around the marker
            if ~isExtended
                SamplesBounds = events(iEvt).samples(1,iOcc) + readSmpRange;
            % Extended event: read the full event
            else
                SamplesBounds = events(iEvt).samples(:,iOcc)';
            end
            % Check if this segment is outside of ALL the bad segments (either entirely before or entirely after)
            if isIgnoreBad && ~isempty(badSeg) && (~all((SamplesBounds(2) < badSeg(1,:)) | (SamplesBounds(1) > badSeg(2,:))))
                bst_report('Info', sProcess, sInputs, sprintf('Event %s #%d is in a bad segment: ignored...', evtName, iOcc));
                continue;
            % Check if this this segment is  outside of the file bounds
            elseif (SamplesBounds(1) < sFile.prop.samples(1)) || (SamplesBounds(2) > sFile.prop.samples(2)) 
                bst_report('Info', sProcess, sInputs, sprintf('Event %s #%d is too close to the beginning or end of the file: ignored...', evtName, iOcc));
                continue;
            end
            % Read block
            [Fevt, TimeVector] = in_fread(sFile, events(iEvt).epochs(iOcc), SamplesBounds, [], ImportOptions);
            % Filter recordings
            Fevt(iChannels,:) = process_bandpass('Compute', Fevt(iChannels,:), TimeVector, bandpass(1), bandpass(2));
            % Keep only the time window we want to process (remove what was read just for the filtering)
            if ~isExtended && ~isempty(iEvtSmpRange)
                Fevt = Fevt(:,iEvtSmpRange);
            end
            % Concatenate to final matrix
            F{end+1} = Fevt(iChannels, :);
            nSamples = nSamples + size(Fevt,2);
            % Check whether we read already all the samples we need
            if (nSamples >= nMaxSamples)
                bst_report('Info', sProcess, sInputs, sprintf('Reached the maximum number of samples at event %d / %d', iOcc, nOcc));
                break;
            end
            nTimePerBlock = size(Fevt,2);
        end
        
    % DATA: Concatenate all the input files
    else
        iBad = [];
        % Read all the files in input
        for iFile = 1:length(sInputs)
            % Progress bar
            bst_progress('set', progressPos + round(iFile / length(sInputs) * 100));
            % Load file
            DataMat = in_bst_data(sInputs(iFile).FileName, 'F', 'ChannelFlag', 'Time');
            % Filter recordings
            DataMat.F(iChannels,:) = process_bandpass('Compute', DataMat.F(iChannels,:), DataMat.Time, bandpass(1), bandpass(2));
            % Get bad channels
            iBad = union(iBad, find(DataMat.ChannelFlag == -1));
            % Concatenate to final matrix
            F{end+1} = DataMat.F(iChannels, :);
            nSamples = nSamples + size(DataMat.F,2);
            % Check whether we read already all the samples we need
            if (nSamples >= nMaxSamples)
                bst_report('Info', sProcess, sInputs, sprintf('Reached the maximum number of samples at file %d / %d', iFile, length(sInputs)));
                break;
            end
            nTimePerBlock = size(DataMat.F,2);
        end
    end
    % Set the progress bar to 100%
    bst_progress('set', progressPos + 100);
    % Concatenate all the loaded data
    F = [F{:}];
    % Remove the bad channels from the matrix
    [iBad, iChanRemove] = intersect(iChannels, iBad);
    if ~isempty(iBad) && ~isempty(F)
        iChannels(iChanRemove) = [];
        F(iChanRemove, :) = [];
    end

    % ===== CHECK NUMBER OF SAMPLES =====
    % Minimum number of time samples required to estimate covariance
    nMinSmp = 10 * size(F,1);
    if isempty(F)
        bst_report('Error', sProcess, sInputs, 'No data could be read from the input files');
        return;
    elseif (size(F,2) < nMinSmp)
        nBlock = ceil(size(F,2) / nTimePerBlock);
        nBlockTotal = ceil(nMinSmp / nTimePerBlock);
        if isRaw
            errMsg = sprintf(' - Add %d events (Total: %d)', nBlockTotal - nBlock, nBlockTotal);
            if ~isExtended
                nAddTime = ceil((nMinSmp - size(F,2)) / nBlock / 2);
                newTimeWin = round([evtSmpRange(1) - nAddTime, evtSmpRange(2) + nAddTime] ./ sFile.prop.sfreq .* 1000);
                errMsg = sprintf([errMsg, 10, ' - Increase the time window around each event to [%d,%d] ms'], newTimeWin(1), newTimeWin(2));
            end
        else
            errMsg = sprintf(' - Add %d files in the process list (Total: %d)', nBlockTotal - nBlock, nBlockTotal);
        end
        bst_report('Error', sProcess, sInputs, ['Not enough time samples to compute projectors. You may:' 10 errMsg]);
        return;
    end
    
    % ===== COMPUTE PROJECTOR =====
    bst_progress('text', 'Computing projector...');
    % Create channel mask matrix
    chanmask = zeros(length(ChannelMat.Channel), 1);
    chanmask(iChannels) = 1;
    % Call computation function
    proj = Compute(F, chanmask);
    % Select the components with a singular value > threshold
    singThresh = 0.12;
    proj.CompMask = double(proj.SingVal ./ sum(proj.SingVal) > singThresh);
    % Set the projector to "active" only if there is at least one component > threshold
    proj.Status = any(proj.CompMask);
    % Modality used in the end
    AllMod = unique({ChannelMat.Channel(iChannels).Type});
    strMod = '';
    for iMod = 1:length(AllMod)
        strMod = [strMod, AllMod{iMod} ' '];
    end
    % Comment
    if ~isempty(evtName)
        proj.Comment = [evtName ': ' strMod datestr(clock)];
    else
        proj.Comment = ['SSP: ' strMod datestr(clock)];
    end

    % ===== OUTPUT =====
    bst_progress('text', 'Applying projector to the recordings...');
    % Apply to the data
    import_ssp(ChannelFile, proj, 1);
    % Return all the input files
    OutputFiles = {sInputs.FileName};
end


%% ===== COMPUTE PROJECTOR =====
function proj = Compute(F, chanmask)
    % SVD decomposition
    [U,S,V] = svd(F, 'econ'); 
    % Create projector structure
    proj = db_template('projector');
    % Keep all the dimensions
    nChannel = length(chanmask);
    nProj    = size(U,2);
    proj.Components = zeros(nChannel, nProj);
    proj.Components(chanmask == 1,:) = U;
    % Other fields
    proj.SingVal  = diag(S)';
    proj.CompMask = zeros(1,nProj);
    proj.Status   = 1;
end


%% ===== BUILD PROJECTOR ====
% Combine all the projectors in decomposed form to create a [nChan x nChan] matrix
%
% USAGE: Projector = process_ssp('BuildProjector', ListSsp, ProjStatus)
%
% INPUT:
%    - ListSsp    : Array of db_template('projector')
%    - ProjStatus : List of the projector status to include 
%                   0 = not applied, not used
%                   1 = have to be used, but still have to be applied on the fly
%                   2 = already applied, saved in the file, not revertible
% OUTPUT:
%    - Projector  : [nChannels x nChannels] matrix, projector in the condensed form (I-UUt)
function Projector = BuildProjector(ListSsp, ProjStatus) %#ok<*DEFNU>
    % Call on an old form of Projector (I-UUt)
    if ~isstruct(ListSsp)
        Projector = ListSsp;
        return
    end
    % Initialize returned matrix
    nChannel = size(ListSsp(1).Components,1);
    Projector = [];
    oldProj = [];
    % Loop on all the categories of projectors available
    U = [];
    for i = 1:length(ListSsp)
        % Is entry not selected: skip
        if ~ismember(ListSsp(i).Status, ProjStatus)
            continue
        end
        % New form: decomposed
        if ~isempty(ListSsp(i).CompMask)
            % Get the dimensions that are currently selected
            U = [U, ListSsp(i).Components(:,ListSsp(i).CompMask == 1)];
        % Old form: I-UUt
        elseif isempty(oldProj)
            oldProj = ListSsp(i).Components;
        else
            oldProj = ListSsp(i).Components * oldProj;
        end
    end
    % If no selected vector
    if (isempty(U) || all(U(:) == 0))
        if ~isempty(oldProj)
            Projector = oldProj;
        elseif ~isempty(U)
            disp('SSP> Warning: Projector is the identity matrix. Ignoring...');
        end
        return
    end
    % Reorthogonalize the vectors
    [U,S,V] = svd(U,0);
    S = diag(S);
    % Throw away the linearly dependent guys (threshold on singular values: 0.01 * the first one)
    iThresh = find(S < 0.01 * S(1),1);
    if ~isempty(iThresh)
        disp(sprintf('SSP> %d linearly depedent vectors removed...', size(U,2)-iThresh+1));
        U = U(:, 1:iThresh-1);
    end
    % Compute projector in the form: I-UUt
    Projector = eye(nChannel) - U*U';
    % Multiply by old-style projectors
    if ~isempty(oldProj)
        Projector = oldProj * Projector;
    end
end


%% ===== CONVERT OLD FORMAT =====
% Old format: I - UUt
% New format: Structure with decomposed form (U, maskU...)
function proj = ConvertOldFormat(oldProj)
    if isempty(oldProj)
        proj = [];
    elseif ~isstruct(oldProj)
        proj = db_template('projector');
        proj.Components = oldProj;
        proj.Comment    = 'Unnamed';
        proj.Status     = 1;
    else
        proj = oldProj;
    end
end

