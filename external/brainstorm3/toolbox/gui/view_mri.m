function [hFig, iDS, iFig] = view_mri(MriFile, OverlayFile)
% VIEW_MRI: Display a MRI in a MriViewer figure.
%
% USAGE:  view_mri(MriFile, OverlayFile)
%         view_mri(MriFile, 'EditMri')
%
% INPUT:
%     - MriFile     : full path to the surface file to display 
%     - OverlayFile : Full or relative path to a file to display on top of the MRI
%     - 'EditMri'   : Show the control to modify the MRI
%
% OUTPUT : 
%     - hFig : Matlab handle to the figure that was created or updated
%     - iDS  : DataSet index in the GlobalData variable
%     - iFig : Indice of returned figure in the GlobalData(iDS).Figure array
% If an error occurs : all the returned variables are set to an empty matrix []

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
% Authors: Francois Tadel, 2009-2013

%% ===== PARSE INPUTS =====
global GlobalData;
if (nargin < 2) || isempty(OverlayFile)
    OverlayFile = '';
end
if strcmpi(OverlayFile, 'EditMri')
    OverlayFile = '';
    isReadOnly = 0;
else
    isReadOnly = 1;
end
% Get file type
if ~isempty(OverlayFile)
    FileType = file_gettype(OverlayFile);
    isStat = any(strcmpi(FileType, {'pdata', 'presults', 'ptimefreq'}));
else
    FileType = '';
end

%% ===== LOAD OVERLAY FILE =====
iDS = [];
switch lower(FileType)
    case {'results', 'presults', 'link'}
        % Load Results file
        [iDS, iDSResult] = bst_memory('LoadResultsFile', OverlayFile);
        if ~isempty(iDSResult)
            bst_memory('LoadResultsMatrix', iDS, iDSResult);
        end
        % Get subject file
        SubjectFile = GlobalData.DataSet(iDS).SubjectFile;
        OverlayType = 'Source';
    case 'dipoles'
        % Try to get an existing DataSet
        [iDS, iDSDipoles] = bst_memory('LoadDipolesFile', OverlayFile);
        % Get subject file
        SubjectFile = GlobalData.DataSet(iDS).SubjectFile;
        OverlayType = 'Dipoles';
    case {'timefreq', 'ptimefreq'}
        % Try to get an existing DataSet (Force loading sources because displaying on the MRI)
        [iDS, iDSTimefreq] = bst_memory('LoadTimefreqFile', OverlayFile, 1, 1);
        % Get subject file
        SubjectFile = GlobalData.DataSet(iDS).SubjectFile;
        OverlayType = 'Timefreq';
    case {'cortex', 'innerskull', 'outerskull', 'scalp', 'tess'}
        SubjectFile = '';
        OverlayType = 'Surface';
    otherwise
        SubjectFile = '';
end
% If subject not available yet
if isempty(SubjectFile)
    % Get Subject that holds this MRI
    sSubject = bst_get('MriFile', MriFile);
    % If this surface does not belong to any subject
    if isempty(sSubject)
        % Create an empty DataSet
        SubjectFile = '';
        iDS = bst_memory('GetDataSetEmpty');
    else
        % Get GlobalData DataSet associated with subjectfile (create if does not exist)
        SubjectFile = sSubject.FileName;
        iDS = bst_memory('GetDataSetSubject', SubjectFile, 1);
    end
    iDS = iDS(1);
end
% Check if Dataset was created
if isempty(iDS)
    error('Could not create new DataSet.');
end


%% ===== CREATE FIGURE =====
bst_progress('start', 'View surface', 'Loading MRI file...');
[hFig, iFig, iOldDataSet, iSurface] = bst_figures('GetFigureWithSurface', MriFile, OverlayFile, 'MriViewer', '');
isNewFig = 0;
% Make sure that only one figure was found
if (length(hFig) > 1)
    hFig  = hFig(1);
    iFig  = iFig(1);
    iDS   = iOldDataSet(1);
    iSurface = iSurface(1);
% Else: Figure was not found
elseif isempty(hFig) 
    % Prepare FigureId structure
    FigureId = db_template('FigureId');
    FigureId.Type     = 'MriViewer';
    FigureId.SubType  = '';
    FigureId.Modality = '';
    % Create figure
    [hFig, iFig, isNewFig] = bst_figures('CreateFigure', iDS, FigureId, 'AlwaysCreate');
    if isempty(hFig)
        bst_error('Could not create figure', 'View mri', 0);
        return;
    end
    % Set application data
    setappdata(hFig, 'StudyFile',    '');
    setappdata(hFig, 'DataFile',     '');
    setappdata(hFig, 'SubjectFile',  SubjectFile);
    setappdata(hFig, 'FigureId',     FigureId);
    % Add colormap
    bst_colormaps('AddColormapToFigure', hFig, 'anatomy');
    
    % Add MRI to the figure
    iSurface = panel_surface('AddSurface', hFig, MriFile);
    if isempty(iSurface)
        return;
    end
    % Get loaded MRI
    sMri = bst_memory('LoadMri', MriFile);
    % If fiducials not defined: force MRI edition
    if isempty(sMri.SCS) || ~isfield(sMri.SCS, 'NAS') || isempty(sMri.SCS.NAS) || isempty(sMri.SCS.LPA) || isempty(sMri.SCS.RPA) || ...
       isempty(sMri.NCS) || ~isfield(sMri.NCS, 'AC')  || isempty(sMri.NCS.AC)  || isempty(sMri.NCS.PC)  || isempty(sMri.NCS.IH)
        isReadOnly = 0;
    end
    % Configure figure: Read-only MRI
    figure_mri('SetWindowReadOnly',  hFig, isReadOnly);
end



%% ===== DISPLAY MRI =====
% Add data on the MRI slices 
if ~isempty(OverlayFile)
    isOk = panel_surface('SetSurfaceData', hFig, iSurface, OverlayType, OverlayFile, isStat);
end
% Configure figure: Results/Anatomy
isResults = ~isempty(OverlayFile) && ~strcmpi(OverlayType, 'surface');
figure_mri('SetWindowHasResults', hFig, isResults);

% Update current figure selection
bst_figures('SetCurrentFigure', hFig, '3D');
if ~isempty(OverlayFile) && isappdata(hFig, 'Timefreq') && ~isempty(getappdata(hFig, 'Timefreq'))
    bst_figures('SetCurrentFigure', hFig, 'TF');
end
% Update Colormap
figure_mri('ColormapChangedCallback', iDS, iFig);
% Update figure name
bst_figures('UpdateFigureName', hFig);
% Set figure visible
set(hFig, 'Visible', 'on');
bst_progress('stop');

% In compiled mode, it's need to call the resize callback to redraw the controls (WHY???)
if exist('isdeployed', 'builtin') && isdeployed
    pos = get(hFig, 'Position');
    set(hFig, 'Position', pos - [0 0 20 20]);
    drawnow;
    set(hFig, 'Position', pos);
end
% Select surface tab
if isNewFig
    gui_brainstorm('SetSelectedTab', 'Surface');
end


