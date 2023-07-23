function view_scouts(ResultsFiles, ScoutsArg)
% VIEW_SCOUTS: Display time series for all the scouts selected in the JList.
%
% USAGE:  view_scouts()                               : Display selected sources file time series for selected scouts
%         view_scouts(ResultsFiles, 'SelectedScouts') : Display input sources file time series for selected scouts
%         view_scouts(ResultsFiles, iScouts)          : Display input sources file time series for input scouts

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
% Authors: Francois Tadel, 2008-2013

global GlobalData;  
%% ===== PARSE INPUTS =====
% If no parameters were given 
if (nargin == 0)
    % === GET SURFACES LIST ===
    hFigures = bst_figures('GetFiguresByType', '3DViz');
    % Process all figures : and keep them that have a ResultsFile defined
    ResultsFiles = {};
    for i = 1:length(hFigures)
        resFile = getappdata(hFigures(i), 'ResultsFile');
        if ~isempty(resFile)
            ResultsFiles{end + 1} = resFile;
        end
    end
    ResultsFiles = unique(ResultsFiles);
    ScoutsArg = 'SelectedScouts';
    clear hFigures resFile;
end
if isempty(ResultsFiles)
    % Try displaying scouts from tree selection
    tree_view_scouts();
    return
end

%% ===== GET SCOUTS LIST =====
% No scout
if isempty(ScoutsArg)
    return
% Use the scouts selected in the "Scouts" panel
elseif ischar(ScoutsArg) && strcmpi(ScoutsArg, 'SelectedScouts')
    % Get selected scouts
    [sScouts, iScouts, sSurf] = panel_scout('GetSelectedScouts');
% Else: use directly the scout indices in argument
else
    iScouts = ScoutsArg;
    [sScouts, sSurf] = panel_scout('GetScouts', iScouts);
end
if isempty(sScouts)
    return
end
clear ScoutsArg;


%% ===== CHECK CORRESPONDANCE SCOUTS/SURFACES =====
iDroppedRes = [];
FileType = {};
% Check each results file
for i = 1:length(ResultsFiles)
    FileType{i} = file_gettype(ResultsFiles{i});
    % Load surface file from sources file
    switch (FileType{i})
        case {'link', 'results', 'presults'}
            ResMat = in_bst_results(ResultsFiles{i}, 0, 'SurfaceFile', 'HeadModelType');
        case {'timefreq', 'ptimefreq'}
            ResMat = in_bst_timefreq(ResultsFiles{i}, 0, 'SurfaceFile', 'HeadModelType', 'DataFile');
            if isempty(ResMat.SurfaceFile) && ~isempty(ResMat.DataFile)
                ResMat = in_bst_results(ResMat.DataFile, 0, 'SurfaceFile', 'HeadModelType');
            else
                ResMat.SurfaceFile   = sSurf.FileName;
                ResMat.HeadModelType = 'surface';
            end
    end
    % If surface is not the same as scouts' one, drop this results file
    if ~file_compare(ResMat.SurfaceFile, sSurf.FileName) || ismember(ResMat.HeadModelType, {'volume', 'dba'})
        iDroppedRes = [iDroppedRes, i];
    end
end
if ~isempty(iDroppedRes)
    ResultsFiles(iDroppedRes) = [];
    FileType(iDroppedRes) = [];
end
% Check number of results files
if isempty(ResultsFiles)
    java_dialog('warning', 'No available source files.', 'Display scouts');
    return
end


%% ===== PREPARE DATA TO DISPLAY =====
% Initialize common descriptors (between all files)
SubjectFile    = '*';
StudyFile      = '*';
FigureDataFile = '*';

% Get display options        
ScoutsOptions = panel_scout('GetScoutsOptions');
% if (length(iScouts) == 1)
%     ScoutsOptions.overlayScouts = 0;
% end
if (length(ResultsFiles) == 1)
    ScoutsOptions.overlayConditions = 0;
end
% Initialize data to display
scoutsActivity = cell(length(ResultsFiles), length(iScouts));
scoutsLabels   = cell(length(ResultsFiles), length(iScouts));
scoutsColors   = cell(length(ResultsFiles), length(iScouts));
axesLabels     = cell(length(ResultsFiles), length(iScouts));
% Process each Results file
for iResFile = 1:length(ResultsFiles)
    % Is stat
    isStat = ismember(FileType{iResFile}, {'presults', 'ptimefreq'});
    isTimefreq = ismember(FileType{iResFile}, {'timefreq', 'ptimefreq'});
    
    % ===== GET/CREATE RESULTS DATASET =====
    bst_progress('start', 'Display scouts time series', ['Loading results file: "' ResultsFiles{iResFile} '"...']);
    % Load results
    if ~isTimefreq
        [iDS, iResult] = bst_memory('LoadResultsFileFull', ResultsFiles{iResFile});
    else
        [iDS, iTimefreq, iResult] = bst_memory('LoadTimefreqFile', ResultsFiles{iResFile}, 1, 1);
    end
    % If no DataSet is accessible : error
    if isempty(iDS)
        warning(['Cannot load file : "', ResultsFiles{iResFile}, '"']);
        return;
    end

    % Get results subjectName/condition/#solInverse (FOR TITLE ONLY)
    [sStudy,   iStudy]   = bst_get('Study',   GlobalData.DataSet(iDS).StudyFile);
    [sSubject, iSubject] = bst_get('Subject', sStudy.BrainStormSubject);
    isInterSubject = (iStudy == -2);
    % Get identification of figure
    if ~isempty(SubjectFile)
        if (SubjectFile(1) == '*')
            SubjectFile = sStudy.BrainStormSubject;
        elseif ~file_compare(SubjectFile, sStudy.BrainStormSubject)
            SubjectFile = [];
        end
    end
    if ~isempty(StudyFile)
        if (StudyFile(1) == '*')
            StudyFile = GlobalData.DataSet(iDS).StudyFile;
        elseif ~file_compare(StudyFile, GlobalData.DataSet(iDS).StudyFile)
            StudyFile = [];
        end
    end
    if ~isempty(FigureDataFile)
        if (FigureDataFile(1) == '*')
            FigureDataFile = GlobalData.DataSet(iDS).DataFile;
        elseif ~file_compare(FigureDataFile, GlobalData.DataSet(iDS).DataFile)
            FigureDataFile = [];
        end
    end
    % If DataFile is not defined for this dataset
    if isempty(FigureDataFile)
        % Get DataFile associated to results file in brainstorm database
        [sDbStudy, iDbStudy, iDbRes] = bst_get('ResultsFile', ResultsFiles{iResFile});
        if ~isempty(iDbRes)
            if isStat
                DataFile = sStudy.Stat(iDbRes).DataFile;
            else
                DataFile = sStudy.Result(iDbRes).DataFile;
            end
        else
            DataFile = '';
        end
    else
        DataFile = FigureDataFile;
    end
    % If no study loaded: ignore file
    if isempty(sStudy)
        error(['No study registered for file: ' strrep(ResultsFiles{iResFile},'\\','\')]);
    end
   
    % ===== Prepare cell array containing time series to display =====
    for k = 1:length(sScouts)
        % ===== Get data to display =====
        % Get list of useful vertices in ImageGridAmp
        if ~isempty(GlobalData.DataSet(iDS).Results(iResult).Atlas)
            % Atlas-based source file: use only the seed of the scout, and find it in the file atlas
            DataToPlotVertices = panel_scout('GetScoutForVertex', GlobalData.DataSet(iDS).Results(iResult).Atlas, sScouts(k).Seed);
            % Error management
            if isempty(DataToPlotVertices)
                disp('BST> Error: No data to display.');
                return;
            end
        else
            DataToPlotVertices = unique(sScouts(k).Vertices);
        end
        % Get data (over current time window)
        if ~isTimefreq
            [DataToPlot, nComponents] = bst_memory('GetResultsValues', iDS, iResult, DataToPlotVertices, 'UserTimeWindow', 0);
        else
            iFreqs = GlobalData.UserFrequencies.iCurrentFreq;
            [DataToPlot, nComponents] = bst_memory('GetTimefreqValues', iDS, iTimefreq, DataToPlotVertices, iFreqs, 'UserTimeWindow', []);
        end
        % Compute the scout values
        if ~isStat
            ScoutFunction = sScouts(k).Function;
        else
            ScoutFunction = 'stat';
        end
        % Only one component
        if (nComponents == 1)
            isFlipSign = ~isStat && ~isTimefreq && ...
                         strcmpi(GlobalData.DataSet(iDS).Results(iResult).DataType, 'results') && ...
                         isempty(strfind(ResultsFiles{iResFile}, '_abs_zscore'));
            iTrace = k;
            scoutsActivity{iResFile,iTrace} = bst_scout_value(DataToPlot, ScoutFunction, sSurf.VertNormals(DataToPlotVertices,:), nComponents, 'none', isFlipSign);
            if ScoutsOptions.displayAbsolute
                scoutsActivity{iResFile,iTrace} = abs(scoutsActivity{iResFile,iTrace});
            end
        % More than one component & Absolute: Display the norm
        elseif ScoutsOptions.displayAbsolute
            iTrace = k;
            scoutsActivity{iResFile,iTrace} = bst_scout_value(DataToPlot, ScoutFunction, sSurf.VertNormals(DataToPlotVertices,:), nComponents, 'norm');
        % More than one component & Relative: Display the three components
        else
            iTrace = nComponents * (k-1) + [1 2 3];
            tmp = bst_scout_value(DataToPlot, ScoutFunction, sSurf.VertNormals(DataToPlotVertices,:), nComponents, 'none');
            for iComp = 1:nComponents
                scoutsActivity{iResFile,iTrace(iComp)} = tmp(iComp:nComponents:end,:);
            end
        end
            
        % === AXES LABELS ===
        % === SUBJECT NAME ===
        % Format: SubjectName/Cond1/.../CondN/(DataComment)/(Sol#iResult)/(ScoutName)
        strAxes = '';
        if ~isempty(sSubject) && (iSubject > 0)
            strAxes = sSubject.Name;
        end
        % === CONDITION ===
        % If inter-subject node
        if isInterSubject
            strAxes = [strAxes, 'Inter'];
        % Else: display conditions name
        else
            for i = 1:length(sStudy.Condition)
                strAxes = [strAxes, '/', sStudy.Condition{i}];
            end
        end
        % === DATA COMMENT ===
        % If more than one data file in this study : display current data comments
        if ~isempty(DataFile) && ((length(sStudy.Data) > 1) || isInterSubject)
            % Find DataFile in current study
            iData = find(file_compare({sStudy.Data.FileName}, DataFile));
            % Add Data comment
            if ~isempty(iData)
                strAxes = [strAxes, '/', sStudy.Data(iData).Comment];
            end
        end
        % === RESULTS COMMENT ===
        % If more than one results file in study : display indice
        if ~isempty(DataFile) && ((~isStat && (length(sStudy.Result) > 1)) || (isStat && (length(sStudy.Stat) > 1)))
            % Get list of results files for current data file
            if isStat
                [tmp__, tmp__, iResInStudy] = bst_get('StatForDataFile', DataFile, iStudy);
                sRes = sStudy.Stat;
            else
                [tmp__, tmp__, iResInStudy] = bst_get('ResultsForDataFile', DataFile, iStudy);
                sRes = sStudy.Result;
            end
            % More than one results file for this data file
            if (length(iResInStudy) > 1)
                strAxes = [strAxes, '/', GlobalData.DataSet(iDS).Results(iResult).Comment];
            end
        % Inter-subject: always display whole
        elseif (isempty(DataFile) || isInterSubject)
           strAxes = [strAxes, '/', GlobalData.DataSet(iDS).Results(iResult).Comment];
        end
        [axesLabels{iResFile,iTrace}] = deal(strAxes);

        % === SCOUTS LABELS/COLORS ===
        if (length(iTrace) == 1)
            scoutsLabels{iResFile,iTrace} = sScouts(k).Label;
            [scoutsColors{iResFile,iTrace}] = deal(sScouts(k).Color);
        else
            for iComp = 1:length(iTrace)
                scoutsLabels{iResFile,iTrace(iComp)} = sprintf('%s%d', sScouts(k).Label, iComp);
                scoutsColors{iResFile,iTrace(iComp)} = sScouts(k).Color .* (1 - .25 * (iComp-1));
            end
        end
    end
end


% ===== DISPLAY STATIC VALUES =====
% Get the number of time samples for all the scouts
nbTimes = cellfun(@(c)size(c,2), scoutsActivity(:));
% If both real scouts and static values
if ((max(nbTimes) > 2) && any(nbTimes == 2))
    iCellToExtend = find(nbTimes == 2);
    for i = 1:length(iCellToExtend)
        scoutsActivity{iCellToExtend(i)} = repmat(scoutsActivity{iCellToExtend(i)}(:,1), [1,max(nbTimes)]);
    end
end


%% ===== LEGENDS =====
% Get common beginning part in all the axesLabels
[ strAxesCommon, axesLabels ] = str_common_path( axesLabels );
% Only one time series: no overlay scout
if (size(scoutsActivity,2) == 1)
    ScoutsOptions.overlayScouts = 0;
end
% If at least one of the scouts functions is "All", ignore the overlay checkboxes
if ~isempty(sScouts) && any(strcmpi({sScouts.Function}, 'All'))
    ScoutsOptions.overlayScouts     = 0;
    ScoutsOptions.overlayConditions = 0;
end

% === NO OVERLAY ===
% Display all timeseries (ResultsFiles/Scouts) in different axes on the same figure
if (~ScoutsOptions.overlayScouts && ~ScoutsOptions.overlayConditions)
    % One graph for each line => Ngraph, Nscouts*Ncond
    % Scouts activity = cell-array {1, Ngraph} of doubles [1,Nt]
    scoutsActivity = scoutsActivity(:)';
    % Axes labels (subj/cond) = cell-array of strings {1, Ngraph}
    axesLabels = axesLabels(:)';
    % Scouts labels = cell-array of strings {1, Ngraph}
    scoutsLabels = scoutsLabels(:)';
    scoutsColors = scoutsColors(:)';
    % Eliminate empty entries
    iEmpty = find(cellfun(@isempty, scoutsActivity));
    if ~isempty(iEmpty)
        scoutsActivity(iEmpty) = [];
        scoutsLabels(iEmpty) = [];
        axesLabels(iEmpty) = [];
        if ~isempty(scoutsColors)
            scoutsColors(iEmpty) = [];
        end
    end
    
% === OVERLAY SCOUTS AND CONDITIONS ===
% Only one graph with Nlines = Nscouts*Ncond
elseif (ScoutsOptions.overlayScouts && ScoutsOptions.overlayConditions)
    % Linearize entries
    scoutsActivity = scoutsActivity(:);
    scoutsLabels = scoutsLabels(:);
    axesLabels = axesLabels(:);
    % Eliminate empty entries
    iEmpty = find(cellfun(@isempty, scoutsActivity));
    if ~isempty(iEmpty)
        scoutsActivity(iEmpty) = [];
        scoutsLabels(iEmpty) = [];
        axesLabels(iEmpty) = [];
    end
    % Scouts activity = double [Nlines, Nt] 
    scoutsActivity = cat(1, scoutsActivity{:});
    % Scouts labels = cell-array {Nlines}
    % => "scoutName @ subject/condition"
    for iTrace = 1:size(scoutsActivity,1)
        if ~isempty(axesLabels{iTrace})
            scoutsLabels{iTrace} = [scoutsLabels{iTrace} ' @ ' axesLabels{iTrace}];
        end
    end
    scoutsColors = [];
    % Only one graph => legend is common scouts parts
    if ~isempty(strAxesCommon)
        axesLabels = {strAxesCommon};
    else
        axesLabels = {'Mixed subjects'};
    end
    
% === OVERLAY SCOUTS ONLY ===
elseif ScoutsOptions.overlayScouts
    % One graph per condition => Ngraph = Ncond
    % Scouts activity = cell-array {1, Ncond} of doubles [Nscout, Nt]
    for i = 1:size(scoutsActivity,1)
        scoutsActivityTmp(i) = {cat(1, scoutsActivity{i,:})};
    end
    scoutsActivity = scoutsActivityTmp;
    % Axes labels (subj/cond) = cell-array of strings {1, Ncond} 
    axesLabels   = axesLabels(:,1)';
    % Scouts labels = cell-array of strings {Nscout, Ncond} 
    scoutsLabels = scoutsLabels';
    scoutsColors = scoutsColors';

% === OVERLAY CONDITIONS ONLY ===
elseif ScoutsOptions.overlayConditions
    % One graph per scout => Ngraph = Nscout
    % Scouts activity = cell-array {1, Nscout} of doubles [Ncond, Nt]
    for j = 1:size(scoutsActivity,2)
        scoutsActivityTmp(j) = {cat(1, scoutsActivity{:,j})};
    end
    scoutsActivity = scoutsActivityTmp;
    % Axes labels (scout names @ common_subject/cond part) = cell-array of strings {1, Nscout} 
    tmpAxesLabels = axesLabels;
    axesLabels = scoutsLabels(1,:);
    % Lines labels (subject/condition) = cell-array of strings {Ncond, Nscout}  
    scoutsLabels = tmpAxesLabels;
    scoutsColors = [];
end
% Close progress bar
bst_progress('stop');


%% ===== CALL DISPLAY FUNCTION ====
% Plot time series
hFig = view_timeseries_matrix(ResultsFiles, scoutsActivity, 'Sources', axesLabels, scoutsLabels, scoutsColors);
% Associate the file with one specific result file 
setappdata(hFig, 'ResultsFiles', ResultsFiles);
if (length(ResultsFiles) == 1)
    setappdata(hFig, 'ResultsFile', ResultsFiles);
else
    setappdata(hFig, 'ResultsFile', []);
end
% Update figure name
bst_figures('UpdateFigureName', hFig);
% Set the time label visible
figure_timeseries('SetTimeVisible', hFig, 1);

    
end


 
 
