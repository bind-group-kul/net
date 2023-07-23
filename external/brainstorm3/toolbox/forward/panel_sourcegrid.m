function varargout = panel_sourcegrid(varargin)
% PANEL_SOURCEGRID: Options for the construction of volume source grid.
% 
% USAGE:  bstPanelNew = panel_sourcegrid('CreatePanel')
%                   s = panel_sourcegrid('GetPanelContents')

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
% Authors: Francois Tadel, 2011-2013

macro_methodcall;
end


%% ===== CREATE PANEL =====
function [bstPanelNew, panelName] = CreatePanel(CortexFile)  %#ok<DEFNU>  
    panelName = 'SourcegridOptions';
    % Java initializations
    import java.awt.*;
    import javax.swing.*;
    % Create main main panel
    jPanelNew = gui_river();
    % Default options
    GridOptions.nLayers       = 17;
    GridOptions.Reduction     = 3;
    GridOptions.nVerticesInit = 4000;
    % Create an envelope of the cortex surface
    [sEnvelope, sCortex] = tess_envelope(CortexFile, 'convhull', GridOptions.nVerticesInit, .001, []);
    if isempty(sEnvelope)
        return;
    end
    
    % ===== GRID OPTIONS =====
    jPanelOpt = gui_river([4,5], [0,15,20,10], 'Grid options');
        jButtonGroup = ButtonGroup();
        % RADIO: Generate grid
        jRadioGenerate = gui_component('radio', jPanelOpt, '', num2str('Generate from cortex surface'), jButtonGroup, [], @(h,ev)UpdatePanel, []);
        jRadioGenerate.setSelected(1);
        % nLayers
        gui_component('label', jPanelOpt, 'br', '     ');
        jLabelLayers = gui_component('label', jPanelOpt, '', 'Number of layers: ', [], [], [], []);
        jTextLayers = gui_component('texttime', jPanelOpt, 'tab', num2str(GridOptions.nLayers, '%d'), [], [], [], []);
        java_setcb(jTextLayers, 'ActionPerformedCallback', @(h,ev)OptionsChanged_Callback, ...
                                'FocusLostCallback',       @(h,ev)OptionsChanged_Callback);
        % Reduction
        gui_component('label', jPanelOpt, 'br', '     ');
        jLabelReduction = gui_component('label', jPanelOpt, '', 'Downsampling factor: ', [], [], [], []);
        jTextReduction = gui_component('texttime', jPanelOpt, 'tab', num2str(GridOptions.Reduction, '%d'), [], [], [], []);
        java_setcb(jTextReduction, 'ActionPerformedCallback', @(h,ev)OptionsChanged_Callback, ...
                                   'FocusLostCallback',       @(h,ev)OptionsChanged_Callback);
        % nVerticesInit
        gui_component('label', jPanelOpt, 'br', '     ');
        jLabelVertInit = gui_component('label', jPanelOpt, '', 'Initial number of vertices: ', [], [], [], []);
        jTextVertInit = gui_component('texttime', jPanelOpt, 'tab', num2str(GridOptions.nVerticesInit, '%d'), [], [], [], []);
        java_setcb(jTextVertInit, 'ActionPerformedCallback', @(h,ev)OptionsChanged_Callback, ...
                                  'FocusLostCallback',       @(h,ev)OptionsChanged_Callback);
        gui_component('label', jPanelOpt, 'br', ' ');
        
        % RADIO: Load from file
        jRadioFile = gui_component('radio', jPanelOpt, 'br', num2str('Load from file [Nx3 double]'), jButtonGroup, [], @(h,ev)UpdatePanel, []);
        % Filename
        gui_component('label', jPanelOpt, 'br', '     ');
        jTextFile = gui_component('text', jPanelOpt, 'hfill', '', [], [], [], []);
        jTextFile.setEditable(0);
        jButtonFile = gui_component('button', jPanelOpt, '', '...', [], [], @(h,ev)SelectFile, []);
         
        % RADIO: Load from variable
        jRadioVar = gui_component('radio', jPanelOpt, 'br', num2str('Load from Matlab variable [Nx3 double]'), jButtonGroup, [], @(h,ev)UpdatePanel, []);
        gui_component('label', jPanelOpt, 'br', '     ');
        jTextVar = gui_component('text', jPanelOpt, 'hfill', '', [], [], [], []);
        java_setcb(jTextVar, 'ActionPerformedCallback', @(h,ev)UpdatePanel);
        
        % Estimated number of vertices
        gui_component('label', jPanelOpt, 'br', '     ');
        gui_component('label', jPanelOpt, 'br', 'Estimated number of grid points: ', [], [], [], []);
        jLabelPoints = gui_component('label', jPanelOpt, '', '2000', [], [], [], []);
    jPanelNew.add('br hfill', jPanelOpt);
    
    % ===== VALIDATION BUTTONS =====
    gui_component('button', jPanelNew, 'br right', 'Preview', [], [], @(h,ev)ShowGrid, []);
    gui_component('button', jPanelNew, '', 'Cancel', [], [], @ButtonCancel_Callback, []);
    gui_component('button', jPanelNew, [], 'Ok', [], [], @ButtonOk_Callback, []);

    % ===== PANEL CREATION =====
    % Return a mutex to wait for panel close
    bst_mutex('create', panelName);
    % Controls list
    ctrl = struct('CortexFile',       CortexFile, ...
                  'sEnvelope',        sEnvelope, ...
                  'sCortex',          sCortex, ...
                  'jRadioGenerate',   jRadioGenerate, ...
                  'jRadioFile',       jRadioFile, ...
                  'jRadioVar',        jRadioVar, ...
                  'jTextLayers',      jTextLayers, ...
                  'jTextReduction',   jTextReduction, ...
                  'jTextVertInit',    jTextVertInit, ...
                  'jTextFile',        jTextFile, ...
                  'jTextVar',         jTextVar);
    % Create the BstPanel object that is returned by the function
    bstPanelNew = BstPanel(panelName, jPanelNew, ctrl);
    % Update panel
    UpdatePanel();
    

%% =================================================================================
%  === INTERNAL CALLBACKS ==========================================================
%  =================================================================================
%% ===== CANCEL BUTTON =====
    function ButtonCancel_Callback(hObject, event)
        % Close preview window
        hFig = findobj(0, 'type', 'figure', 'tag', 'FigCheckGrid');
        if ~isempty(hFig)
            close(hFig);
        end
        % Close panel without saving (release mutex automatically)
        gui_hide(panelName);
    end

%% ===== OK BUTTON =====
    function ButtonOk_Callback(varargin)
        % Close preview window
        hFig = findobj(0, 'type', 'figure', 'tag', 'FigCheckGrid');
        if ~isempty(hFig)
            close(hFig);
        end
        % Release mutex and keep the panel opened
        bst_mutex('release', panelName);
    end

%% ===== OPTION CHANGED =====
    function OptionsChanged_Callback(varargin)
        % Get new options
        NewOptions.nLayers       = str2double(char(ctrl.jTextLayers.getText()));
        NewOptions.Reduction     = str2double(char(ctrl.jTextReduction.getText()));
        NewOptions.nVerticesInit = str2double(char(ctrl.jTextVertInit.getText()));
        % If options changed: update panel
        if ~isequal(NewOptions.nLayers, GridOptions.nLayers) || ~isequal(NewOptions.Reduction, GridOptions.Reduction) || ~isequal(NewOptions.nVerticesInit, GridOptions.nVerticesInit)
            GridOptions = NewOptions;
            UpdatePanel();
        end
    end

%% ===== UPDATE PANEL =====
    function UpdatePanel(varargin)
        global gGridLoc;
        % RADIO: Generate
        isGenerate = jRadioGenerate.isSelected();
        jTextLayers.setEnabled(isGenerate);
        jLabelLayers.setEnabled(isGenerate);
        jTextReduction.setEnabled(isGenerate);
        jLabelReduction.setEnabled(isGenerate);
        jTextVertInit.setEnabled(isGenerate);
        jLabelVertInit.setEnabled(isGenerate);
        % RADIO: File
        isFile = jRadioFile.isSelected();
        jTextFile.setEnabled(isFile);
        jButtonFile.setEnabled(isFile);
        % RADIO: Variable
        isVar = jRadioVar.isSelected();
        jTextVar.setEnabled(isVar);
        % Get full grid
        gGridLoc = GetGrid(ctrl);
        if ~isempty(gGridLoc)
            nTotal = length(gGridLoc);
        else
            nTotal = 0;
        end
        % Display new estimation
        jLabelPoints.setText(num2str(nTotal));
        % Get previous window: If it exists, update it
        hFig = findobj(0, 'type', 'figure', 'tag', 'FigCheckGrid');
        if ~isempty(hFig)
            ShowGrid();
        end
    end

%% ===== SELECT FILE =====
    function SelectFile()
        % Get file
        filename = java_getfile( 'open', 'Import grid of points', '', 'single', 'files', ...
                                {{'*'}, 'ASCII files (*.*)', 'ALL'}, 1);
        % Update panel
        if ~isempty(filename)
            jTextFile.setText(filename);
        end
        UpdatePanel();
    end
end


%% =================================================================================
%  === EXTERNAL CALLBACKS ==========================================================
%  =================================================================================   
%% ===== GET PANEL CONTENTS =====
function grid = GetPanelContents() %#ok<DEFNU>
    global gGridLoc;
    grid = gGridLoc;
    gGridLoc = [];
    clear gGridLoc;
end


%% ===== GET GRID =====
function grid = GetGrid(ctrl)
    % Get panel controls
    if (nargin == 0)
        ctrl = bst_get('PanelControls', 'SourcegridOptions');
    end
    grid = [];
    % Progress bar
    bst_progress('start', 'Volume grid', 'Creating grid...');
    % Radio: Generate
    if ctrl.jRadioGenerate.isSelected()
        % Get options
        Options.nLayers       = str2double(char(ctrl.jTextLayers.getText()));
        Options.Reduction     = str2double(char(ctrl.jTextReduction.getText()));
        Options.nVerticesInit = str2double(char(ctrl.jTextVertInit.getText()));
        % Check for errors
        if isnan(Options.nLayers) || isnan(Options.Reduction) || isnan(Options.nVerticesInit)
            bst_error('Invalid values.', 'Generate grid', 0);
            return
        end
        % If default number of points changed, remesh envelope
        if (Options.nVerticesInit ~= 4000)
            center = mean(ctrl.sEnvelope.Vertices);
            ctrl.sEnvelope.Vertices = bst_bsxfun(@minus, ctrl.sEnvelope.Vertices, center);
            [ctrl.sEnvelope.Vertices, ctrl.sEnvelope.Faces] = tess_remesh(ctrl.sEnvelope.Vertices, Options.nVerticesInit);
            ctrl.sEnvelope.Vertices = bst_bsxfun(@plus, ctrl.sEnvelope.Vertices, center);
        end
        % Compute grid
        grid = bst_sourcegrid(Options, ctrl.CortexFile, ctrl.sCortex, ctrl.sEnvelope);
    % Radio: File
    else
        isFile = ctrl.jRadioFile.isSelected();
        if isFile
            varname = char(ctrl.jTextFile.getText());
        else
            varname = char(ctrl.jTextVar.getText());
        end
        if ~isempty(varname)
            grid = ReadGrid(varname, isFile); 
        end    
    end
    % Close progress bar
    bst_progress('stop');
end

%% ===== READ GRID =====
function grid = ReadGrid(varname, isFile)
    grid = [];
    % Read matrix
    if isFile && file_exist(varname)
        try
            grid = load(varname, '-ascii');
        catch
        end
    else
        grid = in_matlab_var(varname);
    end
    % Re-orient matrix
    if ~isempty(grid)
        if (size(grid,1) ~= 3) && (size(grid,2) ~= 3)
            disp('BST> Invalid grid format. Matrix must be [Nx3].');
        elseif (size(grid,1) == 3) && (size(grid,2) ~= 3)
            grid = grid';
        end
    end
end

%% ===== SHOW GRID =====
function ShowGrid()
    global gGridLoc;
    % Get panel controls
    ctrl = bst_get('PanelControls', 'SourcegridOptions');
    % Get previous window
    hFig = findobj(0, 'type', 'figure', 'tag', 'FigCheckGrid');
    % Create figure if it doesnt exist + show surface
    if isempty(hFig)
        hFig = view_surface(ctrl.CortexFile, .9, [.6 .6 .6], 'NewFigure');
        set(hFig, 'Tag', 'FigCheckGrid');
    % Figure exists: remove previous points
    else
        delete(findobj(hFig, 'tag', 'ptCheckGrid'));
        % Focus on figure
        figure(hFig);
    end
    % No points to show: exit
    if isempty(gGridLoc)
        return;
    end
    % Get axes
    hAxes = findobj(hFig, 'Tag', 'Axes3D');
    % Show grid points
    line(gGridLoc(:,1), gGridLoc(:,2), gGridLoc(:,3), 'LineStyle', 'none', ...
         'Color', [0 1 0], 'MarkerSize', 2, 'Marker', '.', ...
         'Tag', 'ptCheckGrid', 'Parent', hAxes);
end



