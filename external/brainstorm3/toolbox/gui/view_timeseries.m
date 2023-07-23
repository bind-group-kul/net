function [hFig, iDS, iFig] = view_timeseries(DataFile, Modality, RowNames, hFig)
% VIEW_TIMESERIES: Display times series in a new figure.
%
% USAGE: [hFig, iDS, iFig] = view_timeseries(DataFile, Modality=[], RowNames=[], hFig=[])
%        [hFig, iDS, iFig] = view_timeseries(DataFile, Modality=[], RowNames=[], 'NewFigure')
%
% INPUT: 
%     - DataFile  : Path to data file to visualize
%     - Modality  : Modality to display with the input Data file
%     - RowNames  : Cell array of channel names to plot in this figure
%     - "NewFigure" : force new figure creation (do not re-use a previously created figure)
%     - hFig        : Specify the figure in which to display the MRI
%
% OUTPUT : 
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

%% ===== INITIALIZATION =====
global GlobalData;
% Parse inputs
if (nargin < 3) || isempty(RowNames)
    RowNames = {};
elseif ischar(RowNames)
    RowNames = {RowNames};
end
if (nargin < 2) || isempty(Modality)
    % Get default modality
    [tmp,tmp,Modality] = bst_get('ChannelModalities', DataFile);
end
% Get target figure
if (nargin < 4) || isempty(hFig)
    hFig = [];
    iFig = [];
    NewFigure = 0;
elseif ischar(hFig) && strcmpi(hFig, 'NewFigure')
    hFig = [];
    iFig = [];
    NewFigure = 1;
elseif ishandle(hFig)
    [hFig,iFig,iDS] = bst_figures('GetFigure', hFig);
    NewFigure = 0;
else
    error('Invalid figure handle.');
end


%% ===== GET A DATASET AND LOAD DATA =====
% Get DataFile information
[sStudy, iData, ChannelFile] = bst_memory('GetFileInfo', DataFile);
% If Channel is not defined
if isempty(ChannelFile)
    Modality = 'EEG';
end
% If not loaded yet
if isempty(hFig)
    % Load file
    iDS = bst_memory('LoadDataFile', DataFile);
    % If no DataSet is accessible : error
    if isempty(iDS)
        return
    end
end

%% ===== CREATE A NEW FIGURE =====
bst_progress('start', 'View time series', 'Loading data...');
if isempty(hFig)
    % Prepare FigureId structure
    FigureId.Type     = 'DataTimeSeries';
    FigureId.SubType  = '';
    FigureId.Modality = Modality;
    % Create TimeSeries figure
    if NewFigure
        [hFig, iFig, isNewFig] = bst_figures('CreateFigure', iDS, FigureId, 'AlwaysCreate', RowNames);
    else
        [hFig, iFig, isNewFig] = bst_figures('CreateFigure', iDS, FigureId, [], RowNames);
    end
    if isempty(hFig)
        bst_error('Could not create figure', 'View time series', 0);
        return;
    end
else
    isNewFig = 0;
end
% Add DataFile to figure appdata
setappdata(hFig, 'DataFile', DataFile);
setappdata(hFig, 'StudyFile',    GlobalData.DataSet(iDS).StudyFile);
setappdata(hFig, 'SubjectFile',  GlobalData.DataSet(iDS).SubjectFile);

%% ===== SELECT ROWS =====
% Select only the channels that we need to plot
if ~isempty(RowNames) 
    % Get the channels normally displayed in this figure
    iSelChanMod = GlobalData.DataSet(iDS).Figure(iFig).SelectedChannels;
    % Get the channels that are requested from the command line call (RowNames argument)
    iSelChanCall = [];
    AllChannels = {GlobalData.DataSet(iDS).Channel.Name};
    for i = 1:length(RowNames)
        iSelChanCall = [iSelChanCall, find(strcmpi(RowNames{i}, AllChannels))];
    end
    % Keep only the intersection of the two selections (if non-empty)
    if ~isempty(iSelChanCall) && ~isempty(intersect(iSelChanMod, iSelChanCall))
        GlobalData.DataSet(iDS).Figure(iFig).SelectedChannels = intersect(iSelChanMod, iSelChanCall);
    end
    % Redraw position of figures
    if (iFig > 1)
        gui_layout('Update');
    end
end

%% ===== CONFIGURE FIGURE =====
% Static dataset ?
setappdata(hFig, 'isStatic', (GlobalData.DataSet(iDS).Measures.NumberOfSamples <= 2));
% Statistics?
isStat = strcmpi(GlobalData.DataSet(iDS).Measures.DataType, 'stat');
% Create time-series information structure
if isNewFig
    TsInfo = db_template('TsInfo');
    TsInfo.FileName = DataFile;
    TsInfo.Modality = Modality;
    TsInfo.DisplayMode  = bst_get('TSDisplayMode');
    TsInfo.LinesLabels  = {};
    TsInfo.AxesLabels   = {};
    TsInfo.LinesColor   = {};
    TsInfo.RowNames     = RowNames;
    TsInfo.MontageName  = [];
    TsInfo.FlipYAxis    = ~isempty(Modality) && ismember(Modality, {'EEG','MEG','MEG GRAD','MEG MAG','SEEG','ECOG'}) && ~isStat && bst_get('FlipYAxis');
    TsInfo.AutoScaleY   = bst_get('AutoScaleY');
    TsInfo.NormalizeAmp = 0;
    TsInfo.Resolution   = [0 0];
else
    TsInfo = getappdata(hFig, 'TsInfo');
    TsInfo.FileName = DataFile;
end
setappdata(hFig, 'TsInfo', TsInfo);
% Get default montage
if isNewFig
    sMontage = panel_montage('GetCurrentMontage', Modality);
    if ~isempty(sMontage) && isempty(RowNames) && (~isStat || strcmpi(sMontage.Type, 'selection'))
        TsInfo.MontageName = sMontage.Name;
    else
        TsInfo.MontageName = [];
    end
    setappdata(hFig, 'TsInfo', TsInfo);
end

%% ===== PLOT TIME SERIES =====
% Update figure selection
bst_figures('SetCurrentFigure', hFig, '2D');
% Plot figure
isOk = figure_timeseries('PlotFigure', iDS, iFig);
% Some error occured during the display procedure: close the window and stop process
if ~isOk
    close(hFig);
    return;
end


%% ===== UPDATE ENVIRONMENT =====
% Uniformize time series scales if required
isUniform = bst_get('UniformizeTimeSeriesScales');
if ~isempty(isUniform) && (isUniform == 1)
    figure_timeseries('UniformizeTimeSeriesScales', 1); 
end
% Set figure visible
if strcmpi(get(hFig,'Visible'), 'off')
    set(hFig, 'Visible', 'on');
end
% Set the time label visible
figure_timeseries('SetTimeVisible', hFig, 1);
bst_progress('stop');
% Select surface tab
if isNewFig
    panel_record('UpdateDisplayOptions', hFig);
    gui_brainstorm('SetSelectedTab', 'Record');
end




