function [F, TimeVector] = in_fread(sFile, iEpoch, SamplesBounds, iChannels, ImportOptions)
% IN_FREAD: Read a block a data in any recordings file previously opened with in_fopen().
%
% USAGE:  [F, TimeVector] = in_fread(sFile, iEpoch, SamplesBounds, iChannels, ImportOptions);
%         [F, TimeVector] = in_fread(sFile, iEpoch, SamplesBounds, iChannels);                 : Do not apply any pre-preprocessings
%         [F, TimeVector] = in_fread(sFile, iEpoch, SamplesBounds);                            : Read all channels
%
% INPUTS:
%     - sFile         : Structure for importing files in Brainstorm. Created by in_fopen()
%     - iEpoch        : Indice of the epoch to read (only one value allowed)
%     - SamplesBounds : [smpStart smpStop], First and last sample to read in epoch #iEpoch
%     - iChannels     : Array of indices of the channels to import
%     - ImportOptions : Structure created by interface window panel_import_data.m
%
% OUTPUTS:
%     - F          : [nChannels x nTimes], block of recordings
%     - TimeVector : [1 x nTime], time values in seconds

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
% Authors: Francois Tadel, 2009-2012

%% ===== PARSE INPUTS =====
if (nargin < 5)
    ImportOptions = [];
end
if (nargin < 4)
    iChannels = [];
end
TimeVector = [];

%% ===== OPEN FILE =====
% Check if file exists
if ~file_exist(sFile.filename)
    error(['The following file has been removed or is used by another program:' 10 sFile.filename]);
end
% Open file (not for CTF and ANT, because it is open in the in_fread_ctf)
if ismember(sFile.format, {'CTF', 'EEG-ANT-CNT', 'BST-DATA'}) 
    sfid = [];
else
    sfid = fopen(sFile.filename, 'r', sFile.byteorder);
end

%% ===== READ RECORDINGS BLOCK =====
switch (sFile.format)
    case 'FIF'
        [F,TimeVector] = in_fread_fif(sFile, sfid, iEpoch, SamplesBounds, iChannels);
    case {'CTF', 'CTF-CONTINUOUS'}
        isContinuous = strcmpi(sFile.format, 'CTF-CONTINUOUS');
        if isempty(iChannels)
            ChannelRange = [];
            iChanRemove = [];
        else
            ChannelRange = [iChannels(1), iChannels(end)];
            iChanRemove = setdiff(ChannelRange(1):ChannelRange(2), iChannels) - ChannelRange(1) + 1;
        end
        F = in_fread_ctf(sFile, iEpoch, SamplesBounds, ChannelRange, isContinuous);
        % Remove channels that were not supposed to be read
        if ~isempty(iChanRemove)
            F(iChanRemove,:) = [];
        end
    case '4D'
        F = in_fread_4d(sFile, sfid, iEpoch, SamplesBounds, iChannels);
    case 'KIT'
        F = in_fread_kit(sFile, iEpoch, SamplesBounds, iChannels);
    case 'LENA'
        F = in_fread_lena(sFile, sfid, iEpoch, SamplesBounds);
        if ~isempty(iChannels)
            F = F(iChannels,:);
        end
    case 'EEG-ANT-CNT'
        F = in_fread_ant(sFile, SamplesBounds);
        if ~isempty(iChannels)
            F = F(iChannels,:);
        end
    case 'EEG-BRAINAMP'
        F = in_fread_brainamp(sFile, sfid, SamplesBounds);
        if ~isempty(iChannels)
            F = F(iChannels,:);
        end
    case 'EEG-DELTAMED'
        F = in_fread_deltamed(sFile, sfid, SamplesBounds);
        if ~isempty(iChannels)
            F = F(iChannels,:);
        end
    case {'EEG-EDF', 'EEG-BDF'}
        if isempty(iChannels)
            ChannelRange = [];
        else
            ChannelRange = [iChannels(1), iChannels(end)];
        end
        F = in_fread_edf(sFile, sfid, SamplesBounds, ChannelRange);
    case 'EEG-EEGLAB'
        F = in_fread_eeglab(sFile, iEpoch, SamplesBounds);
        if ~isempty(iChannels)
            F = F(iChannels,:);
        end
    case 'EEG-EGI-RAW'
        F = in_fread_egi(sFile, sfid, iEpoch, SamplesBounds);
        if ~isempty(iChannels)
            F = F(iChannels,:);
        end
    case {'EEG-MANSCAN'}
        F = in_fread_manscan(sFile, sfid, iEpoch, SamplesBounds);
        if ~isempty(iChannels)
            F = F(iChannels,:);
        end
    case 'EEG-NEUROSCAN-CNT'
        F = in_fread_cnt(sFile, sfid, SamplesBounds);
        if ~isempty(iChannels)
            F = F(iChannels,:);
        end
    case 'EEG-NEUROSCAN-EEG'
        F = in_fread_eeg(sFile, sfid, iEpoch, SamplesBounds);
        if ~isempty(iChannels)
            F = F(iChannels,:);
        end
    case 'EEG-NEUROSCAN-AVG'
        F = in_fread_avg(sFile, sfid, SamplesBounds);
        if ~isempty(iChannels)
            F = F(iChannels,:);
        end
    case 'EEG-NEUROSCOPE'
        F = in_fread_neuroscope(sFile, sfid, SamplesBounds);
        if ~isempty(iChannels)
            F = F(iChannels,:);
        end
    case 'NIRS-MFIP'
        F = in_fread_mfip(sFile, SamplesBounds);
        if ~isempty(iChannels)
            F = F(iChannels,:);
        end
    case 'BST-DATA'
        if ~isempty(SamplesBounds)
            iTimes = (SamplesBounds(1):SamplesBounds(2)) - sFile.prop.samples(1) + 1;
        else
            iTimes = 1:size(sFile.header.F,2);
        end
        if isempty(iChannels)
            iChannels = 1:size(sFile.header.F,1);
        end
        F = sFile.header.F(iChannels, iTimes);
    otherwise
        error('Cannot read data from this file');
end
% Force the recordings to be in double precision
F = double(F);

%% ===== CLOSE FILE =====
if ~isempty(sfid) && ~isempty(fopen(sfid))
    fclose(sfid);
end


%% ===== TIME =====
% If TimeVector was not defined by the reading functions
if isempty(TimeVector)
    if ~isempty(SamplesBounds)
        TimeVector = (SamplesBounds(1) : SamplesBounds(2)) ./ sFile.prop.sfreq;
    elseif ~isempty(iEpoch) && ~isempty(ImportOptions) && strcmpi(ImportOptions.ImportMode, 'Epoch') && ~isempty(sFile.epochs)
        TimeVector = (sFile.epochs(iEpoch).samples(1) : sFile.epochs(iEpoch).samples(2)) / sFile.prop.sfreq;
    else
        TimeVector = (sFile.prop.samples(1) : sFile.prop.samples(2)) / sFile.prop.sfreq;
    end
end
% If epoching the recordings (ie. reading by events): Use imported time window
if ~isempty(ImportOptions) && strcmpi(ImportOptions.ImportMode, 'Event')
    % TimeVector = TimeVector - TimeVector(1) + ImportOptions.EventsTimeRange(1);
    evtOffset = round(ImportOptions.EventsTimeRange(1) * sFile.prop.sfreq) / sFile.prop.sfreq;
    TimeVector = TimeVector - TimeVector(1) + evtOffset;
end


%% ===== GRADIENT CORRECTION =====
% 3rd-order gradient correction
if ~isempty(ImportOptions) && ImportOptions.UseCtfComp && ~strcmpi(sFile.format, 'BST-DATA') && isfield(sFile.channelmat, 'MegRefCoef') && ~isempty(sFile.channelmat.MegRefCoef) && (sFile.prop.currCtfComp ~= sFile.prop.destCtfComp)
    iMeg = good_channel(sFile.channelmat.Channel,[],'MEG');
    iRef = good_channel(sFile.channelmat.Channel,[],'MEG REF');
    if ~isempty(iChannels) && (length(iChannels) ~= length(sFile.channelmat.Channel))
        error('CTF compensators require that you read all the channels at the same time.');
    else
        F(iMeg,:) = F(iMeg,:) - sFile.channelmat.MegRefCoef * F(iRef,:);
    end
end

%% ===== SSP PROJECTORS =====
if ~isempty(ImportOptions) && ImportOptions.UseSsp && ~strcmpi(sFile.format, 'BST-DATA') && isfield(sFile.channelmat, 'Projector') && ~isempty(sFile.channelmat.Projector)
    % Build projector matrix
    Projector = process_ssp('BuildProjector', sFile.channelmat.Projector, 1);
    % Get bad channels
    iBadChan = find(sFile.channelflag == -1);
    % Apply projector
    if ~isempty(Projector)
        % Remove bad channels from the projector (similar as in process_megreg)
        if ~isempty(iBadChan)
            Projector(iBadChan,:) = 0;
            Projector(:,iBadChan) = 0;
            Projector(iBadChan,iBadChan) = eye(length(iBadChan));
        end
        % Apply projector
        if ~isempty(iChannels)
            F = Projector(iChannels, iChannels) * F;
        else
            F = Projector * F;
        end
    end
end


%% ===== REMOVE BASELINE ======
if ~isempty(ImportOptions) && ~isempty(ImportOptions.RemoveBaseline)
    % Get times to compute the baseline
    switch (ImportOptions.RemoveBaseline)
        case 'all'
            iTimesBl = 1:length(TimeVector);
        case 'time'
            iTimesBl = find((TimeVector >= ImportOptions.BaselineRange(1)) & (TimeVector <= ImportOptions.BaselineRange(2)));
        case 'no'
            iTimesBl = [];
    end
    % Remove baseline
    if ~isempty(iTimesBl)
        % Compute baseline
        blValue = mean(F(:,iTimesBl), 2);
        % Remove from recordings
        F = F - repmat(blValue, [1,size(F,2)]);
    end
end


%% ===== RESAMPLE =====
if ~isempty(ImportOptions) && ImportOptions.Resample && (size(F,2) > 1) && (abs(ImportOptions.ResampleFreq - sFile.prop.sfreq) > 0.05)
    [F, TimeVector] = process_resample('Compute', F, TimeVector, ImportOptions.ResampleFreq);
end



