function varargout = figure_connect( varargin )
% FIGURE_CONNECT: Creation and callbacks for connectivity figures.
%
% USAGE:  hFig = figure_connect('CreateFigure', FigureId)

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
% Authors: Sebastien Dery, Francois Tadel, 2013
%          Francois Tadel, 2014

varargout = [];
macro_methodcall;
end


%% ===== CREATE FIGURE =====
function hFig = CreateFigure(FigureId) %#ok<DEFNU>
	% Create new figure
    hFig = figure('Visible',               'off', ...
                  'NumberTitle',           'off', ...
                  'IntegerHandle',         'off', ...
                  'MenuBar',               'none', ...
                  'Toolbar',               'none', ...
                  'DockControls',          'off', ...earnadd
                  'Units',                 'pixels', ...
                  'Color',                 [0 0 0], ...
                  'BusyAction',            'queue', ...
                  'Interruptible',         'off', ...
                  'HitTest',               'on', ...
                  'Tag',                   FigureId.Type, ...
                  'Renderer',              'opengl', ...
                  'CloseRequestFcn',       @(h,ev)bst_figures('DeleteFigure',h,ev), ...
                  'KeyPressFcn',           @(h,ev)bst_call(@FigureKeyPressedCallback,h,ev), ...
                  'KeyReleaseFcn',         @(h,ev)bst_call(@FigureKeyReleasedCallback,h,ev), ...
                  'WindowButtonDownFcn',   @FigureMouseDownCallback, ...
                  'WindowButtonMotionFcn', @FigureMouseMoveCallback, ...
                  'WindowButtonUpFcn',     @FigureMouseUpCallback, ...
                  'WindowScrollWheelFcn',   @(h,ev)FigureMouseWheelCallback(h,ev), ...
                  'ResizeFcn',             []);

	% === CREATE AXES ===
    % Because colormap functions have Axes check
    % (even though they don't actually need it...)
    %     hAxes = axes('Parent',   hFig, ...
    %                  'Units',    'normalized', ...
    %                  'Position', [.05 .05 .9 .9], ...
    %                  'Tag',      'AxesConnect', ...
    %                  'Visible',  'off', ...
    %                  'BusyAction',    'queue', ...
    %                  'Interruptible', 'off');
              
	% Create rendering panel
    [OGL, container] = javacomponent(java_create('org.brainstorm.connect.GraphicsFramework'), [0, 0, 500, 400], hFig);
    % Resize callback
    set(hFig, 'ResizeFcn', @(h,ev)ResizeCallback(hFig, container));
    % Java callbacks
    set(OGL, 'MouseClickedCallback',    @(h,ev)JavaClickCallback(hFig,ev));
    set(OGL, 'MousePressedCallback',    @(h,ev)FigureMouseDownCallback(hFig,ev));
    set(OGL, 'MouseDraggedCallback',    @(h,ev)FigureMouseMoveCallback(hFig,ev));
    set(OGL, 'MouseReleasedCallback',   @(h,ev)FigureMouseUpCallback(hFig,ev));
    set(OGL, 'KeyPressedCallback',      @(h,ev)FigureKeyPressedCallback(hFig,ev));
    set(OGL, 'KeyReleasedCallback',     @(h,ev)FigureKeyReleasedCallback(hFig,ev));
    
    % Prepare figure appdata
    setappdata(hFig, 'FigureId', FigureId);
    setappdata(hFig, 'hasMoved', 0);
    setappdata(hFig, 'isPlotEditToolbar', 0);
    setappdata(hFig, 'isStatic', 0);
    setappdata(hFig, 'isStaticFreq', 1);
    setappdata(hFig, 'isControlKeyDown', false);
    setappdata(hFig, 'isShiftKeyDown', false);
    setappdata(hFig, 'Colormap', db_template('ColormapInfo'));
    setappdata(hFig, 'GraphSelection', []);
    
    % Time-freq specific appdata
    setappdata(hFig, 'Timefreq', db_template('TfInfo'));
    
    % J3D Container
    setappdata(hFig, 'OpenGLDisplay', OGL);
    setappdata(hFig, 'OpenGLContainer', container);

    setappdata(hFig, 'TextDisplayMode', 1);
    setappdata(hFig, 'NodeDisplay', 1);
    setappdata(hFig, 'HierarchyNodeIsVisible', 1);
    setappdata(hFig, 'MeasureLinksIsVisible', 1);
    setappdata(hFig, 'RegionLinksIsVisible', 0);
    setappdata(hFig, 'RegionFunction', 'mean');
        
    % Camera variables
    setappdata(hFig, 'CameraZoom', 6);
    setappdata(hFig, 'CamPitch', 0.5 * 3.1415);
    setappdata(hFig, 'CamYaw', -0.5 * 3.1415);
    setappdata(hFig, 'CameraPosition', [0 0 0]);
    setappdata(hFig, 'CameraTarget', [0 0 0]);
    
	% Add colormap
    bst_colormaps('AddColormapToFigure', hFig, 'connectn');
end



%% ===========================================================================
%  ===== FIGURE CALLBACKS ====================================================
%  ===========================================================================
%% ===== COLORMAP CHANGED CALLBACK =====
function ColormapChangedCallback(hFig) %#ok<DEFNU>
    UpdateColormap(hFig);
end

%% ===== CURRENT TIME CHANGED =====
function CurrentTimeChangedCallback(hFig)   %#ok<DEFNU>
    % If no time in this figure
    if getappdata(hFig, 'isStatic')
        return;
    end
    % If there is time in this figure
    UpdateFigurePlot(hFig);
end

%% ===== CURRENT FREQ CHANGED =====
function CurrentFreqChangedCallback(hFig)   %#ok<DEFNU>
    % If no frequencies in this figure
    if getappdata(hFig, 'isStaticFreq')
        return;
    end
    % Update figure
    UpdateFigurePlot(hFig);
end


%% ===== SELECTED ROW CHANGED =====
%function SelectedRowChangedCallback(iDS, iFig) %#ok<DEFNU>
% %%% Sensor or cortex region selection was changed in another figure: update figure selection
%
%     global GlobalData;
%     % Get figure appdata
%     hFig = GlobalData.DataSet(iDS).Figure(iFig).hFigure;
%     % Get current selection for the figure
%     curSelRows = figure_timeseries('GetFigSelectedRows', hFig);
%     % Get new selection that the figure should show (keep only the ones available for this figure)
%     allFigRows = GlobalData.DataSet(iDS).Figure(iFig).Handles.LinesLabels;
%     newSelRows = intersect(GlobalData.DataViewer.SelectedRows, allFigRows);
%     % Sensors to select
%     rowsToSel = setdiff(newSelRows, curSelRows);
%     if ~isempty(rowsToSel)
%         figure_timeseries('SetFigSelectedRows', hFig, rowsToSel, 1);
%     end
%     % Sensors to unselect
%     rowsToUnsel = setdiff(curSelRows, newSelRows);
%     if ~isempty(rowsToUnsel)
%         figure_timeseries('SetFigSelectedRows', hFig, rowsToUnsel, 0);
%     end
%end


%% ===== DISPOSE FIGURE =====
function Dispose(hFig) %#ok<DEFNU>
    SetBackgroundColor(hFig, [1 1 1]);
    OGL = getappdata(hFig, 'OpenGLDisplay');
    set(OGL, 'MouseClickedCallback',    []);
    set(OGL, 'MousePressedCallback',    []);
    set(OGL, 'MouseDraggedCallback',    []);
    set(OGL, 'MouseReleasedCallback',   []);
    set(OGL, 'KeyReleasedCallback',     []);
    set(OGL, 'KeyPressedCallback',      []);
    set(OGL, 'MouseWheelMovedCallback', []);
    OGL.resetDisplay();
    delete(OGL);
    setappdata(hFig, 'OpenGLDisplay', []);
end


%% ===== RESET DISPLAY =====
function ResetDisplay(hFig)
    % Reset display
    OGL = getappdata(hFig, 'OpenGLDisplay');
    OGL.resetDisplay();
    % Defaults value
    setappdata(hFig, 'DisplayOutwardMeasure', 1);
    setappdata(hFig, 'DisplayInwardMeasure', 0);
    setappdata(hFig, 'DisplayBidirectionalMeasure', 0);
    setappdata(hFig, 'DataThreshold', 0.5);
    setappdata(hFig, 'DistanceThreshold', 0);
    setappdata(hFig, 'TextDisplayMode', 1);
    setappdata(hFig, 'NodeDisplay', 1);
    setappdata(hFig, 'HierarchyNodeIsVisible', 1);
    if isappdata(hFig, 'DataPair')
        rmappdata(hFig, 'DataPair');
    end
    if isappdata(hFig, 'HierarchyNodesMask')
        rmappdata(hFig, 'HierarchyNodesMask');
    end
    if isappdata(hFig, 'GroupNodesMask')
        rmappdata(hFig, 'GroupNodesMask');
    end
    if isappdata(hFig, 'NodeData')
        rmappdata(hFig, 'NodeData');
    end
    if isappdata(hFig, 'DataMinMax')
        rmappdata(hFig, 'DataMinMax');
    end
end

%% ===== GET BACKGROUND COLOR =====
function backgroundColor = GetBackgroundColor(hFig)
    backgroundColor = getappdata(hFig, 'BgColor');
    if isempty(backgroundColor)
        backgroundColor = [0 0 0];
    end
end

%% ===== RESIZE CALLBACK =====
function ResizeCallback(hFig, container)
    % Update Title     
    RefreshTitle(hFig);
    % Update OpenGL container size
    UpdateContainer(hFig, container);
end

function UpdateContainer(hFig, container)
    % Get figure position
    figPos = get(hFig, 'Position');
    % Get colorbar handle
    hColorbar = findobj(hFig, '-depth', 1, 'Tag', 'Colorbar');
    % Get title handle
    TitlesHandle = getappdata(hFig, 'TitlesHandle');
    titleHeight = 0;
    if (~isempty(TitlesHandle))
        titlePos = get(TitlesHandle(1), 'Position'); 
        titleHeight = titlePos(4);
    end
    % Define constants
    colorbarWidth = 15;
    marginHeight  = 25;
    marginWidth   = 45;
    % If there is a colorbar 
    if ~isempty(hColorbar)
        % Reposition the colorbar
        set(hColorbar, 'Units',    'pixels', ...
                       'Position', [figPos(3) - marginWidth, ...
                                    marginHeight, ...
                                    colorbarWidth, ...
                                    max(1, min(90, figPos(4) - marginHeight - 3))]);
        % Reposition the container
        marginAxes = 0;
        if ~isempty(container)
            set(container, 'Units',    'pixels', ...
                           'Position', [marginAxes, ...
                                        marginAxes, ...
                                        figPos(3) - colorbarWidth - marginWidth - marginAxes, ... 
                                        figPos(4) - 2*marginAxes - titleHeight]);
        end
        uistack(hColorbar,'top',1);
    else
        if ~isempty(container)
            % Java container can take all the figure space
            set(container, 'Units',    'normalized', ...
                           'Position', [.05, .05, .9, .9]);
        end
    end
end

function HasTitle = RefreshTitle(hFig)
    Title = [];
    DisplayInRegion = getappdata(hFig, 'DisplayInRegion');
    if (DisplayInRegion)
        % Organisation level
        OrganiseNode = getappdata(hFig, 'OrganiseNode');
        % Label 
        hTitle = getappdata(hFig, 'TitlesHandle');
        % If data are hierarchicaly organised and we are not
        % already at the whole cortical view
        if (~isempty(OrganiseNode) && OrganiseNode ~= 1)
            % Get where we are textually
            PathNames = VerticeToFullName(hFig, OrganiseNode);
            Recreate = 0;
            nLevel = size(PathNames,2);
            if (nLevel ~= size(hTitle,2) || size(hTitle,2) == 0)
                Recreate = 1;
                for i=1:size(hTitle,2)
                    delete(hTitle(i));
                end
                hTitle = [];
            end
            backgroundColor = GetBackgroundColor(hFig);
            figPos = get(hFig, 'Position');
            Width = 1;
            Height = 25;
            X = 10;
            Y = figPos(4) - Height;
            for i=1:nLevel
                Title = PathNames{i};
                if (Recreate)
                    hTitle(i) = uicontrol( ...
                                       'Style',               'pushbutton', ...
                                       'Enable',              'inactive', ...
                                       'String',              Title, ...
                                       'Units',               'Pixels', ...
                                       'Position',            [0 0 1 1], ...
                                       'HorizontalAlignment', 'center', ...
                                       'FontUnits',           'points', ...
                                       'FontSize',            bst_get('FigFont'), ...
                                       'ForegroundColor',     [0 0 0], ...
                                       'BackgroundColor',     backgroundColor, ...
                                       'HitTest',             'on', ...
                                       'Parent',              hFig, ...
                                       'Callback', @(h,ev)bst_call(@SetExplorationLevelTo,hFig,nLevel-i));
                    set(hTitle(i), 'ButtonDownFcn', @(h,ev)bst_call(@SetExplorationLevelTo,hFig,nLevel-i), ...
                                   'BackgroundColor',     backgroundColor);
                end
                X = X + Width;
                Size = get(hTitle(i), 'extent');
                Width = Size(3) + 10;
                % Minimum width so all buttons look the same
                if (Width < 50)
                    Width = 50;
                end
                set(hTitle(i), 'String',            Title, ...
                               'Position',          [X Y Width Height], ...
                               'BackgroundColor',   backgroundColor);
            end
        else
            for i=1:size(hTitle,2)
                delete(hTitle(i));
            end
            hTitle = [];
        end
        setappdata(hFig, 'TitlesHandle', hTitle);
        UpdateContainer(hFig, getappdata(hFig, 'OpenGLContainer'));
    end    
    HasTitle = size(Title,2) > 0;
end

%% ===========================================================================
%  ===== KEYBOARD AND MOUSE CALLBACKS ========================================
%  ===========================================================================

%% ===== FIGURE MOUSE CLICK CALLBACK =====
function FigureMouseDownCallback(hFig, ev)   
    % Check if MouseUp was executed before MouseDown: Should ignore this MouseDown event
    if isappdata(hFig, 'clickAction') && strcmpi(getappdata(hFig,'clickAction'), 'MouseDownNotConsumed')
        setappdata(hFig,'clickAction','MouseDownOk');
        return;
    end
    % Click on the Java canvas
    if ~isempty(ev)
        if ((ev.getButton() == ev.BUTTON3) || (ev.getButton() == ev.BUTTON2))
            clickAction = 'popup';
        else
            clickAction = 'rotate';
            %clickAction = '';
        end
        clickPos = [ev.getX() ev.getY()];
    % Click on the Matlab colorbar
    else
        if strcmpi(get(hFig, 'SelectionType'), 'alt')
            clickAction = 'popup';
        else
            clickAction = 'colorbar';
        end
        clickPos = get(hFig, 'CurrentPoint');
    end
    % Record action to perform when the mouse is moved
    setappdata(hFig, 'clickAction', clickAction);
    setappdata(hFig, 'clickSource', hFig);
    % Reset the motion flag
    setappdata(hFig, 'hasMoved', 0);
    % Record mouse location in the figure coordinates system
    setappdata(hFig, 'clickPositionFigure', clickPos);
end


%% ===== FIGURE MOUSE MOVE CALLBACK =====
function FigureMouseMoveCallback(hFig, ev)
    % Get current mouse action
    clickAction = getappdata(hFig, 'clickAction');   
    clickSource = getappdata(hFig, 'clickSource');
    % If no source, or source is not the same as the current figure: Ignore
    if isempty(clickAction) || isempty(clickSource) || (clickSource ~= hFig)
        return
    end
    % If MouseUp was executed before MouseDown: Ignore Move event
    if strcmpi(clickAction, 'MouseDownNotConsumed') || isempty(getappdata(hFig, 'clickPositionFigure'))
        return
    end
    % Click on the Java canvas
    if ~isempty(ev)
        curPos = [ev.getX() ev.getY()];
    % Click on the Matlab colorbar
    else
        curPos = get(hFig, 'CurrentPoint');
    end
    % Motion from the previous event
    motionFigure = 0.3 * (curPos - getappdata(hFig, 'clickPositionFigure'));
    % Update click point location
    setappdata(hFig, 'clickPositionFigure', curPos);
    % Update the motion flag
    setappdata(hFig, 'hasMoved', 1);
    % Switch between different actions
    switch(clickAction)              
        case 'colorbar'
            % Get colormap type
            ColormapInfo = getappdata(hFig, 'Colormap');
            % Changes contrast            
            sColormap = bst_colormaps('ColormapChangeModifiers', ColormapInfo.Type, [motionFigure(1), motionFigure(2)] ./ 100, 0);
            set(hFig, 'Colormap', sColormap.CMap);
        case 'rotate'
            
            MouseMoveCamera = getappdata(hFig, 'MouseMoveCamera');
            if isempty(MouseMoveCamera)
                MouseMoveCamera = 0;
            end
            if (MouseMoveCamera)
                motion = -motionFigure * 0.1;
                MoveCamera(hFig, [motion(1) -motion(2) 0]);
            else
                motion = -motionFigure * 0.01;
                RotateCameraAlongAxis(hFig, -motion(2), motion(1));
            end
    end
end


%% ===== FIGURE MOUSE UP CALLBACK =====
function FigureMouseUpCallback(hFig, varargin)
    % Get application data (current user/mouse actions)
    clickAction = getappdata(hFig, 'clickAction');
    hasMoved = getappdata(hFig, 'hasMoved');
    % Remove mouse appdata (to stop movements first)
    setappdata(hFig, 'hasMoved', 0);
    if isappdata(hFig, 'clickPositionFigure')
        rmappdata(hFig, 'clickPositionFigure');
    end
    if isappdata(hFig, 'clickAction')
        rmappdata(hFig, 'clickAction');
    else
        setappdata(hFig, 'clickAction', 'MouseDownNotConsumed');
    end

    % Update display panel
    bst_figures('SetCurrentFigure', hFig, 'TF');
    
    % ===== SIMPLE CLICK =====
    if ~hasMoved
        if strcmpi(clickAction, 'popup')
            DisplayFigurePopup(hFig);
        end
    % ===== MOUSE HAS MOVED =====
    else
        if strcmpi(clickAction, 'colorbar')
            % Apply new colormap to all figures
            ColormapInfo = getappdata(hFig, 'Colormap');
            bst_colormaps('FireColormapChanged', ColormapInfo.Type);
        end
    end
end


%% ===== FIGURE KEY PRESSED CALLBACK =====
function FigureKeyPressedCallback(hFig, keyEvent)
    global ConnectKeyboardMutex;
    % Convert to Matlab key event
    [keyEvent, tmp, tmp] = gui_brainstorm('ConvertKeyEvent', keyEvent);
    if isempty(keyEvent.Key)
        return;
    end
    % Set a mutex to prevent to enter twice at the same time in the routine
    if (isempty(ConnectKeyboardMutex))
        tic;
        % Set mutex
        ConnectKeyboardMutex = 0.1;
        % Process event
        switch (keyEvent.Key)
            case 'a'
                SetSelectedNodes(hFig, [], 1, 1);
            case 'b'
                ToggleBlendingMode(hFig);
            case 'l'
                ToggleTextDisplayMode(hFig);
            case 'h'
                HierarchyNodeIsVisible = getappdata(hFig, 'HierarchyNodeIsVisible');
                HierarchyNodeIsVisible = 1 - HierarchyNodeIsVisible;
                SetHierarchyNodeIsVisible(hFig, HierarchyNodeIsVisible);
            case 'd'
                ToggleDisplayMode(hFig);
            case 'm'
                ToggleMeasureToRegionDisplay(hFig)
            case 'q'
                RenderInQuad = 1 - getappdata(hFig, 'RenderInQuad');
                setappdata(hFig, 'RenderInQuad', RenderInQuad)
                OGL = getappdata(hFig, 'OpenGLDisplay');
                OGL.renderInQuad(RenderInQuad)
                OGL.repaint();
            case {'+', 'add'}
                panel_display('ConnectKeyCallback', keyEvent);
            case {'-', 'subtract'}
                panel_display('ConnectKeyCallback', keyEvent);
            case 'leftarrow'
                ToggleRegionSelection(hFig, 1);
            case 'rightarrow'
                ToggleRegionSelection(hFig, -1);
            case 'uparrow'
                ZoomCamera(hFig, -5);
            case 'downarrow'
                ZoomCamera(hFig, 5);
            case 'escape'
                SetExplorationLevelTo(hFig, 1);
            case 'shift'
                setappdata(hFig, 'MouseMoveCamera', 1);
        end
        %ConnectKeyboardMutex = [];
    else
        % Release mutex if last keypress was processed more than one 2s ago
        t = toc;
        if (t > ConnectKeyboardMutex)
            ConnectKeyboardMutex = [];
        end
    end
end

function FigureKeyReleasedCallback(hFig, keyEvent)
    % Convert to Matlab key event
    keyEvent = gui_brainstorm('ConvertKeyEvent', keyEvent);
    if isempty(keyEvent.Key)
        return;
    end
    % Process event
    switch (keyEvent.Key)
        case 'shift'
            setappdata(hFig, 'MouseMoveCamera', 0);
    end
end

function SetExplorationLevelTo(hFig, Level)
    % Last reorganisation
    OrganiseNode = getappdata(hFig, 'OrganiseNode');
    if (isempty(OrganiseNode) || OrganiseNode == 1)
        return;
    end
    Paths = getappdata(hFig, 'NodePaths');
    Path = Paths{OrganiseNode};
    NextAgregatingNode = Path(find(Path == OrganiseNode) + Level);
    if (NextAgregatingNode ~= OrganiseNode)
        setappdata(hFig, 'OrganiseNode', NextAgregatingNode);
        UpdateFigurePlot(hFig);
    end
end

function NextNode = getNextCircularRegion(hFig, Node, Inc)
    % Construct Spiral Index
    Levels = getappdata(hFig, 'Levels');
    DisplayNode = find(getappdata(hFig, 'DisplayNode'));
    CircularIndex = [];
    for i=1:size(Levels,1)
        CircularIndex = [CircularIndex; Levels{i}];
    end
    CircularIndex(~ismember(CircularIndex,DisplayNode)) = [];
    if isempty(Node)
        NextIndex = 1;
    else
        % Find index
        NextIndex = find(CircularIndex(:) == Node) + Inc;
        nIndex = size(CircularIndex,1);
        if (NextIndex > nIndex)
            NextIndex = 1;
        elseif (NextIndex < 1)
            NextIndex = nIndex;
        end
    end
    % 
    NextNode = CircularIndex(NextIndex);
end

function ToggleRegionSelection(hFig, Inc)
    % Get selected nodes
    selNodes = getappdata(hFig, 'SelectedNodes');
    % Get number of AgregatingNode
    AgregatingNodes = getappdata(hFig, 'AgregatingNodes');
    % 
    if (isempty(selNodes))
        % Get first node
        NextNode = getNextCircularRegion(hFig, [], Inc);
    else
        % Remove previous links
        SetSelectedNodes(hFig, selNodes, 0, 1); 
        % Remove agregating node from selection
        SelectedNode = selNodes(1);
        %
        NextNode = getNextCircularRegion(hFig, SelectedNode, Inc);
    end
    % Is node an agregating node
    IsAgregatingNode = ismember(NextNode, AgregatingNodes);
    if (IsAgregatingNode)
        % Get agregated nodes
        AgregatedNodeIndex = getAgregatedNodesFrom(hFig, NextNode); 
        if (~isempty(AgregatedNodeIndex))
            % Select agregated node
            SetSelectedNodes(hFig, AgregatedNodeIndex, 1, 1);
        end    
    end
    % Select node
    SetSelectedNodes(hFig, NextNode, 1, 1);
end


%% ===== JAVA MOUSE CLICK CALLBACK =====
function JavaClickCallback(hFig, ev)
    % Retrieve button
    ButtonClicked = ev.get('Button');
    ClickCount = ev.get('ClickCount');
    if (ButtonClicked == 1)
        % OpenGL handle
        OGL = getappdata(hFig,'OpenGLDisplay');
        % Minimum distance. 1 is difference between level order of distance
        minimumDistanceThreshold = 1.5;
        % '+1' is to account for the different indexing in Java and Matlab
        nodeIndex = OGL.raypickNearestNode(ev.getX(), ev.getY(), minimumDistanceThreshold) + 1;
        % If a visible node is clicked on
        if (nodeIndex > 0)
            DisplayNode = getappdata(hFig, 'DisplayNode');
            if (DisplayNode(nodeIndex) == 1)
                % Get selected nodes
                selNodes = getappdata(hFig, 'SelectedNodes');
                % Get agregating nodes
                AgregatingNodes = getappdata(hFig, 'AgregatingNodes');
                % Is the node already selected ?
                AlreadySelected = ~isempty(find(selNodes(:) == nodeIndex,1));
                % Is the node an agregating node ?
                IsAgregatingNode = sum(AgregatingNodes(:) == nodeIndex) == 1;

                if (ClickCount == 1)
                    % If it's the only selected node, then select all
                    if (AlreadySelected && length(selNodes) == 1)
                        SetSelectedNodes(hFig, [], 1);
                        return;
                    end

                    if (AlreadySelected && IsAgregatingNode)
                        % Get agregated nodes
                        AgregatedNodeIndex = getAgregatedNodesFrom(hFig, nodeIndex);
                        % How many are already selected
                        NodeAlreadySelected = ismember(AgregatedNodeIndex, selNodes);
                        % Get selected agregated nodes
                        AgregatingNodeAlreadySelected = ismember(AgregatingNodes, selNodes);
                        % If the agregating node and his measure node are the only
                        % selected nodes,  then select all
                        if (sum(NodeAlreadySelected) + sum(AgregatingNodeAlreadySelected) == size(selNodes,1))
                            SetSelectedNodes(hFig, [], 1);
                            return;
                        end
                    end

                    % Select picked node
                    Select = 1;
                    if (AlreadySelected)
                        % Deselect picked node
                        Select = 0;
                    end

                    % If shift is not pressed, deselect all node
                    isShiftDown = ev.get('ShiftDown');
                    if (strcmp(isShiftDown,'off'))
                        % Deselect
                        SetSelectedNodes(hFig, selNodes, 0, 1);
                        % Deselect picked node
                        Select = 1;
                    end
                
                    if (IsAgregatingNode)
                        % Get agregated nodes
                        SelectNodeIndex = getAgregatedNodesFrom(hFig, nodeIndex);
                        % Select
                        SetSelectedNodes(hFig, [SelectNodeIndex(:); nodeIndex], Select);
                        % Go up the hierarchy
                        UpdateHierarchySelection(hFig, nodeIndex, Select);
                    else
                        SetSelectedNodes(hFig, nodeIndex, Select);
                    end
                else
                    if (IsAgregatingNode)
                        OrganiseNode = getappdata(hFig, 'OrganiseNode');
                        if isempty(OrganiseNode)
                            OrganiseNode = 1;
                        end
                        % If it's the same, don't reload for nothing..
                        if (OrganiseNode == nodeIndex)
                            return;
                        end
                        % If there's only one node, useless update
                        AgregatedNodeIndex = getAgregatedNodesFrom(hFig, nodeIndex);
                        Invalid = ismember(AgregatedNodeIndex, AgregatingNodes);
                        Invalid = Invalid | ismember(AgregatedNodeIndex, OrganiseNode);
                        if (size(AgregatedNodeIndex(~Invalid),1) == 1)
                            return;
                        end
                        % There's no exploration in 3D
                        is3DDisplay = getappdata(hFig, 'is3DDisplay');
                        if (~is3DDisplay)
                            setappdata(hFig, 'OrganiseNode', nodeIndex)
                            UpdateFigurePlot(hFig);
                        end
                    end
                end
            end
        else
            if (ClickCount == 2)
                DefaultCamera(hFig);
            end
        end
    end
end

function DefaultCamera(hFig)
    setappdata(hFig, 'CameraZoom', 6);
    setappdata(hFig, 'CamPitch', 0.5 * 3.1415);
    setappdata(hFig, 'CamYaw', -0.5 * 3.1415);
    setappdata(hFig, 'CameraPosition', [0 0 0]);
    setappdata(hFig, 'CameraTarget', [0 0 0]);
    RotateCameraAlongAxis(hFig, 0, 0);
end


function UpdateHierarchySelection(hFig, NodeIndex, Select)
    % Incorrect data
    if (size(NodeIndex,1) > 1 || isempty(NodeIndex ))
        return
    end
    % 
    if (NodeIndex == 1)
        return
    end
    % Go up the hierarchy
    NodePaths = getappdata(hFig, 'NodePaths');
    PathToCenter = NodePaths{NodeIndex};
    % Retrieve Agregating node
    AgregatingNode = PathToCenter(find(PathToCenter == NodeIndex) + 1);
    % Get selected nodes
    selNodes = getappdata(hFig, 'SelectedNodes');
    % Get agregated nodes
    AgregatedNodesIndex = getAgregatedNodesFrom(hFig, AgregatingNode);
    % Is everything selected ?
    if (size(AgregatedNodesIndex,1) == sum(ismember(AgregatedNodesIndex, selNodes)))
        SetSelectedNodes(hFig, AgregatingNode, Select);
        UpdateHierarchySelection(hFig, AgregatingNode, Select);
    end
end

%% ===== JAVA MOUSE WHEEL CALLBACK =====
function FigureMouseWheelCallback(hFig, ev)
    % Control Zoom
    CameraZoom = getappdata(hFig, 'CameraZoom');
    % 0.1 Factor is too much (6 Dec 2013). Now 0.05
    CameraZoom = CameraZoom + (ev.VerticalScrollCount * ev.VerticalScrollAmount) * 0.05;
    if (CameraZoom <= 0)
        CameraZoom = 0;
    end
    setappdata(hFig, 'CameraZoom', CameraZoom);
    UpdateCamera(hFig);
end


%% ===== POPUP MENU =====
function DisplayFigurePopup(hFig)
    import java.awt.event.KeyEvent;
    import java.awt.Dimension;
    import javax.swing.KeyStroke;
    import javax.swing.JLabel;
    import javax.swing.JSlider;
    import org.brainstorm.icon.*;
    % Get figure description
    hFig = bst_figures('GetFigure', hFig);
    % Get axes handles
    hAxes = getappdata(hFig, 'clickSource');
    if isempty(hAxes)
        return
    end
    
    DisplayInRegion = getappdata(hFig, 'DisplayInRegion');
    is3DDisplay = getappdata(hFig, 'is3DDisplay');
    
    % Create popup menu
    jPopup = java_create('javax.swing.JPopupMenu');
    
    % ==== MENU: COLORMAP =====
    bst_colormaps('CreateAllMenus', jPopup, hFig);
    
    % ==== MENU: SNAPSHOT ====
    jPopup.addSeparator();
    jMenuSave = gui_component('Menu', jPopup, [], 'Snapshots', IconLoader.ICON_SNAPSHOT, [], [], []);
        % === SAVE AS IMAGE ===
        jItem = gui_component('MenuItem', jMenuSave, [], 'Save as image', IconLoader.ICON_SAVE, [], @(h,ev)bst_call(@out_figure_image, hFig), []);
        jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_I, KeyEvent.CTRL_MASK));
        % === OPEN AS IMAGE ===
        jItem = gui_component('MenuItem', jMenuSave, [], 'Open as image', IconLoader.ICON_IMAGE, [], @(h,ev)bst_call(@out_figure_image, hFig, 'Viewer'), []);
        jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_J, KeyEvent.CTRL_MASK));       
    jPopup.add(jMenuSave);
    
    % ==== MENU: 2D LAYOUT ====
    jGraphMenu = gui_component('Menu', jPopup, [], 'Display options', IconLoader.ICON_CONNECTN, [], [], []);
        % Check Matlab version: Works only for R2007b and newer
        VER = bst_get('MatlabVersion');
        if (VER.Version >= 705)
            if is3DDisplay
                % == MODIFY CORTEX TRANSPARENCY ==
                jPanelModifiers = gui_river([0 0], [3, 18, 3, 2]);
                Transparency = GetCortexTransparency(hFig);
                % Label
                jPanelModifiers.add(JLabel('Cortex Opacity'));
                % Slider
                jSliderContrast = JSlider(0,250,250);
                jSliderContrast.setValue(round(Transparency * 1000));
                jSliderContrast.setPreferredSize(Dimension(100,23));
                %jSliderContrast.setToolTipText(tooltipSliders);
                jSliderContrast.setFocusable(0);
                jSliderContrast.setOpaque(0);
                jPanelModifiers.add('tab hfill', jSliderContrast);
                % Value (text)
                jLabelContrast = JLabel(sprintf('%0.2f', Transparency));
                jLabelContrast.setPreferredSize(Dimension(50,23));
                jLabelContrast.setHorizontalAlignment(JLabel.LEFT);
                jPanelModifiers.add(jLabelContrast);
                % Slider callbacks
                java_setcb(jSliderContrast.getModel(), 'StateChangedCallback', @(h,ev)CortexTransparencySliderModifying_Callback(hFig, ev, jLabelContrast));
                jGraphMenu.add(jPanelModifiers);
            end
            
            % == MODIFY LINK TRANSPARENCY ==
            jPanelModifiers = gui_river([0 0], [3, 18, 3, 2]);
            Transparency = GetLinkTransparency(hFig);
            % Label
            jPanelModifiers.add(JLabel('Link Transp.'));
            % Slider
            jSliderContrast = JSlider(0,100,100);
            jSliderContrast.setValue(round(Transparency * 100));
            jSliderContrast.setPreferredSize(Dimension(100,23));
            %jSliderContrast.setToolTipText(tooltipSliders);
            jSliderContrast.setFocusable(0);
            jSliderContrast.setOpaque(0);
            jPanelModifiers.add('tab hfill', jSliderContrast);
            % Value (text)
            jLabelContrast = JLabel(sprintf('%.0f %%', Transparency * 100));
            jLabelContrast.setPreferredSize(Dimension(50,23));
            jLabelContrast.setHorizontalAlignment(JLabel.LEFT);
            jPanelModifiers.add(jLabelContrast);
            % Slider callbacks
            % java_setcb(jSliderContrast, 'MouseReleasedCallback', @(h,ev)SliderModifiersValidate_Callback(h, ev, ColormapType, 'Contrast', jLabelContrast));
            java_setcb(jSliderContrast.getModel(), 'StateChangedCallback', @(h,ev)TransparencySliderModifiersModifying_Callback(hFig, ev, jLabelContrast));
            jGraphMenu.add(jPanelModifiers);

            % == MODIFY LINK SIZE ==
            jPanelModifiers = gui_river([0 0], [3, 18, 3, 2]);
            LinkSize = GetLinkSize(hFig);
            % Label
            jPanelModifiers.add(JLabel('Link Size'));
            % Slider
            jSliderContrast = JSlider(0,5,5);
            jSliderContrast.setValue(LinkSize);
            jSliderContrast.setPreferredSize(Dimension(100,23));
            %jSliderContrast.setToolTipText(tooltipSliders);
            jSliderContrast.setFocusable(0);
            jSliderContrast.setOpaque(0);
            jPanelModifiers.add('tab hfill', jSliderContrast);
            % Value (text)
            jLabelContrast = JLabel(sprintf('%.0f', round(LinkSize)));
            jLabelContrast.setPreferredSize(Dimension(50,23));
            jLabelContrast.setHorizontalAlignment(JLabel.LEFT);
            jPanelModifiers.add(jLabelContrast);
            % Slider callbacks
            % java_setcb(jSliderContrast, 'MouseReleasedCallback', @(h,ev)SliderModifiersValidate_Callback(h, ev, ColormapType, 'Contrast', jLabelContrast));
            java_setcb(jSliderContrast.getModel(), 'StateChangedCallback', @(h,ev)SizeSliderModifiersModifying_Callback(hFig, ev, jLabelContrast));
            jGraphMenu.add(jPanelModifiers);
        end
        
        % === TOGGLE BACKGROUND WHITE/BLACK ===
        jGraphMenu.addSeparator();
        BackgroundColor = getappdata(hFig, 'BgColor');
        isWhite = all(BackgroundColor == [1 1 1]);
        jItem = gui_component('CheckBoxMenuItem', jGraphMenu, [], 'White background', [], [], @(h, ev)ToggleBackground(hFig), []);
        jItem.setSelected(isWhite);
        
        % === TOGGLE BLENDING OPTIONS ===
        BlendingEnabled = getappdata(hFig, 'BlendingEnabled');
        jItem = gui_component('CheckBoxMenuItem', jGraphMenu, [], 'Color blending', [], [], @(h, ev)ToggleBlendingMode(hFig), []);
        jItem.setSelected(BlendingEnabled);
        jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_B, 0));
        jGraphMenu.addSeparator();
        
        % === TOGGLE BLENDING OPTIONS ===
        TextDisplayMode = getappdata(hFig, 'TextDisplayMode');
        jLabelMenu = gui_component('Menu', jGraphMenu, [], 'Labels Display', [], [], [], []);
            jItem = gui_component('CheckBoxMenuItem', jLabelMenu, [], 'Measure Nodes', [], [], @(h, ev)SetTextDisplayMode(hFig, 1), []);
            jItem.setSelected(ismember(1,TextDisplayMode));
            if (DisplayInRegion)
                jItem = gui_component('CheckBoxMenuItem', jLabelMenu, [], 'Region Nodes', [], [], @(h, ev)SetTextDisplayMode(hFig, 2), []);
                jItem.setSelected(ismember(2,TextDisplayMode));
            end
            jItem = gui_component('CheckBoxMenuItem', jLabelMenu, [], 'Selection only', [], [], @(h, ev)SetTextDisplayMode(hFig, 3), []);
            jItem.setSelected(ismember(3,TextDisplayMode));

        % === TOGGLE HIERARCHY NODE VISIBILITY ===
        if (DisplayInRegion)
            HierarchyNodeIsVisible = getappdata(hFig, 'HierarchyNodeIsVisible');
            jItem = gui_component('CheckBoxMenuItem', jGraphMenu, [], 'Hide region nodes', [], [], @(h, ev)SetHierarchyNodeIsVisible(hFig, 1 - HierarchyNodeIsVisible), []);
            jItem.setSelected(~HierarchyNodeIsVisible);
            jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_H, 0));
        end
        
        % === TOGGLE BINARY LINK STATUS ===
        Method = getappdata(hFig, 'Method');
        if (strcmp(Method, 'granger') == 1)
            IsBinaryData = getappdata(hFig, 'IsBinaryData');
            jItem = gui_component('CheckBoxMenuItem', jGraphMenu, [], 'Binary Link Display', IconLoader.ICON_CHANNEL_LABEL, [], @(h, ev)SetIsBinaryData(hFig, 1 - IsBinaryData), []);
            jItem.setSelected(IsBinaryData);
            jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_M, 0));
        end

    % ==== MENU: GRAPH DISPLAY ====
    jGraphMenu = gui_component('Menu', jPopup, [], 'Graph options', IconLoader.ICON_CONNECTN, [], [], []);
        % === SELECT ALL THE NODES ===
        jItem = gui_component('MenuItem', jGraphMenu, [], 'Select all the nodes', [], [], @(h, n, s, r)SetSelectedNodes(hFig, [], 1, 1), []);
        jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_A, 0));
        % === SELECT NEXT REGION ===
        jItem = gui_component('MenuItem', jGraphMenu, [], 'Select next region', [], [], @(h, ev)ToggleRegionSelection(hFig, 1), []);
        jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_RIGHT, 0));
        % === SELECT PREVIOUS REGION===
        jItem = gui_component('MenuItem', jGraphMenu, [], 'Select previous region', [], [], @(h, ev)ToggleRegionSelection(hFig, -1), []);
        jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_LEFT, 0));
        jGraphMenu.addSeparator();

        if (DisplayInRegion)
            % === UP ONE LEVEL IN HIERARCHY ===
            jItem = gui_component('MenuItem', jGraphMenu, [], 'One Level Up', [], [], @(h, ev)SetExplorationLevelTo(hFig, 1), []);
            jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_ESCAPE, 0));
            jGraphMenu.addSeparator();
            
            % === TOGGLE DISPLAY REGION MEAN ===
            RegionLinksIsVisible = getappdata(hFig, 'RegionLinksIsVisible');
            RegionFunction = getappdata(hFig, 'RegionFunction');
            jItem = gui_component('CheckBoxMenuItem', jGraphMenu, [], ['Display region ' RegionFunction], [], [], @(h, ev)ToggleMeasureToRegionDisplay(hFig), []);
            jItem.setSelected(RegionLinksIsVisible);
            jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_M, 0));
            
            % === TOGGLE REGION FUNCTIONS===
            IsMean = strcmp(RegionFunction, 'mean');
            jLabelMenu = gui_component('Menu', jGraphMenu, [], 'Region function', [], [], [], []);
                jItem = gui_component('CheckBoxMenuItem', jLabelMenu, [], 'Mean', [], [], @(h, ev)SetRegionFunction(hFig, 'mean'), []);
                jItem.setSelected(IsMean);
                jItem = gui_component('CheckBoxMenuItem', jLabelMenu, [], 'Max', [], [], @(h, ev)SetRegionFunction(hFig, 'max'), []);
                jItem.setSelected(~IsMean);
        end
    
    % Display Popup menu
    gui_popup(jPopup, hFig);
end

% Cortex transparency slider
function CortexTransparencySliderModifying_Callback(hFig, ev, jLabel)
    % Update Modifier value
    newValue = double(ev.getSource().getValue()) / 1000;
    % Setting newValue to 0 will automatically disable Blending
    if (newValue < eps)
        newValue = eps;
    end
    % Update text value
    jLabel.setText(sprintf('%0.2f', newValue));
    %
    SetCortexTransparency(hFig, newValue);
end

% Link transparency slider
function TransparencySliderModifiersModifying_Callback(hFig, ev, jLabel)
    % Update Modifier value
    newValue = double(ev.getSource().getValue()) / 100;
    % Update text value
    jLabel.setText(sprintf('%.0f %%', newValue * 100));
    %
    SetLinkTransparency(hFig, newValue);
end

% Link size slider
function SizeSliderModifiersModifying_Callback(hFig, ev, jLabel)
    % Update Modifier value
    newValue = ev.getSource().getValue();
    % Update text value
    jLabel.setText(sprintf('%.0f', round(newValue)));
    %
    SetLinkSize(hFig, newValue);
end


%% ===========================================================================
%  ===== PLOT FUNCTIONS ======================================================
%  ===========================================================================

%% ===== GET FIGURE DATA =====
function [Time, Freqs, TfInfo, TF, RowNames, DataType, Method, FullTimeVector, PV] = GetFigureData(hFig)
    global GlobalData;
    % === GET FIGURE INFO ===
    % Get selected frequencies and rows
    TfInfo = getappdata(hFig, 'Timefreq');
    if isempty(TfInfo)
        return
    end
    % Get data description
    [iDS, iTimefreq] = bst_memory('GetDataSetTimefreq', TfInfo.FileName);
    if isempty(iDS)
        return
    end
    
    % ===== GET TIME =====
    [Time, iTime] = bst_memory('GetTimeVector', iDS, [], 'CurrentTimeIndex');
    Time = Time(iTime);
    FullTimeVector = Time;
    % If it is a static figure: keep only the first and last times
    if getappdata(hFig, 'isStatic')
        Time = Time([1,end]);
    end
    
    % ===== GET FREQUENCIES =====
    % Get the current freqency
    TfInfo.iFreqs = GlobalData.UserFrequencies.iCurrentFreq;
    if isempty(TfInfo.iFreqs)
        Freqs = GlobalData.DataSet(iDS).Timefreq(iTimefreq).Freqs;
    elseif ~iscell(GlobalData.DataSet(iDS).Timefreq(iTimefreq).Freqs)
       if (GlobalData.DataSet(iDS).Timefreq(iTimefreq).Freqs == 0)
           Freqs = [];
           TfInfo.iFreqs = 1;
       else
           Freqs = GlobalData.DataSet(iDS).Timefreq(iTimefreq).Freqs(TfInfo.iFreqs);
           if (size(Freqs,1) ~= 1)
               Freqs = Freqs';
           end
       end
    else
        % Get a set of frequencies (freq bands)
        Freqs = GlobalData.DataSet(iDS).Timefreq(iTimefreq).Freqs(TfInfo.iFreqs);
    end
        
    % ===== GET DATA =====
    RowNames = GlobalData.DataSet(iDS).Timefreq(iTimefreq).RowNames;
    % Only if requested
    if (nargout >= 4)
        % Get TF values
        [TF, iTimeBands] = bst_memory('GetTimefreqValues', iDS, iTimefreq, [], TfInfo.iFreqs, iTime, TfInfo.Function);
        % Get connectivity matrix
        TF = bst_memory('GetConnectMatrix', iDS, iTimefreq, TF);
        % Get time bands
        if ~isempty(iTimeBands)
            Time = GlobalData.DataSet(iDS).Timefreq(iTimefreq).TimeBands(iTimeBands,:);
        end
        % Data type
        DataType = GlobalData.DataSet(iDS).Timefreq(iTimefreq).DataType;
        % Method
        Method = GlobalData.DataSet(iDS).Timefreq(iTimefreq).Method;
    end
    
    if (nargout >= 9)
        % ===== P VALUE =====
        PV = [];
        % PV = GlobalData.DataSet(iDS).Timefreq(iTimefreq).P;
        % Get connectivity p-value matrix
        % PV = bst_memory('GetConnectMatrix', iDS, iTimefreq, PV);
    end
end

function IsDirectional = IsDirectionalData(hFig)
    % If directional data
    IsDirectional = getappdata(hFig, 'IsDirectionalData');
    % Ensure variable
    if isempty(IsDirectional)
        IsDirectional = 0;
    end
end

function DataPair = LoadConnectivityData(hFig, Options, Atlas, Surface)
    % Parse input
    if (nargin < 2)
        Options = struct();
    end
    if (nargin < 3)
        Atlas = [];
        Surface = [];
    end
    % Maximum number of data allowed
    MaximumNumberOfData = 500;
   
    % === GET DATA ===
    [Time, Freqs, TfInfo, M, RowNames, DataType, Method, FullTimeVector, P] = GetFigureData(hFig);
    % Zero-out the diagonal because its useless
    M = M - diag(diag(M));
    % If the matrix is symetric and Not directional
    if (isequal(M, M') && ~IsDirectionalData(hFig))
        % We don't need the upper half
        for i = 1:size(M,1)
            M(i,i:end) = 0;
        end
    end
    
    % === THRESHOLD ===
    if ((size(M,1) * size(M,2)) > MaximumNumberOfData)
        % Validity mask
        Valid = ones(size(M));
        Valid(M == 0) = 0;
        Valid(diag(ones(size(M)))) = 0;
        
        % === ZERO-OUT INSIGNIFICANT VALUES ===
        if isfield(Options,'Significance') && Options.Significance
            % If we have data to work with..
            if ~isempty(P) && all(size(M) == size(P)) 
                % Keep lowest values only
                B = sort(P(:), 'ascend');
                if length(B) > MaximumNumberOfData
                  Valid = Valid & (P < B(MaximumNumberOfData));
                end
            end
        end
        
        % === ZERO-OUT NEIGHBORS VALUES ===
%         if isfield(Options,'Neighbours') && Options.Neighbours
%             % Do we have data to work with ?
%             if ~isempty(Atlas) && ~isempty(Surface)
%                 % Because
%                 VertConn = full(Surface.VertConn);
%                 % 
%                 nScouts = length(Atlas.Scouts);
%                 % If sources are elemental dipole
%                 if (nScouts == size(Surface.Vertices,1))
%                     Valid = Valid & ~VertConn;
%                 else
%                     CellIndex = cellfun(@(V,I) repmat(I,1,length(V)), {Atlas.Scouts.Vertices}, num2cell(1:length(Atlas.Scouts)), 'UniformOutput', 0);
%                     Index = zeros(size(Surface.Vertices,1),1);
%                     Index([Atlas.Scouts.Vertices]) = [CellIndex{:}];
%                     % 
%                     for i=1:nScouts
%                         Idx = unique(Index(any(VertConn(Atlas.Scouts(i).Vertices,:),1)));
%                         Idx(Idx == i) = [];
%                         Idx(Idx == 0) = [];
%                         Valid(i,Idx) = 0;
%                     end
%                 end
%             end
%         end
        
        % === ZERO-OUT DISTANCE ===
%         if isfield(Options,'Distance') && Options.Distance
%             if isempty(Atlas)
%                 [n,dims] = size(Surface.Vertices);
%                 a = reshape(Surface.Vertices,1,n,dims);
%                 b = reshape(Surface.Vertices,n,1,dims);
%                 dmat = sqrt(sum((a(ones(n,1),:,:) - b(:,ones(n,1),:)).^2,3));
%                 DistanceFactor = getappdata(hFig, 'MeasureDistanceFactor');
%                 dmat = dmat .* DistanceFactor;
%                 Valid = Valid & (dmat > 20);
%             else
%             end
%         end
        
        % === ZERO-OUT LOWEST VALUES ===
        if isfield(Options,'Highest') && Options.Highest
            % Retrieve min/max
            DataMinMax = [min(M(:)), max(M(:))];
            % Keep highest values only
            if (DataMinMax(1) >= 0)
                [tmp,tmp,s] = find(M(Valid == 1));
                B = sort(s, 'descend');
                if length(B) > MaximumNumberOfData
                    t = B(MaximumNumberOfData);
                    Valid = Valid & (M > t);
                end
            else
                [tmp,tmp,s] = find(M(Valid == 1));
                B = sort(abs(s), 'descend');
                if length(B) > MaximumNumberOfData
                    t = B(MaximumNumberOfData);
                    Valid = Valid & ((M < -t) | (M > t));
                end
            end
        end
        
        % 
        M(~Valid) = 0;
        % 
        if ~isempty(P)
            P(~Valid) = 1;
        end
    end

    % Convert matrixu to data pair
    DataPair = MatrixToDataPair(hFig, M);
    % Include P-Value in data structure
    if ~isempty(P)
        % 
        [tmp,tmp,s] = find(P(M ~= 0));
        DataPair(:,4) = s(:);
    end
    
    fprintf('%.0f Connectivity measure loaded\n', size(DataPair,1));

    % ===== MATRIX STATISTICS ===== 
    % Update figure variable
    setappdata(hFig, 'DataMinMax', [min(DataPair(:,3)), max(DataPair(:,3))]);
    
    % Clear memory
    clear M;
end


function aDataPair = MatrixToDataPair(hFig, mMatrix)
    % Reshape
    [i,j,s] = find(mMatrix);
    i = i';
    j = j';
    mMatrix = reshape([i;j],1,[]);
    % Convert to datapair structure
    aDataPair = zeros(size(mMatrix,2)/2,3);
    aDataPair(1:size(mMatrix,2)/2,1) = mMatrix(1:2:size(mMatrix,2));
    aDataPair(1:size(mMatrix,2)/2,2) = mMatrix(2:2:size(mMatrix,2));
    aDataPair(1:size(mMatrix,2)/2,3) = s(:);
    % Add offset
    nAgregatingNode = size(getappdata(hFig, 'AgregatingNodes'),2);
    aDataPair(:,1:2) = aDataPair(:,1:2) + nAgregatingNode;
end


%% ===== UPDATE FIGURE PLOT =====
function LoadFigurePlot(hFig) %#ok<DEFNU>
    global GlobalData;
    % Necessary for data initialization
    ResetDisplay(hFig);
    % Get figure description
    [hFig, tmp, iDS] = bst_figures('GetFigure', hFig);
    % Get connectivity matrix
    [Time, Freqs, TfInfo] = GetFigureData(hFig);
    % Get the file descriptor in memory
    iTimefreq = bst_memory('GetTimefreqInDataSet', iDS, TfInfo.FileName);
    % Data type
    DataType = GlobalData.DataSet(iDS).Timefreq(iTimefreq).DataType;
    RowNames = GlobalData.DataSet(iDS).Timefreq(iTimefreq).RowNames;
    % ===== GET REGION POSITIONS AND HIERARCHY =====
    % Inialize variables
    sGroups = repmat(struct('Name', [], 'RowNames', [], 'Region', []), 0);
    SurfaceMat = [];
    Vertices = [];
    RowLocs = [];
    Atlas = [];
    % Technique to get the hierarchy depends on the data type
    switch (DataType)
        case 'data'
            %% ===== CHANNEL =====
            % Get selections
            sSelect = panel_montage('GetMontagesForFigure', hFig);
            % Check if all the rows to display are in the selections (if not: ignore selections)
            if ~isempty(sSelect)
                AllRows = cat(2, sSelect.ChanNames);
                if ~all(ismember(RowNames, AllRows))
                    sSelect = [];
                    disp('Oops select');
                end
            end
            % Use selections
            if ~isempty(sSelect)
                for iSel = 1:length(sSelect)
                    groupRows = intersect(RowNames, sSelect(iSel).ChanNames);
                    if ~isempty(groupRows)
                        % Detect region based on name
                        Name = upper(sSelect(iSel).Name);
                        Region = [];
                        switch Name
                            case {'CTF LF'}
                                Region = 'LF';
                            case {'CTF LT'}
                                Region = 'LT';
                            case {'CTF LP'}
                                Region = 'LP';
                            case {'CTF LC'}
                                Region = 'LC';
                            case {'CTF LO'}
                                Region = 'LO';
                            case {'CTF RF'}
                                Region = 'RF';
                            case {'CTF RT'}
                                Region = 'RT';
                            case {'CTF RP'}
                                Region = 'RP';
                            case {'CTF RC'}
                                Region = 'RC';
                            case {'CTF RO'}
                                Region = 'RO';
                            case {'CTF ZC'}
                                Region = 'UU';
                            case {'LEFT-TEMPORAL'}
                                Region = 'LT';
                            case {'RIGHT-TEMPORAL'}
                                Region = 'RT';
                            case {'LEFT-PARIETAL'}
                                Region = 'LP';
                            case {'RIGHT-PARIETAL'}
                                Region = 'RP';
                            case {'LEFT-OCCIPITAL'}
                                Region = 'LO';
                            case {'RIGHT-OCCIPITAL'}
                                Region = 'RO';
                            case {'LEFT-FRONTAL'}
                                Region = 'LF';
                            case {'RIGHT-FRONTAL'}
                                Region = 'RF';
                        end
                        if (~isempty(Region))
                            iGroup = length(sGroups) + 1;
                            sGroups(iGroup).Name = sSelect(iSel).Name;
                            sGroups(iGroup).RowNames = groupRows;
                            sGroups(iGroup).Region = Region;
                        end
                    end
                end
            end
 
            % Sensors positions
            selChan = zeros(1, length(RowNames));
            for iRow = 1:length(RowNames)
                % Get indice in the 
                selChan(iRow) = find(strcmpi({GlobalData.DataSet(iDS).Channel.Name}, RowNames{iRow}));
            end
            RowLocs = figure_3d('GetChannelPositions', iDS, selChan);
            

        case 'results'
            %% ===== Atlas =====
            % Load surface
            SurfaceFile = GlobalData.DataSet(iDS).Timefreq(iTimefreq).SurfaceFile;
            if ~isempty(SurfaceFile)
                % Get vertices positions
                if ischar(SurfaceFile)
                    SurfaceMat = in_tess_bst(SurfaceFile);
                    Vertices = SurfaceMat.Vertices;
                end
            end
            % Load atlas
            Atlas = GlobalData.DataSet(iDS).Timefreq(iTimefreq).Atlas;
            % If an atlas is available
            if ~isempty(Atlas)
                % Create groups using the file atlas
                sGroups = GroupScouts(Atlas);
                % Get the position of each scout: use the seed position
                if ~isempty(Vertices)
                    RowLocs = Vertices([Atlas.Scouts.Seed], :);
                end
            else
                if ~isempty(Vertices)
                    RowLocs = Vertices;
                end
                % Group the vertices using the current surface atlas
                if isfield(SurfaceMat, 'Atlas') && isfield(SurfaceMat, 'iAtlas') && ~isempty(SurfaceMat.iAtlas)
                    % Atlas = SurfaceMat.Atlas(SurfaceMat.iAtlas);
                    % error('Group vertices using the current atlas for the surface');
                else
                    error('Group vertices in default regions');
                end
            end
            
            
        case 'matrix'

        otherwise
            error('Unsupported');
    end

    is3DDisplay = getappdata(hFig, 'is3DDisplay');
    if isempty(is3DDisplay) || isempty(RowLocs) || isempty(SurfaceMat)
        is3DDisplay = 0;
    end
    DisplayInCircle = 0;
    DisplayInRegion = 0;
    
    % Assign generic name if necessary
    if isempty(RowNames)
        RowNames = cellstr(num2str((1:size(Vertices,1))'));
    end
    % Ensure proper alignment
    if (size(RowNames,2) > size(RowNames,1))
        RowNames = RowNames';
    end
    % Ensure proper type
    if isa(RowNames, 'double')
        RowNames = cellstr(num2str(RowNames));
    end
    
    %% === ASSIGN GROUPS: CRUCIAL STEP ===
    if is3DDisplay
        % 3D display uses groups to speed the pathway computation
        if isempty(sGroups)
            % Assign groups
            sGroups = AssignGroupBasedOnCentroid(RowLocs, RowNames, sGroups, SurfaceMat);
        end
    else
        % If no hierarchy is defined, display in circle
        if isempty(sGroups)
            % No data to arrange in groups
            if isempty(RowLocs) || isempty(SurfaceMat)
                DisplayInCircle = 1;
                % Create a group for each node
                sGroups = repmat(struct('Name', [], 'RowNames', [], 'Region', []), 0);
                for i=1:length(RowNames)
                    sGroups(1).Name = RowNames{i};
                    sGroups(1).RowNames = [sGroups(1).RowNames {num2str(RowNames{i})}];
                    sGroups(1).Region = 'UU';
                end
            else
                % We have location data so we can aim for
                % a basic 4 quadrants display
                DisplayInRegion = 1;            
                sGroups = AssignGroupBasedOnCentroid(RowLocs, RowNames, sGroups, SurfaceMat);
            end
        else
            % Display in region
            DisplayInRegion = 1;
            % Force basic Anterior/Posterior if necessary
            if (length(sGroups) == 2 && ...
                strcmp(sGroups(1).Region(2), 'U') == 1 && ...
                strcmp(sGroups(2).Region(2), 'U') == 1)
                sGroups = AssignGroupBasedOnCentroid(RowLocs, RowNames, sGroups, SurfaceMat);
            end
        end
    end
    setappdata(hFig, 'DisplayInCircle', DisplayInCircle);
    setappdata(hFig, 'DisplayInRegion', DisplayInRegion);
    setappdata(hFig, 'is3DDisplay', is3DDisplay);

    % IsBinaryData -> Granger
    % IsDirectionalData -> Granger
    setappdata(hFig, 'DefaultRegionFunction', 'max');
    setappdata(hFig, 'DisplayOutwardMeasure', 1);
    setappdata(hFig, 'DisplayInwardMeasure', 1);
    setappdata(hFig, 'HasLocationsData', ~isempty(RowLocs));
    setappdata(hFig, 'MeasureDistanceFactor', 1000); % mm to m
    
    % Retrieve scout colors if possible
    RowColors = BuildNodeColorList(RowNames, Atlas);
    
    % Keep a copy of these variable for figure updates
    setappdata(hFig, 'Groups', sGroups);
    setappdata(hFig, 'RowNames', RowNames);
    setappdata(hFig, 'RowLocs', RowLocs);
    setappdata(hFig, 'RowColors', RowColors);
    
    OGL = getappdata(hFig, 'OpenGLDisplay');
        
    %% ===== ORGANISE VERTICES =====    
    if DisplayInCircle
        [Vertices Paths Names] = OrganiseNodeInCircle(hFig, RowNames, sGroups);
    elseif DisplayInRegion
        [Vertices Paths Names] = OrganiseNodesWithConstantLobe(hFig, RowNames, sGroups, RowLocs, 1);
    elseif is3DDisplay
        % === 3D DISPLAY IS A PROTOTYPE ===
        % Copy cortex Vertices and Faces
        V = SurfaceMat.Vertices;
        F = SurfaceMat.Faces;
        % Scale vertex to stay inside viewing space
        CameraZoom = getappdata(hFig, 'CameraZoom');
        VertexScale3D = (CameraZoom + 1) / (max(sqrt(sum(V.^2,2))));
        % Centroid offset is used to center the model
        Centroid = sum(V,1) / size(V,1);
        V = V - repmat(Centroid, size(V,1), 1);
        V = V * VertexScale3D;
        % Reassign
        TempSurf = SurfaceMat;
        TempSurf.Vertices = V;
        
        % Both variables are needed in OrganiseChannelsIn3D
        setappdata(hFig, 'VertexScale3D', VertexScale3D);
        setappdata(hFig, 'VertexInitCentroid', Centroid);
        
        % Add polygon to Java
        OGL.addPolygon(reshape(V',[],1), reshape(F',[],1) - 1, 1);
        % Typical rendering options
        SetCortexTransparency(hFig, 0.025);
        OGL.setPolygonColor(0, 0, 0, 0);
        OGL.setPolygonVisible(0, 1);
        
%        Atlas = GlobalData.DataSet(iDS).Timefreq(iTimefreq).Atlas;
%        nScouts = size(Atlas.Scouts,2);
%        for i=1:nScouts
%             sV = Atlas.Scouts(i).Vertices;
%             vIndex = zeros(size(V,1),1);
%             vIndex(sV) = find(sV);
%             mF = ismember(F,sV);
%             sF = F(sum(mF,2) == 3,:);
%             sF = vIndex(sF(:,:));
%             
%             OGL.addPolygon(reshape(V(sV,:)',[],1), reshape(sF',[],1) - 1, 1);
%             OGL.setPolygonColor(i - 1, rand(1,1), rand(1,1), rand(1,1));
%             OGL.setPolygonTransparency(i - 1, 0.2);
% 
%             Outlines = ComputePolygonOutline(SurfaceMat, Atlas.Scouts(i));
%             O = Outlines{1};
%             OGL.addRegionOutline(V(sV(O),1), V(sV(O),2), V(sV(O),3));
%             OGL.setRegionOutlineColor(i - 1, rand(1,1), rand(1,1), rand(1,1));
%             OGL.setRegionOutlineTransparency(i - 1, 0.3);
%             OGL.setRegionOutlineThickness(i - 1, 0.5);
%        end

         % 3D agregating node connectivity map
        Conn = zeros(24);
        Connected = [1 2; 1 3; 1 17; 1 18; 1 20; 1 21;
                     2 1; 2 4; 2 18; 2 19; 2 21; 2 22;
                     3 1; 3 4; 3 7; 3 8; 3 10; 3 11;
                     4 2; 4 3; 4 8; 4 9; 4 11; 4 12;
                     ...
                     5 6; 5 8;
                     6 8;
                     7 8; 7 10;
                     8 9; 8 11;
                     9 12;
                     10 11;
                     11 12; 11 13; 11 14;
                     12 14;
                     13 14;
                     14 13;
                     ...
                     15 16; 15 18;
                     16 18;
                     17 18; 17 20;
                     18 19; 18 21;
                     19 22;
                     20 21;
                     21 22; 21 23; 21 24;
                     22 24;
                     23 24;
                     24 23];
        
        idx = sub2ind(size(Conn), Connected(:,1), Connected(:,2));
        idx2 = sub2ind(size(Conn), Connected(:,2), Connected(:,1));
        Conn([idx;idx2]) = 1;
        % Cost function is favoring middle lines (better display)
        Cost = ones(size(Conn));
        C = [8 5; 8 6; 8 11;
             11 13; 11 14; 11 8;
             18 15; 18 16; 18 21;
             21 23; 21 24; 21 18];
        idx = sub2ind(size(Cost), C(:,1), C(:,2));
        idx2 = sub2ind(size(Cost), C(:,2), C(:,1));
        Conn([idx;idx2]) = 1;% * 0.5;
        % Dijkstra 
        [tmp, AgregatingNodeConnectMap] = jk_dijkstra(Conn, Cost);
        setappdata(hFig, 'AgregatingNodeConnectMap', AgregatingNodeConnectMap);
        % 
        [Vertices Paths Names] = OrganiseChannelsIn3D(hFig, sGroups, RowNames, RowLocs, TempSurf);
    else
        disp('Unsupported display. Contact administrator, sorry for the inconvenience');
    end
    
    % Keep graph data
    setappdata(hFig, 'NumberOfNodes', size(Vertices,1));
    setappdata(hFig, 'Vertices', Vertices);
    setappdata(hFig, 'NodePaths', Paths);
    setappdata(hFig, 'Names', Names);
    setappdata(hFig, 'DisplayNode', ones(size(Vertices,1),1));
    setappdata(hFig, 'ValidNode', ones(size(Vertices,1),1));
    
    % Add nodes to Java
    %   This also defines some data-based display parameters
    ClearAndAddChannelsNode(hFig, Vertices, Names);
    
    % Background color :
    %   White is for publications
    %   Black for visualization (default)
    BackgroundColor = GetBackgroundColor(hFig);
    SetBackgroundColor(hFig, BackgroundColor);

    % Prototype (Not working)
    % Compute and add radial region for selection
    % if (is3DDisplay == 0 && DisplayInCircle == 0)
    %    SetupRadialRegion(hFig, Vertices, sGroups, RowNames, RowLocs);
    % end
    
    %% ===== Compute Links =====
    % Data cleaning options
    Options.Significance = 1;
    Options.Neighbours = 0;
    Options.Distance = 0;
    Options.Highest = 1;
    setappdata(hFig, 'LoadingOptions', Options);
    % Clean and compute Datapair
    DataPair = LoadConnectivityData(hFig, Options, Atlas, SurfaceMat);    
    setappdata(hFig, 'DataPair', DataPair);
    setappdata(hFig, 'HasSignificanceValue', size(DataPair,2) == 4);
    
    % Compute distance between regions
    MeasureDistance = [];
    if ~isempty(RowLocs)
        MeasureDistance = ComputeEuclidianMeasureDistance(hFig, DataPair, RowLocs);
    end
    setappdata(hFig, 'MeasureDistance', MeasureDistance);
    
    % Build path based on region
    if is3DDisplay
        MeasureLinks = BuildRegionPath3D(hFig, Paths, DataPair, Vertices);
    else
        MeasureLinks = BuildRegionPath(hFig, Paths, DataPair);
    end
    
    % Compute spline based on MeasureLinks
    aSplines = ComputeSpline(hFig, MeasureLinks, Vertices);
    if ~isempty(aSplines)
        % Add on Java side
        OGL.addPrecomputedMeasureLinks(aSplines);
        % Get link size
        LinkSize = getappdata(hFig, 'LinkSize');
        % Set link width
        SetLinkSize(hFig, LinkSize);
        % Set link transparency
        if (is3DDisplay)
            SetLinkTransparency(hFig, 0.75);
        else
            SetLinkTransparency(hFig, 0.00);
        end
    end
        
    %% ===== Init Filters =====
    % 
    MinThreshold = 0.9;
    if is3DDisplay
        MinThreshold = 0.5;        
    end
    
    % Don't refresh display for each filter at loading time
    Refresh = 0;
    
    % Clear filter masks
    setappdata(hFig, 'MeasureDistanceMask', zeros(size(DataPair,1),1));
    setappdata(hFig, 'MeasureThresholdMask', zeros(size(DataPair,1),1));
    setappdata(hFig, 'MeasureAnatomicalMask', zeros(size(DataPair,1),1));
    setappdata(hFig, 'MeasureDisplayMask', zeros(size(DataPair,1),1));
    setappdata(hFig, 'MeasureSignificanceMask', ones(size(DataPair,1),1));
    
    % Application specific display filter
    SetMeasureDisplayFilter(hFig, ones(size(DataPair,1), Refresh));
    % Min/Max distance filter
    SetMeasureDistanceFilter(hFig, 20, 150, Refresh);
    % Anatomy filter
    SetMeasureAnatomicalFilterTo(hFig, 0, Refresh);
    % Causality direction filter
    IsDirectionalData = getappdata(hFig, 'IsDirectionalData');
    if (IsDirectionalData)
        setDisplayMeasureMode(hFig, 1, 1, 1, Refresh);
    end
    % Threshold in absolute values
    if isempty(DataPair)
        ThresholdMinMax = [0 0];
    else
        ThresholdAbsoluteValue = getappdata(hFig, 'ThresholdAbsoluteValue');
        if isempty(ThresholdAbsoluteValue) || ~ThresholdAbsoluteValue
            ThresholdMinMax = [min(DataPair(:,3)), max(DataPair(:,3))];
        else
            ThresholdMinMax = [min(abs(DataPair(:,3))), max(abs(DataPair(:,3)))];
        end
    end
    setappdata(hFig, 'ThresholdMinMax', ThresholdMinMax);
    % Minimum measure filter
    SetMeasureThreshold(hFig, ThresholdMinMax(1) + MinThreshold * (ThresholdMinMax(2) - ThresholdMinMax(1)), Refresh);
    % Significance filter
    SetMeasureSignificanceFilterTo(hFig, GetSignificanceThreshold(hFig), Refresh);
    
    % Region links
    SetRegionFunction(hFig, getappdata(hFig, 'DefaultRegionFunction'));
    
    %% ===== Rendering option =====
    % Select all
    SetSelectedNodes(hFig, [], 1);
    % Blending
    SetBlendingMode(hFig, 0);
    
    % OpenGL Constant
    % GL_LIGHTING = 2896
    % GL_COLOR_MATERIAL 2903
    % GL_DEPTH_TEST = 2929
    
    % These options are necessary for proper display
    if ~is3DDisplay
        OGL.OpenGLDisable(2896);
        OGL.OpenGLDisable(2903);
        SetHierarchyNodeIsVisible(hFig, 1);
        RenderInQuad = 1;
    else
        OGL.OpenGLEnable(2896);
        OGL.OpenGLEnable(2903);
        SetHierarchyNodeIsVisible(hFig, 0);
        setappdata(hFig, 'TextDisplayMode', []);
        RenderInQuad = 0;
    end
    % 
    OGL.renderInQuad(RenderInQuad);
    setappdata(hFig, 'RenderInQuad', RenderInQuad);
    
    % Update colormap
    UpdateColormap(hFig);
    % 
    RefreshTextDisplay(hFig);
    % Last minute hiding
    HideLonelyRegionNode(hFig);
    % Position camera
    DefaultCamera(hFig);
    % Make sure we have a final request for redraw
    OGL.repaint();
end

function NodeColors = BuildNodeColorList(RowNames, Atlas)
    % We assume RowNames and Scouts are in the same order
    if ~isempty(Atlas)
        NodeColors = reshape([Atlas.Scouts.Color], 3, length(Atlas.Scouts))';
    else
        % Default neutral color
        NodeColors = 0.5 * ones(length(RowNames),3);
    end
end

function sGroups = AssignGroupBasedOnCentroid(RowLocs, RowNames, sGroups, Surface)
    % Compute centroid
    Centroid = sum(Surface.Vertices,1) / size(Surface.Vertices,1);
    % Split in hemisphere first if necessary
    if isempty(sGroups)
        % 
        sGroups(1).Name = 'Left';
        sGroups(1).Region = 'LU';
        sGroups(2).Name = 'Right';
        sGroups(2).Region = 'RU';
        % 
        sGroups(1).RowNames = RowNames(RowLocs(:,2) >= Centroid(2));    
        sGroups(2).RowNames = RowNames(RowLocs(:,2) < Centroid(2));
    end
    % For each hemisphere
    for i=1:2
        OriginalGroupRows = ismember(RowNames, [sGroups(i).RowNames]);
        Posterior = RowLocs(:,1) >= Centroid(1) & OriginalGroupRows;
        Anterior = RowLocs(:,1) < Centroid(1) & OriginalGroupRows;
        % Posterior assignment
        sGroups(i).Name = [sGroups(i).Name ' Posterior'];
        sGroups(i).RowNames = RowNames(Posterior)';
        sGroups(i).Region = [sGroups(i).Region(1) 'P'];
        % Anterior assignment
        sGroups(i+2).Name = [sGroups(i).Name ' Anterior'];
        sGroups(i+2).RowNames = RowNames(Anterior)';
        sGroups(i+2).Region = [sGroups(i).Region(1) 'A'];
    end
end

% Prototype
% function vpath = ComputePolygonOutline(Surface, Scout)
%     vpath = {};
%     if (length(Scout.Vertices) > 1)
%         % === BUILD FACES/VERTICES ===
%         % Move vertices away from the surface
%         %patchVertices = GetScoutPosition(Vertices, VertexNormals, sScouts(i).Vertices, 0.00001);
%         patchVertices = Surface.Vertices(Scout.Vertices, :);
%         % Get all the full faces in the scout patch
%         vertMask = false(length(Surface.Vertices),1);
%         vertMask(Scout.Vertices) = true;
%         % This syntax is faster but equivalent to: 
%         % patchFaces = Faces(all(vertMask(Faces),2),:);
%         iFacesTmp = find(vertMask(Surface.Faces(:,1)));
%         iFacesTmp = iFacesTmp(vertMask(Surface.Faces(iFacesTmp,2)));
%         iFacesTmp = iFacesTmp(vertMask(Surface.Faces(iFacesTmp,3)));
%         patchFaces = Surface.Faces(iFacesTmp,:);
%         % Renumber vertices in patchFaces
%         vertMask = zeros(length(Surface.Vertices),1);
%         vertMask(Scout.Vertices) = 1:length(Scout.Vertices);
%         patchFaces = vertMask(patchFaces);
%         % Re-orient if the orientation is wrong because of this last operation
%         if (size(patchFaces,2) == 1)
%             patchFaces = patchFaces';
%         end
% 
%         % === DRAW CONTOUR ===
%         % Vert-vert connect matrix of all the pairs of vertices
%         VertConn = Surface.VertConn(Scout.Vertices, Scout.Vertices);
%         % Remove the edges inside the contiguous faces
%         if ~isempty(patchFaces)
%             % Build pairs of connected vertices
%             nFaces = size(patchFaces,1);
%             nVert = size(patchVertices,1);
%             pairsVert1 = sparse([patchFaces(:,1); patchFaces(:,2)], [patchFaces(:,2); patchFaces(:,1)], ones(2*nFaces,1), nVert, nVert);
%             pairsVert2 = sparse([patchFaces(:,1); patchFaces(:,3)], [patchFaces(:,3); patchFaces(:,1)], ones(2*nFaces,1), nVert, nVert);
%             pairsVert3 = sparse([patchFaces(:,2); patchFaces(:,3)], [patchFaces(:,3); patchFaces(:,2)], ones(2*nFaces,1), nVert, nVert);
%             % Vert-vert connect matrix for vertex of an inside face (that have to be removed from the coutour)
%             VertConnFaces = (pairsVert1 + pairsVert2 + pairsVert3 >= 2);
%             % Remove pairs from the vert-vert connectivity
%             VertConn = (VertConn & ~VertConnFaces);
%             % If we removed everything (if the scout is a closed surface): take all the vertices connected directly to the seed
%             if (nnz(VertConn) == 0)
%                 % Find the seed in the vertex list
%                 iSeed = find(Scout.Vertices == Scout.Seed);
%                 % Keep the links connected to the seed
%                 VertConn(iSeed,:) = VertConnFaces(iSeed,:);
%                 VertConn(:,iSeed) = VertConnFaces(:,iSeed);
%             end
%         end
%         % Plot contour 
%         if nnz(VertConn)
%             iv = [];
%             % Loop to process all the links of the connectivity matrix
%             while nnz(VertConn)
%                 % Find all the links for the last element of path
%                 if ~isempty(iv)
%                     jv = find(VertConn(iv,:));
%                     if (length(jv) > 1)
%                         [tmp, imax] = max(sum(VertConn(:,jv)));
%                         jv = jv(imax(1));
%                     end
%                     if ~isempty(jv)
%                         % Add link to current path
%                         vpath{end}(end+1) = jv;
%                         % If a link was consumed: remove it from the connectivity matrix
%                         VertConn(iv,jv) = false;
%                         VertConn(jv,iv) = false;
%                     end
%                     % Next node
%                     iv = jv;
%                 % No path: Create a new path, with the first link in the connectivity matrix
%                 else
%                     % Start from a week node (end of chain: only one connection)
%                     minConn = sum(VertConn);
%                     minConn(minConn == 0) = Inf;
%                     [tmp, imin] = min(minConn);
%                     % Start a new path
%                     iv = imin;
%                     vpath{end+1} = iv;
%                 end
%             end               
%         end
%     end
% end


function UpdateFigurePlot(hFig)
    % Progress bar
    bst_progress('start', 'Functional Connectivity Display', 'Updating figures...');
    % Get selected rows
    selNodes = getappdata(hFig, 'SelectedNodes');
    % Get OpenGL handle
    OGL = getappdata(hFig, 'OpenGLDisplay');
    % Clear links
    OGL.clearLinks();
    % 3D display ?
    is3DDisplay = getappdata(hFig, 'is3DDisplay');
    % Get Rowlocs
    RowLocs = getappdata(hFig, 'RowLocs');

    OrganiseNode = getappdata(hFig, 'OrganiseNode');
    if ~isempty(OrganiseNode)
        % Reset display
        OGL.resetDisplay();
        % Back to Default camera
        DefaultCamera(hFig);
        % Which hierarchy level are we ?
        NodeLevel = 1;
        Levels = getappdata(hFig, 'Levels');
        for i=1:size(Levels,1)
            if ismember(OrganiseNode,Levels{i})
                NodeLevel = i;
            end
        end
        % 
        Groups = getappdata(hFig, 'Groups');
        RowNames = getappdata(hFig, 'RowNames');        
        nAgregatingNodes = size(getappdata(hFig, 'AgregatingNodes'),2);
        % 
        Nodes = getAgregatedNodesFrom(hFig, OrganiseNode);
        % 
        Channels = ismember(RowNames, [Groups.RowNames]);
        Index = find(Channels) + nAgregatingNodes;
        InGroups = Index(ismember(Index,Nodes)) - nAgregatingNodes;
        NamesOfNodes = RowNames(InGroups);
        
        GroupsIWant = [];
        for i=1:size(Groups,2)
            if (sum(ismember(Groups(i).RowNames, NamesOfNodes)) > 0)
                GroupsIWant = [GroupsIWant i];
            end
        end
        
        if (OrganiseNode == 1)
            % Return to first display
            DisplayInCircle = getappdata(hFig, 'DisplayInCircle');
            if (~isempty(DisplayInCircle) && DisplayInCircle == 1)
                Vertices = OrganiseNodeInCircle(hFig, RowNames, Groups);
            else
                Vertices = OrganiseNodesWithConstantLobe(hFig, RowNames, Groups, RowLocs, 1);
            end
        else
            % 
            Vertices = ReorganiseNodeAroundInCircle(hFig, Groups(GroupsIWant), RowNames, NodeLevel);
        end
        % 
        setappdata(hFig, 'Vertices', Vertices);
        % 
        nVertices = size(Vertices,1);
        Visible = sum(Vertices(:,1:3) ~= repmat([0 0 -5], nVertices,1),2) >= 1;
        % 
        DisplayNode = zeros(nVertices,1);
        DisplayNode(OrganiseNode) = 1;
        DisplayNode(Visible) = 1;
        % 
        setappdata(hFig, 'DisplayNode', DisplayNode);
        setappdata(hFig, 'ValidNode', DisplayNode);
        % Add the nodes to Java
        ClearAndAddChannelsNode(hFig, Vertices, getappdata(hFig, 'Names'));
    else
        % We assume that if 3D display, we did not unload the polygons
        % so we simply need to load new data
    end
    
    Options = getappdata(hFig, 'LoadingOptions');
    % Clean and Build Datapair
    DataPair = LoadConnectivityData(hFig, Options);
    % Update structure
    setappdata(hFig, 'DataPair', DataPair);    
        
    % Update measure distance
    MeasureDistance = [];
    if ~isempty(RowLocs)
        MeasureDistance = ComputeEuclidianMeasureDistance(hFig, DataPair, RowLocs);
    end
    % Update figure variable
    setappdata(hFig, 'MeasureDistance', MeasureDistance);
    
    % Get computed vertices
    Vertices = getappdata(hFig, 'Vertices');
    % Get computed vertices paths to center
    NodePaths = getappdata(hFig, 'NodePaths');
    % Build Datapair path based on region
    if is3DDisplay
        MeasureLinks = BuildRegionPath3D(hFig, NodePaths, DataPair, Vertices);
    else
        MeasureLinks = BuildRegionPath(hFig, NodePaths, DataPair);
    end
    % Compute spline for MeasureLinks based on Vertices position
    aSplines = ComputeSpline(hFig, MeasureLinks, Vertices);
    if ~isempty(aSplines)
        % Add on Java side
        OGL.addPrecomputedMeasureLinks(aSplines);
        % Set link width
        SetLinkSize(hFig, getappdata(hFig, 'LinkSize'));
        % Set link transparency
        SetLinkTransparency(hFig, getappdata(hFig, 'LinkTransparency'));
    end
    
    %% ===== FILTERS =====
    Refresh = 0;
    
    % Init Filter variables
    setappdata(hFig, 'MeasureDistanceMask', zeros(size(DataPair,1),1));
    setappdata(hFig, 'MeasureThresholdMask', zeros(size(DataPair,1),1));
    setappdata(hFig, 'MeasureAnatomicalMask', zeros(size(DataPair,1),1));
    setappdata(hFig, 'MeasureDisplayMask', zeros(size(DataPair,1),1));
    setappdata(hFig, 'MeasureSignificanceMask', ones(size(DataPair,1),1));
    
    % Threshold 
    if isempty(DataPair)
        ThresholdMinMax = [0 0];
    else
        ThresholdAbsoluteValue = getappdata(hFig, 'ThresholdAbsoluteValue');
        if isempty(ThresholdAbsoluteValue) || ~ThresholdAbsoluteValue
            ThresholdMinMax = [min(DataPair(:,3)), max(DataPair(:,3))];
        else
            ThresholdMinMax = [min(abs(DataPair(:,3))), max(abs(DataPair(:,3)))];
        end
    end
    setappdata(hFig, 'ThresholdMinMax', ThresholdMinMax);

    % Reset filters using the same thresholds
    SetMeasureDisplayFilter(hFig, ones(size(DataPair,1),1), Refresh);
    SetMeasureDistanceFilter(hFig, getappdata(hFig,'MeasureMinDistanceFilter'), getappdata(hFig,'MeasureMaxDistanceFilter'), Refresh);
    SetMeasureAnatomicalFilterTo(hFig, getappdata(hFig, 'MeasureAnatomicalFilter'), Refresh);
    SetMeasureThreshold(hFig, getappdata(hFig, 'MeasureThreshold'), Refresh);
    
    % Update region datapair if possible
    RegionFunction = getappdata(hFig, 'RegionFunction');
    if isempty(RegionFunction)
        RegionFunction = getappdata(hFig, 'DefaultRegionFunction');
    end
    SetRegionFunction(hFig, RegionFunction);

    HierarchyNodeIsVisible = getappdata(hFig, 'HierarchyNodeIsVisible');
    SetHierarchyNodeIsVisible(hFig, HierarchyNodeIsVisible);
    
    RenderInQuad = getappdata(hFig, 'RenderInQuad');
    OGL.renderInQuad(RenderInQuad);
    
    RefreshTitle(hFig);
    
    % Set background color
    SetBackgroundColor(hFig, GetBackgroundColor(hFig));
    % Update colormap
    UpdateColormap(hFig);
    % Redraw selected nodes
    SetSelectedNodes(hFig, selNodes, 1, 1);
    % Update panel
    panel_display('UpdatePanel', hFig);
    % 
    bst_progress('stop');
end

function SetDisplayNodeFilter(hFig, NodeIndex, IsVisible)
    % Get OpenGL handle
	OGL = getappdata(hFig, 'OpenGLDisplay');
    % Update variable
    if (IsVisible == 0)
        IsVisible = -1;
    end
    DisplayNode = getappdata(hFig, 'DisplayNode');
    DisplayNode(NodeIndex) = DisplayNode(NodeIndex) + IsVisible;
    setappdata(hFig, 'DisplayNode', DisplayNode);
    % Update java
    if (IsVisible <= 0)       
        Index = find(DisplayNode <= 0);
    else
        Index = find(DisplayNode > 0);
    end
    for i=1:size(Index,1)
        OGL.setNodeVisibility(Index(i) - 1, DisplayNode(Index(i)) > 0);
    end
    % Redraw
    OGL.repaint();
end

function HideLonelyRegionNode(hFig)
    %
    DisplayInRegion = getappdata(hFig, 'DisplayInRegion');
    if (DisplayInRegion)
        % Get Nodes
        AgregatingNodes = getappdata(hFig, 'AgregatingNodes');
%        MeasureNodes = getappdata(hFig, 'MeasureNodes');
        ChannelData = getappdata(hFig, 'ChannelData');
        for i=1:size(AgregatingNodes,2)
            % Hide nodes with only one measure node
            Search = find(ChannelData(i,:) ~= 0, 1, 'first');
            if (~isempty(Search))
%             Sum = sum(ismember(ChannelData(MeasureNodes,Search), ChannelData(i,Search)));
%             if ~isempty(Sum)
%                 if (Sum <= 1)
%                     OGL.setNodeVisibility(i - 1, 0);
%                    % DisplayNode(i) = 0;
%                 end
%             end
                % Hide nodes with only one region node
                Member = ismember(ChannelData(AgregatingNodes,Search), ChannelData(i,Search));
                SameHemisphere = ismember(ChannelData(AgregatingNodes,3), ChannelData(i,3));
                Member = Member & SameHemisphere;
                Member(i) = 0;
                % If there's only one sub-region, hide it
                if (sum(Member)== 1)
                    SetDisplayNodeFilter(hFig, find(Member), 0);
                end
            end
        end
    end
end


%% ===== FILTERS =====
function SetMeasureDisplayFilter(hFig, NewMeasureDisplayMask, Refresh)
    % Refresh by default
    if (nargin < 3)
        Refresh = 1;
    end
    % Get selected rows
    selNodes = getappdata(hFig, 'SelectedNodes');
    if (Refresh)
        % Remove previous links
        SetSelectedNodes(hFig, selNodes, 0, 0);
    end
    % Update variable
    setappdata(hFig, 'MeasureDisplayMask', NewMeasureDisplayMask);
    if (Refresh)
        % Redraw selected nodes
        SetSelectedNodes(hFig, selNodes, 1, Refresh);
    end
end

function SetMeasureThreshold(hFig, NewMeasureThreshold, Refresh)
    % Refresh by default
    if (nargin < 3)
        Refresh = 1;
    end
    % Get selected rows
    selNodes = getappdata(hFig, 'SelectedNodes');
    % Get Datapair
    DataPair = getappdata(hFig, 'DataPair');
    % Get threshold option
    ThresholdAbsoluteValue = getappdata(hFig, 'ThresholdAbsoluteValue');
    if (ThresholdAbsoluteValue)
        DataPair(:,3) = abs(DataPair(:,3));
    end
    % Compute new mask
    MeasureThresholdMask = DataPair(:,3) >= NewMeasureThreshold;
    if (Refresh)
        % Remove previous links
        SetSelectedNodes(hFig, selNodes, 0, 0);
    end
    % Update variable
    setappdata(hFig, 'MeasureThreshold', NewMeasureThreshold);
    setappdata(hFig, 'MeasureThresholdMask', MeasureThresholdMask);
    if (Refresh)
        % Redraw selected nodes
        SetSelectedNodes(hFig, selNodes, 1, Refresh);
    end
end

function SetMeasureAnatomicalFilterTo(hFig, NewMeasureAnatomicalFilter, Refresh)
    % Refresh by default
    if (nargin < 3)
        Refresh = 1;
    end
    DataPair = getappdata(hFig, 'DataPair');
    % Get selected rows
    selNodes = getappdata(hFig, 'SelectedNodes');    
    % Compute new mask
    NewMeasureAnatomicalMask = GetMeasureAnatomicalMask(hFig, DataPair, NewMeasureAnatomicalFilter);
    if (Refresh)
        % Remove previous links
        SetSelectedNodes(hFig, selNodes, 0, 0);
    end
    % Update variable
    setappdata(hFig, 'MeasureAnatomicalFilter', NewMeasureAnatomicalFilter);
    setappdata(hFig, 'MeasureAnatomicalMask', NewMeasureAnatomicalMask);
    if (Refresh)
        % Redraw selected nodes
        SetSelectedNodes(hFig, selNodes, 1, Refresh);
    end
end

function MeasureAnatomicalMask = GetMeasureAnatomicalMask(hFig, DataPair, MeasureAnatomicalFilter)
    ChannelData = getappdata(hFig, 'ChannelData');
    MeasureAnatomicalMask = zeros(size(DataPair,1),1);
    switch (MeasureAnatomicalFilter)
        case 0 % 0 - All
            MeasureAnatomicalMask(:) = 1;
        case 1 % 1 - Between Hemisphere
            MeasureAnatomicalMask = ChannelData(DataPair(:,1),3) ~= ChannelData(DataPair(:,2),3);
        case 2 % 2 - Between Lobe == Not Same Region
            MeasureAnatomicalMask = ChannelData(DataPair(:,1),1) ~= ChannelData(DataPair(:,2),1);
    end
end

function SetMeasureDistanceFilter(hFig, NewMeasureMinDistanceFilter, NewMeasureMaxDistanceFilter, Refresh)
    % Refresh by default
    if (nargin < 4)
        Refresh = 1;
    end
    % Get selected rows
    selNodes = getappdata(hFig, 'SelectedNodes');        
    % Get distance measures
    MeasureDistance = getappdata(hFig, 'MeasureDistance');
    if isempty(MeasureDistance)
        % Everything
        MeasureDistanceMask = ones(size(MeasureDistance));
    else
        % Compute intersection
        MeasureDistanceMask = (MeasureDistance <= NewMeasureMaxDistanceFilter) & (MeasureDistance(:) >= NewMeasureMinDistanceFilter);
    end
    if (Refresh)
        % Remove previous links
        SetSelectedNodes(hFig, selNodes, 0, 0);
    end
    % Update variable
    setappdata(hFig, 'MeasureMinDistanceFilter', NewMeasureMinDistanceFilter);
    setappdata(hFig, 'MeasureMaxDistanceFilter', NewMeasureMaxDistanceFilter);
    setappdata(hFig, 'MeasureDistanceMask', MeasureDistanceMask);
    if (Refresh)
        % Redraw selected nodes
        SetSelectedNodes(hFig, selNodes, 1, Refresh);
    end
end

function SignificanceThreshold = GetSignificanceThreshold(hFig)
    SignificanceThreshold = getappdata(hFig, 'SignificanceThreshold');
    if isempty(SignificanceThreshold)
        SignificanceThreshold = 0.05;
    end
end

function SetMeasureSignificanceFilterTo(hFig, SignificanceThreshold, Refresh)
    % Refresh by default
    if (nargin < 3)
        Refresh = 1;
    end
    % Data has significance value
    HasSignificanceValue = getappdata(hFig, 'HasSignificanceValue');
    if HasSignificanceValue
        % Get selected rows
        selNodes = getappdata(hFig, 'SelectedNodes');
        % Get Datapair
        DataPair = getappdata(hFig, 'DataPair');
        % Compute new mask
        MeasureSignificanceMask = DataPair(:,4) <= SignificanceThreshold;
        if (Refresh)
            % Remove previous links
            SetSelectedNodes(hFig, selNodes, 0, 0);
        end
        % Update variable
        setappdata(hFig, 'SignificanceThreshold', SignificanceThreshold);
        setappdata(hFig, 'MeasureSignificanceMask', MeasureSignificanceMask);
        if (Refresh)
            % Redraw selected nodes
            SetSelectedNodes(hFig, selNodes, 1, Refresh);
        end
    end
end

% function mMatrix = DataPairToMatrix(hFig, aFaces)
%     % 
%     Max = max(max(aFaces(:,:)));
%     % 
%     mMatrix = aFaces(:,[1 2]);
%     mMatrix = [mMatrix; aFaces(:,[1 3])];
%     mMatrix = [mMatrix; aFaces(:,[2 3])];
%     s = ones(size(mMatrix,1),1);
%     % 
%     mMatrix = sparse(mMatrix(:,1),mMatrix(:,2),s,Max,Max);
%     mMatrix = full(mMatrix);
%     mMatrix(mMatrix(:,:) >= 1) = 1;
% end

function mMeanDataPair = ComputeMeanMeasureMatrix(hFig, mDataPair)
    Levels = getappdata(hFig, 'Levels');
    Regions = Levels{2};
    NumberOfNode = size(Regions,1);
    mMeanDataPair = zeros(NumberOfNode*NumberOfNode,3);
    %
    for i=1:NumberOfNode
        OutNode = getAgregatedNodesFrom(hFig, Regions(i));
        for y=1:NumberOfNode
            if (i ~= y)
                InNode = getAgregatedNodesFrom(hFig, Regions(y));
                Index = ismember(mDataPair(:,1),OutNode) & ismember(mDataPair(:,2),InNode);
                nValue = sum(Index);
                if (nValue > 0)
                    Mean = sum(mDataPair(Index,3)) / sum(Index);
                    mMeanDataPair(NumberOfNode * (i - 1) + y, :) = [Regions(i) Regions(y) Mean];
                end
            end
        end
    end
    mMeanDataPair(mMeanDataPair(:,3) == 0,:) = [];
end

function mMaxDataPair = ComputeMaxMeasureMatrix(hFig, mDataPair)
    Levels = getappdata(hFig, 'Levels');
    Regions = Levels{2};
    NumberOfRegions = size(Regions,1);
    mMaxDataPair = zeros(NumberOfRegions*NumberOfRegions,3);
    
    % Precomputing this saves on processing time
    NodesFromRegions = cell(NumberOfRegions,1);
    for i=1:NumberOfRegions
        NodesFromRegions{i} = getAgregatedNodesFrom(hFig, Regions(i));
    end
    
    for i=1:NumberOfRegions
        for y=1:NumberOfRegions
            if (i ~= y)
                % Retrieve index
                Index = ismember(mDataPair(:,1),NodesFromRegions{i}) & ismember(mDataPair(:,2),NodesFromRegions{y});
                % If there is values
                if (sum(Index) > 0)
                    Max = max(mDataPair(Index,3));
                    mMaxDataPair(NumberOfRegions * (i - 1) + y, :) = [Regions(i) Regions(y) Max];
                end
            end
        end
    end
    % Eliminate empty data
    mMaxDataPair(mMaxDataPair(:,3) == 0,:) = [];
end


function MeasureDistance = ComputeEuclidianMeasureDistance(hFig, aDataPair, mLoc)
    % Correct offset
    nAgregatingNodes = size(getappdata(hFig, 'AgregatingNodes'),2);
    aDataPair(:,1:2) = aDataPair(:,1:2) - nAgregatingNodes;
    % Compute Euclidian distance
    Minus = bsxfun(@minus, mLoc(aDataPair(:,1),:), mLoc(aDataPair(:,2),:));
    MeasureDistance = sqrt(sum(Minus(:,:) .^ 2,2));
    % Convert measure according to factor
    MeasureDistanceFactor = getappdata(hFig, 'MeasureDistanceFactor');
    if isempty(MeasureDistanceFactor)
        MeasureDistanceFactor = 1;
    end
    MeasureDistance = MeasureDistance * MeasureDistanceFactor;
end


%% ===== GET DATA MASK =====
function [DataPair, DataMask] = GetPairs(hFig)
    % Get figure data
    DataPair = getappdata(hFig, 'DataPair');
    % Thresholded list
    if (nargout >= 2)
        MeasureDisplayMask = getappdata(hFig, 'MeasureDisplayMask');
        MeasureDistanceMask = getappdata(hFig, 'MeasureDistanceMask');
        MeasureAnatomicalMask = getappdata(hFig, 'MeasureAnatomicalMask');
        MeasureThresholdMask = getappdata(hFig, 'MeasureThresholdMask'); 
        MeasureSignificanceMask = getappdata(hFig, 'MeasureSignificanceMask');
        
        DataMask = ones(size(DataPair,1),1);
        % Display specific filter
        if ~isempty(MeasureDisplayMask)
            DataMask =  DataMask == 1 & MeasureDisplayMask == 1;
        end
        % Distance filter
        if ~isempty(MeasureDistanceMask)
            DataMask =  DataMask == 1 & MeasureDistanceMask == 1;
        end
        % Anatomical filter
        if ~isempty(MeasureAnatomicalMask)
            DataMask =  DataMask == 1 & MeasureAnatomicalMask == 1;
        end
        % Intensity Threshold filter
        if ~isempty(MeasureThresholdMask)
            DataMask =  DataMask == 1 & MeasureThresholdMask == 1;
        end
        % Significance filter
        if ~isempty(MeasureSignificanceMask)
            DataMask =  DataMask == 1 & MeasureSignificanceMask == 1;
        end
    end
end

function [RegionDataPair, RegionDataMask] = GetRegionPairs(hFig)
    % Get figure data
    RegionDataPair = getappdata(hFig, 'RegionDataPair');
    RegionDataMask = ones(size(RegionDataPair,1),1);
    if (size(RegionDataPair,1) > 0)
        % Get threshold option
        ThresholdAbsoluteValue = getappdata(hFig, 'ThresholdAbsoluteValue');
        if (ThresholdAbsoluteValue)
            RegionDataPair(:,3) = abs(RegionDataPair(:,3));
        end
        % Get threshold
        MeasureThreshold = getappdata(hFig, 'MeasureThreshold');
        if (~isempty(MeasureThreshold))
            % Compute new mask
            MeasureThresholdMask = RegionDataPair(:,3) >= MeasureThreshold;
            RegionDataMask = RegionDataMask & MeasureThresholdMask;
        end
        % Get anatomical filter
        MeasureAnatomicalFilter = getappdata(hFig, 'MeasureAnatomicalFilter');
        if (~isempty(MeasureAnatomicalFilter))
            % Compute new mask
            NewMeasureAnatomicalMask = GetMeasureAnatomicalMask(hFig, RegionDataPair, MeasureAnatomicalFilter);
            RegionDataMask = RegionDataMask & NewMeasureAnatomicalMask;
        end
    end
end


%% ===== UPDATE COLORMAP =====
function UpdateColormap(hFig)   
    % Get selected frequencies and rows
    TfInfo = getappdata(hFig, 'Timefreq');
    if isempty(TfInfo)
        return
    end
    % Get data description
    iDS = bst_memory('GetDataSetTimefreq', TfInfo.FileName);
    if isempty(iDS)
        return
    end
    % Get colormap
    sColormap = bst_colormaps('GetColormap', hFig);
    % Get DataPair
    [DataPair, DataMask] = GetPairs(hFig);    
    if sColormap.isAbsoluteValues
        DataPair(:,3) = abs(DataPair(:,3));
    end
    % Get figure method
    Method = getappdata(hFig, 'Method');
    % Get maximum values
    DataMinMax = getappdata(hFig, 'DataMinMax');
    % Get threshold min/max values
    ThresholdMinMax = getappdata(hFig, 'ThresholdMinMax');
    % === COLORMAP LIMITS ===
    % Units type
    if ismember(Method, {'granger', 'plv', 'plvt'})
        UnitsType = 'timefreq';
    else
        UnitsType = 'connect';
    end
    % Get colormap bounds
    if strcmpi(sColormap.MaxMode, 'custom')
        CLim = [sColormap.MinValue, sColormap.MaxValue];
    elseif ismember(Method, {'granger', 'plv', 'plvt'})
        CLim = [DataMinMax(1) DataMinMax(2)];
    elseif ismember(Method, {'corr'})
        if strcmpi(sColormap.MaxMode, 'local')
            CLim = ThresholdMinMax;
            if sColormap.isAbsoluteValues
                CLim = abs(CLim);            
            end
        else
            if sColormap.isAbsoluteValues
                CLim = [0, 1];
            else
                CLim = [-1, 1];
            end
        end
    elseif ismember(Method, {'cohere'})
        CLim = [0, 1];
    end
    setappdata(hFig, 'CLim', CLim);
    
    % === SET COLORMAP ===
    % Update colorbar font size
    hColorbar = findobj(hFig, '-depth', 1, 'Tag', 'Colorbar');
    if ~isempty(hColorbar)
        set(hColorbar, 'FontSize', bst_get('FigFont'), 'FontUnits', 'points');
    end
    % Get figure colormap
    ColormapInfo = getappdata(hFig, 'Colormap');
    sColormap = bst_colormaps('GetColormap', ColormapInfo.Type);
    % Set figure colormap
    set(hFig, 'Colormap', sColormap.CMap);
    % Create/Delete colorbar
    bst_colormaps('SetColorbarVisible', hFig, sColormap.DisplayColorbar);
    % Display only one colorbar (preferentially the results colorbar)
    bst_colormaps('ConfigureColorbar', hFig, ColormapInfo.Type, UnitsType);
    
    % === UPDATE DISPLAY ===
    CMap = sColormap.CMap;
    OGL = getappdata(hFig, 'OpenGLDisplay');
    is3DDisplay = getappdata(hFig, 'is3DDisplay');
    
    if (sum(DataMask) > 0)
        % Normalize DataPair for Offset
        Max = max(DataPair(:,3));
        Min = min(abs(DataPair(:,3)));
        Diff = (Max - Min);
        if (Diff == 0)
            Offset = DataPair(DataMask,3);
        else
            Offset = (abs(DataPair(DataMask,3)) - Min) ./ (Max - Min);
        end
        % Interpolate
        [StartColor, EndColor] = InterpolateColorMap(hFig, DataPair(DataMask,:), CMap, CLim);
        % Update color
        OGL.setMeasureLinkColorGradient( ...
            find(DataMask) - 1, ...
            StartColor(:,1), StartColor(:,2), StartColor(:,3), ...
            EndColor(:,1), EndColor(:,2), EndColor(:,3));
        if (~is3DDisplay)
            % Offset is always in absolute
            OGL.setMeasureLinkOffset(find(DataMask) - 1, Offset(:).^2 * 2);
        end
    end
    
    [RegionDataPair, RegionDataMask] = GetRegionPairs(hFig);
    if (sum(RegionDataMask) > 0)
        % Normalize DataPair for Offset
        Max = max(RegionDataPair(:,3));
        Min = min(RegionDataPair(:,3));
        Diff = (Max - Min);
        if (Diff == 0)
            Offset = RegionDataPair(RegionDataMask,3);
        else
            Offset = (abs(RegionDataPair(RegionDataMask,3)) - Min) ./ (Max - Min);
        end
        % Normalize within the colormap range 
        [StartColor, EndColor] = InterpolateColorMap(hFig, RegionDataPair(RegionDataMask,:), CMap, CLim);
        % Update display
        OGL.setRegionLinkColorGradient( ...
            find(RegionDataMask) - 1, ...
            StartColor(:,1), StartColor(:,2), StartColor(:,3), ...
            EndColor(:,1), EndColor(:,2), EndColor(:,3));
        if (~is3DDisplay)
            % Offset is always in absolute
            OGL.setRegionLinkOffset(find(RegionDataMask) - 1, Offset(:).^2 * 2);
        end
    end
    
    OGL.repaint();
end


function [StartColor EndColor] = InterpolateColorMap(hFig, DataPair, ColorMap, Limit)
    IsBinaryData = getappdata(hFig, 'IsBinaryData');
    if (~isempty(IsBinaryData) && IsBinaryData == 1)
        % Retrieve ColorMap extremeties
        nDataPair = size(DataPair,1);
        % 
        StartColor(:,:) = repmat(ColorMap(1,:), nDataPair, 1);
        EndColor(:,:) = repmat(ColorMap(end,:), nDataPair, 1);
        % Bidirectional data ?
        DisplayBidirectionalMeasure = getappdata(hFig, 'DisplayBidirectionalMeasure');
        if (DisplayBidirectionalMeasure)
            % Get Bidirectional data
            OutIndex = ismember(DataPair(:,1:2),DataPair(:,2:-1:1),'rows');
            InIndex = ismember(DataPair(:,1:2),DataPair(:,2:-1:1),'rows');
            % Bidirectional links in total Green
            StartColor(OutIndex | InIndex,1) = 0;
            StartColor(OutIndex | InIndex,2) = 0.7;
            StartColor(OutIndex | InIndex,3) = 0;
            EndColor(OutIndex | InIndex,:) = StartColor(OutIndex | InIndex,:);
        end
    else
        % Normalize and interpolate
        a = (DataPair(:,3)' - Limit(1)) / (Limit(2) - Limit(1));
        b = linspace(0,1,size(ColorMap,1));
        m = size(a,2);
        n = size(b,2);
        [tmp,p] = sort([a,b]);
        q = 1:m+n; q(p) = q;
        t = cumsum(p>m);
        r = 1:n; r(t(q(m+1:m+n))) = r;
        s = t(q(1:m));
        id = r(max(s,1));
        iu = r(min(s+1,n));
        [tmp,it] = min([abs(a-b(id));abs(b(iu)-a)]);
        StartColor = ColorMap(id+(it-1).*(iu-id),:);
        EndColor = ColorMap(id+(it-1).*(iu-id),:);
    end
end


%% ===== UPDATE CAMERA =====
function UpdateCamera(hFig)
    Pos = getappdata(hFig, 'CameraPosition');
    CameraTarget = getappdata(hFig, 'CameraTarget');
    Zoom = getappdata(hFig, 'CameraZoom');
    OGL = getappdata(hFig, 'OpenGLDisplay');
    OGL.zoom(Zoom);
    OGL.lookAt(Pos(1), Pos(2), Pos(3), CameraTarget(1), CameraTarget(2), CameraTarget(3), 0, 0, 1);
    OGL.repaint();
end

%% ===== ZOOM CAMERA =====
function ZoomCamera(hFig, inc)
    Zoom = getappdata(hFig, 'CameraZoom');
    Zoom = Zoom + (inc * 0.01);
    setappdata(hFig, 'CameraZoom', Zoom);
	UpdateCamera(hFig);
end

%% ===== ROTATE CAMERA =====
function RotateCameraAlongAxis(hFig, theta, phi)
	Pos = getappdata(hFig, 'CameraPosition');
    Target = getappdata(hFig, 'CameraTarget');
    Zoom = getappdata(hFig, 'CameraZoom');
    Pitch = getappdata(hFig, 'CamPitch');
    Yaw = getappdata(hFig, 'CamYaw');
    
    Pitch = Pitch + theta;
    Yaw = Yaw + phi;
    if (Pitch > (0.5 * 3.1415))
        Pitch = (0.5 * 3.1415);
    elseif (Pitch < -(0.5 * 3.1415))
        Pitch = -(0.5 * 3.1415);
    end
    
    % Projection 
    Pos(1) = cos(Yaw) * cos(Pitch);
	Pos(2) = sin(Yaw) * cos(Pitch);
    Pos(3) = sin(Pitch);
    Pos = Target + Zoom * Pos;
    
    setappdata(hFig, 'CamPitch', Pitch);
    setappdata(hFig, 'CamYaw', Yaw);
    setappdata(hFig, 'CameraPosition', Pos);

	UpdateCamera(hFig);
end

function MoveCamera(hFig, Translation)
    CameraPosition = getappdata(hFig, 'CameraPosition') + Translation;
    CameraTarget = getappdata(hFig, 'CameraTarget') + Translation;
    setappdata(hFig, 'CameraPosition', CameraPosition);
    setappdata(hFig, 'CameraTarget', CameraTarget);
    UpdateCamera(hFig);
end


%% ===========================================================================
%  ===== NODE DISPLAY AND SELECTION ==========================================
%  ===========================================================================

%% ===== SET SELECTED NODES =====
% USAGE:  SetSelectedNodes(hFig, iNodes=[], isSelected=1, isRedraw=1) : Add or remove nodes from the current selection
%         If node selection is empty: select/unselect all the nodes
function SetSelectedNodes(hFig, iNodes, isSelected, isRedraw)
    % Parse inputs
    if (nargin < 2) || isempty(iNodes)
        % Get all the nodes
        NumberOfNodes = getappdata(hFig, 'NumberOfNodes');
        iNodes = 1:NumberOfNodes;
    end
    if (nargin < 3) || isempty(isSelected)
        isSelected = 1;
    end
    if (nargin < 4) || isempty(isRedraw)
        isRedraw = 1;
    end
    % Get list of selected channels
    selNodes = getappdata(hFig, 'SelectedNodes');
    % If nodes are not specified
    if (nargin < 3)
        iNodes = selNodes;
        isSelected = 1;
    end
    % Define node properties
    if isSelected
        SelectedNodeColor = [0.95, 0.0, 0.0];
        selNodes = union(selNodes, iNodes);
    else
        SelectedNodeColor = getappdata(hFig, 'BgColor');
        selNodes = setdiff(selNodes, iNodes);
    end
    % Update list of selected channels
    setappdata(hFig, 'SelectedNodes', selNodes);
    
    % Get OpenGL handle
    OGL = getappdata(hFig, 'OpenGLDisplay');
    
    % Agregating nodes are not visually selected
    AgregatingNodes = getappdata(hFig, 'AgregatingNodes');
    NoColorNodes = ismember(iNodes,AgregatingNodes);
    if (sum(~NoColorNodes) > 0)
        if isSelected
            OGL.setNodeOuterCircleVisibility(iNodes(~NoColorNodes) - 1, 1);
            OGL.setNodeOuterColor(iNodes(~NoColorNodes) - 1, SelectedNodeColor(1), SelectedNodeColor(2), SelectedNodeColor(3));
        else
            OGL.setNodeOuterCircleVisibility(iNodes(~NoColorNodes) - 1, 0);
        end
    end
    RefreshTextDisplay(hFig, isRedraw);
    
    % Get data
    MeasureLinksIsVisible = getappdata(hFig, 'MeasureLinksIsVisible');
    if (MeasureLinksIsVisible)
        [DataToFilter, DataMask] = GetPairs(hFig);
    else
        [DataToFilter, DataMask] = GetRegionPairs(hFig);
    end
    
    % ===== Selection based data filtering =====
    % Direction mask
    IsDirectionalData = getappdata(hFig, 'IsDirectionalData');
    if (~isempty(IsDirectionalData) && IsDirectionalData == 1)
        NodeDirectionMask = zeros(size(DataMask,1),1);
        DisplayOutwardMeasure = getappdata(hFig, 'DisplayOutwardMeasure');
        DisplayInwardMeasure = getappdata(hFig, 'DisplayInwardMeasure');
        DisplayBidirectionalMeasure = getappdata(hFig, 'DisplayBidirectionalMeasure');
        if (DisplayOutwardMeasure)
            OutMask = ismember(DataToFilter(:,1), iNodes);
            NodeDirectionMask = NodeDirectionMask | OutMask;
        end
        if (DisplayInwardMeasure)
            InMask = ismember(DataToFilter(:,2), iNodes);
            NodeDirectionMask = NodeDirectionMask | InMask;
        end
        if (DisplayBidirectionalMeasure)
            % Selection
            SelectedNodeMask = ismember(DataToFilter(:,1), iNodes) ...
                             | ismember(DataToFilter(:,2), iNodes);
            VisibleIndex = find(DataMask == 1);
            % Get Bidirectional data
            BiIndex = ismember(DataToFilter(DataMask,1:2),DataToFilter(DataMask,2:-1:1),'rows');
            NodeDirectionMask(VisibleIndex(BiIndex)) = 1;
            NodeDirectionMask = NodeDirectionMask & SelectedNodeMask;
        end
        UserSpecifiedBinaryData = getappdata(hFig, 'UserSpecifiedBinaryData');
        if (isempty(UserSpecifiedBinaryData) || UserSpecifiedBinaryData == 0)
            % Update binary status
            RefreshBinaryStatus(hFig);                
        end
        DataMask = DataMask == 1 & NodeDirectionMask == 1;
    else
        % Selection filtering
        SelectedNodeMask = ismember(DataToFilter(:,1), iNodes) ...
                         | ismember(DataToFilter(:,2), iNodes);
        DataMask = DataMask & SelectedNodeMask;
    end
    
    % Links are from valid node only
    ValidNode = find(getappdata(hFig, 'ValidNode') > 0);
    ValidDataForDisplay = sum(ismember(DataToFilter(:,1:2), ValidNode),2);
    DataMask = DataMask == 1 & ValidDataForDisplay == 2;

    iData = find(DataMask == 1) - 1;
    if (~isempty(iData))
        % Update visibility
        if (MeasureLinksIsVisible)
            OGL.setMeasureLinkVisibility(iData, isSelected);
        else
            OGL.setRegionLinkVisibility(iData, isSelected);
        end
    end
    
    % These functions sets global Boolean value in Java that allows
    % or disallows the drawing of these measures, which makes it
    % really fast to switch between the two mode
    OGL.setMeasureIsVisible(MeasureLinksIsVisible);
    OGL.setRegionIsVisible(~MeasureLinksIsVisible);
    
    % Redraw OpenGL
    if isRedraw
        OGL.repaint();
    end
end


%%
function SetHierarchyNodeIsVisible(hFig, isVisible)
    HierarchyNodeIsVisible = getappdata(hFig, 'HierarchyNodeIsVisible');
    if (HierarchyNodeIsVisible ~= isVisible)
        AgregatingNodes = getappdata(hFig, 'AgregatingNodes');
        if (isVisible)
            %ValidNode = find(getappdata(hFig, 'ValidNode'));
            %AgregatingNodes(ismember(AgregatingNodes,ValidNode)) = [];
        end
        SetDisplayNodeFilter(hFig, AgregatingNodes, isVisible);
        % Update variable
        setappdata(hFig, 'HierarchyNodeIsVisible', isVisible);
    end
    % Make sure they are invisible
    HideLonelyRegionNode(hFig);
end


%% 
function RegionDataPair = SetRegionFunction(hFig, RegionFunction)
    % Does data has regions to cluster ?
    DisplayInCircle = getappdata(hFig, 'DisplayInCircle');
    if (isempty(DisplayInCircle) || DisplayInCircle == 0)    
        % Get data
        DataPair = GetPairs(hFig);
        % Which function
        switch (RegionFunction)
            case 'mean'
                RegionDataPair = ComputeMeanMeasureMatrix(hFig, DataPair);
            case 'max'
                RegionDataPair = ComputeMaxMeasureMatrix(hFig, DataPair);
            otherwise
                disp('The region function specified is not yet supported. Default to mean.');
                RegionFunction = 'mean';
                RegionDataPair = ComputeMeanMeasureMatrix(hFig, M);
        end
        %
        OGL = getappdata(hFig, 'OpenGLDisplay');
        % Clear
        OGL.clearRegionLinks();
        %
        Paths = getappdata(hFig, 'NodePaths');
        Vertices = getappdata(hFig, 'Vertices');
        % Build path for new datapair
        MeasureLinks = BuildRegionPath(hFig, Paths, RegionDataPair);
        % Compute spline
        aSplines = ComputeSpline(hFig, MeasureLinks, Vertices);
        if (~isempty(aSplines))
            % Add on Java side
            OGL.addPrecomputedHierarchyLink(aSplines); 
            % Get link size
            LinkSize = 6;
            % Width
            OGL.setRegionLinkWidth(0:(size(RegionDataPair,1) - 1), LinkSize);
        end
        % Update figure value
        setappdata(hFig, 'RegionDataPair', RegionDataPair);
        setappdata(hFig, 'RegionFunction', RegionFunction);
        % Update color map
        UpdateColormap(hFig);
    end
end

% Performs a reselection of currently selected nodes
function RefreshDisplay(hFig)
    % Get selected node
    selNodes = getappdata(hFig, 'SelectedNodes');
    % Erase selected node
    SetSelectedNodes(hFig, selNodes, 0, 1);
    % Redraw selected nodes
    SetSelectedNodes(hFig, selNodes, 1, 1);
end

function ToggleMeasureToRegionDisplay(hFig)
    DisplayInRegion = getappdata(hFig, 'DisplayInRegion');
    if (DisplayInRegion)
        % Toggle visibility
        MeasureLinksIsVisible = getappdata(hFig, 'MeasureLinksIsVisible');
        if (MeasureLinksIsVisible)
            MeasureLinksIsVisible = 0;
            RegionLinksIsVisible = 1;
        else
            MeasureLinksIsVisible = 1;
            RegionLinksIsVisible = 0;
        end
        % Get selected node
        selNodes = getappdata(hFig, 'SelectedNodes');
        % Erase selected node
        SetSelectedNodes(hFig, selNodes, 0, 1);
        % Update visibility variable
        setappdata(hFig, 'MeasureLinksIsVisible', MeasureLinksIsVisible);
        setappdata(hFig, 'RegionLinksIsVisible', RegionLinksIsVisible);
        % Redraw selected nodes
        SetSelectedNodes(hFig, selNodes, 1, 1);
    else
        disp('Current data does not support region display.');
    end
end


%% ===== DISPLAY MODE =====
function SetTextDisplayMode(hFig, DisplayMode)
    % Get current display
    TextDisplayMode = getappdata(hFig, 'TextDisplayMode');
    % If not already set
    Index = ismember(TextDisplayMode, DisplayMode);
    if (sum(Index) == 0)
        % 'Selection' mode and the others are mutually exclusive
        if (DisplayMode == 3)
            TextDisplayMode = DisplayMode;
        else
            TextDisplayMode = [TextDisplayMode DisplayMode];
            % Remove 'Selection' mode if necessary
            SelectionModeIndex = ismember(TextDisplayMode,3);
            if (sum(SelectionModeIndex) >= 1)
                TextDisplayMode(SelectionModeIndex) = [];
            end
        end
    else
        TextDisplayMode(Index) = [];
    end
    % Add display mode
    setappdata(hFig, 'TextDisplayMode', TextDisplayMode);
    % Refresh
    RefreshTextDisplay(hFig);
end

function ToggleTextDisplayMode(hFig)
    % Get display mode
    TextDisplayMode = getappdata(hFig, 'TextDisplayMode');
    if (TextDisplayMode == 1)
        TextDisplayMode = [TextDisplayMode 2];
    else
        TextDisplayMode = 1;
    end
    % Add display mode
    setappdata(hFig, 'TextDisplayMode', TextDisplayMode);
    % Refresh
    RefreshTextDisplay(hFig);
end

%% ===== BLENDING =====
% Blending functions has defined by OpenGL
% GL_SRC_COLOR = 768;
% GL_ONE_MINUS_SRC_COLOR = 769;
% GL_SRC_ALPHA = 770;
% GL_ONE_MINUS_SRC_ALPHA = 771;
% GL_ONE_MINUS_DST_COLOR = 775;
% GL_ONE = 1;
% GL_ZERO = 0;

function SetBlendingMode(hFig, BlendingEnabled)
    % Update figure variable
    setappdata(hFig, 'BlendingEnabled', BlendingEnabled);
    % Update display
    OGL = getappdata(hFig,'OpenGLDisplay');
    % 
    if BlendingEnabled
        % Good looking additive blending
        OGL.setMeasureLinkBlendingFunction(770,1);
        % Blending only works nicely on black background
        SetBackgroundColor(hFig, [0 0 0], [1 1 1]);
        % AND with a minimum amount of transparency
        LinkTransparency = GetLinkTransparency(hFig);
        if (LinkTransparency == 0)
            SetLinkTransparency(hFig, 0.02);
        end
    else
        % Translucent blending only
        OGL.setMeasureLinkBlendingFunction(770,771);
    end
    % Request redraw
    OGL.repaint();
end

function ToggleBlendingMode(hFig)
    BlendingEnabled = getappdata(hFig, 'BlendingEnabled');
    if isempty(BlendingEnabled)
        BlendingEnabled = 0;
    end
    SetBlendingMode(hFig, 1 - BlendingEnabled);
end

%% ===== LINK SIZE =====
function LinkSize = GetLinkSize(hFig)
    LinkSize = getappdata(hFig, 'LinkSize');
    if isempty(LinkSize)
        LinkSize = 1;
    end
end

function SetLinkSize(hFig, LinkSize)
    % Get display
    OGL = getappdata(hFig,'OpenGLDisplay');
    % Get # of data to update
    nLinks = size(getappdata(hFig, 'DataPair'), 1);
    % Update size
    OGL.setMeasureLinkWidth(0:(nLinks - 1), LinkSize);
    OGL.repaint();
    % 
    setappdata(hFig, 'LinkSize', LinkSize);
end

%% ===== LINK TRANSPARENCY =====
function LinkTransparency = GetLinkTransparency(hFig)
    LinkTransparency = getappdata(hFig, 'LinkTransparency');
    if isempty(LinkTransparency)
        LinkTransparency = 0.9;
    end
end

function SetLinkTransparency(hFig, LinkTransparency)
    % Get display
    OGL = getappdata(hFig,'OpenGLDisplay');
    % 
    nLinks = size(getappdata(hFig, 'DataPair'),1);
    % 
    OGL.setMeasureLinkTransparency(0:(nLinks - 1), LinkTransparency);
    OGL.repaint();
    % 
    setappdata(hFig, 'LinkTransparency', LinkTransparency);
end

%% ===== CORTEX TRANSPARENCY =====
function CortexTransparency = GetCortexTransparency(hFig)
    CortexTransparency = getappdata(hFig, 'CortexTransparency');
    if isempty(CortexTransparency)
        CortexTransparency = 0.025;
    end
end

function SetCortexTransparency(hFig, CortexTransparency)
    %
    is3DDisplay = getappdata(hFig, 'is3DDisplay');
    if is3DDisplay
        % Get display
        OGL = getappdata(hFig,'OpenGLDisplay');
        % 
        OGL.setPolygonTransparency(0, CortexTransparency);
        OGL.repaint();
    end
    % 
    setappdata(hFig, 'CortexTransparency', CortexTransparency);
end

%% ===== BACKGROUND COLOR =====
function SetBackgroundColor(hFig, BackgroundColor, TextColor)
    % Negate text color if necessary
    if nargin < 3
        TextColor = ~BackgroundColor;
    end
    % Get display
    OGL = getappdata(hFig,'OpenGLDisplay');
    % Update Java background color
    OGL.setClearColor(BackgroundColor(1), BackgroundColor(2), BackgroundColor(3), 0);
    % Update Matlab background color
    set(hFig, 'Color', BackgroundColor)
    % === BLENDING ===
    % Ensures that if background is white no blending is on.
    % Blending is additive and therefore won't be visible.
    if all(BackgroundColor == [1 1 1])
        SetBlendingMode(hFig, 0);
    end
    
    % === UPDATE TEXT COLOR ===
    FigureHasText = getappdata(hFig, 'FigureHasText');
    if FigureHasText
        % Agregating node text
        AgregatingNodes = getappdata(hFig, 'AgregatingNodes');
        if ~isempty(AgregatingNodes)
            OGL.setTextColor(AgregatingNodes - 1, TextColor(1), TextColor(2), TextColor(3));
        end
        % Measure node text
        MeasureNodes = getappdata(hFig, 'MeasureNodes');
        if ~isempty(MeasureNodes)
            OGL.setTextColor(MeasureNodes - 1, TextColor(1), TextColor(2), TextColor(3));
        end
    end
    
    % === 3D POLYGON ===
    is3DDisplay = getappdata(hFig, 'is3DDisplay');
    if is3DDisplay
        OGL.setPolygonColor(0, TextColor(1), TextColor(2), TextColor(3));
    end
    % Update
    OGL.repaint();
    % 
    setappdata(hFig, 'BgColor', BackgroundColor);
    %
    UpdateContainer(hFig, []);
end

function ToggleBackground(hFig)
    % 
    BackgroundColor = getappdata(hFig, 'BgColor');
    if all(BackgroundColor == [1 1 1])
        BackgroundColor = [0 0 0];
    else
        BackgroundColor = [1 1 1];
    end
    TextColor = ~BackgroundColor;
    SetBackgroundColor(hFig, BackgroundColor, TextColor)
end

%%
function SetIsBinaryData(hFig, IsBinaryData)
    % Update variable
    setappdata(hFig, 'IsBinaryData', IsBinaryData);
    setappdata(hFig, 'UserSpecifiedBinaryData', 1);
    % Update colormap
    UpdateColormap(hFig);
end

function ToggleDisplayMode(hFig)
    % Get display mode
    DisplayOutwardMeasure = getappdata(hFig, 'DisplayOutwardMeasure');
    DisplayInwardMeasure = getappdata(hFig, 'DisplayInwardMeasure');
    % Toggle value
    if (DisplayInwardMeasure == 0 && DisplayOutwardMeasure == 0)
        DisplayOutwardMeasure = 1;
        DisplayInwardMeasure = 1;
        DisplayBidirectionalMeasure = 0;
    elseif (DisplayInwardMeasure == 0 && DisplayOutwardMeasure == 1)
        DisplayOutwardMeasure = 0;
        DisplayInwardMeasure = 1;
        DisplayBidirectionalMeasure = 0;
    elseif (DisplayInwardMeasure == 1 && DisplayOutwardMeasure == 0)
        DisplayOutwardMeasure = 1;
        DisplayInwardMeasure = 1;
        DisplayBidirectionalMeasure = 1;
    else
        DisplayOutwardMeasure = 0;
        DisplayInwardMeasure = 0;
        DisplayBidirectionalMeasure = 1;
    end
    % Update display
    setDisplayMeasureMode(DisplayOutwardMeasure, DisplayInwardMeasure, DisplayBidirectionalMeasure);
    % UI refresh candy
    RefreshBinaryStatus(hFig);
end

function setDisplayMeasureMode(hFig, DisplayOutwardMeasure, DisplayInwardMeasure, DisplayBidirectionalMeasure, Refresh)
    if (nargin < 5)
        Refresh = 1;
    end
    % Get selected rows
    selNodes = getappdata(hFig, 'SelectedNodes');
    if (Refresh)
        % Remove previous links
        SetSelectedNodes(hFig, selNodes, 0, 0);
    end
    % Update display mode
    setappdata(hFig, 'DisplayOutwardMeasure', DisplayOutwardMeasure);
    setappdata(hFig, 'DisplayInwardMeasure', DisplayInwardMeasure);
    setappdata(hFig, 'DisplayBidirectionalMeasure', DisplayBidirectionalMeasure);
    % ----- User convenience code -----
    RefreshBinaryStatus(hFig);
    if (Refresh)
        % Redraw selected nodes
        SetSelectedNodes(hFig, selNodes, 1, 1);
    end
end

function RefreshBinaryStatus(hFig)
    IsBinaryData = getappdata(hFig, 'IsBinaryData');
    DisplayOutwardMeasure = getappdata(hFig, 'DisplayOutwardMeasure');
    DisplayInwardMeasure = getappdata(hFig, 'DisplayInwardMeasure');
    DisplayBidirectionalMeasure = getappdata(hFig, 'DisplayBidirectionalMeasure');
    if (DisplayInwardMeasure && DisplayOutwardMeasure)
        IsBinaryData = 1;
    elseif (DisplayInwardMeasure || DisplayOutwardMeasure)
        IsBinaryData = 0;
        selNodes = getappdata(hFig, 'SelectedNodes');
        Nodes = getappdata(hFig, 'MeasureNodes');
        nSelectedMeasureNodes = sum(ismember(Nodes, selNodes));
        if (length(Nodes) == nSelectedMeasureNodes);
            IsBinaryData = 1;
        end
    elseif (DisplayBidirectionalMeasure)
        IsBinaryData = 1;
    end
    curBinaryData = getappdata(hFig, 'IsBinaryData');
    if (IsBinaryData ~= curBinaryData)
        setappdata(hFig, 'IsBinaryData', IsBinaryData);
        % Update colormap
        UpdateColormap(hFig);
    end
    setappdata(hFig, 'UserSpecifiedBinaryData', 0);
end

% ===== REFRESH TEXT VISIBILITY =====
function RefreshTextDisplay(hFig, isRedraw)
    % 
    FigureHasText = getappdata(hFig, 'FigureHasText');
    if FigureHasText
        % 
        if nargin < 2
            isRedraw = 1;
        end
        % 
        AgregatingNodes = getappdata(hFig, 'AgregatingNodes');
        MeasureNodes = getappdata(hFig, 'MeasureNodes');
        ValidNode = getappdata(hFig, 'ValidNode');
        %
        nVertices = size(AgregatingNodes,2) + size(MeasureNodes,2);
        VisibleText = zeros(nVertices,1);
        %
        TextDisplayMode = getappdata(hFig, 'TextDisplayMode');
        if ismember(1,TextDisplayMode)
            VisibleText(MeasureNodes) = ValidNode(MeasureNodes);
        end
        if ismember(2,TextDisplayMode)
            VisibleText(AgregatingNodes) = ValidNode(AgregatingNodes);
        end
        if ismember(3,TextDisplayMode)
            selNodes = getappdata(hFig, 'SelectedNodes');
            VisibleText(selNodes) = ValidNode(selNodes);
        end
        InvisibleText = ~VisibleText;
        % OpenGL Handle
        OGL = getappdata(hFig, 'OpenGLDisplay');
        % Update text visibility
        if (sum(VisibleText) > 0)
            OGL.setTextVisible(find(VisibleText) - 1, 1.0);
        end
        if (sum(InvisibleText) > 0)
            OGL.setTextVisible(find(InvisibleText) - 1, 0.0);
        end
        % Refresh
        if (isRedraw)
            OGL.repaint();
        end
    end
end


%% ===== SET DATA THRESHOLD =====
function SetDataThreshold(hFig, DataThreshold) %#ok<DEFNU>
    % Get selected rows
    selNodes = getappdata(hFig, 'SelectedNodes');
    % Remove previous links
    SetSelectedNodes(hFig, selNodes, 0, 0);
    % Update threshold
    setappdata(hFig, 'DataThreshold', DataThreshold);
    % Redraw selected nodes
    SetSelectedNodes(hFig, selNodes, 1, 1);
end


%% ===== UTILITY FUNCTIONS =====
function NodeIndex = getAgregatedNodesFrom(hFig, AgregatingNodeIndex)
    NodeIndex = [];
    AgregatingNodes = getappdata(hFig, 'AgregatingNodes');
    if ismember(AgregatingNodeIndex,AgregatingNodes)
        NodePaths = getappdata(hFig, 'NodePaths');
        member = cellfun(@(x) ismember(AgregatingNodeIndex,x), NodePaths);
        NodeIndex = find(member == 1);
    end
end


%% ===== COMPUTING LINK PATH =====
function MeasureLinks = BuildRegionPath(hFig, mPaths, mDataPair)
    % Init return variable
    MeasureLinks = [];
    if isempty(mDataPair)
        return;
    end
    % 
    nPairs = size(mDataPair,1);
    if (nPairs > 0)
        % Define path to center as defined by the hierarchy
        ToCenter = mPaths(mDataPair(:,1));
        ToDestination = cellfun(@(x) x(end-1:-1:1), mPaths(mDataPair(:,2)), 'UniformOutput', 0);
        % Concat 
        MeasureLinks = cellfun(@(x,y) cat(2, x, y), ToCenter, ToDestination, 'UniformOutput', 0);
        % Level specific display
        NumberOfLevels = getappdata(hFig, 'NumberOfLevels'); 
        if (NumberOfLevels > 2)
            % Retrieve channel hierarchy
            ChannelData = getappdata(hFig, 'ChannelData');
            % 
            if (~isempty(ChannelData))
                SameRegion = ChannelData(mDataPair(1:end,1),1) == ChannelData(mDataPair(1:end,2),1);
                MeasureLinks(SameRegion) = cellfun(@(x,y) cat(2, x(1:2), y(end)), ToCenter(SameRegion), ToDestination(SameRegion), 'UniformOutput', 0);
                % 
                if (NumberOfLevels > 3)
                    % 
                    SameHemisphere = ChannelData(mDataPair(1:end,1),3) == ChannelData(mDataPair(1:end,2),3);
                    SameLobe = ChannelData(mDataPair(1:end,1),2) == ChannelData(mDataPair(1:end,2),2);
                    % Remove hierarchy based duplicate
                    SameLobe = SameLobe == 1 & SameRegion == 0 & SameHemisphere == 1;
                    SameHemisphere = SameHemisphere == 1 & SameRegion == 0 & SameLobe == 0;
                    %
                    MeasureLinks(SameLobe) = cellfun(@(x,y) cat(2, x(1:2), y(end-1:end)), ToCenter(SameLobe), ToDestination(SameLobe), 'UniformOutput', 0);
                    MeasureLinks(SameHemisphere) = cellfun(@(x,y) cat(2, x(1:3), y(end-2:end)), ToCenter(SameHemisphere), ToDestination(SameHemisphere), 'UniformOutput', 0);
                end
            end
        end
    end
end

function MeasureLinks = BuildRegionPath3D(hFig, mPaths, mDataPair, mLoc)
    % Init return variable
    MeasureLinks = [];
    if isempty(mDataPair)
        return;
    end
    % 
    if (size(mDataPair, 1) > 0)
        % Define path to center as defined by the hierarchy
        ToCenter = mPaths(mDataPair(:,1));        
        ToDestination = cellfun(@(x) flipdim(x,2), mPaths(mDataPair(:,2)), 'UniformOutput', 0);
        % Use path based on connectivity map
        ANCMap = getappdata(hFig, 'AgregatingNodeConnectMap');
        % 
        MeasureLinks = cellfun(@(x,y) [x(1) ANCMap{x(2),y(end-1)} y(end)], ToCenter, ToDestination, 'UniformOutput', 0);
    end
end

% Note: This code should only be called from the console
%       to provide the code line seen in ComputeSpline.
%       Since the weights values used by the spline are static
%       according to the defined level detail and order of the function,
%       we can precompute it to decrease the loading time
function Code = GenerateWeightsCode()
    LinkDetail = 20;
    Spread = linspace(0, 1, LinkDetail);
    Order = [3 4 5 6 7 8 9 10];
    Code = sprintf('WeightsPerOrder = {\n');
    for i=1:size(Order,2)
        Code = sprintf('%s {\n',Code);
        KnotsPerOrder = [zeros(1,Order(i)) 1 ones(1,Order(i))];
        for y=1:Order(i)
            Code = sprintf('%s    {[',Code);
            W = bspline_basis(y-1, Order(i), KnotsPerOrder, Spread);
            for z=1:size(W,2)
                Code = sprintf('%s %1.4f ',Code,W(z));
            end
            Code = sprintf('%s]}\n',Code);
        end
        Code = sprintf('%s}\n',Code);
    end
    Code = sprintf('%s}',Code);
end

function [aSplines] = ComputeSpline(hFig, MeasureLinks, Vertices)
    %
    aSplines = [];
    nMeasureLinks = size(MeasureLinks,1);
    if (nMeasureLinks > 0)
        % Define Spline Implementation details
        Order = [3 4 5 6 7 8 9 10];
        Weights = [
 {
    [ 1.0000  0.8975  0.8006  0.7091  0.6233  0.5429  0.4681  0.3989  0.3352  0.2770  0.2244  0.1773  0.1357  0.0997  0.0693  0.0443  0.0249  0.0111  0.0028  0.0000 ;
      0.0000  0.0997  0.1884  0.2659  0.3324  0.3878  0.4321  0.4654  0.4875  0.4986  0.4986  0.4875  0.4654  0.4321  0.3878  0.3324  0.2659  0.1884  0.0997  0.0000  ;
      0.0000  0.0028  0.0111  0.0249  0.0443  0.0693  0.0997  0.1357  0.1773  0.2244  0.2770  0.3352  0.3989  0.4681  0.5429  0.6233  0.7091  0.8006  0.8975  1.0000 ]'
}
 {
    [ 1.0000  0.8503  0.7163  0.5972  0.4921  0.4001  0.3203  0.2519  0.1941  0.1458  0.1063  0.0746  0.0500  0.0315  0.0182  0.0093  0.0039  0.0012  0.0001  0.0000 ;
      0.0000  0.1417  0.2528  0.3359  0.3936  0.4286  0.4435  0.4409  0.4234  0.3936  0.3543  0.3079  0.2572  0.2047  0.1531  0.1050  0.0630  0.0297  0.0079  0.0000 ;
      0.0000  0.0079  0.0297  0.0630  0.1050  0.1531  0.2047  0.2572  0.3079  0.3543  0.3936  0.4234  0.4409  0.4435  0.4286  0.3936  0.3359  0.2528  0.1417  0.0000 ;
      0.0000  0.0001  0.0012  0.0039  0.0093  0.0182  0.0315  0.0500  0.0746  0.1063  0.1458  0.1941  0.2519  0.3203  0.4001  0.4921  0.5972  0.7163  0.8503  1.0000 ]'
}
 {
    [ 1.0000  0.8055  0.6409  0.5029  0.3885  0.2948  0.2192  0.1591  0.1123  0.0767  0.0503  0.0314  0.0184  0.0099  0.0048  0.0020  0.0006  0.0001  0.0000  0.0000 ;
      0.0000  0.1790  0.3016  0.3772  0.4144  0.4211  0.4046  0.3713  0.3268  0.2762  0.2238  0.1729  0.1263  0.0862  0.0537  0.0295  0.0133  0.0042  0.0006  0.0000 ;
      0.0000  0.0149  0.0532  0.1061  0.1657  0.2256  0.2801  0.3249  0.3565  0.3729  0.3729  0.3565  0.3249  0.2801  0.2256  0.1657  0.1061  0.0532  0.0149  0.0000 ;
      0.0000  0.0006  0.0042  0.0133  0.0295  0.0537  0.0862  0.1263  0.1729  0.2238  0.2762  0.3268  0.3713  0.4046  0.4211  0.4144  0.3772  0.3016  0.1790  0.0000 ;
      0.0000  0.0000  0.0001  0.0006  0.0020  0.0048  0.0099  0.0184  0.0314  0.0503  0.0767  0.1123  0.1591  0.2192  0.2948  0.3885  0.5029  0.6409  0.8055  1.0000 ]'
}
 {
    [ 1.0000  0.7631  0.5734  0.4235  0.3067  0.2172  0.1500  0.1005  0.0650  0.0404  0.0238  0.0132  0.0068  0.0031  0.0013  0.0004  0.0001  0.0000  0.0000  0.0000 ;
      0.0000  0.2120  0.3373  0.3970  0.4089  0.3879  0.3460  0.2931  0.2365  0.1817  0.1325  0.0910  0.0582  0.0340  0.0177  0.0078  0.0026  0.0005  0.0000  0.0000 ;
      0.0000  0.0236  0.0794  0.1489  0.2181  0.2770  0.3194  0.3420  0.3440  0.3271  0.2944  0.2502  0.1995  0.1474  0.0989  0.0582  0.0279  0.0093  0.0013  0.0000 ;
      0.0000  0.0013  0.0093  0.0279  0.0582  0.0989  0.1474  0.1995  0.2502  0.2944  0.3271  0.3440  0.3420  0.3194  0.2770  0.2181  0.1489  0.0794  0.0236  0.0000 ;
      0.0000  0.0000  0.0005  0.0026  0.0078  0.0177  0.0340  0.0582  0.0910  0.1325  0.1817  0.2365  0.2931  0.3460  0.3879  0.4089  0.3970  0.3373  0.2120  0.0000 ;
      0.0000  0.0000  0.0000  0.0001  0.0004  0.0013  0.0031  0.0068  0.0132  0.0238  0.0404  0.0650  0.1005  0.1500  0.2172  0.3067  0.4235  0.5734  0.7631  1.0000 ]'
}
 {
    [ 1.0000  0.7230  0.5131  0.3566  0.2421  0.1600  0.1026  0.0635  0.0377  0.0213  0.0113  0.0056  0.0025  0.0010  0.0003  0.0001  0.0000  0.0000  0.0000  0.0000 ;
      0.0000  0.2410  0.3622  0.4012  0.3874  0.3430  0.2841  0.2221  0.1643  0.1148  0.0753  0.0460  0.0257  0.0129  0.0056  0.0020  0.0005  0.0001  0.0000  0.0000 ;
      0.0000  0.0335  0.1065  0.1881  0.2583  0.3062  0.3278  0.3240  0.2988  0.2583  0.2092  0.1580  0.1102  0.0698  0.0391  0.0184  0.0066  0.0015  0.0001  0.0000 ;
      0.0000  0.0025  0.0167  0.0470  0.0918  0.1458  0.2017  0.2520  0.2897  0.3099  0.3099  0.2897  0.2520  0.2017  0.1458  0.0918  0.0470  0.0167  0.0025  0.0000 ;
      0.0000  0.0001  0.0015  0.0066  0.0184  0.0391  0.0698  0.1102  0.1580  0.2092  0.2583  0.2988  0.3240  0.3278  0.3062  0.2583  0.1881  0.1065  0.0335  0.0000 ;
      0.0000  0.0000  0.0001  0.0005  0.0020  0.0056  0.0129  0.0257  0.0460  0.0753  0.1148  0.1643  0.2221  0.2841  0.3430  0.3874  0.4012  0.3622  0.2410  0.0000 ;
      0.0000  0.0000  0.0000  0.0000  0.0001  0.0003  0.0010  0.0025  0.0056  0.0113  0.0213  0.0377  0.0635  0.1026  0.1600  0.2421  0.3566  0.5131  0.7230  1.0000 ]'
}
 {
    [ 1.0000  0.6849  0.4591  0.3003  0.1911  0.1179  0.0702  0.0401  0.0218  0.0112  0.0054  0.0023  0.0009  0.0003  0.0001  0.0000  0.0000  0.0000  0.0000  0.0000 ;
      0.0000  0.2664  0.3780  0.3942  0.3568  0.2948  0.2268  0.1637  0.1110  0.0705  0.0416  0.0226  0.0111  0.0047  0.0017  0.0005  0.0001  0.0000  0.0000  0.0000 ;
      0.0000  0.0444  0.1334  0.2217  0.2854  0.3159  0.3140  0.2864  0.2422  0.1903  0.1387  0.0931  0.0569  0.0309  0.0144  0.0054  0.0015  0.0002  0.0000  0.0000 ;
      0.0000  0.0041  0.0262  0.0693  0.1269  0.1880  0.2416  0.2785  0.2935  0.2854  0.2569  0.2135  0.1625  0.1115  0.0672  0.0338  0.0130  0.0031  0.0002  0.0000 ;
      0.0000  0.0002  0.0031  0.0130  0.0338  0.0672  0.1115  0.1625  0.2135  0.2569  0.2854  0.2935  0.2785  0.2416  0.1880  0.1269  0.0693  0.0262  0.0041  0.0000 ;
      0.0000  0.0000  0.0002  0.0015  0.0054  0.0144  0.0309  0.0569  0.0931  0.1387  0.1903  0.2422  0.2864  0.3140  0.3159  0.2854  0.2217  0.1334  0.0444  0.0000 ;
      0.0000  0.0000  0.0000  0.0001  0.0005  0.0017  0.0047  0.0111  0.0226  0.0416  0.0705  0.1110  0.1637  0.2268  0.2948  0.3568  0.3942  0.3780  0.2664  0.0000 ;
      0.0000  0.0000  0.0000  0.0000  0.0000  0.0001  0.0003  0.0009  0.0023  0.0054  0.0112  0.0218  0.0401  0.0702  0.1179  0.1911  0.3003  0.4591  0.6849  1.0000 ]'
}
 {
    [ 1.0000  0.6489  0.4107  0.2529  0.1509  0.0869  0.0480  0.0253  0.0126  0.0059  0.0025  0.0010  0.0003  0.0001  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000 ;
      0.0000  0.2884  0.3866  0.3793  0.3219  0.2483  0.1773  0.1181  0.0734  0.0424  0.0225  0.0109  0.0047  0.0017  0.0005  0.0001  0.0000  0.0000  0.0000  0.0000 ;
      0.0000  0.0561  0.1592  0.2489  0.3005  0.3103  0.2865  0.2412  0.1869  0.1335  0.0876  0.0523  0.0279  0.0130  0.0050  0.0015  0.0003  0.0000  0.0000  0.0000 ;
      0.0000  0.0062  0.0375  0.0934  0.1602  0.2217  0.2644  0.2814  0.2719  0.2404  0.1947  0.1438  0.0958  0.0563  0.0283  0.0114  0.0033  0.0005  0.0000  0.0000 ;
      0.0000  0.0004  0.0055  0.0219  0.0534  0.0990  0.1526  0.2052  0.2472  0.2704  0.2704  0.2472  0.2052  0.1526  0.0990  0.0534  0.0219  0.0055  0.0004  0.0000 ;
      0.0000  0.0000  0.0005  0.0033  0.0114  0.0283  0.0563  0.0958  0.1438  0.1947  0.2404  0.2719  0.2814  0.2644  0.2217  0.1602  0.0934  0.0375  0.0062  0.0000 ;
      0.0000  0.0000  0.0000  0.0003  0.0015  0.0050  0.0130  0.0279  0.0523  0.0876  0.1335  0.1869  0.2412  0.2865  0.3103  0.3005  0.2489  0.1592  0.0561  0.0000 ;
      0.0000  0.0000  0.0000  0.0000  0.0001  0.0005  0.0017  0.0047  0.0109  0.0225  0.0424  0.0734  0.1181  0.1773  0.2483  0.3219  0.3793  0.3866  0.2884  0.0000 ;
      0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0001  0.0003  0.0010  0.0025  0.0059  0.0126  0.0253  0.0480  0.0869  0.1509  0.2529  0.4107  0.6489  1.0000 ]'
}
 {
    [ 1.0000  0.6147  0.3675  0.2130  0.1191  0.0640  0.0329  0.0160  0.0073  0.0031  0.0012  0.0004  0.0001  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000 ;
      0.0000  0.3074  0.3891  0.3594  0.2859  0.2058  0.1365  0.0839  0.0478  0.0251  0.0120  0.0051  0.0019  0.0006  0.0002  0.0000  0.0000  0.0000  0.0000  0.0000 ;
      0.0000  0.0683  0.1831  0.2695  0.3050  0.2940  0.2520  0.1959  0.1391  0.0904  0.0534  0.0283  0.0132  0.0053  0.0017  0.0004  0.0001  0.0000  0.0000  0.0000 ;
      0.0000  0.0089  0.0503  0.1179  0.1898  0.2450  0.2714  0.2666  0.2361  0.1898  0.1383  0.0908  0.0529  0.0267  0.0112  0.0036  0.0008  0.0001  0.0000  0.0000 ;
      0.0000  0.0007  0.0089  0.0332  0.0759  0.1313  0.1879  0.2333  0.2576  0.2562  0.2306  0.1873  0.1361  0.0867  0.0469  0.0202  0.0062  0.0010  0.0000  0.0000 ;
      0.0000  0.0000  0.0010  0.0062  0.0202  0.0469  0.0867  0.1361  0.1873  0.2306  0.2562  0.2576  0.2333  0.1879  0.1313  0.0759  0.0332  0.0089  0.0007  0.0000 ;
      0.0000  0.0000  0.0001  0.0008  0.0036  0.0112  0.0267  0.0529  0.0908  0.1383  0.1898  0.2361  0.2666  0.2714  0.2450  0.1898  0.1179  0.0503  0.0089  0.0000 ;
      0.0000  0.0000  0.0000  0.0001  0.0004  0.0017  0.0053  0.0132  0.0283  0.0534  0.0904  0.1391  0.1959  0.2520  0.2940  0.3050  0.2695  0.1831  0.0683  0.0000 ;
      0.0000  0.0000  0.0000  0.0000  0.0000  0.0002  0.0006  0.0019  0.0051  0.0120  0.0251  0.0478  0.0839  0.1365  0.2058  0.2859  0.3594  0.3891  0.3074  0.0000 ;
      0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0000  0.0001  0.0004  0.0012  0.0031  0.0073  0.0160  0.0329  0.0640  0.1191  0.2130  0.3675  0.6147  1.0000 ]'
}
];
        LinkDetail = 20;
        Spread = linspace(0,1,LinkDetail);
        % Bundling factor
        Bundling = 0.9;
        
        is3DDisplay = getappdata(hFig, 'is3DDisplay');
        if (is3DDisplay)
            % Compute weights
            Order = [1 2 3 4 5 6 7 8 9 10];
            Weights = cell(10,1);
            for i=3:10
                n = i - 1;
                t = [0 0 0:1/(n-1):1 1 1];
                Weights{i} = bspline_basismatrix(3, t, Spread);
            end
            Bundling = 0.95;
        end
        
        % Compute spline for each MeasureLinks
        MaxDist = max(max(Vertices(:,:))) * 2;
        aSplines = zeros(nMeasureLinks * 8 * 10 * 3,1);
        
        Index = 1;
        for i=1:nMeasureLinks
            % Link
            Link = MeasureLinks{i};
            % Number of control points (CP)
            nFrames = size(Link,2);
            % Get the positions of CP
            Frames = Vertices(Link(:),:);
            % Last minute display candy
            if (nFrames == 3)
                % We assume that 3 frames are nodes near each others
                % and force an arc between the nodes
                Dist = sqrt(sum(abs(Frames(end,:) - Frames(1,:)).^2));
                Dist = abs(0.9 - Dist / MaxDist);
                Middle = (Frames(1,:) + Frames(end,:)) / 2;
                Frames(2,:) = Middle * Dist;
            end
            % 
            if (nFrames == 2)
                aSplines(Index) = 2;
                aSplines(Index+1:Index + 2 * 3) = reshape(Frames(1:2,:)',[],1);
                Index = Index + 2 * 3 + 1;
            else
                % Bundling property (Higher beta very bundled)
                % Beta = 0.7 + 0.2 * sin(0:pi/(nFrames-1):pi);
                Beta = Bundling * ones(1,nFrames);
                
                % Prototype: Corpus Callosum influence
                % N = nFrames;
                % t = 0:1/(N-1):1;
                % Beta = Bundling + 0.1 * cos((2 * pi) / (N / 2) * (t * N));
                
                for y=2:nFrames-1
                    Frames(y,:) = Beta(y) * Frames(y,:) + (1 - Beta(y)) * (Frames(1,:) + y / (nFrames - 1) * (Frames(end,:) - Frames(1,:)));
                end
                %
                W = Weights{Order == nFrames};
                % 
                Spline = W * Frames;
                % Specifiy link length for Java
                aSplines(Index) = LinkDetail;
                % Assign spline vertices in a one dimension structure
                aSplines(Index+1:Index + (LinkDetail) * 3) = reshape(Spline',[],1);
                % Update index
                Index = Index + (LinkDetail) * 3 + 1;
            end
        end
        % Truncate unused data
        aSplines = aSplines(1:Index-1);
    end
end

function [B,x] = bspline_basismatrix(n,t,x)
    if nargin > 2
        B = zeros(numel(x),numel(t)-n);
        for j = 0 : numel(t)-n-1
            B(:,j+1) = bspline_basis(j,n,t,x);
        end
    else
        [b,x] = bspline_basis(0,n,t);
        B = zeros(numel(x),numel(t)-n);
        B(:,1) = b;
        for j = 1 : numel(t)-n-1
            B(:,j+1) = bspline_basis(j,n,t,x);
        end
    end
end


% This code is the original ComputeSpline without the precomputed
% weight values. This function could be used if we want to user a higher 
% degree of details (LinkDetail) or add a order degree (LongerLinks).
%
% function [aSplines] = OldComputeSpline(hFig, MeasureLinks, Vertices)
%     %
%     aSplines = [];
%     nMeasureLinks = size(MeasureLinks,1);
%     if (nMeasureLinks > 0)
%         % Define Spline Implementation details
%         LinkDetail = 20;
%         Spread = linspace(0, 1, LinkDetail);
%         Order = [3 4 5 6 7 8 9 10];
%         KnotsPerOrder = cell(size(Order,2),1);
%         WeightsPerOrder = cell(size(Order,2),1);
%         for i=1:size(Order,2)
%             KnotsPerOrder(i) = {[zeros(1,Order(i)) 1 ones(1,Order(i))]};
%             Weights = cell(Order(i),1);
%             for y=1:Order(i)
%                 Weights(y) = {bspline_basis(y-1, Order(i), KnotsPerOrder{i}, Spread)};
%             end
%             
%             WeightsPerOrder(i) = {Weights};
%         end
%         % Compute spline for each MeasureLinks
%         MaxDist = max(max(Vertices(:,:))) * 2;
%         Index = 1;
%         aSplines = zeros(nMeasureLinks * 8 * 10 * 3,1);
%         for i=1:nMeasureLinks
%             % Link
%             Link = MeasureLinks{i};
%             % Number of control points (CP)
%             nFrames = size(Link,2);
%             % Get the positions of CP
%             Frames = Vertices(Link(:),:);
%             % Last minute display candy
%             if (nFrames == 3)
%                 % Simple arc for same region nodes
%                 Dist = sqrt(sum(abs(Frames(end,:) - Frames(1,:)).^2));
%                 Dist = abs(0.9 - Dist / MaxDist);
%                 Middle = (Frames(1,:) + Frames(end,:)) / 2;
%                 Frames(2,:) = Middle * Dist;
%             end
%             
%             if (nFrames == 2)
%                 aSplines(Index) = 2;
%                 aSplines(Index+1:Index + 2 * 3) = reshape(Frames(1:2,:)',[],1);
%                 Index = Index + 2 * 3 + 1;
%             else
%                 % Retrieve proper weight for spline
%                 Weights = WeightsPerOrder{Order == nFrames};
%                 Spline = zeros(3,LinkDetail);
%                 for y=1:nFrames
%                     W = Weights{y};
%                     Spline(:,:) = Spline(:,:) + bsxfun(@times, W, Frames(y,:)');
%                 end            
%                 % Specifiy link length for Java
%                 aSplines(Index) = LinkDetail;
%                 % Assign spline vertices in a one dimension structure
%                 aSplines(Index+1:Index + (LinkDetail) * 3) = reshape(Spline,[],1);
%                 % Update index
%                 Index = Index + (LinkDetail) * 3 + 1;
%             end
%         end
%         % Truncate unused data
%         aSplines = aSplines(1:Index-1);
%     end
% end


%% ===== ADD NODES TO JAVA ENGINE =====
function ClearAndAddChannelsNode(hFig, V, Names)
    % Get OpenGL handle
    OGL = getappdata(hFig, 'OpenGLDisplay');
    MeasureNodes = getappdata(hFig, 'MeasureNodes');
    AgregatingNodes = getappdata(hFig, 'AgregatingNodes');
    DisplayedNodes = find(getappdata(hFig, 'ValidNode'));
    DisplayedMeasureNodes = MeasureNodes(ismember(MeasureNodes,DisplayedNodes));
    NumberOfMeasureNode = length(DisplayedMeasureNodes);
    nAgregatingNodes = length(AgregatingNodes);
    
    % Is display in 3D ?
    is3DDisplay = getappdata(hFig, 'is3DDisplay');
    if isempty(is3DDisplay)
        is3DDisplay = 0;
    end
    
    % @TODO: If the number of node is greater than a certain number
    % our current Java engine might not run smoothly for that many text
    FigureHasText = NumberOfMeasureNode <= 500;
    setappdata(hFig, 'FigureHasText', FigureHasText);
    
    % Default link size
    LinkSize = GetLinkSize(hFig);
    % Default radial display option
    RadialTextDisplay = 0;
    % Default node size
    NodeSize = 0;
    % Default text size
    TextSize = 0.005;
    % Default text distance from node
    TextDistanceFromNode = 1;
    
    if ~is3DDisplay
        %
        NodeSize = 30 / NumberOfMeasureNode * 0.25;
        % Small number of node have different hardcoded values
        if (NumberOfMeasureNode <= 20)
            NodeSize = 0.25;
            % For very long text, radial display are much nicer
            MaxLabelLength = max(cellfun(@(x) size(x,2), Names));
            if (MaxLabelLength > 10)
                RadialTextDisplay = 1;
            end
        else
            RadialTextDisplay = 1;
        end
        % Note: 1/20 is an arbitrarily defined ratio 
        %       to compensate for the high font resolution
        FontScalingRatio = 1 / 20;
        TextSize = 1.2 * NodeSize * FontScalingRatio;
        TextDistanceFromNode = NodeSize * 2.5;
        LinkSize = NodeSize * 20;
        if (LinkSize < 1)
            LinkSize = 1;
        end
    end
    RegionNodeSize = 0.5 * NodeSize;
    if (RegionNodeSize < 0.05)
        RegionNodeSize = 0.05;
    end
    RegionTextSize = TextSize;
    
    setappdata(hFig, 'NodeSize', NodeSize);
    setappdata(hFig, 'LinkSize', LinkSize);
    
    nVertices = size(V,1);

    OGL.addNode(V(:,1), V(:,2), V(:,3));
    % 
    OGL.setNodeInnerColor(0:(nVertices-1), 0.7, 0.7, 0.7);
    OGL.setNodeOuterColor(0:(nVertices-1), 0.5, 0.5, 0.5);
    OGL.setNodeOuterRadius(0:(nVertices-1), NodeSize);
    OGL.setNodeInnerRadius(0:(nVertices-1), 0.75 * NodeSize);
    OGL.setNodeOuterRadius(AgregatingNodes - 1, RegionNodeSize);
    OGL.setNodeInnerRadius(AgregatingNodes - 1, 0.75 * RegionNodeSize);
    
    % Node are color coded to their Scout counterpart
    RowColors = getappdata(hFig, 'RowColors');
    if ~isempty(RowColors)
        for i=1:length(RowColors)
            OGL.setNodeInnerColor(nAgregatingNodes+i-1, RowColors(i,1), RowColors(i,2), RowColors(i,3));
        end
    end
    
    Pos = V(:,1:3);
    if ~is3DDisplay
        Dir = bsxfun(@minus, V(:,1:3), [0 0 0]);
        Sum = sum(abs(Dir).^2,2).^(1/2);
        NonZero = Sum ~= 0;
        Dir(NonZero,:) = bsxfun(@rdivide, Dir(NonZero,:), Sum(NonZero));
        Pos(MeasureNodes,:) = V(MeasureNodes,1:3) + Dir(MeasureNodes,:) * TextDistanceFromNode;
    end
    
    % Middle axe used for text alignment
    Axe = [0 1 0];
    % For each node
    for i=1:nVertices
        % Blank name if none is assigned
        if (isempty(Names(i)) || isempty(Names{i}))
            Names{i} = '';
        end
        
        if (is3DDisplay)
            OGL.setNodeTransparency(i - 1, 1.00);
        else
            OGL.setNodeTransparency(i - 1, 0.01);
        end
        
        if (FigureHasText)
            % Assign name
            OGL.setNodeText(i-1, Names(i));
            % Text alignment code
            %   1: Left,
            %   2: Middle,
            %   3: Right
            if (i < nAgregatingNodes)
                % Region nodes are always middle aligned
                OGL.setTextAlignment(i-1, 2);
            else
                if (V(i,1) > 0)
                    % Right hemisphere
                    OGL.setTextAlignment(i-1, 1);
                else
                    % Left hemisphere
                    OGL.setTextAlignment(i-1, 3);
                end
            end
            
            if (RadialTextDisplay && i > nAgregatingNodes)
                % Find out the angle between the node vertex and the center
                theta = 0;
                Denom = (norm(Axe)*norm(Pos(i,:)));
                if (Denom ~= 0)
                    theta = acos(dot(Axe,Pos(i,:))/Denom);
                end
                % Right or Left
                if (V(i,1) > 0)
                    theta = -theta + 3.1415 / 2;
                else
                    theta = theta - 3.1415 / 2;
                end
                % Convert angle
                thetaDeg = (180 / pi) .* theta;
                OGL.setTextOrientation(i-1, thetaDeg);
            end
        end
    end
    
    if (FigureHasText)
        OGL.setTextSize(0:(nVertices-1), TextSize);
        OGL.setTextSize(AgregatingNodes - 1, RegionTextSize);
        OGL.setTextPosition(0:(nVertices-1), Pos(:,1), Pos(:,2), Pos(:,3));
        OGL.setTextTransparency(0:(nVertices-1), 0.0);
        OGL.setTextColor(0:(nVertices-1), 0.1, 0.1, 0.1);
        OGL.setTextVisible(0:(nVertices-1), 1.0);
        OGL.setTextVisible(AgregatingNodes - 1, 0);
    end
end


% function SetupRadialRegion(hFig, Vertices, sGroups, aNames, RowLocs)
%     % 
%     OGL = getappdata(hFig, 'OpenGLDisplay');
%     MeasureLevelDistance = getappdata(hFig, 'MeasureLevelDistance');
%     % 
%     MeasureNodes = getappdata(hFig, 'MeasureNodes');
%     AgregatingNodes = getappdata(hFig, 'AgregatingNodes');
%     NumberOfAgregatingNodes = size(AgregatingNodes,2);
%     nMeasureNodes = size(MeasureNodes,2);
%     % Common rendering parameters
%     rbLineDetail = 50;
%     rbVertexCount = rbLineDetail * 2;
%     rbIndices = zeros(rbVertexCount,1);
%     rbIndices(1:2:rbVertexCount) = 1:1:rbLineDetail;
% 	rbIndices(2:2:rbVertexCount) = (rbLineDetail+1):1:rbVertexCount;
%     rbIndices = rbIndices - 1;
%     % Selection data
%     NumberOfGroups = size(sGroups,2);
%     RadialRegionSelection = zeros(NumberOfGroups * 3,1);
%     RegionParameters = zeros(NumberOfGroups,2);
%     for i=1:NumberOfGroups
%         % Find which node and their Index
%         NodesOfThisGroup = ismember(aNames, sGroups(i).RowNames);
%         Index = find(NodesOfThisGroup) + NumberOfAgregatingNodes;
%         % Get vertices and sort Ant-Post
%         Order = 1:size(Index,1);
%         if ~isempty(RowLocs)
%             [tmp, Order] = sort(RowLocs(NodesOfThisGroup,1), 'descend');
%         end
%         NodesVertices = Vertices(Index(Order),:);
%         % 
%         RegionParameters(i,1) = VectorToAngle(NodesVertices(1,:) / norm(NodesVertices(1,:)));
%         RegionParameters(i,2) = VectorToAngle(NodesVertices(end,:) / norm(NodesVertices(end,:)));
%         % 1st to 4th Quadrant correction
%         if (RegionParameters(i,1) >= 0   && RegionParameters(i,1) <= 90 && ...
%             RegionParameters(i,2) >= 270 && RegionParameters(i,2) <= 360)  
%             RegionParameters(i,1) = 360 + RegionParameters(i,1);
%         end
%     end
% 
%     Parameters{1} = RegionParameters;
%     Lengths = [1.10 1.16];
%     
%     Parameter = Parameters{1};
%     nRadialBox = size(Parameter,1);
%     for i=1:nRadialBox
%         % 
%         StartAngle = Parameter(i,1);
%         EndAngle = Parameter(i,2);
%         % Compute cartesian
%         Interp = linspace(StartAngle, EndAngle, rbLineDetail);
%         [x,y] = pol2cart(deg2rad(Interp), MeasureLevelDistance);
%         % Assign
%         rbVertices = zeros(rbVertexCount,3);
%         rbVertices(1:(rbVertexCount/2),1:2) = Lengths(1,1) * [x' y'];
%         rbVertices((rbVertexCount/2+1):rbVertexCount,1:2) = Lengths(1,2) * [x' y'];
%         % 
%         OGL.addRadialBox(rbVertices(:,1), rbVertices(:,2), rbVertices(:,3), rbIndices(:));
%     end
%     
%     setappdata(hFig, 'RadialRegionSelection', RadialRegionSelection);
%     
%     %LeftHem = ChannelData(:,3) == 1;
%     %RightHem = ChannelData(:,3) == 2;
%     %if (nCerebellum > 0)
%     %    CereHem = ChannelData(:,2) == 4;
%     %    Vertices(CereHem,2) = Vertices(CereHem,2) * 1.2;
%     %end
%     %if (nUnkown > 0)
%     %    Unknown = ChannelData(:,3) == 0;
%     %    Vertices(Unknown,2) = Vertices(Unknown,2) * 1.2;
%     %end
%     
%     %Vertices(LeftHem,1) = Vertices(LeftHem,1) - 0.6;
%     %Vertices(LeftHem,2) = Vertices(LeftHem,2) * 1.2;
% 	%Vertices(RightHem,1) = Vertices(RightHem,1) + 0.6;
%     %Vertices(RightHem,2) = Vertices(RightHem,2) * 1.2;
% 
% end

% function Angle = VectorToAngle(Vector)
%     Reference = [1 0 0];
%     Angle = zeros(size(Vector,1),1);
%     for i=1:size(Vector,1)
%         Angle(i) = acosd(Vector(i,:) * Reference');
%         if (Vector(i,2) < 0 - 0.000001)
%             Angle(i) = 360 - Angle(i);
%         end
%     end
% end


function [Vertices Paths Names] = OrganiseChannelsIn3D(hFig, sGroups, aNames, aLocs, SurfaceStruct)
    % Some values are Hardcoded for Display consistency
    NumberOfMeasureNodes = size(aNames,1);
    NumberOfGroups = size(sGroups,2);
    NumberOfLobes = 7;
    NumberOfHemispheres = 4;
    NumberOfLevels = 5;
    
    [V H] = ComputeCortexPathBundle(SurfaceStruct);
    NumberOfAgregatingNodes = size(V,1);
    
    % Extract only the first region letter of each group
    HemisphereRegions = cellfun(@(x) {x(1)}, {sGroups.Region})';
    LobeRegions = cellfun(@(x) {LobeIndexToTag(LobeTagToIndex(x))}, {sGroups.Region})';
    
    LeftGroupsIndex = strcmp('L',HemisphereRegions) == 1;
    RightGroupsIndex = strcmp('R',HemisphereRegions) == 1;
    
    Lobes = [];
    NumberOfNodesPerLobe = zeros(NumberOfLobes * 2,1);
    for i=1:NumberOfLobes
        Tag = LobeIndexToTag(i);
        RegionsIndex = strcmp(Tag,LobeRegions) == 1;
        NodesInLeft = [sGroups(LeftGroupsIndex & RegionsIndex).RowNames];
        NodesInRight = [sGroups(RightGroupsIndex & RegionsIndex).RowNames];
        NumberOfNodesPerLobe(i) = size(NodesInLeft,2);
        NumberOfNodesPerLobe(NumberOfLobes + i) = size(NodesInRight,2);
        if (size(NodesInLeft,2) > 0 || size(NodesInRight,2) > 0)
            Lobes = [Lobes i];
        end
    end
    
    % Actual number of lobes with data
    NumberOfLobes = size(Lobes,2);    
    NumberOfVertices = NumberOfMeasureNodes + NumberOfAgregatingNodes;
    Vertices = zeros(NumberOfVertices,3);
    Names = cell(NumberOfVertices,1);
    Paths = cell(NumberOfVertices,1);
    ChannelData = zeros(NumberOfVertices,3);
    Levels = cell(3,1);
    
    AgregatingNodeIndex = NumberOfHemispheres;
    for z=1:NumberOfHemispheres
        HemisphereTag = HemisphereIndexToTag(z);
        HemisphereIndex = z;
        for i=1:NumberOfLobes
            LobeTag = LobeIndexToTag(Lobes(i));
            RegionMask = strcmp(LobeTag,LobeRegions) == 1 & strcmp(HemisphereTag,HemisphereRegions) == 1;
            NumberOfRegionInLobe = sum(RegionMask);
            if (NumberOfRegionInLobe > 0)
                AgregatingNodeIndex = AgregatingNodeIndex + 1;
                LobeIndex = AgregatingNodeIndex;
                RegionNodeIndex = find(RegionMask == 1);
                for y=1:NumberOfRegionInLobe
                    AgregatingNodeIndex = AgregatingNodeIndex + 1;
                    RegionIndex = AgregatingNodeIndex;
                    ChannelsOfThisGroup = ismember(aNames, sGroups(RegionNodeIndex(y)).RowNames);
                    Index = find(ChannelsOfThisGroup) + NumberOfAgregatingNodes;
                    Vertices(Index,1:3) = aLocs(ChannelsOfThisGroup, 1:3);
                    Names(Index) = aNames(ChannelsOfThisGroup);
                    ChannelData(Index,:) = repmat([RegionIndex LobeIndex HemisphereIndex], size(Index));
                end
            end
        end
    end
    
    VertexScale3D = getappdata(hFig, 'VertexScale3D');
    Centroid = getappdata(hFig, 'VertexInitCentroid');
    %Centroid = sum(Vertices) / size(Vertices,1);
    Vertices = Vertices - repmat(Centroid, size(Vertices,1), 1);
    Vertices = Vertices * VertexScale3D;
    
    m = size(Vertices,1);
    n = size(V,1);
    XX = sum(Vertices.*Vertices,2);
    YY = sum(V'.*V',1);
    D = XX(:,ones(1,n)) + YY(ones(1,m),:) - 2*Vertices*V';
    for i=NumberOfAgregatingNodes+1:NumberOfVertices
        Hemis = ChannelData(i,3);
        Valid = find(H == Hemis);
        [tmp, nearestNode] = min(D(i,Valid));
        nearestNode = Valid(nearestNode);
        Paths{i} = [i nearestNode];
    end
    
    Vertices(1:NumberOfAgregatingNodes,:) = V;
    
    setappdata(hFig, 'AgregatingNodes', 1:NumberOfAgregatingNodes);
    setappdata(hFig, 'MeasureNodes', (NumberOfAgregatingNodes + 1):(NumberOfAgregatingNodes + NumberOfMeasureNodes));
    setappdata(hFig, 'NumberOfLevels', NumberOfLevels);
    setappdata(hFig, 'Levels', Levels);
    setappdata(hFig, 'ChannelData', ChannelData);
end


function [V H] = ComputeCortexPathBundle(SurfaceStruct)

    Vertices = SurfaceStruct.Vertices;
    Middle = sum(Vertices) / size(Vertices,1);
    [yMin, minHideVert] = min(Vertices(:,2));
    [yMax, maxHideVert] = max(Vertices(:,2));
    xMin = min(Vertices(:,1));
    xMax = max(Vertices(:,1));
    zMin = min(Vertices(:,3));
    zMax = max(Vertices(:,3));
    
    V(1,:) = Middle + [xMin * 0.00 yMin * 0.20 zMin * 0.20];
    V(2,:) = Middle + [xMin * 0.00 yMin * 0.20 zMax * 0.10];
    V(3,:) = Middle + [xMin * 0.00 yMax * 0.20 zMin * 0.20];
    V(4,:) = Middle + [xMin * 0.00 yMax * 0.20 zMax * 0.10];
    H(1:4) = [1 1 2 2]'; 
    vIndex = 4;
    
    % Start point
    START_PERCENT = .3;
    
    % Left hemisphere
    LeftSurface = find(Vertices(:,2) < START_PERCENT * yMin)';
    LeftSurface = setdiff(LeftSurface, minHideVert);
    if ~isempty(minHideVert)
        while ~isempty(LeftSurface)
            minHideVert = union(minHideVert, LeftSurface);
            LeftSurface = tess_scout_swell(minHideVert, SurfaceStruct.VertConn);
        end
    end
    
    % Right hemisphere
    RightSurface = find(Vertices(:,2) > START_PERCENT * yMax)';
    RightSurface = setdiff(RightSurface, maxHideVert);
    if ~isempty(maxHideVert)
        while ~isempty(RightSurface)
            maxHideVert = union(maxHideVert, RightSurface);
            RightSurface = tess_scout_swell(maxHideVert, SurfaceStruct.VertConn);
        end
    end
    
    Surface{1} = Vertices(maxHideVert,:);
    Surface{2} = Vertices(minHideVert,:);
    
%     nCoronalSlice = 4;
%     nTransversalSlice = [2 3 3 2];
%     Connected = [1 2; 1 3; 1 17; 1 18; 1 20; 1 21;
%                  2 1; 2 4; 2 18; 2 19; 2 21; 2 22;
%                  3 1; 3 4; 3 7; 3 8; 3 10; 3 11;
%                  4 2; 4 3; 4 8; 4 9; 4 11; 4 12;
%                  ...
%                  5 6; 5 8;
%                  6 8;
%                  7 8; 7 10;
%                  8 9; 8 11;
%                  9 12;
%                  10 11;
%                  11 12; 11 13; 11 14;
%                  12 14;
%                  13 14;
%                  14 13;
%                  ...
%                  15 16; 15 18;
%                  16 18;
%                  17 18; 17 20;
%                  18 19; 18 21;
%                  19 22;
%                  20 21;
%                  21 22; 21 23; 21 24;
%                  22 24;
%                  23 24;
%                  24 23];
    nCoronalSlice = 4;
    nTransversalSlice = [2 3 3 2];
    CoronalStep = (xMax + abs(xMin)) / nCoronalSlice;
    for y=1:2
        Surf = Surface{y};
        cStart = xMin;
        for i=1:nCoronalSlice
            cEnd = cStart + CoronalStep;
            cIndex = Surf(:,1) >= cStart & Surf(:,1) < cEnd;
            tStart = zMin;
            TransversalStep = (zMax + abs(zMin)) / nTransversalSlice(i);
            for z=1:nTransversalSlice(i)
                tEnd = tStart + TransversalStep;
                tIndex = Surf(:,3) >= tStart & Surf(:,3) < tEnd;
                denom = sum(cIndex & tIndex);
                vIndex = vIndex + 1;
                V(vIndex,:) = [0 0 0];
                H(vIndex) = y;
                if (denom > 0)
                    V(vIndex,:) = sum(Surf(cIndex & tIndex,:)) / denom;
                    V(vIndex,:) = (0.75 * V(vIndex,:));
                end
                tStart = tEnd;
            end
            cStart = cEnd;
        end
    end
end


% Experimental code
% function [sGroups] = AssignRegionBasedOnPosition(hFig, aNames, aLocs, sGroups)
%     NumberOfGroups = size(sGroups,2);
%     CentroidOfEachGroups = zeros(NumberOfGroups,3);
%     for i=1:NumberOfGroups
%         NumberOfChannelsInGroup = size(sGroups(i).RowNames,1);
%         ChannelsInGroupIndex = ismember(aNames, sGroups(i).RowNames);
%         C = aLocs(ChannelsInGroupIndex,:);
%         CentroidOfEachGroups(i,:) = [sum(C(:,1)) sum(C(:,2)) sum(C(:,3))] / NumberOfChannelsInGroup;
%         % Assign channel hemisphere
%         if (CentroidOfEachGroups(i,2) > 0.05)
%             sGroups(i).Region = 1;
%         elseif (CentroidOfEachGroups(i,2) <= -0.05)
%             sGroups(i).Region = 2;
%         else
%             if (CentroidOfEachGroups(i,1) <= 0)
%                 sGroups(i).Region = 3;
%             else
%                 sGroups(i).Region = 4;
%             end
%         end
%     end
% end

function Index = HemisphereTagToIndex(Region)
    Tag = Region(1);
    Index = 4; % Unknown
    switch (Tag)
        case 'L' % Left
            Index = 1;
        case 'R' % Right
            Index = 2;
        case 'C' % Cerebellum
            Index = 3;
    end
end

function Index = LobeTagToIndex(Region)
    Tag = Region(2);
    Index = 7; % Unknown
    switch (Tag)
        case 'F' %Frontal
            Index = 2;
        case 'C' %Central
            Index = 3;
        case 'T' %Temporal
            Index = 4;
        case 'P' %Parietal
            Index = 5;
            if (size(Region,2) >= 3)
                if (strcmp(Region(3), 'F'))
                    Index = 1;
                end
            end
        case 'O' %Occipital
            Index = 6;
    end
end

function Tag = ExtractSubRegion(Region)
    Index = LobeTagToIndex(Region);
    if (Index == 1)
        Tag = Region(4:end);
    else
        Tag = Region(3:end);
    end
end

function Tag = HemisphereIndexToTag(Index)
    Tag = 'U';
    switch (Index)
        case 1
            Tag = 'L';
        case 2
            Tag = 'R';
        case 3
            Tag = 'C';
    end
end

function Tag = LobeIndexToTag(Index)
    Tag = 'U';
    switch (Index)
        case 1
            Tag = 'PF';
        case 2
            Tag = 'F';
        case 3
            Tag = 'C';            
        case 4
            Tag = 'T';
        case 5
            Tag = 'P';
        case 6
            Tag = 'O';
    end
end

function PathNames = VerticeToFullName(hFig, Index)
    if (Index == 1)
        return
    end
    PathNames{1} = 'All';
    ChannelData = getappdata(hFig, 'ChannelData');
    if (ChannelData(Index,3) ~= 0)
        switch (ChannelData(Index,3))
            case 1
                PathNames{2} = ' > Left hemisphere';
            case 2
                PathNames{2} = ' > Right hemisphere';
            case 3
                PathNames{2} = ' > Cerebellum';
            case 4
                PathNames{2} = ' > Unknown';
        end
    end
    
    if (ChannelData(Index,2) ~= 0)
        switch (ChannelData(Index,2))
            case 1
                PathNames{3} = ' > Pre-Frontal';
            case 2
                PathNames{3} = ' > Frontal';
            case 3
                PathNames{3} = ' > Central';
            case 4
                PathNames{3} = ' > Temporal';
            case 5
                PathNames{3} = ' > Parietal';
            case 6
                PathNames{3} = ' > Occipital';
            otherwise
                PathNames{3} = ' > Unknown';
        end
    end
    
    if (ChannelData(Index,1) ~= 0)
        Names = getappdata(hFig, 'Names');
        if isempty(Names{Index})
            PathNames{4} = ' > Sub-region';
        else
            PathNames{4} = [' > ' Names{Index}];
        end
    end 
end


function [sGroups] = GroupScouts(Atlas)
    % 
    NumberOfGroups = 0;
    sGroups = repmat(struct('Name', [], 'RowNames', [], 'Region', {}), 0);
    NumberOfScouts = size(Atlas.Scouts,2);
    for i=1:NumberOfScouts
        Region = Atlas.Scouts(i).Region;
        GroupID = strmatch(Region, {sGroups.Region}, 'exact');
        if isempty(GroupID)
            % New group
            NumberOfGroups = NumberOfGroups + 1;
            sGroups(NumberOfGroups).Name = ['Group ' num2str(NumberOfGroups)];
            sGroups(NumberOfGroups).RowNames = {Atlas.Scouts(i).Label};
            sGroups(NumberOfGroups).Region = Region;
        else
            sGroups(GroupID).RowNames = [sGroups(GroupID).RowNames {Atlas.Scouts(i).Label}];
        end
    end
    
    if size(sGroups,2) == 1 && strcmp(sGroups(1).Region, 'UU') == 1
        sGroups = [];
        return;
    end
    
    % Sort by Hemisphere and Lobe
    for i=2:NumberOfGroups
        j = i;
        sTemp = sGroups(i);
        currentHemisphere = HemisphereTagToIndex(sGroups(i).Region);
        currentLobe = LobeTagToIndex(sGroups(i).Region);
        while ((j > 1))
            current = currentHemisphere;
            next = HemisphereTagToIndex(sGroups(j-1).Region);
            if (current == next)
                current = currentLobe;
                next = LobeTagToIndex(sGroups(j-1).Region);
            end
            if (next <= current)
                break;
            end
            sGroups(j) = sGroups(j-1);
            j = j - 1;
        end
        sGroups(j) = sTemp;
    end
end


% function ChannelData = BuildChannelData(hFig, aNames, sGroups)
%     % Get number of nodes
%     nAgregatingNodes = size(getappdata(hFig, 'AgregatingNodes'),2);
%     nMeasureNodes = size(getappdata(hFig, 'MeasureNodes'),2);
%     NumberOfChannels = nAgregatingNodes + nMeasureNodes;
%     % Get levels
%     % Levels = getappdata(hFig, 'Levels');
%     % Number of levels
%     NumberOfLevels = getappdata(hFig, 'NumberOfLevels');
%     % Init structure - (Hemisphere / Lobe / Region)
%     ChannelData = ones(NumberOfChannels, NumberOfLevels - 2);
%     % Constant variable
%     NumberOfHemisphere = 3;
%     NumberOfLobes = 6;
%     NumberOfGroups = size(sGroups,2);
%     % Level specific
%     if (NumberOfLevels == 5)
%         % Hemisphere
%         for i=1:NumberOfHemisphere
%             HemisphereRegions = cellfun(@(x) {x(1)}, {sGroups.Region})';
%             HemisphereFilter = strcmp(HemisphereIndexToTag(i), HemisphereRegions) == 1;
%             RowNames = [sGroups(HemisphereFilter).RowNames];
%             if (~isempty(RowNames))
%                 Index = ismember(aNames, RowNames);
%                 ChannelData(Index,3) = i;
%             end    
%         end
%         % Lobes
%         for i=1:NumberOfLobes
%             LobeRegions = cellfun(@(x) {x(2)}, {sGroups.Region})';
%             LobeFilter = strcmp(LobeIndexToTag(i), LobeRegions) == 1;
%             RowNames = [sGroups(LobeFilter).RowNames];
%             if (~isempty(RowNames))
%                 Index = ismember(aNames, RowNames);
%                 ChannelData(Index,2) = i;
%             end
%         end
%     end
%     % Lobe Regions
%     for i=1:NumberOfGroups
%         RowNames = [sGroups(i).RowNames];
%         if (~isempty(RowNames))
%             Index = ismember(aNames, RowNames);
%             ChannelData(Index,1) = i;
%         end
%     end
% end

%function BuildDisplayStatistics(hFig, sGroups)
%     RowNames = [sGroups.RowNames];
%     NumberOfMeasure = size(RowNames,1);
%     NumberOfRegion = size(sGroups,1);
%     
%     Hemispheres = [];
%     Lobes = [];
%     
%     RegionsSize = cellfun(@(x) {size(x,2)}, {sGroups.Region});
%     NumberOfLevel = max(RegionsSize) + 1;
%     if (NumberOfLevel > 0)
%         Hemispheres = unique(cellfun(@(x) {x(1)}, {sGroups.Region}));
%     end
%     if (NumberOfLevel > 1)
%         Lobes = unique(cellfun(@(x) {x(2)}, {sGroups.Region}));
%     end
%     
%     NumberOfLobes = size(Lobes,2);
%     NumberOfHemispheres = size(Hemispheres,2);
%end

%
% Experimental display, could be updated and used one day.
%
% function [Vertices Paths Names] = OrganiseNodesWithMeasureDensity(hFig, aNames, sGroups)
% 
%     % Display options
%     MeasureLevel = 4;
%     RegionLevel = 3.5;
%     LobeLevel = 2;
%     HemisphereLevel = 0.5;
% 
%     
%     RowNames = [sGroups.RowNames];    
%     Hemispheres = [];
%     Lobes = [];
%     
%     RegionsSize = cellfun(@(x) {size(x,2)}, {sGroups.Region});
%     % NumberOfLevel = Self + Middle + EverythingInBetween
%     NumberOfLevel = max([RegionsSize{:}]) + 2;
%     Levels = cell(NumberOfLevel,1);
%     if (NumberOfLevel > 0)
%         Levels{1} = cellfun(@(x) {x(1)}, {sGroups.Region});
%         Hemispheres = unique(Levels{1});
%     end
%     if (NumberOfLevel > 1)
%         Levels{2} = unique(cellfun(@(x) {x(2)}, {sGroups.Region}));
%         Lobes = unique(Levels{2});
%     end
%     
%     % Interior to Exterior
%     NumberOfEachLevel = zeros(NumberOfLevel,1);
%     NumberOfEachLevel(1) = 1;
%     NumberOfEachLevel(2) = size(Hemispheres,1);
%     NumberOfEachLevel(3) = size(Lobes,1) * 2;
%     NumberOfEachLevel(4) = size(sGroups,2);
%     NumberOfEachLevel(5) = size(RowNames,2);
%     
%     NumberOfAgregatingNodes = sum(NumberOfEachLevel(1:(end-1)));
%     NumberOfMeasureNodes = sum(NumberOfEachLevel(end));
%     NumberOfVertices = sum(NumberOfEachLevel);
%     Vertices = zeros(NumberOfVertices,3);
%     Names = cell(NumberOfVertices,1);
%     Paths = zeros(NumberOfVertices,NumberOfLevel);
%     
%     AngleStep = 360 / (NumberOfMeasureNodes + 2 * sum(NumberOfEachLevel(2:(end-1))));
% 
%     HemispheresChannels = cell(NumberOfEachLevel(2),1);
%     HemispheresPercent = zeros(NumberOfEachLevel(2),1);
%     for i=1:NumberOfEachLevel(2)
%         GroupsIndex = strcmp(LobeIndexToTag(i), Levels{1}) == 1;
%         HemispheresChannels{i} = [sGroups(GroupsIndex).RowNames];
%         HemispheresPercent(i) = size(HemispheresChannels{i},2) / NumberOfMeasureNodes;
%     end
%      
%     % Static Nodes
%     Vertices(1,:) = [0 0 0];                    % Corpus Callosum
%     Vertices(2,:) = [-HemisphereLevel 0 0];     % Left Hemisphere
%     Vertices(3,:) = [ HemisphereLevel 0 0];     % Right Hemisphere
%     Vertices(4,:) = [ 0 -HemisphereLevel 0];    % Cerebellum
%     Names(1) = {'Corpus Callosum'};
%     Names(2) = {'Left Hemisphere'};
%     Names(3) = {'Right Hemisphere'};
%     Names(4) = {'Cerebellum'};
% 
%     % The lobes are determined by the mean of the regions nodes
%     % The regions nodes are determined by the mean of their nodes
% 
%     % Organise Left Hemisphere
%     RegionIndex = 4 + NumberOfLobes * 2 + 1;
%     for i=1:NumberOfLobes
%         LobeIndex = i;
%         Angle = 90 + LobeSections(LobeIndex,1);
%         LobeTag = LobeIndexToTag(i);
%         HemisphereRegions
%         RegionMask = strcmp(LobeTag,LobeRegions) == 1 & strcmp('L',HemisphereRegions) == 1;
%         RegionNodeIndex = find(RegionMask == 1);
%         NumberOfRegionInLobe = sum(RegionMask);
%         for y=1:NumberOfRegionInLobe
%             Group = sGroups(RegionNodeIndex(y));
%             Region = [Group.Region];
%             NumberOfNodesInGroup = size([Group.RowNames],2);
%             % Figure out how much space per node
%             AllowedPercent = NumberOfNodesInGroup / NumberOfNodesPerLobe(LobeIndex);
%             LobeSpace = LobeSections(LobeIndex,2) - LobeSections(LobeIndex,1);
%             AllowedSpace = AllowedPercent * LobeSpace;
%             % +2 is for the offset at borders so regions don't touch
%             LocalTheta = linspace((pi/180) * (Angle), (pi/180) * (Angle + AllowedSpace), NumberOfNodesInGroup + 2);
%             % Retrieve cartesian coordinate
%             [posX,posY] = pol2cart(LocalTheta(2:end-1),1);
%             % Assign
%             ChannelsOfThisGroup = ismember(aNames, Group.RowNames);
%             % Compensate for agregating nodes
%             Index = find(ChannelsOfThisGroup) + NumberOfAgregatingNodes;
%             Vertices(Index, 1:2) = [posX' posY'] * MeasureLevel;
%             Names(Index) = aNames(ChannelsOfThisGroup);
%             % Update Paths
%             Paths(ChannelsOfThisGroup,1) = Index;
%             Paths(ChannelsOfThisGroup,2) = RegionIndex;
%             Paths(ChannelsOfThisGroup,3) = LobeIndex + 4;
%             Paths(ChannelsOfThisGroup,4) = 2;
%             Paths(ChannelsOfThisGroup,5) = 1;
%             % Update current angle
%             Angle = Angle + AllowedSpace;
%             % Update agregating node
%             Mean = mean([posX' posY']);
%             Mean = Mean / norm(Mean);
%             Vertices(RegionIndex, 1:2) = Mean * RegionLevel;
%             Names(RegionIndex) = {['Region ' Region(3:end)]};
%             RegionIndex = RegionIndex + 1;
%         end
%         
%         Pos = 90 + (LobeSections(LobeIndex,2) + LobeSections(LobeIndex,1)) / 2;
%         [posX,posY] = pol2cart((pi/180) * (Pos),1);
%         Vertices(i+4, 1:2) = [posX,posY] * LobeLevel;
%         Names(i+4) = {['Left ' LobeTag]};
%     end
% %     
% %     % Organise Right Hemisphere
% %     for i=1:NumberOfLobes
% %         LobeIndex = i;
% %         Angle = 90 - LobeSections(LobeIndex,1);
% %         LobeTag = LobeIndexToTag(i);
% %         RegionMask = strcmp(LobeTag,LobeRegions) == 1 & strcmp('R',HemisphereRegions) == 1;
% %         RegionNodeIndex = find(RegionMask == 1);
% %         NumberOfRegionInLobe = sum(RegionMask);
% %         for y=1:NumberOfRegionInLobe
% %             Group = sGroups(RegionNodeIndex(y));
% %             Region = [Group.Region];
% %             NumberOfNodesInGroup = size([Group.RowNames],2);
% %             % Figure out how much space per node
% %             AllowedPercent = NumberOfNodesInGroup / NumberOfNodesPerLobe(LobeIndex);
% %             LobeSpace = LobeSections(LobeIndex,2) - LobeSections(LobeIndex,1);
% %             AllowedSpace = AllowedPercent * LobeSpace;
% %             % +2 is for the offset at borders so regions don't touch        
% %             LocalTheta = linspace(deg2rad(Angle), deg2rad(Angle - AllowedSpace), NumberOfNodesInGroup + 2);
% %             % Retrieve cartesian coordinate
% %             [posX,posY] = pol2cart(LocalTheta(2:end-1),1);
% %             % Assign
% %             ChannelsOfThisGroup = ismember(aNames, Group.RowNames);
% %             % Compensate for agregating nodes
% %             Index = find(ChannelsOfThisGroup) + NumberOfAgregatingNodes;
% %             Vertices(Index, 1:2) = [posX' posY'] * MeasureLevel;
% %             Names(Index) = aNames(ChannelsOfThisGroup);
% %             % Update Paths
% %             Paths(ChannelsOfThisGroup,1) = Index;
% %             Paths(ChannelsOfThisGroup,2) = RegionIndex;
% %             Paths(ChannelsOfThisGroup,3) = NumberOfLobes + LobeIndex + 4;
% %             Paths(ChannelsOfThisGroup,4) = 3;
% %             Paths(ChannelsOfThisGroup,5) = 1;
% %             % Update current angle
% %             Angle = Angle - AllowedSpace;
% %             % Update agregating node
% %             Mean = mean([posX' posY']);
% %             Mean = Mean / norm(Mean);
% %             Vertices(RegionIndex, 1:2) = Mean * RegionLevel;
% %             Names(RegionIndex) = {['Region ' Region(3:end)]};
% %             RegionIndex = RegionIndex + 1;
% %         end
% %         
% %         Pos = 90 - (LobeSections(LobeIndex,2) + LobeSections(LobeIndex,1)) / 2;
% %         [posX,posY] = pol2cart(deg2rad(Pos),1);
% %         Vertices(i+NumberOfLobes+4, 1:2) = [posX,posY] * LobeLevel;
% %         Names(i+NumberOfLobes+4) = {['Right ' LobeTag]};
% %     end
% %     
% %     % Keep Structures Statistics
% %     AgregatingNodes = 1:NumberOfAgregatingNodes;
% %     MeasureNodes = NumberOfAgregatingNodes+1:NumberOfAgregatingNodes+NumberOfNodes;    
% %     setappdata(hFig, 'AgregatingNodes', AgregatingNodes);
% %     setappdata(hFig, 'MeasureNodes', MeasureNodes);
% 
% end

function [Vertices Paths Names] = OrganiseNodesWithConstantLobe(hFig, aNames, sGroups, RowLocs, UpdateStructureStatistics)

    % Display options
    MeasureLevel = 4;
    RegionLevel = 3.5;
    LobeLevel = 2.5;
    HemisphereLevel = 1.0;
    setappdata(hFig, 'MeasureLevelDistance', MeasureLevel);

    % Some values are Hardcoded for Display consistency
    NumberOfMeasureNodes = size(aNames,1);
    NumberOfGroups = size(sGroups,2);
    NumberOfLobes = 7;
    NumberOfHemispheres = 2;
    NumberOfLevels = 5;
        
    % Extract only the first region letter of each group
    HemisphereRegions = cellfun(@(x) {x(1)}, {sGroups.Region})';
    LobeRegions = cellfun(@(x) {LobeIndexToTag(LobeTagToIndex(x))}, {sGroups.Region})';
    
    LeftGroupsIndex = strcmp('L',HemisphereRegions) == 1;
    RightGroupsIndex = strcmp('R',HemisphereRegions) == 1;
    CerebellumGroupsIndex = strcmp('C',HemisphereRegions) == 1;
    UnknownGroupsIndex = strcmp('U',HemisphereRegions) == 1;
    
    % Angle allowed for each hemisphere
    AngleAllowed = [0 180];
    nCerebellum = sum(CerebellumGroupsIndex);
    if (nCerebellum > 0)
        % Constant size of 15% of circle allowed to Cerebellum
        AngleAllowed(2) = 180 - 15;
        NumberOfHemispheres = NumberOfHemispheres + 1;
    end
    
    nUnkown = sum(UnknownGroupsIndex);
    if (nUnkown > 0)
        % Constant size of 15% of circle allowed to Unknown
        AngleAllowed(1) = 15;
    end
    
    % NumberOfLevel = Self + Middle + EverythingInBetween
    Levels = cell(NumberOfLevels,1);
    Levels{5} = 1;
    Levels{4} = (2:(NumberOfHemispheres+1))';
    
    Lobes = [];
    NumberOfNodesPerLobe = zeros(NumberOfLobes * 2,1);
    for i=1:NumberOfLobes
        Tag = LobeIndexToTag(i);
        RegionsIndex = strcmp(Tag,LobeRegions) == 1;
        NodesInLeft = [sGroups(LeftGroupsIndex & RegionsIndex).RowNames];
        NodesInRight = [sGroups(RightGroupsIndex & RegionsIndex).RowNames];
        NumberOfNodesPerLobe(i) = length(NodesInLeft);
        NumberOfNodesPerLobe(NumberOfLobes + i) = length(NodesInRight);
        if (size(NodesInLeft,2) > 0 || size(NodesInRight,2) > 0)
            Lobes = [Lobes i];
        end
    end
    
    % Actual number of lobes with data
    NumberOfLobes = size(Lobes,2);
    
    % Start and end angle for each lobe section
    % We use a constant separation for each lobe
    AngleStep = (AngleAllowed(2) - AngleAllowed(1))/ NumberOfLobes;
    LobeSections = zeros(NumberOfLobes,2);
    LobeSections(:,1) = 0:NumberOfLobes-1;
    LobeSections(:,2) = 1:NumberOfLobes;
    LobeSections(:,:) = AngleAllowed(1) + LobeSections(:,:) * AngleStep;
    
    NumberOfAgregatingNodes = 1 + NumberOfHemispheres + NumberOfLobes * 2 + NumberOfGroups;
    NumberOfVertices = NumberOfMeasureNodes + NumberOfAgregatingNodes;
    Vertices = zeros(NumberOfVertices,3);
    Names = cell(NumberOfVertices,1);
    Paths = cell(NumberOfVertices,1);
    ChannelData = zeros(NumberOfVertices,3);
    
    % Static Nodes
    Vertices(1,:) = [0 0 0];                    % Corpus Callosum
    Vertices(2,:) = [-HemisphereLevel 0 0];     % Left Hemisphere
    Vertices(3,:) = [ HemisphereLevel 0 0];     % Right Hemisphere
    if (nCerebellum > 0)
        Vertices(4,:) = [ 0 -HemisphereLevel 0];    % Cerebellum
        Names(4) = {''};
        Paths{4} = [4 1];
        ChannelData(4,:) = [0 0 3];
    end
    Names(1) = {''};
    Names(2) = {'Left'};
    Names(3) = {'Right'};
    Paths{1} = 1;
    Paths{2} = [2 1];
    Paths{3} = [3 1];
    ChannelData(2,:) = [0 0 1];
    ChannelData(3,:) = [0 0 2];
    
    % The lobes are determined by the mean of the regions nodes
    % The regions nodes are determined by the mean of their nodes
    % Organise Left Hemisphere
    RegionIndex = 1 + NumberOfHemispheres + NumberOfLobes * 2 + 1;
    for i=1:NumberOfLobes
        Lobe = i;
        LobeIndex = Lobe + NumberOfHemispheres + 1;
        Levels{3} = [Levels{3}; LobeIndex];
        Angle = 90 + LobeSections(Lobe,1);
        LobeTag = LobeIndexToTag(Lobes(i));
        RegionMask = strcmp(LobeTag,LobeRegions) == 1 & strcmp('L',HemisphereRegions) == 1;
        RegionNodeIndex = find(RegionMask == 1);
        NumberOfRegionInLobe = sum(RegionMask);
        for y=1:NumberOfRegionInLobe
            Levels{2} = [Levels{2}; RegionIndex];
            Group = sGroups(RegionNodeIndex(y));
            Region = [Group.Region];
            NumberOfNodesInGroup = length([Group.RowNames]);
            if (NumberOfNodesInGroup > 0)
                % Figure out how much space per node
                AllowedPercent = NumberOfNodesInGroup / NumberOfNodesPerLobe(Lobes(i));
                LobeSpace = LobeSections(Lobe,2) - LobeSections(Lobe,1);
                AllowedSpace = AllowedPercent * LobeSpace;
                % +2 is for the offset at borders so regions don't touch        
                LocalTheta = linspace((pi/180) * (Angle), (pi/180) * (Angle + AllowedSpace), NumberOfNodesInGroup + 2);
                % Retrieve cartesian coordinate
                [posX,posY] = pol2cart(LocalTheta(2:(end-1)),1);
                % Assign
                ChannelsOfThisGroup = ismember(aNames, Group.RowNames);
                % Compensate for agregating nodes
                Index = find(ChannelsOfThisGroup) + NumberOfAgregatingNodes;
                % Update node information
                Order = 1:size(Index,1);
                if ~isempty(RowLocs)
                    [tmp, Order] = sort(RowLocs(ChannelsOfThisGroup,1), 'descend');
                end
                Vertices(Index(Order), 1:2) = [posX' posY'] * MeasureLevel;
                Names(Index) = aNames(ChannelsOfThisGroup);
                Paths(Index) = mat2cell([Index repmat([RegionIndex LobeIndex 2 1], size(Index))], ones(1,size(Index,1)), 5);
                ChannelData(Index,:) = repmat([RegionIndex Lobes(Lobe) 1], size(Index));
                Levels{1} = [Levels{1}; Index(Order)];
                % Update agregating node
                if (NumberOfNodesInGroup == 1)
                    Mean = [posX posY];
                else
                    Mean = mean([posX' posY']);
                end
                Mean = Mean / norm(Mean);
                Vertices(RegionIndex, 1:2) = Mean * RegionLevel;
                Names(RegionIndex) = {ExtractSubRegion(Region)};
                Paths(RegionIndex) = {[RegionIndex LobeIndex 2 1]};
                ChannelData(RegionIndex,:) = [RegionIndex Lobes(Lobe) 1];
                % Update current angle
                Angle = Angle + AllowedSpace;
            end
            RegionIndex = RegionIndex + 1;
        end
        
        Pos = 90 + (LobeSections(Lobe,2) + LobeSections(Lobe,1)) / 2;
        [posX,posY] = pol2cart((pi/180) * (Pos),1);
        Vertices(LobeIndex, 1:2) = [posX,posY] * LobeLevel;
        Names(LobeIndex) = {LobeTag};
        Paths(LobeIndex) = {[LobeIndex 2 1]};
        ChannelData(LobeIndex,:) = [0 Lobes(Lobe) 1];
    end
    
    % Organise Right Hemisphere
    for i=1:NumberOfLobes
        Lobe = i;
        LobeIndex = Lobe + NumberOfLobes + NumberOfHemispheres + 1;
        Levels{3} = [Levels{3}; LobeIndex];
        Angle = 90 - LobeSections(Lobe,1);
        LobeTag = LobeIndexToTag(Lobes(i));
        RegionMask = strcmp(LobeTag,LobeRegions) == 1 & strcmp('R',HemisphereRegions) == 1;
        RegionNodeIndex = find(RegionMask == 1);
        NumberOfRegionInLobe = sum(RegionMask);
        for y=1:NumberOfRegionInLobe
            Levels{2} = [Levels{2}; RegionIndex];
            Group = sGroups(RegionNodeIndex(y));
            Region = [Group.Region];
            NumberOfNodesInGroup = length([Group.RowNames]);
            if (NumberOfNodesInGroup > 0)
                % Figure out how much space per node
                AllowedPercent = NumberOfNodesInGroup / NumberOfNodesPerLobe(Lobes(i) + 7);
                LobeSpace = LobeSections(Lobe,2) - LobeSections(Lobe,1);
                AllowedSpace = AllowedPercent * LobeSpace;
                % +2 is for the offset at borders so regions don't touch        
                LocalTheta = linspace((pi/180) * (Angle), (pi/180) * (Angle - AllowedSpace), NumberOfNodesInGroup + 2);
                % Retrieve cartesian coordinate
                [posX,posY] = pol2cart(LocalTheta(2:(end-1)),1);
                % Assign
                ChannelsOfThisGroup = ismember(aNames, Group.RowNames);
                % Compensate for agregating nodes
                Index = find(ChannelsOfThisGroup) + NumberOfAgregatingNodes;
                % Update node information
                Order = 1:size(Index,1);
                if ~isempty(RowLocs)
                    [tmp, Order] = sort(RowLocs(ChannelsOfThisGroup,1), 'descend');
                end
                Vertices(Index(Order), 1:2) = [posX' posY'] * MeasureLevel;
                Names(Index) = aNames(ChannelsOfThisGroup);
                Paths(Index) = mat2cell([Index repmat([RegionIndex LobeIndex 3 1], size(Index))], ones(1,size(Index,1)), 5);
                ChannelData(Index,:) = repmat([RegionIndex Lobes(Lobe) 2], size(Index));
                Levels{1} = [Levels{1}; Index(Order)];
                % Update agregating node
                if (NumberOfNodesInGroup == 1)
                    Mean = [posX posY];
                else
                    Mean = mean([posX' posY']);
                end
                Mean = Mean / norm(Mean);
                Vertices(RegionIndex, 1:2) = Mean * RegionLevel;
                Names(RegionIndex) = {ExtractSubRegion(Region)};
                Paths(RegionIndex) = {[RegionIndex LobeIndex 3 1]};
                ChannelData(RegionIndex,:) = [RegionIndex Lobes(Lobe) 2];
                % Update current angle
                Angle = Angle - AllowedSpace;
            end
            RegionIndex = RegionIndex + 1;
        end
        
        Pos = 90 - (LobeSections(Lobe,2) + LobeSections(Lobe,1)) / 2;
        [posX,posY] = pol2cart((pi/180) * (Pos),1);
        Vertices(LobeIndex, 1:2) = [posX,posY] * LobeLevel;
        Names(LobeIndex) = {LobeTag};
        Paths(LobeIndex) = {[LobeIndex 3 1]};
        ChannelData(LobeIndex,:) = [0 Lobes(Lobe) 2];
    end
    
    % Organise Cerebellum
    if (nCerebellum > 0)
        Angle = 270 - 15;
        NodesInCerebellum = [sGroups(CerebellumGroupsIndex).RowNames];
        NumberOfNodesInCerebellum = size(NodesInCerebellum,2);
        RegionMask = strcmp('C',HemisphereRegions) == 1;
        RegionNodeIndex = find(RegionMask == 1);
        NumberOfRegionInCerebellum = sum(RegionMask);
        for y=1:NumberOfRegionInCerebellum
            Levels{2} = [Levels{2}; RegionIndex];
            Group = sGroups(RegionNodeIndex(y));
            Region = [Group.Region];
            NumberOfNodesInGroup = length([Group.RowNames]);
            if (NumberOfNodesInGroup > 0)
                % Figure out how much space per node
                AllowedPercent = NumberOfNodesInGroup / NumberOfNodesInCerebellum;
                % Static for Cerebellum
                LobeSpace = 30;
                AllowedSpace = AllowedPercent * LobeSpace;
                % +2 is for the offset at borders so regions don't touch        
                LocalTheta = linspace((pi/180) * (Angle), (pi/180) * (Angle + AllowedSpace), NumberOfNodesInGroup + 2);
                % Retrieve cartesian coordinate
                [posX,posY] = pol2cart(LocalTheta(2:(end-1)),1);
                % Assign
                ChannelsOfThisGroup = ismember(aNames, Group.RowNames);
                % Compensate for agregating nodes
                Index = find(ChannelsOfThisGroup) + NumberOfAgregatingNodes;
                Order = 1:size(Index,1);
                if ~isempty(RowLocs)
                    [tmp, Order] = sort(RowLocs(ChannelsOfThisGroup,1), 'descend');
                end
                Vertices(Index(Order), 1:2) = [posX' posY'] * MeasureLevel;
                Names(Index) = aNames(ChannelsOfThisGroup);
                Paths(Index) = mat2cell([Index repmat([RegionIndex 4 1 1], size(Index))], ones(1,size(Index,1)), 5);
                ChannelData(Index,:) = repmat([RegionIndex 0 0], size(Index));
                Levels{1} = [Levels{1}; Index];
                % Update agregating node
                if (NumberOfNodesInGroup == 1)
                    Mean = [posX posY];
                else
                    Mean = mean([posX' posY']);
                end
                Mean = Mean / norm(Mean);
                Vertices(RegionIndex, 1:2) = Mean * RegionLevel;
                Names(RegionIndex) = {ExtractSubRegion(Region)};
                Paths(RegionIndex) = {[RegionIndex 4 1 1]};
                ChannelData(RegionIndex,:) = [RegionIndex 0 0];
                % Update current angle
                Angle = Angle + AllowedSpace;
            end
            RegionIndex = RegionIndex + 1;
        end
    end
    
    % Organise Unknown...
    if (nUnkown > 0)
        Angle = 90 - 15;
        NodesInUnknown = [sGroups(UnknownGroupsIndex).RowNames];
        NumberOfNodesInUnknown = size(NodesInUnknown,2);
        RegionMask = strcmp('U',HemisphereRegions) == 1;
        RegionNodeIndex = find(RegionMask == 1);
        NumberOfRegionInUnknown = sum(RegionMask);
        for y=1:NumberOfRegionInUnknown
            Levels{2} = [Levels{2}; RegionIndex];
            Group = sGroups(RegionNodeIndex(y));
            Region = [Group.Region];
            NumberOfNodesInGroup = size([Group.RowNames],2);
            if (NumberOfNodesInGroup > 0)
                % Figure out how much space per node
                AllowedPercent = NumberOfNodesInGroup / NumberOfNodesInUnknown;
                % Static for Cerebellum
                LobeSpace = 30;
                AllowedSpace = AllowedPercent * LobeSpace;
                % +2 is for the offset at borders so regions don't touch        
                LocalTheta = linspace((pi/180) * (Angle), (pi/180) * (Angle + AllowedSpace), NumberOfNodesInGroup + 2);
                % Retrieve cartesian coordinate
                [posX,posY] = pol2cart(LocalTheta(2:(end-1)),1);
                % Assign
                ChannelsOfThisGroup = ismember(aNames, Group.RowNames);
                % Compensate for agregating nodes
                Index = find(ChannelsOfThisGroup) + NumberOfAgregatingNodes;
                Order = 1:size(Index,1);
                if ~isempty(RowLocs)
                    [tmp, Order] = sort(RowLocs(ChannelsOfThisGroup,1), 'descend');
                end
                Vertices(Index(Order), 1:2) = [posX' posY'] * MeasureLevel;
                Names(Index) = aNames(ChannelsOfThisGroup);
                Paths(Index) = mat2cell([Index repmat([RegionIndex 1 1 1], size(Index))], ones(1,size(Index,1)), 5);
                ChannelData(Index,:) = repmat([RegionIndex 0 0], size(Index));
                Levels{1} = [Levels{1}; Index];
                % Update agregating node
                if (NumberOfNodesInGroup == 1)
                    Mean = [posX posY];
                else
                    Mean = mean([posX' posY']);
                end
                Mean = Mean / norm(Mean);
                Vertices(RegionIndex, 1:2) = Mean * RegionLevel;
                Names(RegionIndex) = {ExtractSubRegion(Region)};
                Paths(RegionIndex) = {[RegionIndex 1 1 1]};
                ChannelData(RegionIndex,:) = [RegionIndex 0 0];
                % Update current angle
                Angle = Angle + AllowedSpace;
            end
            RegionIndex = RegionIndex + 1;
        end
    end
    
    
%     if (nCerebellum > 0)
%         CereHem = ChannelData(:,2) == 4;
%         Vertices(CereHem,2) = Vertices(CereHem,2) * 1.2;
%     end
%     
%     if (nUnkown > 0)
%         Unknown = ChannelData(:,3) == 0;
%         Vertices(Unknown,2) = Vertices(Unknown,2) * 1.2;
%     end
%     
%     %Prototype: Empirical values for a more oval/head-like shape
%     LeftHem = ChannelData(:,3) == 1;
%     RightHem = ChannelData(:,3) == 2;
%     Vertices(LeftHem,1) = Vertices(LeftHem,1) - 0.6;
%     Vertices(LeftHem,2) = Vertices(LeftHem,2) * 1.2;
% 	  Vertices(RightHem,1) = Vertices(RightHem,1) + 0.6;
%     Vertices(RightHem,2) = Vertices(RightHem,2) * 1.2;
    
    if (~isempty(UpdateStructureStatistics) && UpdateStructureStatistics == 1)
        % Keep Structures Statistics
        setappdata(hFig, 'AgregatingNodes', 1:NumberOfAgregatingNodes);
        setappdata(hFig, 'MeasureNodes', (NumberOfAgregatingNodes + 1):(NumberOfAgregatingNodes + NumberOfMeasureNodes));
        setappdata(hFig, 'Lobes', Lobes);
        % Levels information
        setappdata(hFig, 'NumberOfLevels', NumberOfLevels);
        setappdata(hFig, 'Levels', Levels);
        % Node hierarchy data
        setappdata(hFig, 'ChannelData', ChannelData);
    end
end


function [Vertices Paths Names] = OrganiseNodeInCircle(hFig, aNames, sGroups)
    % Display options
    MeasureLevel = 4;
    RegionLevel = 2;

    NumberOfMeasureNodes = size(aNames,1);
    NumberOfGroups = size(sGroups,2);
    NumberOfAgregatingNodes = 1;
        
    NumberOfLevels = 2;
    if (NumberOfGroups > 1)
        NumberOfLevels = 3;
        NumberOfAgregatingNodes = NumberOfAgregatingNodes + NumberOfGroups;
    end
    % NumberOfLevel = Self + Middle + EverythingInBetween
    Levels = cell(NumberOfLevels,1);
    Levels{end} = 1;
    
    NumberOfVertices = NumberOfMeasureNodes + NumberOfAgregatingNodes;
    
    % Structure for vertices
    Vertices = zeros(NumberOfVertices,3);
    Names = cell(NumberOfVertices,1);
    Paths = cell(NumberOfVertices,1);
    
    % Static node
    Vertices(1,1:2) = [0 0];
    Names{1} = ' ';
    Paths{1} = 1;
    
    NumberOfNodesInGroup = zeros(NumberOfGroups,1);
    GroupsTheta = zeros(NumberOfGroups,1);
    GroupsTheta(1,1) = (pi * 0.5);
    for i=1:NumberOfGroups
        if (i ~= 1)
            GroupsTheta(i,1) = GroupsTheta(i-1,2);
        end
        NumberOfNodesInGroup(i) = 1;
        if (iscellstr(sGroups(i).RowNames))
            NumberOfNodesInGroup(i) = size(sGroups(i).RowNames,2);
        end
        Theta = (NumberOfNodesInGroup(i) / NumberOfMeasureNodes * (2 * pi));
        GroupsTheta(i,2) = GroupsTheta(i,1) + Theta;
    end
        
    for i=1:NumberOfGroups
        LocalTheta = linspace(GroupsTheta(i,1), GroupsTheta(i,2), NumberOfNodesInGroup(i) + 1);
        ChannelsOfThisGroup = ismember(aNames, sGroups(i).RowNames);
        Index = find(ChannelsOfThisGroup) + NumberOfAgregatingNodes;
        [posX,posY] = pol2cart(LocalTheta(2:end),1);
        Vertices(Index,1:2) = [posX' posY'] * MeasureLevel;
        Names(Index) = sGroups(i).RowNames;
        Paths(Index) = mat2cell([Index repmat(1, size(Index))], ones(1,size(Index,1)), 2);
        Levels{1} = [Levels{1}; Index];
        
        if (NumberOfLevels > 2)
            RegionIndex = i + 1;
            Paths(Index) = mat2cell([Index repmat([RegionIndex 1], size(Index))], ones(1,size(Index,1)), 3);
            
            % Update agregating node
            if (NumberOfNodesInGroup(i) == 1)
                Mean = [posX posY];
            else
                Mean = mean([posX' posY']);
            end
            Mean = Mean / norm(Mean);
            Vertices(RegionIndex,1:2) = Mean * RegionLevel;
            Names(RegionIndex) = {['Region ' num2str(i)]};
            Paths(RegionIndex) = {[RegionIndex 1]};
            Levels{2} = [Levels{2}; RegionIndex];
        end
    end
    
    % Keep Structures Statistics
    AgregatingNodes = 1:NumberOfAgregatingNodes;
    MeasureNodes = NumberOfAgregatingNodes+1:NumberOfAgregatingNodes+NumberOfMeasureNodes;    
    setappdata(hFig, 'AgregatingNodes', AgregatingNodes);
    setappdata(hFig, 'MeasureNodes', MeasureNodes);
    % 
    setappdata(hFig, 'NumberOfLevels', NumberOfLevels)
    %
    setappdata(hFig, 'Levels', Levels);
end


function Vertices = ReorganiseNodeAroundInCircle(hFig, sGroups, aNames, Level)

    Paths = getappdata(hFig, 'NodePaths');
    nVertices = size(getappdata(hFig, 'Vertices'), 1);
    Vertices = zeros(nVertices,3);
    Vertices(:,3) = -5;
    
    DisplayLevel = 4:-(4/(Level-1)):0;
    
    NumberOfMeasureNodes = length([sGroups.RowNames]);
    NumberOfGroups = length(sGroups);
    
    NumberOfAgregatingNodes = length(getappdata(hFig, 'AgregatingNodes'));
    
    NumberOfNodesInGroup = zeros(NumberOfGroups,1);
    GroupsTheta = zeros(NumberOfGroups,1);
    GroupsTheta(1,1) = (pi * 0.5);
    for i=1:NumberOfGroups
        if (i ~= 1)
            GroupsTheta(i,1) = GroupsTheta(i-1,2);
        end
        NumberOfNodesInGroup(i) = 1;
        if (iscellstr(sGroups(i).RowNames))
            NumberOfNodesInGroup(i) = length(sGroups(i).RowNames);
        end
        Theta = (NumberOfNodesInGroup(i) / NumberOfMeasureNodes * (2 * pi));
        GroupsTheta(i,2) = GroupsTheta(i,1) + Theta;
    end
    
    for i=1:NumberOfGroups
        LocalTheta = linspace(GroupsTheta(i,1), GroupsTheta(i,2), NumberOfNodesInGroup(i) + 2);
        ChannelsOfThisGroup = ismember(aNames, sGroups(i).RowNames);
        Index = find(ChannelsOfThisGroup) + NumberOfAgregatingNodes;
        [posX,posY] = pol2cart(LocalTheta(2:end-1),1);
        Vertices(Index,1:2) = [posX' posY'] * DisplayLevel(1);
        Vertices(Index,3) = 0;
        
        for y=2:Level
            Path = Paths{Index(1)};
            RegionIndex = Path(y);
            if (NumberOfNodesInGroup(i) == 1)
                Mean = [posX posY];
            else
                Mean = mean([posX' posY']);
            end
            Mean = Mean / norm(Mean);
            Vertices(RegionIndex,1:2) = Mean * DisplayLevel(y);
            Vertices(RegionIndex,3) = 0;
        end
    end
end
