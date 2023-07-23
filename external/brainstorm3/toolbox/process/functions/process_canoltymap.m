function varargout = process_canoltymap( varargin )
% This function generates Canolty like maps (Science 2006, figure 1) for the input signal. 

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
% Authors: Esther Florin, Sylvain Baillet, 2011-2013
%          Francois Tadel, 2013-2014

macro_methodcall;
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Canolty maps';
    sProcess.FileTag     = '| canolty';
    sProcess.Category    = 'File';
    sProcess.SubGroup    = 'Frequency';
    sProcess.Index       = 661;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'raw',      'data',     'results',  'matrix'};
    sProcess.OutputTypes = {'timefreq', 'timefreq', 'timefreq', 'timefreq'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;

    % === TIME WINDOW
    sProcess.options.timewindow.Comment = 'Time window: ';
    sProcess.options.timewindow.Type    = 'timewindow';
    sProcess.options.timewindow.Value   = [];
    % === EPOCH TIME
    sProcess.options.epochtime.Comment = 'Epoch time: ';
    sProcess.options.epochtime.Type    = 'range';
    sProcess.options.epochtime.Value   = {[-1, 1], 'ms', []};
    % === NESTING FREQ
    sProcess.options.lowfreq.Comment = 'Nesting frequency (low): ';
    sProcess.options.lowfreq.Type    = 'value';
    sProcess.options.lowfreq.Value   = {4, 'Hz', 2};
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
    % === MAX_BLOCK_SIZE
    sProcess.options.max_block_size.Comment = 'Number of signals to process at once: ';
    sProcess.options.max_block_size.Type    = 'value';
    sProcess.options.max_block_size.Value   = {100, ' ', 0};
    % === SAVE AVERAGED LOW-FREQ SIGNALS
    sProcess.options.save_erp.Comment = 'Save averaged low frequency signals';
    sProcess.options.save_erp.Type    = 'checkbox';
    sProcess.options.save_erp.Value   = 1;
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFile = Run(sProcess, sInput) %#ok<DEFNU>
    % Get options
    OPTIONS.TimeWindow = sProcess.options.timewindow.Value{1};
    OPTIONS.EpochTime  = sProcess.options.epochtime.Value{1};
    OPTIONS.LowFreq    = sProcess.options.lowfreq.Value{1};
    OPTIONS.MaxSignals = sProcess.options.max_block_size.Value{1};
    OPTIONS.SaveErp    = sProcess.options.save_erp.Value;
    % Get target
    if ismember(sInput.FileType, {'data','raw'}) && isfield(sProcess.options, 'target_data') && ~isempty(sProcess.options.target_data.Value)
        OPTIONS.Target = sProcess.options.target_data.Value;
    elseif strcmpi(sInput.FileType, 'results') && isfield(sProcess.options, 'target_res') && ~isempty(sProcess.options.target_res.Value)
        OPTIONS.Target = sProcess.options.target_res.Value;
    elseif ismember(sInput.FileType, {'timefreq', 'matrix'}) && isfield(sProcess.options, 'target_tf') && ~isempty(sProcess.options.target_tf.Value)
        OPTIONS.Target = sProcess.options.target_tf.Value;
    else
        OPTIONS.Target = [];
    end
    OutputFile = {};
    
    % === READ INPUT DATA ===
    % Options for LoadInputFile()
    LoadOptions.LoadFull    = 0;  % Load kernel-based results as kernel+data
    LoadOptions.IgnoreBad   = 1;  % From raw files: ignore the bad segments
    LoadOptions.ProcessName = func2str(sProcess.Function);
    % Load input signals 
    [sMat, nSignals, iRows] = bst_process('LoadInputFile', sInput.FileName, OPTIONS.Target, OPTIONS.TimeWindow, LoadOptions);
    if isempty(sMat.Data)
        return;
    end    
    % Get sampling frequency
    sRate = 1 / (sMat.Time(2) - sMat.Time(1));
    % Replicate low frequency if only one was provided for all the signals
    if (length(OPTIONS.LowFreq) == 1) && (nSignals > 1)
        OPTIONS.LowFreq = repmat(OPTIONS.LowFreq, nSignals, 1);
    % Select only a subset of the low frequencies
    elseif ~isempty(OPTIONS.Target) && ~isempty(iRows) && (length(OPTIONS.LowFreq) ~= length(iRows)) && (max(iRows) < length(OPTIONS.LowFreq))
        OPTIONS.LowFreq = OPTIONS.LowFreq(iRows);
    % Check for compatible size of LowFreq array
    elseif (length(OPTIONS.LowFreq) ~= nSignals)
        bst_report('Error', sProcess, sInput, sprintf('The size of the low-frequency array (%d) does not match the number of signals to process (%d).', length(OPTIONS.LowFreq), nSignals));
        return;
    end
    
    % ===== CALCULATE CANOLTY MAPS =====
    % Number of blocks of signals
    MAX_BLOCK_SIZE = OPTIONS.MaxSignals;
    nBlocks = ceil(nSignals / MAX_BLOCK_SIZE);
    TF  = [];
    ERP = [];
    % Process each block of signals
    for iBlock = 1:nBlocks
        bst_progress('inc', round(iBlock/nBlocks*100));    
        % Indices of the signals
        iSignals = (iBlock-1)*MAX_BLOCK_SIZE+1 : min(iBlock*MAX_BLOCK_SIZE, nSignals);
        % Get signals to process
        if ~isempty(sMat.ImagingKernel)
            Fblock = sMat.ImagingKernel(iSignals,:) * sMat.Data;
        else
            Fblock = sMat.Data(iSignals,:);
        end
        % Calculate canolty map signal
        [TFblock, ERPblock, TimeVectorOut, Freqs, errMsg] = Compute(Fblock, sRate, OPTIONS.LowFreq(iSignals), OPTIONS.EpochTime);
        if ~isempty(errMsg)
            bst_report('Error', sProcess, sInput, errMsg);
            return;
        end
        % Initialize output variable
        if isempty(TF)
            TF  = zeros(nSignals, size(TFblock,2), size(TFblock,3));
            ERP = zeros(nSignals, size(TFblock,2));
        end
        % Copy block results to output variable
        TF(iSignals,:,:)  = TFblock;
        ERP(iSignals,:,:) = ERPblock;
    end
    
    % ===== SAVE TF FILE =====
    % Get the study filename
    sStudy = bst_get('Study', sInput.iStudy);
    % Convert row indices to row names
    if iscell(sMat.RowNames)
        Description = sMat.RowNames;
    else
        Description = {};
        for iRow = 1:length(sMat.RowNames)
            Description{iRow} = num2str(sMat.RowNames(iRow));
        end
    end
    % Create new output structure
    sOutput = db_template('timefreqmat');
    sOutput.TF          = TF;
    sOutput.CanoltyERP  = ERP;
    sOutput.Comment     = 'Canolty maps';
    sOutput.DataType    = sInput.FileType;
    sOutput.Time        = TimeVectorOut;
    sOutput.Freqs       = round(Freqs .* 100) / 100;
    sOutput.Measure     = 'other';
    sOutput.Method      = 'canolty';
    sOutput.DataFile    = sInput.FileName;
    sOutput.SurfaceFile = sMat.SurfaceFile;
    sOutput.Atlas       = [];
    sOutput.Options     = OPTIONS;
    % Row names for full sources of subsets
    if isempty(OPTIONS.Target)
        sOutput.RowNames = sMat.RowNames;
    else
        sOutput.RowNames = Description;
    end
    % Output filename
    OutputFile = bst_process('GetNewFilename', bst_fileparts(sStudy.FileName), 'timefreq_canolty');
    % Save file
    bst_save(OutputFile, sOutput, 'v6');
    % Add file to database structure
    db_add_data(sInput.iStudy, OutputFile, sOutput);
    
    % ===== SAVE MATRIX FILE =====
    if OPTIONS.SaveErp
        % Create new output structure
        sOutput = db_template('matrixmat');
        sOutput.Value       = ERP;
        sOutput.Comment     = [sMat.Comment ' | Canolty ERP'];
        sOutput.Time        = TimeVectorOut;
        sOutput.Description = Description;
        sOutput.Options     = OPTIONS;
        % Output filename
        OutputFileERP = bst_process('GetNewFilename', bst_fileparts(sStudy.FileName), 'matrix_canolty');
        % Save file
        bst_save(OutputFileERP, sOutput, 'v6');
        % Add file to database structure
        db_add_data(sInput.iStudy, OutputFileERP, sOutput);
    end
end

    
    
%% ===== COMPUTE CANOLTY MAPS =====
function [TF, ERP, TimeOut, chirp_center_high, errMsg] = Compute( F, sRate, lowfreq, EpochTime)
    nTime = size(F,2);
    errMsg = '';
    
    % ===== CREATE CHIRPLETS =====
    % Definitions
    fmin = 1;
    fmax = 250;
    numfreqs = 70;
    fstep = 0.75;
    % Calculate center frequencies
    temp1 = (0:numfreqs-1) * fstep;
    temp2 = logspace(log10(fmin), log10(fmax), numfreqs);
    temp2 = (temp2-temp2(1)) * ((temp2(end)-temp1(end)) / temp2(end)) + temp2(1);
    chirp_center_high = temp1 + temp2;
    % Calculate chirplets
    [chirpF_high, Freqs] = bst_chirplet(sRate, nTime, chirp_center_high);

    % ===== INITIALIZE RETURNED VARIABLES =====
    % Generate epoch indices
    iEpochTime = round(EpochTime(1)*sRate):round(EpochTime(2)*sRate);
    if isempty(iEpochTime)
        errMsg = 'Invalid epoch time';
    end
    % Output time vector
    TimeOut = iEpochTime / sRate;
    % Initialize returned variable
    TF  = zeros(size(F,1), length(TimeOut), length(chirp_center_high));
    ERP = zeros(size(F,1), length(TimeOut));

    % ===== FFT OF SIGNALS =====
    % Transform sensor time series into analytic signals
    F_fft = fft(F, length(Freqs), 2);
    % This step scales analytic signal such that: real(analytic_signal) = raw_signal
    % but note that analytic signal energy is double that of raw signal energy
    F_fft(:,Freqs<0) = 0;
    F_fft(:,Freqs>0) = 2 * F_fft(:,Freqs>0);

    % ===== LOOP ON SIGNALS =====
    for iSource = 1:size(F,1)
        % === DETECT MIN/MAX LOW FREQ ===
        % Calculate one chirplet for the low frequency
        [chirpF_low, Freqs] = bst_chirplet(sRate, nTime, lowfreq(iSource));
        % Filter again: Positive version of the signal
        fs_low = bst_freqfilter(F(iSource,:), chirpF_low, Freqs);
        % Detection of phase maxima of theta filtered signal (POSITIVE)
        [tmp, iMaxTheta] = find_maxima(angle(fs_low));

        % === FILTER GAMMA ===
        % Filter source signal using all the low-frequency chirplet
        fs_high = bst_freqfilter(F(iSource,:), chirpF_high, Freqs, F_fft(iSource,:));
        % Magnitude
        fs_high = abs(fs_high);
        % Zscore normalization
        fs_high = process_zscore('Compute', fs_high, 1:size(fs_high,2));

        % === EPOCH ===
        % Makes sure all triggers allow full epoch
        iMaxTheta(iMaxTheta <= abs(iEpochTime(1))) = [];
        iMaxTheta(iMaxTheta >= nTime - iEpochTime(end)) = [];
        % Loop on every peak of theta
        for i = 1:length(iMaxTheta)
            % Find epoch indices
            iTime = iMaxTheta(i) + iEpochTime;
            % Phase-triggered ERP of raw signal
            ERP(iSource,:) = ERP(iSource,:) + F(iSource, iTime) ./ length(iMaxTheta);
            % Phase-triggered time-frequency amplitude values (normalized)
            TF(iSource,:,:) = TF(iSource,:,:) + fs_high(1,iTime,:) ./ length(iMaxTheta);
        end
    end
end





