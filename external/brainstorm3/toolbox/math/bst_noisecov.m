function NoiseCovFiles = bst_noisecov(iTargetStudies, iDataStudies, iDatas, Options)
% BST_NOISECOV: Compute noise covariance matrix for a set of studies.
%
% USAGE:  NoiseCovFiles = bst_noisecov(iTargetStudies, iDataStudies, iDatas, Options)                      
%         NoiseCovFiles = bst_noisecov(iTargetStudies, iDataStudies, iDatas) : Use only the specified recordings
%         NoiseCovFiles = bst_noisecov(iTargetStudies)                       : Use all the recordings from these studies
%               Options = bst_noisecov()
%
% INPUT: 
%     - iTargetStudies : List of studies indices for which the noise covariance matrix is produced
%     - iDataStudies   : [1,nData] int, List of data files to use for computation (studies indices)
%                        If not defined or [], uses all the recordings from all the studies (iTargetStudies)
%     - iDatas         : [1,nData] int, List of data files to use for computation (data indices)
%     - Options        : Structure with the following fields (if not defined: asked to the user)
%           |- Baseline        : [tStart, tStop]; range of time values considered as baseline
%           |- RemoveDcOffset  : {'file', 'all'}; 'all' removes the baseline avg file by file; 'all' computes the baseline avg from all the files
%           |- NoiseCovMethod  : {'full', 'diag'}; diag computes the full matrix but keep only the diagonal
%           |- AutoReplace     : If 1 replaces automatically the previous noisecov file without asking the user for a confirmation

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

%% ===== RETURN DEFAULT OPTIONS =====
% Options structure
if (nargin == 0)
    NoiseCovFiles = struct(...
        'Baseline',        [-.1, 0], ...
        'RemoveDcOffset',  'file', ...
        'NoiseCovMethod',  'full', ...
        'AutoReplace',     0);
    return;
end

%% ===== PARSE INPUTS =====
if (nargin < 4)
    Options = [];
end
NoiseCovFiles = {};
isRaw = 0;
% Get source files
if (nargin < 3) || isempty(iDataStudies) || (length(iDataStudies) ~= length(iDatas))
    % Get all the datafiles depending on the target studies
    sStudies = bst_get('Study', iTargetStudies);
    sDatas = [sStudies.Data];
    DataFiles = {sDatas.FileName};
else
    % Unique studies
    uniqueStudies = unique(iDataStudies);
    DataFiles = {};
    % For each study
    for i = 1:length(uniqueStudies)
        % Get study
        iStudy = uniqueStudies(i);
        sStudy = bst_get('Study', iStudy);
        iDataLocal = iDatas(iDataStudies == iStudy);
        % Add files to list
        DataFiles = cat(2, DataFiles, {sStudy.Data(iDataLocal).FileName});
        % Raw data
        isRaw = any(strcmpi({sStudy.Data(iDataLocal).DataType}, 'raw'));
    end
end


%% ===== GET DATA CHANNELS =====
% Get channel studies
sTargetStudies = bst_get('Study', iTargetStudies);
% Find a study with channel file
iWithChan = find(~cellfun(@isempty, {sTargetStudies.Channel}), 1);
% If a channel file is defined
if ~isempty(iWithChan)
    sStudy = sTargetStudies(iWithChan);
    % Load channel file
    ChannelMat = in_bst_channel(sStudy.Channel.FileName);
    % Get EEG and MEG channels
    iChan = good_channel(ChannelMat.Channel, [], {'MEG','EEG','ECOG','SEEG'});
    nChanAll = length(ChannelMat.Channel);
else
    error('No channel file.');
end


%% ===== READ ALL TIME VECTORS =====
% Regular list of imported data files
if ~isRaw
    % Read all the Time vectors
    DataMats = in_bst_data_multi(DataFiles);
    % Check sampling rates
    SamplingRate = DataMats(1).SamplingRate;
    % Frequency
    if any(abs(SamplingRate - [DataMats.SamplingRate]) > 1e-6)
        error(['The files you selected have different sampling frequencies. They should not be processed together.' 10 ...
               'Please only select recordings with the same sampling frequency.']);
    end
    DataMats(1).iBadTime = [];
% Raw file
else
    % Only one raw file allowed
    if (length(DataFiles) > 1)
        error('Only one raw file allowed for noise covariance computation');
    end
    % Read the description of the raw file
    RawMat = in_bst_data(DataFiles{1});
    sFile = RawMat.F;
    clear RawMat;
    % Get bad segments/epochs
    [badSeg, badEpochs] = panel_record('GetBadSegments', sFile);
    
    % Initialize DataMats structure
    DataMats = repmat(struct('Time', [], 'nAvg', [], 'iEpoch', [], 'iBadTime', []), 0);
    % Define size of blocks to read
    MAX_BLOCK_SIZE = 10000;
    % Loop on epochs
    for iEpoch = 1:max(length(sFile.epochs), 1)
        % Bad epoch
        if ~isempty(sFile.epochs) && sFile.epochs(iEpoch).bad
            disp(sprintf('NOISECOV> Ignoring epoch #%d (tagged as bad)', iEpoch));
        end
        % Get the bad segments for this epoch
        iBadEpoch = find(badEpochs == iEpoch);
        if ~isempty(iBadEpoch)
            badSegEpoc = badSeg(:, iBadEpoch);
        else
            badSegEpoc = [];
        end
        % Get total number of samples
        if ~isempty(sFile.epochs)
            samples = double(sFile.epochs(iEpoch).samples);
            nAvg = double(sFile.epochs(iEpoch).nAvg);
        else
            samples = double(sFile.prop.samples);
            nAvg = 1;
        end
        totalSmpLength = double(samples(2) - samples(1)) + 1;
        % Number of blocks to split this epoch in
        nbBlocks = ceil(totalSmpLength / MAX_BLOCK_SIZE);
        % For each block
        for iBlock = 1:nbBlocks
            % Get samples indices for this block (start ind = 0)
            smpBlock = samples(1) + [(iBlock - 1) * MAX_BLOCK_SIZE, min(iBlock * MAX_BLOCK_SIZE - 1, totalSmpLength - 1)];
            smpList = smpBlock(1):smpBlock(2);
            % Create a data block
            iNew = length(DataMats) + 1;
            DataMats(iNew).iEpoch = iEpoch;
            DataMats(iNew).Time   = smpList ./ sFile.prop.sfreq;
            DataMats(iNew).nAvg   = nAvg;
            % Remove the portions that have bad segments in them
            iBadTime = [];
            for ix = 1:size(badSegEpoc, 2)
                iBadTime = [iBadTime, find((smpList >= badSegEpoc(1,ix)) & (smpList <= badSegEpoc(2,ix)))];
            end
            if ~isempty(iBadTime)
                DataMats(iNew).iBadTime = iBadTime;
                % DataMats(iNew).Time(iBadTime) = [];
            end
        end
    end
    SamplingRate = 1 ./ sFile.prop.sfreq;
end
% Get number of samples and sampling rates
nSamples = length([DataMats.Time]) - length([DataMats.iBadTime]);
% Check number of actual samples available for computation
if (nSamples == 0)
    error('This selection does not contain any file that can be used for computing the noise covariance matrix.');
end


%% ===== GET NOISECOV OPTIONS ======
% Get number of files
nFiles = length(DataMats);
% If the options were not passed in argument
if isempty(Options)
    % Loop to get all the valid times
    allTimes = [];
    for iFile = 1:length(DataMats)
        tmpTime = DataMats(iFile).Time;
        tmpTime(DataMats(iFile).iBadTime) = [];
        allTimes = [allTimes, tmpTime];
    end
    % Prepare GUI options
    guiOptions.timeSamples = sort(allTimes);
    guiOptions.nFiles      = nFiles;
    guiOptions.nChannels   = length(iChan);
    guiOptions.freq        = 1 ./ SamplingRate;
    % Display dialog window
    Options = gui_show_dialog('Noise covariance', @panel_noisecov, 1, [], guiOptions);
    if isempty(Options)
        return
    end
end


%% ===== COMPUTE AVERAGE/TIME =====
if strcmpi(Options.RemoveDcOffset, 'all')
    % Compute the average across ALL the time samples of ALL the files
    Favg = zeros(nChanAll, 1);
    Ntotal = zeros(nChanAll, 1);
    % Progress bar
    bst_progress('start', 'Average across time', 'Computing average across time...', 0, nFiles);
    % Loop on all the files
    for iFile = 1:nFiles
        bst_progress('inc', 1);
        % Load recordings
        [DataMat, iTimeBaseline] = ReadRecordings();
        if isempty(iTimeBaseline)
            continue
        end
        % Get good channels
        iGoodChan = intersect(find(DataMat.ChannelFlag == 1), iChan);
        
        % === Compute average ===
        Favg(iGoodChan)   = Favg(iGoodChan)   + double(DataMat.nAvg) .* sum(DataMat.F(iGoodChan,iTimeBaseline),2);
        Ntotal(iGoodChan) = Ntotal(iGoodChan) + double(DataMat.nAvg) .* length(iTimeBaseline);
    end
    % Remove zero-values in Ntotal
    Ntotal(Ntotal == 0) = 1;
    % Divide each channel by total number of time samples
    Favg = Favg ./ Ntotal;
end


%% ===== COMPUTE NOISE COVARIANCE =====
Ntotal   = zeros(nChanAll);
NoiseCov = zeros(nChanAll);
% Progress bar
bst_progress('start', 'Noise covariance', 'Computing noise covariance...', 0, nFiles);
drawnow
% Loop on all the files
for iFile = 1:nFiles
    bst_progress('inc', 1);
    % Load recordings
    [DataMat, iTimeBaseline] = ReadRecordings();
    if isempty(iTimeBaseline)
        continue
    end
    N = length(iTimeBaseline);
    
    % === Compute average ===
    if strcmpi(Options.RemoveDcOffset, 'file')
        % Get good channels
        iGoodChan = intersect(find(DataMat.ChannelFlag == 1), iChan);
        % Average baseline values
        Favg = mean(DataMat.F(:,iTimeBaseline), 2);
    end
    
    % === Compute covariance ===
    % Remove average
    DataMat.F(iGoodChan,iTimeBaseline) = bst_bsxfun(@minus, DataMat.F(iGoodChan,iTimeBaseline), Favg(iGoodChan,1));
    % Compute covariance for this file
    fileCov = DataMat.nAvg .* (DataMat.F(iGoodChan,iTimeBaseline) * DataMat.F(iGoodChan,iTimeBaseline)');
    % Add file covariance to accumulator
    NoiseCov(iGoodChan,iGoodChan) = NoiseCov(iGoodChan,iGoodChan) + fileCov;
    Ntotal(iGoodChan,iGoodChan) = Ntotal(iGoodChan,iGoodChan) + N;
end
% Remove zeros from N matrix
Ntotal(Ntotal <= 1) = 2;
% Divide final matrix by number of samples
NoiseCov = NoiseCov ./ (Ntotal - 1);
% Apply method
switch lower(Options.NoiseCovMethod)
    case 'full'
        % Default: nothing to do
    case 'diag'
        % Keep only the diagonal of the full noise covariance matrix
        NoiseCov = diag(diag(NoiseCov));
    otherwise
        error('Unknown method.');
end
% Display result in the command window
nSamplesTotal = max(Ntotal(:));
disp(['Number of time samples used for the noise covariance: ' num2str(nSamplesTotal)]);

%% ===== IMPORTING IN DATABASE =====
% Build file structure
NoiseCovMat.Comment  = 'Noise covariance';
NoiseCovMat.NoiseCov = NoiseCov;
% History: Import from Matlab
NoiseCovMat = bst_history('add', NoiseCovMat, 'compute', sprintf('Computed based on %d files (%d samples): Baseline [%1.2f, %1.2f]ms, %s, %s', ...
                          nFiles, nSamplesTotal, Options.Baseline * 1000, Options.RemoveDcOffset, Options.NoiseCovMethod));
% Save in database
NoiseCovFiles = import_noisecov(iTargetStudies, NoiseCovMat, Options.AutoReplace);
% Close progress bar
bst_progress('stop');




%% ========================================================================
%  ======= SUPPORT FUNCTIONS ==============================================
%  ========================================================================

%% ===== READ RECORDINGS BLOCK =====
    function [DataMat, iTimeBaseline] = ReadRecordings()
        iTimeBaseline = [];
        if ~isRaw
            bst_progress('text', ['File: ' DataFiles{iFile}]);
            DataMat = in_bst_data(DataFiles{iFile}, 'F', 'ChannelFlag', 'Time', 'nAvg');
        else
            DataMat = DataMats(iFile);
            % If file is block does not contain any baseline segment: skip it
            if (length(DataMats(iFile).Time) < 2) || (DataMats(iFile).Time(end) < Options.Baseline(1)) || (DataMats(iFile).Time(1) > Options.Baseline(2))
                return;
            end
            % Read raw block
            [DataMat.F, DataMat.Time] = panel_record('ReadRawBlock', sFile, DataMats(iFile).iEpoch, DataMats(iFile).Time([1,end]), 0, 1, 'no');
            DataMat.ChannelFlag = sFile.channelflag;
        end
        % Apply average reference: separately SEEG, ECOG, EEG
        if any(ismember(unique({ChannelMat.Channel.Type}), {'EEG','ECOG','SEEG'}))
            sMontage = panel_montage('GetMontageAvgRef', ChannelMat.Channel, DataMat.ChannelFlag);
            DataMat.F = sMontage.Matrix * DataMat.F;
        end
        % If not enough time frames (ie. if data files)
        if (length(DataMat.Time) <= 2) || (size(DataMat.F,2) <= 2)
            return;
        end
        % Check size
        if (size(DataMat.F,1) ~= nChanAll)
            error('Number of channels is not constant.');
        end
        % Get the times required in the block (only when there are bad segments in raw files)
        if isRaw && ~isempty(DataMat.iBadTime)
            DataMat.Time(DataMat.iBadTime) = [];
            DataMat.F(:, DataMat.iBadTime) = [];
        end
        % Get times that are considered as baseline
        if ~isempty(DataMat.Time)
            iTimeBaseline = panel_time('GetTimeIndices', DataMat.Time, Options.Baseline);
        end
    end

end









