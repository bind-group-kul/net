function OutputFiles = bst_connectivity(FilesA, FilesB, OPTIONS)
% BST_CONNECTIVITY: Computes a connectivity metric between two files A and B
%
% USAGE:  OutputFiles = bst_connectivity(FilesA, FilesB, OPTIONS)
%             OPTIONS = bst_connectivity()

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
% Authors: Francois Tadel, 2012-2013


%% ===== DEFAULT OPTIONS =====
Def_OPTIONS.Method        = 'corr';
Def_OPTIONS.ProcessName   = '';
Def_OPTIONS.TargetA       = [];
Def_OPTIONS.TargetB       = [];
Def_OPTIONS.Freqs         = 0;
Def_OPTIONS.TimeWindow    = [];
Def_OPTIONS.pThreshold    = 1;
Def_OPTIONS.RemoveMean    = 1;     % Option for Correlation
Def_OPTIONS.CohMaxFreqRes = [];    % Option for Coherence
Def_OPTIONS.CohMethod     = 'mni'; % Option for Coherence
Def_OPTIONS.CohWinLength  = [];    % Option for Coherence
Def_OPTIONS.GrangerOrder  = 10;    % Option for Granger causality
Def_OPTIONS.GrangerDir    = 'out'; % Option for Granger causality
Def_OPTIONS.RemoveEvoked  = 0;     % Removed evoked response to each single trial (useful for Granger)
Def_OPTIONS.isMirror      = 1;     % Option for PLV
Def_OPTIONS.isSymmetric   = [];      % Optimize processing and storage for simple matrices
Def_OPTIONS.OutputMode    = 'input'; % {'avg','input','concat'}
Def_OPTIONS.iOutputStudy  = [];
% Return the default options
if (nargin == 0)
    OutputFiles = Def_OPTIONS;
    return
end


%% ===== INITIALIZATIONS =====
% Parse inputs
if ischar(FilesA)
    FilesA = {FilesA};
end
if ischar(FilesB) && ~isempty(FilesB)
    FilesB = {FilesB};
end
% Copy default options to OPTIONS structure (do not replace defined values)
OPTIONS = struct_copy_fields(OPTIONS, Def_OPTIONS, 0);
% Initialize output variables
OutputFiles = {};
Ravg = [];
nAvg = 0;
nTime = 1;
% Initialize progress bar
if bst_progress('isVisible')
    startValue = bst_progress('get');
else
    startValue = 0;
end
% If only one file: process as only one file
if (length(FilesA) == 1)
    OPTIONS.OutputMode = 'input';
end
% Frequency bands
if iscell(OPTIONS.Freqs)
    FreqBands = OPTIONS.Freqs;
else
    FreqBands = [];
end
% Symmetric storage?
if isempty(OPTIONS.isSymmetric)
    OPTIONS.isSymmetric = any(strcmpi(OPTIONS.Method, {'corr','cohere','plv','plvt'})) && (isempty(FilesB) || (isequal(FilesA, FilesB) && isequal(OPTIONS.TargetA, OPTIONS.TargetB)));
end
% Processing [1xN] or [NxN]
isConnNN = isempty(FilesB);
% Options for LoadInputFile()
LoadOptions.LoadFull    = ~isempty(OPTIONS.TargetA) || ~isempty(OPTIONS.TargetB) || ~ismember(OPTIONS.Method, {'cohere'});  % Load kernel-based results as kernel+data for coherence ONLY
LoadOptions.IgnoreBad   = 0;  % From data files: KEEP the bad channels
LoadOptions.ProcessName = OPTIONS.ProcessName;


%% ===== CONCATENATE INPUTS =====
% Load all the data and concatenate it
if strcmpi(OPTIONS.OutputMode, 'concat')
    bst_progress('text', 'Loading input files...');
    % Concatenate FileA
    sInputA = LoadConcat(FilesA, OPTIONS.TargetA, OPTIONS.TimeWindow, LoadOptions, startValue);
    FilesA = FilesA(1);
    % Concatenate FileB
    if ~isConnNN
        sInputB = LoadConcat(FilesB, OPTIONS.TargetB, OPTIONS.TimeWindow, LoadOptions, startValue);
        FilesB = FilesB(1);
        % Some quality check
        if (size(sInputA.Data,2) ~= size(sInputB.Data,2))
            bst_report('Error', OPTIONS.ProcessName, {FilesA{:}, FilesB{:}}, 'Files A and B must have the same number of time samples.');
            return;
        end
    else
        sInputB = sInputA;
    end
end
if isConnNN
    FilesB = FilesA;
end 

% % Granger and trial-based analysis
% if OPTIONS.RemoveEvoked
%     for iFile = 1:length(FilesA)
%         sInputA = LoadConcat(FilesA, OPTIONS.TargetA, OPTIONS.TimeWindow, LoadOptions, startValue);
%     end
% end


%% ===== CALCULATE CONNECTIVITY =====
% Loop over input files
for iFile = 1:length(FilesA)
    bst_progress('set',  round(startValue + (iFile-1) / length(FilesA) * 100));
    %% ===== LOAD SIGNALS =====
    if ~strcmpi(OPTIONS.OutputMode, 'concat')
        bst_progress('text', 'Loading input files...');
        % Load reference signal
        sInputA = bst_process('LoadInputFile', FilesA{iFile}, OPTIONS.TargetA, OPTIONS.TimeWindow, LoadOptions);
        if isempty(sInputA.Data)
            return;
        end
        % Averaging: check for similar dimension in time
        if strcmpi(OPTIONS.OutputMode, 'avg')
            if (iFile == 1)
                nTimeA = size(sInputA.Data,2);
            elseif (size(sInputA.Data,2) ~= nTimeA)
                bst_report('Error', OPTIONS.ProcessName, FilesA{iFile}, 'Invalid time selection, probably due to different time vectors in the input files.');
                return;
            end
        end
        % If a target signal was defined
        if ~isConnNN
            % Load target signal
            sInputB = bst_process('LoadInputFile', FilesB{iFile}, OPTIONS.TargetB, OPTIONS.TimeWindow, LoadOptions);
            if isempty(sInputB.Data)
                return;
            end
            % Some quality check
            if (size(sInputA.Data,2) ~= size(sInputB.Data,2))
                bst_report('Error', OPTIONS.ProcessName, {FilesA{iFile}, FilesB{iFile}}, 'Files A and B must have the same number of time samples.');
                return;
            end
        % Else: Use the same info as FileA
        else
            sInputB = sInputA;
        end
    end
    nSamples = size(sInputB.Data,2);

    %% ===== COMPUTE CONNECTIVITY METRIC =====
    switch (OPTIONS.Method)
        % === CORRELATION ===
        case 'corr'
            bst_progress('text', sprintf('Calculating: Correlation [%dx%d]...', size(sInputA.Data,1), size(sInputB.Data,1)));
            Comment = 'Corr: ';
            % All the correlations with one call
            R = bst_corrn(sInputA.Data, sInputB.Data, OPTIONS.RemoveMean); 
           
%             % Use t-test and standard Gaussian
%             tmp = abs(R(R < 1-eps)) ./ sqrt(1 - R(R < 1-eps).^2) * sqrt(nSamples - 2);
%             pValues(R < 1-eps) = 1 - (1/2 * erfc(-1 * tmp / sqrt(2)));   % 1-normcdf

        % === COHERENCE ===
        case 'cohere'
            bst_progress('text', sprintf('Calculating: Coherence [%dx%d]...', size(sInputA.Data,1), size(sInputB.Data,1)));
            % Check time window length
            if (size(sInputA.Data,2) < 2 * OPTIONS.CohWinLength)
                bst_report('Error', OPTIONS.ProcessName, {FilesA{iFile}, FilesB{iFile}}, sprintf('Selected time window is too short (%d time samples).', size(sInputA.Data,2)));
                return;
            end
            % Get the sampling frequency
            sfreq = 1 ./ (sInputA.Time(2) - sInputA.Time(1));
            % Calculation options
            switch lower(OPTIONS.CohMethod)
                % ===== MNI: BST_COHN =====
                case 'mni'
                    Comment = 'Coh: ';
                    % Estimate the coherence
                    [R, OPTIONS.Freqs] = bst_cohn(sInputA.Data, sInputB.Data, sfreq, OPTIONS.CohWinLength, OPTIONS.CohMaxFreqRes, OPTIONS.isSymmetric, sInputB.ImagingKernel, 100/length(FilesA));
                    % Get the magnitude of the complex values
                    R = abs(R);
%                     % Kuramaswamy's CDF using using Goodman's formula from [1], simplified by the null hypothesis as in [2]
%                     pValues = (1 - R).^(floor(nSamples / OPTIONS.CohWinLength));
%                     % Set to zero the values that are above the p-value threshold
%                     if ~isempty(OPTIONS.pThreshold)
%                         R(pValues >= OPTIONS.pThreshold) = 0;
%                     end
                    

%                 % ===== USC: BST_COHERENCE =====
%                 case 'usc'
%                     Comment = 'Coh: (USC)';
%                     inputs.Fs   = sfreq;
%                     inputs.freq = [];
%                     inputs.maxfreqres = OPTIONS.CohMaxFreqRes;
%                     [R, OPTIONS.Freqs] = bst_coherence(sInputA.Data, sInputB.Data, inputs);
%                     R = abs(R);

                % ===== MATLAB: MSCOHERE =====
                case 'mscohere'
                    Comment = 'mscohere: ';
                    % Get the number of FFT bins return by mscohere
                    if ~isempty(OPTIONS.CohMaxFreqRes) && (length(sInputA.Time) > round(sfreq / OPTIONS.CohMaxFreqRes))
                        nFFT = 2^nextpow2( round(sfreq / OPTIONS.CohMaxFreqRes) );
                    % Use the default for FFT
                    else
                        nFFT = 2^nextpow2( length(sInputA.Time) );
                    end
                    % Get the default output size of mscohere
                    [C, OPTIONS.Freqs] = mscohere(sInputA.Data(1,:), sInputB.Data(1,:), [], [], nFFT, sfreq);
                    %sizeC = length(C);
                    % Initialize returned value
                    R = zeros(size(sInputA.Data,1), size(sInputB.Data,1), nFFT/2+1);
                    % Compute the coherence for each couple
                    for iA = 1:size(sInputA.Data,1)
                        for iB = 1:size(sInputB.Data,1)
                            % Default options
                            % R(iA,iB,:) = mscohere(sInputA.Data(iA,:), sInputB.Data(iB,:), [], [], [], sfreq);
                            % Options that match the results of the bst_coherence function
                            R(iA,iB,:) = mscohere(sInputA.Data(iA, :), sInputB.Data(iB, :), parzenwin(64), 32, nFFT, sfreq);
                        end
                    end
                    % Cut the last frequency bin
                    OPTIONS.Freqs(end) = [];
                    R(:,:,end) = [];
            end
            
        % ==== GRANGER ====
        case 'granger'
            bst_progress('text', sprintf('Calculating: Granger [%dx%d]...', size(sInputA.Data,1), size(sInputB.Data,1)));
            % Using the connectivity toolbox developed at USC
            inputs.partial     = 0;
            inputs.order       = OPTIONS.GrangerOrder;
            inputs.nTrials     = 1;
            inputs.standardize = true;
            inputs.flagFPE     = true;
            inputs.nSitesX     = [];   % Used only for regionally partial causality (partial < 0)
            inputs.nSitesY     = [];   % Used only for regionally partial causality (partial < 0)
            % If computing a 1xN interaction: selection of the Granger orientation
            if (size(sInputA.Data,1) == 1) && strcmpi(OPTIONS.GrangerDir, 'in')
                [R, OPTIONS.GrangerOrderOut] = bst_granger(sInputA.Data, sInputB.Data, inputs);
                R = R';
            else
                [R, OPTIONS.GrangerOrderOut] = bst_granger(sInputB.Data, sInputA.Data, inputs);
            end
            % Comment
            if (size(sInputA.Data,1) == 1)
                Comment = ['Granger(' OPTIONS.GrangerDir '): '];
            else
                Comment = 'Granger: ';
            end
            
        % ==== PLV ====
        case 'plv'
            bst_progress('text', sprintf('Calculating: PLV [%dx%d]...', size(sInputA.Data,1), size(sInputB.Data,1)));
            Comment = 'PLV: ';
            % Get frequency bands
            nFreqBands = size(OPTIONS.Freqs, 1);
            BandBounds = process_tf_bands('GetBounds', OPTIONS.Freqs);
            
            % ===== IMPLEMENTATION G.DUMAS =====
            % Intitialize returned matrix
            R = zeros(size(sInputA.Data,1), size(sInputB.Data,1), nFreqBands);
            % Loop on each frequency band
            for iBand = 1:nFreqBands
                % Band-pass filter in one frequency band + Apply Hilbert transform
                if isConnNN
                    DataAband = process_bandpass('Compute', sInputA.Data, sInputA.Time, BandBounds(iBand,1), BandBounds(iBand,2), [], OPTIONS.isMirror);
                    HA = hilbert(DataAband')';
                    HB = HA;
                else
                    DataAband = process_bandpass('Compute', sInputA.Data, sInputA.Time, BandBounds(iBand,1), BandBounds(iBand,2), [], OPTIONS.isMirror);
                    DataBband = process_bandpass('Compute', sInputB.Data, sInputB.Time, BandBounds(iBand,1), BandBounds(iBand,2), [], OPTIONS.isMirror);
                    HA = hilbert(DataAband')';
                    HB = hilbert(DataBband')';
                end
                phaseA = HA ./ abs(HA);
                phaseB = HB ./ abs(HB);
                cA = real(phaseA);
                cB = real(phaseB);
                sA = imag(phaseA);
                sB = imag(phaseB);
                % Compute PLV 
                % Divide by number of time samples
                R(:,:,iBand) = (cA*cB' + sA*sB' + 1i * (sA*cB' - cA*sB')) ./ size(cA,2);    
            end
            % We don't want to compute again the frequency bands
            FreqBands = [];
            
        % ==== PLV-TIME ====
        case 'plvt'
            bst_progress('text', sprintf('Calculating: Time-resolved PLV [%dx%d]...', size(sInputA.Data,1), size(sInputB.Data,1)));
            Comment = 'PLVT: ';
            % Get frequency bands
            nFreqBands = size(OPTIONS.Freqs, 1);
            BandBounds = process_tf_bands('GetBounds', OPTIONS.Freqs);
            % Time: vector of file B
            nTime = length(sInputB.Time);
            % Intitialize returned matrix
            nA = size(sInputA.Data,1);
            nB = size(sInputB.Data,1);
            R = zeros(nA * nB, nTime, nFreqBands);
            
            % ===== VERSION S.BAILLET =====
            % PLV = exp(1i * (angle(HA) - angle(HB)));
            % Loop on each frequency band
            for iBand = 1:nFreqBands
                % Band-pass filter in one frequency band + Apply Hilbert transform
                if isConnNN
                    DataAband = process_bandpass('Compute', sInputA.Data, sInputA.Time, BandBounds(iBand,1), BandBounds(iBand,2), [], OPTIONS.isMirror);
                    HA = hilbert(DataAband')';
                    HB = HA;
                else
                    DataAband = process_bandpass('Compute', sInputA.Data, sInputA.Time, BandBounds(iBand,1), BandBounds(iBand,2), [], OPTIONS.isMirror);
                    DataBband = process_bandpass('Compute', sInputB.Data, sInputB.Time, BandBounds(iBand,1), BandBounds(iBand,2), [], OPTIONS.isMirror);
                    HA = hilbert(DataAband')';
                    HB = hilbert(DataBband')';
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%% COULD BE OPTIMIZED EXACTLY LIKE 'PLV' CASE
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Replicate nB x HA, and nA x HB
                iA = repmat(1:nA, 1, nB)';
                iB = reshape(repmat(1:nB, nA, 1), [], 1);
                % Compute the PLV in time for each pair
                R(:,:,iBand) = exp(1i * (angle(HA(iA,:)) - angle(HB(iB,:))));
            end
            % We don't want to compute again the frequency bands
            FreqBands = [];
            
        otherwise
            bst_report('Error', OPTIONS.ProcessName, [], ['Invalid method "' OPTIONS.Method '".']);
            return;
    end

            
    %% ===== SAVE FILE =====
    % Reshape: [A*B x nTime x nFreq]
    R = reshape(R, [], nTime, size(R,3));
    % Comment
    if isequal(FilesA, FilesB)
        if (length(sInputA.RowNames) == 1)
            if iscell(sInputA.RowNames)
                Comment = [Comment, sInputA.RowNames{1}];
            else
                Comment = [Comment, '#', num2str(sInputA.RowNames(1))];
            end
        else
            Comment = [Comment, 'Full'];
        end
    else
        Comment = [Comment, sInputA.Comment];
    end
    % Save each connectivity matrix as an independent file
    switch (OPTIONS.OutputMode)
        case 'input'
            nAvg = 1;
            OutputFiles{end+1} = SaveFile(R, sInputB.iStudy, FilesB{iFile}, sInputA, sInputB, Comment, nAvg, OPTIONS, FreqBands);
        case 'concat'
            nAvg = 1;
            OutputFiles{end+1} = SaveFile(R, sInputB.iStudy, [], sInputA, sInputB, Comment, nAvg, OPTIONS, FreqBands);
        case 'avg'
            % Compute online average of the connectivity matrices
            if isempty(Ravg)
                Ravg = R ./ length(FilesA);
            else
                Ravg = Ravg + R ./ length(FilesA);
            end
            nAvg = nAvg + 1;
    end
end

%% ===== SAVE AVERAGE =====
if strcmpi(OPTIONS.OutputMode, 'avg')
    % Save file
    OutputFiles{1} = SaveFile(Ravg, OPTIONS.iOutputStudy, [], sInputA, sInputB, Comment, nAvg, OPTIONS, FreqBands);
end


end



%% ========================================================================
%  ===== SUPPORT FUNCTIONS ================================================
%  ========================================================================

%% ===== SAVE FILE =====
function NewFile = SaveFile(R, iOuptutStudy, DataFile, sInputA, sInputB, Comment, nAvg, OPTIONS, FreqBands)
    NewFile = [];
    bst_progress('text', 'Saving results...');
    % ===== PREPARE OUTPUT STRUCTURE =====
    % Create file structure
    FileMat = db_template('timefreqmat');
    FileMat.TF        = R;
    FileMat.Comment   = Comment;
    FileMat.DataType  = sInputB.DataType;
    FileMat.Freqs     = OPTIONS.Freqs;
    FileMat.Method    = OPTIONS.Method;
    FileMat.DataFile  = file_win2unix(DataFile);
    FileMat.nAvg      = nAvg;
    % Time vector
    if strcmpi(OPTIONS.Method, 'plvt')
        FileMat.Time      = sInputB.Time;
        FileMat.TimeBands = [];
    else
        FileMat.Time      = sInputB.Time([1,end]);
        FileMat.TimeBands = {OPTIONS.Method, sInputB.Time(1), sInputB.Time(end)};
    end
    % Measure
    if strcmpi(OPTIONS.Method, 'plv') || strcmpi(OPTIONS.Method, 'plvt')
        FileMat.Measure   = 'none';
    else
        FileMat.Measure   = 'other';
    end
    % Row names: NxM
    FileMat.RefRowNames = sInputA.RowNames;
    FileMat.RowNames    = sInputB.RowNames;
    % Atlas 
    if ~isempty(sInputB.Atlas)
        FileMat.Atlas = sInputB.Atlas;
    end
    if ~isempty(sInputB.SurfaceFile)
        FileMat.SurfaceFile = sInputB.SurfaceFile;
    end
    if ~isempty(sInputB.GridLoc)
        FileMat.GridLoc = sInputB.GridLoc;
    end
    % History: Computation
    FileMat = bst_history('add', FileMat, 'compute', ['Connectivity measure: ', OPTIONS.Method, ' (see the field "Options" for input parameters)']);

    % Apply time and frequency bands
    if ~isempty(FreqBands)
        FileMat = process_tf_bands('Compute', FileMat, FreqBands, []);
        if isempty(FileMat)
            bst_report('Error', OPTIONS.ProcessName, [], 'Error computing the frequency bands.');
            return;
        end
    end
    
    % ===== OPTIMIZE STORAGE FOR SYMMETRIC MATRIX =====
    FileMat.Options = OPTIONS;
    % Keep only the values below the diagonal
    if FileMat.Options.isSymmetric && (size(FileMat.TF,1) == length(FileMat.RowNames)^2)
        FileMat.TF = process_compress_sym('Compress', FileMat.TF);
    end
        
    % ===== SAVE FILE =====
    % Get output study
    sOutputStudy = bst_get('Study', iOuptutStudy);
    % File tag
    if (length(sInputA.RowNames) == 1)
        fileTag = 'connect1';
    else
        fileTag = 'connectn';
    end
    % Output filename
    NewFile = bst_process('GetNewFilename', bst_fileparts(sOutputStudy.FileName), ['timefreq_' fileTag '_' OPTIONS.Method]);
    % Save file
    bst_save(NewFile, FileMat, 'v6');
    % Add file to database structure
    db_add_data(iOuptutStudy, NewFile, FileMat);
end


%% ===== LOAD CONCATENATED =====
function sInput = LoadConcat(FileNames, Target, TimeWindow, LoadOptions, startValue)
    sInput = [];
    for iFile = 1:length(FileNames)
        % Load file
        bst_progress('set',  round(startValue + (iFile-1) / length(FileNames) * 100));
        sTmp = bst_process('LoadInputFile', FileNames{iFile}, Target, TimeWindow, LoadOptions);
        % Concatenate with previous file
        if isempty(sTmp.Data)
            return;
        elseif isempty(sInput)
            sInput = sTmp;
        else
            sInput.Data = [sInput.Data, sTmp.Data];
            sInput.Time = [sInput.Time, sTmp.Time + sTmp.Time(2) - 2*sTmp.Time(1) + sInput.Time(end)];
        end
    end
end


