function [hFig, iDS, iFig] = view_topography(DataFile, Modality, TopoType, F, UseMagneticExtrap, AlwaysCreate)
% VIEW_TOPOGRAPHY: Display MEG/EEG topography in a new figure.
%
% USAGE:  [hFig, iDS, iFig] = view_topography(DataFile, Modality, TopoType, F, UseMagneticExtrap, AlwaysCreate)
%         [hFig, iDS, iFig] = view_topography(DataFile, Modality, TopoType, F)
%         [hFig, iDS, iFig] = view_topography(DataFile, Modality, TopoType)
%
% INPUT: 
%     - DataFile  :  Full or relative path to data file to visualize.
%     - Modality  : {'MEG', 'MEG GRAD', 'MEG MAG', 'EEG', ...}
%     - TopoType  : {'3DSensorCap', '2DDisc', '2DSensorCap', 2DLayout'}
%     - F         : Data matrix to display instead of the real values from the file
%     - UseMagneticExtrap: Extrapolate magnetic values
%     - AlwaysCreate     : Force the creation of a new figure
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

global GlobalData;
% ===== PARSE INPUTS =====
if (nargin < 6) || isempty(AlwaysCreate) || ~AlwaysCreate
    CreateMode = [];
else
    CreateMode = 'AlwaysCreate';
end
if (nargin < 5) || isempty(UseMagneticExtrap)
    UseMagneticExtrap = [];
end
if (nargin < 4) || isempty(F)
    F = [];
end
if (nargin < 3) || isempty(TopoType)
    TopoType = '2DSensorCap';
end
if (nargin < 2) || isempty(Modality)
    Modality = '';
end

%% ===== LOAD DATA =====
bst_progress('start', 'Topography', 'Loading data file...');
% Get DataFile type
fileType = file_gettype(DataFile);
% Load file
switch(fileType)
    case 'data'
        FileType = 'Data';
        iDS = bst_memory('LoadDataFile', DataFile);
        if isempty(iDS)
            return;
        end
        % Colormap type
        if ~isempty(GlobalData.DataSet(iDS).Measures.ColormapType)
            ColormapType = GlobalData.DataSet(iDS).Measures.ColormapType;
        else
            switch Modality
                case {'MEG', 'MEG MAG', 'MEG GRAD'}
                    ColormapType = 'meg';
                case {'EEG', 'ECOG'}
                    ColormapType = 'eeg';
                otherwise
                    error(['Modality "' Modality '" cannot be represented in 2D topography.']);
            end
        end
        
    case 'pdata'
        FileType = 'Data';
        iDS = bst_memory('LoadDataFile', DataFile);
        if isempty(iDS)
            return;
        end
        % Colormap type
        if ~isempty(GlobalData.DataSet(iDS).Measures.ColormapType)
            ColormapType = GlobalData.DataSet(iDS).Measures.ColormapType;
        else
            ColormapType = 'stat2';
        end
        % Do not allow magnetic extrapolation for stat data
        UseMagneticExtrap = 0;
        
    case {'timefreq', 'ptimefreq'}
        FileType = 'Timefreq';
        [iDS, iTimefreq] = bst_memory('LoadTimefreqFile', DataFile);
        if isempty(iDS)
            return;
        end
        % Colormap type
        if ~isempty(GlobalData.DataSet(iDS).Timefreq(iTimefreq).ColormapType)
            ColormapType = GlobalData.DataSet(iDS).Timefreq(iTimefreq).ColormapType;
        elseif ismember(GlobalData.DataSet(iDS).Timefreq(iTimefreq).Method, {'corr','cohere','granger','plv','plvt'})
            ColormapType = 'connect1';
        elseif ismember(GlobalData.DataSet(iDS).Timefreq(iTimefreq).Method, {'pac'})
            ColormapType = 'pac';
        else
            ColormapType = 'timefreq';
        end
        % Do not allow magnetic extrapolation for Timefreq data
        UseMagneticExtrap = 0;
        % Detect modality
        Modality = GlobalData.DataSet(iDS).Timefreq(iTimefreq).Modality;
        % Check modality
        if (isempty(Modality) || ~ismember(Modality, {'MEG','MEG GRAD','MEG MAG','EEG'}))
            bst_error('Error: Cannot display 2D/3D topography for this file.', 'View topography', 0);
            return;
        end
        
    case 'none'
        
    otherwise
        error(['This files contains information about cortical sources or regions of interest.' 10 ...
               'Cannot display it as a sensor topography.']);
end
if isempty(iDS)
    error(['Cannot load file : "', DataFile, '"']);
end
% Default value for MagneticExtrap
if isempty(UseMagneticExtrap)
    UseMagneticExtrap = ~isempty(Modality) && ismember(Modality, {'MEG', 'MEG GRAD', 'MEG MAG'});
    % Data: Use magnetic interpolation only for real recordings
    if strcmpi(fileType, 'data')
        UseMagneticExtrap = UseMagneticExtrap && ismember(GlobalData.DataSet(iDS).Measures.DataType, {'recordings', 'raw'});
    end
end
     

%% ===== CREATE FIGURE =====
% Prepare FigureId structure
FigureId.Type     = 'Topography';
FigureId.SubType  = TopoType;
FigureId.Modality = Modality;
% Create TimeSeries figure
[hFig, iFig, isNewFig] = bst_figures('CreateFigure', iDS, FigureId, CreateMode, DataFile);
if isempty(hFig)
    bst_error('Cannot create figure', 'View topography', 0);
    return;
end

% Configure app data
setappdata(hFig, 'DataFile',     GlobalData.DataSet(iDS).DataFile);
setappdata(hFig, 'StudyFile',    GlobalData.DataSet(iDS).StudyFile);
setappdata(hFig, 'SubjectFile',  GlobalData.DataSet(iDS).SubjectFile);

%% ===== CONFIGURE FIGURE =====
% If figure already existed: re-use its UseMagneticExtrap value
if ~isNewFig
    oldTopoInfo = getappdata(hFig, 'TopoInfo');
    if ~isempty(oldTopoInfo) && ~isempty(oldTopoInfo.UseMagneticExtrap)
        UseMagneticExtrap = oldTopoInfo.UseMagneticExtrap;
    end
end
% Get default montage (skip "selection montages)
sMontage = panel_montage('GetCurrentMontage', Modality);
if ~isempty(sMontage) && ~strcmpi(sMontage.Type, 'selection')
    MontageName = sMontage.Name;
else
    MontageName = [];
end
% Create topography information structure
TopoInfo = db_template('TopoInfo');
TopoInfo.FileName   = DataFile;
TopoInfo.FileType   = FileType;
TopoInfo.Modality   = Modality;
TopoInfo.TopoType   = TopoType;
TopoInfo.DataToPlot = F;
TopoInfo.UseMagneticExtrap = UseMagneticExtrap;
setappdata(hFig, 'TopoInfo', TopoInfo);
% Create recordings info structure
TsInfo = db_template('TsInfo');
TsInfo.FileName    = DataFile;
TsInfo.Modality    = Modality;
TsInfo.DisplayMode = 'topography';
TsInfo.MontageName = MontageName;
setappdata(hFig, 'TsInfo', TsInfo);
% Add colormap
bst_colormaps('AddColormapToFigure', hFig, ColormapType);

% Time-freq structure
if strcmpi(FileType, 'Timefreq')
    % Get study
    [sStudy, iStudy, iItem, DataType, sTimefreq] = bst_get('AnyFile', DataFile);
    if isempty(sStudy)
        error('File is not registered in database.');
    end
    % Static dataset
    setappdata(hFig, 'isStatic', (GlobalData.DataSet(iDS).Timefreq(iTimefreq).NumberOfSamples <= 2));
    isStaticFreq = (size(GlobalData.DataSet(iDS).Timefreq(iTimefreq).TF,3) <= 1);
    setappdata(hFig, 'isStaticFreq', isStaticFreq);
    % Create options structure
    TfInfo = db_template('TfInfo');
    TfInfo.FileName  = DataFile;
    TfInfo.Comment   = sTimefreq.Comment;
    TfInfo.RowName   = [];
    TfInfo.Function  = process_tf_measure('GetDefaultFunction', GlobalData.DataSet(iDS).Timefreq(iTimefreq).Method);
    if isStaticFreq
        TfInfo.iFreqs = [];
    elseif ~isempty(GlobalData.UserFrequencies.iCurrentFreq)
        TfInfo.iFreqs = GlobalData.UserFrequencies.iCurrentFreq;
    else
        TfInfo.iFreqs = 1;
    end
    % Set figure data
    setappdata(hFig, 'Timefreq', TfInfo);
    % Update figure name
    bst_figures('UpdateFigureName', hFig);
    % Display options panel
    isDisplayTab = ~strcmpi(TfInfo.Function, 'other');
    if isDisplayTab
        gui_brainstorm('ShowToolTab', 'Display');
    end
else
    isDisplayTab = 0;
    setappdata(hFig, 'isStatic', (GlobalData.DataSet(iDS).Measures.NumberOfSamples <= 2));
end

%% ===== PLOT FIGURE =====
isOk = figure_topo('PlotFigure', iDS, iFig, 1);
% If an error occured: delete figure
if ~isOk
    close(hFig);
    bst_progress('stop');
    return
end

%% ===== UPDATE ENVIRONMENT =====
% Update 2D figure selection
bst_figures('SetCurrentFigure', hFig, '2D');
if isDisplayTab
    panel_display('UpdatePanel', hFig);
end
% Update 3D figure selection
if strcmpi(TopoType, '3DSensorCap')
    bst_figures('SetCurrentFigure', hFig, '3D');
end
% Update TF figure selection
if strcmpi(FileType, 'Timefreq')
    bst_figures('SetCurrentFigure', hFig, 'TF');
end
% Set figure visible
set(hFig, 'Visible', 'on');
bst_progress('stop');





