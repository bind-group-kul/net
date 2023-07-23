function varargout = process_pac( varargin )
% PROCESS_PAC: Compute the Phase-Amplitude Coupling in one of several time series (directPAC)
%
% DOCUMENTATION:  For more information, please refer to the method described in the following article
%    Özkurt TE, Schnitzler A, J Neurosci Methods. 2011 Oct 15;201(2):438-43
%    "A critical note on the definition of phase-amplitude cross-frequency coupling"

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
% Authors: Esther Florin, Sylvain Baillet, 2010-2012
%          Francois Tadel, 2013

macro_methodcall;
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Phase-amplitude coupling';
    sProcess.FileTag     = '';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Frequency';
    sProcess.Index       = 660;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'raw',      'data',     'results',  'matrix'};
    sProcess.OutputTypes = {'timefreq', 'timefreq', 'timefreq', 'timefreq'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;

    % === TIME WINDOW
    sProcess.options.timewindow.Comment = 'Time window:';
    sProcess.options.timewindow.Type    = 'timewindow';
    sProcess.options.timewindow.Value   = [];
    % === NESTING FREQ
    sProcess.options.nesting.Comment = 'Nesting frequency band (low):';
    sProcess.options.nesting.Type    = 'range';
    sProcess.options.nesting.Value   = {[2, 30], 'Hz', 2};
    % === NESTED FREQ
    sProcess.options.nested.Comment = 'Nested frequency band (high):';
    sProcess.options.nested.Type    = 'range';
    sProcess.options.nested.Value   = {[40, 150], 'Hz', 2};
    % === SENSOR SELECTION
    sProcess.options.target_data.Comment    = 'Sensor types or names (empty=all): ';
    sProcess.options.target_data.Type       = 'text';
    sProcess.options.target_data.Value      = 'MEG, EEG';
    sProcess.options.target_data.InputTypes = {'data', 'raw'};
    % === SOURCE INDICES
    sProcess.options.target_res.Comment    = 'Source indices (empty=all): ';
    sProcess.options.target_res.Type       = 'text';
    sProcess.options.target_res.Value      = '';
    sProcess.options.target_res.InputTypes = {'results'};
    % === ROW NAMES
    sProcess.options.target_tf.Comment    = 'Row names or indices (empty=all): ';
    sProcess.options.target_tf.Type       = 'text';
    sProcess.options.target_tf.Value      = '';
    sProcess.options.target_tf.InputTypes = {'timefreq', 'matrix'};

    % === LOOP METHOD
    sProcess.options.label1.Comment = '<HTML><BR>Processing options [expert only]:';
    sProcess.options.label1.Type    = 'label';
    % === Parallel processing
    sProcess.options.parallel.Comment = 'Use the parallel processing toolbox';
    sProcess.options.parallel.Type    = 'checkbox';
    sProcess.options.parallel.Value   = (exist('matlabpool', 'file') ~= 0);
    if ~exist('matlabpool', 'file')
        sProcess.options.parallel.Hidden = 1;
    end
    % === USE MEX
    sProcess.options.ismex.Comment = 'Use compiled mex-files';
    sProcess.options.ismex.Type    = 'checkbox';
    sProcess.options.ismex.Value   = 0;
    % === MAX_BLOCK_SIZE
    sProcess.options.max_block_size.Comment = 'Number of signals to process at once: ';
    sProcess.options.max_block_size.Type    = 'value';
    sProcess.options.max_block_size.Value   = {1, ' ', 0};

    % sProcess.options.filter_sensor.InputTypes = {'results'};
    % === AVERAGE OUTPUT FILES
    sProcess.options.label2.Comment = '<HTML><BR>Output options:';
    sProcess.options.label2.Type    = 'label';
    sProcess.options.avgoutput.Comment = 'Save average PAC across trials';
    sProcess.options.avgoutput.Type    = 'checkbox';
    sProcess.options.avgoutput.Value   = 1;
    % === SAVE PAC MAPS
    sProcess.options.savefull.Comment = 'Save the full PAC maps';
    sProcess.options.savefull.Type    = 'checkbox';
    sProcess.options.savefull.Value   = 0;
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputsA) %#ok<DEFNU>
    % Get options
    if isfield(sProcess.options, 'timewindow') && isfield(sProcess.options.timewindow, 'Value') && iscell(sProcess.options.timewindow.Value) && ~isempty(sProcess.options.timewindow.Value)
        OPTIONS.TimeWindow = sProcess.options.timewindow.Value{1};
    else
        OPTIONS.TimeWindow = [];
    end
    OPTIONS.BandNesting = sProcess.options.nesting.Value{1};
    OPTIONS.BandNested  = sProcess.options.nested.Value{1};
    % Get target
    if ismember(sInputsA(1).FileType, {'data','raw'}) && isfield(sProcess.options, 'target_data') && ~isempty(sProcess.options.target_data.Value)
        OPTIONS.Target = sProcess.options.target_data.Value;
    elseif strcmpi(sInputsA(1).FileType, 'results') && isfield(sProcess.options, 'target_res') && ~isempty(sProcess.options.target_res.Value)
        OPTIONS.Target = sProcess.options.target_res.Value;
    elseif ismember(sInputsA(1).FileType, {'timefreq', 'matrix'}) && isfield(sProcess.options, 'target_tf') && ~isempty(sProcess.options.target_tf.Value)
        OPTIONS.Target = sProcess.options.target_tf.Value;
    else
        OPTIONS.Target = [];
    end
    % All other options
    OPTIONS.MaxSignals   = sProcess.options.max_block_size.Value{1};
    OPTIONS.isParallel   = sProcess.options.parallel.Value && (exist('matlabpool', 'file') ~= 0);
    OPTIONS.isMex        = sProcess.options.ismex.Value;
    OPTIONS.isFullMaps   = sProcess.options.savefull.Value;
    OPTIONS.isAvgOutput  = sProcess.options.avgoutput.Value;
    if (length(sInputsA) == 1)
        OPTIONS.isAvgOutput = 0;
    end

    % ===== INITIALIZE =====
    % Initialize output variables
    OutputFiles = {};
    sPAC_avg = [];
    nAvg = 0;
    % Initialize progress bar
    if bst_progress('isVisible')
        startValue = bst_progress('get');
    else
        startValue = 0;
    end
    % Options for LoadInputFile()
    if strcmpi(sInputsA(1).FileType, 'results')
        LoadOptions.LoadFull = 0;  % Load kernel-based results as kernel+data
    else
        LoadOptions.LoadFull = 1;  % Load the full file
    end
    LoadOptions.IgnoreBad   = 1;  % From raw files: ignore the bad segments
    LoadOptions.ProcessName = func2str(sProcess.Function);
    
    % Loop over input files
    for iFile = 1:length(sInputsA)
        % ===== LOAD SIGNALS =====
        bst_progress('text', sprintf('PAC: Loading input file (%d/%d)...', iFile, length(sInputsA)));
        bst_progress('set', round(startValue + (iFile-1) / length(sInputsA) * 100));
        % Load input signals 
        [sInput, nSignals, iRows] = bst_process('LoadInputFile', sInputsA(iFile).FileName, OPTIONS.Target, OPTIONS.TimeWindow, LoadOptions);
        if isempty(sInput) || isempty(sInput.Data)
            return;
        end
        % Get sampling frequency
        sRate = 1 / (sInput.Time(2) - sInput.Time(1));
        % Check the nested frequencies
        if (OPTIONS.BandNested(2) > sRate/3)
            % Warning
            strMsg = sprintf('Higher nesting frequency is too high (%d Hz) compared with sampling frequency (%d Hz): Limiting to %d Hz', round(OPTIONS.BandNested(2)), round(sRate), round(sRate/3));
            disp([10 'process_pac> ' strMsg]);
            bst_report('Warning', 'process_pac', [], strMsg);
            % Fix higher frequencyy
            OPTIONS.BandNested(2) = sRate/3;
        end
        % Check the extent of bandNested band
        if (OPTIONS.BandNested(2) <= OPTIONS.BandNested(1))
            bst_report('Error', 'process_pac', [], sprintf('Invalid frequency range: %d-%d Hz', round(OPTIONS.BandNested(1)), round(OPTIONS.BandNested(2))));
            continue;
        end

        % ===== COMPUTE PAC MEASURE =====
        % Number of blocks of signals
        MAX_BLOCK_SIZE = OPTIONS.MaxSignals;
        nBlocks = ceil(nSignals / MAX_BLOCK_SIZE);
        sPAC = [];
        % Display processing time
        disp(sprintf('Processing %d blocks of %d signals each.', nBlocks, MAX_BLOCK_SIZE));
        % Process each block of signals
        for iBlock = 1:nBlocks
            tic
            bst_progress('text', sprintf('PAC: File %d/%d - Block %d/%d', iFile, length(sInputsA), iBlock, nBlocks));
            bst_progress('set', round(startValue + (iFile-1)/length(sInputsA)*100 + iBlock/nBlocks*100));    
            % Indices of the signals
            iSignals = (iBlock-1)*MAX_BLOCK_SIZE+1 : min(iBlock*MAX_BLOCK_SIZE, nSignals);
            % Get signals to process
            if ~isempty(sInput.ImagingKernel)
                Fblock = sInput.ImagingKernel(iSignals,:) * sInput.Data;
            else
                Fblock = sInput.Data(iSignals,:);
            end
            sPACblock = bst_pac(Fblock, sRate, OPTIONS.BandNesting, OPTIONS.BandNested, OPTIONS.isFullMaps, OPTIONS.isParallel, OPTIONS.isMex);
            % Initialize output structure
            if isempty(sPAC)
                sPAC.ValPAC      = zeros(nSignals,1);
                sPAC.NestingFreq = zeros(nSignals,1);
                sPAC.NestedFreq  = zeros(nSignals,1);
                sPAC.PhasePAC    = zeros(nSignals,1);
                if OPTIONS.isFullMaps
                    sPAC.DirectPAC = zeros(nSignals, 1, size(sPACblock.DirectPAC,3), size(sPACblock.DirectPAC,4));
                else
                    sPAC.DirectPAC = [];
                end
                sPAC.LowFreqs  = sPACblock.LowFreqs;
                sPAC.HighFreqs = sPACblock.HighFreqs;
            end
            % Copy block results to output structure
            sPAC.ValPAC(iSignals)      = sPACblock.ValPAC;
            sPAC.NestingFreq(iSignals) = sPACblock.NestingFreq;
            sPAC.NestedFreq(iSignals)  = sPACblock.NestedFreq;
            sPAC.PhasePAC(iSignals)    = sPACblock.PhasePAC;
            if OPTIONS.isFullMaps
                sPAC.DirectPAC(iSignals,:,:,:) = sPACblock.DirectPAC;
            end
            % Display processing time
            % disp(sprintf('Block #%d/%d: %fs', iBlock, nBlocks, toc));
        end
                
        % ===== APPLY SOURCE ORIENTATION =====
        if strcmpi(sInput.DataType, 'results') && (sInput.nComponents > 1)
            % Number of values per vertex
            switch (sInput.nComponents)
                case 2
                    sPAC.ValPAC      = (sPAC.ValPAC(1:2:end,:,:)      + sPAC.ValPAC(2:2:end,:,:)) / 2;
                    sPAC.NestingFreq = (sPAC.NestingFreq(1:2:end,:,:) + sPAC.NestingFreq(2:2:end,:,:)) / 2;
                    sPAC.NestedFreq  = (sPAC.NestedFreq(1:2:end,:,:)  + sPAC.NestedFreq(2:2:end,:,:)) / 2;
                    sPAC.PhasePAC    = (sPAC.PhasePAC(1:2:end,:,:)    + sPAC.PhasePAC(2:2:end,:,:)) / 2;
                    sPAC.DirectPAC   = (sPAC.DirectPAC(1:2:end,:,:,:) + sPAC.DirectPAC(2:2:end,:,:,:)) / 2;
                    sInput.RowNames = sInput.RowNames(1:2:end);
                case 3
                    sPAC.ValPAC      = (sPAC.ValPAC(1:3:end,:,:)      + sPAC.ValPAC(2:3:end,:,:)      + sPAC.ValPAC(3:3:end,:,:)) / 3;
                    sPAC.NestingFreq = (sPAC.NestingFreq(1:3:end,:,:) + sPAC.NestingFreq(2:3:end,:,:) + sPAC.NestingFreq(3:3:end,:,:)) / 3;
                    sPAC.NestedFreq  = (sPAC.NestedFreq(1:3:end,:,:)  + sPAC.NestedFreq(2:3:end,:,:)  + sPAC.NestedFreq(3:3:end,:,:)) / 3;
                    sPAC.PhasePAC    = (sPAC.PhasePAC(1:3:end,:,:)    + sPAC.PhasePAC(2:3:end,:,:)    + sPAC.PhasePAC(3:3:end,:,:)) / 3;
                    sPAC.DirectPAC   = (sPAC.DirectPAC(1:3:end,:,:,:) + sPAC.DirectPAC(2:3:end,:,:,:) + sPAC.DirectPAC(3:3:end,:,:,:)) / 3;
                    sInput.RowNames = sInput.RowNames(1:3:end);
            end
        end

        % ===== SAVE FILE =====
        % Detect incomplete lists of sources
        isIncompleteResult = strcmpi(sInput.DataType, 'results') && (length(sInput.RowNames) * sInput.nComponents < nSignals);
        % Comment
        Comment = 'MaxPAC';
        if (length(sInput.RowNames) == 1)
            if iscell(sInput.RowNames)
                Comment = [Comment, ': ' sInput.RowNames{1}];
            else
                Comment = [Comment, ': #', num2str(sInput.RowNames(1))];
            end
        elseif isIncompleteResult
            Comment = [Comment, ': ', num2str(length(sInput.RowNames)), ' sources'];
        end
        if OPTIONS.isFullMaps
            Comment = [Comment, ' (Full)'];
        end
        % Output data type: if there are not all the sources, switch the datatype to "scout"
        if isIncompleteResult
            sInput.DataType = 'scout';
            % Convert source indices to strings
            if ~iscell(sInput.RowNames)
                sInput.RowNames = cellfun(@num2str, num2cell(sInput.RowNames), 'UniformOutput', 0);
            end
        end
        % Save each as an independent file
        if ~OPTIONS.isAvgOutput
            nAvg = 1;
            OutputFiles{end+1} = SaveFile(sPAC, sInput.iStudy, sInputsA(iFile).FileName, sInput, Comment, nAvg, OPTIONS);
        else
            % Compute online average of the connectivity matrices
            if isempty(sPAC_avg)
                sPAC_avg.ValPAC      = sPAC.ValPAC      ./ length(sInputsA);
                sPAC_avg.NestingFreq = sPAC.NestingFreq ./ length(sInputsA);
                sPAC_avg.NestedFreq  = sPAC.NestedFreq  ./ length(sInputsA);
                sPAC_avg.PhasePAC    = sPAC.PhasePAC    ./ length(sInputsA);
                sPAC_avg.DirectPAC   = sPAC.DirectPAC   ./ length(sInputsA);
                sPAC_avg.LowFreqs    = sPAC.LowFreqs;
                sPAC_avg.HighFreqs   = sPAC.HighFreqs;
            else
                sPAC_avg.ValPAC      = sPAC_avg.ValPAC      + sPAC.ValPAC      ./ length(sInputsA);
                sPAC_avg.NestingFreq = sPAC_avg.NestingFreq + sPAC.NestingFreq ./ length(sInputsA);
                sPAC_avg.NestedFreq  = sPAC_avg.NestedFreq  + sPAC.NestedFreq  ./ length(sInputsA);
                sPAC_avg.PhasePAC    = sPAC_avg.PhasePAC    + sPAC.PhasePAC    ./ length(sInputsA);
                sPAC_avg.DirectPAC   = sPAC_avg.DirectPAC   + sPAC.DirectPAC   ./ length(sInputsA);
            end
            nAvg = nAvg + 1;
        end
    end

    % ===== SAVE AVERAGE =====
    if OPTIONS.isAvgOutput
        % Output study, in case of average
        [tmp, iOutputStudy] = bst_process('GetOutputStudy', sProcess, sInputsA);
        % Save file
        OutputFiles{1} = SaveFile(sPAC_avg, iOutputStudy, [], sInput, Comment, nAvg, OPTIONS);
    end
end


%% ========================================================================
%  ===== SUPPORT FUNCTIONS ================================================
%  ========================================================================

%% ===== SAVE FILE =====
function NewFile = SaveFile(sPAC, iOuptutStudy, DataFile, sInput, Comment, nAvg, OPTIONS)
    % ===== PREPARE OUTPUT STRUCTURE =====
    % Create file structure
    FileMat = db_template('timefreqmat');
    FileMat.TF        = sPAC.ValPAC;
    FileMat.Comment   = Comment;
    FileMat.Method    = 'pac';
    FileMat.Measure   = 'maxpac';
    FileMat.DataFile  = file_win2unix(DataFile);
    FileMat.nAvg      = nAvg;
    FileMat.Freqs     = 0;
    % All the PAC fields
    FileMat.sPAC = rmfield(sPAC, 'ValPAC');
    % Time vector
    FileMat.Time = sInput.Time([1,end]);
    % Output data type and Row names
    if strcmpi(sInput.DataType, 'results') && ~isempty(OPTIONS.Target) && ~isempty(strtrim(OPTIONS.Target))
        FileMat.DataType = 'matrix';
        if isnumeric(sInput.RowNames)
        	FileMat.RowNames = cellfun(@num2str, num2cell(sInput.RowNames), 'UniformOutput', 0);
        else
            FileMat.RowNames = sInput.RowNames;
        end
    else
        FileMat.DataType = sInput.DataType;
        FileMat.RowNames = sInput.RowNames;
    end
    % Atlas 
    if ~isempty(sInput.Atlas)
        FileMat.Atlas = sInput.Atlas;
    end
    if ~isempty(sInput.SurfaceFile)
        FileMat.SurfaceFile = sInput.SurfaceFile;
    end
    % History: Computation
    FileMat = bst_history('add', FileMat, 'compute', 'PAC measure (see the field "Options" for input parameters)');
    % Save options in the file
    FileMat.Options = OPTIONS;
    
    % ===== SAVE FILE =====
    % Get output study
    sOutputStudy = bst_get('Study', iOuptutStudy);
    % File tag
    if OPTIONS.isFullMaps
        fileTag = 'timefreq_pac_fullmaps';
    else
        fileTag = 'timefreq_pac';
    end
    % Output filename
    NewFile = bst_process('GetNewFilename', bst_fileparts(sOutputStudy.FileName), fileTag);
    % Save file
    bst_save(NewFile, FileMat, 'v6');
    % Add file to database structure
    db_add_data(iOuptutStudy, NewFile, FileMat);
end




