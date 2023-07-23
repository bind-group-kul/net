function newDataFile = bst_simulation(ResultsFile, iVertices, Comment)
% BST_SIMULATION:  Create a pseudo-recordings file by multiplying the forward model with the sources.
%
% USAGE:  newDataFile = bst_simulation(ResultsFile, iVertices, Comment)
%         newDataFile = bst_simulation(ResultsFile, iVertices)  : Use only the selected vertices
%         newDataFile = bst_simulation(ResultsFile)             : Use all the vertices
%
% INPUT:
%     - ResultsFile : Full or relative path to a brainstorm sources file
%     - iVertices   : Indices of the sources to use to simulate the recordings
%     - Comment     : Comment inserted in the created file
% OUTPUT:
%     - newDataFile : Full path to the simulated recordings file created and saved in the database

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
% Authors: Francois Tadel, 2009-2011

%% ===== PARSE INPUTS =====
global GlobalData;
% No vertices specified, take them all
if (nargin < 2)
    iVertices = [];
end
% No comment
if (nargin < 3)
    Comment = '';
end
% Get the protocol folders
ProtocolInfo = bst_get('ProtocolInfo');

%% ===== LOAD SOURCES =====
bst_progress('start', 'Simulation', 'Loading sources...');
% Load results matrix
[iDS, iResult] = bst_memory('LoadResultsFileFull', ResultsFile);
if isempty(iDS)
    return
end
% Check the type of results file
if ~isempty(GlobalData.DataSet(iDS).Results(iResult).Atlas)
    bst_error('Cannot process sources that have been downsampled based on an atlas.', 'bst_simulation', 0);
    return;
end

% ===== LOAD GAIN MATRIX =====
bst_progress('text', 'Loading head model...');
% Get study
[sStudy, iStudy] = bst_get('ResultsFile', ResultsFile);
% Get default headmodel for this study
sHeadModel = bst_get('HeadModelForStudy', iStudy);
if isempty(sHeadModel)
    error('No headmodel available for this study.');
end
HeadModelFile = sHeadModel.FileName;
% Load HeadModel file
HeadModelMat = in_headmodel_bst(HeadModelFile, 0, 'Gain', 'GridLoc', 'GridOrient');
% Number of vertices
nVertGain = size(HeadModelMat.Gain, 2) ./ 3;
nSources  = max(size(GlobalData.DataSet(iDS).Results(iResult).ImagingKernel,1), size(GlobalData.DataSet(iDS).Results(iResult).ImageGridAmp,1)) ./ GlobalData.DataSet(iDS).Results(iResult).nComponents;
% If the head model doesn't match the number of vertices: try loading the head model pointed by the results file
if (nVertGain ~= nSources)
    % Get headmodel file from ResultsFile
    ResultsMat = in_bst_results(ResultsFile, 0,  'HeadModelFile');
    HeadModelFile = ResultsMat.HeadModelFile;
    % Load HeadModel file
    HeadModelMat = in_headmodel_bst(HeadModelFile, 0, 'Gain', 'GridLoc', 'GridOrient');
    % Number of vertices
    nVertGain = size(HeadModelMat.Gain, 2) ./ 3;
    % Check again the number of vertices
    if (nVertGain ~= nSources)
        error(sprintf('Number of sources in the head model (%d) and the inverse model (%d) do not match.', nVertGain, nSources));
    end
end
% No vertices specified: read all
if isempty(iVertices)
    iVertices = 1:nVertGain;
end

%% ===== SIMULATION LOOP =====
% Get time vector
TimeVector = bst_memory('GetTimeVector', iDS, iResult, 'UserTimeWindow');
% Maximum number of time points to process at once
blockSize = 100;
% Compute number of blocks
nBlocks = ceil(length(TimeVector) / blockSize);
% Initialize simulated matrix
nTime = length(TimeVector);
F = zeros(size(HeadModelMat.Gain,1), nTime);
% Progress bar
bst_progress('start', 'Simulation', 'Simulating recordings...', 0, nBlocks);
% Process each time block
for iBlock = 1:nBlocks
    bst_progress('inc', 1);
    % Get time indices
    iTime = ((iBlock-1)*blockSize+1) : min(iBlock * blockSize, nTime);
    % Get sources matrix
    [ResultsValues, nComponents, nVertRes] = bst_memory('GetResultsValues', iDS, iResult, iVertices, iTime, 0);    
    % Check the dimensions of Gain and sources matrix
    if (nVertGain ~= nVertRes)
        error('Number of vertices in selected forward and inverse models do not match.');
    end
    % If sources constrained / head model unconstrained => Constrain head model
    if (nComponents == 1) && (iBlock == 1)
        % If no orientations: error
        if isempty(HeadModelMat.GridOrient)
            error('No source orientations available in this head model.');
        end
        % Apply the fixed orientation to the Gain matrix (normal to the cortex)
        HeadModelMat.Gain = bst_gain_orient(HeadModelMat.Gain, HeadModelMat.GridOrient);
    end
    
    % Fill matrix by computing: leadfield * sources
    switch (nComponents)
        case 1
            F(:,iTime) = HeadModelMat.Gain(:,iVertices) * ResultsValues;
        case 2
            F(:,iTime) = HeadModelMat.Gain(:,2*iVertices-2) * ResultsValues(1:2:end,:) + ...
                         HeadModelMat.Gain(:,2*iVertices-1) * ResultsValues(2:2:end,:);
        case 3
            F(:,iTime) = HeadModelMat.Gain(:,3*iVertices-2) * ResultsValues(1:3:end,:) + ...
                         HeadModelMat.Gain(:,3*iVertices-1) * ResultsValues(2:3:end,:) + ...
                         HeadModelMat.Gain(:,3*iVertices)   * ResultsValues(3:3:end,:);
    end
end
% Remove NaN values
F(isnan(F)) = 0;


%% ===== BUILD SIMULATED DATA FILE =====
% Progress bar
bst_progress('start', 'Simulation', 'Saving simulated recordings...');
% Get a string to represent time
c = clock;
strTime = sprintf('%02.0f%02.0f%02.0f_%02.0f%02.0f', c(1)-2000, c(2:5));
% Build comment
DataComment = ['Simulation: ' Comment ' ' GlobalData.DataSet(iDS).Results(iResult).Comment ' (' strTime ')'];
% Build data file
DataMat = db_template('DataMat');
DataMat.Comment     = DataComment;
DataMat.Time        = TimeVector;
DataMat.F           = F;
DataMat.ChannelFlag = GlobalData.DataSet(iDS).Results(iResult).ChannelFlag;
DataMat.DataType    = 'recordings';

% ===== HISTORY =====
% History: Simulate recordings
DataMat = bst_history('add', DataMat, 'simulation', 'File simulated: Headmodel * Results');
DataMat = bst_history('add', DataMat, 'simulation', [' - Head model file: ' HeadModelFile]);
DataMat = bst_history('add', DataMat, 'simulation', [' - Results file file: ' ResultsFile]);


%% ===== SAVE FILE =====
% Output file
outputFolder = bst_fileparts(GlobalData.DataSet(iDS).StudyFile);
newDataFile = bst_fullfile(ProtocolInfo.STUDIES, outputFolder, ['data_simulation_', strTime, '.mat']);
newDataFile = file_unique(newDataFile);
% Save file
bst_save(newDataFile, DataMat, 'v6');

% ===== UPDATE DATABASE =====
% Unloading dataset
bst_memory('UnloadDataSets', iDS);
% Get study
[sStudy, iStudy, iResult] = bst_get('ResultsFile', ResultsFile);
% Add to database
db_add_data(iStudy, newDataFile, DataMat);
% Update links
db_links('Study', iStudy);
% Update display
panel_protocols('UpdateNode', 'Study', iStudy);
% Select node
panel_protocols('SelectStudyNode', iStudy);
% Hide progress bar 
bst_progress('stop');



