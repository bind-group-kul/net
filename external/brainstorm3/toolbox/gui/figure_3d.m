function varargout = figure_3d( varargin )
% FIGURE_3d: Creation and callbacks for 3D visualization figures.
%
% USAGE: 
%        [hFig] = figure_3d('CreateFigure',               FigureId)
%                 figure_3d('ColormapChangedCallback',    iDS, iFig)    
%                 figure_3d('FigureClickCallback',        hFig, event)  
%                 figure_3d('FigureMouseMoveCallback',    hFig, event)  
%                 figure_3d('FigureMouseUpCallback',      hFig, event)  
%                 figure_3d('FigureMouseWheelCallback',   hFig, event)  
%                 figure_3d('FigureKeyPressedCallback',   hFig, keyEvent)   
%                 figure_3d('ResetView',                  hFig)
%                 figure_3d('SetStandardView',            hFig, viewNames)
%                 figure_3d('DisplayFigurePopup',         hFig)
%                 figure_3d('UpdateSurfaceColor',    hFig, iTess)
%                 figure_3d('ViewSensors',           hFig, isMarkers, isLabels, isMesh=1, Modality=[])
%                 figure_3d('ViewAxis',              hFig, isVisible)
%     [hFig,hs] = figure_3d('PlotSurface',           hFig, faces, verts, cdata, dataCMap, transparency)

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
function hFig = CreateFigure(FigureId) %#ok<DEFNU>
    % Get renderer name
    if (bst_get('DisableOpenGL') == 1)
        rendererName = 'zbuffer';
    else
        rendererName = 'opengl';
    end

    % === CREATE FIGURE ===
    hFig = figure('Visible',       'off', ...
                  'NumberTitle',   'off', ...
                  'IntegerHandle', 'off', ...
                  'MenuBar',       'none', ...
                  'Toolbar',       'none', ...
                  'DockControls',  'on', ...
                  'Units',         'pixels', ...
                  'Color',         [0 0 0], ...
                  'Tag',           FigureId.Type, ...
                  'Renderer',      rendererName, ...
                  'CloseRequestFcn',       @(h,ev)bst_figures('DeleteFigure',h,ev), ...
                  'KeyPressFcn',           @(h,ev)bst_call(@FigureKeyPressedCallback,h,ev), ...
                  'WindowButtonDownFcn',   @FigureClickCallback, ...
                  'WindowButtonMotionFcn', @FigureMouseMoveCallback, ...
                  'WindowButtonUpFcn',     @FigureMouseUpCallback, ...
                  'ResizeFcn',             @ResizeCallback, ...
                  'BusyAction',    'queue', ...
                  'Interruptible', 'off');   
    % Define Mouse wheel callback separately (not supported by old versions of Matlab)
    if isprop(hFig, 'WindowScrollWheelFcn')
        set(hFig, 'WindowScrollWheelFcn',  @FigureMouseWheelCallback, ...
                  'KeyReleaseFcn',         @FigureKeyReleasedCallback);
    end
    
    % === CREATE AXES ===
    hAxes = axes('Parent',   hFig, ...
                 'Units',    'normalized', ...
                 'Position', [.05 .05 .9 .9], ...
                 'Tag',      'Axes3D', ...
                 'Visible',  'off', ...
                 'BusyAction',    'queue', ...
                 'Interruptible', 'off');
    axis vis3d
    axis equal 
    axis off
         
    % === APPDATA STRUCTURE ===
    setappdata(hFig, 'Surface',     repmat(db_template('TessInfo'), 0));
    setappdata(hFig, 'iSurface',    []);
    setappdata(hFig, 'StudyFile',   []);   
    setappdata(hFig, 'SubjectFile', []);      
    setappdata(hFig, 'DataFile',    []); 
    setappdata(hFig, 'ResultsFile', []);
    setappdata(hFig, 'isSelectingCorticalSpot', 0);
    setappdata(hFig, 'isSelectingCoordinates',  0);
    setappdata(hFig, 'isControlKeyDown', false);
    setappdata(hFig, 'isShiftKeyDown', false);
    setappdata(hFig, 'hasMoved',    0);
    setappdata(hFig, 'isPlotEditToolbar',   0);
    setappdata(hFig, 'AllChannelsDisplayed', 0);
    setappdata(hFig, 'ChannelsToSelect', []);
    setappdata(hFig, 'FigureId', FigureId);
    setappdata(hFig, 'isStatic', 0);
    setappdata(hFig, 'isStaticFreq', 1);
    setappdata(hFig, 'Colormap', db_template('ColormapInfo'));

    % === LIGHTING ===
    hl = [];
    % Fixed lights
    hl(1) = camlight(  0,  40, 'infinite');
    hl(2) = camlight(180,  40, 'infinite');
    hl(3) = camlight(  0, -90, 'infinite');
    hl(4) = camlight( 90,   0, 'infinite');
    hl(5) = camlight(-90,   0, 'infinite');
    % Moving camlight
    hl(6) = light('Tag', 'FrontLight', 'Color', [1 1 1], 'Style', 'infinite', 'Parent', hAxes);
    camlight(hl(6), 'headlight');
    % Mute the intensity of the lights
    for i = 1:length(hl)
        set(hl(i), 'color', .4*[1 1 1]);
    end
    % Camera basic orientation
    SetStandardView(hFig, 'top');
end


%% =========================================================================================
%  ===== FIGURE CALLBACKS ==================================================================
%  =========================================================================================  
%% ===== COLORMAP CHANGED =====
% Usage:  ColormapChangedCallback(iDS, iFig)
function ColormapChangedCallback(iDS, iFig) %#ok<DEFNU>
    global GlobalData;
    hFig = GlobalData.DataSet(iDS).Figure(iFig).hFigure;
    % Update surfaces
    panel_surface('UpdateSurfaceColormap', hFig);
    % Update dipoles
    if ~isempty(getappdata(hFig, 'Dipoles')) && gui_brainstorm('isTabVisible', 'Dipoles')
        panel_dipoles('PlotSelectedDipoles', hFig);
    end
end


%% ===== RESIZE CALLBACK =====
function ResizeCallback(hFig, ev)
    % Get colorbar and axes handles
    hColorbar = findobj(hFig, '-depth', 1, 'Tag', 'Colorbar');
    hAxes     = findobj(hFig, '-depth', 1, 'Tag', 'Axes3D');
    if isempty(hAxes)
        return
    end
    hAxes = hAxes(1);
    % Get figure position and size in pixels
    figPos = get(hFig, 'Position');
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
        % Reposition the axes
        marginAxes = 10;
        set(hAxes, 'Units',    'pixels', ...
                   'Position', [marginAxes, ...
                                marginAxes, ...
                                figPos(3) - colorbarWidth - marginAxes, ... % figPos(3) - colorbarWidth - marginWidth - marginAxes, ...
                                max(1, figPos(4) - 2*marginAxes)]);
    % No colorbar : data axes can take all the figure space
    else
        % Reposition the axes
        set(hAxes, 'Units',    'normalized', ...
                   'Position', [.05, .05, .9, .9]);
    end
end
    
%% =========================================================================================
%  ===== KEYBOARD AND MOUSE CALLBACKS ======================================================
%  =========================================================================================
% Complete mouse and keyboard management over the main axes
% Supports : - Customized 3D-Rotation (LEFT click)
%            - Pan (SHIFT+LEFT click, OR MIDDLE click
%            - Zoom (CTRL+LEFT click, OR RIGHT click, OR WHEEL)
%            - Colorbar contrast/brightness
%            - Restore original view configuration (DOUBLE click)

%% ===== FIGURE CLICK CALLBACK =====
function FigureClickCallback(hFig, varargin)
    % Get selected object in this figure
    hObj = get(hFig,'CurrentObject');
    % Find axes
    hAxes = findobj(hFig, '-depth', 1, 'Tag', 'Axes3D');
    if isempty(hAxes)
        warning('Brainstorm:NoAxes', 'Axes could not be found');
        return;
    end
    % Get figure type
    FigureId = getappdata(hFig, 'FigureId');
    % Double click: reset view           
    if strcmpi(get(hFig, 'SelectionType'), 'open')
        ResetView(hFig);
    end
    % Check if MouseUp was executed before MouseDown
    if isappdata(hFig, 'clickAction') && strcmpi(getappdata(hFig,'clickAction'), 'MouseDownNotConsumed')
        % Should ignore this MouseDown event
        setappdata(hFig,'clickAction','MouseDownOk');
        return;
    end
   
    % Start an action (pan, zoom, rotate, contrast, luminosity)
    % Action depends on : 
    %    - the mouse button that was pressed (LEFT/RIGHT/MIDDLE), 
    %    - the keys that the user presses simultaneously (SHIFT/CTRL)
    clickAction = '';
    switch(get(hFig, 'SelectionType'))
        % Left click
        case 'normal'
            % 2DLayout: pan
            if strcmpi(FigureId.SubType, '2DLayout')
                clickAction = 'pan';
            % 2D: nothing
            elseif ismember(FigureId.SubType, {'2DDisc', '2DSensorCap'})
                % Nothing to do
            % Else (3D): rotate
            else
                clickAction = 'rotate';
            end
        % CTRL+Mouse, or Mouse right
        case 'alt'
            clickAction = 'popup';
        % SHIFT+Mouse, or Mouse middle
        case 'extend'
            clickAction = 'pan';
    end
    
    % Record action to perform when the mouse is moved
    setappdata(hFig, 'clickAction', clickAction);
    setappdata(hFig, 'clickSource', hFig);
    setappdata(hFig, 'clickObject', hObj);
    % Reset the motion flag
    setappdata(hFig, 'hasMoved', 0);
    % Record mouse location in the figure coordinates system
    setappdata(hFig, 'clickPositionFigure', get(hFig, 'CurrentPoint'));
    % Record mouse location in the axes coordinates system
    setappdata(hFig, 'clickPositionAxes', get(hAxes, 'CurrentPoint'));
end

    
%% ===== FIGURE MOVE =====
function FigureMouseMoveCallback(hFig, varargin)  
    % Get axes handle
    hAxes = findobj(hFig, '-depth', 1, 'tag', 'Axes3D');
    % Get current mouse action
    clickAction = getappdata(hFig, 'clickAction');   
    clickSource = getappdata(hFig, 'clickSource');   
    % If no action is currently performed
    if isempty(clickAction)
        return
    end
    % If MouseUp was executed before MouseDown
    if strcmpi(clickAction, 'MouseDownNotConsumed') || isempty(getappdata(hFig, 'clickPositionFigure'))
        % Ignore Move event
        return
    end
    % If source is not the same as the current figure: fire mouse up event
    if (clickSource ~= hFig)
        FigureMouseUpCallback(hFig);
        FigureMouseUpCallback(clickSource);
        return
    end

    % Set the motion flag
    setappdata(hFig, 'hasMoved', 1);
    % Get current mouse location in figure
    curptFigure = get(hFig, 'CurrentPoint');
    motionFigure = 0.3 * (curptFigure - getappdata(hFig, 'clickPositionFigure'));
    % Get current mouse location in axes
    curptAxes = get(hAxes, 'CurrentPoint');
    oldptAxes = getappdata(hFig, 'clickPositionAxes');
    if isempty(oldptAxes)
        return
    end
    motionAxes = curptAxes - oldptAxes;
    % Update click point location
    setappdata(hFig, 'clickPositionFigure', curptFigure);
    setappdata(hFig, 'clickPositionAxes',   curptAxes);
    % Get figure size
    figPos = get(hFig, 'Position');
       
    % Switch between different actions (Pan, Rotate, Zoom, Contrast)
    switch(clickAction)              
        case 'rotate'
            % Else : ROTATION
            % Rotation functions : 5 different areas in the figure window
            %     ,---------------------------.
            %     |             2             |
            % .75 |---------------------------| 
            %     |   3  |      5      |  4   |   
            %     |      |             |      | 
            % .25 |---------------------------| 
            %     |             1             |
            %     '---------------------------'
            %           .25           .75
            %
            % ----- AREA 1 -----
            if (curptFigure(2) < .25 * figPos(4))
                camroll(hAxes, motionFigure(1));
                camorbit(hAxes, 0,-motionFigure(2), 'camera');
            % ----- AREA 2 -----
            elseif (curptFigure(2) > .75 * figPos(4))
                camroll(hAxes, -motionFigure(1));
                camorbit(hAxes, 0,-motionFigure(2), 'camera');
            % ----- AREA 3 -----
            elseif (curptFigure(1) < .25 * figPos(3))
                camroll(hAxes, -motionFigure(2));
                camorbit(hAxes, -motionFigure(1),0, 'camera');
            % ----- AREA 4 -----
            elseif (curptFigure(1) > .75 * figPos(3))
                camroll(hAxes, motionFigure(2));
                camorbit(hAxes, -motionFigure(1),0, 'camera');
            % ----- AREA 5 -----
            else
                camorbit(hAxes, -motionFigure(1),-motionFigure(2), 'camera');
            end
            camlight(findobj(hAxes, '-depth', 1, 'Tag', 'FrontLight'), 'headlight');

        case 'pan'
            % Get camera textProperties
            pos    = get(hAxes, 'CameraPosition');
            up     = get(hAxes, 'CameraUpVector');
            target = get(hAxes, 'CameraTarget');
            % Calculate a normalised right vector
            right = cross(up, target - pos);
            up    = up ./ realsqrt(sum(up.^2));
            right = right ./ realsqrt(sum(right.^2));
            % Calculate new camera position and camera target
            panFactor = 0.001;
            pos    = pos    + panFactor .* (motionFigure(1).*right - motionFigure(2).*up);
            target = target + panFactor .* (motionFigure(1).*right - motionFigure(2).*up);
            set(hAxes, 'CameraPosition', pos, 'CameraTarget', target);

        case 'zoom'
            if (motionFigure(2) == 0)
                return;
            elseif (motionFigure(2) < 0)
                % ZOOM IN
                Factor = 1-motionFigure(2)./100;
            elseif (motionFigure(2) > 0)
                % ZOOM OUT
                Factor = 1./(1+motionFigure(2)./100);
            end
            zoom(hFig, Factor);
            
        case {'moveSlices', 'popup'}
            FigureId = getappdata(hFig, 'FigureId');
            % TOPO: Select channels
            if strcmpi(FigureId.Type, 'Topography') && ismember(FigureId.SubType, {'2DLayout', '2DDisc', '2DSensorCap'});
                % Get current point
                curPt = curptAxes(1,:);
                % Limit selection to current display
                curPt(1) = bst_saturate(curPt(1), get(hAxes, 'XLim'));
                curPt(2) = bst_saturate(curPt(2), get(hAxes, 'YLim'));
                if ~isappdata(hFig, 'patchSelection')
                    % Set starting position
                    setappdata(hFig, 'patchSelection', curPt);
                    % Draw patch
                    hSelPatch = patch('XData', curptAxes(1) * [1 1 1 1], ...
                                      'YData', curptAxes(2) * [1 1 1 1], ...
                                      'ZData', .0001 * [1 1 1 1], ...
                                      'LineWidth', 1, ...
                                      'FaceColor', [1 0 0], ...
                                      'FaceAlpha', 0.3, ...
                                      'EdgeColor', [1 0 0], ...
                                      'EdgeAlpha', 1, ...
                                      'BackfaceLighting', 'lit', ...
                                      'Tag',       'TopoSelectionPatch', ...
                                      'Parent',    hAxes);
                else
                    % Get starting position
                    startPt = getappdata(hFig, 'patchSelection');
                    % Update patch position
                    hSelPatch = findobj(hAxes, '-depth', 1, 'Tag', 'TopoSelectionPatch');
                    % Set new patch position
                    set(hSelPatch, 'XData', [startPt(1), curPt(1),   curPt(1), startPt(1)], ...
                                   'YData', [startPt(2), startPt(2), curPt(2), curPt(2)]);
                end
            % MRI: Move slices
            else
                % Get MRI
                [sMri,TessInfo,iTess] = panel_surface('GetSurfaceMri', hFig);
                if isempty(iTess)
                    return
                end

                % === DETECT ACTION ===
                % Is moving axis and direction are not detected yet : do it
                if (~isappdata(hFig, 'moveAxis') || ~isappdata(hFig, 'moveDirection'))
                    % Guess which cut the user is trying to change
                    % Sometimes some problem occurs, leading to values > 800
                    % for a 1-pixel movement => ignoring
                    if (max(motionAxes(1,:)) > 20)
                        return;
                    end
                    % Convert MRI-CS -> SCS
                    motionAxes = motionAxes * sMri.SCS.R;
                    % Get the maximum deplacement as the direction
                    [value, moveAxis] = max(abs(motionAxes(1,:)));
                    moveAxis = moveAxis(1);
                    % Get the directions of the mouse deplacement that will
                    % increase or decrease the value of the slice
                    [value, moveDirection] = max(abs(motionFigure));                   
                    moveDirection = sign(motionFigure(moveDirection(1))) .* ...
                                    sign(motionAxes(1,moveAxis)) .* ...
                                    moveDirection(1);
                    % Save the detected movement direction and orientation
                    setappdata(hFig, 'moveAxis',      moveAxis);
                    setappdata(hFig, 'moveDirection', moveDirection);

                % === MOVE SLICE ===
                else                
                    % Get saved information about current motion
                    moveAxis      = getappdata(hFig, 'moveAxis');
                    moveDirection = getappdata(hFig, 'moveDirection');
                    % Get the motion value
                    val = sign(moveDirection) .* motionFigure(abs(moveDirection));
                    % Get the new position of the slice
                    oldPos = TessInfo(iTess).CutsPosition(moveAxis);
                    newPos = round(bst_saturate(oldPos + val, [1 size(sMri.Cube, moveAxis)]));

                    % Plot a patch that indicates the location of the cut
                    PlotSquareCut(hFig, TessInfo(iTess), moveAxis, newPos);

                    % Draw a new X-cut according to the mouse motion
                    posXYZ = [NaN, NaN, NaN];
                    posXYZ(moveAxis) = newPos;
                    panel_surface('PlotMri', hFig, posXYZ);
                end
            end
    
        case 'colorbar'
            % Delete legend
            % delete(findobj(hFig, 'Tag', 'ColorbarHelpMsg'));
            % Get colormap type
            ColormapInfo = getappdata(hFig, 'Colormap');
            % Changes contrast
            sColormap = bst_colormaps('ColormapChangeModifiers', ColormapInfo.Type, [motionFigure(1), motionFigure(2)] ./ 100, 0);
            set(hFig, 'Colormap', sColormap.CMap);
    end
end

                
%% ===== FIGURE MOUSE UP =====        
function FigureMouseUpCallback(hFig, varargin)
    global GlobalData gChanAlign;
    % === 3DViz specific commands ===
    % Get application data (current user/mouse actions)
    clickAction = getappdata(hFig, 'clickAction');
    clickObject = getappdata(hFig, 'clickObject');
    hasMoved    = getappdata(hFig, 'hasMoved');
    hAxes       = findobj(hFig, '-depth', 1, 'tag', 'Axes3D');
    isSelectingCorticalSpot = getappdata(hFig, 'isSelectingCorticalSpot');
    isSelectingCoordinates  = getappdata(hFig, 'isSelectingCoordinates');
    TfInfo = getappdata(hFig, 'Timefreq');
    
    % Remove mouse appdata (to stop movements first)
    setappdata(hFig, 'hasMoved', 0);
    if isappdata(hFig, 'clickPositionFigure')
        rmappdata(hFig, 'clickPositionFigure');
    end
    if isappdata(hFig, 'clickPositionAxes')
        rmappdata(hFig, 'clickPositionAxes');
    end
    if isappdata(hFig, 'clickAction')
        rmappdata(hFig, 'clickAction');
    else
        setappdata(hFig, 'clickAction', 'MouseDownNotConsumed');
    end
    if isappdata(hFig, 'moveAxis')
        rmappdata(hFig, 'moveAxis');
    end
    if isappdata(hFig, 'moveDirection')
        rmappdata(hFig, 'moveDirection');
    end
    if isappdata(hFig, 'patchSelection')
        rmappdata(hFig, 'patchSelection');
    end
    % Remove SquareCut objects
    PlotSquareCut(hFig);
    % Get figure description
    [hFig, iFig, iDS] = bst_figures('GetFigure', hFig);
    if isempty(iDS)
        return
    end
    Figure = GlobalData.DataSet(iDS).Figure(iFig);
    % Update figure selection
    if strcmpi(Figure.Id.Type, '3DViz') || strcmpi(Figure.Id.SubType, '3DSensorCap')
        bst_figures('SetCurrentFigure', hFig, '3D');
    else
        bst_figures('SetCurrentFigure', hFig, '2D');
    end
    if isappdata(hFig, 'Timefreq') && ~isempty(getappdata(hFig, 'Timefreq'))
        bst_figures('SetCurrentFigure', hFig, 'TF');
    end
    
    % ===== SIMPLE CLICK ===== 
    % If user did not move the mouse since the click
    if ~hasMoved
        % === POPUP ===
        if strcmpi(clickAction, 'popup')
            DisplayFigurePopup(hFig);
            
        % === SELECTING CORTICAL SCOUTS ===
        elseif isSelectingCorticalSpot
            panel_scout('CreateScoutMouse', hFig);
            
        % === SELECTING POINT (COORDINATES PANEL) ===
        elseif isSelectingCoordinates
            if gui_brainstorm('isTabVisible', 'Coordinates')
                panel_coordinates('SelectPoint', hFig);
            end
            
        % === TIME-FREQ CORTICAL POINT ===
        % SHIFT + CLICK: Display time-frequency map for the selected dipole
        elseif ~isempty(TfInfo) && ~isempty(TfInfo.FileName) && strcmpi(Figure.Id.Type, '3DViz') && strcmpi(get(hFig, 'SelectionType'), 'extend')
            % Get selected vertex
            iVertex = panel_coordinates('SelectPoint', hFig, 0);
            % Show time-frequency decomposition for this source
            if ~isempty(iVertex)
                if ~isempty(strfind(TfInfo.FileName, '_psd')) || ~isempty(strfind(TfInfo.FileName, '_fft'))
                    view_spectrum(TfInfo.FileName, 'Spectrum', iVertex, 1);
                elseif ~isempty(strfind(TfInfo.FileName, '_pac_fullmaps'))
                    view_pac(TfInfo.FileName, iVertex, 'PAC', [], 1);
                elseif ~isempty(strfind(TfInfo.FileName, '_pac'))
                    % Nothing
                else
                    view_timefreq(TfInfo.FileName, 'SingleSensor', iVertex, 1);
                end
            end
            
        % === SELECTING SCOUT ===
        elseif ~isempty(clickObject) && ismember(get(clickObject,'Tag'), {'ScoutPatch', 'ScoutContour', 'ScoutMarker'})
            % Get scouts display options
            ScoutsOptions = panel_scout('GetScoutsOptions');
            % Display/hide scouts
            if strcmpi(ScoutsOptions.showSelection, 'all')
                % Find the selected scout
                [sScout, iScout] = panel_scout('GetScoutWithHandle', clickObject);
                % If a scout was found: select it in the list
                if ~isempty(iScout)
                    panel_scout('SetSelectedScouts', iScout);
                end
            end
            
        % === SELECTING SENSORS ===
        else
            iSelChan = [];
            % Check if sensors are displayed in this figure
            hSensorsPatch = findobj(hAxes, '-depth', 1, 'Tag', 'SensorsPatch');
            if (length(hSensorsPatch) == 1)
                % Select the nearest sensor from the mouse
                [p, v, vi] = select3d(hSensorsPatch);
                % If sensor index is not valid
                if isempty(vi) || (vi > length(Figure.SelectedChannels)) || (vi <= 0)
                    return
                end
                % If clicked point is too far away (5mm) from the closest sensor
                % (Do not test Topography figures)
                if ~strcmpi(Figure.Id.Type, 'Topography')
                    if (norm(p - v) > 0.005)
                        return
                    end
                end
                % Is figure used only to display channels
                AllChannelsDisplayed = getappdata(hFig, 'AllChannelsDisplayed');
                % If not all the channels are displayed: need to convert the selected sensor indice
                if ~AllChannelsDisplayed
                    % Get channel indice (in Channel array)
                    iSelChan = Figure.SelectedChannels(vi);
                else
                    AllModalityChannels = good_channel(GlobalData.DataSet(iDS).Channel, [], Figure.Id.Modality);
                    iSelChan = AllModalityChannels(vi);
                end
            end
            
            % Check if sensors where marked to be selected somewhere else in the code
            if isempty(iSelChan)
                iSelChan = getappdata(hFig, 'ChannelsToSelect');
            end
            % Reset this field
            setappdata(hFig, 'ChannelsToSelect', []);
            
            % Select sensor
            if ~isempty(iSelChan)
                % Get channel names
                SelChan = {GlobalData.DataSet(iDS).Channel(iSelChan).Name};
                % SHIFT + CLICK: Display time-frequency map for the sensor
                if strcmpi(get(hFig, 'SelectionType'), 'extend')
                    % Select only the last sensor
                    bst_figures('SetSelectedRows', SelChan);
                    % Time-freq: view a the sensor in a separate figure
                    if ~isempty(TfInfo) && ~isempty(TfInfo.FileName)
                        if ~isempty(strfind(TfInfo.FileName, '_pac_fullmaps'))
                            view_pac(TfInfo.FileName, SelChan);
                        elseif ~isempty(strfind(TfInfo.FileName, '_pac'))
                            % Nothing
                        elseif ~isempty(strfind(TfInfo.FileName, '_psd')) || ~isempty(strfind(TfInfo.FileName, '_fft'))
                            view_spectrum(TfInfo.FileName, 'Spectrum', SelChan, 1);
                        else
                            view_timefreq(TfInfo.FileName, 'SingleSensor', SelChan{1}, 0);
                        end
                    end
                % CLICK: Normally select/unselect sensor
                else
                    % If user is editing/moving sensors: select only the new sensor
                    if ~isempty(gChanAlign) && ~gChanAlign.isMeg && isequal(gChanAlign.selectedButton, gChanAlign.hButtonMoveChan)
                        bst_figures('SetSelectedRows', SelChan);
                    else
                        bst_figures('ToggleSelectedRow', SelChan);
                    end
                end
            end
        end
    % ===== MOUSE HAS MOVED ===== 
    else
        % === COLORMAP HAS CHANGED ===
        if strcmpi(clickAction, 'colorbar')
            % Apply new colormap to all figures
            ColormapInfo = getappdata(hFig, 'Colormap');
            bst_colormaps('FireColormapChanged', ColormapInfo.Type);
            
        % === RIGHT-CLICK + MOVE ===
        elseif strcmpi(clickAction, 'popup')
            % === TOPO: Select channels ===
            if strcmpi(Figure.Id.Type, 'Topography') && ismember(Figure.Id.SubType, {'2DLayout', '2DDisc', '2DSensorCap'});
                % Get selection patch
                hSelPatch = findobj(hAxes, '-depth', 1, 'Tag', 'TopoSelectionPatch');
                if isempty(hSelPatch)
                    return
                elseif (length(hSelPatch) > 1)
                    delete(hSelPatch);
                    return
                end
                % Get selection rectangle
                XBounds = get(hSelPatch, 'XData');
                YBounds = get(hSelPatch, 'YData');
                XBounds = [min(XBounds), max(XBounds)];
                YBounds = [min(YBounds), max(YBounds)];
                % Delete selection patch
                delete(hSelPatch);
                % Find all the sensors that are in that selection rectangle
                if strcmpi(Figure.Id.SubType, '2DLayout')
                    channelLoc = GlobalData.DataSet(iDS).Figure(iFig).Handles.BoxesCenters;
                else
                    channelLoc = GlobalData.DataSet(iDS).Figure(iFig).Handles.MarkersLocs;
                end
                iChannels = find((channelLoc(:,1) >= XBounds(1)) & (channelLoc(:,1) <= XBounds(2)) & ...
                                 (channelLoc(:,2) >= YBounds(1)) & (channelLoc(:,2) <= YBounds(2)));
                % Convert to real channel indices
                iChannels = GlobalData.DataSet(iDS).Figure(iFig).SelectedChannels(iChannels);
                ChannelNames = {GlobalData.DataSet(iDS).Channel(iChannels).Name};
                % Select those channels
                bst_figures('SetSelectedRows', ChannelNames);
                
            % === SLICES WERE MOVED ===
            else
                % Update "Surfaces" panel
                panel_surface('UpdateSurfaceProperties');       
            end
        end
    end 
end


%% ===== FIGURE MOUSE WHEEL =====
function FigureMouseWheelCallback(hFig, event)  
    % ONLY FOR 3D AND 2DLayout
    if isempty(event)
        return;
    elseif (event.VerticalScrollCount < 0)
        % ZOOM IN
        Factor = 1 - event.VerticalScrollCount ./ 20;
    elseif (event.VerticalScrollCount > 0)
        % ZOOM OUT
        Factor = 1./(1 + event.VerticalScrollCount ./ 20);
    end
    % Get figure type
    FigureId = getappdata(hFig, 'FigureId');
    % 2D Layout
    if strcmpi(FigureId.SubType, '2DLayout') 
        % SHIFT + Wheel: Change the channel gain
        if getappdata(hFig, 'isShiftKeyDown')
            figure_topo('UpdateTimeSeriesFactor', hFig, Factor);
        % CONTROL + Wheel: Change the time window
        elseif getappdata(hFig, 'isControlKeyDown')
            figure_topo('UpdateTopoTimeWindow', hFig, Factor);
        % Wheel: Just zoom (like in regular figures)
        else
            zoom(Factor);
        end
    % Else: zoom
    else
        zoom(Factor);
    end
end


%% ===== KEYBOARD CALLBACK =====
function FigureKeyPressedCallback(hFig, keyEvent)   
    global GlobalData TimeSliderMutex;
    % If shift is already pressed, no need to process the "shift" press again
    if (getappdata(hFig, 'isShiftKeyDown') && strcmpi(keyEvent.Key, 'shift')) || ...
       (getappdata(hFig, 'isControlKeyDown') && strcmpi(keyEvent.Key, 'control'))     
        return
    end
    % Prevent multiple executions
    hAxes = findobj(hFig, '-depth', 1, 'Tag', 'Axes3D');
    set([hFig hAxes], 'BusyAction', 'cancel');
    % Get figure description
    [hFig, iFig, iDS] = bst_figures('GetFigure', hFig);
    if isempty(hFig)
        return
    end
    FigureId = GlobalData.DataSet(iDS).Figure(iFig).Id;
    % ===== GET SELECTED CHANNELS =====
    % Get selected channels
    [SelChan, iSelChan] = GetFigSelectedRows(hFig);
    % Get if figure should contain all the modality sensors (display channel net)
    AllChannelsDisplayed = getappdata(hFig, 'AllChannelsDisplayed');
    % Check if it is a realignment figure
    isAlignFig = ~isempty(findobj(hFig, '-depth', 1, 'Tag', 'AlignToolbar'));
    % If figure is 2D
    is2D = ~strcmpi(FigureId.Type, '3DViz') && ~strcmpi(FigureId.SubType, '3DSensorCap');
    isRaw = strcmpi(GlobalData.DataSet(iDS).Measures.DataType, 'raw');
        
    % ===== PROCESS BY CHARACTERS =====
    switch (keyEvent.Character)
        % === NUMBERS : VIEW SHORTCUTS ===
        case '0'
            if ~isAlignFig && ~is2D
                SetStandardView(hFig, {'left', 'right', 'top'});
            end
        case '1'
            if ~is2D
                SetStandardView(hFig, 'left');
            end
        case '2'
            if ~is2D
                SetStandardView(hFig, 'bottom');
            end
        case '3'
            if ~is2D
                SetStandardView(hFig, 'right');
            end
        case '4'
            if ~is2D
                SetStandardView(hFig, 'front');
            end
        case '5'
            if ~is2D
                SetStandardView(hFig, 'top');
            end
        case '6'
            if ~is2D
                SetStandardView(hFig, 'back');
            end
        case '7'
            if ~isAlignFig && ~is2D
                SetStandardView(hFig, {'left', 'right'});
            end
        case '8'
            if ~isAlignFig && ~is2D
                SetStandardView(hFig, {'bottom', 'top'});
            end
        case '9'
            if ~isAlignFig && ~is2D
                SetStandardView(hFig, {'front', 'back'});      
            end
        case '.'
            if ~isAlignFig && ~is2D
                SetStandardView(hFig, {'left', 'right', 'top', 'left_intern', 'right_intern', 'bottom'});
            end
        case {'=', 'equal'}
            if ~isAlignFig && ~is2D
                ApplyViewToAllFigures(hFig, 1, 1);
            end
        case '*'
            if ~isAlignFig && ~is2D
                ApplyViewToAllFigures(hFig, 0, 1);
            end
        % === SCOUTS : GROW/SHRINK ===
        case '+'
            panel_scout('EditScoutsSize', 'Grow1');
        case '-'
            panel_scout('EditScoutsSize', 'Shrink1');
                                   
        otherwise
            % ===== PROCESS BY KEYS =====
            switch (keyEvent.Key)
                % === LEFT, RIGHT, PAGEUP, PAGEDOWN  ===
                case {'leftarrow', 'rightarrow', 'pageup', 'pagedown', 'home', 'end'}
                    if isempty(TimeSliderMutex) || ~TimeSliderMutex
                        panel_time('TimeKeyCallback', keyEvent);
                    end
                    
                % === UP DOWN : Processed by Freq panel ===
                case {'uparrow', 'downarrow'}
                    panel_freq('FreqKeyCallback', keyEvent);
                % === DATABASE NAVIGATOR ===
                case {'f1', 'f2', 'f3', 'f4'}
                    if ~isAlignFig 
                        if isRaw
                            panel_time('TimeKeyCallback', keyEvent);
                        else
                            bst_figures('NavigatorKeyPress', hFig, keyEvent);
                        end
                    end
                % === DATA FILES ===
                % CTRL+A : View axis
                case 'a'
                    if ismember('control', keyEvent.Modifier)
                    	ViewAxis(hFig);
                    end 
                % CTRL+D : Dock figure
                case 'd'
                    if ismember('control', keyEvent.Modifier)
                        isDocked = strcmpi(get(hFig, 'WindowStyle'), 'docked');
                        bst_figures('DockFigure', hFig, ~isDocked);
                    end
                % CTRL+E : Sensors and labels
                case 'e'
                    if ~isAlignFig && ismember('control', keyEvent.Modifier)
                        hLabels = findobj(hAxes, '-depth', 1, 'Tag', 'SensorsLabels');
                        isMarkers = ~isempty(findobj(hAxes, '-depth', 1, 'Tag', 'SensorsPatch')) || ~isempty(findobj(hAxes, '-depth', 1, 'Tag', 'SensorsMarkers'));
                        isLabels  = ~isempty(hLabels);
                        % All figures, except "2DLayout"
                        if ~strcmpi(FigureId.SubType, '2DLayout')
                            % Cycle between three modes : Nothing, Sensors, Sensors+labels
                            if isMarkers && isLabels
                                ViewSensors(hFig, 0, 0);
                            elseif isMarkers
                                ViewSensors(hFig, 1, 1);
                            else
                                ViewSensors(hFig, 1, 0);
                            end
                        % "2DLayout"
                        else
                            isLabelsVisible = strcmpi(get(hLabels(1), 'Visible'), 'on');
                            if isLabelsVisible
                                set(hLabels, 'Visible', 'off');
                            else
                                set(hLabels, 'Visible', 'on');
                            end
                        end
                    end
                % CTRL+I : Save as image
                case 'i'
                    if ismember('control', keyEvent.Modifier)
                        out_figure_image(hFig);
                    end
                % CTRL+J : Open as image
                case 'j'
                    if ismember('control', keyEvent.Modifier)
                        out_figure_image(hFig, 'Viewer');
                    end
                % CTRL+R : Recordings time series
                case 'r'
                    if ismember('control', keyEvent.Modifier) && ~isempty(GlobalData.DataSet(iDS).DataFile)
                        view_timeseries(GlobalData.DataSet(iDS).DataFile, FigureId.Modality);
                    end
                % CTRL+S : Sources (first results file)
                case 's'
                    if ismember('control', keyEvent.Modifier)
                        bst_figures('ViewResults', hFig); 
                    end
                % CTRL+T : Default topography
                case 't'
                    if ismember('control', keyEvent.Modifier) 
                        bst_figures('ViewTopography', hFig); 
                    end
                    
                % === CHANNELS ===
                % RETURN: VIEW SELECTED CHANNELS
                case 'return'
                    if ~isAlignFig && ~isempty(SelChan) && ~AllChannelsDisplayed
                        if isempty(getappdata(hFig, 'Timefreq'))
                            figure_timeseries('DisplayDataSelectedChannels', iDS, SelChan, FigureId.Modality);
                        end
                    end
                % DELETE: SET CHANNELS AS BAD
                case 'delete'
                    if ~isAlignFig && ~isempty(SelChan) && ~AllChannelsDisplayed && ~isempty(GlobalData.DataSet(iDS).DataFile) && ...
                            (length(GlobalData.DataSet(iDS).Figure(iFig).SelectedChannels) ~= length(iSelChan))
                        % Shift+Delete: Mark non-selected as bad
                        newChannelFlag = GlobalData.DataSet(iDS).Measures.ChannelFlag;
                        if ismember('shift', keyEvent.Modifier)
                            newChannelFlag(GlobalData.DataSet(iDS).Figure(iFig).SelectedChannels) = -1;
                            newChannelFlag(iSelChan) = 1;
                        % Delete: Mark selected channels as bad
                        else
                            newChannelFlag(iSelChan) = -1;
                        end
                        % Update channel flage
                        panel_channel_editor('UpdateChannelFlag', GlobalData.DataSet(iDS).DataFile, newChannelFlag);
                        % Reset selection
                        bst_figures('SetSelectedRows', []);
                    end
                % ESCAPE: RESET SELECTION
                case 'escape'
                    % Remove selection cross
                    delete(findobj(hAxes, '-depth', 1, 'tag', 'ptCoordinates'));
                    % Channel selection
                    if ~isAlignFig 
                        % Mark all channels as good
                        if ismember('shift', keyEvent.Modifier)
                            ChannelFlagGood = ones(size(GlobalData.DataSet(iDS).Measures.ChannelFlag));
                            panel_channel_editor('UpdateChannelFlag', GlobalData.DataSet(iDS).DataFile, ChannelFlagGood);
                        % Reset channel selection
                        else
                            bst_figures('SetSelectedRows', []);
                        end
                    end
                % CONTROL: SAVE BUTTON PRESS
                case 'control'
                    setappdata(hFig, 'isControlKeyDown', true);
                % SHIFT: SAVE BUTTON PRESS
                case 'shift'
                    setappdata(hFig, 'isShiftKeyDown', true);
            end
    end
    % Restore events
    if ~isempty(hFig) && ishandle(hFig) && ~isempty(hAxes) && ishandle(hAxes)
        set([hFig hAxes], 'BusyAction', 'queue');
    end
end


%% ===== KEYBOARD CALLBACK: RELEASE =====
function FigureKeyReleasedCallback(hFig, keyEvent)
    % Process event
    % Alter the behavior of the mouse wheel scroll so as that CTRL+Scroll
    % changes the vertical scale instead of the horizontal one 
    setappdata(hFig, 'isControlKeyDown', false);
    setappdata(hFig, 'isShiftKeyDown', false);
end


%% ===== RESET VIEW =====
% Restore initial camera position and orientation
function ResetView(hFig)
    zoom out
    % Get Axes handle
    hAxes = findobj(hFig, '-depth', 1, 'Tag', 'Axes3D');
    set(hFig, 'CurrentAxes', hAxes);
    % Camera basic orientation
    SetStandardView(hFig, 'top');
    % Try to find a light source. If found, align it with the camera
    camlight(findobj(hAxes, '-depth', 1, 'Tag', 'FrontLight'), 'headlight');
end


%% ===== SET STANDARD VIEW =====
function SetStandardView(hFig, viewNames)
    % Make sure that viewNames is a cell array
    if ischar(viewNames)
        viewNames = {viewNames};
    end
    % Get Axes handle
    hAxes = findobj(hFig, '-depth', 1, 'Tag', 'Axes3D');
    % Get the data types displayed in this figure
    ColormapInfo = getappdata(hFig, 'Colormap');
    % Get surface information
    TessInfo = getappdata(hFig, 'Surface');

    % ===== ANATOMY ORIENTATION =====
    % If MRI displayed in the figure, use the orientation of the slices, instead of the orientation of the axes
    R = eye(3);
    % Get the mri surface
    Ranat = [];
    if ismember('anatomy', ColormapInfo.AllTypes)
        iTess = find(strcmpi({TessInfo.Name}, 'Anatomy'));
        if ~isempty(iTess)
            % Get the subject MRI structure in memory
            sMri = bst_memory('GetMri', TessInfo(iTess).SurfaceFile);
            % Calculate transformation: SCS => MRI  (inverse MRI => SCS)
            Ranat = pinv(sMri.SCS.R);
        end
    end
    % Displaying a surface: Load the SCS field from the MRI
    if isempty(Ranat) && ~isempty(TessInfo) && ~isempty(TessInfo(1).SurfaceFile)
        % Get subject
        sSubject = bst_get('SurfaceFile', TessInfo(1).SurfaceFile);
        % If there is an MRI associated with it
        if ~isempty(sSubject) && ~isempty(sSubject.Anatomy) && ~isempty(sSubject.Anatomy(sSubject.iAnatomy).FileName)
            sMri = load(file_fullpath(sSubject.Anatomy(sSubject.iAnatomy).FileName), 'NCS', 'SCS', 'Comment');
            if isfield(sMri, 'NCS') && ~isempty(sMri.NCS) && ~isempty(sMri.NCS.AC) && ~isempty(sMri.NCS.PC) && ~isempty(sMri.NCS.IH) && ...
               isfield(sMri, 'SCS') && ~isempty(sMri.SCS) && ~isempty(sMri.SCS.R)
                % Calculate the MRI => MNI transformation
                mniTransf = cs_mri2mni(sMri);
                % Calculate the SCS => MNI transformation   (inverse MRI=>SCS * MRI=>MNI)
                if ~isempty(mniTransf) && ~isempty(mniTransf.R)
                    Ranat = mniTransf.R * pinv(sMri.SCS.R);
                end
            end
        end
    end
    % Get the rotation to change orientation
    if ~isempty(Ranat)
        R = [0 1 0;-1 0 0; 0 0 1] * Ranat;
    end    
    
    % ===== MOVE CAMERA =====
    % Apply the first orientation to the target figure
    switch lower(viewNames{1})
        case {'left', 'right_intern'}
            newView = [0,1,0];
            newCamup = [0 0 1];
        case {'right', 'left_intern'}
            newView = [0,-1,0];
            newCamup = [0 0 1];
        case 'back'
            newView = [-1,0,0];
            newCamup = [0 0 1];
        case 'front'
            newView = [1,0,0];
            newCamup = [0 0 1];
        case 'bottom'
            newView = [0,0,-1];
            newCamup = [1 0 0];
        case 'top'
            newView = [0,0,1];
            newCamup = [1 0 0];
    end
    % Update camera position
    view(hAxes, newView * R);
    camup(hAxes, double(newCamup * R));
    % Update head light position
    camlight(findobj(hAxes, '-depth', 1, 'Tag', 'FrontLight'), 'headlight');
    % Select only one hemisphere
    if any(ismember(viewNames, {'right_intern', 'left_intern'}))
        bst_figures('SetCurrentFigure', hFig, '3D');
        drawnow;
        if strcmpi(viewNames{1}, 'right_intern')
            panel_surface('SelectHemispheres', 'right');
        elseif strcmpi(viewNames{1}, 'left_intern')
            panel_surface('SelectHemispheres', 'left');
        else
            panel_surface('SelectHemispheres', 'none');
        end
    end
    
    % ===== OTHER FIGURES =====
    % If there are other view to represent
    if (length(viewNames) > 1)
        hClones = bst_figures('GetClones', hFig);
        % Process the other required views
        for i = 2:length(viewNames)
            if ~isempty(hClones)
                % Use an already cloned figure
                hNewFig = hClones(1);
                hClones(1) = [];
            else
                % Clone figure
                hNewFig = bst_figures('CloneFigure', hFig);
            end
            % Set orientation
            SetStandardView(hNewFig, viewNames(i));
        end
        % If there are some cloned figures left : close them
        if ~isempty(hClones)
            close(hClones);
            % Update figures layout
            gui_layout('Update');
        end
    end
end


%% ===== GET COORDINATES =====
function GetCoordinates(varargin)
    % Show Coordinates panel
    gui_show('panel_coordinates', 'JavaWindow', 'Get coordinates', [], 0, 1, 0);
    % Start point selection
    panel_coordinates('SetSelectionState', 1);
end


%% ===== APPLY VIEW TO ALL FIGURES =====
function ApplyViewToAllFigures(hSrcFig, isView, isSurfProp)
    % Get Axes handle
    hSrcAxes = findobj(hSrcFig, '-depth', 1, 'Tag', 'Axes3D');
    % Get surface descriptions
    SrcTessInfo = getappdata(hSrcFig, 'Surface');
    % Get all figures
    hAllFig = bst_figures('GetFiguresByType', '3DViz');
    hAllFig = setdiff(hAllFig, hSrcFig);
    % Process all figures
    for i = 1:length(hAllFig)
        % Get Axes handle
        hDestFig = hAllFig(i);
        hDestAxes = findobj(hDestFig, '-depth', 1, 'Tag', 'Axes3D');
        % === COPY CAMERA ===
        if isView
            % Copy view angle
            [az,el] = view(hSrcAxes);
            view(hDestAxes, az, el);
            % Copy camup
            up = camup(hSrcAxes);
            camup(hDestAxes, up);
            % Update head light position
            camlight(findobj(hDestAxes, '-depth', 1, 'Tag', 'FrontLight'), 'headlight');
        end
        
        % === COPY SURFACES PROPERTIES ===
        if isSurfProp
            DestTessInfo = getappdata(hDestFig, 'Surface');
            % Process each surface of the figure
            for iTess = 1:length(DestTessInfo)
                % Find surface name in source figure
                iTessInSrc = find(strcmpi(DestTessInfo(iTess).Name, {SrcTessInfo.Name}));
                % If surface is also available in source figure
                if ~isempty(iTessInSrc)
                    % Copy surf properties
                    iTessInSrc = iTessInSrc(1);
                    DestTessInfo(iTess).SurfAlpha        = SrcTessInfo(iTessInSrc).SurfAlpha;
                    DestTessInfo(iTess).SurfShowSulci    = SrcTessInfo(iTessInSrc).SurfShowSulci;
                    DestTessInfo(iTess).SurfShowEdges    = SrcTessInfo(iTessInSrc).SurfShowEdges;
                    DestTessInfo(iTess).AnatomyColor     = SrcTessInfo(iTessInSrc).AnatomyColor;
                    DestTessInfo(iTess).SurfSmoothValue  = SrcTessInfo(iTessInSrc).SurfSmoothValue;                    
                    DestTessInfo(iTess).CutsPosition     = SrcTessInfo(iTessInSrc).CutsPosition;
                    DestTessInfo(iTess).Resect           = SrcTessInfo(iTessInSrc).Resect;
                    DestTessInfo(iTess).DataAlpha        = SrcTessInfo(iTessInSrc).DataAlpha;
                    DestTessInfo(iTess).SizeThreshold    = SrcTessInfo(iTessInSrc).SizeThreshold;
                    % Do not update data threshold for stat surfaces (has to remain 0)
                    if ~isempty(DestTessInfo(iTess).DataSource.FileName) && ~ismember(file_gettype(DestTessInfo(iTess).DataSource.FileName), {'pdata','presults','ptimfreq','pmatrix'})
                        DestTessInfo(iTess).DataThreshold    = SrcTessInfo(iTessInSrc).DataThreshold;
                    end

                    % Update surfaces structure
                    setappdata(hDestFig, 'Surface', DestTessInfo);
                    % Update display
                    if strcmpi(DestTessInfo(iTess).Name, 'Anatomy')
                        UpdateMriDisplay(hDestFig, [], DestTessInfo, iTess);
                    else
                        UpdateSurfaceAlpha(hDestFig, iTess);
                        UpdateSurfaceColor(hDestFig, iTess);
                    end
                    % Update scouts displayed on this surfce
                    panel_scout('UpdateScoutsVertices', DestTessInfo(iTess).SurfaceFile);
                end
            end
        end
    end
end


%% ===== POPUP MENU =====
% Show a popup dialog about the target 3DViz figure
function DisplayFigurePopup(hFig)
    import java.awt.event.KeyEvent;
    import javax.swing.KeyStroke;
    import org.brainstorm.icon.*;
    
    global GlobalData;
    % Get figure description
    [hFig, iFig, iDS] = bst_figures('GetFigure', hFig);
    if isempty(iDS)
        return
    end
    % Get DataFile associated with this figure
    DataFile    = GlobalData.DataSet(iDS).DataFile;
    ResultsFile = getappdata(hFig, 'ResultsFile');
    Dipoles     = getappdata(hFig, 'Dipoles');
    % Get surfaces information
    TessInfo = getappdata(hFig, 'Surface');
    % Get time freq information
    TfInfo = getappdata(hFig, 'Timefreq');
    if ~isempty(TfInfo)
        TfFile = TfInfo.FileName;
    else
        TfFile = [];
    end

    % Create popup menu
    jPopup = java_create('javax.swing.JPopupMenu');
    % Get selected channels
    [SelChan, iSelChan] = GetFigSelectedRows(hFig);   
    
    % ==== DISPLAY OTHER FIGURES ====
    if ~isempty(TfFile)
        % Get selected vertex
        iVertex = panel_coordinates('SelectPoint', hFig, 0);
        % Menu for selected vertex
        if ~isempty(iVertex)
            if isempty(strfind(TfFile, '_psd')) && isempty(strfind(TfFile, '_fft')) && isempty(strfind(TfFile, '_pac'))
                jItem = gui_component('MenuItem', jPopup, [], 'Source: Time-frequency', IconLoader.ICON_TIMEFREQ, [], @(h,ev)bst_call(@view_timefreq, TfFile, 'SingleSensor', iVertex, 1));
                jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_SHIFT, 0));
                gui_component('MenuItem', jPopup, [], 'Source: Time series',    IconLoader.ICON_DATA,     [], @(h,ev)bst_call(@view_spectrum, TfFile, 'TimeSeries', iVertex, 1));
            end
            if isempty(strfind(TfFile, '_pac'))
                gui_component('MenuItem', jPopup, [], 'Source: Power spectrum', IconLoader.ICON_SPECTRUM, [], @(h,ev)bst_call(@view_spectrum, TfFile, 'Spectrum', iVertex, 1));
            end
            if ~isempty(strfind(TfFile, '_pac_fullmaps'))
                jItem = gui_component('MenuItem', jPopup, [], 'Sensor PAC map', IconLoader.ICON_PAC, [], @(h,ev)view_pac(TfFile, iVertex, 'DynamicPAC', [], 1));
                jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_SHIFT, 0));
            end
            if (jPopup.getComponentCount() > 0)
                jPopup.addSeparator();
            end
        end
    end
    % Only for MEG and EEG time series
    Modality = GlobalData.DataSet(iDS).Figure(iFig).Id.Modality;  
    FigureType = GlobalData.DataSet(iDS).Figure(iFig).Id.Type;  
    if ~isempty(DataFile)
        % Get study
        sStudy = bst_get('AnyFile', DataFile);
        % === View RECORDINGS ===
        jItem = gui_component('MenuItem', jPopup, [], [Modality ' Recordings'], IconLoader.ICON_TS_DISPLAY, [], @(h,ev)view_timeseries(DataFile));
        jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_R, KeyEvent.CTRL_MASK));
        % === View TOPOGRAPHY ===
        if isempty(TfFile) && ~strcmpi(FigureType, 'Topography')
            jItem = gui_component('MenuItem', jPopup, [], [Modality ' Topography'], IconLoader.ICON_TOPOGRAPHY, [], @(h,ev)bst_figures('ViewTopography',hFig));
            jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_T, KeyEvent.CTRL_MASK));
        end
        % === View SOURCES ===
        if isempty(TfFile) && isempty(ResultsFile) && ~isempty(sStudy.Result)
            jItem = gui_component('MenuItem', jPopup, [], 'View sources', IconLoader.ICON_RESULTS, [], @(h,ev)bst_figures('ViewResults',hFig));
            jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_S, KeyEvent.CTRL_MASK));
        end
        % === VIEW PAC/TIME-FREQ ===
        if strcmpi(FigureType, 'Topography') && ~isempty(SelChan) && ~isempty(Modality) && (Modality(1) ~= '$')
            if ~isempty(strfind(TfFile, '_pac_fullmaps'))
                jItem = gui_component('MenuItem', jPopup, [], 'Sensor PAC map', IconLoader.ICON_PAC, [], @(h,ev)view_pac(TfFile, SelChan{1}));
                jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_SHIFT, 0));
            elseif ~isempty(strfind(TfFile, '_pac'))
                % Nothing
            elseif ~isempty(strfind(TfFile, '_psd')) || ~isempty(strfind(TfFile, '_fft'))
                jItem = gui_component('MenuItem', jPopup, [], 'Sensor spectrum', IconLoader.ICON_SPECTRUM, [], @(h,ev)view_spectrum(TfFile, 'Spectrum', SelChan{1}, 1));
                jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_SHIFT, 0));
            else
                jItem = gui_component('MenuItem', jPopup, [], 'Sensor time-freq map', IconLoader.ICON_TIMEFREQ, [], @(h,ev)view_timefreq(TfFile, 'SingleSensor', SelChan{1}, 0));
                jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_SHIFT, 0));
            end
        end
        jPopup.addSeparator();
    end

    % ==== MENU 2DLAYOUT ====
    if strcmpi(FigureType, 'Topography') && strcmpi(GlobalData.DataSet(iDS).Figure(iFig).Id.SubType, '2DLayout')
        % Get current options
        TopoLayoutOptions = bst_get('TopoLayoutOptions');
        % Create menu
        jMenu = gui_component('Menu', jPopup, [], '2DLayout options', IconLoader.ICON_2DLAYOUT, [], [], []);
        gui_component('MenuItem', jMenu, [], 'Set time window...', [], [], @(h,ev)figure_topo('SetTopoLayoutOptions', 'TimeWindow'));
        jItem = gui_component('CheckBoxMenuItem', jMenu, [], 'White background', [], [], @(h,ev)figure_topo('SetTopoLayoutOptions', 'WhiteBackground', ~TopoLayoutOptions.WhiteBackground));
        jItem.setSelected(TopoLayoutOptions.WhiteBackground);
        jItem = gui_component('CheckBoxMenuItem', jMenu, [], 'Show reference lines', [], [], @(h,ev)figure_topo('SetTopoLayoutOptions', 'ShowRefLines', ~TopoLayoutOptions.ShowRefLines));
        jItem.setSelected(TopoLayoutOptions.ShowRefLines);
        jItem = gui_component('CheckBoxMenuItem', jMenu, [], 'Show legend', [], [], @(h,ev)figure_topo('SetTopoLayoutOptions', 'ShowLegend', ~TopoLayoutOptions.ShowLegend));
        jItem.setSelected(TopoLayoutOptions.ShowLegend);
        jPopup.addSeparator();
    end
    
    % ==== MENU CONTOUR LINES =====
    if strcmpi(FigureType, 'Topography') && ismember(GlobalData.DataSet(iDS).Figure(iFig).Id.SubType, {'2DSensorCap', '2DDisc'})
        % Get current options
        TopoLayoutOptions = bst_get('TopoLayoutOptions');
        % Create menu
        jMenu = gui_component('Menu', jPopup, [], 'Contour lines', IconLoader.ICON_TOPOGRAPHY, [], [], []);
        jItem = gui_component('CheckBoxMenuItem', jMenu, [], 'No contour lines', [], [], @(h,ev)figure_topo('SetTopoLayoutOptions', 'ContourLines', 0));
        jItem.setSelected(TopoLayoutOptions.ContourLines == 0);
        jItem = gui_component('CheckBoxMenuItem', jMenu, [], '5 lines', [], [], @(h,ev)figure_topo('SetTopoLayoutOptions', 'ContourLines', 5));
        jItem.setSelected(TopoLayoutOptions.ContourLines == 5);
        jItem = gui_component('CheckBoxMenuItem', jMenu, [], '10 lines', [], [], @(h,ev)figure_topo('SetTopoLayoutOptions', 'ContourLines', 10));
        jItem.setSelected(TopoLayoutOptions.ContourLines == 10);
        jItem = gui_component('CheckBoxMenuItem', jMenu, [], '15 lines', [], [], @(h,ev)figure_topo('SetTopoLayoutOptions', 'ContourLines', 15));
        jItem.setSelected(TopoLayoutOptions.ContourLines == 15);
        jItem = gui_component('CheckBoxMenuItem', jMenu, [], '20 lines', [], [], @(h,ev)figure_topo('SetTopoLayoutOptions', 'ContourLines', 20));
        jItem.setSelected(TopoLayoutOptions.ContourLines == 20);
        jPopup.addSeparator();
    end
    
    % ==== CHANNELS MENU =====
    % Check if it is a realignment figure
    isAlignFig = ~isempty(findobj(hFig, '-depth', 1, 'Tag', 'AlignToolbar'));
    % Not for align figures
    if ~isAlignFig && ~isempty(GlobalData.DataSet(iDS).ChannelFile)
        jMenuChannels = gui_component('Menu', jPopup, [], 'Channels', IconLoader.ICON_CHANNEL, [], [], []);
        % ==== Selected channels submenu ====
        isMarkers = ~isempty(GlobalData.DataSet(iDS).Figure(iFig).Handles.hSensorMarkers) || ...
                    strcmpi(GlobalData.DataSet(iDS).Figure(iFig).Id.SubType, '2DLayout');
        % Excludes figures without selection and display-only figures (modality name starts with '$')
        if ~isempty(DataFile) && isMarkers && ~isempty(SelChan) && ~isempty(Modality) && (Modality(1) ~= '$')
            % === VIEW TIME SERIES ===
            jItem = gui_component('MenuItem', jMenuChannels, [], 'View selected', IconLoader.ICON_TS_DISPLAY, [], @(h,ev)figure_timeseries('DisplayDataSelectedChannels', iDS, SelChan, Modality), []);
            jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_ENTER, 0)); % ENTER
            % === SET SELECTED AS BAD CHANNELS ===
            newChannelFlag = GlobalData.DataSet(iDS).Measures.ChannelFlag;
            newChannelFlag(iSelChan) = -1;
            jItem = gui_component('MenuItem', jMenuChannels, [], 'Mark selected as bad', IconLoader.ICON_BAD, [], @(h,ev)panel_channel_editor('UpdateChannelFlag', DataFile, newChannelFlag), []);
            jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_DELETE, 0)); % DEL
            % === SET NON-SELECTED AS BAD CHANNELS ===
            newChannelFlag = GlobalData.DataSet(iDS).Measures.ChannelFlag;
            newChannelFlag(GlobalData.DataSet(iDS).Figure(iFig).SelectedChannels) = -1;
            newChannelFlag(iSelChan) = 1;
            jItem = gui_component('MenuItem', jMenuChannels, [], 'Mark non-selected as bad', IconLoader.ICON_BAD, [], @(h,ev)panel_channel_editor('UpdateChannelFlag', DataFile, newChannelFlag), []);
            jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_DELETE, KeyEvent.SHIFT_MASK));
            % === RESET SELECTION ===
            jItem = gui_component('MenuItem', jMenuChannels, [], 'Reset selection', IconLoader.ICON_SURFACE, [], @(h,ev)bst_figures('SetSelectedRows', []), []);
            jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_ESCAPE, 0)); % ESCAPE
        end
        % Separator if previous items
        if (jMenuChannels.getItemCount() > 0)
            jMenuChannels.addSeparator();
        end
        
        % ==== CHANNEL FLAG =====
        if ~isempty(DataFile) && isMarkers
            % ==== MARK ALL CHANNELS AS GOOD ====
            ChannelFlagGood = ones(size(GlobalData.DataSet(iDS).Measures.ChannelFlag));
            jItem = gui_component('MenuItem', jMenuChannels, [], 'Mark all channels as good', IconLoader.ICON_GOOD, [], @(h, ev)panel_channel_editor('UpdateChannelFlag', GlobalData.DataSet(iDS).DataFile, ChannelFlagGood), []);
            jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_ESCAPE, KeyEvent.SHIFT_MASK));
            % ==== EDIT CHANNEL FLAG ====
            gui_component('MenuItem', jMenuChannels, [], 'Edit good/bad channels...', IconLoader.ICON_GOODBAD, [], @(h,ev)gui_edit_channelflag(DataFile), []);
        end
        % Separator if previous items
        if (jMenuChannels.getItemCount() > 0)
            jMenuChannels.addSeparator();
        end
        
        % ==== View Sensors ====
        % Not for 2DLayout
        if ~strcmpi(GlobalData.DataSet(iDS).Figure(iFig).Id.SubType, '2DLayout')
            % Menu "View sensors"
            jItem = gui_component('CheckBoxMenuItem', jMenuChannels, [], 'Display sensors', IconLoader.ICON_CHANNEL, [], @(h,ev)ViewSensors(hFig, ~isMarkers, []), []);
            jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_E, KeyEvent.CTRL_MASK));
            jItem.setSelected(isMarkers);
            % Menu "View sensor labels"
            isLabels = ~isempty(GlobalData.DataSet(iDS).Figure(iFig).Handles.hSensorLabels);
            jItem = gui_component('CheckBoxMenuItem', jMenuChannels, [], 'Display labels', IconLoader.ICON_CHANNEL_LABEL, [], @(h,ev)ViewSensors(hFig, [], ~isLabels), []);
            jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_E, KeyEvent.CTRL_MASK));
            jItem.setSelected(isLabels);
        else
            % Menu "View sensor labels"
            isLabels = ~isempty(GlobalData.DataSet(iDS).Figure(iFig).Handles.hSensorLabels);
            if isLabels
                % Get current state
                isLabelsVisible = strcmpi(get(GlobalData.DataSet(iDS).Figure(iFig).Handles.hSensorLabels(1), 'Visible'), 'on');
                if isLabelsVisible
                    targetVisible = 'off';
                else
                    targetVisible = 'on';
                end
                % Create menu
                jItem = gui_component('CheckBoxMenuItem', jMenuChannels, [], 'Display labels', IconLoader.ICON_CHANNEL_LABEL, [], @(h,ev)set(GlobalData.DataSet(iDS).Figure(iFig).Handles.hSensorLabels, 'Visible', targetVisible), []);
                jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_E, KeyEvent.CTRL_MASK));
                jItem.setSelected(isLabelsVisible);
            end
        end
    end
    
    % ==== Menu colormaps ====
    % Create the colormaps menus
    bst_colormaps('CreateAllMenus', jPopup, hFig);
    
    % ==== Maximum Intensity Projection ====
    ColormapInfo = getappdata(hFig, 'Colormap');
    if ismember('anatomy', ColormapInfo.AllTypes)
        jMenuMri = gui_component('Menu', jPopup, [], 'MRI display', IconLoader.ICON_ANATOMY, [], [], []);
        MriOptions = bst_get('MriOptions');
        % MIP: Anatomy
        jItem = gui_component('CheckBoxMenuItem', jMenuMri, [], 'MIP: Anatomy', [], [], @(h,ev)MipAnatomy_Callback(hFig,ev), []);
        jItem.setSelected(MriOptions.isMipAnatomy);
        % MIP: Functional
        isOverlay = any(ismember({'source','stat1','stat2','timefreq'}, ColormapInfo.AllTypes));
        if isOverlay
            jItem = gui_component('checkboxmenuitem', jMenuMri, [], 'MIP: Functional', [], [], @(h,ev)MipFunctional_Callback(hFig,ev), []);
            jItem.setSelected(MriOptions.isMipFunctional);
        end
        % Smooth factor
        if isOverlay
            jMenuMri.addSeparator();
            jItem0 = gui_component('radiomenuitem', jMenuMri, [], 'Smooth: None', [], [], @(h,ev)SetMriSmooth(hFig, 0), []);
            jItem1 = gui_component('radiomenuitem', jMenuMri, [], 'Smooth: 1',    [], [], @(h,ev)SetMriSmooth(hFig, 1), []);
            jItem2 = gui_component('radiomenuitem', jMenuMri, [], 'Smooth: 2',    [], [], @(h,ev)SetMriSmooth(hFig, 2), []);
            jItem3 = gui_component('radiomenuitem', jMenuMri, [], 'Smooth: 3',    [], [], @(h,ev)SetMriSmooth(hFig, 3), []);
            jItem4 = gui_component('radiomenuitem', jMenuMri, [], 'Smooth: 4',    [], [], @(h,ev)SetMriSmooth(hFig, 4), []);
            jItem5 = gui_component('radiomenuitem', jMenuMri, [], 'Smooth: 5',    [], [], @(h,ev)SetMriSmooth(hFig, 5), []);
            jItem0.setSelected(MriOptions.OverlaySmooth == 0);
            jItem1.setSelected(MriOptions.OverlaySmooth == 1);
            jItem2.setSelected(MriOptions.OverlaySmooth == 2);
            jItem3.setSelected(MriOptions.OverlaySmooth == 3);
            jItem4.setSelected(MriOptions.OverlaySmooth == 4);
            jItem5.setSelected(MriOptions.OverlaySmooth == 5);
        end
    end
%     % Separator
%     if (jPopup.getComponentCount() > 0)
%         jPopup.addSeparator();
%     end
    
    % ==== Navigation submenu ====
    if ~isempty(DataFile) && ~strcmpi(GlobalData.DataSet(iDS).Measures.DataType, 'raw')
        jMenuNavigator = gui_component('Menu', jPopup, [], 'Navigator', IconLoader.ICON_NEXT_SUBJECT, [], [], []);
        bst_navigator('CreateNavigatorMenu', jMenuNavigator);
        jPopup.addSeparator();        
    end
    
    % ==== MENU GET COORDINATES ====
    if ~strcmpi(FigureType, 'Topography')
        gui_component('MenuItem', jPopup, [], 'Get coordinates...', IconLoader.ICON_SCOUT_NEW, [], @GetCoordinates, []);
    end
    
    % ==== Menu SNAPSHOT ====
    jMenuSave = gui_component('Menu', jPopup, [], 'Snapshot', IconLoader.ICON_SNAPSHOT, [], [], []);
        % Default output dir
        LastUsedDirs = bst_get('LastUsedDirs');
        DefaultOutputDir = LastUsedDirs.ExportImage;
        % Is there a time window defined
        isTime = ~isempty(GlobalData) && ~isempty(GlobalData.UserTimeWindow.CurrentTime) ...
                  && ~isempty(GlobalData.UserTimeWindow.Time) && (~isempty(DataFile) || ~isempty(ResultsFile) || ~isempty(Dipoles));
        % === SAVE AS IMAGE ===
        jItem = gui_component('MenuItem', jMenuSave, [], 'Save as image', IconLoader.ICON_SAVE, [], @(h,ev)out_figure_image(hFig), []);
        jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_I, KeyEvent.CTRL_MASK));
        % === OPEN AS IMAGE ===
        jItem = gui_component('MenuItem', jMenuSave, [], 'Open as image', IconLoader.ICON_IMAGE, [], @(h,ev)out_figure_image(hFig, 'Viewer'), []);
        jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_J, KeyEvent.CTRL_MASK));
        % === SAVE SURFACE ===
        if ~isempty(TessInfo)
            if ~isempty([TessInfo.hPatch]) && any([TessInfo.nVertices] > 5)
                jMenuSave.addSeparator();
            end
            % Loop on all the surfaces
            for it = 1:length(TessInfo)
                if ~isempty(TessInfo(it).SurfaceFile) && ~isempty(TessInfo(it).hPatch) && (TessInfo(it).nVertices > 5)
                    jItem = gui_component('MenuItem', jMenuSave, [], ['Save surface: ' TessInfo(it).Name], IconLoader.ICON_SAVE, [], @(h,ev)SaveSurface(TessInfo(it)));
                end
            end
        end
        % === MOVIES ===
        % WARNING: Windows ONLY (for the moment)
        % And NOT for 2DLayout figures
        if exist('avifile', 'file') && ~strcmpi(GlobalData.DataSet(iDS).Figure(iFig).Id.SubType, '2DLayout')
            % Separator
            jMenuSave.addSeparator();
            % === MOVIE (TIME) ===
            if isTime
                gui_component('MenuItem', jMenuSave, [], 'Movie (time): Selected figure', IconLoader.ICON_MOVIE, [], @(h,ev)out_figure_movie(hFig, DefaultOutputDir, 'time'), []);
                gui_component('MenuItem', jMenuSave, [], 'Movie (time): All figures',     IconLoader.ICON_MOVIE, [], @(h,ev)out_figure_movie(hFig, DefaultOutputDir, 'allfig'), []);
            end
            % If not topography
            if ~strcmpi(FigureType, 'Topography')
                if isTime
                    jMenuSave.addSeparator();
                end
                % === MOVIE (HORIZONTAL) ===
                gui_component('MenuItem', jMenuSave, [], 'Movie (horizontal)', IconLoader.ICON_MOVIE, [], @(h,ev)out_figure_movie(hFig, DefaultOutputDir, 'horizontal'), []);
                % === MOVIE (VERTICAL) ===
                gui_component('MenuItem', jMenuSave, [], 'Movie (vertical)', IconLoader.ICON_MOVIE, [], @(h,ev)out_figure_movie(hFig, DefaultOutputDir, 'vertical'), []);
            end
        end
        % === CONTACT SHEETS / TIME ===
        % If time, and if not 2DLayout
        if isTime && ~strcmpi(GlobalData.DataSet(iDS).Figure(iFig).Id.SubType, '2DLayout')
            jMenuSave.addSeparator();
            gui_component('MenuItem', jMenuSave, [], 'Time contact sheet: Figure', IconLoader.ICON_CONTACTSHEET, [], @(h,ev)view_contactsheet(hFig, 'time', 'fig', DefaultOutputDir), []);
        end
        % === CONTACT SHEET / SLICES ===
        if ismember('anatomy', ColormapInfo.AllTypes)
            if isTime
                jMenuSave.addSeparator();
                gui_component('MenuItem', jMenuSave, [], 'Time contact sheet: Coronal',  IconLoader.ICON_CONTACTSHEET, [], @(h,ev)view_contactsheet(hFig, 'time', 'y', DefaultOutputDir), []);
                gui_component('MenuItem', jMenuSave, [], 'Time contact sheet: Sagittal', IconLoader.ICON_CONTACTSHEET, [], @(h,ev)view_contactsheet(hFig, 'time', 'x', DefaultOutputDir), []);
                gui_component('MenuItem', jMenuSave, [], 'Time contact sheet: Axial',    IconLoader.ICON_CONTACTSHEET, [], @(h,ev)view_contactsheet(hFig, 'time', 'z', DefaultOutputDir), []);
            end
            jMenuSave.addSeparator();
            gui_component('MenuItem', jMenuSave, [], 'Volume contact sheet: Coronal',  IconLoader.ICON_CONTACTSHEET, [], @(h,ev)view_contactsheet(hFig, 'volume', 'y', DefaultOutputDir), []);
            gui_component('MenuItem', jMenuSave, [], 'Volume contact sheet: Sagittal', IconLoader.ICON_CONTACTSHEET, [], @(h,ev)view_contactsheet(hFig, 'volume', 'x', DefaultOutputDir), []);
            gui_component('MenuItem', jMenuSave, [], 'Volume contact sheet: Axial',    IconLoader.ICON_CONTACTSHEET, [], @(h,ev)view_contactsheet(hFig, 'volume', 'z', DefaultOutputDir), []);
        end
    
    % ==== Menu "Figure" ====
    jMenuFigure = gui_component('Menu', jPopup, [], 'Figure', IconLoader.ICON_LAYOUT_SHOWALL, [], [], []);
        % Show axes
        isAxis = ~isempty(findobj(hFig, 'Tag', 'AxisXYZ'));
        jItem = gui_component('CheckBoxMenuItem', jMenuFigure, [], 'View axis', IconLoader.ICON_AXES, [], @(h,ev)ViewAxis(hFig, ~isAxis), []);
        jItem.setSelected(isAxis);
        jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_A, KeyEvent.CTRL_MASK)); 
        % Show Head points
        isHeadPoints = ~isempty(GlobalData.DataSet(iDS).HeadPoints) && ~isempty(GlobalData.DataSet(iDS).HeadPoints.Loc);
        if isHeadPoints
            % Are head points visible
            hHeadPointsMarkers = findobj(GlobalData.DataSet(iDS).Figure(iFig).hFigure, 'Tag', 'HeadPointsMarkers');
            isVisible = ~isempty(hHeadPointsMarkers) && strcmpi(get(hHeadPointsMarkers, 'Visible'), 'on');
            jItem = gui_component('CheckBoxMenuItem', jMenuFigure, [], 'View head points', IconLoader.ICON_CHANNEL, [], @(h,ev)ViewHeadPoints(hFig, ~isVisible), []);
            jItem.setSelected(isVisible);
        end
        jMenuFigure.addSeparator();
        % Change background color
        gui_component('MenuItem', jMenuFigure, [], 'Change background color', IconLoader.ICON_COLOR_SELECTION, [], @(h,ev)bst_figures('ChangeBackgroundColor', hFig), []);
        jMenuFigure.addSeparator();
        % Show Matlab controls
        isMatlabCtrl = ~strcmpi(get(hFig, 'MenuBar'), 'none') && ~strcmpi(get(hFig, 'ToolBar'), 'none');
        jItem = gui_component('CheckBoxMenuItem', jMenuFigure, [], 'Matlab controls', IconLoader.ICON_MATLAB_CONTROLS, [], @(h,ev)bst_figures('ShowMatlabControls', hFig, ~isMatlabCtrl), []);
        jItem.setSelected(isMatlabCtrl);
        % Show plot edit toolbar
        isPlotEditToolbar = getappdata(hFig, 'isPlotEditToolbar');
        jItem = gui_component('CheckBoxMenuItem', jMenuFigure, [], 'Plot edit toolbar', IconLoader.ICON_PLOTEDIT, [], @(h,ev)bst_figures('TogglePlotEditToolbar', hFig), []);
        jItem.setSelected(isPlotEditToolbar);
        % Dock figure
        isDocked = strcmpi(get(hFig, 'WindowStyle'), 'docked');
        jItem = gui_component('CheckBoxMenuItem', jMenuFigure, [], 'Dock figure', IconLoader.ICON_DOCK, [], @(h,ev)bst_figures('DockFigure', hFig, ~isDocked), []);
        jItem.setSelected(isDocked);
        jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_D, KeyEvent.CTRL_MASK)); 

    % ==== Menu "Views" ====    
    % Not for Topography
    if ~strcmpi(FigureType, 'Topography')
        jMenuView = gui_component('Menu', jPopup, [], 'Views', IconLoader.ICON_AXES, [], [], []);
        % Check if it is a realignment figure
        isAlignFigure = ~isempty(findobj(hFig, 'Tag', 'AlignToolbar'));
        % STANDARD VIEWS
        jItemViewLeft   = gui_component('MenuItem', jMenuView, [], 'Left',   [], [], @(h,ev)SetStandardView(hFig, {'left'}), []);
        jItemViewBottom = gui_component('MenuItem', jMenuView, [], 'Bottom', [], [], @(h,ev)SetStandardView(hFig, {'bottom'}), []);
        jItemViewRight  = gui_component('MenuItem', jMenuView, [], 'Right',  [], [], @(h,ev)SetStandardView(hFig, {'right'}), []);
        jItemViewFront  = gui_component('MenuItem', jMenuView, [], 'Front',  [], [], @(h,ev)SetStandardView(hFig, {'front'}), []);
        jItemViewTop    = gui_component('MenuItem', jMenuView, [], 'Top',    [], [], @(h,ev)SetStandardView(hFig, {'top'}), []);
        jItemViewBack   = gui_component('MenuItem', jMenuView, [], 'Back',   [], [], @(h,ev)SetStandardView(hFig, {'back'}), []);
        % Keyboard shortcuts
        jItemViewLeft.setAccelerator(  KeyStroke.getKeyStroke('1', 0)); 
        jItemViewBottom.setAccelerator(KeyStroke.getKeyStroke('2', 0)); 
        jItemViewRight.setAccelerator( KeyStroke.getKeyStroke('3', 0));
        jItemViewFront.setAccelerator( KeyStroke.getKeyStroke('4', 0));
        jItemViewTop.setAccelerator(   KeyStroke.getKeyStroke('5', 0));
        jItemViewBack.setAccelerator(  KeyStroke.getKeyStroke('6', 0));
        % MULTIPLE VIEWS
        if ~isAlignFigure
            jItemViewLR     = gui_component('MenuItem', jMenuView, [], '[Left, Right]',              [], [], @(h,ev)SetStandardView(hFig, {'left', 'right'}), []);
            jItemViewTB     = gui_component('MenuItem', jMenuView, [], '[Top, Bottom]',              [], [], @(h,ev)SetStandardView(hFig, {'top', 'bottom'}), []);
            jItemViewFB     = gui_component('MenuItem', jMenuView, [], '[Front, Back]',              [], [], @(h,ev)SetStandardView(hFig, {'front','back'}), []);
            jItemViewLTR    = gui_component('MenuItem', jMenuView, [], '[Left, Top, Right]',         [], [], @(h,ev)SetStandardView(hFig, {'left', 'top', 'right'}), []);
            jItemViewLRIETB = gui_component('MenuItem', jMenuView, [], '[L/R, Int/Extern, Top/Bot]', [], [], @(h,ev)SetStandardView(hFig, {'left', 'right', 'top', 'left_intern', 'right_intern', 'bottom'}), []);
            % Keyboard shortcuts
            jItemViewLR.setAccelerator(    KeyStroke.getKeyStroke('7', 0));
            jItemViewTB.setAccelerator(    KeyStroke.getKeyStroke('8', 0));
            jItemViewFB.setAccelerator(    KeyStroke.getKeyStroke('9', 0));
            jItemViewLTR.setAccelerator(   KeyStroke.getKeyStroke('0', 0));
            jItemViewLRIETB.setAccelerator(KeyStroke.getKeyStroke('.', 0));
            % APPLY THRESHOLD TO ALL FIGURES
            jMenuView.addSeparator();
            if ismember('source', ColormapInfo.AllTypes)
                jItem = gui_component('MenuItem', jMenuView, [], 'Apply threshold to all figures', [], [], @(h,ev)ApplyViewToAllFigures(hFig, 0, 1), []);
                jItem.setAccelerator(KeyStroke.getKeyStroke('*', 0));
            end
            % SET SAME VIEW FOR ALL FIGURES
            jItem = gui_component('MenuItem', jMenuView, [], 'Apply this view to all figures', [], [], @(h,ev)ApplyViewToAllFigures(hFig, 1, 1), []);
            jItem.setAccelerator(KeyStroke.getKeyStroke('=', 0));
            % CLONE FIGURE
            jMenuView.addSeparator();
            gui_component('MenuItem', jMenuView, [], 'Clone figure', [], [], @(h,ev)bst_figures('CloneFigure', hFig), []);
        end
    end
    % ==== Display menu ====
    gui_popup(jPopup, hFig);
end


%% ===== FIGURE CONFIGURATION FUNCTIONS =====
% CHECKBOX: MIP ANATOMY
function MipAnatomy_Callback(hFig, ev)
    MriOptions = bst_get('MriOptions');
    MriOptions.isMipAnatomy = ev.getSource().isSelected();
    bst_set('MriOptions', MriOptions);
    bst_figures('FireCurrentTimeChanged', 1);
end
% CHECKBOX: MIP FUNCTIONAL
function MipFunctional_Callback(hFig, ev)
    MriOptions = bst_get('MriOptions');
    MriOptions.isMipFunctional = ev.getSource().isSelected();
    bst_set('MriOptions', MriOptions);
    bst_figures('FireCurrentTimeChanged', 1);
end
% RADIO: MRI SMOOTH
function SetMriSmooth(hFig, OverlaySmooth)
    MriOptions = bst_get('MriOptions');
    MriOptions.OverlaySmooth = OverlaySmooth;
    bst_set('MriOptions', MriOptions);
    bst_figures('FireCurrentTimeChanged', 1);
end


%% ==============================================================================================
%  ====== SURFACES ==============================================================================
%  ==============================================================================================           
%% ===== GET SELECTED ROWS =====
% USAGE:   [SelRows, iRows] = GetFigSelectedRows(hFig);
%           SelRows         = GetFigSelectedRows(hFig);
function [SelRows, iRows] = GetFigSelectedRows(hFig)
    global GlobalData;
    % Initialize retuned values
    SelRows = [];
    iRows = [];
    % Find figure
    [hFig, iFig, iDS] = bst_figures('GetFigure', hFig);
    % Get indices of the channels displayed in this figure
    iDispRows = GlobalData.DataSet(iDS).Figure(iFig).SelectedChannels;
    if isempty(iDispRows) || isempty(GlobalData.DataViewer.SelectedRows)
        return;
    end
    % Get all the sensors displayed in the figure
    DispRows = {GlobalData.DataSet(iDS).Channel(iDispRows).Name};
    % Get the general list of selected rows
    SelRows = intersect(GlobalData.DataViewer.SelectedRows, DispRows);
    % If required: get the indices
    if (nargout >= 2) && ~isempty(SelRows)
        % Find row indices in the full list
        for i = 1:length(SelRows)
            iRows = [iRows, iDispRows(strcmpi(SelRows{i}, DispRows))];
        end
    end
end
    
    
%% ===== GET SELECTED ROWS =====
% USAGE:   UpdateFigSelectedRows(iDS, iFig);
function UpdateFigSelectedRows(iDS, iFig)
    global GlobalData;
    % Get figure handles
    sHandles = GlobalData.DataSet(iDS).Figure(iFig).Handles;
    % If no sensor information: return
    iDispChan = GlobalData.DataSet(iDS).Figure(iFig).SelectedChannels;
    if isempty(iDispChan)
        return;
    end    
    % Get all the sensors displayed in the figure
    DispChan = {GlobalData.DataSet(iDS).Channel(iDispChan).Name};
    % Get the general list of selected rows
    SelChan = intersect(GlobalData.DataViewer.SelectedRows, DispChan);
    % Find row indices in the full list
    iSelChan = [];
    for i = 1:length(SelChan)
        iSelChan = [iSelChan, find(strcmpi(SelChan{i}, DispChan))];
    end
    % Compute the unselected channels
    iUnselChan = setdiff(1:length(iDispChan), iSelChan);
    
    % For 2D Layout figures only
    if strcmpi(GlobalData.DataSet(iDS).Figure(iFig).Id.SubType, '2DLayout')
        % Selected channels : Paint lines in red
        if ~isempty(iSelChan)
            set(sHandles.hLines(iSelChan), 'Color', 'r');
            set(sHandles.hSensorLabels(iSelChan), ...
                'Color',      [.2 1 .4], ...
                'FontUnits', 'points', ...
                'FontSize',   bst_get('FigFont') + 1, ...
                'FontWeight', 'bold');
        end
        % Deselected channels : Restore initial color
        if ~isempty(iUnselChan)
            set(sHandles.hLines(iUnselChan), 'Color', sHandles.LinesColor(1,:));
            set(sHandles.hSensorLabels(iUnselChan), ...
                'Color',      .8*[1 1 1], ...
                'FontUnits', 'points', ...
                'FontSize',   bst_get('FigFont'), ...
                'FontWeight', 'normal');
        end
    % All other 2D/3D figures
    else
        % If valid sensor markers exist 
        hMarkers = sHandles.hSensorMarkers;
        if ~isempty(hMarkers) && all(ishandle(hMarkers)) && strcmpi(get(hMarkers(1), 'Type'), 'patch')
            % Get the color of all the vertices
            VerticesColors = get(hMarkers, 'FaceVertexCData');
            % Update the vertices that changed
            if ~isempty(iSelChan)
                VerticesColors(iSelChan, :) = repmat([1 0.3 0], [length(iSelChan), 1]);
            end
            if ~isempty(iUnselChan)
                VerticesColors(iUnselChan, :) = repmat([1 1 1], [length(iUnselChan), 1]);
            end
            % Update patch object
            set(hMarkers, 'FaceVertexCData', VerticesColors);
        end
    end
end


%% ===== PLOT SURFACE =====
% Convenient function to consistently plot surfaces.
% USAGE : [hFig,hs] = PlotSurface(hFig, faces, verts, cdata, dataCMap, transparency)
% Parameters :
%     - hFig         : figure handle to use
%     - faces        : the triangle listing (array)
%     - verts        : the corresponding vertices (array)
%     - surfaceColor : color data used to display the surface itself (FaceVertexCData for each vertex, or a unique color for all vertices)
%     - dataColormap : colormap used to display the data on the surface
%     - transparency : surface transparency ([0,1])
% Returns :
%     - hFig : figure handle used
%     - hs   : handle to the surface
function varargout = PlotSurface( hFig, faces, verts, surfaceColor, transparency) %#ok<DEFNU>
    % Check inputs
    if (nargin ~= 5)
        error('Invalid call to PlotSurface');
    end
    % If vertices are assumed transposed (if the assumption is wrong, will crash below anyway)
    if (size(verts,2) > 3)
        verts = verts';
    end
    % If vertices are assumed transposed (if the assumption is wrong, will crash below anyway)
    if (size(faces,2) > 3)
        faces = faces';  
    end
    % Surface color
    if (length(surfaceColor) == 3)
        FaceVertexCData = [];
        FaceColor = surfaceColor;
        EdgeColor = 'none';
    elseif (length(surfaceColor) == length(verts))
        FaceVertexCData = surfaceColor;
        FaceColor = 'interp';
        EdgeColor = 'interp';
    else
        error('Invalid surface color.');
    end
    % Set figure as current
    set(0, 'CurrentFigure', hFig);
    
    % Create patch
    hs = patch('Faces',            faces, ...
               'Vertices',         verts,...
               'FaceVertexCData',  FaceVertexCData, ...
               'FaceColor',        FaceColor, ...
               'FaceAlpha',        1 - transparency, ...
               'AlphaDataMapping', 'none', ...
               'EdgeColor',        EdgeColor, ...
               'BackfaceLighting', 'lit');
    % Configure patch material
    material([ 0.5 0.50 0.20 1.00 0.5 ])
    lighting phong
    
    % Set output variables
    if(nargout>0),
        varargout{1} = hFig;
        varargout{2} = hs;
    end
end


%% ===== PLOT SQUARE/CUT =====
% USAGE:  PlotSquareCut(hFig, TessInfo, dim, pos)
%         PlotSquareCut(hFig)  : Remove all square cuts displayed
function PlotSquareCut(hFig, TessInfo, dim, pos)
    % Get figure description and MRI
    [hFig, iFig, iDS] = bst_figures('GetFigure', hFig);
    % Delete the previous patch
    delete(findobj(hFig, 'Tag', 'squareCut'));
    if (nargin < 4)
        return
    end
    hAxes  = findobj(hFig, '-depth', 1, 'tag', 'Axes3D');
    % Get maximum dimensions (MRI size)
    sMri = bst_memory('GetMri', TessInfo.SurfaceFile);
    mriSize = size(sMri.Cube);
    voxSize = sMri.Voxsize;

    % Get locations of the slice
    nbPts = 50;
    baseVect = linspace(-.01, 1.01, nbPts);
    switch(dim)
        case 1
            X = ones(nbPts)         .* (pos + 2)  .* voxSize(1); 
            Y = meshgrid(baseVect)  .* mriSize(2) .* voxSize(2);   
            Z = meshgrid(baseVect)' .* mriSize(3) .* voxSize(3); 
            surfColor = [1 .5 .5];
        case 2
            X = meshgrid(baseVect)  .* mriSize(1) .* voxSize(1); 
            Y = ones(nbPts)         .* (pos + 2)  .* voxSize(2) + .1;    
            Z = meshgrid(baseVect)' .* mriSize(3) .* voxSize(3); 
            surfColor = [.5 1 .5];
        case 3
            X = meshgrid(baseVect)  .* mriSize(1) .* voxSize(1); 
            Y = meshgrid(baseVect)' .* mriSize(2) .* voxSize(2); 
            Z = ones(nbPts)         .* (pos + 2)  .* voxSize(3) + .1;        
            surfColor = [.5 .5 1];
    end

    % === Switch coordinates from MRI-CS to SCS ===
    % Apply Rotation/Translation
    XYZ = [reshape(X, 1, []);
           reshape(Y, 1, []); 
           reshape(Z, 1, [])];
    XYZ = cs_mri2scs(sMri, XYZ);
    % Convert to millimeters
    XYZ = XYZ ./ 1000;

    % === PLOT SURFACE ===
    % Plot new surface  
    hCut = surface('XData',     reshape(XYZ(1,:),nbPts,nbPts), ...
                   'YData',     reshape(XYZ(2,:),nbPts,nbPts), ...
                   'ZData',     reshape(XYZ(3,:),nbPts,nbPts), ...
                   'CData',     ones(nbPts), ...
                   'FaceColor',        surfColor, ...
                   'FaceAlpha',        .3, ...
                   'EdgeColor',        'none', ...
                   'AmbientStrength',  .5, ...
                   'DiffuseStrength',  .9, ...
                   'SpecularStrength', .1, ...
                   'Tag',    'squareCut', ...
                   'Parent', hAxes);
end


%% ===== UPDATE MRI DISPLAY =====
% USAGE:  UpdateMriDisplay(hFig, dims, TessInfo, iTess)
%         UpdateMriDisplay(hFig, dims)
%         UpdateMriDisplay(hFig)
function UpdateMriDisplay(hFig, dims, TessInfo, iTess)
    % Parse inputs
    if (nargin < 4)
        [sMri,TessInfo,iTess] = panel_surface('GetSurfaceMri', hFig);
    end
    if (nargin < 2) || isempty(dims)
        dims = [1 2 3];
    end
    % Get the slices that need to be redrawn
    newPos = [NaN, NaN, NaN];
    newPos(dims) = TessInfo(iTess).CutsPosition(dims);
    % Redraw the three slices
    panel_surface('PlotMri', hFig, newPos);
end



%% ===== UPDATE SURFACE COLOR =====
% Compute color RGB values for each vertex of the surface, taking in account : 
%     - the surface color,
%     - the sulci map
%     - the data matrix displayed over the surface (and the data threshold),
%     - the data colormap : RGB values, normalized?, absolute values?, limits
%     - the data transparency
% Parameters : 
%     - hFig : handle to a 3DViz figure
%     - iTess     : indice of the surface to update
function UpdateSurfaceColor(hFig, iTess)
    % Get surfaces list 
    TessInfo = getappdata(hFig, 'Surface');
    % Ignore empty surfaces and MRI slices
    if isempty(TessInfo(iTess).hPatch) || ~any(ishandle(TessInfo(iTess).hPatch))
        return 
    end
    % Get best colormap to display data
    ColormapInfo = getappdata(hFig, 'Colormap');
    sColormap = bst_colormaps('GetColormap', ColormapInfo.Type);
    
    % === MRI ===
    if strcmpi(TessInfo(iTess).Name, 'Anatomy')
        % Update display
        UpdateMriDisplay(hFig, [], TessInfo, iTess);
        
    % === SURFACE ===
    else
        % === BUILD VALUES ===
        % If there is no data overlay
        if isempty(TessInfo(iTess).Data)
            DataSurf = [];
        else
            % Apply absolute value
            DataSurf = TessInfo(iTess).Data;
            if sColormap.isAbsoluteValues
                DataSurf = abs(DataSurf);
            end
            % Apply data threshold
            [DataSurf, ThreshBar] = ThresholdSurfaceData(DataSurf, TessInfo(iTess).DataLimitValue, TessInfo(iTess).DataThreshold, sColormap);
            % If there is an atlas defined for this surface: replicate the values for each patch
            if ~isempty(TessInfo(iTess).DataSource.Atlas) && ~isempty(TessInfo(iTess).DataSource.Atlas.Scouts)
                % Initialize full cortical map
                DataScout = DataSurf;
                DataSurf = zeros(TessInfo(iTess).nVertices,1);
                % Duplicate the value of each scout to all the vertices
                sScouts = TessInfo(iTess).DataSource.Atlas.Scouts;
                for i = 1:length(sScouts)
                    DataSurf(sScouts(i).Vertices,:) = DataScout(i,:);
                end
            % Apply size threshold (surface only)
            elseif (TessInfo(iTess).SizeThreshold > 1)
                % Get the cortex surface (for the vertices connectivity)
                sSurf = bst_memory('GetSurface', TessInfo(iTess).SurfaceFile);
                % Get clusters that are above the threshold
                iVertOk = bst_cluster_threshold(abs(DataSurf), TessInfo(iTess).SizeThreshold, sSurf.VertConn);
                DataSurf(~iVertOk) = 0;
            end
            % Add threshold markers to colorbar
            AddThresholdMarker(hFig, TessInfo(iTess).DataLimitValue, ThreshBar);
        end
   
        % SHOW SULCI MAP
        if TessInfo(iTess).SurfShowSulci
            % Get surface
            sSurf = bst_memory('GetSurface', TessInfo(iTess).SurfaceFile);
            SulciMap = sSurf.SulciMap;
        % DO NOT SHOW SULCI MAP
        else
            SulciMap = zeros(TessInfo(iTess).nVertices, 1);
        end
        % Compute RGB values
        FaceVertexCdata = BlendAnatomyData(SulciMap, ...                                  % Anatomy: Sulci map
                                           TessInfo(iTess).AnatomyColor([1,end], :), ...  % Anatomy: color
                                           DataSurf, ...                                  % Data: values map
                                           TessInfo(iTess).DataLimitValue, ...            % Data: limit value
                                           TessInfo(iTess).DataAlpha,...                  % Data: transparency
                                           sColormap);                                    % Colormap
        % Edge display : on/off
        if ~TessInfo(iTess).SurfShowEdges
            EdgeColor = 'none';
        else
            EdgeColor = TessInfo(iTess).AnatomyColor(1, :);
        end
        % Set surface colors
        set(TessInfo(iTess).hPatch, 'FaceVertexCdata', FaceVertexCdata, ...
                                    'FaceColor',       'interp', ...
                                    'EdgeColor',       EdgeColor);
    end
end


%% ===== THRESHOLD DATA =====
function [Data, ThreshBar] = ThresholdSurfaceData(Data, DataLimit, DataThreshold, sColormap)
    if ~sColormap.isAbsoluteValues && (DataLimit(1) == -DataLimit(2))
        ThreshBar = DataThreshold * max(abs(DataLimit)) * [-1,1];
        Data(abs(Data) < ThreshBar(2)) = 0;
    elseif (DataLimit(2) <= 0)
        ThreshBar = DataLimit(2);
        Data((Data < DataLimit(1) + (DataLimit(2)-DataLimit(1)) * DataThreshold)) = DataLimit(1);
        Data(Data > DataLimit(2)) = 0;
    else
        ThreshBar = DataLimit(1) + (DataLimit(2)-DataLimit(1)) * DataThreshold;
        Data((Data < ThreshBar)) = 0;
        Data(Data > DataLimit(2)) = DataLimit(2);
    end
end


%% ===== ADD THRESHOLD MARKER =====
function AddThresholdMarker(hFig, DataLimit, ThreshBar)
    hColorbar = findobj(hFig, '-depth', 1, 'Tag', 'Colorbar');
    if ~isempty(hColorbar)
        % Delete existing threshold bars
        hThreshBar = findobj(hColorbar, 'Tag', 'ThreshBar');
        delete(hThreshBar);
        % Draw all the threshold bars
        if ((length(ThreshBar) == 1) || (ThreshBar(2) ~= ThreshBar(1)))
            for i = 1:length(ThreshBar)
                yval = (ThreshBar(i) - DataLimit(1)) / (DataLimit(2) - DataLimit(1)) * 256;
                line([0 1], yval.*[1 1], [1 1], 'Color', [1 1 1], 'Parent', hColorbar, 'Tag', 'ThreshBar');
            end
        end
    end
end


%% ===== BLEND ANATOMY DATA =====
% Compute the RGB color values for each vertex of an enveloppe.
% INPUT:
%    - SulciMap     : [nVertices] vector with 0 or 1 values (0=gyri, 1=sulci)
%    - Data         : [nVertices] vector 
%    - DataLimit    : [absMaxVal] or [minVal, maxVal], or []
%    - DataAlpha    : Transparency value for the data (if alpha=0, we only see the anatomy color)
%    - AnatomyColor : [2x3] colors for anatomy (sulci / gyri)
%    - sColormap    : Colormap for the data
% OUTPUT:
%    - mixedRGB     : [nVertices x 3] RGB color value for each vertex
function mixedRGB = BlendAnatomyData(SulciMap, AnatomyColor, Data, DataLimit, DataAlpha, sColormap)
    % Create a background: light 1st color for gyri, 2nd color for sulci
    anatRGB = AnatomyColor(2-SulciMap, :);
    % === OVERLAY: DATA MAP ===
    if ~isempty(Data) && (DataLimit(2) ~= DataLimit(1))
        iDataCmap = round( ((size(sColormap.CMap,1)-1)/(DataLimit(2)-DataLimit(1))) * (Data - DataLimit(1))) + 1;
        iDataCmap(iDataCmap <= 0) = 1;
        iDataCmap(iDataCmap > size(sColormap.CMap,1)) = size(sColormap.CMap,1);
        dataRGB = sColormap.CMap(iDataCmap, :);
    else
        dataRGB = [];
    end
    % === MIX ANATOMY/DATA RGB ===
    mixedRGB = anatRGB;
    if ~isempty(dataRGB)
        toBlend = find(Data ~= 0); % Find vertex indices holding non-zero activation (after thresholding)
        mixedRGB(toBlend,:) = DataAlpha * anatRGB(toBlend,:) + (1-DataAlpha) * dataRGB(toBlend,:);
    end
end

%% ===== SMOOTH SURFACE CALLBACK =====
function SmoothSurface(hFig, iTess, smoothValue)
    % Get surfaces list 
    TessInfo = getappdata(hFig, 'Surface');
    % Ignore MRI slices
    if strcmpi(TessInfo(iTess).Name, 'Anatomy')
        return
    end
    % Get surfaces vertices
    sSurf = bst_memory('GetSurface', TessInfo(iTess).SurfaceFile);
    % If smoothValue is null: restore initial vertices
    if (smoothValue == 0)
        set(TessInfo(iTess).hPatch, 'Vertices', sSurf.Vertices);
        return
    end

    % ===== SMOOTH SURFACE =====
    SurfSmoothIterations = ceil(300 * smoothValue * length(sSurf.Vertices) / 100000);
    % Calculate smoothed vertices locations
    Vertices_sm = tess_smooth(sSurf.Vertices, smoothValue, SurfSmoothIterations, sSurf.VertConn, 1);
    % Apply smoothed locations
    set(TessInfo(iTess).hPatch, 'Vertices',  Vertices_sm);
end



%% ===== UPDATE SURFACE ALPHA =====
% Update Alpha values for the given surface.
% Fields that are used from TessInfo:
%    - SurfAlpha : Transparency of the surface patch
%    - Resect    : [x,y,z] doubles : Resect surfaces at these coordinates
%                  or string {'left', 'right', 'all'} : Display only selected part of the surface
function UpdateSurfaceAlpha(hFig, iTess)
    % Get surfaces list 
    TessInfo = getappdata(hFig, 'Surface');
    Surface = TessInfo(iTess);
       
    % Ignore empty surfaces and MRI slices
    if strcmpi(Surface.Name, 'Anatomy') || isempty(Surface.hPatch) || ~ishandle(Surface.hPatch)
        return 
    end
    % Apply current smoothing
    SmoothSurface(hFig, iTess, Surface.SurfSmoothValue);
    % Get surfaces vertices
    Vertices = get(Surface.hPatch, 'Vertices');
    nbVertices = length(Vertices);
    % Get vertex connectivity
    sSurf = bst_memory('GetSurface', TessInfo(iTess).SurfaceFile);
    VertConn = sSurf.VertConn;
    % Create Alpha data
    FaceVertexAlphaData = ones(length(sSurf.Faces),1) * (1-Surface.SurfAlpha);
    
    % ===== HEMISPHERE SELECTION (CHAR) =====
    if ischar(Surface.Resect)
        % Detect hemispheres
        [rH, lH, isConnected] = tess_hemisplit(sSurf);
        % If there is no separation between  left and right: use the numeric split
        if isConnected
            iHideVert = [];
            switch (Surface.Resect)
                case 'right', Surface.Resect = [0  0.0000001 0];
                case 'left',  Surface.Resect = [0 -0.0000001 0];
            end
        % If there is a structural separation between left and right: usr
        else
            switch (Surface.Resect)
                case 'right', iHideVert = lH;
                case 'left',  iHideVert = rH;
                otherwise,    iHideVert = [];
            end
        end
        % Update Alpha data
        if ~isempty(iHideVert)
            isHideFaces = any(ismember(sSurf.Faces, iHideVert), 2);
            FaceVertexAlphaData(isHideFaces) = 0;
        end
    end
        
    % ===== RESECT (DOUBLE) =====
    if isnumeric(Surface.Resect) && (length(Surface.Resect) == 3) && ~all(Surface.Resect == 0)
        iNoModif = [];
        % Compute mean and max of the coordinates
        meanVertx = mean(Vertices, 1);
        maxVertx  = max(abs(Vertices), [], 1);
        % Limit values
        resectVal = Surface.Resect .* maxVertx + meanVertx;
        % Get vertices that are kept in all the cuts
        for iCoord = 1:3
            if Surface.Resect(iCoord) > 0
                iNoModif = union(iNoModif, find(Vertices(:,iCoord) < resectVal(iCoord)));
            elseif Surface.Resect(iCoord) < 0
                iNoModif = union(iNoModif, find(Vertices(:,iCoord) > resectVal(iCoord)));
            end
        end
        % Get all the faces that are partially visible
        ShowVert = zeros(nbVertices,1);
        ShowVert(iNoModif) = 1;
        facesStatus = sum(ShowVert(sSurf.Faces), 2);
        isFacesVisible = (facesStatus > 0);

        % Get the vertices of the faces that are partially visible
        iVerticesVisible = sSurf.Faces(isFacesVisible,:);
        iVerticesVisible = unique(iVerticesVisible(:))';
        % Hide some vertices
        FaceVertexAlphaData(~isFacesVisible) = 0;
        
        % Get vertices to project
        iVerticesToProject = [iVerticesVisible, tess_scout_swell(iVerticesVisible, VertConn)];
        iVerticesToProject = setdiff(iVerticesToProject, iNoModif);
        % If there are some vertices to project
        if ~isempty(iVerticesToProject)
            % === FIRST PROJECTION ===
            % For the projected vertices: get the distance from each cut
            distToCut = abs(Vertices(iVerticesToProject, :) - repmat(resectVal, [length(iVerticesToProject), 1]));
            % Set the distance to the cuts that are not required to infinite
            distToCut(:,(Surface.Resect == 0)) = Inf;
            % Get the closest cut
            [minDist, closestCut] = min(distToCut, [], 2);

            % Project each vertex       
            Vertices(sub2ind(size(Vertices), iVerticesToProject, closestCut')) = resectVal(closestCut);

            % === SECOND PROJECTION ===            
            % In the faces that have visible and invisible vertices: project the invisible vertices on the visible vertices
            % Get the mixed faces (partially visible)
            ShowVert = zeros(nbVertices,1);
            ShowVert(iVerticesVisible) = 1;
            facesStatus = sum(ShowVert(sSurf.Faces), 2);
            iFacesMixed = find((facesStatus > 0) & (facesStatus < 3));
            % Project vertices
            projectList = logical(ShowVert(sSurf.Faces(iFacesMixed,:)));
            for iFace = 1:length(iFacesMixed)
                iVertVis = sSurf.Faces(iFacesMixed(iFace), projectList(iFace,:));
                iVertHid = sSurf.Faces(iFacesMixed(iFace), ~projectList(iFace,:));
                % Project hidden vertices on first visible vertex
                Vertices(iVertHid, :) = repmat(Vertices(iVertVis(1), :), length(iVertHid), 1);
            end
            % Update patch
            set(Surface.hPatch, 'Vertices', Vertices);
        end
    end
    
    % ===== HIDE NON-SELECTED STRUCTURES =====
    % Hide non-selected Structures scouts
    if ~isempty(sSurf.Atlas) && strcmpi(sSurf.Atlas(sSurf.iAtlas).Name, 'Structures')
        % Get scouts display options
        ScoutsOptions = panel_scout('GetScoutsOptions');
        % Get selected scouts
        sScouts = panel_scout('GetSelectedScouts');
        % Get all the selected vertices
        if ~isempty(sScouts) && strcmpi(ScoutsOptions.showSelection, 'select')
            % Get the list of hidden vertices
            iSelVert = unique([sScouts.Vertices]);
            isSelVert = zeros(length(sSurf.Vertices),1);
            isSelVert(iSelVert) = 1;
            % Get the list of hidden faces 
            isSelFaces = any(isSelVert(sSurf.Faces), 2);
            % Add hidden faces to current mask
            FaceVertexAlphaData(~isSelFaces) = 0;
        end
    end
   
    % Update surface
    if all(FaceVertexAlphaData)
        set(Surface.hPatch, 'FaceAlpha', 1-Surface.SurfAlpha);
    else
        set(Surface.hPatch, 'FaceVertexAlphaData', FaceVertexAlphaData, ...
                            'FaceAlpha',           'flat');
    end
end


%% ===== GET CHANNELS POSITIONS =====
% USAGE:  [chan_loc, markers_loc, vertices] = GetChannelPositions(iDS, selChan)
%         [chan_loc, markers_loc, vertices] = GetChannelPositions(iDS, Modality)
%         [chan_loc, markers_loc, vertices] = GetChannelPositions(ChannelMat, ...)
function [chan_loc, markers_loc, vertices] = GetChannelPositions(iDS, selChan)
    global GlobalData;
    % Initialize returned variables
    chan_loc    = [];
    markers_loc = [];
    vertices    = [];
    % Get device type
    if isstruct(iDS)
        ChannelMat = iDS;
        [tag, Device] = channel_detect_device(ChannelMat);
        Channel = ChannelMat.Channel;
    else
        Device = bst_get('ChannelDevice', GlobalData.DataSet(iDS).ChannelFile);
        Channel = GlobalData.DataSet(iDS).Channel;
    end
    % Get selected channels
    if ischar(selChan)
        Modality = selChan;
        selChan = good_channel(Channel, [], Modality);
    end
    Channel = Channel(selChan);
    % Find magnetometers
    if strcmpi(Device, 'Vectorview306')
        iMag = good_channel(Channel, [], 'MEG MAG');
    end
    % Loop on all the sensors
    for i = 1:length(Channel)
        % Get number of integration points or coils
        nIntegPoints = size(Channel(i).Loc, 2);
        % Switch depending on the device
        switch (Device)
            case {'CTF', '4D', 'KIT'}
                if (nIntegPoints >= 4)
                    chan_loc    = [chan_loc,    mean(Channel(i).Loc(:,1:4),2)];
                    markers_loc = [markers_loc, mean(Channel(i).Loc(:,1:4),2)];
                    vertices    = [vertices,    Channel(i).Loc(:,1:4)];
                else
                    chan_loc    = [chan_loc,    mean(Channel(i).Loc,2)];
                    markers_loc = [markers_loc, mean(Channel(i).Loc,2)];
                    vertices    = [vertices,    Channel(i).Loc];
                end
            case 'Vectorview306'
                chan_loc    = [chan_loc,    mean(Channel(i).Loc, 2)];
                markers_loc = [markers_loc, Channel(i).Loc(:,1)];
                if isempty(iMag) || ismember(i, iMag)
                    vertices = [vertices, Channel(i).Loc];
                end
            case 'BabySQUID'
                chan_loc    = [chan_loc,    Channel(i).Loc(:,1)];
                markers_loc = [markers_loc, Channel(i).Loc(:,1)];
                vertices    = [vertices,    Channel(i).Loc(:,1)];
            otherwise
                chan_loc    = [chan_loc,    mean(Channel(i).Loc,2)];
                markers_loc = [markers_loc, Channel(i).Loc(:,1)];
                vertices    = [vertices,    Channel(i).Loc];
        end
    end
    chan_loc    = double(chan_loc');
    markers_loc = double(markers_loc');
    vertices    = double(vertices');
end


%% ===== VIEW SENSORS =====
%Display sensors markers and labels in a 3DViz figure.
% Usage:   ViewSensors(hFig, isMarkers, isLabels)           : Display selected channels of figure hFig
%          ViewSensors(hFig, isMarkers, isLabels, Modality) : Display channels of target Modality in figure hFig
% Parameters :
%     - hFig      : target '3DViz' figure
%     - isMarkers : Sensors markers status : {0 (hide), 1 (show), [] (ignore)}
%     - isLabels  : Sensors labels status  : {0 (hide), 1 (show), [] (ignore)}
%     - isMesh    : If 1, display a mesh; if 0, display only the markers
%     - Modality  : Sensor type to display
function ViewSensors(hFig, isMarkers, isLabels, isMesh, Modality)
    global GlobalData;
    % Parse inputs
    if (nargin < 5) || isempty(Modality)
        Modality = '';
    end
    if (nargin < 4) || isempty(isMesh)
        isMesh = 1;
    end
    % Get figure description
    [hFig, iFig, iDS] = bst_figures('GetFigure', hFig);
    if isempty(iDS)
        return
    end
    % Check if there is a channel file associated with this figure
    if isempty(GlobalData.DataSet(iDS).Channel)
        return
    end
    PlotHandles = GlobalData.DataSet(iDS).Figure(iFig).Handles;
    isTopography = strcmpi(get(hFig, 'Tag'), 'Topography');
    is2D = 0;
    
    % ===== MARKERS LOCATIONS =====
    % === TOPOGRAPHY ===
    if isTopography
        % Markers locations where stored in the Handles structure while creating topography patch
        if isempty(PlotHandles.MarkersLocs)
            return
        end
        % Get a location to display the Markers
        markersLocs = PlotHandles.MarkersLocs;
        % Flag=1 if 2D display
        is2D = ismember(GlobalData.DataSet(iDS).Figure(iFig).Id.SubType, {'2DDisc','2DSensorCap'});
        % Get selected channels
        selChan = GlobalData.DataSet(iDS).Figure(iFig).SelectedChannels;
        markersOrient = [];
        
    % === 3DVIZ ===
    else
        Channel = GlobalData.DataSet(iDS).Channel;
        % Find sensors of the target modality, select and display them
        if isempty(Modality)
            selChan = GlobalData.DataSet(iDS).Figure(iFig).SelectedChannels;
        else
            selChan = good_channel(Channel, [], Modality);
        end
        % If no channels for this modality
        if isempty(selChan)
            bst_error(['No "' Modality '" sensors in channel file: "' GlobalData.DataSet(iDS).ChannelFile '".'], 'View sensors', 0);
            return
        end
        % Get sensors positions
        [tmp, markersLocs, Vertices] = GetChannelPositions(iDS, selChan);
        % Markers orientations: only for MEG
        if ismember(Modality, {'MEG', 'MEG GRAD', 'MEG MAG', 'Vectorview306', 'CTF', '4D', 'KIT'})
            markersOrient = cell2mat(cellfun(@(c)c(:,1), {Channel(selChan).Orient}, 'UniformOutput', 0))';
        else
            markersOrient = [];
        end
    end
    % Make sure that electrodes locations are in double precision
    markersLocs = double(markersLocs);
    markersOrient = double(markersOrient);
    
    % ===== DISPLAY MARKERS OBJECTS =====
    % Put focus on target figure
    hAxes = findobj(hFig, '-depth', 1, 'Tag', 'Axes3D');
    % === SENSORS ===
    if ~isempty(isMarkers)
        % Delete sensor markers
        if ~isempty(PlotHandles.hSensorMarkers) && all(ishandle(PlotHandles.hSensorMarkers))
            delete(PlotHandles.hSensorMarkers);
            delete(PlotHandles.hSensorOrient);
            PlotHandles.hSensorMarkers = [];
            PlotHandles.hSensorOrient = [];
        end
        
        % Display sensors markers
        if isMarkers
            % Is display of a flat 2D topography map
            if is2D
                PlotHandles.hSensorMarkers = PlotSensors2D(hAxes, markersLocs);
            % If VectorView306   
            elseif strcmpi(Modality, 'Vectorview306')
                [PlotHandles.hSensorMarkers, PlotHandles.hSensorOrient] = PlotSensorsVectorview306(hAxes, Vertices);
                isLabels = 0;
            % If CTF/4D
            elseif strcmpi(Modality, 'CTF') || strcmpi(Modality, '4D') || strcmpi(Modality, 'KIT')
                [PlotHandles.hSensorMarkers, PlotHandles.hSensorOrient] = PlotSensorsCtf(hAxes, Vertices);
                %PlotSensorsCtfRef(hAxes, GlobalData.DataSet(iDS).Channel);
                isLabels = 0;
            % If more than one patch : transparent sensor cap
            elseif ~isempty(findobj(hAxes, 'type', 'patch')) || ~isempty(findobj(hAxes, 'type', 'surface'))
                [PlotHandles.hSensorMarkers, PlotHandles.hSensorOrient] = PlotSensorsNet(hAxes, markersLocs, 0, isMesh, markersOrient);
            % Else, sensor cap is the only patch => display its faces
            else
                [PlotHandles.hSensorMarkers, PlotHandles.hSensorOrient] = PlotSensorsNet(hAxes, markersLocs, 1, isMesh, markersOrient);
            end
        end
    end
    
    % === LABELS ===
    if ~isempty(isLabels)
        % Delete sensor labels
        if ~isempty(PlotHandles.hSensorLabels)
            delete(PlotHandles.hSensorLabels(ishandle(PlotHandles.hSensorLabels)));
            PlotHandles.hSensorLabels = [];
        end
        % Display sensor labels
        if isLabels
            sensorNames = {GlobalData.DataSet(iDS).Channel.Name}';
            if ~isempty(sensorNames)
                % Get the names of the seleected sensors
                sensorNames = sensorNames(selChan);
                PlotHandles.hSensorLabels = text(1.08*markersLocs(:,1), 1.08*markersLocs(:,2), 1.08*markersLocs(:,3), ...
                                                 sensorNames, ...
                                                 'Parent',              hAxes, ...
                                                 'HorizontalAlignment', 'center', ...
                                                 'FontSize',            bst_get('FigFont') + 2, ...
                                                 'FontUnits',           'points', ...
                                                 'FontWeight',          'normal', ...
                                                 'Tag',                 'SensorsLabels', ...
                                                 'Color',               [1,1,.2], ...
                                                 'Interpreter',         'none');
            end
        end
    end
    GlobalData.DataSet(iDS).Figure(iFig).Handles = PlotHandles;
    % Repaint selected sensors for this figure
    UpdateFigSelectedRows(iDS, iFig);
end


%% ===== VIEW HEAD POINTS =====
function ViewHeadPoints(hFig, isVisible)
    global GlobalData;
    % Get figure description
    [hFig, iFig, iDS] = bst_figures('GetFigure', hFig);
    if isempty(iDS)
        return
    end
    hAxes = findobj(hFig, '-depth', 1, 'Tag', 'Axes3D');
    % If no head points are available: exit
    if isempty(GlobalData.DataSet(iDS).HeadPoints) || ~isfield(GlobalData.DataSet(iDS).HeadPoints, 'Loc') || isempty(GlobalData.DataSet(iDS).HeadPoints.Loc)
        return
    end
    HeadPoints = GlobalData.DataSet(iDS).HeadPoints;
    
    % Get existing sensor patches: do not display points where there are already EEG markers
    hSensorsPatch = findobj(hAxes, '-depth', 1, 'Tag', 'SensorsPatch');
    if ~isempty(hSensorsPatch) && strcmpi(get(hSensorsPatch,'Visible'), 'on')
        % Get sensors markers
        pts = get(hSensorsPatch, 'Vertices');
        % Compute full distance matrix sensors/headpoints
        nhp = length(HeadPoints.Type);
        ns = length(pts);
        dist = sqrt((pts(:,1)*ones(1,nhp) - ones(ns,1)*HeadPoints.Loc(1,:)).^2 + (pts(:,2)*ones(1,nhp) - ones(ns,1)*HeadPoints.Loc(2,:)).^2 + (pts(:,3)*ones(1,nhp) - ones(ns,1)*HeadPoints.Loc(3,:)).^2);
        % Duplicates: head points that are less than .1 millimeter away from a sensor
        iDupli = find(min(dist) < 0.0001);
        % If any duplicates: move them slightly inside so they are not completely overlapping with the electrodes
        [th,phi,r] = cart2sph(HeadPoints.Loc(1,iDupli), HeadPoints.Loc(2,iDupli), HeadPoints.Loc(3,iDupli));
        [HeadPoints.Loc(1,iDupli), HeadPoints.Loc(2,iDupli), HeadPoints.Loc(3,iDupli)] = sph2cart(th, phi, r - 0.0001);
    end
    
    % Else, get previous head points
    hHeadPointsMarkers = findobj(hAxes, 'Tag', 'HeadPointsMarkers');
    hHeadPointsLabels  = findobj(hAxes, 'Tag', 'HeadPointsLabels');
    % If head points graphic objects already exist: set the "Visible" property
    if ~isempty(hHeadPointsMarkers)
        if isVisible
            set([hHeadPointsMarkers hHeadPointsLabels], 'Visible', 'on');
        else
            set([hHeadPointsMarkers hHeadPointsLabels], 'Visible', 'off');
        end
    % If head points objects were not created yet: create them
    elseif isVisible
        % Get digitized points locations
        digLoc = double(HeadPoints.Loc)';
        % Prepare display names
        digNames = cell(size(HeadPoints.Label));
        for i = 1:length(HeadPoints.Label)
            switch upper(HeadPoints.Type{i})
                case 'CARDINAL'
                    digNames{i} = HeadPoints.Label{i};
                case 'EXTRA'
                    digNames{i} = HeadPoints.Label{i};
                case 'HPI'
                    digNames{i} = HeadPoints.Label{i};
                    if isempty(strfind(digNames{i}, 'HPI-')) && isempty(strfind(digNames{i}, 'HLC-'))
                        digNames{i} = ['HPI-', digNames{i}];
                    end
                otherwise
                    if isnumeric(HeadPoints.Label{i})
                        digNames{i} = [HeadPoints.Type{i}, '-', num2str(HeadPoints.Label{i})];
                    else
                        digNames{i} = [HeadPoints.Type{i}, '-', HeadPoints.Label{i}];
                    end
            end
        end
        % Get the different types of points
        iFid   = {find(strcmpi(HeadPoints.Type, 'CARDINAL')), find(strcmpi(HeadPoints.Type, 'HPI'))};
        iExtra = find(strcmpi(HeadPoints.Type, 'EXTRA') | strcmpi(HeadPoints.Type, 'EEG'));
        % Plot fiducials
        for k = 1:2
            if ~isempty(iFid{k})
                if (k == 1)
                    markerFaceColor = [1 1 .3];
                    objTag = 'HeadPointsFid';
                else
                    markerFaceColor = [.9 .6 .2];
                    objTag = 'HeadPointsHpi';
                end
                % Display markers
                line(digLoc(iFid{k},1), digLoc(iFid{k},2), digLoc(iFid{k},3), ...
                    'Parent',          hAxes, ...
                    'LineWidth',       2, ...
                    'LineStyle',       'none', ...
                    'MarkerFaceColor', markerFaceColor, ...
                    'MarkerEdgeColor', [1 .4 .4], ...
                    'MarkerSize',      7, ...
                    'Marker',          'o', ...
                    'UserData',        iFid{k}, ...
                    'Tag',             objTag);
                % Group by similar names
                [uniqueNames, iUnique] = unique(digNames(iFid{k}));
                % Display labels
                txtLoc = digLoc(iFid{k}(iUnique),:);
                txtLocSph = [];
                % Bring the labels further away from the head to make them readable
                [txtLocSph(:,1), txtLocSph(:,2), txtLocSph(:,3)] = cart2sph(txtLoc(:,1), txtLoc(:,2), txtLoc(:,3));
                [txtLoc(:,1), txtLoc(:,2), txtLoc(:,3)] = sph2cart(txtLocSph(:,1), txtLocSph(:,2), txtLocSph(:,3) + 0.03);
                % Display text
                text(txtLoc(:,1), txtLoc(:,2), txtLoc(:,3), ...
                    uniqueNames', ...
                    'Parent',              hAxes, ...
                    'HorizontalAlignment', 'center', ...
                    'Fontsize',            bst_get('FigFont') + 2, ...
                    'FontUnits',           'points', ...
                    'FontWeight',          'normal', ...
                    'Tag',                 'HeadPointsLabels', ...
                    'Color',               [1,1,.2], ...
                    'Interpreter',         'none');
            end
        end
        % Plot extra head points
        if ~isempty(iExtra)
            % Display markers
            line(digLoc(iExtra,1), digLoc(iExtra,2), digLoc(iExtra,3), ...
                'Parent',          hAxes, ...
                'LineWidth',       2, ...
                'LineStyle',       'none', ...
                'MarkerFaceColor', [.3 1 .3], ...
                'MarkerEdgeColor', [.4 .7 .4], ...
                'MarkerSize',      6, ...
                'Marker',          'o', ...
                'UserData',        iExtra, ...
                'Tag',             'HeadPointsMarkers');
        end
    end
end


%% ===== VIEW AXIS =====
function ViewAxis(hFig, isVisible)
    hAxes = findobj(hFig, '-depth', 1, 'Tag', 'Axes3D');
    if (nargin < 2)
        isVisible = isempty(findobj(hAxes, 'Tag', 'AxisXYZ'));
    end
    if isVisible
        line([0 0.15], [0 0], [0 0], 'Color', [1 0 0], 'Marker', '>', 'Parent', hAxes, 'Tag', 'AxisXYZ');
        line([0 0], [0 0.15], [0 0], 'Color', [0 1 0], 'Marker', '>', 'Parent', hAxes, 'Tag', 'AxisXYZ');
        line([0 0], [0 0], [0 0.15], 'Color', [0 0 1], 'Marker', '>', 'Parent', hAxes, 'Tag', 'AxisXYZ');
        text(0.151, 0, 0, 'X', 'Color', [1 0 0], 'Parent', hAxes, 'Tag', 'AxisXYZ');
        text(0, 0.151, 0, 'Y', 'Color', [0 1 0], 'Parent', hAxes, 'Tag', 'AxisXYZ');
        text(0, 0, 0.151, 'Z', 'Color', [0 0 1], 'Parent', hAxes, 'Tag', 'AxisXYZ');
    else
        hAxisXYZ = findobj(hAxes, 'Tag', 'AxisXYZ');
        if ~isempty(hAxisXYZ)
            delete(hAxisXYZ);
        end
    end
end


%% ===== PLOT SENSORS: 2D =====
% Plot the sensors projected in 2D in a 3D figure.
% USAGE:  hNet = gui_plotSensors2D( hAxes, vertices )
% INPUT:  - hAxes        : handle to axes in which you need to display the sensors patch
%         - vertices     : [NbVert * NbIntergationPoints, 3] double, (x,y,z) location of each sensor
function [hNet, hOrient] = PlotSensors2D( hAxes, vertices )
    hOrient = [];
    % Try to plot markers with PATCH function
    try
        % === PREPARE PATCH ===
        % Convex hull of the set of points
        faces = delaunay(vertices(:,2), vertices(:,1));
        vertices(:,3) = 0.05;

        % === DISPLAY PATCH ===
        % Create sensors patch
        hNet = patch('Vertices',        vertices, ...
                     'Faces',           faces, ...
                     'FaceVertexCData', repmat([1 1 1], [length(vertices), 1]), ...
                     'Parent',          hAxes, ...
                     'Marker',          'o', ...
                     'FaceColor',       'none', ...
                     'EdgeColor',       'none', ...
                     'LineWidth',       2, ...
                     'MarkerEdgeColor', [.4 .4 .3], ...
                     'MarkerFaceColor', 'flat', ...
                     'MarkerSize',      6, ...
                     'BackfaceLighting', 'lit', ...
                     'Tag',             'SensorsPatch');

    % If convhull or patch crashed : try LINE function
    catch
        warning('Brainstorm:PatchError', 'patch() function returned an error. Trying to display sensors with line() function...');
        hNet = line(vertices(:,1), vertices(:,2), vertices(:,3), ...
                    'Parent',          hAxes, ...
                    'LineWidth',       2, ...
                    'LineStyle',       'none', ...
                    'MarkerFaceColor', [1 1 1], ...
                    'MarkerEdgeColor', [.4 .4 .4], ...
                    'MarkerSize',      6, ...
                    'Marker',          'o', ...
                    'Tag',             'SensorsMarkers');
    end
end


%% ===== PLOT SENSORS: CTF =====
function [hNet, hOrient] = PlotSensorsCtf( hAxes, vertices )
    % CTF sensors
    for i = 1:4:length(vertices)
        VertPatch = vertices((1:4) + i - 1,:);
        hPatch = patch('Vertices',         VertPatch, ...
                        'Faces',           [1 2 3 4 1], ...
                        'FaceVertexCData', repmat([1 1 1], [length(vertices), 1]), ...
                        'Parent',          hAxes, ...
                        'Marker',          'none', ...
                        'LineWidth',       1, ...
                        'FaceColor',       [1 1 0], ...
                        'FaceAlpha',       1, ...
                        'EdgeColor',       [.4 .4 .3], ...
                        'EdgeAlpha',       1, ...
                        'BackfaceLighting', 'unlit', ...
                        'Tag',             'CTFSensorsPatch');
        material([ 0.5 0.50 0.20 1.00 0.5 ])
        lighting phong
    end
    hNet = [];
    hOrient = [];
end

%% ===== PLOT CTF REFERENCES =====
function PlotSensorsCtfRef(hAxes, Channels)
    % Loop on sensors
    for iChan = 1:length(Channels)
        % Skip non-ref sensors
        if ~strcmpi(Channels(iChan).Type, 'MEG REF')
            continue;
        end
        % Plot each coil
        nCoils = size(Channels(iChan).Loc, 2);
        if (nCoils < 4)
            % Plot coils, connected with lines
            coilLocs = Channels(iChan).Loc;
            line(coilLocs(1,:), coilLocs(2,:), coilLocs(3,:), ...
                'Parent',          hAxes, ...
                'LineWidth',       2, ...
                'LineStyle',       '-', ...
                'MarkerFaceColor', [1 1 1], ...
                'MarkerEdgeColor', [.4 .4 .4], ...
                'MarkerSize',      6, ...
                'Marker',          'o', ...
                'Tag',             'SensorsMarkersRef');
            % === Orientation ===
            for iCoil = 1:nCoils
                % Define line to be displayed from the first coil
                curOrient = Channels(iChan).Orient(:,iCoil) / norm(Channels(iChan).Orient(:,iCoil)) * 0.02;
                lineOrient = [coilLocs(:,iCoil)'; coilLocs(:,iCoil)' + curOrient'];
                % Plot line to represent the orientation
                line(lineOrient(:,1), lineOrient(:,2), lineOrient(:,3), ...
                     'Color',      [1 0 0], ...
                     'LineWidth',   1, ...
                     'Marker',     '>', ...
                     'MarkerSize', 3, ...
                     'Parent',     hAxes, ...
                     'Tag',        'LineOrientRef');
            end
        else
            for i = 1:4:nCoils
                VertPatch = Channels(iChan).Loc(:,(1:4) + i - 1)';
                hPatch = patch('Vertices',         VertPatch, ...
                                'Faces',           [1 2 3 4 1], ...
                                'FaceVertexCData', repmat([1 1 1], [5, 1]), ...
                                'Parent',          hAxes, ...
                                'Marker',          'o', ...
                                'LineWidth',       1, ...
                                'FaceColor',       [1 1 0], ...
                                'FaceAlpha',       .9, ...
                                'EdgeColor',       [1 1 0], ...
                                'EdgeAlpha',       1, ...
                                'MarkerEdgeColor', [.4 .4 .3], ...
                                ... 'MarkerFaceColor', 'flat', ...
                                'MarkerSize',      3, ...
                                'BackfaceLighting', 'unlit', ...
                                'Tag',             'CTFSensorsPatchRef');
                material([ 0.5 0.50 0.20 1.00 0.5 ])
                lighting phong
                % === Orientation ===
                % Compute center of the chip
                centerLoc = mean(VertPatch, 1);
                % Get the orientation for this location
                curOrient = Channels(iChan).Orient(:,1);
                % Normalize to the size of the sensor
                curOrient = curOrient' / norm(curOrient) * 0.02;
                % Define line to be displayed from the center of the chip
                lineOrient = [centerLoc; centerLoc + curOrient];
                % Plot line to represent the orientation
                line(lineOrient(:,1), lineOrient(:,2), lineOrient(:,3), ...
                     'Color',      [1 0 0], ...
                     'LineWidth',   1, ...
                     'Marker',     '>', ...
                     'MarkerSize', 3, ...
                     'Parent',     hAxes, ...
                     'Tag',        'LineOrientRef');
            end
        end
        % Plot text
        textLocs = Channels(iChan).Loc(:,1);
        PlotHandles.hSensorLabels = text(...
             1.08*textLocs(1), 1.08*textLocs(2), 1.08*textLocs(3), ...
             Channels(iChan).Name, ...
             'Parent',              hAxes, ...
             'HorizontalAlignment', 'center', ...
             'FontSize',            bst_get('FigFont') + 2, ...
             'FontUnits',           'points', ...
             'FontWeight',          'normal', ...
             'Tag',                 'SensorsLabelsRef', ...
             'Color',               [1,1,.2], ...
             'Interpreter',         'none');
    end
end


%% ===== PLOT SENSORS: VECTORVIEW306 =====
function [hNet, hOrient] = PlotSensorsVectorview306( hAxes, vertices )
    % For each Neuromag sensor chip (2 axial gradiometers, 1 magnetometer)
    for i = 1:102
        indM = [1, 2, 3, 4] + (i-1)*4;
        V = [vertices(indM,1), vertices(indM,2), vertices(indM,3)];
        V = V([1 2 4 3], :);
        center = mean(V);
        V = bst_bsxfun(@minus, V, center);
        V = bst_bsxfun(@times, V, 0.015 ./ sqrt(sum(V.^2,2)));
        V = bst_bsxfun(@plus,  V, center);
        VertPatch = V;

        hPatch = patch('Vertices',         VertPatch, ...
                        'Faces',           [1 2 3 4 1], ...
                        'FaceVertexCData', repmat([1 1 1], [length(vertices), 1]), ...
                        'Parent',          hAxes, ...
                        'Marker',          'none', ...
                        'LineWidth',       1, ...
                        'FaceColor',       [.9 .9 0], ...
                        'FaceAlpha',       1, ...
                        'EdgeColor',       [.4 .4 .3], ...
                        'EdgeAlpha',       1, ...
                        'BackfaceLighting', 'unlit', ...
                        'Tag',             'Vectorview306SensorsPatch');
        material([ 0.5 0.50 0.20 1.00 0.5 ])
        lighting phong
    end
    hNet = [];
    hOrient = [];
end

%% ===== PLOT SENSORS: NET 3D =====
% Plot the sensors patch in a 3D figure.
% USAGE:  [hNet, hOrient] = PlotSensorsNet( hAxes, vertices, isFaces, isMesh, orient )
%         [hNet, hOrient] = PlotSensorsNet( hAxes, vertices, isFaces )
% INPUT:  
%    - hAxes     : handle to axes in which you need to display the sensors patch
%    - vertices  : [NbVert * NbIntergationPoints, 3] double, (x,y,z) location of each sensor
%    - isFaces   : {0,1} - If 0, the faces are not displayed (alpha = 0)
%    - isMesh    : {0,1} - If 0, Do not create the mesh
%    - orient    : [NbVert * NbIntergationPoints, 3] double, orientation of the coil
%                     => Orientation displayed only if Faces are displayed
% OUTPUT:
%    - hNet : handle to the sensors patch
function [hNet, hOrient] = PlotSensorsNet( hAxes, vertices, isFaces, isMesh, orient )
    % Parse inputs
    if (nargin < 3) || isempty(isFaces)
        isFaces = 1;
    end
    if (nargin < 4) || isempty(isMesh)
        isMesh = 1;
    end
    if (nargin < 5) || isempty(orient)
        orient = [];
    end
    % Nothing to display
    hNet = [];
    hOrient = [];
    if isempty(vertices)
        return
    end

    % ===== SENSORS PATCH =====
    % Try to plot markers with PATCH function
    if isMesh
        try
            % === TESSELATE SENSORS NET ===
            faces = channel_tesselate( vertices );

            % === DISPLAY PATCH ===
            % Display faces / edges / vertices
            if isFaces
                FaceColor = [.7 .7 .5];
                EdgeColor = [.4 .4 .3];
                LineWidth = 1;
            % Else, display only vertices markers
            else
                FaceColor = 'none';
                EdgeColor = 'none';
                LineWidth = 2;
            end
            % Create sensors patch
            hNet = patch('Vertices',        vertices, ...
                         'Faces',           faces, ...
                         'FaceVertexCData', repmat([1 1 1], [length(vertices), 1]), ...
                         'Parent',          hAxes, ...
                         'Marker',          'o', ...
                         'LineWidth',       LineWidth, ...
                         'FaceColor',       FaceColor, ...
                         'FaceAlpha',       1, ...
                         'EdgeColor',       EdgeColor, ...
                         'EdgeAlpha',       1, ...
                         'MarkerEdgeColor', [.4 .4 .3], ...
                         'MarkerFaceColor', 'flat', ...
                         'MarkerSize',      6, ...
                         'BackfaceLighting', 'lit', ...
                         'Tag',             'SensorsPatch');
           if isFaces
               material([ 0.5 0.50 0.20 1.00 0.5 ])
               lighting phong
           end
           
        % If convhull or patch crashed : try next option
        catch
            warning('Brainstorm:PatchError', 'patch() function returned an error. Trying to display sensors with line() function...');
            hNet = [];
        end 
    end
    % If nothing is displayed yet (crash, or specific request of not having a mesh): plot only the sensor markers
    if isempty(hNet)
        hNet = line(vertices(:,1), vertices(:,2), vertices(:,3), ...
                    'Parent',          hAxes, ...
                    'LineWidth',       2, ...
                    'LineStyle',       'none', ...
                    'MarkerFaceColor', [1 1 1], ...
                    'MarkerEdgeColor', [.4 .4 .4], ...
                    'MarkerSize',      6, ...
                    'Marker',          'o', ...
                    'Tag',             'SensorsMarkers');
    end

    % ===== ORIENTATIONS =====
    % if ~isempty(orient) && isFaces
    %     hOrient = zeros(1,length(orient));
    %     for i = 1:length(orient)
    %         curOrient = orient(i,:);
    %         % Scale orientation vector for display
    %         scaleFactor = 0.0173;
    %         curOrient = curOrient ./ norm(curOrient) .* scaleFactor;
    %         % Define line to be displayed from the center of the chip
    %         lineOrient = [vertices(i,:); vertices(i,:) + curOrient];
    %         % Plot line to represent the orientation
    %         hOrient(i) = line(lineOrient(:,1), lineOrient(:,2), lineOrient(:,3), ...
    %                          'Color',      [1 0 0], ...
    %                          'LineWidth',  1, ...
    %                          'Marker',     '>', ...
    %                          'MarkerSize', 3, ...
    %                          'Parent',     hAxes, ...
    %                          'Tag',        'LineOrient');
    %     end
    % else
    %     hOrient = [];
    % end
end


%% ===== SAVE SURFACE =====
function SaveSurface(TessInfo)
    % Progress bar
    bst_progress('start', 'Save surface', 'Saving new surface...');
    % Get subject
    [sSubject, iSubject] = bst_get('SurfaceFile', TessInfo.SurfaceFile);
    % Load initial file
    FullFileName = file_fullpath(TessInfo.SurfaceFile);
    sSurfInit = load(FullFileName, 'Comment');
    % Create surface file
    sSurf.Vertices = get(TessInfo.hPatch, 'Vertices');
    sSurf.Faces    = get(TessInfo.hPatch, 'Faces');
    sSurf.Comment  = [sSurfInit.Comment, ' fig'];
    % Get hidden faces
    iFaceHide = find(get(TessInfo.hPatch, 'FaceVertexAlphaData') == 0);
    % If there are some, get the hidden vertices (vertices that are not in any visible face)
    if ~isempty(iFaceHide)
        % Get the hidden vertices
        FacesShow = sSurf.Faces;
        FacesShow(iFaceHide,:) = [];
        iVertHide = setdiff(1:length(sSurf.Vertices), unique(FacesShow(:)'));
        % If there are some hidden vertices: remove them from the surface
        if ~isempty(iVertHide)
            [sSurf.Vertices, sSurf.Faces] = tess_remove_vert(sSurf.Vertices, sSurf.Faces, iVertHide);
        end
    end
    % Create output filename
    OutputFile = strrep(FullFileName, '.mat', '_fig.mat');
    OutputFile = file_unique(OutputFile);
    % Save file
    bst_save(OutputFile, sSurf, 'v7');
    % Update database
    db_add_surface( iSubject, OutputFile, sSurf.Comment );
    bst_progress('stop');
end


