function [OutputFiles, Messages] = bst_timefreq(Data, OPTIONS)
% BST_TIMEFREQ: Compute time-frequency decompositions of the signals.
%
% USAGE:  [OutputFiles, Messages] = bst_timefreq(Data, OPTIONS)
% 
%                         OPTIONS = bst_timefreq();
%
% INPUTS:
%     - Data: Can be one of the following
%          - String, filename
%          - Cell-array of strings, filenames
%          - Matrix of time-series [nRow x nTime]
%          - Cell-array of matrices of time series
%     - OPTIONS: Structure with the following fields
%          - Method       : {'morlet', 'fft', 'psd', 'hilbert'}
%          - Output       : {'average', 'all'}
%          - Comment      : Output file comment
%          - ListFiles    : Cell array of filenames, used only if Data is a matrix of data (used to reference the "parent" file)
%          - iTargetStudy : Specify output study
%          - TimeVector   : Full time vector of the data to process
%          - SensorTypes  : Cell-array of strings, sensors to process (can be sensor names or sensor types)
%          - RowNames     : Names of the rows in the data matrix that is processed (sensors name, scout name, etc.)
%          - Freqs        : Frequencies to process, vector or frequency bands (cell array)
%          - TimeBands    : Cell array, time bands to process when not using the original file time
%          - MorletFc     : Parameter for Morlet wavelets
%          - MorletFwhmTc : Parameter for Morlet wavelets
%          - Measure      : Function to apply to the TF coefficients after computation: {'Power', 'none'}
%          - ClusterFuncTime : When is the cluster function supposed to be applied respect with the TF decomposition: {'before', 'after'}
% 
% OUTPUTS:
%     - OutputFiles : Cell-array, list of files that were created
%                     or the contents of the file if we don't know where to save them
%     - Messages    : String, reports errors and warnings

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

%% ===== DEFAULT OPTIONS =====
Def_OPTIONS.Comment         = '';
Def_OPTIONS.Method          = 'morlet';
Def_OPTIONS.Freqs           = [];
Def_OPTIONS.TimeVector      = [];
Def_OPTIONS.TimeBands       = [];
Def_OPTIONS.TimeWindow      = [];
Def_OPTIONS.ClusterFuncTime = 'none';
Def_OPTIONS.Measure         = 'power';
Def_OPTIONS.Output          = 'all';
Def_OPTIONS.MorletFc        = 1;
Def_OPTIONS.MorletFwhmTc    = 3;
Def_OPTIONS.WinLength       = [];
Def_OPTIONS.WinOverlap      = 50;
Def_OPTIONS.isMirror        = 0;
Def_OPTIONS.SensorTypes     = 'MEG, EEG';
Def_OPTIONS.Clusters        = {};
Def_OPTIONS.iTargetStudy    = [];
Def_OPTIONS.SaveKernel      = 0;
Def_OPTIONS.nComponents     = 1;
% Return the default options
if (nargin == 0)
    OutputFiles = Def_OPTIONS;
    return
end
% Copy default options to OPTIONS structure (do not replace defined values)
OPTIONS = struct_copy_fields(OPTIONS, Def_OPTIONS, 0);


%% ===== PARSE INPUTS =====
% Initializations
OutputFiles = {};
Messages = [];
% Data: List of data blocks/files to process
if ~iscell(Data)
    Data = {Data};
end
% OPTIONS
nGoodSamples_avg = [];
isAverage        = strcmpi(OPTIONS.Output, 'average');
nAvg             = 1;
nAvgTotal        = 0;
TF_avg           = [];
ChannelFlag      = [];
RowNames         = [];
InitTimeVector   = [];
nRows            = [];
% Number of frequency bands
if iscell(OPTIONS.Freqs)
    FreqBands = OPTIONS.Freqs;
else
    FreqBands = [];
end
isAddedCommentSensor = 0;
isAddedCommentOptions = 0;
% Cannot do average and "save kernel" at the same time
if isAverage && OPTIONS.SaveKernel
    Messages = 'Incompatible options: 1)Keep the inversion kernel and 2)average trials';
end
        
% Progress bar
switch(OPTIONS.Method)
    case 'morlet',   strMap = 'time-frequency maps';
    case 'fft',      strMap = 'FFT values';
    case 'psd',      strMap = 'PSD values';
    case 'hilbert',  strMap = 'Hilbert maps';
end
bst_progress('start', 'Frequency analysis', ['Computing ' strMap '...'], 0, 2 * length(Data));

% Loop on all the data blocks
for iData = 1:length(Data)
    % ===== GET INITIAL DATA FILE =====
    % If data block is a file
    isFile = ischar(Data{iData});
    if isFile 
        InitFile = Data{iData};
    elseif isempty(OPTIONS.ListFiles)
        InitFile = [];
    else
        InitFile = OPTIONS.ListFiles{iData};
    end
    % Get source information
    if ~isempty(InitFile)
        % Get file in database
        [sStudy, iStudy, iFile, DataType] = bst_get('AnyFile', InitFile);
        % Convert file type
        if strcmpi(DataType, 'link')
            DataType = 'results';
        end
    else
        DataType = 'scout';
        iStudy = [];
    end

    % Output study
    if isequal(OPTIONS.iTargetStudy, 'NoSave')
        iTargetStudy = [];
    elseif ~isempty(OPTIONS.iTargetStudy)
        iTargetStudy = OPTIONS.iTargetStudy;
    else
        iTargetStudy = iStudy;
    end
    
    % ===== READ DATA =====
    iGoodChannels = [];
    ImagingKernel = [];
    SurfaceFile   = [];
    GridLoc       = [];
    if isFile
        % Select subset of data
        switch (DataType)
            case 'data'
                % Read file
                sMat = in_bst_data(InitFile, 'F', 'Time', 'ChannelFlag', 'nAvg');
                % Raw file 
                if isstruct(sMat.F)
                    sFile = sMat.F;
                    % Check that we are not reading from a epoched file
                    if (length(sFile.epochs) > 1)
                        Messages = 'Files with epochs are not supported by this process.';
                        return;
                    end
                    % Reading options
                    ImportOptions = db_template('ImportOptions');
                    ImportOptions.ImportMode = 'Time';
                    ImportOptions.Resample   = 0;
                    ImportOptions.UseCtfComp = 1;
                    ImportOptions.UseSsp     = 1;
                    ImportOptions.RemoveBaseline = 'no';
                    ImportOptions.DisplayMessages = 0;
                    % Read data
                    SamplesBounds = sFile.prop.samples(1) + bst_closest(OPTIONS.TimeWindow, sMat.Time) - 1;
                    [F, sMat.Time] = in_fread(sFile, 1, SamplesBounds, [], ImportOptions);
                % Imported data file
                else
                    F = sMat.F;
                end
                nAvg = sMat.nAvg;
                OPTIONS.TimeVector = sMat.Time;
                % Get channel file
                ChannelFile = bst_get('ChannelFileForStudy', sStudy.FileName);
                if isempty(ChannelFile)
                    error('No channel definition available for this file.');
                end
                % Load channel file
                ChannelMat  = in_bst_channel(ChannelFile);
                ChannelFlag = sMat.ChannelFlag;
                % Get channels we want to process
                if ~isempty(OPTIONS.SensorTypes)
                    % Get sensor types
                    [iChannels, SensorComment] = channel_find(ChannelMat.Channel, OPTIONS.SensorTypes);
                    % Not average file: keep only the good channels
                    if ~isAverage
                        iChannels = intersect(iChannels, find(ChannelFlag == 1));
                    end
                    % No sensors: error
                    if isempty(iChannels)
                        Messages = 'No sensors are selected.';
                        return;
                    end
                    % Add comment
                    if ~isAddedCommentSensor
                        isAddedCommentSensor = 1;
                        OPTIONS.Comment = [OPTIONS.Comment ' (', SensorComment, ')'];
                    end
                    % Remove the unnecessary data
                    F = F(iChannels, :);
                    ChannelFlag = ChannelFlag(iChannels);
                    RowNames = {ChannelMat.Channel(iChannels).Name};
                else
                    RowNames = {ChannelMat.Channel.Name};
                end
                % Accumulator for good rows markers
                if isAverage
                    % Check for same number of rows
                    if isempty(nRows)
                        nRows = size(F,1);
                    elseif (nRows ~= size(F,1))
                        Messages = 'Input files do not have the same number of channels: Cannot compute average.';
                        return;
                    end
                    if isempty(nGoodSamples_avg)
                        nGoodSamples_avg = zeros(size(F,1), 1);
                    end
                    iGoodChannels = find(ChannelFlag == 1);
                    nGoodSamples_avg(iGoodChannels) = nGoodSamples_avg(iGoodChannels) + nAvg;
                end
                
            case 'results'
                % The PSD cannot be applied on the sensors signals and then projected to the sources, as it returns only the power in each frequency band instead of the complex values
                if strcmpi(OPTIONS.Method, 'psd')
                    isLoadFull = 1;
                % The dynamic ZScore has to be applied before any other computation
                elseif ~isempty(strfind(InitFile, '_zscore'))
                    %isLoadFull = 1;
                    Messages = 'Cannot process dynamic zscores of sources.';
                    return;
                else
                    isLoadFull = 0;
                end
                % Get inversion kernel
                ResultsMat = in_bst_results(InitFile, isLoadFull, 'ImageGridAmp', 'ImagingKernel', 'GoodChannel', 'nComponents', 'DataFile', 'nAvg', 'Time', 'Atlas', 'SurfaceFile', 'GridLoc');
                % Row "names" for sources: source indices
                nComponents = ResultsMat.nComponents;
                SurfaceFile = ResultsMat.SurfaceFile;
                GridLoc     = ResultsMat.GridLoc;
                nSources = max(size(ResultsMat.ImageGridAmp,1), size(ResultsMat.ImagingKernel,1)) ./ ResultsMat.nComponents;
                
                % Kernel results: Process the recordings file
                if ~isempty(ResultsMat.ImagingKernel) && isempty(ResultsMat.ImageGridAmp)
                    ImagingKernel = ResultsMat.ImagingKernel;
                    % Load associated data file
                    sMat = in_bst_data(sStudy.Result(iFile).DataFile);
                    % Get indices of channels for this results file
                    F    = sMat.F(ResultsMat.GoodChannel, :);
                    nAvg = sMat.nAvg;
                    OPTIONS.TimeVector = sMat.Time;
                % Full results: Proces the sources time series
                else
                    F    = ResultsMat.ImageGridAmp;
                    nAvg = ResultsMat.nAvg;
                    OPTIONS.TimeVector = ResultsMat.Time;
                end
                % RowNames: If it comes from an atlas: keep the atlas labels
                if isfield(ResultsMat, 'Atlas') && ~isempty(ResultsMat.Atlas) && ~isempty(ResultsMat.Atlas.Scouts)
                    RowNames = {ResultsMat.Atlas.Scouts.Label};
                % Else: use row indices
                else
                    RowNames = 1:nSources;
                end
                
            case 'matrix'
                % Read file
                sMat = in_bst_matrix(InitFile);
                F    = sMat.Value;
                nAvg = sMat.nAvg;
                OPTIONS.TimeVector = sMat.Time;
                % Row name in Description field
                if (numel(sMat.Description) ~= size(F,1))
                    Messages = 'Only the "matrix" file that represent scouts/clusters time series can be processed by this function.';
                    return;
                end
                RowNames = sMat.Description';
                
            otherwise
                Messages = ['Unsupported data type: ' DataType];
                return;
        end
        clear ResultsMat sMat;
        % Keep only the required time window
        if ~isempty(OPTIONS.TimeWindow)
            % Find the indices of the time window in the original time vector
            iTime = bst_closest(OPTIONS.TimeWindow, OPTIONS.TimeVector);
            % If the time window is invalid: start index=stop index
            if (iTime(1) == iTime(2))
                Messages = ['Selected time window is not valid for one of the input files.' 10 ...
                            'If you are processing files with different time definitions,' 10 ...
                            'consider using the process Standardize > Uniform epoch time.'];
                return;
            end
            % Keep only the time window of interest
            iTime = iTime(1):iTime(2);
            OPTIONS.TimeVector = OPTIONS.TimeVector(iTime);
            F = F(:,iTime);
        end
        
    % ===== PROCESS DATA BLOCKS =====
    else
        RowNames = OPTIONS.RowNames{iData};
        F = Data{iData};
        % Restore initial time vector, in case it was modified by the process
        if isempty(InitTimeVector)
            InitTimeVector = OPTIONS.TimeVector;
        else
            OPTIONS.TimeVector = InitTimeVector;
        end
        % Data type: 'cluster' or 'scout'
        if strcmpi(DataType, 'data')
            DataType = 'cluster';
            nComponents = 1;
        else
            DataType = 'scout';
            if (length(OPTIONS.nComponents) == 1)
                nComponents = OPTIONS.nComponents;
            else
                nComponents = OPTIONS.nComponents(iData);
            end
        end
    end

    % ===== COMPUTE TRANSFORM =====
    isMeasureApplied = 0;
    switch (OPTIONS.Method)
        % Morlet wavelet transform (Dimitrios Pantazis)
        case 'morlet'
            % Remove mean of the signal
            F = bst_bsxfun(@minus, F, mean(F,2));
            % Group in frequency bands
            if ~isempty(FreqBands)
                OPTIONS.Freqs = [];
                % Get frequencies for each frequency bands
                evalFreqBands = process_tf_bands('Eval', FreqBands);
                % Loop on each frequency
                for iBand = 1:size(evalFreqBands,1)
                    freq = evalFreqBands{iBand,2};
                    % If there are only two values: use 4 values for the frequency band
                    if (length(freq) == 2)
                        freq = linspace(freq(1), freq(2), 4);
                    end
                    % Add to the frequencies to process
                    OPTIONS.Freqs = [OPTIONS.Freqs, freq];
                end
            end
            % Compute wavelet decompositions
            TF = morlet_transform(F, OPTIONS.TimeVector, OPTIONS.Freqs, OPTIONS.MorletFc, OPTIONS.MorletFwhmTc, 'n');

        % FFT: Matlab function fft
        case 'fft'
            % Next power of 2 from length of signal
            sRate = abs(1 / (OPTIONS.TimeVector(2) - OPTIONS.TimeVector(1)));
            nTime = length(OPTIONS.TimeVector);
            NFFT = 2^nextpow2(nTime);
            % Positive frequency bins spanned by FFT
            OPTIONS.Freqs = sRate / 2 * linspace(0,1,NFFT/2+1);
            % Keep only first and last time instants
            OPTIONS.TimeVector = OPTIONS.TimeVector([1 end]);
            % Remove mean of the signal
            F = bst_bsxfun(@minus, F, mean(F,2));
            % Apply a hamming window to signal
            F = bst_bsxfun(@times, F, bst_window(size(F,2), 'hamming')');
            % Compute FFT
            Ffft = fft(F, NFFT, 2);
            % Keep only first half
            % (x2 to recover full power from negative frequencies)
            TF = 2 * Ffft(:,1:NFFT/2+1) ./ nTime;
            % Permute dimensions: time and frequency
            TF = permute(TF, [1 3 2]);
%             % Comment
%             if (iData == 1)
%                 OPTIONS.Comment = ['FFT: ' OPTIONS.Comment];
%             end
            
        % PSD: Homemade computation based on Matlab's FFT
        case 'psd'
            % Calculate PSD/FFT
            [TF, OPTIONS.Freqs, Nwin, Messages] = bst_psd(F, OPTIONS.TimeVector, OPTIONS.WinLength, OPTIONS.WinOverlap);
            if isempty(TF)
                return;
            end
            % Keep only first and last time instants
            OPTIONS.TimeVector = OPTIONS.TimeVector([1 end]);
            % Comment
            if ~isAddedCommentOptions
                isAddedCommentOptions = 1;
                OPTIONS.Comment = sprintf('PSD: %d/%dms %s', Nwin, round(OPTIONS.WinLength.*1000), OPTIONS.Comment);
            end
            % Measure is already applied (power)
            isMeasureApplied = 1;
            
        % Hilbert
        case 'hilbert'
            % Get bounds of each frequency bands
            BandBounds = process_tf_bands('GetBounds', FreqBands);
            % Intitialize returned matrix
            TF = zeros(size(F,1), size(F,2), size(BandBounds,1));
            % Loop on each frequency band
            for iBand = 1:size(BandBounds,1)
                % Band-pass filter in one frequency band
                Fband = process_bandpass('Compute', F, OPTIONS.TimeVector, BandBounds(iBand,1), BandBounds(iBand,2), [], OPTIONS.isMirror);
                % Apply Hilbert transform
                TF(:,:,iBand) = hilbert(Fband')';
            end
    end
    bst_progress('inc', 1);
    % Set to zero the bad channels
    if ~isempty(iGoodChannels)
        iBadChannels = setdiff(1:size(F,1), iGoodChannels);
        if ~isempty(iBadChannels)
            TF(iBadChannels, :, :) = 0;
        end
    end
    % Clean memory
    clear F;

    % ===== REBUILD FULL SOURCES =====
    % Kernel => Full results
    if strcmpi(DataType, 'results') && ~isempty(ImagingKernel) && ~OPTIONS.SaveKernel
        % Initialize full time-frequency matrix
        TF_full = zeros(size(ImagingKernel,1), size(TF,2), size(TF,3));
        % Loop on the frequencies
        for ifreq = 1:size(TF,3)
            TF_full(:,:,ifreq) = ImagingKernel * TF(:,:,ifreq);
        end
        % Replace previous values with new ones
        TF = TF_full;
        clear TF_full;
    end
    % Cannot save kernel when components > 1
    if strcmpi(DataType, 'results') && OPTIONS.SaveKernel && (nComponents > 1)
        Messages = ['Cannot keep the inversion kernel when processing unconstrained sources.' 10 ...
                    'Please selection the option "Optimize: No, save full sources."'];
        return;
    end
    
    % ===== APPLY SOURCE ORIENTATION =====
    % Unconstrained sources => SUM for each point
    if (strcmpi(DataType, 'results') || strcmpi(DataType, 'scout')) && (nComponents > 1)
        % Number of values per vertex
        switch (nComponents)
            case 2,  TF = abs(TF(1:2:end,:,:)).^2 + abs(TF(2:2:end,:,:)).^2;
            case 3,  TF = abs(TF(1:3:end,:,:)).^2 + abs(TF(2:3:end,:,:)).^2 + abs(TF(3:3:end,:,:)).^2;
        end
        % If power was already applied
        if isMeasureApplied
            TF = sqrt(TF);
        % Else: Apply measure
        else
            switch lower(OPTIONS.Measure)
                case 'none'
                    Messages = 'Cannot process unconstrained sources without applying a measure: Power or Magnitude.';
                    return;
                case 'power'
                    % Nothing to do, already squared
                case 'magnitude'
                    TF = sqrt(TF);
            end
        end
        isMeasureApplied = 1;
        % Scouts with 3 orientations: Keep one label every 3
        if strcmpi(DataType, 'scout')
            RowNames = RowNames(1:nComponents:end);
            RowNames = cellfun(@(c)c(1:end-2), RowNames, 'UniformOutput', 0);
        end
    end
    
    % ===== APPLY MEASURE =====
    if ~isMeasureApplied
        switch lower(OPTIONS.Measure)
            case 'none',      % Nothing to do
            case 'power',     TF = abs(TF) .^ 2;
            case 'magnitude', TF = abs(TF);
            otherwise,        error('Unknown measure.');
        end
    end
    
    % ===== PROCESS POWER FOR SCOUTS/CLUSTERS =====
    % Get the lists of clusters
    ClusterNames = unique(RowNames);
    % If processing data blocks and if there are identical row names => Processing clusters / scouts
    if ~isFile && ~isempty(OPTIONS.Clusters) && (length(ClusterNames) ~= length(RowNames))
        % If cluster function should be applied AFTER time-freq: we have now all the time series
        if strcmpi(OPTIONS.ClusterFuncTime, 'after')
            TF_cluster = zeros(length(ClusterNames), size(TF,2), size(TF,3));
            % For each unique row name: compute a measure over the clusters values
            for iCluster = 1:length(ClusterNames)
                indClust = find(strcmpi(ClusterNames{iCluster}, RowNames));
                % Compute cluster/scout measure
                for iFreq = 1:size(TF,3)
                    TF_cluster(iCluster,:,iFreq) = bst_scout_value(TF(indClust,:,iFreq), OPTIONS.Clusters(iCluster).Function);
                end
            end
            % Save only the requested rows
            RowNames = {OPTIONS.Clusters.Label};
            TF = TF_cluster;
        % Just make all RowNames unique
        else
            initRowNames = RowNames;
            RowNames = cell(size(TF,1),1);
            % For each row name: update name with the indice of the row
            for iCluster = 1:length(ClusterNames)
                indClust = find(strcmpi(ClusterNames{iCluster}, initRowNames));
                % Process each cluster element: add an indice
                for i = 1:length(indClust)
                    RowNames{indClust(i)} = sprintf('%s.%d', ClusterNames{iCluster}, i);
                end
            end
        end
    end

    % ===== SAVE FILE / COMPUTE AVERAGE =====
    % Only save average
    if isAverage
        % First loop: create the accumulator
        if isempty(TF_avg)
            TF_avg = zeros(size(TF));
        % Other loops: check if data size is coherent with previous loops
        elseif ~isequal(size(TF), size(TF_avg))
            Messages = 'Input files have different or number of elements: cannot compute average...';
            return;
        end
        % Add block to accumulator
        TF_avg = TF_avg + TF * nAvg;
        nAvgTotal = nAvgTotal + nAvg;
    % Save all the time-frequency maps
    else
        % Save file
        SaveFile(iTargetStudy, InitFile, DataType, RowNames, TF, OPTIONS, FreqBands, SurfaceFile, GridLoc);
    end
    bst_progress('inc', 1);
end

% Finish to compute average
if isAverage
    bst_progress('start', 'Time-frequency', 'Saving average...');
    % Non-recordings: divide everything 
    if isempty(nGoodSamples_avg)
        TF_avg = TF_avg ./ nAvgTotal;
    % Else: we have the information channel by channel
    else
        % Delete the channels that are bad everywhere
        iBad = find(nGoodSamples_avg == 0);
        if ~isempty(iBad)
            TF_avg(iBad,:,:) = [];
            nGoodSamples_avg(iBad) = [];
            RowNames(iBad) = [];
        end
        % Divide channel by channel
        for i = 1:length(nGoodSamples_avg)
            TF_avg(i,:,:) = TF_avg(i,:,:) ./ nGoodSamples_avg(i);
        end
    end
    % Related file: ignore if more than one in input
    if (length(Data) > 1)
        InitFile = '';
    end
    % Save file
    SaveFile(iTargetStudy, InitFile, DataType, RowNames, TF_avg, OPTIONS, FreqBands, SurfaceFile, GridLoc);
end


%% ===== SAVE FILE =====
    function SaveFile(iTargetStudy, DataFile, DataType, RowNames, TF, OPTIONS, FreqBands, SurfaceFile, GridLoc)
        % Create file structure
        FileMat = db_template('timefreqmat');
        FileMat.Comment   = OPTIONS.Comment;
        FileMat.DataType  = DataType;
        FileMat.TF        = TF;
        FileMat.Time      = OPTIONS.TimeVector;
        FileMat.TimeBands = [];
        FileMat.Freqs     = OPTIONS.Freqs;
        FileMat.RowNames  = RowNames;
        FileMat.Measure   = OPTIONS.Measure;
        FileMat.Method    = OPTIONS.Method;
        FileMat.DataFile  = file_short(DataFile);
        FileMat.nAvg      = nAvg;
        FileMat.SurfaceFile = SurfaceFile;
        FileMat.GridLoc     = GridLoc;
        % Options
        FileMat.Options.Method          = OPTIONS.Method;
        FileMat.Options.Measure         = OPTIONS.Measure;
        FileMat.Options.Output          = OPTIONS.Output;
        FileMat.Options.MorletFc        = OPTIONS.MorletFc;
        FileMat.Options.MorletFwhmTc    = OPTIONS.MorletFwhmTc;
        FileMat.Options.ClusterFuncTime = OPTIONS.ClusterFuncTime;
        % History: Computation
        FileMat = bst_history('add', FileMat, 'compute', 'Time-frequency decomposition');
        
        % Apply time and frequency bands
        % if ~strcmpi(OPTIONS.Method, 'hilbert') && (~isempty(FreqBands) || ~isempty(OPTIONS.TimeBands))
        %     FileMat = process_tf_bands('Compute', FileMat, FreqBands, OPTIONS.TimeBands);
        % end
        if ~isempty(FreqBands) || ~isempty(OPTIONS.TimeBands)
            if strcmpi(OPTIONS.Method, 'hilbert') && ~isempty(OPTIONS.TimeBands)
                FileMat = process_tf_bands('Compute', FileMat, [], OPTIONS.TimeBands);
            elseif strcmpi(OPTIONS.Method, 'morlet') || strcmpi(OPTIONS.Method, 'psd') 
                FileMat = process_tf_bands('Compute', FileMat, FreqBands, OPTIONS.TimeBands);
            end
        end
        
        % Save the file
        if ~isempty(iTargetStudy)
            % Get output study
            sTargetStudy = bst_get('Study', iTargetStudy);
            % Output filename
            fileBase = 'timefreq';
            if strcmpi(OPTIONS.Output, 'all') && ~isempty(FileMat.DataFile)
                % Look for a trial tag in the filename
                iTagStart = strfind(FileMat.DataFile, '_trial');
                if ~isempty(iTagStart)
                    iTagStop = iTagStart + min([find(FileMat.DataFile(iTagStart+6:end) == '_',1), find(FileMat.DataFile(iTagStart+6:end) == '.',1)]) + 4;
                    if ~isempty(iTagStop)
                        fileBase = [fileBase FileMat.DataFile(iTagStart:iTagStop)];
                    end
                end
            end
            if OPTIONS.SaveKernel
                fileBase = [fileBase '_KERNEL_' OPTIONS.Method];
            else
                fileBase = [fileBase '_' OPTIONS.Method];
            end
            FileName = bst_process('GetNewFilename', bst_fileparts(sTargetStudy.FileName), fileBase);
            % Save file
            bst_save(FileName, FileMat, 'v6');
            % Add file to database structure
            db_add_data(iTargetStudy, FileName, FileMat);
            % Return new filename
            OutputFiles{end+1} = FileName;
        % Returns the contents of the file instead of saving them
        else
            OutputFiles{end+1} = FileMat;
        end
    end

end


