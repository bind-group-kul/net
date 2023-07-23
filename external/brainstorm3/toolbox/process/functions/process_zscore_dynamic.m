function varargout = process_zscore_dynamic( varargin )
% PROCESS_ZSCORE_DYNAMIC: Prepares a file for dynamic display of the zscore (load-time)
%
% DESCRIPTION:  For each channel:
%     1) Compute mean m and variance v for baseline
%     2) For each time sample, subtract m and divide by v
                        
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
% Authors: Francois Tadel, 2013

macro_methodcall;
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Z-score (dynamic)';
    sProcess.FileTag     = '| zscored';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Standardize';
    sProcess.Index       = 411;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'results', 'timefreq', 'matrix'};
    sProcess.OutputTypes = {'data', 'results', 'timefreq', 'matrix'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;

    % Definition of the options
    % === Baseline time window
    sProcess.options.baseline.Comment = 'Baseline:';
    sProcess.options.baseline.Type    = 'baseline';
    sProcess.options.baseline.Value   = [];
    % === Sensor types
    sProcess.options.sensortypes.Comment = 'Sensor types or names (empty=all): ';
    sProcess.options.sensortypes.Type    = 'text';
    sProcess.options.sensortypes.Value   = 'MEG, EEG';
    sProcess.options.sensortypes.InputTypes = {'data'};
    % === Absolute values for sources
    sProcess.options.source_abs.Comment = 'Use absolute values of source activations';
    sProcess.options.source_abs.Type    = 'checkbox';
    sProcess.options.source_abs.Value   = 1;
    sProcess.options.source_abs.InputTypes = {'results'};
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess)
    % Get frequency band
    time = sProcess.options.baseline.Value{1};
    % Add frequency band
    if any(abs(time) > 2)
        Comment = sprintf('Z-score normalization (dynamic): [%1.3fs,%1.3fs]', time(1), time(2));
    else
        Comment = sprintf('Z-score normalization (dynamic): [%dms,%dms]', round(time(1)*1000), round(time(2)*1000));
    end
end


%% ===== RUN =====
% USAGE:  OutputFiles = process_zscore_dynamic('Run', sProcess, sInputs)
%         OutputFiles = process_zscore_dynamic('Run', sProcess, sInputsBaseline, sInputs)
function OutputFiles = Run(sProcess, sInputsBaseline, sInputs) %#ok<DEFNU>

    % ===== OPTIONS =====
    % Initialize output file list
    OutputFiles = {};
    % Parse inputs
    if (nargin < 3) || isempty(sInputs)
        sInputs = sInputsBaseline;
        isBinaryInput = 0;
    else
        isBinaryInput = 1;
    end
    % Get options
    ZScore.baseline = sProcess.options.baseline.Value{1};
    if isfield(sProcess.options, 'sensortypes') && ~isempty(sProcess.options.sensortypes)
        SensorsTypes = sProcess.options.sensortypes.Value;
    else
        SensorsTypes = [];
    end
    if isfield(sProcess.options, 'source_abs') && ~isempty(sProcess.options.source_abs)
        ZScore.abs = sProcess.options.source_abs.Value;
    else
        ZScore.abs = 0;
    end
    % Check file types
    if ~strcmpi(sInputsBaseline(1).FileType, sInputs(1).FileType)
        bst_report('Error', sProcess, sInputsBaseline, 'Files in sets A and B must be of the same type.');
        return;
    elseif (length(sInputsBaseline) ~= length(sInputs))
        bst_report('Error', sProcess, sInputsBaseline, 'This process requires the same number of files in file groups A and B.');
        return;
    end
    % Initialize progress bar
    startValue = bst_progress('get');
    % Load kernel-based results as FULL sources
    OPTIONS.ProcessName = func2str(sProcess.Function);
    OPTIONS.LoadFull = 1;
    
    % ===== GET INPUT FILES =====
    FileType = sInputs(1).FileType;
    % Group the source files that rely on the same shared kernel
    if strcmpi(FileType, 'results') && ~isBinaryInput
        % Get source file
        [InputResFiles, InputDataFiles] = cellfun(@file_resolve_link, {sInputs.FileName}, 'UniformOutput', 0);
        % Replace the empty entries in the list of data files with '' (so that it ismember doesn't crash later)
        [InputDataFiles{cellfun(@isempty, InputDataFiles)}] = deal('');
        % Find the unique files to process
        [tmp, iUnique] = unique(InputResFiles);
        iUnique = sort(iUnique);
        FileNames = InputResFiles(iUnique);
        % Keep only the unique inputs
        sInputs = sInputs(iUnique);
        sInputsBaseline = sInputsBaseline(iUnique);
    else
        FileNames = file_fullpath({sInputs.FileName});
    end
    % Define default colormap type
    if strcmpi(FileType, 'results')
        ColormapType = 'stat1';
    else
        ColormapType = 'stat2';
    end

    % Loop over all the input files
    for iFile = 1:length(FileNames)
        bst_progress('set', round(startValue + (iFile-1) / length(FileNames) * 100));
        
        % ===== GET CHANNEL INDICES =====
        % If processing recordings and sensor types is not empty
        if strcmpi(FileType, 'data') && ~isempty(SensorsTypes)
            % Load channel file
            ChannelMat = in_bst_channel(sInputs(iFile).ChannelFile);
            % Find selected sensors
            iChannels = channel_find(ChannelMat.Channel, SensorsTypes);
            % Find channels to exclude from the computation
            iRowExclude = setdiff(1:length(ChannelMat.Channel), iChannels);
        else
            iRowExclude = [];
        end
    
        % ===== LOAD =====
        % Check if default study
        isSharedKernel = strcmpi(FileType, 'results') && ~isempty(strfind(sInputs(iFile).FileName, 'link|')) && ~isempty(strfind(FileNames{iFile}, '_KERNEL_'));
        % If regular file: load and calculate the baseline
        if ~isSharedKernel || isBinaryInput
            % Load the baseline
            sInput = bst_process('LoadInputFile', sInputsBaseline(iFile).FileName, [], ZScore.baseline, OPTIONS);
            if isempty(sInput) || isempty(sInput.Data)
                return;
            end
            % Check for measure
            if ~isreal(sInput.Data)
                bst_report('Error', sProcess, sInputsBaseline(iFile), 'Cannot process complex values. Please apply a measure to the values before calling this function.');
                return;
            end
            % If the metrics have to be calculated from absolute values
            if ZScore.abs
                sInput.Data = abs(sInput.Data);
            end
            % Calculate mean and standard deviation
            [ZScore.mean, ZScore.std] = process_zscore('ComputeStat', sInput.Data);
            % Set rows that were not supposed to normalized to m=0 and std=1
            if ~isempty(iRowExclude)
                ZScore.mean(iRowExclude) = 0;
                ZScore.std(iRowExclude)  = 1;
            end
        % Shared kernel: we cannot calculate the baseline now, it has to be done at the load time
        else
            ZScore.mean = [];
            ZScore.std  = [];
        end
        
        % ===== OUTPUT STRUCTURE =====
        % Load full original file
        sMat = load(FileNames{iFile});
        % Add the structure zscore + other file modifications
        sMat.ZScore       = ZScore;
        sMat.ColormapType = ColormapType;
        if strcmpi(FileType, 'data')
            sMat.DataType = 'zscore';
        end
        % Define file tag
        if ZScore.abs
            sMat.Comment = [sMat.Comment ' | abs ' sProcess.FileTag];
            fileTag = '_abs_zscore';
        else
            sMat.Comment = [sMat.Comment ' ' sProcess.FileTag];
            fileTag = '_zscore';
        end
        % Add history entry
        sMat = bst_history('add', sMat, 'process', [func2str(sProcess.Function) ': ' FormatComment(sProcess)]);
        
        % ===== SAVE FILE =====
        % Get output study and filename
        if isSharedKernel && isBinaryInput
            [sOutputStudy, iOutputStudy, iRes] = bst_get('AnyFile', FileNames{iFile});
            [tmp, kernelName] = bst_fileparts(FileNames{iFile});
            OutputFile = file_unique(bst_fullfile(bst_fileparts(file_fullpath(sOutputStudy.FileName)), [kernelName, fileTag '.mat']));
            % Attach this output kernel to the input data file
            sMat.DataFile = sOutputStudy.Result(iRes).DataFile;
        else
            [sOutputStudy, iOutputStudy] = bst_get('AnyFile', FileNames{iFile});
            OutputFile = file_unique(strrep(FileNames{iFile}, '.mat', [fileTag '.mat']));
        end
        % Save new file
        bst_save(OutputFile, sMat, 'v6');
        % Add file to database structure
        sOutputStudy = db_add_data(iOutputStudy, OutputFile, sMat);

        % ===== RELOAD =====
        % Addition checks operations for results files
        if strcmpi(FileType, 'results')
            % Update links if the was create was a shared kernel
            if isSharedKernel && ~isBinaryInput
                % Refresh node in tree first
                panel_protocols('UpdateNode', 'Study', iOutputStudy);
                % Update links
                isDefaultStudy = strcmpi(sOutputStudy.Name, bst_get('DirDefaultStudy'));
                if isDefaultStudy
                    [sSubject, iSubject] = bst_get('Subject', sOutputStudy.BrainStormSubject);
                    OutputLinks = db_links('Subject', iSubject);
                    panel_protocols('UpdateTree');
                else
                    OutputLinks = db_links('Study', iOutputStudy);
                end
                % Split the links in results+data file
                [LinkResFiles, LinkDataFiles] = cellfun(@file_resolve_link, OutputLinks, 'UniformOutput', 0);
                % Find the links that are relative to the kernel we just saved AND to the data files in input
                iSelLinks = find(file_compare(LinkResFiles, OutputFile) & ismember(LinkDataFiles, InputDataFiles));
                % If some files were found: add them to the list of returned files
                if ~isempty(iSelLinks)
                    OutputFiles = cat(2, OutputFiles, OutputLinks{iSelLinks});
                end
            else
                OutputFiles{end+1} = OutputFile;
            end
        else
            OutputFiles{end+1} = OutputFile;
        end
    end
end


%% ===== COMPUTE DYNAMIC ZSCORE =====
% USAGE:  [Data, ZScore] = process_zscore_dynamic('Compute', Data, ZScore, Time, ImagingKernel, F)    % Estimate ZScore for kernel-based sources
%         [Data, ZScore] = process_zscore_dynamic('Compute', Data, ZScore, Time)
%         [Data, ZScore] = process_zscore_dynamic('Compute', Data, ZScore)
function [Data, ZScore] = Compute(Data, ZScore, Time, ImagingKernel, F) %#ok<DEFNU>
    % Time is optional for some calls
    if (nargin < 5)
        ImagingKernel = [];
        F = [];
    end
    if (nargin < 3)
        Time = [];
    end
    % Error in file structure
    if ~isfield(ZScore, 'mean') || ~isfield(ZScore, 'std') || ~isfield(ZScore, 'abs')
        error('Error in file structure.');
    end
    % Apply absolute value
    if ZScore.abs && ~isempty(Data)
        Data = abs(Data);
    end
    % Calculate mean and std if not available yet
    if isempty(ZScore.mean) || isempty(ZScore.std)
        if isempty(Time)
            error('Operation not supported.');
        end
        % Find baseline indices
        iBaseline = panel_time('GetTimeIndices', Time, ZScore.baseline);
        if isempty(iBaseline)
            bst_report('Error', 'process_zscore_dynamic', [], 'Baseline definition is not valid for this file.');
            Data = [];
            return;
        end
        % Compute from the Data matrix
        if isempty(ImagingKernel)
            [ZScore.mean, ZScore.std] = process_zscore('ComputeStat', Data(:,iBaseline,:));
        elseif ZScore.abs
            [ZScore.mean, ZScore.std] = process_zscore('ComputeStat', abs(ImagingKernel * F(:,iBaseline)));
        else
            [ZScore.mean, ZScore.std] = process_zscore('ComputeStat', ImagingKernel * F(:,iBaseline));
        end
    end
    % Apply Z-score
    if ~isempty(Data)
        Data = bst_bsxfun(@minus,   Data, ZScore.mean);
        Data = bst_bsxfun(@rdivide, Data, ZScore.std);
    end
end


