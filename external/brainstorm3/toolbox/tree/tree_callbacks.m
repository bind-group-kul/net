function jPopup = tree_callbacks( varargin )
% TREE_CALLBACKS: Perform an action on a given BstNode, or return a popup menu.
%
% USAGE:  tree_callbacks(bstNodes, action);
%
% INPUT:
%     - bstNodes : Array of BstNode java handle target
%                  Most of the functions will only use the first node
%                  Array of nodes is useful only for some popup functions
%     - action   : action that was performed {'popup', 'click', 'doubleclick'}
%
% OUTPUT: 
%     - jPopup   : handle to a JPopupMenu (or [] if no popup is created)

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

import org.brainstorm.icon.*;
import java.awt.event.KeyEvent;
import javax.swing.KeyStroke;

global GlobalData;

%% ===== PARSE INPUTS =====
if (nargin == 0)
    % Nothing to do... just to force the compilation of the file
    return
elseif (nargin == 2)
    if (isa(varargin{1}(1), 'org.brainstorm.tree.BstNode') && ischar(varargin{2}))
        bstNodes = varargin{1};
        action  = varargin{2};
    else
        error('Usage : tree_callbacks(bstNodes, action)');
    end
else
    error('Usage : tree_callbacks(bstNodes, action)');
end
% Initialize return variable
jPopup = [];
% Is Matlab running (if not it is a compiled version)
isMatlabRunning = ~(exist('isdeployed', 'builtin') && isdeployed);


%% ===== GET ALL THE NEEDED OBJECTS =====
% Get current Protocol description
ProtocolInfo = bst_get('ProtocolInfo');
% Node type
nodeType = char(bstNodes(1).getType());
% Get node information
filenameRelative = char(bstNodes(1).getFileName());
% Build full filename (depends on the file type)
switch lower(nodeType)
    case {'surface', 'scalp', 'cortex', 'outerskull', 'innerskull', 'other', 'subject', 'studysubject', 'anatomy'}
        filenameFull = bst_fullfile(ProtocolInfo.SUBJECTS, filenameRelative);
    case {'study', 'condition', 'rawcondition', 'channel', 'headmodel', 'data','rawdata', 'datalist', 'results', 'kernel', 'pdata', 'presults', 'ptimefreq', 'image', 'noisecov', 'dipoles','timefreq', 'spectrum', 'matrix'}
        filenameFull = bst_fullfile(ProtocolInfo.STUDIES, filenameRelative);
    case 'link'
        filenameFull = filenameRelative;
    otherwise
        filenameFull = '';
end
% Is special node (starting with '(')
if (bstNodes(1).getComment().length() > 0)
    isSpecialNode = ismember(char(bstNodes(1).getType()), {'subject','defaultstudy'}) && (bstNodes(1).getComment().charAt(0) == '(');
else
    isSpecialNode = 0;
end
iStudy = [];
iSubject = [];
 
%% ===== CLICK =====
switch (lower(action))  
    case {'click', 'popup'}
        nodeStudy  = [];
        conditionTypes = {'condition', 'rawcondition', 'studysubject', 'study', 'defaultstudy'};
        % Select the Study (subject/condition) closest to the node that was clicked
        switch lower(nodeType)
            % Selecting a condition
            case conditionTypes
                % If selected node is a Study node
                if (bstNodes(1).getStudyIndex() ~= 0)
                    nodeStudy = bstNodes(1);
                % Else : try to find a Study node in the children nodes
                elseif (bstNodes(1).getChildCount() > 0)
                    % If first child is a study node : select it
                    if (bstNodes(1).getChildAt(0).getStudyIndex() ~= 0)
                        nodeStudy = bstNodes(1).getChildAt(0);
                        % Else look it 2nd levels of children
                    elseif (bstNodes(1).getChildAt(0).getChildCount() > 0) && (bstNodes(1).getChildAt(0).getChildAt(0).getStudyIndex() ~= 0)
                        nodeStudy = bstNodes(1).getChildAt(0).getChildAt(0);
                    end
                end
                % If not is not generated: Create node contents
                if ~isempty(nodeStudy)
                    panel_protocols('CreateStudyNode', nodeStudy);
                end
            % Selecting a file in a condition
            case {'data', 'rawdata', 'datalist', 'channel', 'headmodel', 'noisecov', 'results', 'kernel', 'matrix', 'dipoles', 'timefreq', 'spectrum', 'pdata', 'presults', 'ptimefreq', 'link'}
                nodeStudy = bstNodes(1);
                % Go up in the ancestors, until we get a study file
                while ~isempty(nodeStudy) && ~any(strcmpi(nodeStudy.getType(), conditionTypes))
                    nodeStudy = nodeStudy.getParent();
                end
        end
                
        % If study selected changed 
        if ~isempty(nodeStudy) && (isempty(ProtocolInfo.iStudy) || (double(nodeStudy.getStudyIndex()) ~= ProtocolInfo.iStudy))
            panel_protocols('SelectStudyNode', nodeStudy);
        end
end
 

%% ===== DOUBLE CLICK =====
switch (lower(action))  
    case 'doubleclick'       
        % Switch between node types
        % Existing node types : root, loading, subjectdb, studydbsubj, studydbcond, 
        %                       surface, scalp, cortex, outerskull, innerskull, other,
        %                       subject, anatomy, study, studysubject, condition, 
        %                       channel, headmodel, data, results, link
        switch lower(nodeType)       
            % ===== SUBJECT DB ===== 
            case {'subjectdb', 'studydbsubj', 'studydbcond'}
                % Edit protocol
                iProtocol = bst_get('iProtocol');
                gui_edit_protocol('edit', iProtocol);
                
            % === SUBJECT ===
            case 'subject'
                % If clicked subject is not the default subject (ie. index=0)
                if (bstNodes(1).getStudyIndex() > 0)
                	db_edit_subject(bstNodes(1).getStudyIndex());
                end
            % === SUBJECT ===
            case 'studysubject'
                % If clicked subject is not the default subject (ie. index=0)
                if (bstNodes(1).getItemIndex() > 0)
                    % Edit subject
                	db_edit_subject(bstNodes(1).getItemIndex());
                end
                
            % ===== ANATOMY =====
            % Mark/unmark (items selected : 1)
            case 'anatomy'
                % Get subject
                iSubject = bstNodes(1).getStudyIndex();
                sSubject = bst_get('Subject', iSubject);
                iAnatomy = bstNodes(1).getItemIndex();
                % If item is not marked yet : mark it (and unmark all the other nodes)
                if (~ismember(iAnatomy, sSubject.iAnatomy) || ~bstNodes(1).isMarked())
                    db_surface_default(iSubject, 'Anatomy', iAnatomy);
                % Else, this item is already marked : display it in MRI Viewer
                else
                    view_mri(filenameRelative);
                end
    
            % ===== SURFACE ===== 
            % Mark/unmark (items selected : 1/category)
            case {'scalp', 'outerskull', 'innerskull', 'cortex'}
                iSubject = bstNodes(1).getStudyIndex();
                sSubject = bst_get('Subject', iSubject);
                iSurface = bstNodes(1).getItemIndex();
                % If surface is not selected yet
                switch lower(nodeType)
                    case 'scalp',      SurfaceType = 'Scalp';
                    case 'innerskull', SurfaceType = 'InnerSkull';
                    case 'outerskull', SurfaceType = 'OuterSkull';
                    case 'cortex',     SurfaceType = 'Cortex';
                    case 'other',      SurfaceType = 'Other';
                end
                if (~ismember(iSurface, sSubject.(['i' SurfaceType])) || ~bstNodes(1).isMarked())
                    % Set it as subject default
                    db_surface_default(iSubject, SurfaceType, iSurface);
                % Else, this item is already marked : display it in surface viewer
                else
                    view_surface(filenameRelative);
                end
            % Other surface: display it
            case 'other'
                view_surface(filenameRelative);
                
            % ===== CHANNEL =====
            % If one and only one modality available : display sensors
            % Else : Edit channel file
            case 'channel'
                % Get displayable modalities for this file
                [tmp, DisplayMod] = bst_get('ChannelModalities', filenameRelative);
                DisplayMod = intersect(DisplayMod, {'EEG','MEG','MEG GRAD','MEG MAG','ECOG','SEEG'});
                % If only one modality
                if (length(DisplayMod) == 1)
                    view_channels(filenameRelative, DisplayMod{1});
                else
                    % Open file in the "Channel Editor"
                    gui_edit_channel( filenameRelative );
                end               
                
            % ===== HEADMODEL =====
            % Mark/unmark (items selected : 1)
            case 'headmodel'
                iStudy     = bstNodes(1).getStudyIndex();
                sStudy     = bst_get('Study', iStudy);
                iHeadModel = bstNodes(1).getItemIndex();
                % If item is not marked yet : mark it (and unmark all the other nodes)
                if (~ismember(iHeadModel, sStudy.iHeadModel) || ~bstNodes(1).isMarked())
                    % Select this node (and unselect all the others)
                    panel_protocols('MarkUniqueNode', bstNodes(1));
                    % Save in database selected file
                    sStudy.iHeadModel = iHeadModel;
                    bst_set('Study', iStudy, sStudy);
                % Else, this item is already marked : keep it marked
                end
                
            % ===== NOISE COV =====
            case 'noisecov'
                view_noisecov(filenameRelative);

            % ===== DATA =====
            % View data file (MEG and EEG)
            case {'data', 'pdata', 'rawdata'}
                view_timeseries(filenameRelative);

            % ===== DATA LIST =====
            % Expand node
            case 'datalist'
                panel_protocols('ExpandPath', bstNodes(1), 1);
                
            % ===== RESULTS =====
            % View results on cortex
            case {'results', 'link'}
                view_surface_data([], filenameRelative);
                
            % ===== STAT/RESULTS =====
            case 'presults'
                view_surface_data([], filenameRelative);
                
            % ===== DIPOLES =====
            case 'dipoles'
                % Display on existing figures
                view_dipoles(filenameFull);
                
            % ===== TIME-FREQUENCY =====
            case {'timefreq', 'ptimefreq'}
                % Get study
                iStudy = bstNodes(1).getStudyIndex();
                iTimefreq = bstNodes(1).getItemIndex();
                sStudy = bst_get('Study', iStudy);
                % Get data type
                if strcmpi(char(bstNodes(1).getType()), 'ptimefreq')
                    TimefreqMat = in_bst_timefreq(filenameRelative, 0, 'DataType');
                    if ~isempty(TimefreqMat.DataType)
                        DataType = TimefreqMat.DataType;
                    else
                        DataType = 'matrix';
                    end
                else
                    DataType = sStudy.Timefreq(iTimefreq).DataType;
                end
                % PAC and DPAC
                if ~isempty(strfind(filenameRelative, '_pac_fullmaps'))
                    view_pac(filenameRelative);
                    return;
                elseif ~isempty(strfind(filenameRelative, '_dpac_fullmaps'))
                    view_pac(filenameRelative, [], 'DynamicPAC');
                    return;
                end
                % Get subject 
                sSubject = bst_get('Subject', sStudy.BrainStormSubject);
                switch DataType
                    % Results: display on cortex or MRI
                    case 'results'
                        if ~isempty(strfind(filenameRelative, '_connectn'))
                            view_connect(filenameRelative, 'GraphFull');
                        else
                            view_timefreq(filenameRelative, 'SingleSensor');
                        end
                    % Else
                    case {'data', 'cluster', 'scout', 'matrix'}
                        if ismember(nodeType, {'timefreq', 'ptimefreq'})
                            if ~isempty(strfind(filenameRelative, '_pac')) || ~isempty(strfind(filenameRelative, '_dpac'))
                                if strcmpi(DataType, 'data')
                                    view_topography(filenameRelative, [], '2DSensorCap', [], 0);
                                else
                                    view_struct(filenameFull);
                                end
                            elseif ~isempty(strfind(filenameRelative, '_connect1_cohere'))
                                view_spectrum(filenameRelative, 'Spectrum');
                            elseif ~isempty(strfind(filenameRelative, '_connect1')) && strcmpi(DataType, 'data')
                                view_topography(filenameRelative, [], '2DSensorCap', [], 0);
                            elseif ~isempty(strfind(filenameRelative, '_connectn'))
                                view_connect(filenameRelative, 'GraphFull');
                            else
                                view_timefreq(filenameRelative, 'SingleSensor');
                            end
                        else
                            view_spectrum(filenameRelative, 'Spectrum');
                        end
                        
                    otherwise
                        error(['Invalid data type: ' DataType]);
                end
                
            % ===== SPECTRUM =====
            case 'spectrum'
                % Get study
                iStudy = bstNodes(1).getStudyIndex();
                iTimefreq = bstNodes(1).getItemIndex();
                sStudy = bst_get('Study', iStudy);
                % Get subject 
                sSubject = bst_get('Subject', sStudy.BrainStormSubject);
                switch sStudy.Timefreq(iTimefreq).DataType
                    % Results: display on cortex or MRI
                    case 'results'
                        % Get head model type for the sources file
                        if ~isempty(sStudy.Timefreq(iTimefreq).DataFile)
                            [sStudyData, iStudyData, iResult] = bst_get('AnyFile', sStudy.Timefreq(iTimefreq).DataFile);
                            isVolume = ismember(sStudyData.Result(iResult).HeadModelType, {'volume', 'dba'});
                        % Get the default head model
                        else
                            isVolume = 0;
                        end
                        % Cortex / MRI
                        if ~isempty(sSubject) && ~isempty(sSubject.iCortex) && ~isVolume
                            view_surface_data([], filenameRelative);
                        elseif ~isempty(sSubject) && ~isempty(sSubject.iAnatomy)
                            MriFile = sSubject.Anatomy(sSubject.iAnatomy).FileName;
                            view_surface_data(MriFile, filenameRelative);
                        else
                            view_timefreq(filenameRelative, 'SingleSensor');
                        end
                    % Else
                    case {'data', 'cluster', 'scout', 'matrix'}
                        view_spectrum(filenameRelative, 'Spectrum');

                    otherwise
                        error(['Invalid data type: ' sStudy.Timefreq(iTimefreq).DataType]);
                end

            % ===== MATRIX =====
            case 'matrix'
                view_matrix( filenameRelative, 'TimeSeries' );
                
            % ===== IMAGE =====
            case 'image'
                view_image(filenameFull);
            
        end
        % Repaint tree
        panel_protocols('RepaintTree');
        
        
        
%% ===== POPUP =====
% Existing node types : root, loading, subjectdb, studydbsubj, studydbcond, 
%                       surface, scalp, cortex, outerskull, innerskull, other,
%                       subject, anatomy, study, studysubject, condition, 
%                       channel, headmodel, data, results, pdata, presults, ptimefreq
    case 'popup'
        % Create popup menu
        jPopup = java_create('javax.swing.JPopupMenu');
        jMenuExport = [];
        jMenuFileOther = [];
        
        switch lower(nodeType)
%% ===== POPUP: SUBJECTDB =====
            case 'subjectdb'
                if ~bst_get('ReadOnly')
                    iProtocol = bst_get('iProtocol');
                    gui_component('MenuItem', jPopup, [], 'Edit protocol', IconLoader.ICON_EDIT,        [], @(h,ev)bst_call(@gui_edit_protocol, 'edit', iProtocol), []);
                    gui_component('MenuItem', jPopup, [], 'New subject',   IconLoader.ICON_SUBJECT_NEW, [], @(h,ev)bst_call(@db_edit_subject), []);
                end
                % Export menu (added later)
                jMenuExport = gui_component('MenuItem', [], [], 'Export',   IconLoader.ICON_SAVE, [], @(h,ev)bst_call(@export_protocol), []);

%% ===== POPUP: STUDIESDB =====
            case {'studydbsubj', 'studydbcond'}
                if ~bst_get('ReadOnly')
                    iProtocol = bst_get('iProtocol');
                    gui_component('MenuItem', jPopup, [], 'Edit protocol', IconLoader.ICON_EDIT,        [], @(h,ev)bst_call(@gui_edit_protocol, 'edit', iProtocol), []);
                    gui_component('MenuItem', jPopup, [], 'New subject',   IconLoader.ICON_SUBJECT_NEW, [], @(h,ev)bst_call(@db_edit_subject), []);
                    gui_component('MenuItem', jPopup, [], 'Add condition', IconLoader.ICON_FOLDER_NEW,  [], @(h,ev)bst_call(@db_add_condition, '*'), []);
                    AddSeparator(jPopup);
                    gui_component('MenuItem', jPopup, [], 'Review raw file', IconLoader.ICON_RAW_DATA, [], @(h,ev)bst_call(@import_raw), []);
                    gui_component('MenuItem', jPopup, [], 'Import MEG/EEG',  IconLoader.ICON_EEG_NEW,  [], @(h,ev)bst_call(@import_data), []);
                    AddSeparator(jPopup);
                    % === IMPORT CHANNEL / COMPUTE HEADMODEL ===
                    fcnPopupImportChannel();
                    fcnPopupMenuGoodBad();
                    fcnPopupComputeHeadmodel();
                    fncPopupMenuNoiseCov();
                    % === SOURCES/TIMEFREQ ===
                    fcnPopupComputeSources();
                    fcnPopupProjectSources();
                end
                % Export menu (added later)
                jMenuExport = gui_component('MenuItem', [], [], 'Export',   IconLoader.ICON_SAVE, [], @(h,ev)bst_call(@export_protocol), []);


%% ===== POPUP: SUBJECT =====
            case 'subject'
                % Get subject
                iSubject = bstNodes(1).getStudyIndex(); 
                sSubject = bst_get('Subject', iSubject);
                % === EDIT SUBJECT ===
                % If subject is not default subject (if subject index is not 0)
                if ~bst_get('ReadOnly') && (iSubject > 0)
                    gui_component('MenuItem', jPopup, [], 'Edit subject', IconLoader.ICON_EDIT, [], @(h,ev)bst_call(@db_edit_subject, iSubject), []);
                end
                % If subject node is not a node linked to "Default anatomy"
                if ~bst_get('ReadOnly') && ((iSubject == 0) || ~sSubject.UseDefaultAnat)
                    AddSeparator(jPopup);
                    % === IMPORT ===
                    gui_component('MenuItem', jPopup, [], 'Import anatomy folder', IconLoader.ICON_ANATOMY, [], @(h,ev)bst_call(@import_anatomy, iSubject), []);
                    gui_component('MenuItem', jPopup, [], 'Import MRI', IconLoader.ICON_ANATOMY, [], @(h,ev)bst_call(@import_mri, iSubject, [], [], 1), []);
                    gui_component('MenuItem', jPopup, [], 'Import surfaces', IconLoader.ICON_SURFACE, [], @(h,ev)bst_call(@import_surfaces, iSubject), []);
                    AddSeparator(jPopup);
                    % === USE DEFAULT ===
                    % Get registered Brainstorm anatomy defaults
                    sTemplates = bst_get('AnatomyDefaults');
                    if ~isempty(sTemplates)
                        jMenuDefaults = gui_component('Menu', jPopup, [], 'Use template', IconLoader.ICON_ANATOMY, [], [], []);
                        % Add an item per Template available
                        for i = 1:length(sTemplates)
                            if ~isempty(strfind(sTemplates(i).FilePath, 'http://')) || ~isempty(strfind(sTemplates(i).FilePath, 'https://')) || ~isempty(strfind(sTemplates(i).FilePath, 'ftp://'))
                                Comment = ['Download: ' sTemplates(i).Name];
                            else
                                Comment = sTemplates(i).Name;
                            end
                            gui_component('MenuItem', jMenuDefaults, [], Comment, IconLoader.ICON_ANATOMY, [], @(h,ev)bst_call(@db_set_template, iSubject, sTemplates(i), 1), []);
                        end
                        % Create new template
                        AddSeparator(jMenuDefaults);
                        gui_component('MenuItem', jMenuDefaults, [], 'Create new template', IconLoader.ICON_ANATOMY, [], @(h,ev)bst_call(@export_default_anat, iSubject), []);
                    end
                    AddSeparator(jPopup);
                    

                    % === GENERATE HEAD ===
                    jItem = gui_component('MenuItem', jPopup, [], 'Generate head surface', IconLoader.ICON_SURFACE_SCALP, [], @(h,ev)bst_call(@tess_isohead, iSubject), []);
                    if isempty(sSubject.Anatomy)
                        jItem.setEnabled(0);
                    end
                    % === GENERATE BEM ===
                    jItem = gui_component('MenuItem', jPopup, [], 'Generate BEM surfaces', IconLoader.ICON_ANATOMY, [], @(h,ev)bst_call(@tess_bem, iSubject), []);
                    % Disable if no scalp or cortex available
                    if isempty(sSubject.iCortex) || isempty(sSubject.iScalp) || isempty(sSubject.Anatomy)
                        jItem.setEnabled(0);
                    end
                    % Export menu (added later)
                    if (iSubject ~= 0)
                        jMenuExport{1} = gui_component('MenuItem', [], [], 'Export subject',  IconLoader.ICON_SAVE, [], @(h,ev)bst_call(@export_protocol, bst_get('iProtocol'), iSubject), []);
                        jMenuExport{2} = 'separator';
                    end
                end
                
%% ===== POPUP: STUDYSUBJECT =====
            case 'studysubject'
                % Get subject
                iStudy = bstNodes(1).getStudyIndex();
                iSubject = bstNodes(1).getItemIndex();
                sSubject = bst_get('Subject', iSubject);
                % If node is a directory node
                isDirNode = (bstNodes(1).getStudyIndex() == 0);
                % === EDIT SUBJECT ===
                if ~bst_get('ReadOnly')
                    gui_component('MenuItem', jPopup, [], 'Edit subject', IconLoader.ICON_EDIT, [], @(h,ev)bst_call(@db_edit_subject, iSubject), []);
                end
                % === ADD CONDITION ===
                if ~bst_get('ReadOnly') && isDirNode
                    gui_component('MenuItem', jPopup, [], 'Add condition', IconLoader.ICON_FOLDER_NEW, [], @(h,ev)bst_call(@db_add_condition, char(bstNodes(1).getComment())), []);
                end
                % === IMPORT DATA ===
                if ~bst_get('ReadOnly')
                    AddSeparator(jPopup);
                    if isDirNode
                        gui_component('MenuItem', jPopup, [], 'Review raw file', IconLoader.ICON_RAW_DATA, [], @(h,ev)bst_call(@import_raw, [], [], iSubject), []);
                    end
                    gui_component('MenuItem', jPopup, [], 'Import MEG/EEG', IconLoader.ICON_EEG_NEW, [], @(h,ev)bst_call(@import_data, [], [], iStudy, iSubject), []);
                    AddSeparator(jPopup);
                end
                % === IMPORT CHANNEL / COMPUTE HEADMODEL ===
                % If not global default Channel + Headmodel
                if ~bst_get('ReadOnly')
                    if (sSubject.UseDefaultChannel ~= 2)
                        fcnPopupImportChannel();
                        fcnPopupMenuGoodBad();
                        fcnPopupClusterTimeSeries();
                        fcnPopupComputeHeadmodel();
                        fncPopupMenuNoiseCov();
                    else
                        fcnPopupMenuGoodBad();
                        fcnPopupClusterTimeSeries();
                        AddSeparator(jPopup);
                    end
                end
                % === SOURCES/TIMEFREQ ===
                if ~bst_get('ReadOnly')
                    fcnPopupComputeSources();
                    fcnPopupProjectSources();
                end
                fcnPopupScoutTimeSeries(jPopup);
                % Export menu (added later)
                jMenuExport = gui_component('MenuItem', [], [], 'Export subject', IconLoader.ICON_SAVE, [], @(h,ev)bst_call(@export_protocol, bst_get('iProtocol'), iSubject), []);
                
%% ===== POPUP: CONDITION =====
            case {'condition', 'rawcondition'}
                if ~bst_get('ReadOnly')
                    isRaw = strcmpi(nodeType, 'rawcondition');
                    % If it is a study node
                    if (bstNodes(1).getStudyIndex() ~= 0) 
                        iStudy   = bstNodes(1).getStudyIndex();
                        iSubject = bstNodes(1).getItemIndex();
                        sSubject = bst_get('Subject', iSubject);
                        % === IMPORT DATA/DIPOLES ===
                        if (length(bstNodes) == 1) && ~isRaw
                            gui_component('MenuItem', jPopup, [], 'Import MEG/EEG', IconLoader.ICON_EEG_NEW, [], @(h,ev)bst_call(@import_data, [], [], iStudy, iSubject), []);
                            gui_component('MenuItem', jPopup, [], 'Import dipoles', IconLoader.ICON_DIPOLES, [], @(h,ev)bst_call(@import_dipoles, iStudy), []);
                            AddSeparator(jPopup);
                        end
                        % If not Default Channel
                        if (sSubject.UseDefaultChannel == 0)
                            % === IMPORT CHANNEL / COMPUTE HEADMODEL ===
                            fcnPopupImportChannel();
                            fcnPopupMenuGoodBad();
                            fcnPopupClusterTimeSeries();
                            fcnPopupComputeHeadmodel();
                            if ~isRaw || (length(bstNodes) == 1)
                                fncPopupMenuNoiseCov();
                            end
                        else
                            fcnPopupMenuGoodBad();
                            fcnPopupClusterTimeSeries();
                            % Separator
                            AddSeparator(jPopup);
                        end
                    else
                        fcnPopupMenuGoodBad();
                        fcnPopupClusterTimeSeries();
                        % Separator
                        AddSeparator(jPopup);
                    end
                    % === SOURCES/TIMEFREQ ===
                    fcnPopupComputeSources();
                    fcnPopupProjectSources();
                    fcnPopupScoutTimeSeries(jPopup);
                    % === GROUP CONDITIONS ===
                    if ~isRaw && (length(bstNodes) >= 2)
                        % Get conditions name list
                        ConditionsPaths = {};
                        for i = 1:length(bstNodes)
                            ConditionsPaths{i} = char(bstNodes(i).getFileName());
                        end
                        % Add separator
                        AddSeparator(jPopup);
                        % Menu "Group conditions"
                        gui_component('MenuItem', jPopup, [], 'Group conditions', IconLoader.ICON_FUSION, [], @(h,ev)bst_call(@db_group_conditions, ConditionsPaths), []);
                    end
                end
                
%% ===== POPUP: STUDY =====
            case 'study'
                if ~bst_get('ReadOnly')
                    iStudy   = bstNodes(1).getStudyIndex();
                    iSubject = bstNodes(1).getItemIndex();
                    sSubject = bst_get('Subject', iSubject);
                    % Get inter-subject study
                    [sInterStudy, iInterStudy] = bst_get('AnalysisInterStudy');
                    % === IMPORT DATA ===
                    if ~isSpecialNode
                        gui_component('MenuItem', jPopup, [], 'Import MEG/EEG', IconLoader.ICON_EEG_NEW, [], @(h,ev)bst_call(@import_data, [], [], iStudy, iSubject), []);
                    end
                    % If not Default Channel
                    if (sSubject.UseDefaultChannel == 0) && (iStudy ~= iInterStudy)
                        % === IMPORT CHANNEL / COMPUTE HEADMODEL ===
                        fcnPopupImportChannel();
                        fcnPopupMenuGoodBad();
                        fcnPopupClusterTimeSeries();
                        fcnPopupComputeHeadmodel();
                        fncPopupMenuNoiseCov();
                    elseif ~isSpecialNode
                        fcnPopupMenuGoodBad();
                        fcnPopupClusterTimeSeries();
                        AddSeparator(jPopup);
                    end
                    % === SOURCES/TIMEFREQ ===
                    fcnPopupComputeSources();
                    fcnPopupProjectSources();
                    fcnPopupScoutTimeSeries(jPopup);
                end
                
%% ===== POPUP: DEFAULT STUDY =====
            case 'defaultstudy'
                iStudy = -3;
                if ~bst_get('ReadOnly')
                    % === IMPORT CHANNEL / COMPUTE HEADMODEL ===
                    fcnPopupImportChannel();
                    fcnPopupComputeHeadmodel();
                    fncPopupMenuNoiseCov();
                    % === COMPUTE SOURCES ===
                    fcnPopupComputeSources();
                    AddSeparator(jPopup);
                end
                
%% ===== POPUP: CHANNEL =====
            case 'channel'
                % === DISPLAY SENSORS ===
                % Get study index
                iStudy = bstNodes(1).getStudyIndex();
                % Get avaible modalities for this data file
                [tmp__, DisplayMod] = bst_get('ChannelModalities', filenameRelative);
                Device = bst_get('ChannelDevice', filenameRelative);
                % If only one modality
                if (length(DisplayMod) == 1) && ((length(bstNodes) ~= 1) || isempty(Device)) && ~ismember(Device, {'Vectorview306', 'CTF', '4D', 'KIT'})
                    gui_component('MenuItem', jPopup, [], 'Display sensors', IconLoader.ICON_CHANNEL, [], @(h,ev)bst_call(@DisplayChannels, bstNodes, DisplayMod{1}), []);
                % More than one modality
                elseif (length(DisplayMod) >= 1)
                    jMenuDisplay = gui_component('Menu', jPopup, [], 'Display sensors', IconLoader.ICON_DISPLAY, [], [], []);
                    % Only if one item selected
                    if (length(bstNodes) == 1) && ismember(Device, {'Vectorview306', 'CTF', '4D', 'KIT'})
                        gui_component('MenuItem', jMenuDisplay, [], [Device ' coils'], IconLoader.ICON_CHANNEL, [], @(h,ev)bst_call(@DisplayChannels, bstNodes, Device), []);
                        gui_component('MenuItem', jMenuDisplay, [], [Device ' helmet'], IconLoader.ICON_CHANNEL, [], @(h,ev)bst_call(@DisplayHelmet, iStudy, filenameFull), []);
                        AddSeparator(jMenuDisplay);
                    end
                    % === ITEM: MODALITIES ===
                    % For each displayable sensor type, display an item in the "display" submenu
                    for iType = 1:length(DisplayMod)
                        channelTypeDisplay = getChannelTypeDisplay(DisplayMod{iType}, DisplayMod);
                        gui_component('MenuItem', jMenuDisplay, [], channelTypeDisplay, IconLoader.ICON_CHANNEL, [], @(h,ev)bst_call(@DisplayChannels, bstNodes, DisplayMod{iType}), []);
                    end
                end
                
                % ONLY IF ONE FILE SELECTED
                if (length(bstNodes) == 1)
                    % === EDIT CHANNEL FILE ===
                    if ~bst_get('ReadOnly')
                        gui_component('MenuItem', jPopup, [], 'Edit channel file', IconLoader.ICON_EDIT, [], @(h,ev)bst_call(@gui_edit_channel, filenameRelative), []);
                    end
                    AddSeparator(jPopup);
                    % === MENU "ALIGN" ===
                    jMenuAlign = gui_component('Menu', jPopup, [], 'MRI registration', IconLoader.ICON_ALIGN_CHANNELS, [], [], []);
                        % === EEG SENSORS ===
                        EEGMod = {'EEG','SEEG','ECOG'};
                        EEGModDisplay = intersect(EEGMod, DisplayMod);
                        if ~isempty(EEGModDisplay)
                            if ismember('MEG', DisplayMod)
                                strType = [' (' EEGModDisplay{1} ')'];
                            else
                                strType = '';
                            end
                            % Check alignment
                            gui_component('MenuItem', jMenuAlign, [], ['Check' strType], IconLoader.ICON_ALIGN_CHANNELS, [], @(h,ev)bst_call(@ChannelCheckAlignment_Callback, iStudy, EEGModDisplay{1}, 0), []);
                            % Align
                            if ~bst_get('ReadOnly')
                                gui_component('MenuItem', jMenuAlign, [], ['Edit...' strType], IconLoader.ICON_ALIGN_CHANNELS, [], @(h,ev)bst_call(@ChannelCheckAlignment_Callback, iStudy, EEGModDisplay{1}, 1), []);
                            end
                            AddSeparator(jMenuAlign);
                        end
                        % === MEG SENSORS ===
                        if ismember('MEG', DisplayMod)
                            if ismember('EEG', DisplayMod)
                                strType = ' (MEG)';
                            else
                                strType = '';
                            end
                            % Check alignment
                            gui_component('MenuItem', jMenuAlign, [], ['Check' strType], IconLoader.ICON_ALIGN_CHANNELS, [], @(h,ev)bst_call(@ChannelCheckAlignment_Callback, iStudy, 'MEG', 0), []);
                            % Align
                            if ~bst_get('ReadOnly')
                                gui_component('MenuItem', jMenuAlign, [], ['Edit...' strType], IconLoader.ICON_ALIGN_CHANNELS, [], @(h,ev)bst_call(@ChannelCheckAlignment_Callback, iStudy, 'MEG', 1), []);
                                AddSeparator(jMenuAlign);
                            end
                        end
                        % Auto MRI registration 
                        if ~bst_get('ReadOnly')
                            gui_component('MenuItem', jMenuAlign, [], 'Refine using head points', IconLoader.ICON_ALIGN_CHANNELS, [], @(h,ev)bst_call(@channel_align_auto, filenameRelative, [], 1, 0), []);
                        end
                    
                    % === MENU: EXTRA HEAD POINTS ===
                    jMenuHeadPoints = gui_component('Menu', jPopup, [], 'Digitized head points', IconLoader.ICON_CHANNEL, [], [], []);
                        % View head points
                        gui_component('MenuItem', jMenuHeadPoints, [], 'View head points', IconLoader.ICON_SURFACE_SCALP, [], @(h,ev)bst_call(@view_headpoints, filenameFull, [], 0), []);
                        % Add head points
                        if ~bst_get('ReadOnly')
                            gui_component('MenuItem', jMenuHeadPoints, [], 'Add points...', IconLoader.ICON_CHANNEL, [], @(h,ev)bst_call(@channel_add_headpoints, filenameFull), []);
                        end
                        % Remove all head points
                        if ~bst_get('ReadOnly')
                            gui_component('MenuItem', jMenuHeadPoints, [], 'Remove all points', IconLoader.ICON_DELETE, [], @(h,ev)bst_call(@channel_remove_headpoints, filenameFull), []);
                        end
                        % WARP
                        if ~bst_get('ReadOnly')
                            AddSeparator(jMenuHeadPoints);
                            jMenuWarp = gui_component('Menu', jMenuHeadPoints, [], 'Warp', IconLoader.ICON_ALIGN_CHANNELS, [], [], []);
                            gui_component('MenuItem', jMenuWarp, [], 'Deform default anatomy to fit these points', IconLoader.ICON_ALIGN_CHANNELS, [], @(h,ev)bst_call(@bst_warp_prepare, filenameFull), []);
                        end
                    % === LOAD SSP PROJECTORS ===
                    if ~bst_get('ReadOnly')
                        gui_component('MenuItem', jPopup, [], 'Load SSP projectors', IconLoader.ICON_CONDITION, [], @(h,ev)bst_call(@import_ssp, filenameFull), []);
                    end
                    % === COMPUTE HEAD MODEL ===
                    if ~bst_get('ReadOnly')
                        fcnPopupComputeHeadmodel();
                    end
                    % === MENU: EXPORT ===
                    % Export menu (added later)
                    jMenuExport = gui_component('MenuItem', [], [], 'Export to file', IconLoader.ICON_SAVE, [], @(h,ev)bst_call(@export_channel, filenameFull), []);
                end
                
%% ===== POPUP: ANATOMY =====
            case 'anatomy'
                % MENU : DISPLAY
                jMenuDisplay = gui_component('Menu', jPopup, [], 'Display', IconLoader.ICON_ANATOMY, [], [], []);
                    gui_component('MenuItem', jMenuDisplay, [], 'MRI Viewer',           IconLoader.ICON_ANATOMY, [], @(h,ev)bst_call(@view_mri, filenameRelative), []);
                    gui_component('MenuItem', jMenuDisplay, [], '3D orthogonal slices', IconLoader.ICON_ANATOMY, [], @(h,ev)bst_call(@view_mri_3d, filenameRelative), []);
                    AddSeparator(jMenuDisplay);
                    gui_component('MenuItem', jMenuDisplay, [], 'Axial slices',    IconLoader.ICON_SLICES,  [], @(h,ev)bst_call(@view_mri_slices, filenameRelative, 'axial', 20), []);
                    gui_component('MenuItem', jMenuDisplay, [], 'Coronal slices',  IconLoader.ICON_SLICES,  [], @(h,ev)bst_call(@view_mri_slices, filenameRelative, 'coronal', 20), []);
                    gui_component('MenuItem', jMenuDisplay, [], 'Sagittal slices', IconLoader.ICON_SLICES,  [], @(h,ev)bst_call(@view_mri_slices, filenameRelative, 'sagittal', 20), []);
                    AddSeparator(jMenuDisplay);
                    gui_component('MenuItem', jMenuDisplay, [], 'Histogram', IconLoader.ICON_HISTOGRAM, [], @(h,ev)bst_call(@view_mri_histogram, filenameFull), []);
                % === MENU: EDIT MRI ===
                if ~bst_get('ReadOnly')
                    gui_component('MenuItem', jPopup, [], 'Edit MRI...', IconLoader.ICON_ANATOMY, [], @(h,ev)bst_call(@view_mri, filenameRelative, 'EditMri'), []);
                end
                % === MENU: GENERATE HEAD SURFACE ===
                if ~bst_get('ReadOnly')
                    AddSeparator(jPopup);
                    gui_component('MenuItem', jPopup, [], 'Generate head surface', IconLoader.ICON_SURFACE_SCALP, [], @(h,ev)bst_call(@tess_isohead, filenameRelative), []);
                end
                % === MENU: EXPORT ===
                % Export menu (added later)
                jMenuExport = gui_component('MenuItem', [], [], 'Export to file', IconLoader.ICON_SAVE, [], @(h,ev)bst_call(@export_mri, filenameFull), []);
                    

%% ===== POPUP: SURFACE =====
            case {'scalp', 'cortex', 'outerskull', 'innerskull', 'other'}
                % Get subject
                iSubject = bstNodes(1).getStudyIndex();
                sSubject = bst_get('Subject', iSubject);
                
                % === DISPLAY ===
                gui_component('MenuItem', jPopup, [], 'Display', IconLoader.ICON_DISPLAY, [], @(h,ev)bst_call(@view_surface, filenameRelative), []);

                % === SET SURFACE TYPE ===
                if ~bst_get('ReadOnly')
                    jItemSetSurfType = gui_component('Menu', jPopup, [], 'Set surface type', IconLoader.ICON_SURFACE, [], [], []);
                    jItemSetSurfTypeScalp      = gui_component('MenuItem', jItemSetSurfType, [], 'Scalp',       IconLoader.ICON_SURFACE_SCALP, [], @(h,ev)bst_call(@node_set_type, bstNodes(1), 'Scalp'), []);
                    jItemSetSurfTypeCortex     = gui_component('MenuItem', jItemSetSurfType, [], 'Cortex',      IconLoader.ICON_SURFACE_CORTEX, [], @(h,ev)bst_call(@node_set_type, bstNodes(1), 'Cortex'), []);
                    jItemSetSurfTypeOuterSkull = gui_component('MenuItem', jItemSetSurfType, [], 'Outer skull', IconLoader.ICON_SURFACE_OUTERSKULL, [], @(h,ev)bst_call(@node_set_type, bstNodes(1), 'OuterSkull'), []);
                    jItemSetSurfTypeInnerSkull = gui_component('MenuItem', jItemSetSurfType, [], 'Inner skull', IconLoader.ICON_SURFACE_INNERSKULL, [], @(h,ev)bst_call(@node_set_type, bstNodes(1), 'InnerSkull'), []);
                    jItemSetSurfTypeOther      = gui_component('MenuItem', jItemSetSurfType, [], 'Other',       IconLoader.ICON_SURFACE, [], @(h,ev)bst_call(@node_set_type, bstNodes(1), 'Other'), []);
                    % Check current type
                    switch (nodeType)
                        case 'scalp'
                            jItemSetSurfTypeScalp.setSelected(1);
                        case 'cortex'
                            jItemSetSurfTypeCortex.setSelected(1);
                        case 'outerskull'
                            jItemSetSurfTypeOuterSkull.setSelected(1);
                        case 'innerskull'
                            jItemSetSurfTypeInnerSkull.setSelected(1);
                        case 'other'
                            jItemSetSurfTypeOther.setSelected(1);
                    end
                end
                
                % SET AS DEFAULT SURFACE
                if ~bst_get('ReadOnly')
                    iSurface = bstNodes(1).getItemIndex();
                    switch lower(nodeType)
                        case 'scalp',      SurfaceType = 'Scalp';
                        case 'innerskull', SurfaceType = 'InnerSkull';
                        case 'outerskull', SurfaceType = 'OuterSkull';
                        case 'cortex',     SurfaceType = 'Cortex';
                        case 'other',      SurfaceType = 'Other';
                    end
                    if (~ismember(iSurface, sSubject.(['i' SurfaceType])) || ~bstNodes(1).isMarked()) && ~strcmpi(nodeType, 'other')
                        gui_component('MenuItem', jPopup, [], ['Set as default ' lower(nodeType)], IconLoader.ICON_GOOD, [], @(h,ev)bst_call(@SetDefaultSurf, iSubject, SurfaceType, iSurface), []);
                    end            
                    % Separator
                    AddSeparator(jPopup);
                end
                % NUMBER OF SELECTED FILES
                if (length(bstNodes) >= 2)
                    if ~bst_get('ReadOnly')
                        gui_component('MenuItem', jPopup, [], 'Less vertices...', IconLoader.ICON_DOWNSAMPLE, [], @(h,ev)bst_call(@tess_downsize, GetAllFilenames(bstNodes)), []);
                        gui_component('MenuItem', jPopup, [], 'Merge surfaces',   IconLoader.ICON_FUSION, [], @(h,ev)bst_call(@SurfaceConcatenate, GetAllFilenames(bstNodes)), []);
                        gui_component('MenuItem', jPopup, [], 'Average surfaces', IconLoader.ICON_SURFACE_ADD, [], @(h,ev)bst_call(@SurfaceAverage, GetAllFilenames(bstNodes)), []);
                    end
                else
                    % === MENU: "ALIGN WITH MRI" ===
                    jMenuAlign = gui_component('Menu', jPopup, [], 'MRI registration', IconLoader.ICON_ALIGN_SURFACES, [], [], []);
                        % === CHECK ALIGNMENT WITH MRI ===
                        gui_component('MenuItem', jMenuAlign, [], 'Check MRI/surface registration...', IconLoader.ICON_CHECK_ALIGN, [], @(h,ev)bst_call(@SurfaceCheckAlignment_Callback, bstNodes(1)), []);
                        % No read-only
                        if ~bst_get('ReadOnly')
                            AddSeparator(jMenuAlign);
                            % === ALIGN ALL SURFACES ===
                            gui_component('MenuItem', jMenuAlign, [], 'Edit fiducials...', IconLoader.ICON_ALIGN_SURFACES, [], @(h,ev)bst_call(@tess_align_fiducials, filenameRelative, {sSubject.Surface.FileName}), []);
                            % === MENU: ALIGN SURFACE MANUALLY ===
                            jMenuAlignManual = gui_component('Menu', jPopup, [], 'Align manually on...', IconLoader.ICON_ALIGN_SURFACES, [], [], []);
                                % ADD ANATOMIES
                                for iAnat = 1:length(sSubject.Anatomy)
                                    fullAnatFile = bst_fullfile(ProtocolInfo.SUBJECTS, sSubject.Anatomy(iAnat).FileName);
                                    gui_component('MenuItem', jMenuAlignManual, [], sSubject.Anatomy(iAnat).Comment, IconLoader.ICON_ANATOMY, [], @(h,ev)bst_call(@tess_align_manual, fullAnatFile, filenameFull), []);
                                end
                                % ADD SURFACES
                                for iSurf = 1:length(sSubject.Surface)
                                    % Ignore itself
                                    fullSurfFile = bst_fullfile(ProtocolInfo.SUBJECTS, sSubject.Surface(iSurf).FileName);
                                    if ~file_compare(fullSurfFile, filenameFull)
                                        gui_component('MenuItem', jMenuAlignManual, [], sSubject.Surface(iSurf).Comment, IconLoader.ICON_SURFACE, [], @(h,ev)bst_call(@tess_align_manual, fullSurfFile, filenameFull), []);
                                    end
                                end
                            % === MENU: LOAD FREESURFER SPHERE ===
                            AddSeparator(jMenuAlign);
                            gui_component('MenuItem', jMenuAlign, [], 'Load FreeSurfer sphere...', IconLoader.ICON_FOLDER_OPEN, [], @(h,ev)bst_call(@TessAddSphere, filenameRelative), []);
                            gui_component('MenuItem', jMenuAlign, [], 'Display FreeSurfer sphere', IconLoader.ICON_DISPLAY,     [], @(h,ev)bst_call(@view_surface_sphere, filenameRelative), []);
                        end
                
                    % No read-only
                    if ~bst_get('ReadOnly')
                        gui_component('MenuItem', jPopup, [], 'Less vertices...', IconLoader.ICON_DOWNSAMPLE, [], @(h,ev)bst_call(@tess_downsize, filenameFull, [], []), []);
                        gui_component('MenuItem', jPopup, [], 'Remesh...', IconLoader.ICON_FLIP, [], @(h,ev)bst_call(@tess_remesh, filenameFull), []);
                        gui_component('MenuItem', jPopup, [], 'Swap faces', IconLoader.ICON_FLIP, [], @(h,ev)bst_call(@SurfaceSwapFaces_Callback, filenameFull), []);
                        if strcmpi(nodeType, 'scalp')
                            gui_component('MenuItem', jPopup, [], 'Fill holes', IconLoader.ICON_RECYCLE, [], @(h,ev)bst_call(@SurfaceFillHoles_Callback, filenameFull), []);
                        end
                        gui_component('MenuItem', jPopup, [], 'Remove interpolations', IconLoader.ICON_RECYCLE, [], @(h,ev)bst_call(@SurfaceClean_Callback, filenameFull, 0), []);
                        gui_component('MenuItem', jPopup, [], 'Clean surface',         IconLoader.ICON_RECYCLE, [], @(h,ev)bst_call(@SurfaceClean_Callback, filenameFull, 1), []);
                    end
                end
                % === MENU: EXPORT ===
                % Export menu (added later)
                jMenuExport = gui_component('MenuItem', [], [], 'Export to file', IconLoader.ICON_SAVE, [], @(h,ev)bst_call(@export_surfaces, filenameFull), []);
                
                
%% ===== POPUP: NOISECOV =====
            case 'noisecov'
                if (length(bstNodes) == 1)
                    % Get modalities for first selected file
                    AllMod = bst_get('ChannelModalities', filenameRelative);
                    % Display as image
                    if (length(AllMod) == 1)
                        gui_component('MenuItem', jPopup, [], 'Display as image', IconLoader.ICON_NOISECOV, [], @(h,ev)bst_call(@view_noisecov, filenameRelative), []);
                    elseif (length(AllMod) > 1)
                        % All sensors
                        jMenuDisplay = gui_component('Menu', jPopup, [], 'Display as image', IconLoader.ICON_NOISECOV, [], [], []);
                        gui_component('MenuItem', jMenuDisplay, [], 'All sensors', IconLoader.ICON_NOISECOV, [], @(h,ev)bst_call(@view_noisecov, filenameRelative), []);
                        AddSeparator(jMenuDisplay);
                        % Each sensor type independently
                        for i = 1:length(AllMod)
                            gui_component('MenuItem', jMenuDisplay, [], AllMod{i}, IconLoader.ICON_NOISECOV, [], @(h,ev)bst_call(@view_noisecov, filenameRelative, AllMod{i}), []);
                        end
                    end
                    % Apply 
                    if ~bst_get('ReadOnly')
                        % Apply to all conditions/subjects
                        AddSeparator(jPopup);
                        gui_component('MenuItem', jPopup, [], 'Copy to other conditions', IconLoader.ICON_HEADMODEL, [], @(h,ev)bst_call(@db_set_noisecov, bstNodes(1).getStudyIndex(), 'AllConditions'), []);
                        gui_component('MenuItem', jPopup, [], 'Copy to other subjects',   IconLoader.ICON_HEADMODEL, [], @(h,ev)bst_call(@db_set_noisecov, bstNodes(1).getStudyIndex(), 'AllSubjects'), []);
                    end
                end
                
%% ===== POPUP: HEADMODEL =====
            case 'headmodel'
                % Get study description
                iStudy = bstNodes(1).getStudyIndex();
                sStudy = bst_get('Study', iStudy);
                iHeadModel = bstNodes(1).getItemIndex();
                if ~isempty(sStudy.Channel)
                    ChannelFile = bst_fullfile(ProtocolInfo.STUDIES, sStudy.Channel.FileName);
                else
                    ChannelFile = [];
                end
                
                % SET AS DEFAULT HEADMODEL
                if ~bst_get('ReadOnly')
                    if (~ismember(iHeadModel, sStudy.iHeadModel) || ~bstNodes(1).isMarked())
                        gui_component('MenuItem', jPopup, [], ['Set as default ' lower(nodeType)], IconLoader.ICON_GOOD, [], @(h,ev)bst_call(@SetDefaultHeadModel, bstNodes(1), iHeadModel, iStudy, sStudy), []);
                        AddSeparator(jPopup);
                    end
                end
                
                % === COMPUTE SOURCES ===
                if ~bst_get('ReadOnly')
                    gui_component('MenuItem', jPopup, [], 'Compute sources', IconLoader.ICON_RESULTS, [], @(h,ev)bst_call(@selectHeadmodelAndComputeSources, bstNodes), []);
                end
                % === CHECK SPHERES ===
                MEGMethod = sStudy.HeadModel(iHeadModel).MEGMethod;
                EEGMethod = sStudy.HeadModel(iHeadModel).EEGMethod;
                if ~isempty(ChannelFile) && ~strcmpi(sStudy.HeadModel(iHeadModel).HeadModelType, 'dba') && ...
                        ((~isempty(MEGMethod) && ismember(MEGMethod, {'os_meg', 'meg_sphere'})) || (~isempty(EEGMethod) && strcmpi(EEGMethod, 'eeg_3sphereberg')))
                    [sSubject, iSubject] = bst_get('Subject', sStudy.BrainStormSubject);
                    % Create menu item
                    gui_component('MenuItem', jPopup, [], 'Check spheres', IconLoader.ICON_HEADMODEL, [], @(h,ev)bst_call(@view_spheres, filenameFull, ChannelFile, sSubject), []);
                end
                
%% ===== POPUP: DATA =====
            case {'data', 'rawdata'}
                % Get study description
                iStudy = bstNodes(1).getStudyIndex();
                sStudy = bst_get('Study', iStudy);
                iData = bstNodes(1).getItemIndex();
                % Data type
                DataType = sStudy.Data(iData).DataType;
                isStat = ~strcmpi(DataType, 'recordings') && ~strcmpi(DataType, 'raw');
                % Get modalities for first selected file
                [AllMod, DisplayMod] = bst_get('ChannelModalities', filenameRelative);
                % Remove EDF Annotation channels from the list
                iEDF = find(strcmpi(AllMod, 'EDF') | strcmpi(AllMod, 'BDF'));
                if ~isempty(iEDF)
                    AllMod(iEDF) = [];
                end
                % One data file selected only
                if (length(bstNodes) == 1)
                    % Get associated subject and surfaces, if it exists
                    [sSubject, iSubject] = bst_get('Subject', sStudy.BrainStormSubject);
                    % RAW continuous files
                    if ~bst_get('ReadOnly') && ~isStat
                        % Import in database
                        gui_component('MenuItem', jPopup, [], 'Import in database', IconLoader.ICON_EEG_NEW, [], @(h,ev)bst_call(@import_raw_to_db, filenameRelative), []);
                        % Load file descriptor
                        ChannelFile = bst_get('ChannelFileForStudy', filenameRelative);
                        if ~isempty(ChannelFile) && strcmpi(DataType, 'raw')
                            Device = bst_get('ChannelDevice', ChannelFile);
                            % If CTF file format
                            if strcmpi(Device, 'CTF')
                                gui_component('MenuItem', jPopup, [], 'Switch epoched/continous', IconLoader.ICON_RAW_DATA, [], @(h,ev)bst_process('CallProcess', 'process_ctf_convert', filenameFull, [], 'rectype', 3, 'interactive', 1), []);
                            end
                        end
                        % Separator
                        AddSeparator(jPopup);
                    end
                    % If some modalities defined
                    if ~isempty(AllMod)
                        % For each modality, display a menu
                        for iMod = 1:length(AllMod)
                            % Make the sensor type more user-friendly
                            channelTypeDisplay = getChannelTypeDisplay(AllMod{iMod}, AllMod);
                            % Create the menu
                            jMenuModality = gui_component('Menu', jPopup, [], channelTypeDisplay, IconLoader.ICON_DATA, [], [], []);
                            % === DISPLAY TIME SERIES ===
                            gui_component('MenuItem', jMenuModality, [], 'Display time series', IconLoader.ICON_TS_DISPLAY, [], @(h,ev)bst_call(@view_timeseries, filenameRelative, AllMod{iMod}, [], 'NewFigure'), []);
                            % == DISPLAY TOPOGRAPHY ==
                            if ismember(AllMod{iMod}, {'EEG', 'MEG', 'MEG MAG', 'MEG GRAD', 'ECOG'}) && ~isempty(DisplayMod) && ismember(AllMod{iMod}, DisplayMod)
                                fcnPopupDisplayTopography(jMenuModality, filenameRelative, AllMod, AllMod{iMod}, isStat);
                            end
                            % === DISPLAY ON SCALP ===
                            % => ONLY for EEG, and if a scalp is defined
                            if strcmpi(AllMod{iMod}, 'EEG') && ~isempty(sSubject) && ~isempty(sSubject.iScalp) && ~isempty(DisplayMod) && ismember(AllMod{iMod}, DisplayMod)
                                AddSeparator(jMenuModality);
                                gui_component('MenuItem', jMenuModality, [], 'Display on scalp', IconLoader.ICON_SURFACE_SCALP, [], @(h,ev)bst_call(@view_surface_data, sSubject.Surface(sSubject.iScalp).FileName, filenameRelative, AllMod{iMod}), []);
                            end
                        end
                                                
                        % === GOOD/BAD CHANNELS===
                        if ~bst_get('ReadOnly')
                            % MENU
                            jPopupMenuGoodBad = fcnPopupMenuGoodBad();
                            AddSeparator(jPopupMenuGoodBad);
                            % EDIT GOOD/BAD
                            gui_component('MenuItem', jPopupMenuGoodBad, [], 'Edit good/bad channels...', IconLoader.ICON_GOODBAD, [], @(h,ev)bst_call(@gui_edit_channelflag, char(bstNodes(1).getFileName())), []);
                            % === GOOD/BAD TRIAL ===
                            if strcmpi(DataType, 'recordings')
                                if (bstNodes(1).getModifier() == 0)
                                    gui_component('MenuItem', jPopup, [], 'Reject trial', IconLoader.ICON_BAD, [], @(h,ev)bst_call(@process_detectbad, 'SetTrialStatus', bstNodes, 1), []);
                                else
                                    gui_component('MenuItem', jPopup, [], 'Accept trial', IconLoader.ICON_GOOD, [], @(h,ev)bst_call(@process_detectbad, 'SetTrialStatus', bstNodes, 0), []);
                                end
                            end
                        end
                    % Cannot access channel file => plot raw Data.F matrix
                    else
                        % === WARNING: NO CHANNEL ===
                        gui_component('MenuItem', jPopup, [], 'No channel file', IconLoader.ICON_WARNING, [], [], []);
                        AddSeparator(jPopup);
                        % === DISPLAY TIME SERIES ===
                        if ~strcmpi(DataType, 'raw')
                            gui_component('MenuItem', jPopup, [], 'Display time series', IconLoader.ICON_TS_DISPLAY, [], @(h,ev)bst_call(@view_timeseries, filenameRelative), []);
                        end
                    end
                    % ADDED LATER, IN "FILE" SUBMENU
                    % === MENU: SET NUMBER OF TRIALS ===
                    if ~bst_get('ReadOnly') && strcmpi(DataType, 'recordings')
                        gui_component('MenuItem', jPopup, [], 'Set number of trials', IconLoader.ICON_DATA_LIST, [], @(h,ev)bst_call(@SetNavgData, filenameFull), []);
                    end
                else
                    % Good/bad channels
                    fcnPopupMenuGoodBad();
                    AddSeparator(jPopup);
                    % === GOOD/BAD TRIAL ===
                    if ~bst_get('ReadOnly') && strcmpi(DataType, 'recordings')
                        gui_component('MenuItem', jPopup, [], 'Reject trials', IconLoader.ICON_BAD,  [], @(h,ev)bst_call(@process_detectbad, 'SetTrialStatus', bstNodes, 1), []);
                        gui_component('MenuItem', jPopup, [], 'Accept trials', IconLoader.ICON_GOOD, [], @(h,ev)bst_call(@process_detectbad, 'SetTrialStatus', bstNodes, 0), []);
                    end
                end
                % === MENU: EXPORT ===
                if ~strcmpi(DataType, 'raw')
                    jMenuExport = gui_component('MenuItem', [], [], 'Export to file', IconLoader.ICON_SAVE, [], @(h,ev)bst_call(@export_data, GetAllFilenames(bstNodes)), []);
                end
                % === VIEW CLUSTERS ===
                if ~isempty(AllMod)
                    fcnPopupClusterTimeSeries();
                end
                        
                % INVERSE SOLUTIONS
                if ~bst_get('ReadOnly') && ~isempty(AllMod) && ismember(DataType, {'raw', 'recordings'})
                    % Get subject and inter-subject study
                    sSubject = bst_get('Subject', sStudy.BrainStormSubject);
                    [sInterStudy, iInterStudy] = bst_get('AnalysisInterStudy');
                    % === COMPUTE SOURCES ===
                    % If not Default Channel
                    if (sSubject.UseDefaultChannel == 0) && (iStudy ~= iInterStudy)
                        fcnPopupComputeHeadmodel();
                    else
                        AddSeparator(jPopup);    
                    end
                    if strcmpi(DataType, 'recordings') || (length(bstNodes) == 1)
                        fncPopupMenuNoiseCov();
                    end
                    fcnPopupComputeSources();
                    fcnPopupProjectSources();
                    fcnPopupScoutTimeSeries(jPopup);
                end
               
%% ===== POPUP: STAT/DATA =====
            case 'pdata'
                % Get protocol description
                iStudy = bstNodes(1).getStudyIndex();
                sStudy = bst_get('Study', iStudy);
                % Get avaible modalities for this data file
                [AllMod, DisplayMod] = bst_get('ChannelModalities', filenameRelative);
                % One data file selected only
                if (length(bstNodes) == 1)
                    % === VIEW RESULTS ===
                    % Get associated subject and surfaces, if it exists
                    sSubject = bst_get('Subject', sStudy.BrainStormSubject);
                    % If channel file is defined and at least one modality
                    if ~isempty(AllMod)
                        % For each modality, display a menu
                        for iMod = 1:length(AllMod)
                            % Make the sensor type more user-friendly
                            channelTypeDisplay = getChannelTypeDisplay(AllMod{iMod}, AllMod);
                            % Create menu
                            jMenuModality = gui_component('Menu', jPopup, [], channelTypeDisplay, IconLoader.ICON_DATA, [], [], []);
                            % === DISPLAY TIME SERIES ===
                            gui_component('MenuItem', jMenuModality, [], 'Display time series', IconLoader.ICON_TS_DISPLAY, [], @(h,ev)bst_call(@view_timeseries, filenameRelative, AllMod{iMod}), []);
                            % == DISPLAY TOPOGRAPHY ==
                            if ismember(AllMod{iMod}, {'EEG', 'MEG', 'MEG MAG', 'MEG GRAD', 'ECOG'}) && ...
                                ~(strcmpi(AllMod{iMod}, 'MEG') && all(ismember({'MEG MAG', 'MEG GRAD'}, AllMod))) && ...
                                ~isempty(DisplayMod) && ismember(AllMod{iMod}, DisplayMod)
                                fcnPopupDisplayTopography(jMenuModality, filenameRelative, AllMod, AllMod{iMod}, 1);
                            end
                            % === DISPLAY ON SCALP ===
                            if strcmpi(AllMod{iMod}, 'EEG') && ~isempty(sSubject) && ~isempty(sSubject.iScalp) && ~isempty(DisplayMod) && ismember(AllMod{iMod}, DisplayMod)
                                AddSeparator(jMenuModality);
                                gui_component('MenuItem', jMenuModality, [], 'Display on scalp', IconLoader.ICON_SURFACE_SCALP, [], @(h,ev)bst_call(@view_surface_data, sSubject.Surface(sSubject.iScalp).FileName, filenameRelative, AllMod{iMod}), []);
                            end
                        end
                        
                        % === VIEW CLUSTERS ===
                        fcnPopupClusterTimeSeries();
                        
                        % === GOOD/BAD CHANNELS===
                        if ~bst_get('ReadOnly') && (length(bstNodes) == 1)
                            % MENU
                            jPopupMenuGoodBad = fcnPopupMenuGoodBad();
                            AddSeparator(jPopupMenuGoodBad);
                            % EDIT GOOD/BAD
                            gui_component('MenuItem', jPopupMenuGoodBad, [], 'Edit good/bad channels...', IconLoader.ICON_GOODBAD, [], @(h,ev)bst_call(@gui_edit_channelflag, char(bstNodes(1).getFileName())), []);
                        end
                    % Cannot access channel file => plot raw Data.F matrix
                    else
                        % === WARNING: NO CHANNEL ===
                        gui_component('MenuItem', jPopup, [], 'No channel file', IconLoader.ICON_WARNING, [], [], []);
                        AddSeparator(jPopup);
                        % === DISPLAY TIME SERIES ===
                        gui_component('MenuItem', jPopup, [], 'Display time series', IconLoader.ICON_TS_DISPLAY, [], @(h,ev)bst_call(@view_timeseries, filenameRelative), []);
                    end
                end

                
%% ===== POPUP: DATA LIST =====
            case 'datalist'                
                if ~bst_get('ReadOnly')
                    % Good/bad channels
                    fcnPopupMenuGoodBad();
                    fcnPopupClusterTimeSeries();
                    AddSeparator(jPopup);
                    % Good/bad trials
                    gui_component('MenuItem', jPopup, [], 'Reject trials', IconLoader.ICON_BAD,  [], @(h,ev)bst_call(@process_detectbad, 'SetTrialStatus', bstNodes, 1), []);
                    gui_component('MenuItem', jPopup, [], 'Accept trials', IconLoader.ICON_GOOD, [], @(h,ev)bst_call(@process_detectbad, 'SetTrialStatus', bstNodes, 0), []);
                    AddSeparator(jPopup);
                    % === COMPUTE SOURCES ===
                    fncPopupMenuNoiseCov();
                    % === MENU: EXPORT ===
                    jMenuExport = gui_component('MenuItem', [], [], 'Export to file', IconLoader.ICON_SAVE, [], @(h,ev)bst_call(@export_data, GetAllFilenames(bstNodes, 'data')), []);
                end
                
%% ===== POPUP: RESULTS =====
            case {'results', 'link'}
                isLink = strcmpi(nodeType, 'link');
                % Get study
                iStudy = bstNodes(1).getStudyIndex();
                sStudy = bst_get('Study', iStudy);
                iResult = bstNodes(1).getItemIndex();
                % Get associated subject
                [sSubject, iSubject] = bst_get('Subject', sStudy.BrainStormSubject);
                % FOR FIRST NODE: Get associated recordings (DataFile)
                DataFile = sStudy.Result(iResult).DataFile;
                isVolumeGrid = ismember(sStudy.Result(iResult).HeadModelType, {'volume', 'dba'});
                isStat = ~isempty(strfind(filenameRelative, '_pthresh'));
                % Get type of data node
                isRaw = 0;
                if ~isempty(DataFile)
                    [tmp__, tmp__, iData] = bst_get('DataFile', DataFile, iStudy);
                    if ~isempty(iData)
                        isRaw = strcmpi(sStudy.Data(iData).DataType, 'raw');
                    end
                end
                
                % IF NOT A STAND-ALONE KERNEL-ONLY RESULTS NODE
                % === MENU: CORTICAL ACTIVATIONS ===
                jMenuActivations = gui_component('Menu', jPopup, [], 'Cortical activations', IconLoader.ICON_RESULTS, [], [], []);

                % ONE RESULTS FILE SELECTED
                if (length(bstNodes) == 1) 
                    % === DISPLAY ON CORTEX ===
                    if ~isVolumeGrid
                        if ~isempty(sSubject) && ~isempty(sSubject.iCortex)
                            gui_component('MenuItem', jMenuActivations, [], 'Display on cortex', IconLoader.ICON_CORTEX, [], @(h,ev)bst_call(@view_surface_data, [], filenameRelative), []);
                        else
                            gui_component('MenuItem', jMenuActivations, [], 'No cortex available', IconLoader.ICON_WARNING, [], [], []);
                        end
                    end
                    % === DISPLAY ON MRI ===
                    if ~isempty(sSubject) && ~isempty(sSubject.iAnatomy)
                        gui_component('MenuItem', jMenuActivations, [], 'Display on MRI (3D)', IconLoader.ICON_ANATOMY, [], @(h,ev)bst_call(@view_surface_data, sSubject.Anatomy(sSubject.iAnatomy).FileName, filenameRelative), []);
                        gui_component('MenuItem', jMenuActivations, [], 'Display on MRI (MRI Viewer)', IconLoader.ICON_ANATOMY, [], @(h,ev)bst_call(@view_mri, sSubject.Anatomy(sSubject.iAnatomy).FileName, filenameRelative), []);
                    else
                        gui_component('MenuItem', jMenuActivations, [], 'No MRI available', IconLoader.ICON_WARNING, [], [], []);
                    end
                    % === DISPLAY ON SPHERE ===
                    if ~isVolumeGrid && ~isempty(sSubject) && ~isempty(sSubject.iCortex)
                        AddSeparator(jMenuActivations);
                        gui_component('MenuItem', jMenuActivations, [], 'Display on spheres', IconLoader.ICON_SURFACE, [], @(h,ev)bst_call(@view_surface_sphere, filenameRelative), []);
                    end
                end

                % === VIEW SCOUTS ===
                fcnPopupScoutTimeSeries(jMenuActivations, 1);

                % === MENU: SIMULATE DATA ===
                [tmp__, iDefStudy]   = bst_get('DefaultStudy', iSubject);
                if ~bst_get('ReadOnly') && ~isRaw && ~ismember(iStudy, iDefStudy) && ~isempty(strfind(filenameRelative, '_wMNE')) && ~isStat
                    jMenuModality = gui_component('Menu', jPopup, [], 'Model evaluation', IconLoader.ICON_RESULTS, [], [], []);
                    gui_component('MenuItem', jMenuModality, [], 'Simulate recordings', IconLoader.ICON_TS_DISPLAY, [], @(h,ev)bst_call(@bst_simulation, filenameRelative), []);
                end
                
                % === VIEW BAD CHANNELS ===
                if ~isStat
                    gui_component('MenuItem', jPopup, [], 'View bad channels', IconLoader.ICON_BAD, [], @(h,ev)bst_call(@tree_set_channelflag, bstNodes, 'ShowBad'), []);
                end
                
                % === PROJECT ON DEFAULT ANATOMY ===
                % If subject does not use default anatomy
                if ~bst_get('ReadOnly') && ~isRaw && ~isVolumeGrid && ~isStat
                    fcnPopupProjectSources(1);
                end
                
                % === PLUG-INS ===
                if ~bst_get('ReadOnly') && ~isRaw && ~isLink && (length(bstNodes) == 1) && ~isStat
                    AddSeparator(jPopup);
                    jMenuPlugins = gui_component('Menu', jPopup, [], 'Plug-ins', IconLoader.ICON_CONDITION, [], [], []);
                        % === OPTICAL FLOW ===
                        if (sSubject.iCortex)
                            gui_component('MenuItem', jMenuPlugins, [], '[Experimental] Optical flow', IconLoader.ICON_CONDITION, [], @(h,ev)panel_opticalflow('Compute', filenameRelative), []);
                        end
                end
                
                % === MENU: EXPORT ===
                % Added later...
                if ~isRaw && (length(bstNodes) == 1) && ~isStat
                    jMenuExport{1} = gui_component('MenuItem', [], [], 'Export as 4D matrix', IconLoader.ICON_SAVE, [], @(h,ev)panel_process_select('ShowPanelForFile', {filenameFull}, 'process_export_spmvol'), []);
%                     if ~isVolumeGrid
%                         jMenuExport{2} = gui_component('MenuItem', [], [], 'Export to SPM12', IconLoader.ICON_SAVE, [], @(h,ev)panel_process_select('ShowPanelForFile', {filenameFull}, 'process_export_spmsurf'), []);
%                     end
                end

                
%% ===== POPUP: SHARED RESULTS KERNEL =====
            case 'kernel'
                gui_component('MenuItem', jPopup, [], 'Inversion kernel', IconLoader.ICON_WARNING, [], [], []);
                
                
%% ===== POPUP: STAT/RESULTS =====
            case 'presults'
                % ONE RESULTS FILE SELECTED
                if (length(bstNodes) == 1)
                    % Get study
                    iStudy = bstNodes(1).getStudyIndex();
                    sStudy = bst_get('Study', iStudy);
                    % Get associated subject and surfaces, if it exists
                    sSubject = bst_get('Subject', sStudy.BrainStormSubject);
                    isVolumeGrid = 0;

                    % === MENU: CORTICAL ACTIVATIONS ===
                    jMenuActivations = gui_component('Menu', jPopup, [], 'Cortical activations', IconLoader.ICON_RESULTS, [], [], []);
                        % === DISPLAY ON CORTEX ===
                        if ~isempty(sSubject) && ~isempty(sSubject.iCortex) && ~isVolumeGrid
                            gui_component('MenuItem', jMenuActivations, [], 'Display on cortex', IconLoader.ICON_CORTEX, [], @(h,ev)bst_call(@view_surface_data, [], filenameRelative), []);
                        end
                        % === DISPLAY ON MRI ===
                        if ~isempty(sSubject) && ~isempty(sSubject.iAnatomy)
                            gui_component('MenuItem', jMenuActivations, [], 'Display on MRI (3D)', IconLoader.ICON_ANATOMY, [], @(h,ev)bst_call(@view_surface_data, sSubject.Anatomy(sSubject.iAnatomy).FileName, filenameRelative), []);
                            gui_component('MenuItem', jMenuActivations, [], 'Display on MRI (MRI Viewer)', IconLoader.ICON_ANATOMY, [], @(h,ev)bst_call(@view_mri, sSubject.Anatomy(sSubject.iAnatomy).FileName, filenameRelative), []);
                        else
                            gui_component('MenuItem', jMenuActivations, [], 'No MRI available', IconLoader.ICON_WARNING, [], [], []);
                        end
                end
                % === VIEW SCOUTS ===
                fcnPopupScoutTimeSeries(jMenuActivations, 1);

                
                
%% ===== POPUP: DIPOLES =====
            case 'dipoles'
                % ONE DIPOLES FILE SELECTED
                if (length(bstNodes) == 1)
                    gui_component('MenuItem', jPopup, [], 'Display on MRI (3D)', IconLoader.ICON_DIPOLES, [], @(h,ev)bst_call(@view_dipoles, filenameRelative, 'Mri3D'), []);
                    gui_component('MenuItem', jPopup, [], 'Display on cortex',   IconLoader.ICON_DIPOLES, [], @(h,ev)bst_call(@view_dipoles, filenameRelative, 'Cortex'), []);
                    AddSeparator(jPopup);
                    gui_component('MenuItem', jPopup, [], 'Display in MRI Viewer', IconLoader.ICON_DIPOLES, [], @(h,ev)bst_call(@view_dipoles, filenameRelative, 'MriViewer'), []);
                end
                
%% ===== POPUP: TIME-FREQ =====
            case {'timefreq', 'ptimefreq'}
                % Get study description
                iStudy = bstNodes(1).getStudyIndex();
                iTimefreq = bstNodes(1).getItemIndex();
                sStudy = bst_get('Study', iStudy);
                % Get data type
                if strcmpi(char(bstNodes(1).getType()), 'ptimefreq')
                    TimefreqMat = in_bst_timefreq(filenameRelative, 0, 'DataType');
                    if ~isempty(TimefreqMat.DataType)
                        DataType = TimefreqMat.DataType;
                    else
                        DataType = 'matrix';
                    end
                    DataFile = [];
                else
                    DataType = sStudy.Timefreq(iTimefreq).DataType;
                    DataFile = sStudy.Timefreq(iTimefreq).DataFile;
                end
                % One file selected
                if (length(bstNodes) == 1)
                    % ===== NxN CONNECTIVITY =====
                    if ~isempty(strfind(filenameRelative, '_connectn'))
                        gui_component('MenuItem', jPopup, [], 'Connectivity graph (full)',   IconLoader.ICON_CONNECTN, [], @(h,ev)bst_call(@view_connect, filenameRelative, 'GraphFull'), []);
                        %gui_component('MenuItem', jPopup, [], 'Connectivity graph (3D)',   IconLoader.ICON_CONNECTN, [], @(h,ev)bst_call(@view_connect, filenameRelative, '3DGraph'));
                        %gui_component('MenuItem', jPopup, [], 'Connectivity graph (groups)', IconLoader.ICON_CONNECTN, [], @(h,ev)bst_call(@view_connect, filenameRelative, 'GraphGroups'));
                        AddSeparator(jPopup);
                        gui_component('MenuItem', jPopup, [], 'Display as image', IconLoader.ICON_NOISECOV, [], @(h,ev)bst_call(@view_connect, filenameRelative, 'Image'), []);
                    end
                    % ===== PAC: FULL MAPS =====
                    if ~isempty(strfind(filenameRelative, '_pac_fullmaps'))
                        gui_component('MenuItem', jPopup, [], 'DirectPAC maps', IconLoader.ICON_PAC, [], @(h,ev)bst_call(@view_pac, filenameRelative));
                        AddSeparator(jPopup);
                    elseif ~isempty(strfind(filenameRelative, '_dpac_fullmaps'))
                        jMenuPac = gui_component('Menu', jPopup, [], 'DynamicPAC maps', IconLoader.ICON_PAC, [], [], []);
                            gui_component('MenuItem', jMenuPac, [], 'One channel', IconLoader.ICON_PAC, [], @(h,ev)bst_call(@view_pac, filenameRelative, [], 'DynamicPAC', 'SingleSensor'), []);
                            if strcmpi(DataType, 'data') || strcmpi(DataType, 'matrix')
                                gui_component('MenuItem', jMenuPac, [], 'All channels',   IconLoader.ICON_PAC,      [], @(h,ev)bst_call(@view_pac, filenameRelative, [], 'DynamicPAC', 'AllSensors'), []);
                                gui_component('MenuItem', jMenuPac, [], 'Power spectrum', IconLoader.ICON_SPECTRUM, [], @(h,ev)bst_call(@view_pac, filenameRelative, [], 'DynamicPAC', 'Spectrum'), []);
                                gui_component('MenuItem', jMenuPac, [], 'Time series',    IconLoader.ICON_DATA,     [], @(h,ev)bst_call(@view_pac, filenameRelative, [], 'DynamicPAC', 'TimeSeries'), []);
                            end
                            if strcmpi(DataType, 'data')
                                AddSeparator(jMenuPac);
                                gui_component('MenuItem', jMenuPac, [], '3D Sensor cap', IconLoader.ICON_TOPOGRAPHY, [], @(h,ev)bst_call(@view_pac, filenameRelative, [], 'DynamicPAC', '3DSensorCap'), []);
                                gui_component('MenuItem', jMenuPac, [], '2D Sensor cap', IconLoader.ICON_TOPOGRAPHY, [], @(h,ev)bst_call(@view_pac, filenameRelative, [], 'DynamicPAC', '2DSensorCap'), []);
                                gui_component('MenuItem', jMenuPac, [], '2D Disc',       IconLoader.ICON_TOPOGRAPHY, [], @(h,ev)bst_call(@view_pac, filenameRelative, [], 'DynamicPAC', '2DDisc'), []);
                            end
                        jMenuPac = gui_component('Menu', jPopup, [], 'DynamicNesting maps', IconLoader.ICON_PAC, [], [], []);
                            gui_component('MenuItem', jMenuPac, [], 'One channel',  IconLoader.ICON_PAC, [], @(h,ev)bst_call(@view_pac, filenameRelative, [], 'DynamicNesting', 'SingleSensor'), []);
                            if strcmpi(DataType, 'data') || strcmpi(DataType, 'matrix')
                                gui_component('MenuItem', jMenuPac, [], 'All channels',   IconLoader.ICON_PAC,      [], @(h,ev)bst_call(@view_pac, filenameRelative, [], 'DynamicNesting', 'AllSensors'), []);
                                gui_component('MenuItem', jMenuPac, [], 'Power spectrum', IconLoader.ICON_SPECTRUM, [], @(h,ev)bst_call(@view_pac, filenameRelative, [], 'DynamicNesting', 'Spectrum'), []);
                                gui_component('MenuItem', jMenuPac, [], 'Time series',    IconLoader.ICON_DATA,     [], @(h,ev)bst_call(@view_pac, filenameRelative, [], 'DynamicNesting', 'TimeSeries'), []);
                            end
                            if strcmpi(DataType, 'data')
                                AddSeparator(jMenuPac);
                                gui_component('MenuItem', jMenuPac, [], '3D Sensor cap', IconLoader.ICON_TOPOGRAPHY, [], @(h,ev)bst_call(@view_pac, filenameRelative, [], 'DynamicNesting', '3DSensorCap'), []);
                                gui_component('MenuItem', jMenuPac, [], '2D Sensor cap', IconLoader.ICON_TOPOGRAPHY, [], @(h,ev)bst_call(@view_pac, filenameRelative, [], 'DynamicNesting', '2DSensorCap'), []);
                                gui_component('MenuItem', jMenuPac, [], '2D Disc',       IconLoader.ICON_TOPOGRAPHY, [], @(h,ev)bst_call(@view_pac, filenameRelative, [], 'DynamicNesting', '2DDisc'), []);
                            end
                        AddSeparator(jPopup);
                    end
                    
                    % ===== RECORDINGS =====
                    if strcmpi(DataType, 'data')
                        % No connectivity
                        if isempty(strfind(filenameRelative, '_connect1')) && isempty(strfind(filenameRelative, '_connectn')) && isempty(strfind(filenameRelative, '_pac')) && isempty(strfind(filenameRelative, '_dpac')) 
                            gui_component('MenuItem', jPopup, [], 'One channel',            IconLoader.ICON_TIMEFREQ, [], @(h,ev)bst_call(@view_timefreq, filenameFull, 'SingleSensor'), []);
                            gui_component('MenuItem', jPopup, [], 'All channels',           IconLoader.ICON_TIMEFREQ, [], @(h,ev)bst_call(@view_timefreq, filenameFull, 'AllSensors'), []);
                            gui_component('MenuItem', jPopup, [], '2D Layout (maps)',       IconLoader.ICON_TIMEFREQ, [], @(h,ev)bst_call(@view_timefreq, filenameFull, '2DLayout'), []);
                            gui_component('MenuItem', jPopup, [], '2D Layout (no overlap)', IconLoader.ICON_TIMEFREQ, [], @(h,ev)bst_call(@view_timefreq, filenameFull, '2DLayoutOpt'), []);
                            AddSeparator(jPopup);
                            gui_component('MenuItem', jPopup, [], 'Power spectrum', IconLoader.ICON_SPECTRUM, [], @(h,ev)bst_call(@view_spectrum, filenameRelative, 'Spectrum'), []);
                            gui_component('MenuItem', jPopup, [], 'Time series',    IconLoader.ICON_DATA,     [], @(h,ev)bst_call(@view_spectrum, filenameRelative, 'TimeSeries'), []);
                            AddSeparator(jPopup);
                        end
                        % Only connect1/cohere
                        if ~isempty(strfind(filenameRelative, '_connect1_cohere'))
                            gui_component('MenuItem', jPopup, [], 'Power spectrum', IconLoader.ICON_SPECTRUM, [], @(h,ev)bst_call(@view_spectrum, filenameRelative, 'Spectrum'), []);
                            AddSeparator(jPopup);
                        end
                        % No connectN
                        if isempty(strfind(filenameRelative, '_connectn'))
                            gui_component('MenuItem', jPopup, [], '3D Sensor cap', IconLoader.ICON_TOPOGRAPHY, [], @(h,ev)bst_call(@view_topography, filenameRelative, [], '3DSensorCap', [], 0), []);
                            gui_component('MenuItem', jPopup, [], '2D Sensor cap', IconLoader.ICON_TOPOGRAPHY, [], @(h,ev)bst_call(@view_topography, filenameRelative, [], '2DSensorCap', [], 0), []);
                            gui_component('MenuItem', jPopup, [], '2D Disc',       IconLoader.ICON_TOPOGRAPHY, [], @(h,ev)bst_call(@view_topography, filenameRelative, [], '2DDisc',      [], 0), []);
                        end
                        % No connect, no PAC
                        if isempty(strfind(filenameRelative, '_connectn')) && isempty(strfind(filenameRelative, '_connect1')) && isempty(strfind(filenameRelative, '_pac')) && isempty(strfind(filenameRelative, '_dpac')) 
                            gui_component('MenuItem', jPopup, [], '2D Layout', IconLoader.ICON_2DLAYOUT, [], @(h,ev)bst_call(@view_topography, filenameRelative, [], '2DLayout', [], 0), []);
                        end
                    % ===== SOURCES =====
                    elseif strcmpi(DataType, 'results')
                        % No connectivity 
                        if isempty(strfind(filenameRelative, '_connectn'))
                            sSubject = bst_get('Subject', sStudy.BrainStormSubject);
                            % One channel only
                            gui_component('MenuItem', jPopup, [], 'One channel', IconLoader.ICON_TIMEFREQ, [], @(h,ev)bst_call(@view_timefreq, filenameFull, 'SingleSensor'), []);
                            AddSeparator(jPopup);
                            % Get head model type for the sources file
                            if ~isempty(DataFile)
                                [sStudyData, iStudyData, iResult] = bst_get('AnyFile', DataFile);
                                if ~isempty(sStudyData)
                                    isVolume = ismember(sStudyData.Result(iResult).HeadModelType, {'volume', 'dba'});
                                else
                                    disp('BST> Error: This file was linked to a source file that was deleted.');
                                    isVolume = 0;
                                end
                            % Else, read from the file if there is a GridLoc field
                            else
                                w = whos('-file', file_fullpath(filenameRelative), 'GridLoc');
                                isVolume = (prod(w.size) > 0);                                
                            end
                            % Cortex / MRI
                            if ~isempty(sSubject) && ~isempty(sSubject.iCortex) && ~isVolume
                                gui_component('MenuItem', jPopup, [], 'Display on cortex', IconLoader.ICON_CORTEX, [], @(h,ev)bst_call(@view_surface_data, [], filenameRelative), []);
                            end
                            if ~isempty(sSubject) && ~isempty(sSubject.iAnatomy)
                                MriFile = sSubject.Anatomy(sSubject.iAnatomy).FileName;
                                gui_component('MenuItem', jPopup, [], 'Display on MRI (3D)',         IconLoader.ICON_ANATOMY, [], @(h,ev)bst_call(@view_surface_data, MriFile, filenameRelative), []);
                                gui_component('MenuItem', jPopup, [], 'Display on MRI (MRI Viewer)', IconLoader.ICON_ANATOMY, [], @(h,ev)bst_call(@view_mri, MriFile, filenameRelative), []);
                            end
                        end
                    % ===== CLUSTERS/SCOUTS =====
                    else
                        strType = DataType;
                        if strcmpi(strType, 'matrix')
                            strTypeS = 'matrices';
                        else
                            strTypeS = [strType, 's'];
                        end
                        if isempty(strfind(filenameRelative, '_connectn')) && isempty(strfind(filenameRelative, '_connect1')) && isempty(strfind(filenameRelative, '_pac')) && isempty(strfind(filenameRelative, '_dpac')) 
                            gui_component('MenuItem', jPopup, [], ['Time-freq: One ' strType],  IconLoader.ICON_TIMEFREQ, [], @(h,ev)bst_call(@view_timefreq, filenameFull, 'SingleSensor'), []);
                            gui_component('MenuItem', jPopup, [], ['Time-freq: All ' strTypeS], IconLoader.ICON_TIMEFREQ, [], @(h,ev)bst_call(@view_timefreq, filenameFull, 'AllSensors'), []);
                            AddSeparator(jPopup);
                            gui_component('MenuItem', jPopup, [], 'Power spectrum', IconLoader.ICON_SPECTRUM, [], @(h,ev)bst_call(@view_spectrum, filenameRelative, 'Spectrum'), []);
                            gui_component('MenuItem', jPopup, [], 'Time series',    IconLoader.ICON_DATA,     [], @(h,ev)bst_call(@view_spectrum, filenameRelative, 'TimeSeries'), []);
                        end
                    end
                end
                % Project sources
                if strcmpi(DataType, 'results') && isempty(strfind(filenameRelative, '_KERNEL_'))
                    fcnPopupProjectSources(1);
                end
                
                
%% ===== POPUP: SPECTRUM =====
            case 'spectrum'
                % Get study description
                iStudy = bstNodes(1).getStudyIndex();
                iTimefreq = bstNodes(1).getItemIndex();
                sStudy = bst_get('Study', iStudy);
                % One file selected
                if (length(bstNodes) == 1)
                    % ===== RECORDINGS =====
                    if strcmpi(sStudy.Timefreq(iTimefreq).DataType, 'data')
                        gui_component('MenuItem', jPopup, [], 'Power spectrum', IconLoader.ICON_SPECTRUM, [], @(h,ev)bst_call(@view_spectrum, filenameRelative, 'Spectrum'), []);
                        AddSeparator(jPopup);
                        gui_component('MenuItem', jPopup, [], '3D Sensor cap', IconLoader.ICON_TOPOGRAPHY, [], @(h,ev)bst_call(@view_topography, filenameRelative, [], '3DSensorCap', [], 0), []);
                        gui_component('MenuItem', jPopup, [], '2D Sensor cap', IconLoader.ICON_TOPOGRAPHY, [], @(h,ev)bst_call(@view_topography, filenameRelative, [], '2DSensorCap', [], 0), []);
                        gui_component('MenuItem', jPopup, [], '2D Disc',       IconLoader.ICON_TOPOGRAPHY, [], @(h,ev)bst_call(@view_topography, filenameRelative, [], '2DDisc',      [], 0), []);
                    % ===== SOURCES =====
                    elseif strcmpi(sStudy.Timefreq(iTimefreq).DataType, 'results')
                        AddSeparator(jPopup);
                        % Get head model type for the sources file
                        if ~isempty(sStudy.Timefreq(iTimefreq).DataFile)
                            [sStudyData, iStudyData, iResult] = bst_get('AnyFile', sStudy.Timefreq(iTimefreq).DataFile);
                            isVolume = ismember(sStudyData.Result(iResult).HeadModelType, {'volume', 'dba'});
                        % Get the default head model
                        else
                            isVolume = 0;
                        end
                        % Get subject structure
                        sSubject = bst_get('Subject', sStudy.BrainStormSubject);
                        % Cortex / MRI
                        if ~isempty(sSubject) && ~isempty(sSubject.iCortex) && ~isVolume
                            gui_component('MenuItem', jPopup, [], 'Display on cortex', IconLoader.ICON_CORTEX, [], @(h,ev)bst_call(@view_surface_data, [], filenameRelative), []);
                        end
                        if ~isempty(sSubject) && ~isempty(sSubject.iAnatomy)
                            MriFile = sSubject.Anatomy(sSubject.iAnatomy).FileName;
                            gui_component('MenuItem', jPopup, [], 'Display on MRI (3D)',         IconLoader.ICON_ANATOMY, [], @(h,ev)bst_call(@view_surface_data, MriFile, filenameRelative), []);
                            gui_component('MenuItem', jPopup, [], 'Display on MRI (MRI Viewer)', IconLoader.ICON_ANATOMY, [], @(h,ev)bst_call(@view_mri, MriFile, filenameRelative), []);
                        end
                    % ===== CLUSTERS/SCOUTS =====
                    else
                        gui_component('MenuItem', jPopup, [], 'Power spectrum', IconLoader.ICON_SPECTRUM, [], @(h,ev)bst_call(@view_spectrum, filenameRelative, 'Spectrum'), []);
                    end
                end
                % Project sources
                if strcmpi(sStudy.Timefreq(iTimefreq).DataType, 'results') && isempty(strfind(filenameRelative, '_KERNEL_'))
                    fcnPopupProjectSources(1);
                end
                
                
%% ===== POPUP: IMAGE =====
            case 'image'
                % ONE IMAGE SELECTED
                if (length(bstNodes) == 1)
                    gui_component('MenuItem', jPopup, [], 'View image', IconLoader.ICON_IMAGE, [], @(h,ev)bst_call(@view_image, filenameFull), []);
                end
                
%% ===== POPUP: MATRIX =====
            case 'matrix'
                gui_component('MenuItem', jPopup, [], 'Display as time series', IconLoader.ICON_TS_DISPLAY, [], @(h,ev)bst_call(@view_matrix, filenameFull, 'TimeSeries'), []);
                gui_component('MenuItem', jPopup, [], 'Display as image',       IconLoader.ICON_NOISECOV,   [], @(h,ev)bst_call(@view_matrix, filenameFull, 'Image'), []);
                gui_component('MenuItem', jPopup, [], 'Display as table',       IconLoader.ICON_MATRIX,     [], @(h,ev)bst_call(@view_matrix, filenameFull, 'Table'), []);
        end
        
%% ===== POPUP: COMMON MENUS =====
        % Add generic buttons, that can be applied to all nodes
        % If popup is not empty : add a separator
        AddSeparator(jPopup);
        % Properties of the selection
        isone = (length(bstNodes) == 1);
        isfile = ~isempty(filenameFull);
        isstudy = (ismember(nodeType, {'study', 'studysubject', 'defaultstudy', 'condition', 'rawcondition'}) && ~isempty(iStudy) && (iStudy ~= 0));
        issubject = strcmpi(nodeType, 'subject') && ~isempty(iSubject);
        
        % ===== MENU FILE =====
        jMenuFile = gui_component('Menu', [], [], 'File', IconLoader.ICON_MATLAB, [], [], []);
            % ===== VIEW FILE =====
            if isone && isfile && ~ismember(nodeType, {'subject', 'study', 'studysubject', 'condition', 'rawcondition', 'datalist', 'image'})
                gui_component('MenuItem', jMenuFile, [], 'View file contents', IconLoader.ICON_MATLAB, [], @(h,ev)bst_call(@view_struct, filenameFull), []);
                gui_component('MenuItem', jMenuFile, [], 'View file history', IconLoader.ICON_MATLAB, [], @(h,ev)bst_call(@bst_history, 'view', filenameFull), []);
                AddSeparator(jMenuFile);
            end
            % ===== EXPORT SUBMENU =====
            if ~isempty(jMenuExport)
                if iscell(jMenuExport)
                    for i = 1:length(jMenuExport)
                        if ischar(jMenuExport{i}) && strcmpi(jMenuExport{i}, 'separator')
                            AddSeparator(jMenuFile);
                        else
                            jMenuFile.add(jMenuExport{i});
                        end
                    end 
                else
                    jMenuFile.add(jMenuExport);
                end
            end
            % ===== EXPORT TO MATLAB VARIABLE =====
            if isfile && isMatlabRunning && ~ismember(nodeType, {'study', 'studysubject', 'defaultstudy', 'condition', 'rawcondition', 'subject','datalist'})
                gui_component('MenuItem', jMenuFile, [], 'Export to Matlab', IconLoader.ICON_MATLAB_EXPORT, [], @(h,ev)bst_call(@export_matlab, bstNodes), []);
            end
            % ===== IMPORT FROM MATLAB VARIABLE =====
            if ~bst_get('ReadOnly') && isone && isMatlabRunning
                if isstudy
                    gui_component('MenuItem', jMenuFile, [], 'Import from Matlab', IconLoader.ICON_MATLAB_IMPORT, [], @(h,ev)bst_call(@db_add, iStudy), []);
                    gui_component('MenuItem', jMenuFile, [], 'Import source maps', IconLoader.ICON_RESULTS, [], @(h,ev)bst_call(@import_sources, iStudy), []);
                elseif issubject
                    gui_component('MenuItem', jMenuFile, [], 'Import from Matlab', IconLoader.ICON_MATLAB_IMPORT, [], @(h,ev)bst_call(@db_add, iSubject), []);
                elseif isfile && ~ismember(nodeType, {'study', 'studysubject', 'defaultstudy', 'condition', 'rawcondition', 'subject', 'link', 'datalist', 'image'})
                    gui_component('MenuItem', jMenuFile, [], 'Import from Matlab', IconLoader.ICON_MATLAB_IMPORT, [], @(h,ev)bst_call(@node_import, bstNodes(1)), []);
                end
            end
            % ===== RAW FILE =====
            if ~bst_get('ReadOnly') && isone && isfile && strcmpi(nodeType, 'rawdata')
                AddSeparator(jMenuFile);
                gui_component('MenuItem', jMenuFile, [], 'Fix broken link', IconLoader.ICON_RAW_DATA, [], @(h,ev)panel_record('FixFileLink', filenameRelative), []);
                gui_component('MenuItem', jMenuFile, [], 'Delete raw file', IconLoader.ICON_RAW_DATA, [], @(h,ev)panel_record('DeleteRawFile', filenameRelative), []);
            end
            if isone && isfile && strcmpi(nodeType, 'rawdata') % && strcmpi(Device, 'CTF')
                gui_component('Menu', jMenuFile, [], 'Extra acquisition files', IconLoader.ICON_RAW_DATA, [], @(h,ev)CreateCtfFiles(ev.getSource(), filenameFull), []);
            end
            if ~bst_get('ReadOnly') && isone && isstudy && strcmpi(nodeType, 'rawcondition')
                AddSeparator(jMenuFile);
                gui_component('MenuItem', jMenuFile, [], 'Delete raw file', IconLoader.ICON_RAW_DATA, [], @(h,ev)panel_record('DeleteRawFile', filenameRelative), []);
            end
            AddSeparator(jMenuFile);
           
            % ===== OTHER MENUS =====
            if isone && ~isempty(jMenuFileOther)
                jMenuFile.add(jMenuFileOther);
                AddSeparator(jMenuFile);
            end
            % ===== COPY/CUT =====
            if ~bst_get('ReadOnly') && isfile && ~isSpecialNode && ~isstudy && ~issubject && ~ismember(nodeType, {'studysubject','condition','datalist','link','rawcondition','rawdata'})
                jItem = gui_component('MenuItem', jMenuFile, [], 'Copy', IconLoader.ICON_COPY, [], @(h,ev)panel_protocols('CopyNode', bstNodes, 0), []);
                jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_C, KeyEvent.CTRL_MASK));
                jItem = gui_component('MenuItem', jMenuFile, [], 'Cut',  IconLoader.ICON_CUT, [], @(h,ev)panel_protocols('CopyNode', bstNodes, 1), []);
                jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_X, KeyEvent.CTRL_MASK));
            end
            % ===== PASTE =====
            if ~bst_get('ReadOnly') && isone && (isstudy || issubject) && ~isempty(bst_get('Clipboard'))
                jItem = gui_component('MenuItem', jMenuFile, [], 'Paste',  IconLoader.ICON_PASTE, [], @(h,ev)panel_protocols('PasteNode', bstNodes), []);
                jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_V, KeyEvent.CTRL_MASK));
            end
            % ===== DELETE =====
            if ~bst_get('ReadOnly') && ~isSpecialNode && ~ismember(nodeType, {'defaultstudy', 'link'})
                jItem = gui_component('MenuItem', jMenuFile, [], 'Delete', IconLoader.ICON_DELETE, [], @(h,ev)bst_call(@node_delete, bstNodes), []);
                jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_DELETE, 0));
            end
            % ===== RENAME =====
            if ~bst_get('ReadOnly') && isone && isfile && ~isSpecialNode && ~ismember(nodeType, {'link', 'image'})
                jItem = gui_component('MenuItem', jMenuFile, [], 'Rename', IconLoader.ICON_EDIT, [], @(h,ev)bst_call(@EditNode_Callback, bstNodes(1)), []);
                jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_F2, 0));
            end
            % ===== DUPLICATE =====
            if ~bst_get('ReadOnly') && isone && ~isSpecialNode
                if ismember(nodeType, {'data', 'results', 'timefreq', 'spectrum', 'matrix'})
                    gui_component('MenuItem', jMenuFile, [], 'Duplicate file', IconLoader.ICON_COPY, [], @(h,ev)bst_call(@process_duplicate, 'DuplicateData', filenameRelative, '_copy'), []);
                elseif ismember(nodeType, {'studysubject', 'subject'})
                    gui_component('MenuItem', jMenuFile, [], 'Duplicate subject', IconLoader.ICON_COPY, [], @(h,ev)bst_call(@process_duplicate, 'DuplicateSubject', bst_fileparts(filenameRelative), '_copy'), []);
                elseif strcmpi(nodeType, 'condition') && (bstNodes(1).getStudyIndex ~= 0)
                    gui_component('MenuItem', jMenuFile, [], 'Duplicate condition', IconLoader.ICON_COPY, [], @(h,ev)bst_call(@process_duplicate, 'DuplicateCondition', filenameRelative, '_copy'), []);
                end
            end
            % ===== SEND TO PROCESS ======
            if ~bst_get('ReadOnly') && ismember(nodeType, {'studydbsubj', 'studydbcond', 'study', 'studysubject', 'data', 'datalist', 'results', 'resultslist', 'link', 'timefreq', 'spectrum', 'matrix', 'rawdata', 'rawcondition'})
                AddSeparator(jMenuFile);
                jMenuProcess = gui_component('Menu', jMenuFile, [], 'Process', IconLoader.ICON_PROCESS, [], [], []);
                    gui_component('MenuItem', jMenuProcess, [], 'Add to Process1',    IconLoader.ICON_PROCESS, [], @(h,ev)panel_nodelist('AddNodes', 'Process1',  bstNodes), []);
                    gui_component('MenuItem', jMenuProcess, [], 'Add to Process2(A)', IconLoader.ICON_PROCESS, [], @(h,ev)panel_nodelist('AddNodes', 'Process2A', bstNodes), []);
                    gui_component('MenuItem', jMenuProcess, [], 'Add to Process2(B)', IconLoader.ICON_PROCESS, [], @(h,ev)panel_nodelist('AddNodes', 'Process2B', bstNodes), []);
            end
            % ===== LOCATE FILE/FOLDER =====
            if isone && isfile && ~ismember(nodeType, {'datalist'})
                AddSeparator(jMenuFile);
                % Target file
                if strcmpi(nodeType, 'link')
                    destfile = file_resolve_link(filenameFull);
                elseif any(filenameFull == '*')
                    istar = find(filenameFull == '*');
                    destfile = filenameFull(1:istar-1);
                else
                    destfile = filenameFull;
                end
                % Target folder
                if isdir(destfile)
                    destfolder = destfile;
                else
                    destfolder = bst_fileparts(destfile);
                end
                % ===== COPY TO CLIPBOARD =====
                gui_component('MenuItem', jMenuFile, [], 'Copy file path to clipboard', IconLoader.ICON_COPY, [], @(h,ev)bst_call(@clipboard, 'copy', filenameFull), []);

                % ===== GO TO THIS DIRECTORY ======
                if isMatlabRunning
                    gui_component('MenuItem', jMenuFile, [], 'Go to this directory (Matlab)', IconLoader.ICON_MATLAB, [], @(h,ev)cd(destfolder), []);
                end
                % ===== LOCATE ON DISK =====
                % Open terminal in this folder
                if ~strncmp(computer, 'PC', 2)
                    gui_component('MenuItem', jMenuFile, [], 'Open terminal in this folder', IconLoader.ICON_TERMINAL, [], @(h,ev)bst_call(@bst_which, destfolder, 'terminal'), []);
                end
                % Select file in system's file explorer
                if ~strcmpi(nodeType, 'link')
                    gui_component('MenuItem', jMenuFile, [], 'Show in file explorer', IconLoader.ICON_EXPLORER, [], @(h,ev)bst_call(@bst_which, destfile, 'explorer'), []);
                end
            end
        % Add File menu to popup
        if (jMenuFile.getMenuComponentCount() > 0)
            jPopup.add(jMenuFile);
        end
        % ===== RELOAD =====
        if isone && ismember(nodeType, {'subjectdb', 'studydbsubj', 'studydbcond', 'subject', 'study', 'studysubject', 'condition', 'rawcondition', 'defaultstudy'})
            gui_component('MenuItem', jPopup, [], 'Reload', IconLoader.ICON_RELOAD, [], @(h,ev)panel_protocols('ReloadNode', bstNodes(1)), []);
        end
end % END SWITCH( ACTION )




%% ================================================================================================
%  ===== POPUP SHORTCUTS ==========================================================================
%  ================================================================================================
%% ===== MENU: IMPORT CHANNEL =====
    function fcnPopupImportChannel()
        import org.brainstorm.icon.*;
        % Get all studies
        iAllStudies = tree_channel_studies( bstNodes );
        
        % === IMPORT CHANNEL ===
        gui_component('MenuItem', jPopup, [], 'Import channel file', IconLoader.ICON_CHANNEL, [], @(h,ev)bst_call(@import_channel, iAllStudies), []);
        % === USE DEFAULT CHANNEL FILE ===
        if (length(bstNodes) == 1)
            % Get registered Brainstorm EEG defaults
            bstDefaults = bst_get('EegDefaults');
            if ~isempty(bstDefaults)
                jMenuDefaults = gui_component('Menu', jPopup, [], 'Use default EEG cap', IconLoader.ICON_CHANNEL, [], [], []);
                % Add a directory per template block available
                for iDir = 1:length(bstDefaults)
                    jMenuDir = gui_component('Menu', jMenuDefaults, [], bstDefaults(iDir).name, IconLoader.ICON_FOLDER_CLOSE, [], [], []);
                    % Add an item per Template available
                    fList = bstDefaults(iDir).contents;
                    for iFile = 1:length(fList)
                        gui_component('MenuItem', jMenuDir, [], fList(iFile).name, IconLoader.ICON_CHANNEL, [], @(h,ev)bst_call(@db_set_channel, iAllStudies, fList(iFile).fullpath, 1, 0), []);
                    end
                end
            end
        end
    end

%% ===== MENU: GOOD/BAD CHANNELS =====
    function jMenu = fcnPopupMenuGoodBad()
        import org.brainstorm.icon.*;
        jMenu = gui_component('Menu', jPopup, [], 'Good/bad channels', IconLoader.ICON_GOODBAD, [], [], []);
        gui_component('MenuItem', jMenu, [], 'Mark some channels as good...', IconLoader.ICON_GOOD, [], @(h,ev)bst_call(@tree_set_channelflag, bstNodes, 'ClearBad'), []);
        gui_component('MenuItem', jMenu, [], 'Mark all channels as good',     IconLoader.ICON_GOOD, [], @(h,ev)bst_call(@tree_set_channelflag, bstNodes, 'ClearAllBad'), []);
        gui_component('MenuItem', jMenu, [], 'Mark some channels as bad...',  IconLoader.ICON_BAD,  [], @(h,ev)bst_call(@tree_set_channelflag, bstNodes, 'AddBad'), []);
        gui_component('MenuItem', jMenu, [], 'Mark flat channels as bad',     IconLoader.ICON_BAD,  [], @(h,ev)bst_call(@tree_set_channelflag, bstNodes, 'DetectFlat'), []);
        gui_component('MenuItem', jMenu, [], 'View all bad channels',         IconLoader.ICON_BAD,  [], @(h,ev)bst_call(@tree_set_channelflag, bstNodes, 'ShowBad'), []);
    end
%% ===== MENU: HEADMODEL =====
    function fcnPopupComputeHeadmodel()   
        import org.brainstorm.icon.*;
        AddSeparator(jPopup);
        gui_component('MenuItem', jPopup, [], 'Compute head model', IconLoader.ICON_HEADMODEL, [], @(h,ev)bst_call(@panel_protocols, 'TreeHeadModel', bstNodes), []);
    end
%% ===== MENU: NOISE COV =====
    function fncPopupMenuNoiseCov()
        import org.brainstorm.icon.*;
        jMenu = gui_component('Menu', jPopup, [], 'Noise covariance', IconLoader.ICON_NOISECOV, [], [], []);
        gui_component('MenuItem', jMenu, [], 'Import from file',   IconLoader.ICON_NOISECOV, [], @(h,ev)bst_call(@tree_set_noisecov, bstNodes), []);
        gui_component('MenuItem', jMenu, [], 'Import from Matlab', IconLoader.ICON_NOISECOV, [], @(h,ev)bst_call(@tree_set_noisecov, bstNodes, 'MatlabVar'), []);
        AddSeparator(jMenu);
        gui_component('MenuItem', jMenu, [], 'Compute from recordings', IconLoader.ICON_NOISECOV, [], @(h,ev)bst_call(@tree_set_noisecov, bstNodes, 'Compute'), []);
        AddSeparator(jMenu);
        gui_component('MenuItem', jMenu, [], 'No noise modeling (identity matrix)', IconLoader.ICON_NOISECOV, [], @(h,ev)bst_call(@tree_set_noisecov, bstNodes, 'Identity'), []);
    end

%% ===== MENU: COMPUTE SOURCES =====
    function fcnPopupComputeSources()         
        import org.brainstorm.icon.*;
        gui_component('MenuItem', jPopup, [], 'Compute sources', IconLoader.ICON_RESULTS, [], @(h,ev)bst_call(@panel_protocols, 'TreeInverse', bstNodes), []);
    end

%% ===== MENU: PROJECT ON DEFAULT ANATOMY =====
    % Offer the projection of the source files on the default anatomy, and if possible to a single subject
    function fcnPopupProjectSources(isSeparator)
        import org.brainstorm.icon.*;
        % Default: no separator
        if (nargin == 0) || isempty(isSeparator)
            isSeparator = 0;
        end
        % Get node type
        if strcmpi(nodeType, 'timefreq') || strcmpi(nodeType, 'spectrum')
            for iNode = 1:length(bstNodes)
                ResultFiles{iNode} = char(bstNodes(iNode).getFileName());
                iStudies(iNode) = bstNodes(iNode).getStudyIndex();
            end
            % Get all the studies
            sStudies = bst_get('Study', iStudies);
        else
            % Get all the Results files that are classified in the input nodes
            [iStudies, iResults] = tree_dependencies(bstNodes, 'results');
            if isempty(iResults) 
                return;
            elseif isequal(iStudies, -10)
                disp('BST> Error in tree_dependencies.');
                return;
            end
            % Get all the studies
            sStudies = bst_get('Study', iStudies);
            % Build results files list
            for iRes = 1:length(iResults)
                ResultFiles{iRes} = sStudies(iRes).Result(iResults(iRes)).FileName;
            end
        end
        % Get all the subjects
        SubjectFiles = unique({sStudies.BrainStormSubject});
        nCortex = 0;
        
        % ===== SINGLE SUBJECT =====
        sCortex = [];
        % If only one subject: offer to reproject the sources on it
        if (length(SubjectFiles) == 1)
            % Get subject
            [sSubject, iSubject] = bst_get('Subject', SubjectFiles{1});
            % If not using default anat and there is more than one cortex
            if ~sSubject.UseDefaultAnat && ~isempty(sSubject.iCortex)
                % Get all cortex surfaces
                sCortex = bst_get('SurfaceFileByType', iSubject, 'Cortex', 0);
                nCortex = length(sCortex);
            end
            UseDefaultAnat = sSubject.UseDefaultAnat;
        % If more than one subject: just check if the subjects are using default anatomy
        else
            for iSubj = 1:length(SubjectFiles)
                sSubjects(iSubj) = bst_get('Subject', SubjectFiles{iSubj});
            end
            UseDefaultAnat = any([sSubjects.UseDefaultAnat]);
        end

        % ===== DEFAULT ANATOMY =====
        % Get all cortex surfaces for default subject
        sDefCortex = bst_get('SurfaceFileByType', 0, 'Cortex', 0);
        nCortex = nCortex + length(sDefCortex);
        
        % ===== CREATE MENUS =====
        % Show a "Project sources" menu if there are more than one cortex avaiable
        % or if there is one default cortex and subjects do not use default anatomy
        if (nCortex > 1) || ((nCortex == 1) && ~isempty(sDefCortex) && ~UseDefaultAnat)
            if isSeparator
                AddSeparator(jPopup);
            end
            jMenu = gui_component('Menu', jPopup, [], sprintf('Project sources (%d)', length(ResultFiles)), IconLoader.ICON_RESULTS_LIST, [], [], []);
            % === DEFAULT ANAT ===
            if ~isempty(sDefCortex)
                jMenuDef = gui_component('Menu', jMenu, [], 'Default anatomy', IconLoader.ICON_SUBJECT, [], [], []);
                % Loop on all the cortex surfaces
                for iCort = 1:length(sDefCortex)
                    gui_component('MenuItem', jMenuDef, [], sDefCortex(iCort).Comment, IconLoader.ICON_CORTEX, [], @(h,ev)bst_call(@bst_project_sources, ResultFiles, sDefCortex(iCort).FileName), []);
                end
            end
            % === INIDIVIDUAL SUBJECT ===
            if ~isempty(sCortex)
                jMenuSubj = gui_component('Menu', jMenu, [], sSubject.Name, IconLoader.ICON_SUBJECT, [], [], []);
                % Loop on all the cortex surfaces
                for iCort = 1:length(sCortex)
                    gui_component('MenuItem', jMenuSubj, [], sCortex(iCort).Comment, IconLoader.ICON_CORTEX, [], @(h,ev)bst_call(@bst_project_sources, ResultFiles, sCortex(iCort).FileName), []);
                end
            end
        end
    end

%% ===== MENU: CLUSTERS TIME SERIES =====
    function fcnPopupClusterTimeSeries()
        import org.brainstorm.icon.*;
        if ~isempty(GlobalData.Clusters)
            gui_component('MenuItem', jPopup, [], 'Clusters time series', IconLoader.ICON_TS_DISPLAY, [], @(h,ev)bst_call(@tree_view_clusters, bstNodes), []);
        end
    end

%% ===== MENU: SCOUT TIME SERIES =====
    function fcnPopupScoutTimeSeries(jMenu, isSeparator)
        import org.brainstorm.icon.*;
        if (nargin < 2) || isempty(isSeparator)
            isSeparator = 0;
        end
        %if ~isempty(panel_scout('GetScouts'))
            if isSeparator
                AddSeparator(jMenu);
            end
            gui_component('MenuItem', jMenu, [], 'Scouts time series', IconLoader.ICON_TS_DISPLAY, [], @(h,ev)bst_call(@tree_view_scouts, bstNodes), []);
        %end
    end
end % END FUNCTION



%% ================================================================================================
%  === CALLBACKS ==================================================================================
%  ================================================================================================
%% ===== EDIT NODE =====
function EditNode_Callback(node)
    % Get tree handle
    ctrl = bst_get('PanelControls', 'protocols');
    if isempty(ctrl) || isempty(ctrl.jTreeProtocols)
        return;
    end
	ctrl.jTreeProtocols.startEditingAtPath(javax.swing.tree.TreePath(node.getPath()));
end

%% ===== ADD SEPARATOR =====
function AddSeparator(jMenu)
    if isa(jMenu, 'javax.swing.JPopupMenu')
        nmenu = jMenu.getComponentCount();
        if (nmenu > 0) && ~isa(jMenu.getComponent(nmenu-1), 'javax.swing.JSeparator')
            jMenu.addSeparator();
        end
    else
        nmenu = jMenu.getMenuComponentCount();
        if (nmenu > 0) && ~isa(jMenu.getMenuComponent(nmenu-1), 'javax.swing.JSeparator')
            jMenu.addSeparator();
        end
    end
end


%% ===== DISPLAY TOPOGRAPHY =====
function fcnPopupDisplayTopography(jMenu, FileName, AllMod, Modality, isStat)
    import org.brainstorm.icon.*;
    AddSeparator(jMenu);
    % Interpolation
    gui_component('MenuItem', jMenu, [], '3D Sensor cap', IconLoader.ICON_TOPOGRAPHY, [], @(h,ev)view_topography(FileName, Modality, '3DSensorCap'), []);
    gui_component('MenuItem', jMenu, [], '2D Sensor cap', IconLoader.ICON_TOPOGRAPHY, [], @(h,ev)view_topography(FileName, Modality, '2DSensorCap'), []);
    gui_component('MenuItem', jMenu, [], '2D Disc',       IconLoader.ICON_TOPOGRAPHY, [], @(h,ev)view_topography(FileName, Modality, '2DDisc'), []);
    gui_component('MenuItem', jMenu, [], '2D Layout',     IconLoader.ICON_2DLAYOUT,   [], @(h,ev)view_topography(FileName, Modality, '2DLayout'), []);

    % === NO MAGNETIC INTERPOLATION ===
    % Only for NEUROMAG MEG data (and not "MEG (all)" = MAG+GRAD)
    if ~isStat && ismember(Modality, {'MEG', 'MEG MAG', 'MEG GRAD'}) && ~(strcmpi(Modality, 'MEG') && any(ismember(AllMod, {'MEG MAG', 'MEG GRAD'})))
        AddSeparator(jMenu);
        % Menu "No interpolation"
        jMenuNoInterp = gui_component('Menu', jMenu, [], 'No magnetic interpolation', IconLoader.ICON_TOPOGRAPHY, [], [], []);
            gui_component('MenuItem', jMenuNoInterp, [], '3D Sensor cap', IconLoader.ICON_TOPOGRAPHY, [], @(h,ev)view_topography(FileName, Modality, '3DSensorCap', [], 0, 1), []);
            gui_component('MenuItem', jMenuNoInterp, [], '2D Sensor cap', IconLoader.ICON_TOPOGRAPHY, [], @(h,ev)view_topography(FileName, Modality, '2DSensorCap', [], 0, 1), []);
            gui_component('MenuItem', jMenuNoInterp, [], '2D Disc',       IconLoader.ICON_TOPOGRAPHY, [], @(h,ev)view_topography(FileName, Modality, '2DDisc', [], 0, 1), []);
    end
end
    
    
%% ===== SURFACE CALLBACKS =====
% ===== GET ALL FILENAMES =====
function FileNames = GetAllFilenames(bstNodes, nodeType)
    % Prepare list of the files to be concatenated
    FileNames = {};
    for iNode = 1:length(bstNodes)
        if strcmpi(bstNodes(iNode).getType(), 'datalist')
            [iDepStudies, iDepItems] = tree_dependencies(bstNodes, nodeType);
            if isequal(iDepStudies, -10)
                disp('BST> Error in tree_dependencies.');
                continue;
            end
            for i = 1:length(iDepStudies)
                sStudy = bst_get('Study', iDepStudies(i));
                FileNames{end+1} = file_fullpath(sStudy.Data(iDepItems(i)).FileName);
            end
        else
            FileNames{end+1} = file_fullpath(char(bstNodes(iNode).getFileName()));
        end
    end
end

% ===== CHECK SURFACE ALIGNMENT WITH MRI =====
function SurfaceCheckAlignment_Callback(bstNode)
    bst_progress('start', 'Check surface alignment', 'Loading MRI and surface...');
    % Get subject information 
    iSubject = bstNode.getStudyIndex();
    sSubject = bst_get('Subject', iSubject);
    % If no MRI is defined : cannot check alignment
    if isempty(sSubject.iAnatomy)
        bst_error('You must define a default MRI before checking alignment.', 'Check alignment MRI/surface', 0);
        return;
    end
    % Get default MRI and target surface
    MriFile     = sSubject.Anatomy(sSubject.iAnatomy).FileName;
    SurfaceFile = char(bstNode.getFileName());
    % Load MRI
    sMri = bst_memory('LoadMri', MriFile);
    % If MRI is defined but not oriented
    if ~isfield(sMri, 'SCS') || ~isfield(sMri.SCS, 'R') || isempty(sMri.SCS.R)
        bst_error('You must select MRI fiducials before aligning a surface on it', 'Check alignment MRI/surface', 0);
        return;
    end
    % Display MRI and Surface with MRIViewer
    view_mri(MriFile, SurfaceFile);
    bst_progress('stop');
end


% ===== SWAP FACES =====
function SurfaceSwapFaces_Callback(TessFile)
    bst_progress('start', 'Swap faces', 'Processing file...');
    % Load surface file (Faces field)
    TessMat = load(TessFile);
    % Swap vertex order
    TessMat.Faces = TessMat.Faces(:,[2 1 3]);
    % History: Swap faces
    TessMat = bst_history('add', TessMat, 'swap', 'Swap faces');
    % Save surface file
    bst_save(TessFile, TessMat, 'v7');
    bst_progress('stop');
    % Unload surface file
    bst_memory('UnloadSurface', TessFile);
end


%% ===== CLEAN SURFACE =====
function SurfaceClean_Callback(TessFile, isRemove)
    % Unload surface file
    bst_memory('UnloadSurface', TessFile);
    bst_progress('start', 'Clean surface', 'Processing file...');
    % Save current scouts modifications
    panel_scout('SaveModifications');
    % Load surface file (Faces field)
    TessMat = in_tess_bst(TessFile, 0);
    % Clean surface
    if isRemove
        % Ask for user confirmation
        isConfirm = java_dialog('confirm', [...
            'Warning: This operation may remove vertices from the surface.' 10 10 ... 
            'If you run it, you have to delete and recalculate the' 10 ...
            'headmodels and source files calculated using this surface.' 10 10 ...
            'Run the surface cleaning now?' 10 10], ...
           'Clean surface');
        if ~isConfirm
            bst_progress('stop');
            return;
        end
        % Clean file
        [TessMat.Vertices, TessMat.Faces, remove_vertices, remove_faces, TessMat.Atlas] = tess_clean(TessMat.Vertices, TessMat.Faces, TessMat.Atlas);
    end
    % Create new surface
    newTessMat = db_template('surfacemat');
    newTessMat.Faces    = TessMat.Faces;
    newTessMat.Vertices = TessMat.Vertices;
    newTessMat.Comment  = TessMat.Comment;
    % Atlas
    newTessMat.Atlas  = TessMat.Atlas;
    newTessMat.iAtlas = TessMat.iAtlas;
    if isfield(TessMat, 'Reg')
        newTessMat.Reg = TessMat.Reg;
    end
    % History
    if isfield(TessMat, 'History')
        newTessMat = bst_history('add', newTessMat, 'clean', 'Remove interpolations');
    end
    % Save cleaned surface file
    bst_save(TessFile, newTessMat, 'v7');
    % Close progresss bar
    bst_progress('stop');
    % Display message
    if isRemove
        java_dialog('msgbox', sprintf('%d vertices and %d faces removed', length(remove_vertices), length(remove_faces)), 'Clean surface');
    else
        java_dialog('msgbox', 'Done.', 'Remove interpolations');
    end
end

%% ===== FILL HOLES =====
function SurfaceFillHoles_Callback(TessFile)
    bst_progress('start', 'Fill holes', 'Processing file...');
    % ===== LOAD =====
    % Unload everything
    bst_memory('UnloadAll', 'Forced');
    % Load surface file (Faces field)
    sHead = in_tess_bst(TessFile, 0);
    % Get subject
    [sSubject, iSubject] = bst_get('SurfaceFile', TessFile);
    if isempty(sSubject.Anatomy)
        bst_error('No MRI available.', 'Remove surface holes');
        return;
    end
    % Load MRI
    sMri = bst_memory('LoadMri', sSubject.Anatomy(sSubject.iAnatomy).FileName);
    
    % ===== PROCESS =====
    % Remove holes
    [sHead.Vertices, sHead.Faces] = tess_fillholes(sMri, sHead.Vertices, sHead.Faces);
    % Create new surface
    sHeadNew.Faces    = sHead.Faces;
    sHeadNew.Vertices = sHead.Vertices;
    sHeadNew.Comment  = [sHead.Comment, '_fill'];
    
    % ===== SAVE FILE =====
    % Create output filenames
    NewTessFile = file_unique(strrep(TessFile, '.mat', '_fill.mat'));
    % Save head
    sHeadNew = bst_history('add', sHeadNew, 'clean', 'Filled holes');
    bst_save(NewTessFile, sHeadNew, 'v7');
    db_add_surface(iSubject, NewTessFile, sHeadNew.Comment);
    bst_progress('inc', 5);
    % Stop
    bst_progress('stop');
end


%% ===== CONCATENATE SURFACES =====
function SurfaceConcatenate(TessFiles)
    % Concatenate surface files
    NewFile = tess_concatenate(TessFiles);
    % Select new file in the tree
    if ~isempty(NewFile)
        panel_protocols('SelectNode', [], NewFile);
    end
end

%% ===== AVERAGE SURFACES =====
function SurfaceAverage(TessFiles)
    % Average surface files
    [NewFile, iSurf, errMsg] = tess_average(TessFiles);
    % Select new file in the tree
    if ~isempty(NewFile)
        panel_protocols('SelectNode', [], NewFile);
    elseif ~isempty(errMsg)
        bst_error(errMsg, 'Average surfaces', 0);
    end
end

%% ===== LOAD FREESURFER SPHERE =====
function TessAddSphere(TessFile)
    [TessMat, errMsg] = tess_addsphere(TessFile);
    if ~isempty(errMsg)
        bst_error(errMsg, 'Load FreeSurfer sphere', 0);
    end
end


%% ===== CHECK ALIGN CHANNELS/SCALP =====
function ChannelCheckAlignment_Callback(iStudy, Modality, isEdit)
%     % WARNING: Not supposed to do this with MEG
%     if strcmpi(Modality, 'MEG') && isEdit
%         res = java_dialog('confirm', ['WARNING: You are NOT supposed to do that.' 10 10 ...
%                           'The manual sensors alignment is provided to fit an EEG cap on the head.' 10 ...
%                           'When using MEG, the position of the head in the machine should be' 10 ...
%                           'recorded automatically and should not be modified manually.' 10 10 ...
%                           'However, sometimes this alignment is very bad and could require a manual' 10 ...
%                           'repositioning, but you should try to find the cause of the problem before.' 10 10 ...
%                           'Align manually MEG sensors ?'], 'Align MEG sensors');
%         if ~res
%             return
%         end
%     end
    % Get channel description
    sChannel = bst_get('ChannelForStudy', iStudy);
    if isempty(sChannel)
        return
    end
    % Call visualization functions
    channel_align_manual(sChannel.FileName, Modality, isEdit);
end


%% ===== COMPUTE SOURCES (HEADMODEL) =====
function selectHeadmodelAndComputeSources(bstNodes)
    % Select node
    tree_callbacks(bstNodes, 'doubleclick');
    % Compute sources
    panel_protocols('TreeInverse', bstNodes);
end


%% ===== DISPLAY CHANNELS =====
function [hFig, iDS, iFig] = DisplayChannels(bstNodes, Modality)
    % ===== DISPLAY SCALP SURFACE =====
    % Get study
    iStudy = bstNodes(1).getStudyIndex();
    sStudy = bst_get('Study', iStudy);
    if isempty(sStudy)
        return
    end
    % Get subject
    sSubject = bst_get('Subject', sStudy.BrainStormSubject);
    % View scalp surface if available
    if ~isempty(sSubject) && ~isempty(sSubject.iScalp)
        % Transparency depends on the modality
        if ismember(Modality, {'SEEG', 'ECOG'})
            SurfAlpha = .6;
        else
            SurfAlpha = 0;
        end
        % Display surface
        ScalpFile = sSubject.Surface(sSubject.iScalp).FileName;
        hFig = view_surface(ScalpFile, SurfAlpha);
    else
        hFig = [];
    end
    
    % ===== DISPLAY CHANNEL FILES ======
    % Only one: Markers and labels 
    if (length(bstNodes) == 1)
        fileName = char(bstNodes(1).getFileName());
        [hFig, iDS, iFig] = view_channels(fileName, Modality, 1, 1, hFig);
    % Multiple: Markers only
    else
        ColorTable = [1,0,0; 0,1,0; 0,0,1];
        for i = 1:length(bstNodes)
            color = ColorTable(mod(i-1,size(ColorTable,1))+1,:);
            % View channel file
            fileName = char(bstNodes(i).getFileName());
            [hFig, iDS, iFig] = view_channels(fileName, Modality, 1, 0, hFig);
            % Rename objects so that they are not deleted by the following call
            hPatch = findobj(hFig, 'tag', 'SensorsPatch');
            set(hPatch, 'FaceColor', color, 'FaceAlpha', .3, 'SpecularStrength', 0, ...
                        'EdgeColor', color, 'EdgeAlpha', .2, 'LineWidth', 1, ...
                        'Marker', 'none', 'Tag', 'MultipleSensorsPatches');
            if (i ~= length(bstNodes))
                hPatch = copyobj(hPatch, get(hPatch,'Parent'));
            end
        end
    end
end


%% ===== DISPLAY MEG HELMET =====
function [hFig, iDS, iFig] = DisplayHelmet(iStudy, ChannelFile)
    % Get study
    sStudy = bst_get('Study', iStudy);
    if isempty(sStudy)
        return
    end
    % Get subject
    sSubject = bst_get('Subject', sStudy.BrainStormSubject);
    % View scalp surface if available
    if ~isempty(sSubject) && ~isempty(sSubject.iScalp)
        ScalpFile = sSubject.Surface(sSubject.iScalp).FileName;
        hFig = view_surface(ScalpFile);
    else
        hFig = [];
    end    
    % Display helmet
    bst_progress('start', 'Display MEG helmet', 'Loading sensors...');
    [hFig, iDS, iFig] = view_helmet(ChannelFile, hFig);
    bst_progress('stop');
end


%% ===== GET CHANNEL DISPLAY NAME =====
% Make the "MEG", "MEG GRAD" and "MEG MAG" types more readable for the average user
function displayType = getChannelTypeDisplay(chType, allTypes)
    if ismember(upper(chType), {'MEG', 'MEG GRAD', 'MEG MAG'})
        switch upper(chType)
            case 'MEG'
                % If mixture of GRAD and MAG
                if any(ismember(allTypes, {'MEG GRAD', 'MEG MAG'}))
                    displayType = 'MEG (all)';
                else
                    displayType = 'MEG';
                end
            case 'MEG GRAD'
                displayType = 'MEG (gradiometers)';
            case 'MEG MAG'
                displayType = 'MEG (magnetometers)';
        end
    else
        displayType = chType;
    end
end


%% ===== SET DEFAULT SURFACE =====
function SetDefaultSurf(iSubject, SurfaceType, iSurface)
    % Update database
    db_surface_default(iSubject, SurfaceType, iSurface);
    % Repaint tree
    panel_protocols('RepaintTree');
end

%% ===== SET DEFAULT HEADMODEL =====
function SetDefaultHeadModel(bstNode, iHeadModel, iStudy, sStudy)
    % Select this node (and unselect all the others)
    panel_protocols('MarkUniqueNode', bstNode);
    % Save in database selected file
    sStudy.iHeadModel = iHeadModel;
    bst_set('Study', iStudy, sStudy);
    % Repaint tree
    panel_protocols('RepaintTree');
end
                

%% ===== SET NUMBER OF TRIALS =====
function SetNavgData(filenameFull)
    % Load file
    DataMat = in_bst_data(filenameFull, 'nAvg', 'History');
    % Ask factor to the user 
    res = java_dialog('input', ['Enter the number of trials that were used to compute this ' 10 ...
                                'averaged file (nAvg field in the file)'], 'Set number of trials', [], num2str(DataMat.nAvg));
    if isempty(res) 
        return
    end
    DataMat.nAvg = str2double(res);
    if isnan(DataMat.nAvg) || (length(DataMat.nAvg) > 1) || (DataMat.nAvg < 0) || (round(DataMat.nAvg) ~= DataMat.nAvg)
        bst_error('Invalid value', 'Set number of trials', 0);
        return;
    end
    % History: Set number of trials
    DataMat = bst_history('add', DataMat, 'set_trials', ['Set number of trials: ' res]);
    % Save file
    bst_save(filenameFull, DataMat, 'v6', 1);
end


%% ===== DISPLAY CTF FILES =====
function CreateCtfFiles(jMenu, filenameFull)
    import org.brainstorm.icon.*;
    % Load sFile structure
    DataMat = in_bst_data(filenameFull, 'F');
    % Get DS folder
    DsFolder = bst_fileparts(DataMat.F.filename);
    % Find session log file
    listDir = dir(bst_fullfile(DsFolder, '*.txt'));
    for i = 1:length(listDir)
        SessionsFile = bst_fullfile(DsFolder, listDir(i).name);
        gui_component('MenuItem', jMenu, [], listDir(i).name, IconLoader.ICON_EDIT, [], @(h,ev)view_text(SessionsFile, listDir(i).name, 1), []);
    end
    % Find image files
    listDir = [dir(bst_fullfile(DsFolder, '*.jpg')), dir(bst_fullfile(DsFolder, '*.gif')), dir(bst_fullfile(DsFolder, '*.JPG')), dir(bst_fullfile(DsFolder, '*.png')), dir(bst_fullfile(DsFolder, '*.tif'))];
    for i = 1:length(listDir)
        ImageFile = bst_fullfile(DsFolder, listDir(i).name);
        gui_component('MenuItem', jMenu, [], listDir(i).name, IconLoader.ICON_IMAGE, [], @(h,ev)view_image(ImageFile), []);
    end
end

