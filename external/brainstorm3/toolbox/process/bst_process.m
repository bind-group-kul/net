function varargout = bst_process( varargin )
% BST_PROCESS: Apply a list of processes to a set of files.
%
% USAGE:    sNewFiles = bst_process('Run', sProcesses, sInputs, sInputs2,  isReport=1)
%         OutputFiles = bst_process('CallProcess', sProcess,    sInputs,   sInputs2,   OPTIONS)
%         OutputFiles = bst_process('CallProcess', sProcess,    FileNames, FileNames2, OPTIONS)
%         OutputFiles = bst_process('CallProcess', ProcessName, sInputs,   sInputs2,   OPTIONS)
%         OutputFiles = bst_process('CallProcess', ProcessName, FileNames, FileNames2, OPTIONS)

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
% Authors: Francois Tadel, 2010-2013

macro_methodcall;
end


%% ===== RUN PROCESSES =====
function sInputs = Run(sProcesses, sInputs, sInputs2, isReport)
    % Initializations
    if (nargin < 4) || isempty(isReport)
        isReport = 1;
    end
    if (nargin < 3) || isempty(sInputs2)
        sInputs2 = [];
    elseif ischar(sInputs2) || iscell(sInputs2)
        sInputs2 = GetInputStruct(sInputs2);
    end
    % Create inputs structures
    if ischar(sInputs) || iscell(sInputs)
        sInputs = GetInputStruct(sInputs);
    end
    StudyToRedraw = {};
    isReload = 0;
    % List all the input files
    if ~isempty(sInputs2)
        sInputAll = [sInputs(:)', sInputs2(:)'];
    else
        sInputAll = sInputs;
    end
    % Start a new report session
    if isReport
        bst_report('Start', sInputAll);
    end
    
    % Group some processes together to optimize the pipeline speed
    sProcesses = OptimizePipeline(sProcesses);
    
    
    % ===== PARALLEL PROCESSING =====
    % Can we apply parallel processing?
    %   - parallel option has to be enabled
    %   - matlabpool function must be available
    %   - process does not modify the time definition (not possible for resampling)
    isParallel = 0;
    if (exist('matlabpool', 'file') ~= 0)
        % Look for a process with a parallel computing option
        for iProc = 1:length(sProcesses)
            opts = sProcesses(iProc).options;
            isParallel = isParallel || (isfield(opts, 'parallel') && ~isempty(opts.parallel) && opts.parallel.Value);
        end
        % Start matlabpool
        if isParallel
            try
                matlabpool open;
            catch
            end
        end        
    end
    
    % ===== APPLY PROCESSES =====
    for iProc = 1:length(sProcesses)
        OutputFiles = {};
        % Start a new report session
        if ~(isfield(sProcesses(iProc).options, 'save') && isfield(sProcesses(iProc).options.save, 'Value') && ~isempty(sProcesses(iProc).options.save.Value) && ~sProcesses(iProc).options.save.Value)
            bst_report('Process', sProcesses(iProc), sInputs);
        end
        % Apply process #iProc
        switch lower(sProcesses(iProc).Category)
            case {'filter', 'filter2'}
                % Make sure that file type is indentical for both sets
                if strcmpi(sProcesses(iProc).Category, 'filter2') && ~isempty(sInputs) && ~isempty(sInputs2) && ~strcmpi(sInputs(1).FileType, sInputs2(1).FileType)
                    bst_report('Error', sProcesses(iProc), [], 'Cannot process inputs from different types.');
                    break;
                end
                % Progress bar
                bst_progress('start', 'Process', ['Applying process: ' sProcesses(iProc).Comment '...'], 0, 100 * length(sProcesses) * length(sInputs));
                bst_progress('set', 100 * (iProc-1) * length(sInputs));
                % Process each input file
                for iInput = 1:length(sInputs)
                    % Capture processes crashes
                    try
                        % Apply filter to file
                        if strcmpi(sProcesses(iProc).Category, 'filter')
                            OutputFiles{iInput} = ProcessFilter(sProcesses(iProc), sInputs(iInput));
                        else
                            OutputFiles{iInput} = ProcessFilter2(sProcesses(iProc), sInputs(iInput), sInputs2(iInput));
                        end
                    catch
                        strError = bst_error();
                        if strcmpi(sProcesses(iProc).Category, 'filter')
                            bst_report('Error', sProcesses(iProc), sInputs(iInput), strError);
                        else
                            bst_report('Error', sProcesses(iProc), [sInputs(iInput), sInputs2(iInput)], strError);
                        end
                        continue;
                    end
                    % Increase progress bar
                    bst_progress('set', 100 * ((iProc-1) * length(sInputs) + iInput));
                end
                
            case {'stat1', 'stat2'}
                % Progress bar
                bst_progress('start', 'Process', ['Applying process: ' sProcesses(iProc).Comment '...'], 0, 100 * length(sProcesses));
                bst_progress('set', 100 * (iProc-1));
                % Capture processes crashes
                try
                    OutputFiles = ProcessStat(sProcesses(iProc), sInputs, sInputs2);
                catch
                    strError = bst_error();
                    bst_report('Error', sProcesses(iProc), sInputAll, strError);
                    OutputFiles = {};
                end
                
            case {'file', 'file2'}
                % Progress bar
                bst_progress('start', 'Process', ['Applying process: ' sProcesses(iProc).Comment '...'], 0, 100 * length(sProcesses) * length(sInputs));
                bst_progress('set', 100 * (iProc-1) * length(sInputs));
                % Process each input file
                for iInput = 1:length(sInputs)
                    % Capture processes crashes
                    try
                        if strcmpi(sProcesses(iProc).Category, 'file')
                            tmpFiles = sProcesses(iProc).Function('NoCatch', 'Run', sProcesses(iProc), sInputs(iInput));
                        else
                            tmpFiles = sProcesses(iProc).Function('NoCatch', 'Run', sProcesses(iProc), sInputs(iInput), sInputs2(iInput));
                        end
                    catch
                        strError = bst_error();
                        if strcmpi(sProcesses(iProc).Category, 'file')
                            bst_report('Error', sProcesses(iProc), sInputs(iInput), strError);
                        else
                            bst_report('Error', sProcesses(iProc), [sInputs(iInput), sInputs2(iInput)], strError);
                        end
                        continue;
                    end
                    % Add new files to the final list of output files
                    if ~isempty(tmpFiles)
                        OutputFiles = [OutputFiles, tmpFiles];
                    end
                    % Increase progress bar
                    bst_progress('set', 100 * ((iProc-1) * length(sInputs) + iInput));
                end
                
            case 'custom'
                % Progress bar
                bst_progress('start', 'Process', ['Applying process: ' sProcesses(iProc).Comment '...'], 0, 100 * length(sProcesses));
                bst_progress('set', 100 * (iProc-1));
                % Capture processes crashes
                try
                    if isempty(sInputs2)
                        OutputFiles = sProcesses(iProc).Function('NoCatch', 'Run', sProcesses(iProc), sInputs);
                    else
                        OutputFiles = sProcesses(iProc).Function('NoCatch', 'Run', sProcesses(iProc), sInputs, sInputs2);
                    end
                catch
                    strError = bst_error();
                    bst_report('Error', sProcesses(iProc), sInputAll, strError);
                    OutputFiles = {};
                end
        end
        % Remove empty filenames
        if iscell(OutputFiles)
            iEmpty = find(cellfun(@isempty, OutputFiles));
            if ~isempty(iEmpty)
                OutputFiles(iEmpty) = [];
            end
        end
        % No output: exit the loop
        if isempty(OutputFiles) || isequal(OutputFiles, {[]})
            sInputs = [];
            break;
        elseif ~ischar(OutputFiles) && ~iscell(OutputFiles)
            sInputs = OutputFiles;
            break;
        end
        % Import -> import: Do not update the input
        if isequal(OutputFiles, {'import'});
            continue;
        end
        % Get new inputs structures
        sInputs = GetInputStruct(OutputFiles);
        
        % Get all the studies to update
        allStudies = bst_get('Study', unique([sInputs.iStudy]));
        StudyToRedraw = cat(2, StudyToRedraw, {allStudies.FileName});
        % Are those studies supposed to be reloaded
        isReload = isReload || (~strcmpi(sProcesses(iProc).Category, 'Filter') && isfield(sProcesses(iProc).options, 'overwrite') && isfield(sProcesses(iProc).options.overwrite, 'Value') && isequal(sProcesses(iProc).options.overwrite.Value, 1));
    end

    % Close matlab parallel pool
    if isParallel
        matlabpool close;
    end
    
    % ===== UPDATE INTERFACE =====
    % If there are studies to redraw
    if ~isempty(StudyToRedraw)
        StudyToRedraw = unique(StudyToRedraw);
        % Get all the study indices
        iStudyToRedraw = [];
        for i = 1:length(StudyToRedraw)
            [sStudy, iStudy] = bst_get('Study', StudyToRedraw{i});
            iStudyToRedraw = [iStudyToRedraw, iStudy];
        end
        % Full reload
        if isReload
            db_reload_studies(iStudyToRedraw, 1);
        % Simple tree update
        else
            % Update results links in target study
            db_links('Study', iStudyToRedraw);
            % Update tree 
            panel_protocols('UpdateNode', 'Study', iStudyToRedraw);
        end
        % Select first target study as current node
        try
            nodeStudy = panel_protocols('SelectStudyNode', iStudyToRedraw(1));
        catch
            disp('BST> Warning: Could not select the output file in the tree.'); 
            nodeStudy = [];
        end
        % Save database
        db_save();
        drawnow;
        % Select first output file
        if ~isempty(OutputFiles)
            panel_protocols('SelectNode', nodeStudy, OutputFiles{1});
        end
    end
    % Close progress bar
    bst_progress('stop');
    % Report procesing
    if isReport
        % Save report
        ReportFile = bst_report('Save', sInputs);
        % Open report (errors only)
        bst_report('Open', ReportFile, 0);
    end
end


%% ===== PROCESS: FILTER =====
function OutputFile = ProcessFilter(sProcess, sInput)
    % ===== SELECT CHANNELS =====
    if ismember(sInput.FileType, {'data', 'raw'}) && ~isempty(sInput.ChannelFile) && isfield(sProcess.options, 'sensortypes') && ~isempty(sProcess.options.sensortypes)
        % Read the channel file
        ChannelMat = in_bst_channel(sInput.ChannelFile);
        % Get channel indices
        iSelRows = channel_find(ChannelMat.Channel, sProcess.options.sensortypes.Value);
        % If no selection: file not processed
        if isempty(iSelRows)
            bst_report('Error', sProcess, sInput, ['Selected sensor types are not available in file "' sInput.FileName '".']);
            OutputFile = [];
            return;
        end
    else
        iSelRows = [];
    end
    
    % ===== LOAD FILE =====
    % Raw file: do not load full file
    if strcmpi(sInput.FileType, 'raw')
        isLoadFull = 0;
    else
        isLoadFull = 1;
    end
    % Get data matrix
    [sMat, matName] = in_bst(sInput.FileName, [], isLoadFull);
    matValues = sMat.(matName);
    if isfield(sMat, 'Measure')
        sInput.Measure = sMat.Measure;
        % Do not allow complex values
        if ~ismember(func2str(sProcess.Function), {'process_tf_measure', 'process_matlab_eval', 'process_extract_time'}) && ~isreal(matValues)
            bst_report('Error', sProcess, sInput, 'Cannot process complex values. A measure have to be applied to this data before (power, magnitude, phase...)');
            OutputFile = [];
            return;
        end
    else
        sInput.Measure = [];
    end
    % Do not allow Time Bands
    if isfield(sMat, 'TimeBands') && ~isempty(sMat.TimeBands) && ismember(func2str(sProcess.Function), {'process_average_time', 'process_zscore', 'process_ersd', 'process_extract_time'}) 
        % && isfield(sMat, 'Measure') && ~strcmpi(sMat.Measure, 'other') && ~strcmpi(sMat.Measure, 'plv')
        bst_report('Error', sProcess, sInput, 'Cannot process values averaged by time bands.');
        OutputFile = [];
        return;
    end
    % Copy channel flag information
    if isfield(sMat, 'ChannelFlag')
        sInput.ChannelFlag = sMat.ChannelFlag;
    end
    % Copy nAvg information
    if isfield(sMat, 'nAvg') && ~isempty(sMat.nAvg)
        sInput.nAvg = sMat.nAvg;
    else
        sInput.nAvg = 1;
    end
    % Raw files
    isRaw = isstruct(matValues);
    if isRaw
        sFile = matValues;
        clear matValues;
        iEpoch = 1;
        nEpochs = length(sFile.epochs);
        % Get size of input data
        nRow = length(sMat.ChannelFlag);
        nCol = length(sMat.Time);
        % Prepare import options
        % NOTE: FORCE READING CLEAN DATA (CTF compensators + Previous SSP)
        ImportOptions = db_template('ImportOptions');
        ImportOptions.ImportMode      = 'Time';
        ImportOptions.DisplayMessages = 0;
        ImportOptions.UseCtfComp      = 1;
        ImportOptions.UseSsp          = 1;
        ImportOptions.RemoveBaseline  = 'no';
        % If it is a CTF file NOT saved in 3rd order gradient compensation, and processing channel/channel => WARNING
        if ismember(sFile.format, {'CTF','CTF-CONTINUOUS'}) && (sFile.prop.currCtfComp ~= 3) && ismember(1,sProcess.processDim)
            % Disable the CTF compensation
            ImportOptions.UseCtfComp = 0;
            % Log an error message
            bst_report('Error', sProcess, sInput, [...
                'This CTF file was not saved with the 3rd order compensation.' 10 ...
                'The process is applied on the uncompensated data, which can lead to severe contamination from the reference sensors.' 10 ...
                'If you want to force the CTF compensation to be applied before, use the process: "Artifacts > Apply SSP & CTF compensation"']);
        end
        % Warning: SSP cannot be applied for channel/channel processing
        if ismember(1,sProcess.processDim) && ~isempty(sFile.channelmat) && isfield(sFile.channelmat, 'Projector') && ~isempty(sFile.channelmat.Projector) && any([sFile.channelmat.Projector.Status] == 1)
            % Disable the SSP correction
            ImportOptions.UseSsp = 0;
            % Log a warning message
            bst_report('Error', sProcess, sInput, [...
                'This file contains SSP projectors, which require all the channels to be read at the same time.' 10 ...
                'This process is reading and processing the continuous files one channel after the other.' 10 ...
                'Therefore the SSP operators cannot be applied on the fly before the process is called, they will be applied after, when importing or reviewing the file.' 10, ...
                'If you want to force the SSP projectors to be applied before, use the process: "Artifacts > Apply SSP & CTF compensation"']);
        end
    else
        iEpoch = 1;
        nEpochs = 1;
        % Get size of input data
        [nRow, nCol, nFreq] = size(matValues);
    end
    % If native file with multiple epochs: ERROR
    if isRaw && (nEpochs > 1)
        bst_report('Error', sProcess, sInput, 'Impossible to process native epoched/averaged files. Please import them in database or convert them to continuous.');
        OutputFile = [];
        return;
    end
    % Build output file tag
    fileTag = ['_', strtrim(strrep(sProcess.FileTag,'|',''))];
    % Absolute values of sources?
    isAbsolute = ~isRaw && strcmpi(matName, 'ImageGridAmp') && (sProcess.isSourceAbsolute >= 1);
    if isAbsolute
        matValues = abs(matValues);
        fileTag = ['_abs', fileTag];
    end
    txtProgress = ['Applying process: ' sProcess.Comment '...'];
    
    % ===== PARALLEL PROCESSING =====
    % Can we apply parallel processing?
    %   - parallel option has to be enabled
    %   - matlabpool function must be available
    %   - process dimension 1 has to be allowed
    %   - process does not modify the time definition (not possible for resampling)
    isParallel = (exist('matlabpool', 'file') ~= 0) && isfield(sProcess.options, 'parallel') && ~isempty(sProcess.options.parallel) && sProcess.options.parallel.Value;
    OutMeasure = [];
    OutputMat = [];
    % Run parallel
    if isParallel
        % Process all rows
        if isempty(iSelRows)
            iSelRows = 1:nRow;
        end
        % Set time vector in input
        sInput.TimeVector = sMat.Time;
        OutTime = sMat.Time;
        % RAW: Create a new raw file to store the results
        if isRaw
            bst_progress('text', [txtProgress, ' [reading]']);
            % Get indices
            iBoundRows = [min(iSelRows), max(iSelRows)];
            iReadRows = iBoundRows(1):iBoundRows(2);
            iSkipRow = setdiff(iBoundRows(1):iBoundRows(2), iSelRows) - iBoundRows(1) + 1;
            nProcessRows = iBoundRows(2) - iBoundRows(1) + 1;
            % Read all the input file 
            OutputMat = in_fread(sFile, iEpoch, sFile.prop.samples, iReadRows, ImportOptions);
            % Loop on row blocks
            bst_progress('text', [txtProgress, ' [processing]']);
            parfor iRow = 1:size(OutputMat, 1)
                tic
                % If it is not a row to process: skip
                if ismember(iRow, iSkipRow)
                   continue;
                end
                % Copy input variable
                sInputRow = sInput;
                sInputRow.A = OutputMat(iRow,:,:);
                % Run process
                sInputRow = sProcess.Function('NoCatch', 'Run', sProcess, sInputRow);
                % If an error occured
                if isempty(sInputRow)
                    continue;
                end
                % Save results
                OutputMat(iRow,:,:) = sInputRow.A;
                % Display increment message
                disp(sprintf('Signal #%d/%d: %fs', iRow, nProcessRows, toc));
            end
            % Create new file
            isForceCopy = 1;
            [sFileOut, errMsg] = CreateRawOut(sInput, sFile, fileTag, ImportOptions, isForceCopy);
            % Error processing
            if isempty(sFileOut) && ~isempty(errMsg)
                bst_report('Error', sProcess, sInput, errMsg);
                OutputFile = [];
                return;
            elseif ~isempty(errMsg)
                bst_report('Warning', sProcess, sInput, errMsg);
            end
            % Save
            bst_progress('text', [txtProgress, ' [writing]']);
            out_fwrite(sFileOut, iEpoch, sFileOut.prop.samples, iReadRows, OutputMat);
        % Regular files
        else
            % Create output matrix
            OutputMat = matValues;
            % Loop on row blocks
            parfor iRow = iSelRows
                tic
                % Copy input variable
                sInputRow = sInput;
                % Read values
                sInputRow.A = matValues(iRow, :, :);
                % Run process
                sInputRow = sProcess.Function('NoCatch', 'Run', sProcess, sInputRow);
                % If an error occured
                if isempty(sInputRow)
                    continue;
                end
                % Save results
                OutputMat(iRow,:,:) = sInputRow.A;
                % Display increment message
                disp(sprintf('Signal #%d/%d: %fs', iRow, nRow, toc));
            end
        end
        
    % ===== REGULAR PROCESSING =====
    else
        % ===== SPLIT IN BLOCKS =====
        % Get maximum size of a data block
        ProcessOptions = bst_get('ProcessOptions');
        MaxSize = ProcessOptions.MaxBlockSize;
        % Split the block size in rows and columns
        if (nRow * nCol > MaxSize) && ~isempty(sProcess.processDim)
            % Split max block by row blocks
            if ismember(1, sProcess.processDim)
                % Split by row and col blocks
                if (nCol > MaxSize) && ismember(2, sProcess.processDim)
                    BlockSizeRow = 1;
                    BlockSizeCol = MaxSize;
                % Split only by row blocks
                else
                    BlockSizeRow = max(floor(MaxSize / nCol), 1);
                    BlockSizeCol = nCol;
                end
            % Split max block by col blocks
            elseif ismember(2, sProcess.processDim)
                BlockSizeRow = nRow;
                BlockSizeCol = max(floor(MaxSize / nRow), 1);
            end
            % Adapt block size to FIF block size
            if (BlockSizeCol < nCol) && isRaw && strcmpi(sFile.format, 'FIF') && isfield(sFile.header, 'raw') && isfield(sFile.header.raw, 'rawdir') && ~isempty(sFile.header.raw.rawdir)
                fifBlockSize = double(sFile.header.raw.rawdir(1).nsamp);
                BlockSizeCol = fifBlockSize * max(1, round(BlockSizeCol / fifBlockSize));
            end
        else
            BlockSizeRow = nRow;
            BlockSizeCol = nCol;
        end
        % Split data in blocks
        nBlockRow = ceil(nRow / BlockSizeRow);
        nBlockCol = ceil(nCol / BlockSizeCol);
        % Get current progress bar position
        progressPos = bst_progress('get');
        prevPos = 0;
        % Display console message
        if (nBlockRow > 1) && (nBlockCol > 1)
            disp(sprintf('BST> %s: Processing %d blocks of %d signals and %d time points.', sProcess.Comment, nBlockCol * nBlockRow, BlockSizeRow, BlockSizeCol));
        elseif (nBlockRow > 1)
            disp(sprintf('BST> %s: Processing %d blocks of %d signals.', sProcess.Comment, nBlockRow, BlockSizeRow));
        elseif (nBlockCol > 1)
            disp(sprintf('BST> %s: Processing %d blocks of %d time points.', sProcess.Comment, nBlockCol, BlockSizeCol));
        end
        
        % ===== PROCESS BLOCKS =====
        isFirstLoop = 1;
        % Loop on row blocks
        for iBlockRow = 1:nBlockRow
            % Indices of rows to process
            iRow = 1 + (((iBlockRow-1)*BlockSizeRow) : min(iBlockRow * BlockSizeRow - 1, nRow - 1));
            % Process only the required rows
            if ~isempty(iSelRows)
                [tmp__, iRowProcess] = intersect(iRow, iSelRows);
            end
            % Loop on col blocks
            for iBlockCol = 1:nBlockCol
                % Indices of columns to process
                iCol = 1 + (((iBlockCol-1)*BlockSizeCol) : min(iBlockCol * BlockSizeCol - 1, nCol - 1));
                % Progress bar
                newPos = progressPos + round(((iBlockRow - 1) * nBlockCol + iBlockCol) / (nBlockRow * nBlockCol) * 100);
                if (newPos ~= prevPos)
                    bst_progress('set', newPos);
                    prevPos = newPos;
                end

                % === GET DATA ===
                % Read values
                if isRaw
                    bst_progress('text', [txtProgress, ' [reading]']);
                    % Indices to read
                    SamplesBounds = sFile.prop.samples(1) + iCol([1,end]) - 1;
                    % Read block
                    sInput.A = in_fread(sFile, iEpoch, SamplesBounds, iRow, ImportOptions);
                    % Progress bar: processing
                    bst_progress('text', [txtProgress, ' [processing]']);
                else
                    sInput.A = matValues(iRow, iCol, :);
                end
                % Set time vector in input
                sInput.TimeVector = sMat.Time(iCol);

                % === PROCESS ===
                % Process all rows
                if isempty(iSelRows) || isequal(iRowProcess, 1:size(sInput.A))
                    sInput = sProcess.Function('NoCatch', 'Run', sProcess, sInput);
                % Process only a subset of rows
                elseif ~isempty(iRowProcess)
                    tmp = sInput.A;
                    sInput.A = sInput.A(iRowProcess,:,:);
                    sInput = sProcess.Function('NoCatch', 'Run', sProcess, sInput);
                    if ~isempty(sInput)
                        tmp(iRowProcess,:,:) = sInput.A;
                        sInput.A = tmp;
                    end
                end

                % If an error occured
                if isempty(sInput)
                    OutputFile = [];
                    return;
                end

                % === INITIALIZE OUTPUT ===
                % Split along columns (time): No support for change in sample numbers (resample)
                if ismember(2, sProcess.processDim)
                    nOutTime = nCol;
                    iOutTime = iCol;
                % All the other options (split by row, no split): support for resampling
                else
                    nOutTime = length(sInput.TimeVector);
                    iOutTime = iCol(1) - 1 + (1:length(sInput.TimeVector));
                end

                % Create output variable
                if isFirstLoop
                    isFirstLoop = 0;
                    bst_progress('text', [txtProgress, ' [creating new file]']);
                    % Did time definition change?
                    isTimeChange = ~ismember(2, sProcess.processDim) && ~isequal(sInput.TimeVector, sMat.Time) && (isRaw || ~((size(matValues,2) == 1) && (length(sMat.Time) == 2)));
                    % Output time vector
                    if isTimeChange && isRaw
                        % Do not allow time modifications on continuous files
                        bst_report('Error', sProcess, sInput, 'No changes to the time definition are allowed when processing native files.');
                        OutputFile = [];
                        return;
                    elseif isTimeChange
                        % If there are events: update the time and sample indices
                        if isfield(sMat, 'Events') && ~isempty(sMat.Events)
                            OldFreq = 1./(sMat.Time(2) - sMat.Time(1));
                            sMat.Events = panel_record('ChangeTimeVector', sMat.Events, OldFreq, sInput.TimeVector);
                        end
                        % Save new time vector
                        OutTime = sInput.TimeVector;
                    else
                        OutTime = sMat.Time;
                    end
                    % Output measure
                    if isfield(sInput, 'Measure')
                        OutMeasure = sInput.Measure;                   
                    end
                    % RAW: Create a new raw file to store the results
                    if isRaw
                        % Create new file
                        [sFileOut, errMsg] = CreateRawOut(sInput, sFile, fileTag, ImportOptions);
                        % Error processing
                        if isempty(sFileOut) && ~isempty(errMsg)
                            bst_report('Error', sProcess, sInput, errMsg);
                            OutputFile = [];
                            return;
                        elseif ~isempty(errMsg)
                            bst_report('Warning', sProcess, sInput, errMsg);
                        end
                    else
                        OutputMat = zeros(nRow, nOutTime, nFreq);
                    end
                end

                % === SAVE VALUES ===
                if isRaw
                    bst_progress('text', [txtProgress, ' [writing]']);
                    % Indices to write
                    SamplesBounds = sFileOut.prop.samples(1) + iOutTime([1,end]) - 1;
                    % Write block
                    sFileOut = out_fwrite(sFileOut, iEpoch, SamplesBounds, iRow, sInput.A);
                else
                    OutputMat(iRow,iOutTime,:) = sInput.A;
                end
            end
        end
    end
    
    % ===== CREATE OUTPUT STRUCTURE =====
    % If there is a DataFile link, and the time definition changed, and results is not static: remove link
    if isfield(sMat, 'DataFile') && ~isempty(sMat.DataFile)
        if ~isequal(sMat.Time, OutTime) && (length(OutTime) > 2)
            sMat.DataFile = [];
        else
            sMat.DataFile = file_short(sMat.DataFile);
        end
    end
    % Output time vector
    sMat.Time = OutTime;
    % Output measure
    if ~isempty(OutMeasure)
        sMat.Measure = OutMeasure;
    end
    % Set data fields
    if isRaw
        % Remove the string: "Link to raw file"
        sMat.Comment = strrep(sMat.Comment, 'Link to raw file', 'Raw');
        sMat.Time = [sMat.Time(1), sMat.Time(end)];
        sMat.F = sFileOut;
    else
        sMat.(matName) = OutputMat;
    end
    % Comment: forced in the options
    if isfield(sProcess.options, 'Comment') && isfield(sProcess.options.Comment, 'Value') && ~isempty(sProcess.options.Comment.Value)
        sMat.Comment = sProcess.options.Comment.Value;
    else
        % Absolute value tag
        if isAbsolute
            sMat.Comment = [sMat.Comment, ' | abs'];
        end
        % Add file tag
        if isfield(sInput, 'FileTag') && ~isempty(sInput.FileTag)
            sMat.Comment = [sMat.Comment, ' ', sInput.FileTag];
        else
            sMat.Comment = [sMat.Comment, ' ', sProcess.FileTag];
        end
    end
    % If data + changed data type
    if isfield(sInput, 'DataType') && ~isempty(sInput.DataType) && isfield(sMat, 'DataType')
        sMat.DataType = sInput.DataType;
    end
    if isfield(sInput, 'ColormapType') && ~isempty(sInput.ColormapType)
        sMat.ColormapType = sInput.ColormapType;
    end
    
    % ===== HISTORY =====
    % History: Absolute value
    if isAbsolute
        HistoryComment = [func2str(sProcess.Function) ': Absolute value'];
        sMat = bst_history('add', sMat, 'process', HistoryComment);
    end
    % History: Process name + options
    if isfield(sInput, 'HistoryComment') && ~isempty(sInput.HistoryComment)
        HistoryComment = [func2str(sProcess.Function) ': ' sInput.HistoryComment];
    else
        HistoryComment = [func2str(sProcess.Function) ': ' sProcess.Function('FormatComment', sProcess)];
    end
    sMat = bst_history('add', sMat, 'process', HistoryComment);
    
    % ===== OUTPUT FILENAME =====
    % Protocol folders
    ProtocolInfo = bst_get('ProtocolInfo');
    % If file is a raw link: create new condition
    if isRaw
        % Get short filename
        [tmp, rawBase] = bst_fileparts(sFileOut.filename);
        ConditionName = ['@raw' rawBase];
        newPath = bst_fullfile(ProtocolInfo.STUDIES, ConditionName);
        % Add a numeric tag at the end of the condition name
        if isdir(newPath)
            newPath = file_unique(newPath);
            [tmp, ConditionName] = bst_fileparts(newPath, 1);
        end
        % Create output condition
        iOutputStudy = db_add_condition(sInput.SubjectName, ConditionName);
        if isempty(iOutputStudy)
            bst_report('Error', sProcess, sInput, ['Output folder could not be created:' 10 newPath]);
            OutputFile = [];
            return;
        end
        % Get output study
        sOutputStudy = bst_get('Study', iOutputStudy);
        % Full file name
        OutputFile = bst_fullfile(ProtocolInfo.STUDIES, bst_fileparts(sOutputStudy.FileName), ['data_0raw_' rawBase '.mat']);
        % Get subject
        sSubject = bst_get('Subject', sInput.SubjectName);
        % If no default channel file: create new channel file
        if (sSubject.UseDefaultChannel == 0)
            db_set_channel(iOutputStudy, sFileOut.channelmat, 2, 0);
        end
    % Regular files
    else
        % If file is a link
        if strcmpi(sInput.FileName(1:4), 'link')
            [basekernel, basedata] = file_resolve_link(sInput.FileName);
            if ~isempty(basedata)
                basepath = bst_fileparts(basedata);
                [tmp__, basekernel, basext] = bst_fileparts(basekernel);
                basefile = bst_fullfile(basepath, [basekernel, basext]);
            else
                basefile = basekernel;
            end
        else
            basefile = sInput.FileName;
        end
        % Get output study: same as input
        [sOutputStudy, iOutputStudy, iFile, fileType] = bst_get('AnyFile', sInput.FileName);
        % Full output file
        basefile = file_short(basefile);
        OutputFile = [strrep(basefile, '.mat', ''), fileTag, '.mat'];
        OutputFile = strrep(OutputFile, '_KERNEL', '');
        OutputFile = file_unique(bst_fullfile(ProtocolInfo.STUDIES, OutputFile));
    end
    
    % ===== SAVE FILE =====
    % Save new file
    bst_save(OutputFile, sMat, 'v6');
    
    % ===== REGISTER IN DATABASE =====
    % Overwrite required: check if it is doable
    if isfield(sProcess.options, 'overwrite') && sProcess.options.overwrite.Value 
        % Ignore overwrite for RAW files in another format than BST-BIN
        if isRaw
            sProcess.options.overwrite.Value = 0;
            bst_report('Warning', sProcess, sInput, 'Cannot overwrite native files.');
        % Ignore overwrite for links
        elseif strcmpi(fileType, 'link')
            sProcess.options.overwrite.Value = 0;
            bst_report('Warning', sProcess, sInput, 'Cannot overwrite links.');
        end
    end
    % Register in database
    if isfield(sProcess.options, 'overwrite') && sProcess.options.overwrite.Value
        db_add_data(iOutputStudy, OutputFile, sMat, sInput.iItem);
    else
        db_add_data(iOutputStudy, OutputFile, sMat);
    end
end


%% ===== PROCESS: FILTER2 =====
function OutputFile = ProcessFilter2(sProcess, sInputA, sInputB)
    % ===== LOAD FILES =====
    % Get data matrix
    [sMatA, matName] = in_bst(sInputA.FileName);
    [sMatB, matName] = in_bst(sInputB.FileName);
    sInputA.A = sMatA.(matName);
    sInputB.A = sMatB.(matName);
    % Check size
    if ~isequal(size(sInputA.A), size(sInputB.A)) && ~ismember(func2str(sProcess.Function), {'process_baseline_ab', 'process_zscore_ab', 'process_zscore_dynamic_ab'})
        bst_report('Error', sProcess, [sInputA, sInputB], 'Files in groups A and B do not have the same size.');
        OutputFile = [];
        return;
    end
    % Check time-freq measures
    if isfield(sMatA, 'Measure') && isfield(sMatB, 'Measure') && ~strcmpi(sMatA.Measure, sMatB.Measure)
        bst_report('Error', sProcess, [sInputA, sInputB], 'Files in groups A and B do not have the same measure applied on the time-frequency coefficients.');
        OutputFile = [];
        return;
    end
    % Do not allow TimeBands
    if ((isfield(sMatA, 'TimeBands') && ~isempty(sMatA.TimeBands)) || (isfield(sMatB, 'TimeBands') && ~isempty(sMatB.TimeBands))) ...
            && ismember(func2str(sProcess.Function), {'process_baseline_ab', 'process_zscore_ab'}) 
        % && isfield(sMat, 'Measure') && ~strcmpi(sMat.Measure, 'other') && ~strcmpi(sMat.Measure, 'plv')
        bst_report('Error', sProcess, [sInputA, sInputB], 'Cannot process values averaged by time bands.');
        OutputFile = [];
        return;
    end
    % Copy channel flag information
    if isfield(sMatA, 'ChannelFlag') && isfield(sMatB, 'ChannelFlag')
        sInputA.ChannelFlag = sMatA.ChannelFlag;
        sInputA.ChannelFlag(sMatB.ChannelFlag == -1) = -1;
        sInputB.ChannelFlag = sInputA.ChannelFlag;
    end
    
    % Copy nAvg information
    if isfield(sMatA, 'nAvg') && ~isempty(sMatA.nAvg)
        sInputA.nAvg = sMatA.nAvg;
    else
        sInputA.nAvg = 1;
    end
    if isfield(sMatB, 'nAvg') && ~isempty(sMatB.nAvg)
        sInputB.nAvg = sMatB.nAvg;
    else
        sInputB.nAvg = 1;
    end
    % Copy time information
    sInputA.TimeVector = sMatA.Time;
    sInputB.TimeVector = sMatB.Time;
    % Get output file tag
    if ~isempty(sProcess.FileTag)
        fileTag = ['_', strtrim(strrep(sProcess.FileTag,'|',''))];
    else
        fileTag = [];
    end
    % Absolute values of sources?
    isAbsolute = strcmpi(matName, 'ImageGridAmp') && (sProcess.isSourceAbsolute >= 1);
    if isAbsolute
        sInputA.A = abs(sInputA.A);
        sInputB.A = abs(sInputB.A);
        fileTag = ['_abs', fileTag];
    end

    % ===== PROCESS =====
    % Apply process function
    sOutput = sProcess.Function('NoCatch', 'Run', sProcess, sInputA, sInputB);
    % If an error occured
    if isempty(sOutput)
        OutputFile = [];
        return;
    end
    
    % ===== OUTPUT STUDY =====
    % Get output study
    [sStudy, iStudy, Comment, uniqueDataFile] = GetOutputStudy(sProcess, [sInputA, sInputB], sOutput.Condition);
    % Get output file type
    fileType = GetFileTag(sInputA(1).FileName);
    % Build output filename
    OutputFile = GetNewFilename(bst_fileparts(sStudy.FileName), [fileType fileTag]);

    % ===== CREATE OUTPUT STRUCTURE =====
    sMatOut = sMatB;
    sMatOut.(matName) = sOutput.A;
    % Comment: forced in the options
    if isfield(sProcess.options, 'Comment') && isfield(sProcess.options.Comment, 'Value') && ~isempty(sProcess.options.Comment.Value)
        sMatOut.Comment = sProcess.options.Comment.Value;
    else
        sMatOut.Comment = sOutput.Comment;
    end
    % Reset DataFile field
    if isfield(sMatOut, 'DataFile') && (length(uniqueDataFile) > 1)
        sMatOut.DataFile = [];
    end
    % If data + changed data type
    if isfield(sOutput, 'DataType') && ~isempty(sOutput.DataType) && isfield(sMatOut, 'DataType')
        sMatOut.DataType = sOutput.DataType;
    end
    if isfield(sOutput, 'ColormapType') && ~isempty(sOutput.ColormapType)
        sMatOut.ColormapType = sOutput.ColormapType;
    end
    % Copy time vector
    sMatOut.Time = sOutput.TimeVector;
    % Fix surface link for warped brains
    if isfield(sMatOut, 'SurfaceFile') && ~isempty(sMatOut.SurfaceFile) && ~isempty(strfind(sMatOut.SurfaceFile, '_warped'))
        sMatOut = process_average('FixWarpedSurfaceFile', sMatOut, sInputA(1), sStudy);
    end
    
    % ===== HISTORY =====
    HistoryComment = [func2str(sProcess.Function) ': ' sProcess.Function('FormatComment', sProcess)];
    sMatOut = bst_history('reset', sMatOut);
    sMatOut = bst_history('add', sMatOut, 'process', HistoryComment);
    sMatOut = bst_history('add', sMatOut, 'process', ['File A: ' sInputA.FileName]);
    if ~isempty(sMatA.History)
        sMatOut = bst_history('add', sMatOut, sMatA.History, ' - ');
    end
    sMatOut = bst_history('add', sMatOut, 'process', ['File B: ' sInputB.FileName]);
    if ~isempty(sMatB.History)
        sMatOut = bst_history('add', sMatOut, sMatB.History, ' - ');
    end
    sMatOut = bst_history('add', sMatOut, 'process', 'Process completed');

    % ===== SAVE FILE =====
    % Save new file
    bst_save(OutputFile, sMatOut, 'v6');
    % Register in database
    db_add_data(iStudy, OutputFile, sMatOut);
end


%% ===== PROCESS: STAT =====
function OutputFiles = ProcessStat(sProcess, sInputA, sInputB)
    % Check inputs
    if ~isempty(strfind(GetFileTag(sInputA(1).FileName), 'connect'))
        bst_report('Error', sProcess, sInputA, 'Statistical tests on connectivity results are not supported yet.');
        OutputFiles = [];
        return;
    end

    % ===== CALL PROCESS =====
    isStat1 = strcmpi(sProcess.Category, 'Stat1');
    if isStat1
        sOutput = sProcess.Function('NoCatch', 'Run', sProcess, sInputA);
    else
        sOutput = sProcess.Function('NoCatch', 'Run', sProcess, sInputA, sInputB);
    end
    if isempty(sOutput)
        OutputFiles = {};
        return;
    end
    
    % ===== GET OUTPUT STUDY =====
    % Display progress bar
    bst_progress('text', 'Saving results...');
    % Get number of subjects that are involved
    if isStat1
        uniqueSubjectName = unique({sInputA.SubjectFile});
        uniqueStudy       = unique([sInputA.iStudy]);
    else
        uniqueSubjectName = unique([{sInputA.SubjectFile}, {sInputB.SubjectFile}]);
        uniqueStudy       = unique([sInputA.iStudy, sInputB.iStudy]);
    end
    % If all files share same study: save in it
    if (length(uniqueStudy) == 1)
        [sStudy, iStudy] = bst_get('Study', uniqueStudy);
    % If all files share the same subject: save in intra-analysis
    elseif (length(uniqueSubjectName) == 1)
        % Get subject
        [sSubject, iSubject] = bst_get('Subject', uniqueSubjectName{1});
        % Get intra-subjet analysis study for this subject
        [sStudy, iStudy] = bst_get('AnalysisIntraStudy', iSubject);
    else
        % Get inter-subjet analysis for this subject
        [sStudy, iStudy] = bst_get('AnalysisInterStudy');
    end

    % ===== CREATE OUTPUT STRUCTURE =====
    % Template structure for stat files
    sOutput.Type = sInputA(1).FileType;
    % Comment: forced in the options
    if isfield(sProcess.options, 'Comment') && isfield(sProcess.options.Comment, 'Value') && ~isempty(sProcess.options.Comment.Value)
        sOutput.Comment = sProcess.options.Comment.Value;
    % Regular comment
    else
        sOutput.Comment = sProcess.Function('FormatComment', sProcess);
        if ~isStat1
            % Get comment for files A and B
            [tmp__, tmp__, CommentA] = bst_process('GetOutputStudy', sProcess, sInputA);
            [tmp__, tmp__, CommentB] = bst_process('GetOutputStudy', sProcess, sInputB);
            % Get full comment
            sOutput.Comment = [sOutput.Comment ': ' CommentA ' vs. ' CommentB];
        end
    end
    % Results: Get extra infotmation
    if strcmpi(sInputA(1).FileType, 'results')
        % Load extra fields
        ResultsMat = in_bst_results(sInputA(1).FileName, 0, 'HeadModelType', 'SurfaceFile', 'nComponents');
        % Copy fields
        sOutput.HeadModelType = ResultsMat.HeadModelType;
        sOutput.SurfaceFile   = ResultsMat.SurfaceFile;
        sOutput.nComponents   = ResultsMat.nComponents;
    end
    % Fix surface link for warped brains
    if isfield(sOutput, 'SurfaceFile') && ~isempty(sOutput.SurfaceFile) && ~isempty(strfind(sOutput.SurfaceFile, '_warped'))
        sOutput = process_average('FixWarpedSurfaceFile', sOutput, sInputA(1), sStudy);
    end
    % History
    sOutput = bst_history('add', sOutput, 'stat', sProcess.Comment);
    % History: List files A
    sOutput = bst_history('add', sOutput, 'stat', 'List of files in group A:');
    for i = 1:length(sInputA)
        sOutput = bst_history('add', sOutput, 'stat', [' - ' sInputA(i).FileName]);
    end
    % History: List files B
    sOutput = bst_history('add', sOutput, 'stat', 'List of files in group B:');
    for i = 1:length(sInputB)
        sOutput = bst_history('add', sOutput, 'stat', [' - ' sInputB(i).FileName]);
    end
    
    % ===== SAVE FILE =====
    % Output filetype
    fileType = ['p', GetFileTag(sInputA(1).FileName)];
    % Output filename
    OutputFiles{1} = bst_process('GetNewFilename', bst_fileparts(sStudy.FileName), fileType);
    % Save on disk
    bst_save(OutputFiles{1}, sOutput, 'v6');
    % Register in database
    db_add_data(iStudy, OutputFiles{1}, sOutput);
end



%% ===== INPUT STRUCTURE =====
function sInputs = GetInputStruct(FileNames)
    % If single filename: convert to a list
    if ischar(FileNames)
        FileNames = {FileNames};
    end
    % Output structure
    sInputs = repmat(db_template('processfile'), 0);
    % Loop on all the files
    for i = 1:length(FileNames)
        % Get study
        [sStudy, iStudy, iItem, fileType, sItem] = bst_get('AnyFile', FileNames{i});
        if isempty(sStudy)
            continue;
        end
        % Get subject
        sSubject = bst_get('Subject', sStudy.BrainStormSubject);
        % Get channel file
        sChannel = bst_get('ChannelForStudy', iStudy);
        % Fill structure
        iInput = length(sInputs) + 1;
        sInputs(iInput).iStudy      = iStudy;
        sInputs(iInput).iItem       = iItem;
        sInputs(iInput).FileName    = sItem.FileName;
        sInputs(iInput).Comment     = sItem.Comment;
        sInputs(iInput).SubjectFile = file_win2unix(sStudy.BrainStormSubject);
        sInputs(iInput).SubjectName = sSubject.Name;
        if ~isempty(sChannel)
            sInputs(iInput).ChannelFile  = file_win2unix(sChannel.FileName);
            sInputs(iInput).ChannelTypes = sChannel.Modalities;
        else
            sInputs(iInput).ChannelFile  = [];
            sInputs(iInput).ChannelTypes = [];
        end
        % Condition
        if ~isempty(sStudy.Condition)
            sInputs(iInput).Condition = sStudy.Condition{1};
        else
            sInputs(iInput).Condition = '';
        end
        % Associate data file
        if isfield(sItem, 'DataFile')
            sInputs(iInput).DataFile = sItem.DataFile;
        end
        % File type
        switch(fileType)
            case 'data'
                if strcmpi(sStudy.Data(iItem).DataType, 'raw')
                    sInputs(iInput).FileType = 'raw';
                else
                    sInputs(iInput).FileType = 'data';
                end
            case {'results', 'link'}
                sInputs(iInput).FileType = 'results';
            case 'timefreq'
                sInputs(iInput).FileType = 'timefreq';
            case 'matrix'
                sInputs(iInput).FileType = 'matrix';
            otherwise
                sInputs(iInput).FileType = fileType;
        end
    end
end

%% ===== GET OUTPUT STUDY =====
% USAGE:  [sStudy, iStudy, Comment, uniqueDataFile] = GetOutputStudy(sProcess, sInputs)    
%         [sStudy, iStudy, Comment, uniqueDataFile] = GetOutputStudy(sProcess, sInputs, intraCondName)  : New condition instead of intra-subject
function [sStudy, iStudy, Comment, uniqueDataFile] = GetOutputStudy(sProcess, sInputs, intraCondName)
    % Parse inputs
    if (nargin < 3)
        intraCondName = [];
    end
    
    % === OUTPUT CONDITION ===
    % Get list of subjects / conditions
    uniqueSubj = unique(cellfun(@(c)strrep(c,'\','/'), {sInputs.SubjectFile}, 'UniformOutput', 0));
    uniqueCond = unique({sInputs.Condition});
    uniqueStudy = unique([sInputs.iStudy]);
    % Unique reference data file (results and timefreq only)
    if ~any(cellfun(@isempty, {sInputs.DataFile}))
        DataFiles = {sInputs.DataFile};
        DataFiles = strrep(DataFiles, '/', '');
        DataFiles = strrep(DataFiles, '\', '');
        uniqueDataFile = unique(DataFiles);
    else
        uniqueDataFile = [];
    end
    % One study only
    if (length(uniqueStudy) == 1)
        % Output study: this study
        iStudy = uniqueStudy;
        sStudy = bst_get('Study', iStudy);
        % Get uniformized lists of comments
        listComments = cellfun(@(c)deblank(str_remove_parenth(c)), {sInputs.Comment}, 'UniformOutput', 0);
        uniqueComments = unique(listComments);
        % If averaged list of trials
        if (length(uniqueComments) == 1)
            Comment = sprintf('%s', uniqueComments{1});
        else
            Comment = sprintf('%d files', length(sInputs));
        end
    % One subject only
    elseif (length(uniqueSubj) == 1)
        % Get subject
        [sSubject, iSubject] = bst_get('Subject', uniqueSubj{1});
        % Create new condition for intra-subject
        if ~isempty(intraCondName)
            % Try to get condition
            [sStudy, iStudy] = bst_get('StudyWithCondition', bst_fullfile(sSubject.Name, intraCondName));
            % Condition does not exist: Create new condition
            if isempty(sStudy)
                iStudy = db_add_condition(iSubject, intraCondName, 1);
                sStudy = bst_get('Study', iStudy);
            end
        % Else: Output study = "intra" node for this subject
        else
            [sStudy, iStudy] = bst_get('AnalysisIntraStudy', iSubject);
        end
        % Comment
        Comment = sprintf('%d files', length(sInputs));
    % One condition
    elseif (length(uniqueCond) == 1)
        % Output study: "inter" node
        [sStudy, iStudy] = bst_get('AnalysisInterStudy');
        % Comment
        Comment = sprintf('%s (%d files)', uniqueCond{1}, length(sInputs));
    % No regularities
    else
        % Output study: "inter" node
        [sStudy, iStudy] = bst_get('AnalysisInterStudy');
        % Comment
        Comment = sprintf('%d files', length(sInputs));
    end
    
    % ===== COMBINE CHANNEL FILES =====
    % If source and target studies are not the same
    if ~isequal(uniqueStudy, iStudy)
        % Destination study for new channel file
        [tmp__, iChanStudyDest] = bst_get('ChannelForStudy', iStudy);
        % Source channel files studies
        [tmp__, iChanStudySrc] = bst_get('ChannelForStudy', uniqueStudy);
        % If target study has no channel file: create a new one by combination of the others
        %NoWarning   = strcmpi(sInputs(1).FileType, 'results');
        NoWarning   = 1;
        UserConfirm = 0;
        [isNewFile, Message] = db_combine_channel(unique(iChanStudySrc), iChanStudyDest, UserConfirm, NoWarning);
        % Error management
        if ~isempty(Message)
            bst_report('Warning', sProcess, sInputs, Message);
        end
    end
end

%% ===== GET NEW FILENAME =====
function filename = GetNewFilename(fPath, fBase)
    % Folder
    ProtocolInfo = bst_get('ProtocolInfo');
    fPath = strrep(fPath, ProtocolInfo.STUDIES, '');
    % Date and time
    c = clock;
    strTime = sprintf('_%02.0f%02.0f%02.0f_%02.0f%02.0f', c(1)-2000, c(2:5));
    % Remove extension
    fBase = strrep(fBase, '.mat', '');
    % Full filename
    filename = bst_fullfile(ProtocolInfo.STUDIES, fPath, [fBase, strTime, '.mat']);
    filename = file_unique(filename);
end


%% ===== GET FILE TAG =====
% Return a file tag that would completely identify the type of data available in the input file
function FileTag = GetFileTag(FileName)
    FileType = file_gettype(FileName);
    switch(FileType)
        case 'data'
            if ~isempty(strfind(FileName, '_0raw'))
                FileTag = 'data_0raw';
            else
                FileTag = 'data';
            end
        case {'results', 'link'}
            FileTag = 'results';
        case {'timefreq', 'ptimefreq'}
            FileTag = FileType;
            listTags = {'_fft', '_psd', '_hilbert', ...
                        '_connect1_corr', '_connect1_cohere', '_connect1_granger', '_connect1_plv', '_connect1_plvt', '_connect1', ...
                        '_connectn_corr', '_connectn_cohere', '_connectn_granger', '_connectn_plv', '_connectn_plvt', '_connectn', ...
                        '_pac_fullmaps', '_pac', '_dpac_fullmaps', '_dpac'};
            for i = 1:length(listTags)
                if ~isempty(strfind(FileName, listTags{i}))
                    FileTag = ['timefreq', listTags{i}];
                    break;
                end
            end
        otherwise
            FileTag = FileType;
    end
end


%% ===== LOAD INPUT FILE =====
% USAGE:  [sInput, nSignals, iRows] = bst_process('LoadInputFile', FileName, Target=[], TimeWindow=[], OPTIONS=[LoadFull=1])
%                           OPTIONS = bst_process('LoadInputFile');
function [sInput, nSignals, iRows] = LoadInputFile(FileName, Target, TimeWindow, OPTIONS) %#ok<DEFNU>
    % Default options
    defOPTIONS = struct(...
        'LoadFull',     1, ...
        'IgnoreBad',    0, ...
        'ProcessName',  'process_unknown');
    nSignals = 0;
    iRows = [];
    % Return default options structure
    if (nargin == 0)
        sInput = defOPTIONS;
        return;
    elseif (nargin < 4) || isempty(OPTIONS)
        OPTIONS = defOPTIONS;
    else
        OPTIONS = struct_copy_fields(OPTIONS, defOPTIONS, 0);
    end
    % Other defaults
    if (nargin < 3) || isempty(TimeWindow)
        TimeWindow = [];
    end
    if (nargin < 2) || isempty(Target)
        Target = [];
    end
    % Initialize returned variables
    sInput = struct(...
        'Data',          [], ...
        'ImagingKernel', [], ...
        'RowNames',      [], ...
        'Time',          [], ...
        'DataType',      [], ...
        'Comment',       [], ...
        'iStudy',        [], ...
        'Atlas',         [], ...
        'SurfaceFile',   [], ...
        'GridLoc',       [], ...
        'nComponents',   []);
    % Find file in database
    [sStudy, sInput.iStudy, iFile, sInput.DataType] = bst_get('AnyFile', FileName);
    % Load file
    [sMat, matName] = in_bst(FileName, TimeWindow, OPTIONS.LoadFull, OPTIONS.IgnoreBad);
    sInput.Data = sMat.(matName);
    % Select signal of interest
    switch (sInput.DataType)
        case 'data'
            % Get channel file
            sChannel = bst_get('ChannelForStudy', sInput.iStudy);
            % Load channel file
            ChannelMat = in_bst_channel(sChannel.FileName);
            % If channel specified, use it. If not, use all the channels
            if ~isempty(Target)
                iRows = channel_find(ChannelMat.Channel, Target);
                if isempty(iRows)
                    bst_report('Error', OPTIONS.ProcessName, [], ['Channel "' Target '" does not exist.']);
                    sInput.Data = [];
                    return;
                end
            else
                iRows = 1:length(ChannelMat.Channel);
            end
            % Ignore bad channels
            if OPTIONS.IgnoreBad && isfield(sMat, 'ChannelFlag') && ~isempty(sMat.ChannelFlag) && any(sMat.ChannelFlag == -1)
                iGoodChan = find(sMat.ChannelFlag' == 1);
                iRows = intersect(iRows, iGoodChan);
            end
            % Keep only the channels of interest
            if (length(iRows) ~= length(ChannelMat.Channel))
                sInput.Data = sInput.Data(iRows,:);
            end
            % Get the row names
            sInput.RowNames = {ChannelMat.Channel(iRows).Name};
            
        case {'results', 'link'}
            % Save number of components per vertex
            sInput.nComponents = sMat.nComponents;
            % All the source indices
            nSources = size(sInput.Data,1);
            AllRowNames = reshape(repmat(1:nSources, sMat.nComponents, 1), 1, []);
            % Rows are indicated with integers: indices of the sources
            if ~isempty(Target)
                % Check Target type
                if ischar(Target)
                    iRows = str2num(Target);
                elseif isnumeric(Target)
                    switch (sMat.nComponents)
                        case 1,   iRows = Target;
                        case 2,   iRows = 2*Target + [-1 0];
                        case 3,   iRows = 3*Target + [-2 -1 0];
                    end
                end
                % Check rows
                if isempty(iRows) || any(iRows > size(sInput.Data,1))
                    bst_report('Error', OPTIONS.ProcessName, [], 'Invalid sources selection.');
                    sInput.Data = [];
                    return;
                end
                % Keep only the sources of interest
                sInput.Data = sInput.Data(iRows,:);
            else
                % Keep all the sources
                iRows = 1:size(sInput.Data,1);
            end
            % Row names = indices
            sInput.DataType = 'results';
            % Copy recordings in case of kernel+recordings file
            if strcmpi(matName, 'ImagingKernel') && isfield(sMat, 'F') && ~isempty(sMat.F)
                sInput.ImagingKernel = sInput.Data;
                sInput.Data = sMat.F;
            end
            % Get the associated surface
            if ~isempty(sMat.SurfaceFile)
                sInput.SurfaceFile = sMat.SurfaceFile;
            end
            if ~isempty(sMat.GridLoc)
                sInput.GridLoc = sMat.GridLoc;
            end
            % Copy atlas if it exists
            if isfield(sMat, 'Atlas') && ~isempty(sMat.Atlas)
                sInput.Atlas = sMat.Atlas;
                sInput.RowNames = {sMat.Atlas.Scouts(iRows).Label};
            else
                sInput.RowNames = AllRowNames(iRows);
            end
            
        case 'timefreq'
            % Find target rows
            if ~isempty(Target)
                RowNames = strtrim(str_split(Target, ',;'));
                iRows = find(ismember(sMat.RowNames, RowNames));
                if isempty(iRows)
                    bst_report('Error', OPTIONS.ProcessName, [], 'Invalid rows selection.');
                    sInput.Data = [];
                    return;
                end
                sInput.Data = sInput.Data(iRows,:,:);
            else
                iRows = 1:size(sInput.Data,1);
            end
            % Get the row names
            sInput.RowNames = sMat.RowNames(iRows);
            sInput.DataType = sMat.DataType;
            % Copy surface file
            if isfield(sMat, 'SurfaceFile') && ~isempty(sMat.SurfaceFile)
                sInput.SurfaceFile = sMat.SurfaceFile;
            end
            
        case 'matrix'
            % Scouts time series: remove everything after the @
            for iDesc = 1:numel(sMat.Description)
                iAt = find(sMat.Description{iDesc} == '@', 1);
                if ~isempty(iAt)
                    sMat.Description{iDesc} = strtrim(sMat.Description{iDesc}(1:iAt-1));
                end
            end
            % Select target rows
            if ~isempty(Target) && (size(sMat.Description,2) == 1)
                % Check Target type
                if ischar(Target)
                    % Look for the row by name
                    iRows = find(strcmpi(sMat.Description, Target));
                    % If nothing found: look for the row by index
                    if isempty(iRows)
                        iRows = str2num(Target);
                    end
                elseif isnumeric(Target)
                    iRows = Target;
                end
                % Nothing found, definitely: error
                if isempty(iRows) || (max(iRows) > size(sInput.Data,1))
                    bst_report('Error', OPTIONS.ProcessName, [], ['Row "' Target '" does not exist.']);
                    sInput.Data = [];
                    return;
                end
                % Keep only the rows of interest
                sInput.Data = sInput.Data(iRows,:);
            else
                iRows = 1:size(sMat.Description,1);
            end
            % Get the row names
            sInput.RowNames = sMat.Description(iRows,:);
            sInput.DataType = 'matrix';
            
        otherwise
            error('todo');
    end
    % Other values to return
    sInput.Time    = sMat.Time;
    sInput.Comment = sMat.Comment;
    % Count output signals
    if ~isempty(sInput.ImagingKernel) 
        nSignals = size(sInput.ImagingKernel, 1);
    else
        nSignals = size(sInput.Data, 1);
    end
end


%% ===== CALL PROCESS =====
% USAGE:  OutputFiles = bst_process('CallProcess', sProcess,    sInputs,   sInputs2,   OPTIONS)
%         OutputFiles = bst_process('CallProcess', sProcess,    FileNames, FileNames2, OPTIONS)
%         OutputFiles = bst_process('CallProcess', ProcessName, sInputs,   sInputs2,   OPTIONS)
%         OutputFiles = bst_process('CallProcess', ProcessName, FileNames, FileNames2, OPTIONS)
function OutputFiles = CallProcess(sProcess, sInputs, sInputs2, varargin) %#ok<DEFNU>
    % Get process
    if ischar(sProcess)
        sProcess = panel_process_select('GetProcess', sProcess);
        if isempty(sProcess)
            error('Unknown process.');
        end
    end
    % Get files
    if isempty(sInputs) || isequal(sInputs, {''})
        % If no inputs, but the process requires input files: error
        if (sProcess.nMinFiles > 0)
            bst_report('Error', sProcess, [], 'No input.');
            OutputFiles = [];
            return;
        % Else: input is import
        else
            sInputs = db_template('importfile');
        end
    elseif ~isstruct(sInputs)
        sInputs = GetInputStruct(sInputs);
    end
    % Get files
    if ~isempty(sInputs2) && ~isstruct(sInputs)
        sInputs2 = GetInputStruct(sInputs2);
    end
    % Get options
    for i = 1:2:length(varargin)
        if ~ischar(varargin{i})
            error('Invalid options.');
        end
        % Get default and new values
        if isfield(sProcess.options, varargin{i}) && isfield(sProcess.options.(varargin{i}), 'Value')
            defVal = sProcess.options.(varargin{i}).Value;
        else
            defVal = [];
        end
        if isfield(sProcess.options, varargin{i}) && isfield(sProcess.options.(varargin{i}), 'Type')
            defType = sProcess.options.(varargin{i}).Type;
        else
            defType = '';
        end
        newVal = varargin{i+1};
        updateVal = defVal;
        %  Simple "value" type call: just the value instead of the cell list
        if ~isempty(defVal) && iscell(defVal) && isnumeric(newVal)
            updateVal{1} = newVal;
        elseif ismember(lower(defType), {'timewindow','baseline','poststim','value','range'}) && isempty(defVal) && ~isempty(newVal) && ~iscell(newVal)
            updateVal = {newVal, 's', []};
        elseif ismember(lower(defType), {'timewindow','baseline','poststim','value','range','combobox'}) && iscell(defVal) && ~isempty(defVal) && ~iscell(newVal) && ~isempty(newVal)
            updateVal{1} = newVal;
        % Generic call: just copy the value
        else
            updateVal = newVal;
        end
        % Save the finale value
        sProcess.options.(varargin{i}).Value = updateVal;
    end
    % Absolute values of sources
    if isfield(sProcess.options, 'source_abs') && ~isempty(sProcess.options.source_abs) && ~isempty(sProcess.options.source_abs.Value)
        sProcess.isSourceAbsolute = sProcess.options.source_abs.Value;
    elseif (sProcess.isSourceAbsolute < 0)
        sProcess.isSourceAbsolute = 0;
    elseif (sProcess.isSourceAbsolute > 1)
        sProcess.isSourceAbsolute = 1;
    end
    % Call process
    OutputFiles = Run(sProcess, sInputs, sInputs2, 0);
end


%% ===== CREATE OUTPUT RAW FILE =====
function [sFileOut, errMsg] = CreateRawOut(sInput, sFileIn, fileTag, ImportOptions, isForceCopy)
    % Parse inputs
    if (nargin < 5) || isempty(isForceCopy)
        isForceCopy = 0;
    end
    % Copy input file structure
    sFileOut = sFileIn;
    errMsg = [];
    % Switch based on file format
    switch (sFileIn.format)
        case 'FIF'
            % Define output filename
            sFileOut.filename = file_unique(strrep(sFileIn.filename, '.fif', [fileTag, '.fif']));
            % Copy in file to out file
            res = copyfile(sFileIn.filename, sFileOut.filename, 'f');
            if ~res
                error(['Could not create output file: ' sFileOut.filename]);
            end
            
        case {'CTF', 'CTF-CONTINUOUS'}
            % Output is forced to 3rd order gradient
            if ImportOptions.UseCtfComp
                sFileOut.prop.currCtfComp = 3;
                sFileOut.header.grad_order_no = 3 * ones(size(sFileOut.header.grad_order_no));
            end
            % File output has to be ctf-continuous
            sFileOut.format = 'CTF-CONTINUOUS';
            % Input dataset name
            [dsPath, dsNameIn, dsExt] = bst_fileparts(bst_fileparts(sFileIn.filename));
            pathIn = bst_fullfile(dsPath, [dsNameIn, dsExt]);
            % Output dataset name
            pathOut = file_unique(bst_fullfile(dsPath, [dsNameIn, fileTag, dsExt]));
            [tmp__, dsNameOut, dsExt] = bst_fileparts(pathOut);
            % Make sure that folder does not exist yet
            if isdir(pathOut)
                errMsg = ['Output folder already exists: ' pathOut];
                sFileOut = [];
                return;
            end
            % Create new folder
            res = mkdir(pathOut);
            if ~res
                errMsg = ['Could not create output folder: ' pathOut];
                sFileOut = [];
                return;
            end
            % Copy each file of original ds folder
            dirDs = dir(bst_fullfile(pathIn, '*'));
            for iFile = 1:length(dirDs)
                % Some filenames to skip
                if ismember(dirDs(iFile).name, {'.', '..', 'hz.ds'})
                    continue;
                end
                % Some extensions to process differently
                [tmp__, fName, fExt] = bst_fileparts(dirDs(iFile).name);
                switch (fExt)
                    case '.ds'
                        % Ignore the sub-folders (ex: hz.ds)
                        continue;

                    case {'.meg4','.1_meg4','.2_meg4','.3_meg4','.4_meg4','.5_meg4','.6_meg4','.7_meg4','.8_meg4','.9_meg4'}
                        destfile = bst_fullfile(pathOut, [dsNameOut, fExt]);
                        % If file is the .meg4, set it as the file referenced in the sFile structure
                        if strcmpi(fExt, '.meg4')
                            sFileOut.filename = destfile;
                        end
                        % All the other .res4: replace the name in the meg4_files cell array
                        iMeg4 = find(~cellfun(@(c)isempty(strfind(c, fExt)), sFileOut.header.meg4_files));
                        if (length(iMeg4) ~= 1)
                            errMsg = 'Multiple .res4 files in the .ds folder. Cannot process.';
                            sFileOut = [];
                            return;
                        end
                        sFileOut.header.meg4_files{iMeg4} = destfile;
                        % Create empty file (with header), do not copy initial file
                        if ~isForceCopy
                            sfid = fopen(destfile, 'w+');
                            fwrite(sfid, ['MEG41CP' 0], 'char');
                            fclose(sfid);
                            destfile = [];
                        % Make a full copy of the file
                        else
                            % Just keep destfile variable, and the next block will copy the file
                        end
                    case {'.acq','.hc','.hist','.infods','.newds','.res4'}
                        % Copy file, force the name to be the DS name
                        destfile = bst_fullfile(pathOut, [dsNameOut, fExt]);
                        
                    otherwise
                        % Copy file, keep initial filename
                        destfile = bst_fullfile(pathOut, dirDs(iFile).name);
                end
                % Copy file, replacing the name of the DS
                if ~isempty(destfile)
                    res = copyfile(bst_fullfile(pathIn, dirDs(iFile).name), destfile, 'f');
                    if ~res
                        errMsg = ['Could not create output file: ' destfile];
                        sFileOut = [];
                        return;
                    end
                end
            end
            % Delete epochs description
            sFileOut.epochs = [];

        otherwise
            errMsg = 'Unsupported file format (only continuous FIF and CTF files can be processed).';
            sFileOut = [];
            return;
    end
    % Mark the projectors as already applied to the file
    if ImportOptions.UseSsp && isfield(sFileOut.channelmat, 'Projector') && ~isempty(sFileOut.channelmat.Projector)
        for iProj = 1:length(sFileOut.channelmat.Projector)
            if (sFileOut.channelmat.Projector(iProj).Status == 1)
                sFileOut.channelmat.Projector(iProj).Status = 2;
            end
        end
    end
end


%% ===== OPTIMIZE PIPELINE =====
function sProcesses = OptimizePipeline(sProcesses)
    % Find an import process
    iImport = [];
    for i = 1:length(sProcesses)
        if ismember(func2str(sProcesses(i).Function), {'process_import_data_epoch', 'process_import_data_time', 'process_import_data_event'})
            iImport = i;
            break;
        end
    end
    % If there is no import pipeline: exit
    if isempty(iImport)
        return;
    end
    % Loop on the processes that can be glued to this one
    iRemove = [];
    for iProcess = (iImport+1):length(sProcesses)
        % List of accepted processes: copy options
        switch (func2str(sProcesses(iProcess).Function))
            case 'process_baseline'
                sProcesses(iImport).options.baseline = sProcesses(iProcess).options.baseline;
                % Ignoring sensors selection
                if isfield(sProcesses(iProcess).options, 'sensortypes') && ~isempty(sProcesses(iProcess).options.sensortypes.Value)
                    strWarning = [10 ' - Sensor selection is ignored, baseline is removed from all the data channels.'];
                else
                    strWarning = '';
                end
            case 'process_resample'
                sProcesses(iImport).options.freq = sProcesses(iProcess).options.freq;
                strWarning = '';
            otherwise
                break;
        end
        % Force overwrite
        if isfield(sProcesses(iProcess).options, 'overwrite') && ~sProcesses(iProcess).options.overwrite.Value
            strWarning = [strWarning 10 ' - Forcing overwrite option: Intermediate files are not saved in the database.'];
        end
        % Merge processes
        iRemove(end+1) = iProcess;
        % Issue warning in the report
        bst_report('Warning', sProcesses(iProcess), [], ['Process "' sProcesses(iProcess).Comment '" has been merged with process "' sProcesses(iImport).Comment '".' strWarning]);
    end
    % Remove the processes that were included somewhere else
    if ~isempty(iRemove)
        sProcesses(iRemove) = [];
    end
end


%% ===== OPTIMIZE PIPELINE: REVERT =====
% Re-expand optimized pipeline to the original list of processes
function sProcesses = OptimizePipelineRevert(sProcesses) %#ok<DEFNU>
    % Find an import process
    iImport = [];
    for i = 1:length(sProcesses)
        if ismember(func2str(sProcesses(i).Function), {'process_import_data_epoch', 'process_import_data_time', 'process_import_data_event'})
            iImport = i;
            break;
        end
    end
    % If there is no import pipeline: exit
    if isempty(iImport)
        return;
    end
    % Check some options to convert to other processes
    sProcAdd = repmat(db_template('processdesc'), 0);
    if isfield(sProcesses(iImport).options, 'baseline') && isfield(sProcesses(iImport).options.baseline, 'Value') && ~isempty(sProcesses(iImport).options.baseline.Value)
        % Get process
        sProcAdd(end+1).Function = @process_baseline;
        sProcAdd(end) = struct_copy_fields(sProcAdd(end), process_baseline('GetDescription'), 1);
        % Set options
        sProcAdd(end).options.sensortypes.Value = '';
        sProcAdd(end).options.baseline.Value = sProcesses(iImport).options.baseline.Value;
        % Remove option from initial process
        sProcesses(iImport).options = rmfield(sProcesses(iImport).options, 'baseline');
    end
    if isfield(sProcesses(iImport).options, 'freq') && isfield(sProcesses(iImport).options.freq, 'Value') && ~isempty(sProcesses(iImport).options.freq.Value)
        % Get process
        sProcAdd(end+1).Function = @process_resample;
        sProcAdd(end) = struct_copy_fields(sProcAdd(end), process_resample('GetDescription'), 1);
        % Set options
        sProcAdd(end).options.freq.Value = sProcesses(iImport).options.freq.Value;
        % Remove option from initial process
        sProcesses(iImport).options = rmfield(sProcesses(iImport).options, 'freq');
    end
    % Add to process list
    sProcesses = [sProcesses(1:iImport), sProcAdd, sProcesses(iImport+1:end)];
end



