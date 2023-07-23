function [hFig, iDS, iFig] = view_connect(TimefreqFile, DisplayMode, isNewFigure)
% VIEW_CONNECT: Display a NxN connectivity matrix
%
% USAGE: [hFig, iDS, iFig] = view_connect(TimefreqFile, DisplayMode='SingleSensor', RowName=[], isNewFigure=0)
%
% INPUT: 
%     - TimefreqFile : Path to connectivity file to visualize
%     - DisplayMode  : {'Image', 'GraphFull', 'GraphGroups'}
%     - isNewFigure  : If 1, force the creation of a new figure
%
% OUTPUT : 
%     - hFig : Matlab handle to the figure that was created or updated
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
% Authors: Francois Tadel, 2012


%% ===== PARSE INPUTS =====
if (nargin < 2)
    DisplayMode = 'GraphFull';
end
if (nargin < 3) || isempty(isNewFigure) || (isNewFigure == 0)
    CreateMode = '';
else
    CreateMode = 'AlwaysCreate';
end
% Initializations
global GlobalData;
hFig = [];
iFig = [];
% Check if OpenGL is activated
if bst_get('DisableOpenGL')
    bst_error(['Connectivity figures requires the OpenGL rendering to be enabled.' 10 ...
               'Please go to File > Edit preferences...'], 'View connectivity matrix', 0);
    return;
elseif ~exist('org.brainstorm.connect.GraphicsFramework', 'class')
    bst_error(['The OpenGL connectivity graph is not available for your version of Matlab.' 10 10 ...
               'You can use those tools by running the compiled version: ' 10 ...
               'see the Installation page on the Brainstorm website.'], 'View connectivity matrix', 0);
    return;
end


%% ===== LOAD CONNECT FILE =====
% Get study
[sStudy, iStudy, iTf] = bst_get('TimefreqFile', TimefreqFile);
if isempty(sStudy)
    error('File is not registered in database.');
end
% Progress bar
bst_progress('start', 'View connectivity map', 'Loading data...');
% Load file
[iDS, iTimefreq] = bst_memory('LoadTimefreqFile', TimefreqFile);
if isempty(iDS)
    return;
end
% Detect modality
Modality = GlobalData.DataSet(iDS).Timefreq(iTimefreq).Modality;
% Check that the matrix is square: cannot display [NxM] connectivity matrix where N~=M
if (length(GlobalData.DataSet(iDS).Timefreq(iTimefreq).RefRowNames) ~= length(GlobalData.DataSet(iDS).Timefreq(iTimefreq).RowNames)) && ~strcmpi(DisplayMode, 'Image')
    bst_error(sprintf('The connectivity matrix size is [%dx%d].\nThis graph display can be used only for square matrices (NxN).', ...
              length(GlobalData.DataSet(iDS).Timefreq(iTimefreq).RefRowNames), length(GlobalData.DataSet(iDS).Timefreq(iTimefreq).RowNames)), ...
              'View connectivity matrix', 0);
    return;
end


%% ===== DISPLAY AS IMAGE =====
% Display as image
if strcmpi(DisplayMode, 'Image')
    if ~isempty(GlobalData.UserFrequencies.iCurrentFreq)
        iFreqs = GlobalData.UserFrequencies.iCurrentFreq;
    else
        iFreqs = 1;
    end
    if ismember(GlobalData.DataSet(iDS).Timefreq(iTimefreq).Method, {'plv','plvt'})
        TfFunction = 'magnitude';
    else
        TfFunction = 'other';
    end
    % Get values
    TF = bst_memory('GetTimefreqValues', iDS, iTimefreq, [], iFreqs, 1, TfFunction);
    % Get connectivity matrix
    M = bst_memory('GetConnectMatrix', iDS, iTimefreq, TF);
    % Plot as a flat image
    view_image(M(:,:,1), 'jet', ['Connectivity: ' TimefreqFile], [], []);
    bst_progress('stop');
    return;
end
%     function ClickCallback(hFig, iSel)
%         % Get selected rows
%         selRefRow = uniqueRefRows{iSel(1)};
%         selRow    = uniqueRows{iSel(2)};
%         % Display them
%         disp([selRefRow '=>' selRow]);
%         % Load a pseudo 1xN connectivity file
%         iNewTf = bst_memory('LoadTimefreqRow', iDS, iTimefreq, selRefRow);
%         NewFileName = GlobalData.DataSet(iDS).Timefreq(iNewTf).FileName;
%         % Display
%         switch (GlobalData.DataSet(iDS).Timefreq(iTimefreq).DataType)
%             case 'data'
%                 view_topography(NewFileName, [], '2DSensorCap', [], 0);
%             otherwise
%                 error('Not supported yet.');
%         end
%     end


%% ===== CREATE FIGURE =====
% Prepare FigureId structure
FigureId          = db_template('FigureId');
FigureId.Type     = 'Connect';
FigureId.SubType  = DisplayMode;
FigureId.Modality = Modality;
% Create figure
[hFig, iFig, isNewFig] = bst_figures('CreateFigure', iDS, FigureId, CreateMode, sStudy.Timefreq(iTf).FileName);   
% If figure was not created: Display an error message and return
if isempty(hFig)
    bst_error('Cannot create figure', 'View connectivity matrix', 0);
    return;
end
% If it is not a new figure: reinitialize it
if ~isNewFig
    figure_connect('ResetDisplay', hFig);
end


%% ===== INITIALIZE FIGURE =====
% Configure app data
setappdata(hFig, 'DataFile',     GlobalData.DataSet(iDS).DataFile);
setappdata(hFig, 'StudyFile',    GlobalData.DataSet(iDS).StudyFile);
setappdata(hFig, 'SubjectFile',  GlobalData.DataSet(iDS).SubjectFile);
% Static dataset
setappdata(hFig, 'isStatic', (GlobalData.DataSet(iDS).Timefreq(iTimefreq).NumberOfSamples <= 2));
isStaticFreq = (size(GlobalData.DataSet(iDS).Timefreq(iTimefreq).TF,3) <= 1);
setappdata(hFig, 'isStaticFreq', isStaticFreq);
% Get figure data
TfInfo = getappdata(hFig, 'Timefreq');
% Create time-freq information structure
TfInfo.FileName    = sStudy.Timefreq(iTf).FileName;
TfInfo.Comment     = sStudy.Timefreq(iTf).Comment;
TfInfo.DisplayMode = DisplayMode;
TfInfo.InputTarget = [];
TfInfo.RowName     = [];
IsDirectionalData = 0;
IsBinaryData = 0;
ThresholdAbsoluteValue = 0;
switch (GlobalData.DataSet(iDS).Timefreq(iTimefreq).Method)
    case 'corr',     TfInfo.Function = 'other';
                     ThresholdAbsoluteValue = 1;
    case 'cohere',   TfInfo.Function = 'other';
    case 'granger',  TfInfo.Function = 'other';
                     IsDirectionalData = 1;
                     IsBinaryData = 1;
    case 'plv',      TfInfo.Function = 'magnitude';
    case 'plvt',     TfInfo.Function = 'magnitude';
    otherwise,       TfInfo.Function = 'other';
end
% Update figure variable
setappdata(hFig, 'Method', GlobalData.DataSet(iDS).Timefreq(iTimefreq).Method);
setappdata(hFig, 'IsDirectionalData', IsDirectionalData);
setappdata(hFig, 'IsBinaryData', IsBinaryData);
setappdata(hFig, 'ThresholdAbsoluteValue', ThresholdAbsoluteValue);
setappdata(hFig, 'is3DDisplay', strcmpi(DisplayMode, '3DGraph'));

% Frequency selection
if isStaticFreq
    TfInfo.iFreqs = [];
else
    TfInfo.iFreqs = GlobalData.UserFrequencies.iCurrentFreq;
end
% Set figure data
setappdata(hFig, 'Timefreq', TfInfo);
% Display options panel
gui_brainstorm('ShowToolTab', 'Display');


%% ===== DRAW FIGURE =====
figure_connect('LoadFigurePlot', hFig);


%% ===== UPDATE ENVIRONMENT =====
% Update figure selection
bst_figures('SetCurrentFigure', hFig, 'TF');
% Select display options
panel_display('UpdatePanel', hFig);
% Set figure visible
set(hFig, 'Visible', 'on');
bst_progress('stop');


end





