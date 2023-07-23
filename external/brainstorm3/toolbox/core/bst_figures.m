function varargout = bst_figures( varargin )
% BST_FIGURES: Manages all the visualization figures.
%
% USAGE :  
%    [hFig, iFig, isNewFig] = bst_figures('CreateFigure',     iDS, FigureId, CreateMode, Constrains)
%                             bst_figures('UpdateFigureName', hFig)
%        [hFigs,iFigs,iDSs] = bst_figures('GetFigure',        iDS,      FigureId)
%        [hFigs,iFigs,iDSs] = bst_figures('GetFigure',        DataFile, FigureId)
%        [hFigs,iFigs,iDSs] = bst_figures('GetFigure',        hFigure)

%                   [hFigs] = bst_figures('GetAllFigures')
% [hFigs,iFigs,iDSs,iSurfs] = bst_figures('GetFigureWithSurface', SurfFile)
% [hFigs,iFigs,iDSs,iSurfs] = bst_figures('GetFigureWithSurface', SurfFile, DataFile, FigType, Modality)
%        [hFigs,iFigs,iDSs] = bst_figures('GetFigureWithSurfaces')
%        [hFigs,iFigs,iDSs] = bst_figures('GetFiguresByType', figType)
% [hFigs,iFigs,iDSs,iSurfs] = bst_figures('GetFiguresForScouts')
%                             bst_figures('DeleteFigure', hFigure)
%                             bst_figures('DeleteFigure', hFigure, 'NoUnload')
%                             bst_figures('FireCurrentTimeChanged')
%                             bst_figures('FireCurrentFreqChanged')
%                             bst_figures('FireTopoOptionsChanged')
%                             bst_figures('SetCurrentFigure', hFig, Type)
%                             bst_figures('SetCurrentFigure', hFig)
%                             bst_figures('CheckCurrentFigure')
%                 [hNewFig] = bst_figures('CloneFigure', hFig)
%   [hClones, iClones, iDS] = bst_figures('GetClones', hFig)
%                             bst_figures('ReloadFigures')
%                             bst_figures('NavigatorKeyPress', hFig, keyEvent)
%                             bst_figures('ViewTopography',    hFig)
%                             bst_figures('ViewResults',       hFig)
%                             bst_figures('DockFigure',        hFig)
%                             bst_figures('ShowMatlabControls',    hFig, isMatlabCtrl)
%                             bst_figures('TogglePlotEditToolbar', hFig)
%                             bst_figures('SetSelectedRows',       RowNames)
%                             bst_figures('ToggleSelectedRow',     RowName)
%                             bst_figures('FireSelectedRowChanged')
%       [SelChan, iSelChan] = bst_figures('GetSelectedChannels', iDS)

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

macro_methodcall;
end


%% ===== CREATE FIGURE =====
% USAGE:  [hFig, iFig, isNewFig] = CreateFigure(iDS, FigureId)
%         [hFig, iFig, isNewFig] = CreateFigure(iDS, FigureId, 'AlwaysCreate')
%         [hFig, iFig, isNewFig] = CreateFigure(iDS, FigureId, 'AlwaysCreate', Constrains)
function [hFig, iFig, isNewFig] = CreateFigure(iDS, FigureId, CreateMode, Constrains)
    global GlobalData;
    hFig = [];
    iFig = [];
    % Parse inputs
    if (nargin < 4)
        Constrains = [];
    end
    if (nargin < 3) || isempty(CreateMode)
        CreateMode = 'Default';
    end
    isAlwaysCreate = strcmpi(CreateMode, 'AlwaysCreate');
    isDoLayout = 1;
    
    % If figure creation is not forced
    if ~isAlwaysCreate
        % Get all existing (valid) figure for this dataset
        [hFigures, iFigures] = GetFigure(iDS, FigureId);
        % If at least one valid figure was found
        if ~isempty(hFigures)
            % Refine selection for certain types of figures
            if ~isempty(Constrains) && ischar(Constrains) && ismember(FigureId.Type, {'Timefreq', 'Spectrum', 'Connect', 'Pac'})
                for i = 1:length(hFigures)
                    TfInfo = getappdata(hFigures(i), 'Timefreq');
                    if ~isempty(TfInfo) && file_compare(TfInfo.FileName, Constrains)
                        hFig(end+1) = hFigures(i);
                        iFig(end+1) = iFigures(i);
                    end
                end
                % If there are more than one figure possible, try to take the last used one
                if (length(hFig) > 1)
                    if ~isempty(GlobalData.CurrentFigure.TypeTF)
                        iLast = find(hFig == GlobalData.CurrentFigure.TypeTF);
                        if ~isempty(iLast)
                            hFig = hFig(iLast);
                            iFig = iFig(iLast);
                        end
                    end
                    % If could not find a valid figure
                    if (length(hFig) > 1)
                        hFig = hFig(1);
                        iFig = iFig(1);
                    end
                end
            % Topography: Recordings or Timefreq
            elseif ~isempty(Constrains) && ischar(Constrains) && strcmpi(FigureId.Type, 'Topography')
                for i = 1:length(hFigures)
                    TfInfo = getappdata(hFigures(i), 'Timefreq');
                    FileType = file_gettype(Constrains);
                    if (ismember(FileType, {'data', 'pdata'}) && isempty(TfInfo)) || ...
                       (ismember(FileType, {'timefreq', 'ptimefreq'}) && ~isempty(TfInfo) && file_compare(TfInfo.FileName, Constrains))
                        hFig = hFigures(i);
                        iFig = iFigures(i);
                        break;
                    end
                end
            % Data time series => Selected sensors must be the same
            elseif ~isempty(Constrains) && strcmpi(FigureId.Type, 'DataTimeSeries')
                for i = 1:length(hFigures)
                    TsInfo = getappdata(hFigures(i), 'TsInfo');
                    if isequal(TsInfo.RowNames, Constrains)
                        hFig = hFigures(i);
                        iFig = iFigures(i);
                        break;
                    end
                    %isDoLayout = 0;
                end
            % Result time series (scouts)
            elseif ~isempty(Constrains) && strcmpi(FigureId.Type, 'ResultsTimeSeries')
                for i = 1:length(hFigures)
                    TfInfo = getappdata(hFigures(i), 'Timefreq');
                    ResultsFiles = getappdata(hFigures(i), 'ResultsFiles');
                    if iscell(Constrains)
                        BaseFile = Constrains{1};
                    elseif ischar(Constrains)
                        BaseFile = Constrains;
                    end
                    FileType = file_gettype(BaseFile);
                    if (strcmpi(FileType, 'data') && isempty(TfInfo)) || ...
                       (strcmpi(FileType, 'timefreq') && ~isempty(ResultsFiles) && all(file_compare(ResultsFiles, Constrains))) || ...
                       (strcmpi(FileType, 'timefreq') && ~isempty(TfInfo) && file_compare(TfInfo.FileName, Constrains)) || ...
                       (ismember(FileType, {'results','link'}) && ~isempty(ResultsFiles) && all(file_compare(ResultsFiles, Constrains)))
                        hFig = hFigures(i);
                        iFig = iFigures(i);
                        break;
                    end
                end
            % Else: Use the first figure in the list (there can be more than one : for multiple views of same data)
            else
                hFig = hFigures(1);
                iFig = iFigures(1);
            end
        end
    end
       
    % No figure : create one
    isNewFig = isempty(hFig);
    if isNewFig
        % ==== CREATE FIGURE ====
        switch(FigureId.Type)
            case {'DataTimeSeries', 'ResultsTimeSeries'}
                hFig = figure_timeseries('CreateFigure', FigureId);
                FigHandles = db_template('DisplayHandlesTimeSeries');
            case 'Topography'
                hFig = figure_3d('CreateFigure', FigureId);
                FigHandles = db_template('DisplayHandlesTopography');
            case '3DViz'
                hFig = figure_3d('CreateFigure', FigureId);
                FigHandles = db_template('DisplayHandles3DViz');
            case 'MriViewer'
                % ===== ADDED FOR COMPATIBILITY =====
                VER = bst_get('MatlabVersion');
                if (VER.Version > 703)
                   hFig = figure_mri('CreateFigure', FigureId);
                else
                    warning('off', 'UIBUTTONGROUP:CHILDADD');
                    warning('off', 'MATLAB:childAddedCbk:CallbackWillBeOverwritten');
                    hFig = figure_mri_export('CreateFigure', FigureId);
                end
                %  ===================================
                set(hFig, 'Visible', 'off');
                drawnow
                % Get figure handles
                FigHandles = guidata(hFig);
            case 'Timefreq'
                hFig = figure_timefreq('CreateFigure', FigureId);
                FigHandles = db_template('DisplayHandlesTimefreq');
            case 'Spectrum'
                hFig = figure_spectrum('CreateFigure', FigureId);
                FigHandles = db_template('DisplayHandlesTimeSeries');
            case 'Pac'
                hFig = figure_pac('CreateFigure', FigureId);
                FigHandles = db_template('DisplayHandlesTimefreq');
            case 'Connect'
                hFig = figure_connect('CreateFigure', FigureId);
                FigHandles = db_template('DisplayHandlesTimefreq');
            otherwise
                error(['Invalid figure type : ', FigureId.Type]);
        end
       
        % ==== REGISTER FIGURE IN DATASET ====
        iFig = length(GlobalData.DataSet(iDS).Figure) + 1;
        GlobalData.DataSet(iDS).Figure(iFig)         = db_template('Figure');
        GlobalData.DataSet(iDS).Figure(iFig).Id      = FigureId;
        GlobalData.DataSet(iDS).Figure(iFig).hFigure = hFig;
        GlobalData.DataSet(iDS).Figure(iFig).Handles = FigHandles;
    end   
    
    % Find selected channels
    if ~isempty(GlobalData.DataSet(iDS).Figure(iFig).Id.Modality)
        % Get selected channels
        selChan = good_channel(GlobalData.DataSet(iDS).Channel, ...
                               GlobalData.DataSet(iDS).Measures.ChannelFlag, ...
                               GlobalData.DataSet(iDS).Figure(iFig).Id.Modality);
        % Make sure that something can be displayed in this figure
        if isempty(selChan) && ~isempty(GlobalData.DataSet(iDS).Measures.ChannelFlag)
            % Get the channels again, but ignoring the bad channels
            selChanAll = good_channel(GlobalData.DataSet(iDS).Channel, [], GlobalData.DataSet(iDS).Figure(iFig).Id.Modality);
            % Display an error message, depending on the results of this request
            if ~isempty(selChanAll)
                error(['Nothing to display: All the "' GlobalData.DataSet(iDS).Figure(iFig).Id.Modality '" channels are marked as bad.']);
            else
                % THAT IS FINE TO SHOW DATA WITHOUT ANY CHANNEL
                %error(['There are no "' GlobalData.DataSet(iDS).Figure(iFig).Id.Modality '" channel in this channel file']);
            end
        end
        % Save selected channels for this figure
        GlobalData.DataSet(iDS).Figure(iFig).SelectedChannels = selChan;
    else
        GlobalData.DataSet(iDS).Figure(iFig).SelectedChannels = [];
    end
    % Set figure name
    UpdateFigureName(hFig);
    % Tile windows
    if isDoLayout
        gui_layout('Update');
    end
end

    
%% ===== UPDATE FIGURE NAME =====
function UpdateFigureName(hFig)
    global GlobalData;
    % Get figure description in GlobalData
    [hFig, iFig, iDS] = GetFigure(hFig);
    
    % ==== FIGURE NAME ====
    % SubjectName/Condition/Modality
    figureName = '';
    % Get Subject name and Study name to define window title
    sStudy   = [];
    sSubject = [];
    % Get study
    if ~isempty(GlobalData.DataSet(iDS).StudyFile)
        [sStudy, iStudy] = bst_get('Study', GlobalData.DataSet(iDS).StudyFile);
    end
    % Get subject
    if ~isempty(GlobalData.DataSet(iDS).SubjectFile)
        sSubject = bst_get('Subject', GlobalData.DataSet(iDS).SubjectFile);
    end
    % Add subject name
    if ~isempty(sSubject) && ~isempty(sSubject.Name)
        figureName = [figureName sSubject.Name];
    end
    % Add condition name, data comment, and inverse comment
    if ~isempty(sStudy)
        isInterSubject = (iStudy == -2);
        % === CONDITION NAME ===
        if ~isempty(sStudy.Condition)
            for iCond = 1:length(sStudy.Condition)
                figureName = [figureName '/' sStudy.Condition{iCond}];
            end
        % Inter-subject node
        elseif isInterSubject
            figureName = [figureName 'Inter-subject'];
        end
        % === DATA FILE COMMENT ===
        % If a DataFile is defined for this dataset
        % AND there is MORE THAN ONE data files in this study => display data file comment
        if ~isempty(GlobalData.DataSet(iDS).DataFile) && (length(sStudy.Data) >= 2)
            % Look for current data file in study database structure
            iData = find(file_compare({sStudy.Data.FileName}, GlobalData.DataSet(iDS).DataFile), 1);
            % If a data file is found
            if ~isempty(iData)
                figureName = [figureName '/' sStudy.Data(iData).Comment];
            end
        end
        % === DATA/STAT FILE COMMENT ===
        if ~isempty(GlobalData.DataSet(iDS).DataFile) && (length(sStudy.Stat) >= 2)
            % Look for current stat file in study database structure
            iStat = find(file_compare({sStudy.Stat.FileName}, GlobalData.DataSet(iDS).DataFile), 1);
            % If a stat file is found
            if ~isempty(iStat)
                figureName = [figureName '/' sStudy.Stat(iStat).Comment];
            end
        end
        % === RESULTS NAME ===
        % If a ResultsFile is defined for this FIGURE
        % AND there is MORE THAN ONE results files in this study => display results file indice
        figResultsFile = getappdata(hFig, 'ResultsFile');
        if ~isempty(figResultsFile) && (length(sStudy.Result) >= 2)
            % Look for current results file in study database structure
            iResult = find(file_compare({sStudy.Result.FileName}, figResultsFile), 1);
            % If a data file is found
            if ~isempty(iResult)
                figureName = [figureName '/' sStudy.Result(iResult).Comment];
            end
        end
        % === RESULTS/STAT FILE COMMENT ===
        if ~isempty(figResultsFile) && (length(sStudy.Stat) >= 2)
            % Look for current stat file in study database structure
            iStat = find(file_compare({sStudy.Stat.FileName}, figResultsFile), 1);
            % If a stat file is found
            if ~isempty(iStat)
                figureName = [figureName '/' sStudy.Stat(iStat).Comment];
            end
        end
        % === TIME-FREQ FILE COMMENT ===
        TfInfo = getappdata(hFig, 'Timefreq');
        if ~isempty(TfInfo) && ~isempty(TfInfo.FileName) && (length(sStudy.Timefreq) >= 2)
            iPipe = find(TfInfo.FileName == '|', 1);
            if ~isempty(iPipe)
                TimefreqFile = TfInfo.FileName(1:iPipe-1);
                RefRowName = [' (' TfInfo.FileName(iPipe+1:end) ')'];
            else
                TimefreqFile = TfInfo.FileName;
                RefRowName = '';
            end
            % Look for current timefreq file in study database structure
            iTimefreq = find(file_compare({sStudy.Timefreq.FileName}, TimefreqFile), 1);
            % If a stat file is found
            if ~isempty(iTimefreq)
                figureName = [figureName '/' sStudy.Timefreq(iTimefreq).Comment, RefRowName];
            end
        end
        % Display mode
        if ~isempty(TfInfo)

        end
    end
    % Add Modality
    FigureId = GlobalData.DataSet(iDS).Figure(iFig).Id;
    if ~isempty(FigureId.Modality)
        figureNameModality = FigureId.Modality;
    else
        figureNameModality = '';
    end
    % If figureName is still empty : use the figure index
    if isempty(figureName)
        figureName = sprintf('#%d', iFig);
    end
    
    % Add prefix : figure type
    switch(FigureId.Type)
        case 'DataTimeSeries'
            % Get current montage
            TsInfo = getappdata(hFig, 'TsInfo');
            if isempty(TsInfo) || isempty(TsInfo.MontageName) || ~isempty(TsInfo.RowNames)
                strMontage = '';
            elseif strcmpi(TsInfo.MontageName, 'Average reference')
                strMontage = '(AvgRef)';
            else
                strMontage = ['(' TsInfo.MontageName ')'];
            end
            figureName = [figureNameModality strMontage '/TS: ' figureName];
        case 'ResultsTimeSeries'
            if ~isempty(figureNameModality)
                figureName = [figureNameModality(1:end-1) ': ' figureName];
            end
            % Matrix file: display the file name
            TsInfo = getappdata(hFig, 'TsInfo');
            if ~isempty(TsInfo) && ~isempty(TsInfo.FileName) && strcmpi(file_gettype(TsInfo.FileName), 'matrix')
                iMatrix = find(file_compare({sStudy.Matrix.FileName}, TsInfo.FileName), 1);
                if ~isempty(iMatrix)
                    figureName = [figureName '/' sStudy.Matrix(iMatrix).Comment];
                end
            end
            
        case 'Topography'
            figureName = [figureNameModality  '/TP: ' figureName];
        case '3DViz'
            figureName = [figureNameModality  '/3D: ' figureName];
        case 'MriViewer'
            figureName = [figureNameModality  '/MriViewer: ' figureName];
        case 'Timefreq'
            figureName = [figureNameModality  '/TF: ' figureName];
        case 'Spectrum'
            switch (FigureId.SubType)
                case 'TimeSeries'
                    figType = 'TS';
                case 'Spectrum'
                    figType = 'PSD';
                otherwise
                    figType = 'TF';
            end
            figureName = [figureNameModality '/' figType ': ' figureName];
        case 'Pac'
            figureName = [figureNameModality '/PAC: ' figureName];
        case 'Connect'
            figureName = [figureNameModality '/Connect: ' figureName];
        otherwise
            error(['Invalid figure type : ', FigureId.Type]);
    end
    
    % Update figure name
    set(hFig, 'Name', figureName);
end


%% ===== GET FIGURE =====
%Search for a registered figure in the GlobalData structure
% Usage : GetFigure(iDS, FigureId)
%         GetFigure(DataFile, FigureId)
%         GetFigure(hFigure)
% To avoid one search criteria, just set it to []
function [hFigures, iFigures, iDataSets] = GetFigure(varargin)
    global GlobalData;
    hFigures  = [];
    iFigures  = [];
    iDataSets = [];
    
    % Parse inputs
    % Call : GetFigure(DataFile, FigureId)
    if (nargin == 2) && ischar(varargin{1}) && isFigureId(varargin{2})
        DataFile = varargin{1};
        FigureId = varargin{2};       
        % Try to find a loaded dataset for current data
        iDS = find(file_compare({GlobalData.DataSet.DataFile}, DataFile));
        if isempty(iDS)
            return;
        end
        % Recursively call GetFigure function to find target figureId in the target loaded DataSet
        [hFigures, iFigures, iDataSets] = GetFigure(iDS(1), FigureId);
        
    % Call : GetFigure(iDS, FigureId)
    elseif (nargin == 2) && isnumeric(varargin{1}) && (varargin{1} <= length(GlobalData.DataSet)) && isFigureId(varargin{2})
        iDS      = varargin{1};
        FigureId = varargin{2};

        for iFig = 1:length(GlobalData.DataSet(iDS).Figure)
            if (compareFigureId(FigureId, GlobalData.DataSet(iDS).Figure(iFig).Id))
                hFigures  = [hFigures,  GlobalData.DataSet(iDS).Figure(iFig).hFigure];
                iFigures  = [iFigures,  iFig];
                iDataSets = [iDataSets, iDS];
            end
        end
        
    % Call : GetFigure(hFigure)
    elseif (nargin == 1) && isnumeric(varargin{1})
        hFig = varargin{1};
        
        for iDS = 1:length(GlobalData.DataSet)
            if ~isempty(GlobalData.DataSet(iDS).Figure)
                iFig = find([GlobalData.DataSet(iDS).Figure.hFigure] == hFig, 1);
                if ~isempty(iFig)
                    hFigures  = GlobalData.DataSet(iDS).Figure(iFig).hFigure;
                    iFigures  = iFig;
                    iDataSets = iDS;
                    break
                end
            end
        end
        
    % Invalid call
    else
        error(['Usage : GetFigure(iDS, FigureId)' 10 ...
               '        GetFigure(DataFile, FigureId)' 10 ...
               '        GetFigure(hFigure)']);
    end
end
    

%% ===== GET ALL FIGURES =====
% Return handles of all the figures registred by Brainstorm
function hFigures = GetAllFigures() %#ok<DEFNU>
    global GlobalData;
    hFigures  = [];
    % Process all DataSets
    for iDS = 1:length(GlobalData.DataSet)
        hFigures = [hFigures, GlobalData.DataSet(iDS).Figure.hFigure];
    end
end

   
%% ===== GET FIGURE WITH A SPECIFIC SURFACE =====
%  Usage : GetFigureWithSurface(SurfaceFile, DataFile, FigType, Modality)
%          GetFigureWithSurface(SurfaceFile)
%          GetFigureWithSurface(SurfaceFiles)
function [hFigures, iFigures, iDataSets, iSurfaces] = GetFigureWithSurface(SurfaceFile, DataFile, FigType, Modality) %#ok<DEFNU>
    global GlobalData;
    hFigures  = [];
    iFigures  = [];
    iDataSets = [];
    iSurfaces = [];
    % Parse inputs
    if (nargin < 4)
        DataFile = '';
        FigType  = '3DViz';
        Modality = '';
    end
    % Process all DataSets
    for iDS = 1:length(GlobalData.DataSet)
        % Process all figures of this dataset
        for iFig = 1:length(GlobalData.DataSet(iDS).Figure)
            Figure = GlobalData.DataSet(iDS).Figure(iFig);
            % Look only in 3DViz figures (there cannot be surfaces displayed in other widow types)
            % and figures that have the appropriate Modality
            if strcmpi(Figure.Id.Type, FigType) && (isempty(Modality) || strcmpi(Figure.Id.Modality, Modality))
                % Get surfaces list
                TessInfo = getappdata(Figure.hFigure, 'Surface');
                % Look for surface
                for iTess = 1:length(TessInfo)
                    % Check if the (or one of the) surface file is valid
                    if iscell(SurfaceFile)
                        isSurfFileOk = 0;
                        i = 1;
                        while (i <= length(SurfaceFile) && ~isSurfFileOk)
                            isSurfFileOk = file_compare(TessInfo(iTess).SurfaceFile, SurfaceFile{i});
                            i = i + 1;
                        end
                    else
                        isSurfFileOk = file_compare(TessInfo(iTess).SurfaceFile, SurfaceFile);
                    end
                    % If figure is accepted: add it to the list
                    if isSurfFileOk && (isempty(DataFile) ...
                                        || file_compare(TessInfo(iTess).DataSource.FileName, DataFile))
                        hFigures  = [hFigures,  Figure.hFigure];
                        iFigures  = [iFigures,  iFig];
                        iDataSets = [iDataSets, iDS];
                        iSurfaces = [iSurfaces, iTess];
                    end
                end
            end
        end
    end
end    


%% ===== GET FIGURES BY TYPE =====
function [hFigures, iFigures, iDataSets] = GetFiguresByType(figType)
    global GlobalData;
    hFigures  = [];
    iFigures  = [];
    iDataSets = [];
    % Process all DataSets
    for iDS = 1:length(GlobalData.DataSet)
        % Process all figures of this dataset
        for iFig = 1:length(GlobalData.DataSet(iDS).Figure)
            % If figure has the right type : return it
            if (ischar(figType) && strcmpi(GlobalData.DataSet(iDS).Figure(iFig).Id.Type, figType)) || (iscell(figType) && ismember(GlobalData.DataSet(iDS).Figure(iFig).Id.Type, figType))
                hFigures  = [hFigures,  GlobalData.DataSet(iDS).Figure(iFig).hFigure];
                iFigures  = [iFigures,  iFig];
                iDataSets = [iDataSets, iDS];
            end
        end
    end
end


%% ===== GET FIGURES FOR SCOUTS =====
% Get all the Brainstorm 3DVIz figures that have a cortex surface displayed
%  Usage : GetFiguresForScouts()
function [hFigures, iFigures, iDataSets, iSurfaces] = GetFiguresForScouts()
    global GlobalData;
    hFigures  = [];
    iFigures  = [];
    iDataSets = [];
    iSurfaces = [];
    % Process all DataSets
    for iDS = 1:length(GlobalData.DataSet)
        % Process all figures of this dataset
        for iFig = 1:length(GlobalData.DataSet(iDS).Figure)
            Figure = GlobalData.DataSet(iDS).Figure(iFig);
            % If 3DViz figure
            if strcmpi(Figure.Id.Type, '3DViz')
                % Look for a cortex surface in figure
                TessInfo = getappdata(Figure.hFigure, 'Surface');
                iCortex  = find(strcmpi({TessInfo.Name}, 'cortex'));
                iAnatomy = find(strcmpi({TessInfo.Name}, 'Anatomy'));
                iValidSurface = [iCortex, iAnatomy];
                % If a cortex is found : add figure to returned figures list
                if ~isempty(iValidSurface) 
                    hFigures  = [hFigures,  Figure.hFigure];
                    iFigures  = [iFigures,  iFig];
                    iDataSets = [iDataSets, iDS];
                    iSurfaces = [iSurfaces, iValidSurface(1)];
                end
            end
        end
    end
end    


%% ===== GET FIGURES WITH SURFACES ======
% Get all the Brainstorm 3DVIz figures that have at list on surface displayed in them
%  Usage : GetFigureWithSurfaces()
function [hFigs,iFigs,iDSs] = GetFigureWithSurfaces() %#ok<DEFNU>
    hFigs = [];
    iFigs = [];
    iDSs  = [];
    % Get 3D Viz figures
    [hFigs3D, iFigs3D, iDSs3D] = GetFiguresByType('3DViz');
    % Loop to find figures with surfaces
    for i = 1:length(hFigs3D)
        if ~isempty(getappdata(hFigs3D(i), 'Surface'))
            hFigs(end+1) = hFigs3D(i);
            iFigs(end+1) = iFigs3D(i);
            iDSs(end+1)  = iDSs3D(i);
        end
    end
end

%% ===== GET FIGURE HANDLES =====
function [Handles,iFig,iDS] = GetFigureHandles(hFig) %#ok<DEFNU>
    global GlobalData;
    % Get figure description
    [hFig,iFig,iDS] = GetFigure(hFig);
    if ~isempty(iDS)
        % Return handles
        Handles = GlobalData.DataSet(iDS).Figure(iFig).Handles;
    else
        warning('Figure is not registered in Brainstorm.');
        Handles = [];
    end
end

%% ===== SET FIGURE HANDLES =====
function [Handles,iFig,iDS] = SetFigureHandles(hFig, Handles) %#ok<DEFNU>
    global GlobalData;
    % Get figure description
    [hFig,iFig,iDS] = GetFigure(hFig);
    if isempty(iDS)
        error('Figure is not registered in Brainstorm');
    end
    % Return handles
    GlobalData.DataSet(iDS).Figure(iFig).Handles = Handles;
end


%% ===== DELETE FIGURE =====
%  Usage : DeleteFigure(hFigure)
%          DeleteFigure(..., 'NoUnload') : do not unload the corresponding datasets
%          DeleteFigure(..., 'NoLayout') : do not call the layout manager
function DeleteFigure(hFigure, varargin) %#ok<DEFNU>
    % Get GlobalData
    global GlobalData;
    if isempty(GlobalData)
        warning('Brainstorm is not started.');
        delete(hFigure);
        return;
    end
    % Parse inputs
    NoUnload = any(strcmpi(varargin, 'NoUnload'));
    NoLayout = any(strcmpi(varargin, 'NoLayout'));
    isKeepAnatomy = 1;

    % Find figure index in GlobalData structure
    [hFig, iFig, iDS] = GetFigure(hFigure);
    % If figure is registered
    if isempty(iFig) 
        warning('Figure is not registered in Brainstorm.');
        delete(hFigure);
        return;
    end
    % Get figure type
    Figure = GlobalData.DataSet(iDS).Figure(iFig);

    % ===== MRI VIEWER =====
    % Check for modifications of the MRI (MRI Viewer figures only)
    if strcmpi(Figure.Id.Type, 'MriViewer') && Figure.Handles.isModified
        % If MRI was modified : ask to save the changes
        if java_dialog('confirm', 'MRI was modified, save changes ?', 'MRI Viewer')
            % Save MRI
            isCloseAccepted = figure_mri('SaveMri', hFig);
            % If the save function refused to close the window
            if ~isCloseAccepted
                return
            end
        end
        % Unload anatomy
        isKeepAnatomy = 0;
    end
    
    % Check if surfaces were modified
    if ~isempty(GlobalData.Surface) && any([GlobalData.Surface.isAtlasModified])
        % Force unload of the anatomy
        isKeepAnatomy = 0;
    end
    % Remove figure reference from GlobalData
    GlobalData.DataSet(iDS).Figure(iFig) = [];
    
    % Check if figure was the current TF figure
    wasCurTf = isequal(GlobalData.CurrentFigure.TypeTF, hFigure);
    % Clear selected figure
    GlobalData.CurrentFigure.Last   = setdiff(GlobalData.CurrentFigure.Last,   hFigure);
    GlobalData.CurrentFigure.Type3D = setdiff(GlobalData.CurrentFigure.Type3D, hFigure);
    GlobalData.CurrentFigure.Type2D = setdiff(GlobalData.CurrentFigure.Type2D, hFigure);
    GlobalData.CurrentFigure.TypeTF = setdiff(GlobalData.CurrentFigure.TypeTF, hFigure);
    % If the figure is a 3DViz figure
    if ishandle(hFigure) && isappdata(hFigure, 'Surface')
        % Signals the "Surfaces" and "Scouts" panel that a figure was closed
        panel_surface('UpdatePanel');
        % Remove scouts references
        panel_scout('RemoveScoutsFromFigure', hFigure);
        % Reset "Coordinates" panel
        if gui_brainstorm('isTabVisible', 'Coordinates')
            panel_coordinates('RemoveSelection');
        end
        % Reset "Dipoles" panel
        if gui_brainstorm('isTabVisible', 'Dipoles')
        	panel_dipoles('UpdatePanel');
        end
    end
    % If figure is an OpenGL connectivty graph: call the destructor
    if strcmpi(Figure.Id.Type, 'Connect')
        figure_connect('Dispose', hFigure);
    end
    % Delete graphic object
    if ishandle(hFigure)
        delete(hFigure);
    end
    % Unload unused datasets
    if ~NoUnload
        if isKeepAnatomy
            bst_memory('UnloadAll', 'KeepMri', 'KeepSurface');
        else
            bst_memory('UnloadAll');
        end
    end   
    % Update layout
    if ~NoLayout
        gui_layout('Update');
    end
    % If closed figure was a TimeSeries one: update time series scales
    if strcmpi(Figure.Id.Type, 'DataTimeSeries')
        % === Unformize time series scales if required ===
        isSynchro = bst_get('UniformizeTimeSeriesScales');
        if ~isempty(isSynchro) && (isSynchro == 1)
            figure_timeseries('UniformizeTimeSeriesScales', 1); 
        end
    end
    % If closed figure was the selected time-freq figure, and Display panel still visible
    %if strcmpi(Figure.Id.Type, 'Timefreq') || strcmpi(Figure.Id.Type, 'Spectrum') || strcmpi(Figure.Id.Type, 'Connect')
    if wasCurTf && gui_brainstorm('isTabVisible', 'Display')
        % Finds the next Timefreq figure
        FindCurrentTimefreqFigure();
    end
end
    

%% ===== FIRE CURRENT TIME CHANGED =====
%Call the 'CurrentTimeChangedCallback' function for all the registered figures
function FireCurrentTimeChanged(ForceTime)
    global GlobalData;
    if (nargin < 1) || isempty(ForceTime)
        ForceTime = 0;
    end
    for iDS = 1:length(GlobalData.DataSet)
        for iFig = 1:length(GlobalData.DataSet(iDS).Figure)
            sFig = GlobalData.DataSet(iDS).Figure(iFig);
            % Only fires for currently visible displayed figures, AND not static
            if strcmpi(get(sFig.hFigure, 'Visible'), 'off') || (~ForceTime && getappdata(sFig.hFigure, 'isStatic'))
                continue;
            end
            % Notice figure
            switch (sFig.Id.Type)
                case {'DataTimeSeries', 'ResultsTimeSeries'}
                    figure_timeseries('CurrentTimeChangedCallback', iDS, iFig);
                case 'Topography'
                    figure_topo('CurrentTimeChangedCallback', iDS, iFig);
                case '3DViz'
                    panel_surface('UpdateSurfaceData', sFig.hFigure);
                    if gui_brainstorm('isTabVisible', 'Dipoles')
                        panel_dipoles('CurrentTimeChangedCallback', sFig.hFigure);
                    end
                case 'MriViewer'
                    panel_surface('UpdateSurfaceData', sFig.hFigure);
                case 'Timefreq'
                    figure_timefreq('CurrentTimeChangedCallback', sFig.hFigure);
                case 'Spectrum'
                    figure_spectrum('CurrentTimeChangedCallback', sFig.hFigure);
                case 'Pac'
                    figure_pac('CurrentTimeChangedCallback', sFig.hFigure);
                case 'Connect'
                    figure_connect('CurrentTimeChangedCallback', sFig.hFigure);
            end
        end 
    end
end


%% ===== FIRE CURRENT FREQUENCY CHANGED =====
%Call the 'CurrentFreqChangedCallback' function for all the registered figures
function FireCurrentFreqChanged() %#ok<DEFNU>
    global GlobalData;
    for iDS = 1:length(GlobalData.DataSet)
        % If no time-frequency information: skip
        if isempty(GlobalData.DataSet(iDS).Timefreq)
            continue;
        end
        % Process all figures
        for iFig = 1:length(GlobalData.DataSet(iDS).Figure)
            sFig = GlobalData.DataSet(iDS).Figure(iFig);
            % Only fires for currently visible displayed figures, AND not static
            if strcmpi(get(sFig.hFigure, 'Visible'), 'off') || isempty(getappdata(sFig.hFigure, 'Timefreq')) || getappdata(sFig.hFigure, 'isStaticFreq')
                continue;
            end
            % Notice figures
            switch (sFig.Id.Type)
                case {'DataTimeSeries', 'ResultsTimeSeries'}
                    % Nothing to do
                case 'Topography'
                    figure_topo('CurrentFreqChangedCallback', iDS, iFig);
                case '3DViz'
                    %panel_surface('UpdateSurfaceData', sFig.hFigure);
                    panel_surface('CurrentFreqChangedCallback', iDS, iFig);
                case 'MriViewer'
                    %panel_surface('UpdateSurfaceData', sFig.hFigure);
                    panel_surface('CurrentFreqChangedCallback', iDS, iFig);
                case 'Timefreq'
                    figure_timefreq('CurrentFreqChangedCallback', sFig.hFigure);
                case 'Spectrum'
                    figure_spectrum('CurrentFreqChangedCallback', sFig.hFigure);
                case 'Pac'
                    % Nothing
                case 'Connect'
                    bst_progress('start', 'Connectivity graph', 'Reloading connectivity graph...');
                    figure_connect('CurrentFreqChangedCallback', sFig.hFigure);
                    bst_progress('stop');
            end
        end
    end
end


%% ===== FIRE TOPO LAYOUT OPTIONS CHANGED =====
function FireTopoOptionsChanged(isLayout) %#ok<DEFNU>
    global GlobalData;
    % Loop on all the datasets
    for iDS = 1:length(GlobalData.DataSet)
        % Process all figures
        for iFig = 1:length(GlobalData.DataSet(iDS).Figure)
            sFig = GlobalData.DataSet(iDS).Figure(iFig);
            if strcmpi(get(sFig.hFigure, 'Visible'), 'off') || ~strcmpi(sFig.Id.Type, 'Topography') || ...
               (isLayout && ~strcmpi(sFig.Id.SubType, '2DLayout')) || (~isLayout && strcmpi(sFig.Id.SubType, '2DLayout'))
                continue
            end
            GlobalData.DataSet(iDS).Figure(iFig).Handles.DataMinMax = [];
            figure_topo('UpdateTopoPlot', iDS, iFig);
        end
    end
end


%% ===== SET CURRENT FIGURE =====
% Usage:  bst_figures('SetCurrentFigure', hFig, Type);
%         bst_figures('SetCurrentFigure', hFig);
function SetCurrentFigure(hFig, Type)
    global GlobalData;
    % No type specified: sets only the last figure selected
    if (nargin < 2) || isempty(Type)
        Type = 'Last';
    else
        Type = ['Type' Type];
    end
    % Check if figure changed
    oldFig = GlobalData.CurrentFigure.Last;
    oldFigType = GlobalData.CurrentFigure.(Type);
    if ~isempty(hFig) && ~isempty(GlobalData.CurrentFigure.Last) && ~isempty(oldFigType) && (oldFigType == hFig) && (GlobalData.CurrentFigure.Last == hFig)
        return
    end
    % Update GlobalData structure
    GlobalData.CurrentFigure.(Type) = hFig;
    GlobalData.CurrentFigure.Last = hFig;

    % === FIRE EVENT FOR ALL PANELS ===
    switch (Type)
        case 'Type2D'
            panel_record('CurrentFigureChanged_Callback', hFig);
            
        case 'Type3D'
            % Only when figure changed (within the figure type)
            if ~isempty(hFig) && ~isequal(oldFigType, hFig)
                panel_surface('CurrentFigureChanged_Callback');
                panel_scout( 'CurrentFigureChanged_Callback', oldFig, hFig);
                if gui_brainstorm('isTabVisible', 'Coordinates')
                    panel_coordinates('CurrentFigureChanged_Callback');
                end
                if gui_brainstorm('isTabVisible', 'Dipoles')
                    panel_dipoles('CurrentFigureChanged_Callback', hFig);
                end
            end
        case 'TypeTF'
            % Only when figure changed (whatever the type of the figure is)
            if ~isempty(hFig) && ~isequal(oldFigType, hFig)
                panel_display('CurrentFigureChanged_Callback', hFig);
            end
    end

    % === SELECT CORRESPONDING TREE NODE ===
    if ~isempty(hFig) && ~isequal(oldFig, hFig)
        % Get all the data accessible in this figure
        SubjectFile = getappdata(hFig, 'SubjectFile');
        StudyFile   = getappdata(hFig, 'StudyFile');
        DataFile    = getappdata(hFig, 'DataFile');
        ResultsFile = getappdata(hFig, 'ResultsFile');
        TfInfo      = getappdata(hFig, 'Timefreq');
        % Try to select a node in the tree
        if ~isempty(TfInfo) && ~isempty(TfInfo.FileName)
            [tmp__, iStudy, iTimefreq] = bst_get('TimefreqFile', TfInfo.FileName);
            if ~isempty(iStudy)
                if ~isempty(strfind(TfInfo.FileName, '_psd')) || ~isempty(strfind(TfInfo.FileName, '_fft'))
                    panel_protocols('SelectNode', [], 'spectrum', iStudy, iTimefreq);
                else
                    panel_protocols('SelectNode', [], 'timefreq', iStudy, iTimefreq);
                end
            % File not found: Try in stat files
            else
                [tmp__, iStudy, iStat] = bst_get('StatFile', TfInfo.FileName);
                if ~isempty(iStudy)
                    panel_protocols('SelectNode', [], 'ptimefreq', iStudy, iStat);
                end
            end
        elseif ~isempty(ResultsFile)
            if iscell(ResultsFile)
                ResultsFile = ResultsFile{1};
            end
            [tmp__, iStudy, iResult] = bst_get('ResultsFile', ResultsFile);
            if ~isempty(iStudy)
                if isequal(ResultsFile(1:4), 'link')
                    panel_protocols('SelectNode', [], 'link', iStudy, iResult);
                else
                    panel_protocols('SelectNode', [], 'results', iStudy, iResult);
                end
            % ResultsFile not found: Try in stat files
            else
                [tmp__, iStudy, iStat] = bst_get('StatFile', ResultsFile);
                if ~isempty(iStudy)
                    panel_protocols('SelectNode', [], 'presults', iStudy, iStat);
                else
                    [tmp__, iStudy, iTimefreq] = bst_get('TimefreqFile', ResultsFile);
                    if ~isempty(iStudy)
                        panel_protocols('SelectNode', [], 'presults', iStudy, iTimefreq);
                    end
                end
            end
        elseif ~isempty(DataFile)
            if iscell(DataFile)
                DataFile = DataFile{1};
            end
            [tmp__, iStudy, iData] = bst_get('DataFile', DataFile);
            if ~isempty(iStudy)
                panel_protocols('SelectNode', [], 'data', iStudy, iData);
            % DataFile not found: Try in stat files
            else
                [tmp__, iStudy, iStat] = bst_get('StatFile', DataFile);
                if ~isempty(iStudy)
                    panel_protocols('SelectNode', [],'pdata', iStudy, iStat);
                end
            end
        elseif ~isempty(StudyFile)
            [tmp__, iStudy] = bst_get('Study', StudyFile);
            panel_protocols('SelectNode', [], 'studysubject', iStudy, -1);
        elseif ~isempty(SubjectFile)
            [tmp__, iSubject] = bst_get('Subject', SubjectFile);
            panel_protocols('SelectNode', [], 'subject', -1, iSubject);
        end
    end
end

%% ===== GET CURRENT FIGURE =====
% Usage:  [hFig,iFig,iDS] = bst_figures('GetCurrentFigure', '2D');
%         [hFig,iFig,iDS] = bst_figures('GetCurrentFigure', '3D');
%         [hFig,iFig,iDS] = bst_figures('GetCurrentFigure', 'TF');
%         [hFig,iFig,iDS] = bst_figures('GetCurrentFigure');
function [hFig,iFig,iDS] = GetCurrentFigure(Type)
	global GlobalData;
    hFig = [];
    iFig = [];
    iDS  = [];
    % No type specified: return the last figure selected
    if (nargin < 1) || isempty(Type)
        Type = 'Last';
    else
        Type = ['Type' Type];
    end
    % Remove selected point from current figure
    if ~isempty(GlobalData.CurrentFigure.(Type)) && ishandle(GlobalData.CurrentFigure.(Type))
        hFig = GlobalData.CurrentFigure.(Type);
    else
        return
    end
    % Get information from figure, if necessary
    if (nargout > 1)
        [hFig,iFig,iDS] = GetFigure(hFig);
    end
end


%% ===== FIND CURRENT FIGURE =====
% Tries to guess what the current figure that contains timefreq information
function [hFig,iFig,iDS] = FindCurrentTimefreqFigure()
    global GlobalData;
    % Tries to use the current referenced figure
    [hFig,iFig,iDS] = GetCurrentFigure('TF');
    if ~isempty(hFig)
        return;
    end
    % Else: Look for another figure
    for iDS = 1:length(GlobalData.DataSet)
        for iFig = 1:length(GlobalData.DataSet(iDS).Figure)
            h = GlobalData.DataSet(iDS).Figure(iFig).hFigure;
            if ~ishandle(h) || ~isappdata(h, 'Timefreq')
                continue;
            end
            if ~isempty(getappdata(h, 'Timefreq'))
                hFig = h;
                % Set the current figure to this figure
                SetCurrentFigure(hFig, 'TF');
                return;
            end
        end
    end
    hFig = [];
    iFig = [];
    iDS = [];
end


%% ===== CHECK CURRENT FIGURE =====
function CheckCurrentFigure()
    global GlobalData;
    % Get current figure
    hFig = gcf;
    if isappdata(hFig, 'hasMoved')
        GlobalData.CurrentFigure.Last = hFig;
    end
end

%% ===== CLONE FIGURE =====
function hNewFig = CloneFigure(hFig)
    global GlobalData;
    % Get figure description in GlobalData
    [hFig, iFig, iDS] = GetFigure(hFig);
    if isempty(iFig)
        warning('Brainstorm:FigureNotRegistered','Figure is not registered in Brainstorm.');
        return;
    end
    FigureId = GlobalData.DataSet(iDS).Figure(iFig).Id;
    % Create new empty figure
    [hNewFig, iNewFig] = bst_figures('CreateFigure', iDS, FigureId, 'AlwaysCreate');
    % Get original figure appdata
    AppData = getappdata(hFig);
    % Remove unwanted objects from the AppData structure
    for field = fieldnames(AppData)'
        if ~isempty(strfind(field{1}, 'uitools')) || isjava(AppData.(field{1})) || ismember(field{1}, {'SubplotDefaultAxesLocation', 'SubplotDirty'})
            AppData = rmfield(AppData, field{1});
            continue;
        end
    end
        
    % ===== 3D FIGURES =====
    if strcmpi(FigureId.Type, '3DViz')
        % Remove all children objects (axes are automatically created)
        delete(get(hNewFig, 'Children'));
        % Copy all the figure objects
        hChild = get(hFig, 'Children');
        copyobj(hChild, hNewFig);
        % Copy figure colormap
        set(hNewFig, 'Colormap', get(hFig, 'Colormap'));
        % Copy Figure UsageData
        set(hNewFig, 'UserData', get(hFig, 'UserData'));

        % === Copy and update figure AppData ===
        % Get patches handles
        hAxes    = findobj(hFig,    'tag', 'Axes3D');
        hNewAxes = findobj(hNewFig, 'tag', 'Axes3D');
        hPatches    = [findobj(hAxes,    'type', 'patch')',  findobj(hAxes,    'type', 'surf')'];
        hNewPatches = [findobj(hNewAxes, 'type', 'patch')',  findobj(hNewAxes, 'type', 'surf')'];
        % Update handles
        for iSurf = 1:length(AppData.Surface)
            iPatch = find(AppData.Surface(iSurf).hPatch == hPatches);
            AppData.Surface(iSurf).hPatch = hNewPatches(iPatch);
        end
        % Update new figure appdata
        fieldList = fieldnames(AppData);
        for iField = 1:length(fieldList)
            setappdata(hNewFig, fieldList{iField}, AppData.(fieldList{iField}));
        end

        % === 2D/3D FIGURES ===
        % Update sensor markers and labels
        GlobalData.DataSet(iDS).Figure(iNewFig).Handles.hSensorMarkers = findobj(hNewAxes, 'tag', 'SensorMarker');
        GlobalData.DataSet(iDS).Figure(iNewFig).Handles.hSensorLabels  = findobj(hNewAxes, 'tag', 'SensorsLabels');
        % Delete scouts
        delete(findobj(hNewAxes, 'Tag', 'ScoutLabel'));
        delete(findobj(hNewAxes, 'Tag', 'ScoutMarker'));
        delete(findobj(hNewAxes, 'Tag', 'ScoutPatch'));
        delete(findobj(hNewAxes, 'Tag', 'ScoutContour'));
        % Update current figure selection
        if strcmpi(FigureId.Type, '3DViz') || strcmpi(FigureId.SubType, '3DSensorCap')
            SetCurrentFigure(hNewFig, '3D');
        else
            SetCurrentFigure(hNewFig);
        end
        % Redraw scouts if any
        panel_scout('PlotScouts', [], hNewFig);
        panel_scout('UpdateScoutsDisplay', hNewFig);

        % === RESIZE ===
        % Call Resize and ColormapChanged callback to reposition correctly the colorbar
        figure_3d(get(hNewFig, 'ResizeFcn'), hNewFig, []);
        figure_3d('ColormapChangedCallback', iDS, iNewFig);
        % Copy position and size of the initial figure (if no automatic repositioning)
        if isempty(bst_get('Layout', 'WindowManager'))
            newPos = get(hFig, 'Position') + [10 -10 0 0];
            set(hNewFig, 'Position', newPos);
        end
        % Update Surfaces panel
        panel_surface('UpdatePanel');
        
    % ===== TIME SERIES =====
    elseif strcmpi(FigureId.Type, 'DataTimeSeries')
        % Update new figure appdata
        fieldList = fieldnames(AppData);
        for iField = 1:length(fieldList)
            setappdata(hNewFig, fieldList{iField}, AppData.(fieldList{iField}));
        end
        GlobalData.DataSet(iDS).Figure(iNewFig).SelectedChannels = GlobalData.DataSet(iDS).Figure(iFig).SelectedChannels;
        % Update figure selection
        bst_figures('SetCurrentFigure', hNewFig, '2D');
        % Update figure
        figure_timeseries('PlotFigure', iDS, iNewFig);
    end
    % Make new figure visible
    set(hNewFig, 'Visible', 'on');
end


%% ===== GET CLONES =====
function [hClones, iClones, iDS] = GetClones(hFig)
    global GlobalData;
    % Get figure description in GlobalData
    [hFig, iFig, iDS] = GetFigure(hFig);
    if isempty(iFig)
        warning('Brainstorm:FigureNotRegistered','Figure is not registered in Brainstorm.');
        return;
    end
    % Get all figures that have the same FigureId in the same DataSet
    [hClones, iClones, iDS] = GetFigure(iDS, GlobalData.DataSet(iDS).Figure(iFig).Id);
    % Remove input figure
    iDel = find(hClones == hFig);
    hClones(iDel) = [];
    iClones(iDel) = [];
    iDS(iDel) = [];
    % Remove figures that do not have the same ResultsFile displayed
    ResultsFile = getappdata(hFig, 'ResultsFile');
    if ~isempty(ResultsFile)
        iDel = [];
        for i = 1:length(hClones)
            cloneResultsFile = getappdata(hClones(i), 'ResultsFile');
            if~strcmpi(ResultsFile, cloneResultsFile)
                iDel = [iDel i];
                break
            end
        end
        if ~isempty(iDel)
            hClones(iDel) = [];
            iClones(iDel) = [];
            iDS(iDel) = [];
        end
    end
end



%% ======================================================================
%  ===== CALLBACK SHARED BY ALL FIGURES =================================
%  ======================================================================
%% ===== NAVIGATOR KEYPRESS =====
function NavigatorKeyPress( hFig, keyEvent ) %#ok<DEFNU>
    % Get figure description
    [hFig, iFig, iDS] = GetFigure(hFig);
    if isempty(hFig)
        return
    end

    % ===== PROCESS BY KEYS =====
    switch (keyEvent.Key)
        % === DATABASE NAVIGATOR ===
        case 'f1'
            if ismember('shift', keyEvent.Modifier)
                bst_navigator('DbNavigation', 'PreviousSubject', iDS);
            else
                bst_navigator('DbNavigation', 'NextSubject', iDS);
            end
        case 'f2'
            if ismember('shift', keyEvent.Modifier)
                bst_navigator('DbNavigation', 'PreviousCondition', iDS);
            else
                bst_navigator('DbNavigation', 'NextCondition', iDS);
            end
        case 'f3'
            if ismember('shift', keyEvent.Modifier)
                bst_navigator('DbNavigation', 'PreviousData', iDS);
            else
                bst_navigator('DbNavigation', 'NextData', iDS);
            end
        case 'f4'
            %             if ismember('shift', keyEvent.Modifier)
            %                 bst_navigator('DbNavigation', 'PreviousResult', iDS);
            %             else
            %                 bst_navigator('DbNavigation', 'NextResult', iDS);
            %             end
    end
end


%% ===== VIEW TOPOGRAPHY =====
function ViewTopography(hFig)
    global GlobalData;
    % Get figure description
    [hFig, iFig, iDS] = GetFigure(hFig);
    if isempty(iDS) || isempty(GlobalData.DataSet(iDS).ChannelFile)
        return
    end
    % Get figure type
    FigureType  = GlobalData.DataSet(iDS).Figure(iFig).Id.Type;
    Modality = [];
    switch(FigureType)
        case 'Topography'
            % Nothing to do
            return
        case {'3DViz', 'DataTimeSeries', 'ResultsTimeSeries'}
            % Get all the figure information 
            DataFile = getappdata(hFig, 'DataFile');
            Modality = GlobalData.DataSet(iDS).Figure(iFig).Id.Modality;
            % If current modality is not MEG or EEG, cannot display topography: get default modality
            if ~ismember(Modality, {'MEG','MEG GRAD','MEG MAG','EEG','ECOG','SEEG'}) && ~isempty(DataFile)
                % Get displayable sensor types
                [AllMod, DispMod, Modality] = bst_get('ChannelModalities', DataFile);
            end
        case {'Timefreq', 'Spectrum', 'Pac'}
            % Get time freq information
            TfInfo = getappdata(hFig, 'Timefreq');
            DataFile = TfInfo.FileName;
            iTimefreq = bst_memory('GetTimefreqInDataSet', iDS, DataFile);
            % Switch depending on the data type
            switch (GlobalData.DataSet(iDS).Timefreq(iTimefreq).DataType)
                case 'data'
                    % Get the type of the sensor that is currently displayed
                    iSelChan = find(strcmpi({GlobalData.DataSet(iDS).Channel.Name}, TfInfo.RowName));
                    if ~isempty(iSelChan)
                        Modality = GlobalData.DataSet(iDS).Channel(iSelChan).Type;
                    else
                        Modality = GlobalData.DataSet(iDS).Figure(iFig).Id.Modality;
                    end
                otherwise
                    error(['This files contains information about cortical sources or regions of interest.' 10 ...
                           'Cannot display it as a sensor topography.']);
            end
        case 'Connect'
            warning('todo');
    end
    % Call view data function
    if ~isempty(DataFile) && ~isempty(Modality)
        view_topography(DataFile, Modality);
    end
end


%% ===== VIEW RESULTS =====
function ViewResults(hFig) %#ok<DEFNU>
    global GlobalData;
    % Get figure description
    [hFig, iFig, iDS] = GetFigure(hFig);
    if isempty(iDS)
        return
    end
    % Get all the figure information 
    DataFile    = getappdata(hFig, 'DataFile');
    ResultsFile = getappdata(hFig, 'ResultsFile');
    Modality    = GlobalData.DataSet(iDS).Figure(iFig).Id.Modality;
    % Display results only for figures without results
    if ~isempty(ResultsFile) || isempty(DataFile)
        return
    end
    % === RESULTS FILE ===
    % Get first available results files for figure data file
    [sStudy, iStudy, iResults] = bst_get('ResultsForDataFile', DataFile);
    if isempty(iResults)
        return
    end
    ListResultsFiles = {sStudy.Result(iResults).FileName};
    % Try to find a results file with the same modality
    if ~isempty(Modality)
        ResultsFile = '';
        for i = 1:length(ListResultsFiles)
            if ~isempty(strfind(ListResultsFiles{i}, ['_' Modality '_']))
                ResultsFile = ListResultsFiles{i};
                break;
            end
        end
        % Check if a ResultsFile is found
        if isempty(ResultsFile)
            java_dialog('warning', ['No sources computed for modality "' Modality '".'],'View sources');
            return
        end
    else
        ResultsFile = ListResultsFiles{1};
    end
    % Call view results function
    view_surface_data([], ResultsFile, Modality);
end


%% ===== DOCK FIGURE =====
function DockFigure(hFig, isDocked) %#ok<DEFNU>
    if isDocked
        set(hFig, 'WindowStyle', 'docked');
        ShowMatlabControls(hFig, 1);
        plotedit('off');
    else
        set(hFig, 'WindowStyle', 'normal');
        ShowMatlabControls(hFig, 0);
    end
    gui_layout('Update');
end

    
%% ===== SHOW MATLAB CONTROLS =====
function ShowMatlabControls(hFig, isMatlabCtrl)
    if ~isMatlabCtrl
        set(hFig, 'Toolbar', 'none', 'MenuBar', 'none');
        plotedit('off');
    else
        set(hFig, 'Toolbar', 'figure', 'MenuBar', 'figure');
        plotedit('on');
    end
    %movegui(hFig);
    gui_layout('Update');
end

%% ===== PLOT EDIT TOOLBAR =====
function TogglePlotEditToolbar(hFig) %#ok<DEFNU>
    % Keep in the figure appdata whether toolbar is displayed
    isPlotEditToolbar = getappdata(hFig, 'isPlotEditToolbar');
    setappdata(hFig, 'isPlotEditToolbar', ~isPlotEditToolbar);
    % Show/Hide Matlab controls at the same time
    ShowMatlabControls(hFig, ~isPlotEditToolbar);
    plotedit('off');
    drawnow
    % Toggle Plot Edit toolbar display
    try
        plotedit(hFig, 'plotedittoolbar', 'toggle');
    catch
    end
    % Reposition figures
    gui_layout('Update');
end




%% ======================================================================
%  ===== LOCAL HELPERS ==================================================
%  ======================================================================
% Check if a Figure structure is a valid 
function isValid = isFigureId(FigureId)
    if (~isempty(FigureId) && isstruct(FigureId) && ...
            isfield(FigureId, 'Type') && ...
            isfield(FigureId, 'SubType') && ...
            isfield(FigureId, 'Modality') && ...
            ismember(FigureId.Type, {'DataTimeSeries', 'ResultsTimeSeries', 'Topography', '3DViz', 'MriViewer', 'Timefreq', 'Spectrum', 'Pac', 'Connect'}));
        isValid = 1;
    else
        isValid = 0;
    end
end
    
% Compare two figure identification structures.
% FOR THE MOMENT : COMPARISON EXCLUDES 'SUBTYPE' FIELD
% Return : 1 if the two structures are equal,
%          0 else
function isEqual = compareFigureId(fid1, fid2)
    if (strcmpi(fid1.Type, fid2.Type) && ...
        (isempty(fid1.SubType) || isempty(fid2.SubType) || strcmpi(fid1.SubType, fid2.SubType)) && ... 
        (isempty(fid1.Modality) || isempty(fid2.Modality) || strcmpi(fid1.Modality, fid2.Modality)))
    
        isEqual = 1;
    else
        isEqual = 0;
    end
end
        


%% ===== RELOAD FIGURES ======
% Reload all the figures (needed for instance after changing the visualization filters parameters).
%
% USAGE:  ReloadFigures(FigureType)  : Reload all the figures of a specific type
%         ReloadFigures(FigureTypes) : Reload all the figures of a list of types
%         ReloadFigures('Stat')      : Reload all the stat figures
%         ReloadFigures(hFigs)       : Reload a specific list of figures
%         ReloadFigures()            : Reload all the figures
function ReloadFigures(FigureTypes)
    global GlobalData;
    % If figure type not sepcified
    isStatOnly = 0;
    hFigs = [];
    if (nargin == 0)
        FigureTypes = [];
    elseif ischar(FigureTypes)
        if strcmpi(FigureTypes, 'Stat')
            FigureTypes = [];
            isStatOnly = 1;
        else
            FigureTypes = {FigureTypes};
        end
    elseif isnumeric(FigureTypes)
        hFigs = FigureTypes;
        FigureTypes = [];
    end
    FigClose = [];
    ReOpenCode = [];
    % Process all the loaded datasets
    for iDS = 1:length(GlobalData.DataSet)
        % Process all the figures
        for iFig = 1:length(GlobalData.DataSet(iDS).Figure)
            Figure = GlobalData.DataSet(iDS).Figure(iFig);
            % Check figure type
            if ~isempty(FigureTypes) && ~ismember(Figure.Id.Type, FigureTypes)
                continue;
            end
            if ~isempty(hFigs) && ~ismember(Figure.hFigure, hFigs)
                continue;
            end
            % Switch according to figure type
            switch(Figure.Id.Type)
                case 'DataTimeSeries'
                    % Ignore non-stat files
                    if isStatOnly && ~strcmpi(GlobalData.DataSet(iDS).Measures.DataType, 'stat')
                        continue;
                    end
                    % Reload
                    if isempty(Figure.Id.Modality)
                        % Nothing to do
                    elseif (Figure.Id.Modality(1) == '$')
                        DataFiles = getappdata(Figure.hFigure, 'DataFiles');
                        iClusters = getappdata(Figure.hFigure, 'iClusters');
                        if ~isempty(DataFiles) && ~isempty(iClusters)
                            view_clusters(DataFiles, iClusters, Figure.hFigure);
                        end
                    else
                        TsInfo = getappdata(Figure.hFigure, 'TsInfo');
                        if TsInfo.AutoScaleY
                            GlobalData.DataSet(iDS).Figure(iFig).Handles.DataMinMax = [];
                        end
                        figure_timeseries('PlotFigure', iDS, iFig);
                    end
                    UpdateFigureName(Figure.hFigure);
                    
                case 'ResultsTimeSeries'
                    % Get file names displayed in this figure
                    ResultsFiles = getappdata(Figure.hFigure, 'ResultsFiles');
                    TsInfo = getappdata(Figure.hFigure, 'TsInfo');
                    % Ignore non-stat files
                    if isStatOnly
                        if ~strcmpi(file_gettype(ResultsFiles{1}), 'presults')
                            continue;
                        end
                    end
                    % Reload
                    if ~isempty(ResultsFiles)
                        view_scouts(ResultsFiles, 'SelectedScouts');
                    elseif ~isempty(TsInfo) && isfield(TsInfo, 'FileName') && ~isempty(TsInfo.FileName)
                        FigClose = [FigClose, Figure.hFigure];
                        ReOpenCode = [ReOpenCode 'view_matrix(''' TsInfo.FileName ''', ''TimeSeries''); ' 10];
                    end
                    
                case 'Topography'
%                     % Ignore non-stat files
%                     TopoInfo = getappdata(Figure.hFigure, 'TopoInfo');
%                     if ~ismember(file_gettype(TopoInfo.FileName), {'pdata', 'presults', 'ptimefreq'})
%                         continue;
%                     end
                    % Refresh
                    figure_topo('UpdateTopoPlot', iDS, iFig);
                    
                case '3DViz'
                    % Get the kind of data represented in this window
                    TessInfo = getappdata(Figure.hFigure, 'Surface');
                    % === PROCESS SURFACES ===
                    for iTess = 1:length(TessInfo)
                        % Ignore non-stat files
                        if isStatOnly && ~isempty(TessInfo(iTess).DataSource.FileName)
                            if ~ismember(file_gettype(TessInfo(iTess).DataSource.FileName), {'pdata', 'presults', 'ptimefreq'})
                                continue;
                            end
                        end
                        % View new surface / new data on surface
                        view_surface_data(TessInfo(iTess).SurfaceFile, TessInfo(iTess).DataSource.FileName, Figure.Id.Modality);
                    end
                    % === PROCESS SENSORS ===
                    ChannelFile = GlobalData.DataSet(iDS).ChannelFile;
                    if ~isempty(ChannelFile)
                        % Get the elements to be displayed
                        isMarkers = ~isempty(Figure.Handles.hSensorMarkers);
                        isLabels  = ~isempty(Figure.Handles.hSensorLabels);
                        % Update channels display
                        if isMarkers || isLabels
                            view_channels(ChannelFile, Figure.Id.Modality, isMarkers, isLabels);
                        end
                    end
                    
                case 'MriViewer'
                    % Get the kind of data represented in this window
                    TessInfo = getappdata(Figure.hFigure, 'Surface');
                    % === PROCESS SURFACES ===
                    for iTess = 1:length(TessInfo)
                        % Ignore non-stat files
                        isStat = ~isempty(TessInfo(iTess).DataSource.FileName) && ismember(file_gettype(TessInfo(iTess).DataSource.FileName), {'pdata', 'presults', 'ptimefreq'});
                        if isStatOnly && ~isStat
                            continue;
                        end
                        % Update channels display
                        view_mri(TessInfo(iTess).SurfaceFile, TessInfo(iTess).DataSource.FileName);
                    end
                    
                case 'Timefreq'
                    figure_timefreq('UpdateFigurePlot', Figure.hFigure, 1);
                case 'Spectrum'
                    figure_spectrum('UpdateFigurePlot', Figure.hFigure);
                    UpdateFigureName(Figure.hFigure);
                case 'Pac'
                    figure_pac('UpdateFigurePlot', Figure.hFigure);
                case 'Connect'
                    warning('todo: reload figure');
            end
        end
        % Update selected sensors
        FireSelectedRowChanged();
    end
    % Re-uniformize figures
    figure_timeseries('UniformizeTimeSeriesScales');
    % Close figures
    if ~isempty(FigClose)
        close(FigClose);
    end
    % Re-open figures
    if ~isempty(ReOpenCode)
        eval(ReOpenCode);
    end
end


%% =========================================================================================
%  ===== MOUSE SELECTION ===================================================================
%  =========================================================================================
% ===== TOGGLE SELECTED ROW =====
function ToggleSelectedRow(RowName)
    global GlobalData;
    % Convert to cell
    if ~iscell(RowName)
        RowName = {RowName};
    end
    % If row name is already in list: remove it
    if ismember(RowName, GlobalData.DataViewer.SelectedRows)
        SetSelectedRows(setdiff(GlobalData.DataViewer.SelectedRows, RowName));
    % Else: add it
    else
        SetSelectedRows(union(GlobalData.DataViewer.SelectedRows, RowName));
    end
end

%% ===== SET SELECTED ROWS =====
function SetSelectedRows(RowNames, isUpdateClusters)
    global GlobalData;
    % Parse inputs
    if (nargin < 2) || isempty(isUpdateClusters)
        isUpdateClusters = 1;
    end
    % Convert to cell
    if isempty(RowNames)
        RowNames = {};
    elseif ischar(RowNames)
        RowNames = {RowNames};
    end
    % Set list
    GlobalData.DataViewer.SelectedRows = RowNames;
    % Update all figures
    FireSelectedRowChanged();
    % Update selected clusters
    if isUpdateClusters
        panel_cluster('SetSelectedClusters', [], 0);
    end
end

%% ===== GET SELECTED CHANNELS =====
function [SelChan, iSelChan] = GetSelectedChannels(iDS)
    global GlobalData;
    % No channel file: return
    if isempty(GlobalData.DataSet(iDS).Channel)
        return;
    end
    AllChan = {GlobalData.DataSet(iDS).Channel.Name};
    % Get the channel names and indices
    SelChan = {};
    iSelChan = [];
    for i = 1:length(GlobalData.DataViewer.SelectedRows)
        iChan = find(strcmpi(GlobalData.DataViewer.SelectedRows{i}, AllChan));
        if ~isempty(iChan)
            SelChan{end+1} = AllChan{iChan};
            iSelChan(end+1) = iChan;
        end
    end
end

%% ===== FIRE SELECTED ROWS CHANGED =====
% Call SelectedRowChangedCallback on all the figures
function FireSelectedRowChanged()
    global GlobalData;
    for iDS = 1:length(GlobalData.DataSet)
        for iFig = 1:length(GlobalData.DataSet(iDS).Figure)
            sFig = GlobalData.DataSet(iDS).Figure(iFig);
            % Only fires for currently visible displayed figures, AND not static
            switch (sFig.Id.Type)
                case 'DataTimeSeries'
                    figure_timeseries('SelectedRowChangedCallback', iDS, iFig);
                case 'ResultsTimeSeries'
                    % Nothing to do
                case 'Topography'
                    figure_3d('UpdateFigSelectedRows', iDS, iFig);
                case '3DViz'
                    figure_3d('UpdateFigSelectedRows', iDS, iFig);
                case 'MriViewer'
                    % Nothing to do
                case 'Timefreq'
                    % Nothing to do
                case 'Spectrum'
                    figure_spectrum('SelectedRowChangedCallback', iDS, iFig);
                case 'Pac'
                    % Nothing to do
                case 'Connect'
                    figure_spectrum('SelectedRowChangedCallback', iDS, iFig);
                otherwise
                    % Nothing to do
            end
        end 
    end
end


%% ===== CHANGE BACKGROUND COLOR =====
function ChangeBackgroundColor(hFig) %#ok<*DEFNU>
    % Use previous scout color
    newColor = uisetcolor([0 0 0], 'Select scout color');
    % If no color was selected: exit
    if (length(newColor) ~= 3)
        return
    end
    % Find all the dependent axes
    hAxes = findobj(hFig, 'Type', 'Axes')';
    % Set background
    set([hFig hAxes], 'Color', newColor);
    % Change color for other controls
    hControls = findobj(hFig, 'Type', 'uicontrol')';
    if ~isempty(hControls)
        set(hControls, 'BackgroundColor', newColor);
    end
end


