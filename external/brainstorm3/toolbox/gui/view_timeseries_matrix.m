function [hFig, iDS, iFig] = view_timeseries_matrix(BaseFiles, F, Modality, AxesLabels, LinesLabels, LinesColor, hFig)
% VIEW_TIMESERIES_MATRIX: Display times series matrix in a new figure.
%
% USAGE:  [hFig, iDS, iFig] = view_timeseries_matrix(BaseFiles, F, Modality, AxesLabels, LinesLabels, LinesColor, hFig)
%         [hFig, iDS, iFig] = view_timeseries_matrix(BaseFiles, F, Modality, AxesLabels, LinesLabels, LinesColor)
%         [hFig, iDS, iFig] = view_timeseries_matrix(BaseFiles, F)
%
% INPUT:
%   - BaseFiles   : Files that figure will be associated with
%   - F           : Cell-array of data matrices to display ([NbRows x NbTime])  {1 x nbData}
%   - Modality    : {'MEG', 'MEG MAG', 'MEG GRAD', 'EEG', 'Other', 'Source', ...}
%   - LinesLabels : Cell array of strings {NbRows}
%   - LinesColor  : Cell array of RGB colors 
%   - hFig        : Specify the figure to draw in
%
% OUTPUT: 
%     - hFig : Matlab handle to the 3DViz figure that was created or updated
%     - iDS  : DataSet index in the GlobalData variable
%     - iFig : Indice of returned figure in the GlobalData(iDS).Figure array

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
% Authors: Francois Tadel, 2008-2014


%% ===== PARSE INPUTS =====
global GlobalData;
% Parse inputs
if (nargin < 7) || isempty(hFig)
    hFig = [];
end
if (nargin < 6) || isempty(LinesColor)
    LinesColor = [];
end
if (nargin < 5) || isempty(LinesLabels)
    LinesLabels = {};
end
if (nargin < 4) || isempty(AxesLabels)
    AxesLabels = {};
end
if (nargin < 3) || isempty(Modality)
    Modality = '';
end
if (nargin < 2)
    error('Usage : [hFig, iDS, iFig] = view_timeseries_matrix(BaseFile, F, Modality, AxesLabels, LinesLabels, LinesColor)');
end
% BaseFiles: cell list or char
if isempty(BaseFiles)
    BaseFile = [];
elseif iscell(BaseFiles)
    BaseFile = BaseFiles{1};
elseif ischar(BaseFiles)
    BaseFile = BaseFiles;
    BaseFiles = {BaseFiles};
end
% Make sure that F is in a cell array
if ~iscell(F)
    F = {F};
end
if ~iscell(AxesLabels)
    AxesLabels = {AxesLabels};
end;
iFig = [];


%% ===== GET A DATASET AND LOAD DATA =====
% Get filetype
FileType = file_gettype(BaseFile);
ResultsFile = [];
% Load file
switch (FileType)
    case {'data', 'pdata'}
        iDS = bst_memory('LoadDataFile', BaseFile);
        FigureType = 'DataTimeSeries';
    case {'results', 'link', 'presults'}
        iDS = bst_memory('LoadResultsFile', BaseFile);
        FigureType = 'ResultsTimeSeries';
        ResultsFile = BaseFile;
    case 'timefreq'
        iDS = bst_memory('LoadTimefreqFile', BaseFile);
        FigureType = 'ResultsTimeSeries';
        ResultsFile = BaseFile;
    case 'matrix'
        iDS = bst_memory('LoadMatrixFile', BaseFile);
        FigureType = 'ResultsTimeSeries';
    otherwise
        error('Cannot display this file as time series.');
end
% If no DataSet is accessible : error
if isempty(iDS)
    return
end


%% ===== CREATE A NEW FIGURE =====
bst_progress('start', 'View time series', 'Loading data...');
% Use existing figure
if ~isempty(hFig)
     [hFig, iFig, iDS] = bst_figures('GetFigure', hFig);
     isNewFig = 0;
% Create new figure
else
    % Prepare FigureId structure
    FigureId.Type     = FigureType;
    FigureId.SubType  = '';
    FigureId.Modality = Modality;
    % Create TimeSeries figure
    [hFig, iFig, isNewFig] = bst_figures('CreateFigure', iDS, FigureId, [], BaseFiles);
    if isempty(hFig)
        bst_error('Cannot create figure', 'View time series matrix', 0);
        return;
    end
end
% Reset min/max values
[GlobalData.DataSet(iDS).Figure(iFig).Handles.DataMinMax] = deal([]);
% Add DataFile to figure appdata
setappdata(hFig, 'DataFile',     GlobalData.DataSet(iDS).DataFile);
setappdata(hFig, 'StudyFile',    GlobalData.DataSet(iDS).StudyFile);
setappdata(hFig, 'SubjectFile',  GlobalData.DataSet(iDS).SubjectFile);
if ~isempty(ResultsFile)
    setappdata(hFig, 'ResultsFile', ResultsFile);
end

%% ===== CONFIGURE FIGURE =====
% Static dataset ?
setappdata(hFig, 'isStatic', (GlobalData.DataSet(iDS).Measures.NumberOfSamples <= 2));
% Get default montage
MontageName = [];
if strcmpi(FileType, 'data')
    sMontage = panel_montage('GetCurrentMontage', Modality);
    if ~isempty(sMontage)
        MontageName = sMontage.Name;
    end
end
% Create topography information structure
TsInfo = db_template('TsInfo');
TsInfo.FileName     = BaseFile;
TsInfo.Modality     = Modality;
TsInfo.AxesLabels   = AxesLabels;
TsInfo.LinesLabels  = LinesLabels;
TsInfo.LinesColor   = LinesColor;
TsInfo.RowNames     = LinesLabels;
TsInfo.MontageName  = MontageName;
TsInfo.NormalizeAmp = 0;
TsInfo.Resolution   = [0 0];
if ~isNewFig
    oldTsInfo = getappdata(hFig, 'TsInfo');
    TsInfo.DisplayMode = oldTsInfo.DisplayMode;
    TsInfo.FlipYAxis   = oldTsInfo.FlipYAxis;
    TsInfo.AutoScaleY  = oldTsInfo.AutoScaleY;
elseif ~isempty(Modality) && ismember(Modality, {'$EEG','$MEG','$MEG GRAD','$MEG MAG','$SEEG','$ECOG'})
    TsInfo.DisplayMode = bst_get('TSDisplayMode');
    TsInfo.FlipYAxis   = bst_get('FlipYAxis');
    TsInfo.AutoScaleY  = bst_get('AutoScaleY');
else
    TsInfo.DisplayMode = 'butterfly';
    TsInfo.FlipYAxis   = 0;
    TsInfo.AutoScaleY  = 1;
end
setappdata(hFig, 'TsInfo', TsInfo);
% Update figure name
bst_figures('UpdateFigureName', hFig);

%% ===== PLOT TIME SERIES =====
figure_timeseries('PlotFigure', iDS, iFig, F);


%% ===== UPDATE ENVIRONMENT =====
% Uniformize time series scales if required
isUniform = bst_get('UniformizeTimeSeriesScales');
if ~isempty(isUniform) && (isUniform == 1)
    figure_timeseries('UniformizeTimeSeriesScales', 1); 
end

% Update figure selection
bst_figures('SetCurrentFigure', hFig, '2D');
% Set figure visible
set(hFig, 'Visible', 'on');
bst_progress('stop');


end






