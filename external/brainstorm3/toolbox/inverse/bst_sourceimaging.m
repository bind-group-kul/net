function [OPTIONS, Results] = bst_sourceimaging(OPTIONS)
% BST_SOURCEIMAGING: Command line call to source imaging routines
%
% USAGE: [OPTIONS,Results] = bst_sourceimaging(OPTIONS)
%                  OPTIONS = bst_sourceimaging()
%
% INPUTS
%       OPTIONS - a structure of parameters
% OUTPUTS
%       Results - a regular Brainstorm Results structure (see documentation for details)
%
% Details of the structure for OPTIONS
%   Data Information:
%          .DataFile   : A string or Cell array of strings of actual data files requested for localization. 
%                        or empty [] to compute a generic linear solution (kernel)
%          .TimeSegment: Vector of min and max time samples (in seconds) giving first and last latencies specifying
%                        the time window for analysis.
%                        (Default is empty : i.e. take all time samples)
%          .BaselineSegment: Vector of min and max time samples (in seconds) giving first and last latencies specifying
%                        the time window for baseline. The baseline will be
%                        used to noise normalize the cortical maps
%          .ChannelFlag: a vector of flags (1 for good, -1 for bad) of channels in the data file to process
%                        (Default is ChannelFlag from data file or all good channels from data array )
%          .DataTypes  : Cell array of strings: list of modality to use for the reconstruction (MEG, MEG GRAD, MEG MAG, EEG)
%          .Comment    : Inverse solution description (optional)
%          .NoiseCovRaw: Noise covariance matrix for RAW recordings ([nChannel x nChannel] matrix)
%   
%   Channel information:
%          .ChannelFile: path to channel file
%
%   Forward Field Information :
%          .HeadModelFile: Filename of the Brainstorm headmodel file to use for imaging. If is empty, look for.GainFile field.
%
%   Processing Parameters :
%          .InverseMethod   : A string that specifies the imaging method: wmne, dspm, sloreta, lcmvbf...
%          .Tikhonov        : Hyperparameter used in Tykhonov regularization
%          .FFNormalization : Apply forward field normalization of the gain matrix
%          .OutputFormat    : Parameter for LCMV Beamformer (see lcmvbf.m)
%   Output Information:
%          .ResultFile      : Output filename
%          .ComputeKernel   : If 1, compute MN kernel to be applied subsequently to data instead of full ImageGridAmp array

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
% Authors: Sylvain Baillet, October 2002
%          Esen Kucukaltun-Yildirim, 2004
%          Syed Ashrafulla, John Mosher, Rey Ramirez, 2009-2012
%          Francois Tadel, 2009-2013


%% ===== PARSE INPUTS =====
% Default options settings
Def_OPTIONS = struct(...
    ... === DATABASE ===
    'ChannelFlag',         [], ...
    'ChannelFile',         '', ...
    'HeadModelFile',       '', ...
    'DataFile',            '', ...
    'Data',                [], ...
    'DataTypes',           [], ...
    'DataTime',            [], ...
    ... === GENERAL OPTIONS ===
    'InverseMethod',       'wmne', ...
    'Comment',             '', ...
    'NoiseCovRaw',         [], ...
    'nAvg',                1, ...
    'DisplayMessages',     1, ...
    ... === OLD MINNORM OPTIONS ===
    'FFNormalization',     1, ...
    'Tikhonov',            10, ...
    ... === LCMV OPTIONS ===
    'TimeSegment',         [], ...
    'BaselineSegment',     [], ...
    'DataBaseline',        [], ...
    ... === OUTPUT OPTIONS ===
    'ResultFile',          '', ...
    'ComputeKernel',       1);
% Return empty OPTIONS structure
if (nargin == 0)
    OPTIONS = Def_OPTIONS;
    Results = [];
    return
end
% Check field names of passed OPTIONS and fill missing ones with default values
OPTIONS = struct_copy_fields(OPTIONS, Def_OPTIONS, 0);
clear Def_OPTIONS
% Check some mandatory fields
if isempty(OPTIONS.HeadModelFile) || isempty(OPTIONS.ChannelFile) || isempty(OPTIONS.DataTypes) 
    error('The following fields must be defined: HeadModelFile, DataFile, ChannelFile, DataTypes.');
end
% Get brainstorm protocol information
ProtocolInfo = bst_get('ProtocolInfo');


%% ===== CHANNEL FILE =====
ChannelMat = in_bst_channel(OPTIONS.ChannelFile, 'Channel');
OPTIONS.Channel = ChannelMat.Channel; 
clear ChannelMat

%% ===== LOAD DATA =======================================================
if ~isempty(OPTIONS.DataFile)
    % Load data file info
    DataMat = in_bst_data(OPTIONS.DataFile, 'ChannelFlag', 'Time', 'nAvg');
    % If ChannelFlag not given: take the one from the Data file
    if isempty(OPTIONS.ChannelFlag)
        OPTIONS.ChannelFlag = DataMat.ChannelFlag;
    end
    % Number of trials (meaningful for averages only)
    nAvg = DataMat.nAvg;

    % ===== TIME =====
    % Default Time Segment: the whole set of time samples
    if ~isempty(OPTIONS.TimeSegment)
        TimeBounds = bst_closest([OPTIONS.TimeSegment(1) OPTIONS.TimeSegment(2)], DataMat.Time'); 
        iTime = TimeBounds(1):TimeBounds(end); 
    else
        iTime = 1:length(DataMat.Time); 
    end
    % Full time segment (in sample indices)
    OPTIONS.DataTime = DataMat.Time(iTime);
else
    iTime = [];
    nAvg = OPTIONS.nAvg;
end
if isempty(nAvg)
    nAvg = 1;
end

% Divide noise covariance by number of trials
if ~isempty(OPTIONS.NoiseCovRaw)
    OPTIONS.NoiseCov = OPTIONS.NoiseCovRaw ./ nAvg;
else
    OPTIONS.NoiseCov = [];
end

%% ===== CHANNEL FLAG =====
% Get the list of good channels
OPTIONS.GoodChannel = good_channel(OPTIONS.Channel, OPTIONS.ChannelFlag, OPTIONS.DataTypes);
if isempty(OPTIONS.GoodChannel)
    error('No good channels available.');
end


%% ===== LOAD RECORDINGS =====
if ~OPTIONS.ComputeKernel || strcmpi(OPTIONS.InverseMethod, 'lcmvbf')
    % Load data
    DataMat = in_bst_data(OPTIONS.DataFile, 'F', 'Time');
    % Get data of interest
    OPTIONS.Data = DataMat.F(OPTIONS.GoodChannel, iTime);
    % Release structure
    clear DataMatF
end


%% ===== LOAD HEAD MODEL =====
% Load head model
HeadModel = in_headmodel_bst(OPTIONS.HeadModelFile, 0, 'Gain', 'GridLoc', 'GridOrient', 'SurfaceFile', 'MEGMethod', 'EEGMethod', 'ECOGMethod', 'SEEGMethod', 'HeadModelType');
% Select only good channels
HeadModel.Gain = HeadModel.Gain(OPTIONS.GoodChannel, :);
% Apply average reference: separately SEEG, ECOG, EEG
if any(ismember(unique({OPTIONS.Channel.Type}), {'EEG','ECOG','SEEG'}))
    sMontage = panel_montage('GetMontageAvgRef', OPTIONS.Channel(OPTIONS.GoodChannel), OPTIONS.ChannelFlag(OPTIONS.GoodChannel));
    HeadModel.Gain = sMontage.Matrix * HeadModel.Gain;
end
% Get surface file
SurfaceFile = HeadModel.SurfaceFile;
% Get number of sources
nSources =  size(HeadModel.Gain,2) / 3;
% Check that processing MEG with a spherical headmodel: if not, discard the 'truncated' option
if isfield(OPTIONS, 'SourceOrient') && strcmpi(OPTIONS.SourceOrient{1}, 'truncated')  && (~isfield(HeadModel, 'MEGMethod') || ~strcmpi(HeadModel.MEGMethod, 'meg_sphere'))
    warning('Recordings do not contain MEG, or forward model is not spherical: ignore "truncated" source orientation.');
    OPTIONS.SourceOrient = {'loose'};
end


%% ===== DEFAULT FILENAME =====
% If use default filename
if isempty(OPTIONS.ResultFile);
    % === METHOD NAME ===
    switch(OPTIONS.InverseMethod)
        case 'lcmvbf'
            switch OPTIONS.OutputFormat
                case 0,  strMethod = '_LCMV_KERNEL'; % Filter Output
                case 1,  strMethod = '_LCMV';        % Neural Index 
                case 2,  strMethod = '_LCMV_KERNEL'; % Normalized Filter Output
                case 3,  strMethod = '_LCMV';        % Source Power
            end
        case 'wmne',    strMethod = '_wMNE';
        case 'gls',     strMethod = '_GLS';
        case 'gls_p',   strMethod = '_GLSP';
        case 'glsr',    strMethod = '_GLSR';
        case 'glsr_p',  strMethod = '_GLSRP';
        case 'mnej',    strMethod = '_MNEJ';
        case 'mnej_p',  strMethod = '_MNEJP';
        case 'dspm',    strMethod = '_dSPM';
        case 'sloreta', strMethod = '_sLORETA';
        case 'mem',     strMethod = '_MEM';
    end
    % Add Modality name
    for i = 1:length(OPTIONS.DataTypes)
        strMethod = [strMethod, '_', file_standardize(OPTIONS.DataTypes{i})];
    end
    % Add Kernel tag
    if OPTIONS.ComputeKernel
        strMethod = [strMethod, '_KERNEL'];
    end
    
    % File Path
    if isempty(OPTIONS.DataFile)
        OutputDir = bst_fileparts(file_fullpath(OPTIONS.ChannelFile));
    else
        OutputDir = bst_fileparts(file_fullpath(OPTIONS.DataFile));
    end
    % Output filename
    OPTIONS.ResultFile = bst_process('GetNewFilename', OutputDir, ['results', strMethod]);
end
% Ensure relative/full paths
OPTIONS.ResultFile = file_short(OPTIONS.ResultFile);
ResultFileFull = bst_fullfile(ProtocolInfo.STUDIES, OPTIONS.ResultFile);

%% ===== COMPUTE INVERSE SOLUTION =====
switch( OPTIONS.InverseMethod )       
    case 'lcmvbf'
        if ~isempty(OPTIONS.BaselineSegment)
            % Get baseline
            BaselineInd = bst_closest([OPTIONS.BaselineSegment(1) OPTIONS.BaselineSegment(2)], DataMat.Time'); %get the indices for start and stop points
            OPTIONS.BaselineSegment = [DataMat.Time(BaselineInd(1)), DataMat.Time(BaselineInd(end))]; % Time segment (min max only, in sec)
            iTimeNoise = BaselineInd(1):BaselineInd(end); % Full Baseline segment
            if length(iTimeNoise)<3
                error('Baseline region does not have enough time slices. Select a different noise region');
            end
            % Get data on the baseline
            OPTIONS.DataBaseline = DataMat.F(OPTIONS.GoodChannel, iTimeNoise);
        end
        clear DataMat;
        
        % Apply constrains
        if OPTIONS.isConstrained
            HeadModel.Gain = bst_gain_orient(HeadModel.Gain, HeadModel.GridOrient);
        end
        % Beamformer estimation
        [Results, OPTIONS] = bst_lcmvbf(HeadModel.Gain, OPTIONS);
        
    case {'wmne', 'dspm', 'sloreta'}      
        % NoiseCov: keep only the good channels
        if ~isempty(OPTIONS.NoiseCov)
            OPTIONS.NoiseCov = OPTIONS.NoiseCov(OPTIONS.GoodChannel, OPTIONS.GoodChannel);
        else
            OPTIONS.NoiseCov = eye(length(OPTIONS.GoodChannel));
        end
        % Get channels types
        OPTIONS.ChannelTypes = {OPTIONS.Channel(OPTIONS.GoodChannel).Type};
        % Call Rey's wmne function
        % NOTE: The output HeadModel param is used here in return to save LOTS of memory in the bst_wmne function,
        %       event if it seems to be absolutely useless. Having a parameter in both input and output have the
        %       effect in Matlab of passing them "by referece".
        %       So please, do NOT remove it from the following line
        [Results, OPTIONS, HeadModel] = bst_wmne(HeadModel, OPTIONS);

    case {'gls', 'gls_p', 'glsr', 'glsr_p', 'mnej', 'mnej_p'}
        % NoiseCov: keep only the good channels
        if ~isempty(OPTIONS.NoiseCov)
            OPTIONS.NoiseCov = OPTIONS.NoiseCov(OPTIONS.GoodChannel, OPTIONS.GoodChannel);
        else
            OPTIONS.NoiseCov = eye(length(OPTIONS.GoodChannel));
        end
        % Get channels types
        OPTIONS.ChannelTypes = {OPTIONS.Channel(OPTIONS.GoodChannel).Type};
        % Mosher's function
        [Results, OPTIONS] = bst_wmne_mosher(HeadModel, OPTIONS);
        
    case 'mem'
        % NoiseCov: keep only the good channels
        if ~isempty(OPTIONS.NoiseCov)
            OPTIONS.NoiseCov = OPTIONS.NoiseCov(OPTIONS.GoodChannel, OPTIONS.GoodChannel);
        else
            OPTIONS.NoiseCov = eye(length(OPTIONS.GoodChannel));
        end
        % Get channels types
        OPTIONS.ChannelTypes = {OPTIONS.Channel(OPTIONS.GoodChannel).Type};
        % Call the mem solver
        [Results, OPTIONS] = be_main(HeadModel, OPTIONS);
        
    otherwise
        error('Unknown method');
end
% Check if number no time dimension
if ~isempty(Results.ImageGridAmp) && (size(Results.ImageGridAmp, 2) == 1)
    % If the output is not a timecourse: replicate the results to get two time instants
    Results.ImageGridAmp = repmat(Results.ImageGridAmp, [1,2]); 
    % Keep only first and last time instants
    iTime = [iTime(1), iTime(end)];
    OPTIONS.DataTime = [OPTIONS.DataTime(1), OPTIONS.DataTime(end)];    
end

%% ===== COMPUTE FULL RESULTS =====
% Full results
if (OPTIONS.ComputeKernel == 0) && ~isempty(Results.ImagingKernel)
    % Multiply inversion kernel with the recordings
    Results.ImageGridAmp = Results.ImagingKernel * OPTIONS.Data;
    Results.ImagingKernel = [];
end

%% ===== SAVE RESULTS FILE =====
% Number of components for each vertex
Results.nComponents = round(max(size(Results.ImageGridAmp,1),size(Results.ImagingKernel,1)) / nSources);
% Add a few fields (for records)
if ~isempty(OPTIONS.Comment)
    Results.Comment = OPTIONS.Comment;
else
    Results.Comment = OPTIONS.InverseMethod;
end
Results.Function = OPTIONS.InverseMethod;
if (OPTIONS.ComputeKernel == 1)
    Results.Time = [];
else
    Results.Time = OPTIONS.DataTime;
end
Results.ChannelFlag   = OPTIONS.ChannelFlag;
Results.GoodChannel   = OPTIONS.GoodChannel;
Results.HeadModelFile = file_short(OPTIONS.HeadModelFile);
Results.HeadModelType = HeadModel.HeadModelType;
Results.SurfaceFile   = file_short(SurfaceFile);
switch lower(Results.HeadModelType)
    case 'volume'
        Results.GridLoc = HeadModel.GridLoc;
    case 'surface'
        Results.GridLoc = [];
    case 'dba'
        Results.GridLoc = HeadModel.GridLoc;
    otherwise
        Results.GridLoc = [];
end
if isempty(OPTIONS.DataFile)
    Results.DataFile = '';
else
    Results.DataFile = file_short(OPTIONS.DataFile);
end
% Save the relevant method options
strOptions = intersect(fieldnames(OPTIONS), ...
    {'DataTypes','DataTime','nAvg','FFNormalization','Tikhonov','TimeSegment','BaselineSegment', ...
     'DataBaseline','ComputeKernel','SNR','diagnoise','SourceOrient','loose','depth','weightexp', ...
     'weightlimit','magreg','gradreg','eegreg','ecogreg','seegreg','pca','flagSourceOrient'});
for i = 1:length(strOptions)
    Results.Options.(strOptions{i}) = OPTIONS.(strOptions{i});
end
% History
Results = bst_history('add', Results, 'compute', ['Source estimation: ' OPTIONS.InverseMethod]);
% Save Results structure
bst_save(ResultFileFull, Results, 'v6');







