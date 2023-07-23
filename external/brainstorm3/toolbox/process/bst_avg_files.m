function [Stat, Messages, iOutFiles, Events] = bst_avg_files( StatType, FilesListA, FilesListB, avg_func, isPercent )
% BST_AVG_FILES: Compute statistics on one or two files sets.
%
% USAGE:  [Stat, Messages, iOutFiles, Events] = bst_avg_files( StatType, FilesListA, FilesListB, avg_func, isPercent )
%
% INPUT:
%    - StatType   : string => {'mean', 'var', 'mean_diff', 'var_diff'}
%    - FilesListA : Cell array of full paths to files from set A
%    - FilesListB : Cell array of full paths to files from set B
%    - avg_func   : {'mean', 'rms', 'abs'}
%    - isPercent  : If 1, Use current progress bar, and progression from 0 to 100 ("inc" only)
%
% OUTPUT:
%    - Stat: struct
%         |- ChannelFlag : array with -1 for all the bad channels found in all the processed files
%         |- MatName     : name of the file fieldname on which the stat was computed
%         |- (statname)  : values for the target statistics
%         |- Time        : time values
%    - Messages          : cell array of error/warning messages
%    - iOutFiles         : indices of the input files that were used in the average
%    - Events            : combined events structures of all the input files

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
% Authors: Francois Tadel, 2008-2013


%% ===== PARSE INPUTS =====
if (nargin < 3) || isempty(FilesListB)
    FilesListB = {};
end
if (nargin < 4) || isempty(avg_func)
    avg_func = 'mean';
end
if (nargin < 5) || isempty(isPercent)
    isPercent = 0;
end
% Get progress bar initial level
if isPercent && bst_progress('isVisible')
    startValue = bst_progress('get');
else
    startValue = 0;
end
% Computing a mean/var of a difference
isDiff = ~isempty(strfind(StatType, '_diff'));
StatType = strrep(StatType, '_diff', '');
% Check number of inputs
if isDiff && (length(FilesListA) ~= length(FilesListB))
    error('Difference of files: number of files in sets A and B must be equal.');
end


%% ===== MEAN/VAR COMPUTATION =====
switch lower(StatType)       
    case 'mean'
        if ~isPercent
            bst_progress('start', 'Computing mean', 'Initialization...', 0, 100);
        end
        % Compute mean
        [Stat, Messages, iOutFiles, Events] = getVarianceValues(FilesListA, FilesListB, 0, isDiff, avg_func, startValue);      
    case 'var'
        if ~isPercent
            bst_progress('start', 'Computing variance', 'Initialization...', 0, 100);
        end
        % Compute mean and variance
        [Stat, Messages, iOutFiles, Events] = getVarianceValues(FilesListA, FilesListB, 1, isDiff, avg_func, startValue);
    otherwise
        error('Invalid option StatType: "%s".', StatType);
end

% Progress bar
if ~isPercent
    bst_progress('stop');
end
end



%% ===============================================
%  ===== COMPUTE MEAN/VARIANCE OF FILES LIST =====
%  ===============================================
% Using West algorithm, from Wikipedia page: http://en.wikipedia.org/wiki/Algorithms_for_calculating_variance
% D.H.D. West (1979). Communications of the ACM, 22, 9, 532-535: Updating Mean and Variance Estimates: An Improved Method
% 
% def weighted_incremental_variance(FilesList):
%     MeanValues = 0
%     VarValues = 0
%     nGoodSamples = 0
%     for (matValues, nAvg) in FilesList:
%         nGoodSamples_old = nGoodSamples;
%         nGoodSamples = nAvg + nGoodSamples_old
%         Q = matValues - MeanValues
%         R = Q * nAvg / nGoodSamples
%         VarValues = VarValues + nGoodSamples_old * Q * R
%         MeanValues = MeanValues + R
%     VarValues = VarValues / (nGoodSamples-1)  # if sample is the population, omit -1
%     return VarValues

function [Stat, Messages, iOutFiles, AllEvents] = getVarianceValues(FilesList, FilesList2, computeVariance, isDiff, avg_func, startValue)
    VarValues    = [];
    MeanValues   = [];
    MeanMatName  = [];
    NbChannels   = 0;
    initTimeVector = [];
    initRowNames = [];
    nGoodSamples = [];
    isData       = 0;
    n            = length(FilesList);
    nAvgTotal    = 0;
    isApplyNavg  = -1;
    Stat         = [];
    Messages     = [];
    iOutFiles    = [];
    sFile.events = repmat(db_template('event'), 0);
    AllEvents    = [];
    
    % Process all the files
    for iFile = 1:n
        bst_progress('text', ['Processing file : "' FilesList{iFile} '"...']);
        bst_progress('set',  round(startValue + iFile/n*100));

        % === LOAD FILE ===
        % Load file #iFile
        [sMat, matName] = in_bst(FilesList{iFile});
        matValues = double(sMat.(matName));
        nAvg = sMat.nAvg;
        nAvgTotal = nAvgTotal + nAvg;
        TimeVector = sMat.Time;
        % Apply default measure to TF values
        if strcmpi(matName, 'TF') && ~isreal(matValues)
            % Get default function
            defMeasure = process_tf_measure('GetDefaultFunction', sMat.Method);
            % Apply default function
            [matValues, isError] = process_tf_measure('Compute', matValues, sMat.Measure, defMeasure);
            if isError
                Messages = [Messages, 'Error: Invalid measure conversion: ' sMat.Measure ' => ' defMeasure];
                continue;
            end
        end
        % Detect bad channels in matrix/timefreq files
        if ismember(matName, {'TF','Value'})
            % Detect the rows for which all the values are exactly zero
            iBadChan = find(all(all(matValues==0,2),3));
            % If there are some: set a ChannelFlag variable
            ChannelFlag = ones(size(matValues,1),1);
            if ~isempty(iBadChan)
                ChannelFlag(iBadChan) = -1;
            end
        % Data: Load bad channels from file
        elseif strcmpi(matName, 'F') && isfield(sMat, 'ChannelFlag')
            ChannelFlag = sMat.ChannelFlag;
        else
            ChannelFlag = [];
        end
        if isfield(sMat, 'Measure')
            Measure = sMat.Measure;
        else
            Measure = [];
        end
        if isfield(sMat, 'RowNames')
            RowNames = sMat.RowNames;
        else
            RowNames = [];
        end
        if isfield(sMat, 'Events') && ~isempty(sMat.Events)
            Events = sMat.Events;
        else
            Events = [];
        end
        % Check the row names
        clear sMat;
        % Substract file from set B, if applicable
        if isDiff
            % Read file B
            [sMat2, matName2] = in_bst(FilesList2{iFile});
            % Check size
            if ~isempty(matValues) && ~isequal(size(matValues), size(sMat2.(matName2)))
                Messages = [Messages, sprintf('Files #A%d and #B%d have different numbers of channels or time samples.\n', iFile, iFile)];
                continue;
            end
            % Substract two files: A - B (absolute values or relative)
            switch (avg_func)
                case 'mean',  matValues = matValues - double(sMat2.(matName2));
                case 'rms',   matValues = matValues.^2 - double(sMat2.(matName2)).^2;
                case 'abs',   matValues = abs(matValues) - abs(double(sMat2.(matName2)));
            end
            % Add bad channels from file B to file A
            if ~isempty(ChannelFlag) && isfield(sMat2, 'ChannelFlag')
                ChannelFlag(sMat2.ChannelFlag == -1) = -1;
            end
            clear sMat2;
        % Else: Apply absolute values if necessary
        else
            switch (avg_func)
                case 'mean',  % Nothing to do
                case 'rms',   matValues = matValues .^ 2;
                case 'abs',   matValues = abs(matValues);
            end
        end
        % If file is first of the list
        if (iFile == 1)
            % Initialize data fields
            MeanValues = zeros(size(matValues));
            if computeVariance
                VarValues = zeros(size(matValues));
            end
            MeanMatName = matName;
            % If processing recordings (="data") files
            isData = strcmpi(MeanMatName, 'F');
            % Good channels
            NbChannels = length(ChannelFlag);
            if isData
                nGoodSamples = zeros(NbChannels, 1);
            else
                nGoodSamples = zeros(size(matValues,1), 1);
            end
            % Initial Time Vector
            initTimeVector = TimeVector;
            initMeasure = Measure;
            sFile.prop.sfreq = 1 ./ (TimeVector(2) - TimeVector(1));
            % Initial row names
            initRowNames = RowNames;
        % All other files
        else
            % If current matrix has not the same size than the others
            if ~all(size(MeanValues) == size(matValues))
                Messages = [Messages, sprintf('Error: File #%d contains a data matrix that has a different size:\n%s\n', iFile, FilesList{iFile})];
                continue;
            elseif ~strcmpi(MeanMatName, matName)
                Messages = [Messages, sprintf('Error: File #%d has a different type. All the result files should be of the same type (full results or kernel-only):\n%s\n', iFile, FilesList{iFile})];
                continue;
            % Check time values
            elseif (length(initTimeVector) ~= length(TimeVector)) && ~all(initTimeVector == TimeVector)
                Messages = [Messages, sprintf('Error: File #%d has a different time definition:\n%s\n', iFile, FilesList{iFile})];
                continue;
            % Check TF measure
            elseif ~isempty(initMeasure) && ~strcmpi(Measure, initMeasure)
                Messages = [Messages, sprintf('Error: File #%d has a different measure applied to the time-frequency coefficients:\n%s\n', iFile, FilesList{iFile})];
                continue;
            end
            % Check row names
            if ~isequal(initRowNames, RowNames)
                Messages = [Messages, sprintf('Warning: File #%d has a different list of row names, averaging them might be inappropriate.\n%s\n', iFile, FilesList{iFile})];
            end
        end

        % === RE-AVERAGING ===
        % Averaging recordings with different nAvg
        if isData && (nAvg ~= 1) && (n > 1)
            % If question not asked yet
            if (isApplyNavg == -1)
                isApplyNavg = 1;
%                 isApplyNavg = java_dialog('confirm', ['Warning: You are processing averaged files.' 10 10 ...
%                                                       'Do you want to weight the different averages with the number of trials (nAvg) ?' 10 10], ...
%                                                       'Compute variance');
            end
            % If weight with nAvg requested by user
            if ~isApplyNavg
                nAvg = 1;
            end
        end

        % === CHECK NUMBER OF CHANNELS ===
        nGoodSamples_old = nGoodSamples;
        if ~isempty(ChannelFlag) && (NbChannels ~= length(ChannelFlag))
            if isData
                % Data : number of channels MUST be the same for all samples
                error('All the input files should have the same number of channels.');
            else
                % Results and other: Simply ignore ChannelFlag definition
                NbChannels = 0;
                nGoodSamples = nGoodSamples + 1;
                nAvg = 1;
                iGoodRows = true(size(matValues,1), 1);
            end
        else
            % Get good channels
            if ~isempty(ChannelFlag)
                iGoodRows = (ChannelFlag == 1);
            else
                iGoodRows = true(size(matValues,1), 1);
            end
            % Count good channels
            nGoodSamples(iGoodRows) = nGoodSamples(iGoodRows) + nAvg;
        end

        % === ADD NEW VALUES ===
        iOutFiles(end+1) = iFile;
        % Q = matValues - MeanValues
        matValues(iGoodRows,:) = matValues(iGoodRows,:) - MeanValues(iGoodRows,:);
        % R = Q * nAvg / nGoodSamples
        R = bst_bsxfun(@rdivide, matValues(iGoodRows,:) .* nAvg, nGoodSamples(iGoodRows));
        if computeVariance
            % VarValues = VarValues + nGoodSamples_old * Q * R
            matValues(iGoodRows,:) = matValues(iGoodRows,:) .* R;
            VarValues(iGoodRows,:) = VarValues(iGoodRows,:) + bst_bsxfun(@times, matValues(iGoodRows,:), nGoodSamples_old(iGoodRows));
        end
        MeanValues(iGoodRows,:) = MeanValues(iGoodRows,:) + R;
        
        % === ADD EVENTS ===
        if ~isempty(Events)
            sFile = import_events(sFile, Events);
        end
    end
    % Nothing was processed
    if isempty(MeanValues)
        return;
    end
    % Bad channels = channels that are BAD in ALL the samples
    if (NbChannels > 0)
        MeanBadChannels = find(nGoodSamples == 0);
    else
        MeanBadChannels = [];
    end

    % === FINALIZE COMPUTATION ===
    % RMS
    if strcmpi(avg_func, 'RMS')
        MeanValues = sqrt(MeanValues);
    end
    % Variance
    if computeVariance
        iMulti = (nGoodSamples > 1);
        iOther = (nGoodSamples <= 1);
        % If n>1: 
        VarValues(iMulti,:) = bst_bsxfun(@rdivide, VarValues(iMulti,:), (nGoodSamples(iMulti)-1));
        % If n<=1: Var = 0
        VarValues(iOther, :) = 0;
        Stat.var = VarValues;
    end
    % Time vector
    Stat.MatName     = MeanMatName;
    Stat.mean        = MeanValues;
    Stat.Time        = initTimeVector;
    Stat.nAvg        = nAvgTotal;
    Stat.Measure     = initMeasure;
    Stat.ChannelFlag = ones(NbChannels, 1);
    Stat.ChannelFlag(MeanBadChannels) = -1;
    % Remove last \n at the end of the messages
    if ~isempty(Messages)
        Messages = Messages(1:end-1);
    end
    % Return the list of all the events found in all the files
    AllEvents = sFile.events;
end



