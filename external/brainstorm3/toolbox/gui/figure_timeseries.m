function varargout = figure_timeseries( varargin )
% FIGURE_TIMESERIES: Creation and callbacks for time series figures.
%
% USAGE:  hFig = figure_timeseries('CreateFigure', FigureId)
%                figure_timeseries('CurrentTimeChangedCallback',  iDS, iFig)
%                figure_timeseries('UniformizeTimeSeriesScales',  isUniform)
%                figure_timeseries('FigureMouseDownCallback',     hFig, event)
%                figure_timeseries('FigureMouseMoveCallback',     hFig, event)  
%                figure_timeseries('FigureMouseUpCallback',       hFig, event)
%                figure_timeseries('FigureMouseWheelCallback',    hFig, event)
%                figure_timeseries('FigureKeyPressedCallback',    hFig, keyEvent)
%                figure_timeseries('LineClickedCallback',         hLine, ev)
%                figure_timeseries('DisplayDataSelectedChannels', iDS, SelecteRows, Modality)
%                figure_timeseries('ToggleAxesProperty',          hAxes, propName)
%                figure_timeseries('ResetView',                   hFig)
%                figure_timeseries('ResetViewLinked',             hFig)
%                figure_timeseries('DisplayFigurePopup',          hFig, menuTitle=[], curTime=[])

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

macro_methodcall;
end


%% ===== CREATE FIGURE =====
function hFig = CreateFigure(FigureId)
    import org.brainstorm.icon.*;
    % Create new figure
    hFig = figure('Visible',       'off', ...
                  'NumberTitle',   'off', ...
                  'IntegerHandle', 'off', ...
                  'MenuBar',       'none', ...
                  'Toolbar',       'none', ...
                  'DockControls',  'on', ...
                  'Units',         'pixels', ...
                  'Interruptible', 'off', ...
                  'BusyAction',    'queue', ...
                  'Tag',           FigureId.Type, ...
                  'Renderer',      'zbuffer', ...
                  'CloseRequestFcn',     @(h,ev)bst_figures('DeleteFigure',h,ev), ...
                  'KeyPressFcn',         @FigureKeyPressedCallback, ...
                  'WindowButtonDownFcn', @FigureMouseDownCallback, ...
                  'WindowButtonUpFcn',   @FigureMouseUpCallback, ...
                  'ResizeFcn',           @ResizeCallback);
    % Define Mouse wheel callback separately (not supported by old versions of Matlab)
    if isprop(hFig, 'WindowScrollWheelFcn')
        set(hFig, 'WindowScrollWheelFcn',  @FigureMouseWheelCallback, ...
                  'KeyReleaseFcn',         @FigureKeyReleasedCallback);
    end

    % Prepare figure appdata
    setappdata(hFig, 'hasMoved', 0);
    setappdata(hFig, 'isPlotEditToolbar', 0);
    setappdata(hFig, 'AllChannelsDisplayed', 0);
    setappdata(hFig, 'GraphSelection', []);
    setappdata(hFig, 'isStatic', 0);
    setappdata(hFig, 'isStaticFreq', 1);
    setappdata(hFig, 'isControlKeyDown', false);
    setappdata(hFig, 'isShiftKeyDown', false);
    setappdata(hFig, 'Colormap', db_template('ColormapInfo'));
    setappdata(hFig, 'MovingTimeBar', 0);
end


%% ===========================================================================
%  ===== FIGURE CALLBACKS ====================================================
%  ===========================================================================
%% ===== CURRENT TIME CHANGED =====
% Usage: CurrentTimeChangedCallback(iDS, iFig)
%
% Operations: - Move time cursor (vertical line at current time)
%             - Move text cursor (text field representing the current time frame)
function CurrentTimeChangedCallback(iDS, iFig)
    global GlobalData;
    % Get current display structure
    DisplayHandles = GlobalData.DataSet(iDS).Figure(iFig).Handles;
    % Get current time frame
    CurrentTime = GlobalData.UserTimeWindow.CurrentTime;
    % Time cursor
    if ~isempty([DisplayHandles.hCursor]) && all(ishandle([DisplayHandles.hCursor]))
        % Move time cursor to current time frame
        set([DisplayHandles.hCursor], 'Xdata', [CurrentTime CurrentTime]);
    end
    % Text time cursor
    if ~isempty(DisplayHandles(1).hTextCursor) && ishandle(DisplayHandles(1).hTextCursor)
        % Format current time
        [timeUnit, isRaw, precision] = panel_time('GetTimeUnit');
        textCursor = panel_time('FormatValue', CurrentTime, timeUnit, precision);
        textCursor = [textCursor ' ' timeUnit];
        % Move text cursor to current time frame
        set(DisplayHandles(1).hTextCursor, 'String', textCursor);
    end
end


%% ===== SELECTED ROW CHANGED =====
function SelectedRowChangedCallback(iDS, iFig)
    global GlobalData;
    % Ignore figures with multiple axes
    if (length(GlobalData.DataSet(iDS).Figure(iFig).Handles) ~= 1)
        return;
    end
    % Get figure appdata
    hFig = GlobalData.DataSet(iDS).Figure(iFig).hFigure;
    % Get current selection for the figure
    curSelRows = GetFigSelectedRows(hFig);
    % Get new selection that the figure should show (keep only the ones available for this figure)
    allFigRows = GlobalData.DataSet(iDS).Figure(iFig).Handles.LinesLabels;
    newSelRows = intersect(GlobalData.DataViewer.SelectedRows, allFigRows);
    % Sensors to select
    rowsToSel = setdiff(newSelRows, curSelRows);
    if ~isempty(rowsToSel)
        SetFigSelectedRows(hFig, rowsToSel, 1);
    end
    % Sensors to unselect
    rowsToUnsel = setdiff(curSelRows, newSelRows);
    if ~isempty(rowsToUnsel)
        SetFigSelectedRows(hFig, rowsToUnsel, 0);
    end
end


%% ===== UNIFORMIZE SCALES =====
% Uniformize or not all the TimeSeries scales
%
% Usage:  UniformizeTimeSeriesScales(isUniform)
%         UniformizeTimeSeriesScales()
function UniformizeTimeSeriesScales(isUniform)
    global GlobalData;
    % Parse inputs
    if (nargin < 1)
        isUniform = bst_get('UniformizeTimeSeriesScales');
    end
    % === UNIFORMIZE ===
    if (isUniform)
        % FigureList : {EEG[iDS,iFig], MEG[iDS,iFig], OTHER[iDS,iFig], SOURCES_AM[iDS,iFig], Val>0.01[iDS,iFig]}
        FigureList       = {[], [], [], [], []};
        % CurDataMinMax : {EEG[min,max], MEG[min,max], OTHER[min,max], SOURCES_AM[min,max], Val>0.01[min,max]}
        FigureDataMinMax = {[0,0], [0,0], [0,0], [0,0], [0,0]};
        % Process all the TimeSeries figures, and set the YLim to the maximum one
        for iDS = 1:length(GlobalData.DataSet)
            % Process all figures
            for iFig = 1:length(GlobalData.DataSet(iDS).Figure)
                Handles = GlobalData.DataSet(iDS).Figure(iFig).Handles;
                TsInfo = getappdata(GlobalData.DataSet(iDS).Figure(iFig).hFigure, 'TsInfo');
                % If time series displayed in column for this figure: ignore it
                if ~ismember(GlobalData.DataSet(iDS).Figure(iFig).Id.Type, {'DataTimeSeries', 'ResultsTimeSeries'}) || strcmpi(TsInfo.DisplayMode, 'column')
                    continue
                end
                % Process each graph separately
                for iAxes = 1:length(Handles)
                    % Get figure data minimum and maximum
                    CurDataMinMax = Handles(iAxes).DataMinMax;
                    % Process only if DataMinMax is a valid field
                    if isempty(CurDataMinMax) || (CurDataMinMax(1) >= CurDataMinMax(2))
                        continue;
                    end
                    % Uniformization depends on the DataType displayed in the figure
                    switch (GlobalData.DataSet(iDS).Figure(iFig).Id.Type)
                        % Recordings time series : uniformize modality by modality
                        case 'DataTimeSeries'
                            % LARGE VALUES
                            if (CurDataMinMax(2) > 0.01)
                                iType = 5;
                            else
                                switch(GlobalData.DataSet(iDS).Figure(iFig).Id.Modality)
                                    case {'EEG', 'ECOG', 'SEEG', '$EEG', '$ECOG', '$SEEG'}
                                        iType = 1;
                                    case {'MEG', 'MEG GRAD', 'MEG MAG', '$MEG', '$MEG GRAD', '$MEG MAG'}
                                        iType = 2;
                                    otherwise
                                        iType = 3;
                                end
                            end
                        % Recordings time series : uniformize all the windows together
                        case 'ResultsTimeSeries'
                            fmax = max(abs(CurDataMinMax));
                            % Results in Amper.meter (display in picoAmper.meter)
                            if (fmax > 0) && (fmax < 1e-4)
                                iType = 4;
                            % Stat on Results
                            elseif (fmax > 0)
                                iType = 5;
                            end
                    end
                    FigureList{iType} = [FigureList{iType}; iDS, iFig];
                    FigureDataMinMax{iType} = [min(FigureDataMinMax{iType}(1), CurDataMinMax(1)), ...
                                               max(FigureDataMinMax{iType}(2), CurDataMinMax(2))];
                end
            end
        end

        % Unformize TimeSeries figures
        for iMod = 1:length(FigureList)
            for i = 1:size(FigureList{iMod}, 1)
                if (FigureDataMinMax{iMod}(1) >= FigureDataMinMax{iMod}(2))
                    continue;
                end
                % Get figure and axes handles
                sFigure = GlobalData.DataSet(FigureList{iMod}(i,1)).Figure(FigureList{iMod}(i,2));
                hFig  = sFigure.hFigure;
                % Process each graph separately
                for iPlot = 1:length(sFigure.Handles)
                    hAxes = sFigure.Handles(iPlot).hAxes;
                    % Get maximal value
                    fmax = max(abs(FigureDataMinMax{iMod})) * sFigure.Handles(iPlot).DisplayFactor;
                    % If displaying absolute values (only positive values)
                    if (FigureDataMinMax{iMod}(1) >= 0)
                        ylim = 1.05 .* [0, fmax];
                    % Else : displaying positive and negative values
                    else
                        ylim = 1.05 .* [-fmax, fmax];
                    end      
                    % Update figure Y-axis limits
                    set(hAxes, 'YLim', ylim);
                    setappdata(hAxes, 'YLimInit', ylim);
                    % Update TimeCursor position
                    hCursor = findobj(hAxes, '-depth', 1, 'Tag', 'Cursor');
                    set(hCursor, 'YData', ylim);
                end
            end
        end
       
    % === UN-UNIFORMIZE ===
    else
        % Process all the TimeSeries figures, and set the YLim to the maximum one
        for iDS = 1:length(GlobalData.DataSet)
            for iFig = 1:length(GlobalData.DataSet(iDS).Figure)
                % Get figure handles
                Handles = GlobalData.DataSet(iDS).Figure(iFig).Handles;
                TsInfo = getappdata(GlobalData.DataSet(iDS).Figure(iFig).hFigure, 'TsInfo');
                % Skip the unmananged types of figures
                if ~ismember(GlobalData.DataSet(iDS).Figure(iFig).Id.Type, {'DataTimeSeries', 'ResultsTimeSeries'}) || strcmpi(TsInfo.DisplayMode, 'column')
                    continue;
                end
                % Loop on figure axes
                for iAxes = 1:length(Handles)
                    % Process only if DataMinMax is a valid field
                    CurDataMinMax = Handles(iAxes).DataMinMax;
                    if isempty(CurDataMinMax) || (CurDataMinMax(1) >= CurDataMinMax(2))
                        continue;
                    end
                    % Get figure and axes handles
                    hFig = GlobalData.DataSet(iDS).Figure(iFig).hFigure;
                    hAxes = Handles(iAxes).hAxes;
                    % Get maximal value
                    fmax = max(abs(CurDataMinMax)) * Handles(iAxes).DisplayFactor;
                    % If displaying absolute values (only positive values)
                    if (CurDataMinMax(1) >= 0)
                        ylim = 1.05 .* [0, fmax];
                    % Else : displaying positive and negative values
                    else
                        ylim = 1.05 .* [-fmax, fmax];
                    end    
                    % Update figure Y-axis limits
                    set(hAxes, 'YLim', ylim);
                    setappdata(hAxes, 'YLimInit', ylim);
                    % Update TimeCursor position
                    hCursor = findobj(hAxes, '-depth', 1, 'Tag', 'Cursor');
                    set(hCursor, 'YData', ylim);
                end
            end
        end
    end
end



%% ===========================================================================
%  ===== KEYBOARD AND MOUSE CALLBACKS ========================================
%  ===========================================================================
%% ===== FIGURE MOUSE DOWN =====
function FigureMouseDownCallback(hFig, ev)
    global GlobalData;
    % Get selected object in this figure
    hObj = get(hFig,'CurrentObject');
    if isempty(hObj)
        return;
    end
    % Get object tag
    objTag = get(hObj, 'Tag');
    % Re-select main axes
    drawnow;
    hAxes = findobj(hFig, '-depth', 1, 'tag', 'AxesGraph');
    % If more than one axes object: select one using "gca"
    if (length(hAxes) > 1)
        if any(hAxes == gca)
            hAxes = gca;
        else
            hAxes = hAxes(1);
        end
    end
    % Set axes as current object
    set(hFig,'CurrentObject', hAxes(1), 'CurrentAxes', hAxes(1));
    % Get figure properties
    MouseStatus = get(hFig, 'SelectionType');
    isStatic = getappdata(hFig, 'isStatic');
    % If shift button pressed: ignore click on lines
    if strcmpi(MouseStatus, 'extend') && strcmpi(objTag, 'DataLine')
        % Replace with a click on the axes
        objTag = 'AxesGraph';
        hObj = get(hObj, 'Parent');
    end
    
    % Switch between available graphic objects
    switch (objTag)
        case {'DataTimeSeries', 'ResultsTimeSeries'}
            % Figure: Keep the main axes as clicked object
            hAxes = hAxes(1);
        case 'AxesGraph'
            % Axes: selectec axes = the one that was clicked
            hAxes = hObj;
        case 'DataLine'
            % Time series lines: select
            if (~strcmpi(MouseStatus, 'alt') || (get(hObj, 'LineWidth') > 1))
                LineClickedCallback(hObj);
                return;
            end
        case 'AxesRawTimeBar'
            % Raw time bar: change time window
            timePos = get(hObj, 'CurrentPoint');
            timePos = timePos(1,1) - (GlobalData.UserTimeWindow.Time(2)-GlobalData.UserTimeWindow.Time(1)) / 2;
            panel_record('SetStartTime', timePos);
            return;
        case 'UserTime'
            % Raw time marker patch: ignore click
            setappdata(hFig, 'MovingTimeBar', hObj);
            hAxes = get(hObj, 'Parent');
        case {'TimeSelectionPatch', 'TimeZeroLine', 'Cursor', 'TextCursor', 'GFP', 'GFPTitle'}
            hAxes = get(hObj, 'Parent');
        case 'legend'
            legendButtonDownFcn = get(hObj, 'ButtonDownFcn');
            legendButtonDownFcn{1}(hObj, ev, legendButtonDownFcn{2});
            return
        case 'EventDots'
            % Force updating the figure selection before the mouse release, because if no the events are not the ones we need
            bst_figures('SetCurrentFigure', hFig, '2D');
            % Get events
            events = panel_record('GetEvents');
            % Get event type
            iEvt = get(hObj, 'UserData');
            % Get raw bar (time or events)
            hRawBar = get(hObj, 'Parent');
            % Get mouse time
            timePos = get(hRawBar, 'CurrentPoint');
            % Get the closest event
            evtTimes = events(iEvt).times;
            if (size(evtTimes, 1) == 1)
                iOccur = bst_closest(timePos(1), evtTimes);
            else
                iOccur = bst_closest(timePos(1), evtTimes(:));
                iOccur = ceil(iOccur / 2);
            end
            % Select event in panel "Raw"
            panel_record('SetSelectedEvent', iEvt, iOccur);
            % Move to this specific time
            panel_record('JumpToEvent', iEvt, iOccur);
            return
        otherwise
            % Any other object: consider as a click on the main axes
    end

    % ===== PROCESS CLICKS ON MAIN TS AXES =====
    % Start an action (Move time cursor, pan)
    switch(MouseStatus)
        % Left click
        case 'normal'
            clickAction = 'selection'; 
            % Initialize time selection
            if ~isStatic
                X = GetMouseTime(hFig, hAxes);
                setappdata(hFig, 'GraphSelection', [X, Inf]);
            else
                setappdata(hFig, 'GraphSelection', []);
            end
        % CTRL+Mouse, or Mouse right
        case 'alt'
            clickAction = 'pan';
        % SHIFT+Mouse
        case 'extend'
            clickAction = 'pan';
        % DOUBLE CLICK
        case 'open'
            ResetViewLinked(hFig);
            return;
        % OTHER : nothing to do
        otherwise
            return
    end

    % Reset the motion flag
    setappdata(hFig, 'hasMoved', 0);
    % Record mouse location in the figure coordinates system
    setappdata(hFig, 'clickPositionFigure', get(hFig, 'CurrentPoint'));
    % Record action to perform when the mouse is moved
    setappdata(hFig, 'clickAction', clickAction);
    % Record axes ibject that was clicked (usefull when more than one axes object in figure)
    setappdata(hFig, 'clickSource', hAxes);
    % Register MouseMoved callbacks for current figure
    set(hFig, 'WindowButtonMotionFcn', @FigureMouseMoveCallback);
end


%% ===== FIGURE MOUSE MOVE =====
function FigureMouseMoveCallback(hFig, event)  
    global GlobalData;
    % Get current mouse action
    clickAction = getappdata(hFig, 'clickAction');
    hAxes = getappdata(hFig, 'clickSource');
    if isempty(clickAction) || isempty(hAxes)
        return
    end
    % Set the motion flag
    setappdata(hFig, 'hasMoved', 1);
    % Get current mouse location
    curptFigure = get(hFig, 'CurrentPoint');
    motionFigure = (curptFigure - getappdata(hFig, 'clickPositionFigure')) / 100;
    % Update click point location
    setappdata(hFig, 'clickPositionFigure', curptFigure);

    % Switch between different actions (Pan, Rotate, Contrast)
    switch(clickAction)                          
        case 'pan'
            % Get initial XLim and YLim
            XLimInit = getappdata(hAxes, 'XLimInit');
            YLimInit = getappdata(hAxes, 'YLimInit');
            % Move view along X axis
            XLim = get(hAxes, 'XLim');
            XLim = XLim - (XLim(2) - XLim(1)) * motionFigure(1);
            XLim = limitInterval(XLim, XLimInit);
            set(hAxes, 'XLim', XLim);
            % Move view along Y axis
            YLim = get(hAxes, 'YLim');
            YLim_prev = YLim;
            YLim = YLim - (YLim(2) - YLim(1)) * motionFigure(2);
            YLim = limitInterval(YLim, YLimInit);
            set(hAxes, 'YLim', YLim);
            % Update raw events bar xlim
            UpdateRawXlim(hFig, XLim);
            
        case 'selection'
            % Update figure selection
            %bst_figures('SetCurrentFigure', hFig, '2D');
            % Get time selection
            MovingTimeBar = getappdata(hFig, 'MovingTimeBar');
            GraphSelection = getappdata(hFig, 'GraphSelection');
            % Time selection
            if (MovingTimeBar == 0) && ~isempty(GraphSelection)
                % Update time selection
                GraphSelection(2) = GetMouseTime(hFig, hAxes);
                SetTimeSelectionLinked(hFig, GraphSelection);
            % Move time bar
            elseif (MovingTimeBar ~= 0)
                % Get time bar patch
                xBar = get(MovingTimeBar, 'XData');
                % Get current mouse time position
                xMouse = get(hAxes, 'CurrentPoint');
                xMouse = xMouse(1);
                startBar = xMouse - (GraphSelection(1) - GlobalData.UserTimeWindow.Time(1));
                % Get previous bar position
                xBar = startBar + [0, 1, 1, 0] * (xBar(2)-xBar(1));
                % Block in the XLim bounds
                %XLim = get(hAxes, 'XLim');
                XLim = GlobalData.FullTimeWindow.Epochs(GlobalData.FullTimeWindow.CurrentEpoch).Time([1, end]);
                if (min(xBar) < XLim(1))
                    xBar = xBar - min(xBar) + XLim(1);
                elseif (max(xBar) > XLim(2))
                    xBar = xBar - max(xBar) + XLim(2);
                end
                % Update bar
                set(MovingTimeBar, 'XData', xBar);
            end
    end
end
            

%% ===== FIGURE MOUSE UP =====        
function FigureMouseUpCallback(hFig, event)
    % Get mouse state
    hasMoved    = getappdata(hFig, 'hasMoved');
    MouseStatus = get(hFig, 'SelectionType');
    MovingTimeBar = getappdata(hFig, 'MovingTimeBar');
    % Reset figure mouse fields
    setappdata(hFig, 'clickAction', '');
    setappdata(hFig, 'hasMoved', 0);
    setappdata(hFig, 'MovingTimeBar', 0);
    % Get axes handles
    hAxes = getappdata(hFig, 'clickSource');
    if isempty(hAxes) || ~ishandle(hAxes)
        return
    end
    
    % If mouse has not moved: popup or time change
    if ~hasMoved && ~isempty(MouseStatus)
        % Get new time
        X = GetMouseTime(hFig, hAxes);
        % Change time
        switch (MouseStatus)
            % LEFT CLICK  /  SHIFT+Mouse
            case {'normal', 'extend'}
                % Move time cursor to new time
                hCursor = findobj(hAxes, '-depth', 1, 'Tag', 'Cursor');
                set(hCursor, 'XData', [X,X]);
                drawnow;
                % Update the current time in the whole application      
                panel_time('SetCurrentTime', X);
                % Remove previous time selection patch
                SetTimeSelectionLinked(hFig, []);
            % CTRL+Mouse, or Mouse right
            case 'alt'
                DisplayFigurePopup(hFig, [], X);            
        end
    % If time bar was moved: update time
    elseif hasMoved && MovingTimeBar
        % Get time bar patch
        xBar = get(MovingTimeBar, 'XData');
        % Set new start time to the beginning of the bar
        panel_record('SetStartTime', xBar(1));
    % If time selection was defined: check if its length is non-zero
    elseif hasMoved
        GraphSelection = getappdata(hFig, 'GraphSelection');
        if (length(GraphSelection) == 2) && (GraphSelection(1) == GraphSelection(2))
            SetTimeSelectionLinked(hFig, []);
        end
    end
    
    % Reset MouseMove callbacks for current figure
    set(hFig, 'WindowButtonMotionFcn', []); 
    % Remove mouse callbacks appdata
    setappdata(hFig, 'clickSource', []);
    setappdata(hFig, 'clickAction', []);
    % Update figure selection
    bst_figures('SetCurrentFigure', hFig, '2D');
end


%% ===== GET MOUSE TIME =====
function X = GetMouseTime(hFig, hAxes)
    % Get current point in axes
    X = get(hAxes, 'CurrentPoint');
    XLim = get(hAxes, 'XLim');
    % Check whether cursor is out of display time bounds
    X = bst_saturate(X(1,1), XLim);
    % Get the time vector
    TimeVector = getappdata(hFig, 'TimeVector');
    % Select the closest point in time vector
    if ~isempty(TimeVector)
        X = TimeVector(bst_closest(X,TimeVector));
    end
end

%% ===== SET TIME SELECTION: LINKED =====
% Apply the same time selection to similar figures
function SetTimeSelectionLinked(hFig, GraphSelection)
    % Get all the time-series figures
    hAllFigs = bst_figures('GetFiguresByType', {'DataTimeSeries', 'ResultsTimeSeries'});
    % Place the input figure in first
    hAllFigs(hAllFigs == hFig) = [];
    hAllFigs = [hFig, hAllFigs];
    % Loop over all the figures found
    for i = 1:length(hAllFigs)
        % Set figure configuration
        setappdata(hAllFigs(i), 'GraphSelection', GraphSelection);
        % Redraw time selection
        DrawTimeSelection(hAllFigs(i));
    end
end

%% ===== SET TIME SELECTION: MANUAL INPUT =====
% Define manually the time selection for a given TimeSeries figure
% USAGE:  SetTimeSelectionManual(hFig, newSelection)
%         SetTimeSelectionManual(hFig)
function SetTimeSelectionManual(hFig, newSelection)
    % Get the time vector for this figure
    TimeVector = getappdata(hFig, 'TimeVector');
    % Ask for a time window
    if (nargin < 2) || isempty(newSelection)
        newSelection = panel_time('InputTimeWindow', TimeVector([1,end]), 'Set time selection');
        if isempty(newSelection)
            return
        end
    end
    % Select the closest point in time vector
    newSelection = TimeVector(bst_closest(newSelection,TimeVector));
    % Draw new time selection
    SetTimeSelectionLinked(hFig, newSelection);
end

%% ===== DRAW TIME SELECTION =====
function DrawTimeSelection(hFig)
    % Get axes (can have more than one)
    hAxesList = findobj(hFig, '-depth', 1, 'Tag', 'AxesGraph');
    % Get time selection
    GraphSelection = getappdata(hFig, 'GraphSelection');
    % Process all the axes
    for i = 1:length(hAxesList)
        hAxes = hAxesList(i);
        % Draw new time selection patch
        if ~isempty(GraphSelection) && ~isinf(GraphSelection(2))
            % Get axes limits 
            YLim = get(hAxes, 'YLim');
            % Get previous patch
            hTimePatch = findobj(hAxes, '-depth', 1, 'Tag', 'TimeSelectionPatch');
            % Position of the square patch
            XData = [GraphSelection(1), GraphSelection(2), GraphSelection(2), GraphSelection(1)];
            YData = [YLim(1), YLim(1), YLim(2), YLim(2)];
            ZData = [0.01 0.01 0.01 0.01];
            % If patch do not exist yet: create it
            if isempty(hTimePatch)
                % BUG WITH PATCH + ERASEMODE
                % Draw patch
                hTimePatch = patch('XData', XData, ...
                                   'YData', YData, ...
                                   'ZData', ZData, ...
                                   'EraseMode', 'xor', ...   % BUG OPENGL
                                   'LineWidth', 1, ...
                                   'FaceColor', [.3 .3 1], ...
                                   'FaceAlpha', 1, ...
                                   ... 'FaceAlpha', .3, ...
                                   'EdgeColor', [.3 .3 1], ...
                                   'EdgeAlpha', 1, ...
                                   'Tag',       'TimeSelectionPatch', ...
                                   'Parent',    hAxes);
            % Else, patch already exist: update it
            else
                % Change patch limits
                set(hTimePatch, ...
                    'XData', XData, ...
                    'YData', YData, ...
                    'ZData', ZData, ...
                    ... 'EraseMode', 'xor', ...
                    'Visible', 'on');
            end
            
            % Get current time units
            [timeUnit, isRaw, precision] = panel_time('GetTimeUnit');
            % Get selection label
            hTextTimeSel = findobj(hFig, '-depth', 1, 'Tag', 'TextTimeSel');
            if ~isempty(hTextTimeSel)
                % Format string
                strMin = panel_time('FormatValue', min(GraphSelection), timeUnit, precision);
                strMax = panel_time('FormatValue', max(GraphSelection), timeUnit, precision);
                strSelection = ['Selection: [' strMin ' ' timeUnit ', ' strMax ' ' timeUnit ']'];
                strLength = sprintf('         Duration: [%d ms]', round(abs(GraphSelection(2) - GraphSelection(1)) * 1000));
                % Update label
                set(hTextTimeSel, 'Visible', 'on', 'String', [strSelection, strLength]);
            end
            
        else
            % Remove previous selection patch            
            set(findobj(hAxes, '-depth', 1, 'Tag', 'TimeSelectionPatch'), 'Visible', 'off');
            set(findobj(hFig, '-depth', 1, 'Tag', 'TextTimeSel'), 'Visible', 'off');
        end
    end
end


%% ===== FIGURE MOUSE WHEEL =====
function FigureMouseWheelCallback(hFig, event)
    if isempty(event)
        return;
    elseif (event.VerticalScrollCount < 0)
        % ZOOM IN
        Factor = 1 - event.VerticalScrollCount ./ 10;
    elseif (event.VerticalScrollCount > 0)
        % ZOOM OUT
        Factor = 1./(1 + event.VerticalScrollCount ./ 10);
    end
    if getappdata(hFig, 'isControlKeyDown') 
        FigureZoom(hFig, 'vertical', Factor);
    elseif getappdata(hFig, 'isShiftKeyDown')
        UpdateTimeSeriesFactor(hFig, Factor);
    else
        FigureZoomLinked(hFig, 'horizontal', Factor);
    end
end


%% ===== FIGURE ZOOM: LINKED =====
% Apply the same zoom operations to similar figures
function FigureZoomLinked(hFig, direction, Factor)
    % Get all the time-series figures
    hAllFigs = bst_figures('GetFiguresByType', {'DataTimeSeries', 'ResultsTimeSeries'});
    % Place the input figure in first
    hAllFigs(hAllFigs == hFig) = [];
    hAllFigs = [hFig, hAllFigs];
    % Loop over all the figures found
    for i = 1:length(hAllFigs)
        % Apply zoom factor
        FigureZoom(hAllFigs(i), direction, Factor);
    end
end


%% ===== FIGURE ZOOM =====
function FigureZoom(hFig, direction, Factor)
    % Get list of axes in this figure
    hAxes = findobj(hFig, '-depth', 1, 'Tag', 'AxesGraph');
    % Possible directions
    switch lower(direction)
        case 'vertical'
            % Process axes individually
            for i = 1:length(hAxes)
                % Get current zoom factor
                YLim = get(hAxes(i), 'YLim');
                Ylength = YLim(2) - YLim(1);
                % In case everything is positive: zoom from the bottom
                if (YLim(1) >= 0)
                    YLim = [YLim(1), YLim(1) + Ylength/Factor];
                % Else: zoom from the middle
                else
                    Ycenter = (YLim(2) + YLim(1)) / 2;
                    YLim = [Ycenter - Ylength/Factor/2, Ycenter + Ylength/Factor/2];
                end
                % Update zoom factor
                set(hAxes(i), 'YLim', YLim);
                % Set the time cursor height to the maximum of the display
                hCursor = findobj(hAxes(i), '-depth', 1, 'Tag', 'Cursor');
                set(hCursor, 'YData', YLim)
            end
        case 'horizontal'
            % Get current time frame
            hCursor = findobj(hAxes(1), '-depth', 1, 'Tag', 'Cursor');
            Xcurrent = get(hCursor, 'XData');
            % No time window (averaged time): skip
            if isempty(Xcurrent)
                return;
            end
            Xcurrent = Xcurrent(1);
            % Get initial XLim 
            XLimInit = getappdata(hAxes(1), 'XLimInit');
            % Get current limits
            XLim = get(hAxes(1), 'XLim');
            % Apply zoom factor
            Xlength = XLim(2) - XLim(1);
            XLim = [Xcurrent - Xlength/Factor/2, Xcurrent + Xlength/Factor/2];
            XLim = limitInterval(XLim, XLimInit);
            % Apply to ALL Axes in the figure
            set(hAxes, 'XLim', XLim);
            % RAW: Set the time limits of the events bar
            UpdateRawXlim(hFig, XLim);
    end
end


%% ===== RESET VIEW: LINKED =====
function ResetViewLinked(hFig)
    % Get all the time-series figures
    hAllFigs = bst_figures('GetFiguresByType', {'DataTimeSeries', 'ResultsTimeSeries'});
    % Place the input figure in first
    hAllFigs(hAllFigs == hFig) = [];
    hAllFigs = [hFig, hAllFigs];
    % Loop over all the figures found
    for i = 1:length(hAllFigs)
        ResetView(hAllFigs(i));
    end
end

%% ===== RESET VIEW =====
function ResetView(hFig)
    % Get list of axes in this figure
    hAxes = findobj(hFig, '-depth', 1, 'Tag', 'AxesGraph');
    % Loop the different axes
    for i = 1:length(hAxes)
        % Restore initial X and Y zooms
        XLim = getappdata(hAxes(i), 'XLimInit');
        YLim = getappdata(hAxes(i), 'YLimInit');
        set(hAxes(i), 'XLim', XLim);
        set(hAxes(i), 'YLim', YLim);
        % Set the time cursor height to the maximum of the display
        hCursor = findobj(hAxes(i), '-depth', 1, 'Tag', 'Cursor');
        set(hCursor, 'YData', YLim)
    end
    % Update raw events bar xlim
    UpdateRawXlim(hFig);
end


%% ===== RESIZE FUNCTION =====
function ResizeCallback(hFig, ev)
    % Get figure size
    figPos = get(hFig, 'Position');
    % Get all the axes in the figure
    hAxes = findobj(hFig, '-depth', 1, 'tag', 'AxesGraph');
    nAxes = length(hAxes);
    % Is time bar display or hidden (for RAW viewer)
    NoTimeBar = getappdata(hFig, 'NoTimeBar');
    
    % ===== REPOSITION AXES =====
    % With or without time bars
    if ~isempty(NoTimeBar) && NoTimeBar
        axesPos = [58,  1,  figPos(3)-85,  figPos(4)];
    else
        axesPos = [58, 40,  figPos(3)-85,  figPos(4)-60];
    end
    % Reposition axes
    if (nAxes == 1)
        set(hAxes, 'Position', max(axesPos,1));
    elseif (nAxes > 1)
        % Re-order axes in the original order
        iOrder = get(hAxes, 'UserData');
        hAxes([iOrder{:}]) = hAxes;
        % Get number of rows and columns
        nRows = floor(sqrt(nAxes));
        nCols = ceil(nAxes / nRows);
        margins = [58, 40, 27, 20];
        axesSize = [(figPos(3)-margins(3)) / nCols, ...
                    (figPos(4)-margins(4)) / nRows];
        % Resize all the axes independently
        for iAxes = 1:nAxes
            % Get position of this axes in the figure
            iRow = ceil(iAxes / nCols);
            iCol = iAxes - (iRow-1)*nCols;
            % Calculate axes position
            plotPos = [(iCol-1)*axesSize(1) + margins(1), (nRows-iRow)*axesSize(2) + margins(2), axesSize(1)-margins(1), axesSize(2)-margins(2)];
            % Update axes positions
            set(hAxes(iAxes), 'Position', max(plotPos,1));
        end
    end

    % ===== REPOSITION TIME BAR =====
    hRawTimeBar = findobj(hFig, '-depth', 1, 'Tag', 'AxesRawTimeBar');
    if ~isempty(hRawTimeBar)
        hButtonForward   = findobj(hFig, '-depth', 1, 'Tag', 'ButtonForward');
        hButtonBackward  = findobj(hFig, '-depth', 1, 'Tag', 'ButtonBackward');
        hButtonBackward2 = findobj(hFig, '-depth', 1, 'Tag', 'ButtonBackward2');
        % Update time bar position
        barPos = [axesPos(1), 5, axesPos(3) - 40, 12];
        set(hRawTimeBar, 'Units', 'pixels', 'Position', barPos);
        % Update buttons position
        set(hButtonForward,  'Position',  [barPos(1) + barPos(3) + 33, 3, 30, 16]);
        set(hButtonBackward, 'Position',  [barPos(1) + barPos(3) + 3, 3, 30, 16]);
        set(hButtonBackward2, 'Position', [barPos(1) - 30, 3, 30, 16]);
    end
    
    % ===== REPOSITION EVENTS BAR =====
    hEventsBar = findobj(hFig, '-depth', 1, 'Tag', 'AxesEventsBar');
    % Update events bar position
    if ~isempty(hEventsBar)
        eventPos = [axesPos(1), axesPos(2) + axesPos(4) + 1, axesPos(3), figPos(4) - axesPos(2) - axesPos(4) - 1];
        eventPos(eventPos < 1) = 1;
        set(hEventsBar, 'Units', 'pixels', 'Position', eventPos);
    end
    
    % ===== REPOSITION TIME LABEL =====
    hTextCursor = findobj(hFig, '-depth', 1, 'Tag', 'TextCursor');
    % Update events bar position
    if ~isempty(hTextCursor)
        eventPos = [3, axesPos(2) + axesPos(4) + 1, axesPos(1) - 2, figPos(4) - axesPos(2) - axesPos(4) - 5];
        eventPos(eventPos < 1) = 1;
        set(hTextCursor, 'Units', 'pixels', 'Position', eventPos);
    end
    
    % ===== REPOSITION TIME SELECTION LABEL =====
    hTextTimeSel = findobj(hFig, '-depth', 1, 'Tag', 'TextTimeSel');
    if ~isempty(hTextTimeSel)
        % Update time bar position
        barPos = [axesPos(1), 3, axesPos(3) - 40, 16];
        barPos(barPos < 1) = 1;
        set(hTextTimeSel, 'Units', 'pixels', 'Position', barPos);
    end
    
    % ===== REPOSITION SCALE CONTROLS =====
    hButtonGainMinus = findobj(hFig, '-depth', 1, 'Tag', 'ButtonGainMinus');
    hButtonGainPlus  = findobj(hFig, '-depth', 1, 'Tag', 'ButtonGainPlus');
    hButtonAutoScale = findobj(hFig, '-depth', 1, 'Tag', 'ButtonAutoScale');
    hButtonSetScaleY = findobj(hFig, '-depth', 1, 'Tag', 'ButtonSetScaleY');
    hButtonFlipY     = findobj(hFig, '-depth', 1, 'Tag', 'ButtonFlipY');
    hButtonZoomTimePlus  = findobj(hFig, '-depth', 1, 'Tag', 'ButtonZoomTimePlus');
    hButtonZoomTimeMinus = findobj(hFig, '-depth', 1, 'Tag', 'ButtonZoomTimeMinus');
    % Update gain buttons
    butSize = 22;
    if ~isempty(hButtonGainMinus)
        set(hButtonGainMinus, 'Position', [figPos(3)-butSize-1, 45, butSize, butSize]);
        set(hButtonGainPlus,  'Position', [figPos(3)-butSize-1, 70, butSize, butSize]);
    end
    if ~isempty(hButtonAutoScale)
        set(hButtonAutoScale, 'Position', [figPos(3)-butSize-1, 110, butSize, butSize]);
    end
    if ~isempty(hButtonSetScaleY)
        set(hButtonSetScaleY, 'Position', [figPos(3)-butSize-1, 135, butSize, butSize]);
    end
    if ~isempty(hButtonFlipY)
        set(hButtonFlipY,  'Position', [figPos(3)-butSize-1, 160, butSize, butSize]);
    end
    if ~isempty(hButtonZoomTimePlus)
        set(hButtonZoomTimePlus,   'Position', [figPos(3) - 65, 3, butSize, butSize]);
        set(hButtonZoomTimeMinus,  'Position', [figPos(3) - 40, 3, butSize, butSize]);
    end

    % ===== REPOSITION SCALE BAR =====
     hColumnScale = findobj(hFig, '-depth', 1, 'Tag', 'AxesColumnScale');
     if ~isempty(hColumnScale)
        % Update scale bar position
        xBar = axesPos(1) + axesPos(3) + 2;
        barPos = [xBar, axesPos(2), figPos(3)-xBar, axesPos(4)];
        set(hColumnScale, 'Units',    'pixels', ...
                          'Position', barPos);             
     end
end


%% ===== KEYBOARD CALLBACK =====
function FigureKeyPressedCallback(hFig, ev)
    global GlobalData;
    % Convert event to Matlab (in case it's coming from a java callback)
    [keyEvent, isControl, isShift] = gui_brainstorm('ConvertKeyEvent', ev);
    if isempty(keyEvent.Key)
        return
    end
    % If shift is already pressed, no need to process the "shift" press again
    if (getappdata(hFig, 'isShiftKeyDown') && strcmpi(keyEvent.Key, 'shift')) || ...
       (getappdata(hFig, 'isControlKeyDown') && strcmpi(keyEvent.Key, 'control'))     
        return
    end
    % Prevent multiple executions
    hAxes = findobj(hFig, '-depth', 1, 'Tag', 'AxesGraph')';
    set([hFig hAxes], 'BusyAction', 'cancel');
    % Get figure description
    [hFig, iFig, iDS] = bst_figures('GetFigure', hFig);
    % ===== GET SELECTED CHANNELS =====
    Modality = GlobalData.DataSet(iDS).Figure(iFig).Id.Modality;
    isMenuSelectedChannels = 0;
    if ~isempty(iDS) && ~isempty(GlobalData.DataSet(iDS).Channel)
        % Get channel selection
        [SelectedRows, iSelectedRows] = GetFigSelectedRows(hFig, {GlobalData.DataSet(iDS).Channel.Name});
        if ~isempty(iSelectedRows) && ~isempty(Modality) && (Modality(1) ~= '$')
            isMenuSelectedChannels = 1;
        end
    end
    % Check if it is a full data file or not
    isFullDataFile = ~isempty(Modality) && (Modality(1) ~= '$') && ~strcmpi(Modality, 'Sources');
    isRaw = strcmpi(GlobalData.DataSet(iDS).Measures.DataType, 'raw');
    
    % If Shift key is pressed: channel selection 
    if getappdata(hFig, 'isShiftKeyDown')
        % Other key: process it 
        isProcessed = panel_montage('ProcessKeyPress', hFig, keyEvent.Key);
        if isProcessed
            return
        end
    end
    % Process event
    switch (keyEvent.Key)
        % === LEFT, RIGHT, PAGEUP, PAGEDOWN ===
        case {'leftarrow', 'rightarrow', 'uparrow', 'downarrow', 'pageup', 'pagedown', 'home', 'end'}
            panel_time('TimeKeyCallback', keyEvent);
            
        % === DATABASE NAVIGATOR ===
        case {'f1', 'f2', 'f3', 'f4'}
            if isRaw
                panel_time('TimeKeyCallback', keyEvent);
            else
                bst_figures('NavigatorKeyPress', hFig, keyEvent);
            end
        % === DATA FILES ===
        % CTRL+E : Add/delete event (raw viewer only)
        case 'e'
            if isControl && ~isempty(GlobalData.DataSet(iDS).Measures.sFile) % && isFullDataFile 
                panel_record('ToggleEvent');
            end
        % CTRL+B : Accept/reject trial or time segment
        case 'b'
            if isControl && isFullDataFile
                switch lower(GlobalData.DataSet(iDS).Measures.DataType)
                    case 'recordings'
                        % Get data file
                        DataFile = GlobalData.DataSet(iDS).DataFile;
                        if isempty(DataFile)
                            return
                        end
                        % Get study
                        [sStudy, iStudy, iData] = bst_get('DataFile', DataFile);
                        % Change status
                        process_detectbad('SetTrialStatus', DataFile, ~sStudy.Data(iData).BadTrial);
                    case 'raw'
                        panel_record('RejectTimeSegment');
                end
            end
        % CTRL+D : Dock figure
        case 'd'
            if isControl
                isDocked = strcmpi(get(hFig, 'WindowStyle'), 'docked');
                bst_figures('DockFigure', hFig, ~isDocked);
            end
        % CTRL+I : Save as image
        case 'i'
            if isControl
                out_figure_image(hFig);
            end
        % CTRL+J : Save as image
        case 'j'
            if isControl
                out_figure_image(hFig, 'Viewer');
            end
        % CTRL+S : Sources (first results file)
        case 's'
            if isControl && isFullDataFile
                bst_figures('ViewResults', hFig);
            end
        % CTRL+T : Default topography
        case 't'           
            if isControl && isFullDataFile
                bst_figures('ViewTopography', hFig);
            end
        % RETURN: VIEW SELECTED CHANNELS
        case 'return'
            if isMenuSelectedChannels && isFullDataFile               
                DisplayDataSelectedChannels(iDS, SelectedRows, GlobalData.DataSet(iDS).Figure(iFig).Id.Modality);
            end
        % DELETE: SET AS BAD
        case 'delete'
            if isMenuSelectedChannels && isFullDataFile && (length(GlobalData.DataSet(iDS).Figure(iFig).SelectedChannels) ~= length(iSelectedRows))
                % SHIFT+DELETE: Set all channels as bad but the selected one
                if isShift
                    newChannelFlag = GlobalData.DataSet(iDS).Measures.ChannelFlag;
                    newChannelFlag(GlobalData.DataSet(iDS).Figure(iFig).SelectedChannels) = -1;
                    newChannelFlag(iSelectedRows) = 1;
                % DELETE
                elseif isMenuSelectedChannels && isFullDataFile
                    newChannelFlag = GlobalData.DataSet(iDS).Measures.ChannelFlag;
                    newChannelFlag(iSelectedRows) = -1;
                end
                % Save new channel flag
                panel_channel_editor('UpdateChannelFlag', GlobalData.DataSet(iDS).DataFile, newChannelFlag);
                % Reset selected channels
                bst_figures('SetSelectedRows', []);
            end
            
        % ESCAPE: CLEAR
        case 'escape'
            % SHIFT+ESCAPE: Set all channels as good
            if isShift && isFullDataFile
                ChannelFlagGood = ones(size(GlobalData.DataSet(iDS).Measures.ChannelFlag));
                panel_channel_editor('UpdateChannelFlag', GlobalData.DataSet(iDS).DataFile, ChannelFlagGood)
            % ESCAPE: Reset channel selection
            else
                bst_figures('SetSelectedRows', []);
            end          
        % CONTROL: SAVE BUTTON PRESS
        case 'control'
            setappdata(hFig, 'isControlKeyDown', true);
        % SHIFT: SAVE BUTTON PRESS
        case 'shift'
            setappdata(hFig, 'isShiftKeyDown', true);
        otherwise
            % Not found: test based on the character that was generated
            if isfield(keyEvent, 'Character') && ~isempty(keyEvent.Character)
                switch (keyEvent.Character)
                    % PLUS/MINUS: GAIN CONTROL
                    case '+'
                        UpdateTimeSeriesFactor(hFig, 1.1);
                    case '-'
                        UpdateTimeSeriesFactor(hFig, .9091);
                    % COPY VIEW OPTIONS
                    case '='
                        if isFullDataFile
                            CopyDisplayOptions(hFig, 1, 1);
                        end
                    case '*'
                        if isFullDataFile
                            CopyDisplayOptions(hFig, 1, 0);
                        end
                    % RAW VIEWER: Configurable shortcuts
                    case {'1','2','3','4','5','6','7','8','9'}
                        if ~isempty(GlobalData.DataSet(iDS).Measures.sFile)
                            % Get current configuration
                            RawViewerOptions = bst_get('RawViewerOptions');
                            % If the key that was pressed is in the shortcuts list
                            iShortcut = find(strcmpi(RawViewerOptions.Shortcuts(:,1), keyEvent.Character));
                            % If shortcut was found: call the corresponding function
                            if ~isempty(iShortcut) && ~isempty(RawViewerOptions.Shortcuts{iShortcut,2})
                                panel_record('ToggleEvent', RawViewerOptions.Shortcuts{iShortcut,2});
                            end
                        end
                end
            end
    end
    % Restore events
    if ~isempty(hFig) && ishandle(hFig)
        hAxes = findobj(hFig, '-depth', 1, 'Tag', 'AxesGraph')';
        set([hFig hAxes], 'BusyAction', 'queue');
    end
end



%% ===== KEYBOARD CALLBACK: RELEASE =====
function FigureKeyReleasedCallback(hFig, keyEvent)
    % Alter the behavior of the mouse wheel scroll so as that CTRL+Scroll
    % changes the vertical scale instead of the horizontal one 
    switch (keyEvent.Key)
        case 'control'
            setappdata(hFig, 'isControlKeyDown', false);
        case 'shift'
            setappdata(hFig, 'isShiftKeyDown', false);
    end
end


%% ===== UPDATE TIME SERIES FACTOR =====
function UpdateTimeSeriesFactor(hFig, changeFactor, isSave)
    global GlobalData;
    if (nargin < 3) || isempty(isSave)
        isSave = 1;
    end
    % Get figure description
    [hFig, iFig, iDS] = bst_figures('GetFigure', hFig);
    Handles = GlobalData.DataSet(iDS).Figure(iFig).Handles;
    TsInfo = getappdata(hFig, 'TsInfo');
    % If figure is not in Column display mode: nothing to do
    isColumn = strcmpi(TsInfo.DisplayMode, 'column');
    % Update all axes
    for iAxes = 1:length(Handles)
        % Column plot: update the gain of the lines plotted
        if isColumn
            % Update figure lines
            for iLine = 1:length(Handles(iAxes).hLines)
                % Skip the channels that are not visible
                if (Handles(iAxes).ChannelOffsets(iLine) < 0)
                    continue;
                end
                % Get values
                YData = get(Handles(iAxes).hLines(iLine), 'YData');
                % Re-center them on zero, and change the factor
                YData = (YData - Handles(iAxes).ChannelOffsets(iLine)) * changeFactor + Handles(iAxes).ChannelOffsets(iLine);
                % Update value
                set(Handles(iAxes).hLines(iLine), 'YData', YData);
            end
            % Update factor value
            GlobalData.DataSet(iDS).Figure(iFig).Handles(iAxes).DisplayFactor = Handles(iAxes).DisplayFactor * changeFactor;
        % Else: Zoom/unzoom vertically in the graph
        else
            FigureZoom(hFig, 'vertical', changeFactor);
        end
    end
    % Save current change factor
    if isSave && isColumn
        SetDefaultFactor(iDS, iFig, changeFactor);
    end
    % Update scale bar (not for spectrum figures)
    if ~strcmpi(GlobalData.DataSet(iDS).Figure(iFig).Id.Type, 'Spectrum')
        UpdateScaleBar(iDS, iFig);
    end
end


%% ===== SET DEFAULT DISPLAY FACTOR =====
function SetDefaultFactor(iDS, iFig, changeFactor)
    global GlobalData;
    % Get modality
    Modality = GlobalData.DataSet(iDS).Figure(iFig).Id.Modality;
    % Default factors list is still empty
    if isempty(GlobalData.DataViewer.DefaultFactor)
        GlobalData.DataViewer.DefaultFactor = {Modality, changeFactor};
    else
        iMod = find(cellfun(@(c)isequal(c,Modality), GlobalData.DataViewer.DefaultFactor(:,1)));
        if isempty(iMod)
            iMod = size(GlobalData.DataViewer.DefaultFactor, 1) + 1;
            GlobalData.DataViewer.DefaultFactor(iMod, :) = {Modality, changeFactor};
        else
            GlobalData.DataViewer.DefaultFactor{iMod,2} = changeFactor * GlobalData.DataViewer.DefaultFactor{iMod,2};
        end
    end
end


%% ===== GET DEFAULT FACTOR =====
function defaultFactor = GetDefaultFactor(Modality)
    global GlobalData
    if isempty(GlobalData.DataViewer.DefaultFactor)
        defaultFactor = 1;
    else
        iMod = find(cellfun(@(c)isequal(c,Modality), GlobalData.DataViewer.DefaultFactor(:,1)));
        if isempty(iMod)
            defaultFactor = 1;
        else
            defaultFactor = GlobalData.DataViewer.DefaultFactor{iMod,2};
        end
    end
end


%% ===== LINE CLICKED =====
function LineClickedCallback(hLine, ev)
    global GlobalData;
    % Get figure handle
    hFig = get(hLine, 'Parent');
    while ~strcmpi(get(hFig, 'Type'), 'figure') || isempty(hFig)
        hFig = get(hFig, 'Parent');
    end
    if isempty(hFig)
        return;
    end
    hAxes = get(hLine, 'Parent');
    setappdata(hFig, 'clickSource', []);
    % Get figure description
    [hFig, iFig, iDS] = bst_figures('GetFigure', hFig);
    sFig = GlobalData.DataSet(iDS).Figure(iFig);
    % Accept only mouse selection for DataTimeSeries AND real recordings
    if ~strcmpi(sFig.Id.Type, 'DataTimeSeries') || isempty(sFig.Id.Modality)
        return
    end
    % Get channel indice (relative to montage display rows)
    iClickChan = find(sFig.Handles.hLines == hLine);
    if isempty(iClickChan)
        return
    end
    % Get channels selected in the figure (relative to Channel structure)
    if ~isempty(sFig.SelectedChannels)
        iFigChannels = sFig.SelectedChannels;
    else
        iFigChannels = 1:length(GlobalData.DataSet(iDS).Channel);
    end
    % Get figure montage
    TsInfo = getappdata(hFig, 'TsInfo');
    % If there is a montage selected
    if ~isempty(TsInfo.MontageName)
        % Get selected montage
        sMontage = panel_montage('GetMontage', TsInfo.MontageName, hFig);
        if isempty(sMontage)
            disp(['BST> Error: Invalid montage name "' TsInfo.MontageName '".']);
            return;
        end
        % Get montage indices
        [iMontageChannels, iMatrixChan, iMatrixDisp] = panel_montage('GetMontageChannels', sMontage, {GlobalData.DataSet(iDS).Channel(iFigChannels).Name});
        % Get the entry corresponding to the clicked channel in the montage
        ChannelName = sMontage.DispNames{iMatrixDisp(iClickChan)};
        channelLabel = ['Channel: ' ChannelName];
    else
        iChannel = iFigChannels(iClickChan);
        ChannelName = char(GlobalData.DataSet(iDS).Channel(iChannel).Name);
        channelLabel = sprintf('Channel #%d: %s', iChannel, ChannelName);
    end
    % Get click type
    isRightClick = strcmpi(get(hFig, 'SelectionType'), 'alt');
    % Right click : display popup menu
    if isRightClick
        % Display popup menu (with the channel name as a title)
        setappdata(hFig, 'clickSource', hAxes);
        DisplayFigurePopup(hFig, channelLabel);   
        setappdata(hFig, 'clickSource', []);
    % Left click: Select/unselect line
    else
        bst_figures('ToggleSelectedRow', ChannelName);
    end             
    % Update figure selection
    bst_figures('SetCurrentFigure', hFig, '2D');
end


%% ===== GET SELECTED ROWS =====
% USAGE:   [RowNames, iRows] = GetFigSelectedRows(hFig, AllRows);
%           RowNames         = GetFigSelectedRows(hFig);
function [RowNames, iRows] = GetFigSelectedRows(hFig, AllRows)
    global GlobalData;
    % Initialize retuned values
    RowNames = [];
    iRows = [];
    % Find figure
    [hFig, iFig, iDS] = bst_figures('GetFigure', hFig);
    sHandles = GlobalData.DataSet(iDS).Figure(iFig).Handles(1);
    % Get lines widths
    iValidLines = find(ishandle(sHandles.hLines));
    LineWidth = get(sHandles.hLines(iValidLines), 'LineWidth');
    % Find selected lines
    if iscell(LineWidth)
        iRowsFig = find([LineWidth{:}] > 1.5);
    else
        iRowsFig = find(LineWidth > 1.5);
    end
    % Nothing found
    if isempty(iRowsFig)
        return;
    end
    iRowsFig = iValidLines(iRowsFig);
    % Return row names
    RowNames = sort(sHandles.LinesLabels(iRowsFig));
    % If required: get the indices
    if (nargout >= 2) && (nargin >=2) && ~isempty(AllRows)
        % Find row indices in the full list
        for i = 1:length(RowNames)
            iRows = [iRows, find(strcmpi(RowNames{i}, AllRows))];
        end
    end
end


%% ===== SET SELECTED ROWS =====
% USAGE: 
function SetFigSelectedRows(hFig, RowNames, isSelect)
    global GlobalData;
    % Find figure
    [hFig, iFig, iDS] = bst_figures('GetFigure', hFig);
    sHandles = GlobalData.DataSet(iDS).Figure(iFig).Handles;
    % Get lines indices
    if ~isempty(RowNames)
        iLines = [];
        for i = 1:length(RowNames)
            iLines = [iLines, find(strcmpi(RowNames{i}, sHandles.LinesLabels))];
        end
    else
        iLines  = 1:length(sHandles.hLines);
    end
    % Process each line
    for i = 1:length(iLines)
        % Get line handle
        hLine = sHandles.hLines(iLines(i));
        % If not a valid handle: skip
        if ~ishandle(hLine)
            continue;
        end
        % Newly selected channels : Paint lines in thick red
        if isSelect
            ZData     = 3 + 0.*get(hLine, 'ZData');
            LineWidth = 2;
            Color     = 'r';
        % Deselected channels : Restore initial color and width
        else
            ZData     = 1.5 + 0.*get(hLine, 'ZData');
            LineWidth = .5;
            Color     = sHandles.LinesColor(iLines(i),:);
        end
        set(hLine, 'LineWidth', LineWidth, 'Color', Color, 'ZData', ZData);
    end
end


%% ===== DISPLAY SELECTED CHANNELS =====
% Usage : DisplayDataSelectedChannels(iDS, SelectedRows, Modality)
function DisplayDataSelectedChannels(iDS, SelectedRows, Modality)
    global GlobalData;
    % Reset selection
    bst_figures('SetSelectedRows', []);
    % Get selected sensors
    DataFile = GlobalData.DataSet(iDS).DataFile;
    % Plot selected sensors
    view_timeseries(DataFile, Modality, SelectedRows);
end


%% ===== HIDE/SHOW LEGENDS =====
function ToggleAxesProperty(hAxes, propName)
    switch get(hAxes(1), propName)
        case 'on'
            set(hAxes, propName, 'off');
        case 'off'
            set(hAxes, propName, 'on');
    end
end


%% ===== POPUP MENU =====
function DisplayFigurePopup(hFig, menuTitle, curTime)
    import java.awt.event.KeyEvent;
    import javax.swing.KeyStroke;
    import org.brainstorm.icon.*;
    global GlobalData;
    % If menuTitle not specified
    if (nargin < 2)
        menuTitle = '';
    end
    if (nargin < 3)
        curTime = [];
    end
    % Get figure description
    [hFig, iFig, iDS] = bst_figures('GetFigure', hFig);
    FigId = GlobalData.DataSet(iDS).Figure(iFig).Id;
    TsInfo = getappdata(hFig, 'TsInfo');
    % Get axes handles
    hAxes = getappdata(hFig, 'clickSource');
    if isempty(hAxes)
        return
    end
    % Get study
    DataFile = GlobalData.DataSet(iDS).DataFile;
    if ~isempty(DataFile)
        [sStudy, iStudy, iData] = bst_get('AnyFile', DataFile);
    end
    isRaw = strcmpi(GlobalData.DataSet(iDS).Measures.DataType, 'raw');
    
    % Create popup menu
    jPopup = java_create('javax.swing.JPopupMenu');
    % Menu title
    if ~isempty(menuTitle)
        gui_component('Label', jPopup, [], ['<HTML><BLOCKQUOTE><B>' menuTitle '</B></BLOCKQUOTE></HTML>'], [], [], [], []);
        jPopup.addSeparator();
    end
        
    % ==== EVENTS ====
    % If an event structure is defined
    if ~isempty(GlobalData.DataSet(iDS).Measures.sFile)
        % Add / delete event
        jItem = gui_component('MenuItem', jPopup, [], 'Add / delete event', IconLoader.ICON_EVT_OCCUR_ADD, [], @(h,ev)bst_call(@panel_record, 'ToggleEvent'), []);
        jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_E, KeyEvent.CTRL_MASK));
        % Only for RAW files
        if isRaw
            % Reject time segment
            jItem = gui_component('MenuItem', jPopup, [], 'Reject time segment', IconLoader.ICON_BAD, [], @(h,ev)bst_call(@panel_record, 'RejectTimeSegment'), []);
            jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_B, KeyEvent.CTRL_MASK));
            jPopup.addSeparator();
            % Previous / next event
            jItem = gui_component('MenuItem', jPopup, [], 'Jump to previous event', IconLoader.ICON_ARROW_LEFT, [], @(h,ev)bst_call(@panel_record, 'JumpToEvent', 'leftarrow'), []);
            jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_LEFT, KeyEvent.SHIFT_MASK));
            jItem = gui_component('MenuItem', jPopup, [], 'Jump to next event', IconLoader.ICON_ARROW_RIGHT, [], @(h,ev)bst_call(@panel_record, 'JumpToEvent', 'rightarrow'), []);
            jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_RIGHT, KeyEvent.SHIFT_MASK));
        end
        jPopup.addSeparator();
    end
    
    % ==== DISPLAY OTHER FIGURES ====
    % Only for MEG and EEG time series
    Modality = GlobalData.DataSet(iDS).Figure(iFig).Id.Modality;   
    isSource = strcmpi(Modality, 'Sources');        
    if ~isempty(Modality) && (Modality(1) ~= '$') && ~isSource
        % === View TOPOGRAPHY ===
        jItem = gui_component('MenuItem', jPopup, [], 'View topography', IconLoader.ICON_TOPOGRAPHY, [], @(h,ev)bst_figures('ViewTopography', hFig), []);
        jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_T, KeyEvent.CTRL_MASK));   
        % === View SOURCES ===
        if ~isempty(sStudy.Result)
            jItem = gui_component('MenuItem', jPopup, [], 'View sources', IconLoader.ICON_RESULTS, [], @(h,ev)bst_figures('ViewResults', hFig), []);
            jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_S, KeyEvent.CTRL_MASK));
        end
        jPopup.addSeparator();
    end
    
    % ==== MENU: CHANNELS ====
    if ~isempty(iDS) && ~isempty(Modality) && (Modality(1) ~= '$') && ~isSource && ~isempty(DataFile)
        % === SET TRIAL GOOD/BAD ===
        if strcmpi(GlobalData.DataSet(iDS).Measures.DataType, 'recordings')
            if (sStudy.Data(iData).BadTrial == 0)
                jItem = gui_component('MenuItem', jPopup, [], 'Reject trial', IconLoader.ICON_BAD, [], @(h,ev)bst_call(@process_detectbad, 'SetTrialStatus', DataFile, 1), []);
            else
                jItem = gui_component('MenuItem', jPopup, [], 'Accept trial', IconLoader.ICON_GOOD, [], @(h,ev)bst_call(@process_detectbad, 'SetTrialStatus', DataFile, 0), []);
            end
            jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_B, KeyEvent.CTRL_MASK));
        end    

        % Create figures menu
        jMenuSelected = gui_component('Menu', jPopup, [], 'Channels', IconLoader.ICON_CHANNEL, [], [], []);
        [SelectedRows, iSelectedRows] = GetFigSelectedRows(hFig, {GlobalData.DataSet(iDS).Channel.Name});
        % Excludes figures without selection and display-only figures (modality name starts with '$')
        if ~isempty(iSelectedRows) && ~isempty(GlobalData.DataSet(iDS).Figure(iFig).Id.Modality) && (GlobalData.DataSet(iDS).Figure(iFig).Id.Modality(1) ~= '$')
            % === VIEW TIME SERIES ===
            jItem = gui_component('MenuItem', jMenuSelected, [], 'View selected', IconLoader.ICON_TS_DISPLAY, [], @(h, ev)DisplayDataSelectedChannels(iDS, SelectedRows, GlobalData.DataSet(iDS).Figure(iFig).Id.Modality), []);
            jItem.setAccelerator(KeyStroke.getKeyStroke(int32(KeyEvent.VK_ENTER), 0)); % ENTER
            % === SET SELECTED AS BAD CHANNELS ===
            newChannelFlag = GlobalData.DataSet(iDS).Measures.ChannelFlag;
            newChannelFlag(iSelectedRows) = -1;
            jItem = gui_component('MenuItem', jMenuSelected, [], 'Mark selected as bad', IconLoader.ICON_BAD, [], @(h, ev)panel_channel_editor('UpdateChannelFlag', DataFile, newChannelFlag), []);
            jItem.setAccelerator(KeyStroke.getKeyStroke(int32(KeyEvent.VK_DELETE), 0)); % DEL
            % === SET NON-SELECTED AS BAD CHANNELS ===
            newChannelFlag = GlobalData.DataSet(iDS).Measures.ChannelFlag;
            newChannelFlag(GlobalData.DataSet(iDS).Figure(iFig).SelectedChannels) = -1;
            newChannelFlag(iSelectedRows) = 1;
            jItem = gui_component('MenuItem', jMenuSelected, [], 'Mark non-selected as bad', IconLoader.ICON_BAD, [], @(h, ev)panel_channel_editor('UpdateChannelFlag', DataFile, newChannelFlag), []);
            jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_DELETE, KeyEvent.SHIFT_MASK));
            % === RESET SELECTION ===
            jItem = gui_component('MenuItem', jMenuSelected, [], 'Reset selection', IconLoader.ICON_SURFACE, [], @(h, ev)bst_figures('SetSelectedRows',[]), []);
            jItem.setAccelerator(KeyStroke.getKeyStroke(int32(KeyEvent.VK_ESCAPE), 0)); % ESCAPE
        end
        % Separator if previous items
        if (jMenuSelected.getItemCount() > 0)
            jMenuSelected.addSeparator();
        end

        % ==== MARK ALL CHANNELS AS GOOD ====
        ChannelFlagGood = ones(size(GlobalData.DataSet(iDS).Measures.ChannelFlag));
        jItem = gui_component('MenuItem', jMenuSelected, [], 'Mark all channels as good', IconLoader.ICON_GOOD, [], @(h, ev)panel_channel_editor('UpdateChannelFlag', DataFile, ChannelFlagGood), []);
        jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_ESCAPE, KeyEvent.SHIFT_MASK));
        % ==== EDIT CHANNEL FLAG =====
        gui_component('MenuItem', jMenuSelected, [], 'Edit good/bad channels...', IconLoader.ICON_GOODBAD, [], @(h,ev)gui_edit_channelflag(DataFile), []);
    end
    
    % ==== MENU: CHANNELS DISPLAY ====
    % Available only for "column" display mode
    if ~isSource && ~isempty(Modality) && (Modality(1) ~= '$') && (isempty(TsInfo) || isempty(TsInfo.RowNames))
        jMenuSelections = gui_component('Menu', jPopup, [], 'Montage', IconLoader.ICON_TS_DISPLAY_MODE, [], [], []);
        % Montages
        panel_montage('CreateFigurePopupMenu', jMenuSelections, hFig);
    end
    
    % ==== MENU: NAVIGATION ====
    if ~isSource && ~isRaw && ~isempty(DataFile)
        jMenuNavigator = gui_component('Menu', jPopup, [], 'Navigator', IconLoader.ICON_NEXT_SUBJECT, [], [], []);
        bst_navigator('CreateNavigatorMenu', jMenuNavigator);
    end
    
    % ==== MENU: SELECTION ====
    jMenuSelection = gui_component('Menu', jPopup, [], 'Time selection', IconLoader.ICON_TS_SELECTION, [], [], []);
    % Move time sursor
    if ~isempty(curTime)
        gui_component('MenuItem', jMenuSelection, [], 'Set current time   [Shift+Click]', [], [], @(h,ev)panel_time('SetCurrentTime', curTime), []);
        jMenuSelection.addSeparator();
    end
    % Set selection
    gui_component('MenuItem', jMenuSelection, [], 'Set selection manually...', IconLoader.ICON_TS_SELECTION, [], @(h,ev)SetTimeSelectionManual(hFig), []);
    % Get current time selection
    GraphSelection = getappdata(hFig, 'GraphSelection');
    isTimeSelection = ~isempty(GraphSelection) && ~isinf(GraphSelection(2));
    if isTimeSelection
        jMenuSelection.addSeparator();
        % ONLY FOR ORIGINAL DATA FILES
        if strcmpi(FigId.Type, 'DataTimeSeries') && ~isempty(FigId.Modality) && (FigId.Modality(1) ~= '$') && ~isempty(DataFile)
            % === SAVE MEAN AS NEW FILE ===
            gui_component('MenuItem', jMenuSelection, [], 'Average over time', IconLoader.ICON_TS_NEW, [], @(h,ev)bst_call(@out_figure_timeseries, hFig, 'Database', 'SelectedChannels', 'SelectedTime', 'TimeAverage'), []);
            % === REJECT TIME SEGMENT ===
            if isRaw
                jItem = gui_component('MenuItem', jMenuSelection, [], 'Reject time segment', IconLoader.ICON_BAD, [], @(h,ev)bst_call(@panel_record, 'RejectTimeSegment'), []);
                jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_B, KeyEvent.CTRL_MASK));
            end
            % === EXPORT TO DATABASE ===
            jMenuSelection.addSeparator();
            gui_component('MenuItem', jMenuSelection, [], 'Export to database', IconLoader.ICON_DATA, [], @(h,ev)bst_call(@out_figure_timeseries, hFig, 'Database', 'SelectedChannels', 'SelectedTime'), []);
        end

        % === EXPORT TO FILE ===
        gui_component('MenuItem', jMenuSelection, [], 'Export to file', IconLoader.ICON_TS_EXPORT, [], @(h,ev)bst_call(@out_figure_timeseries, hFig, [], 'SelectedChannels', 'SelectedTime'), []);
        % === EXPORT TO MATLAB ===
        gui_component('MenuItem', jMenuSelection, [], 'Export to Matlab', IconLoader.ICON_MATLAB_EXPORT, [], @(h,ev)bst_call(@out_figure_timeseries, hFig, 'Variable', 'SelectedChannels', 'SelectedTime'), []);
    end
    
    % ==== MENU: SNAPSHOT ====
    jPopup.addSeparator();
    jMenuSave = gui_component('Menu', jPopup, [], 'Snapshots', IconLoader.ICON_SNAPSHOT, [], [], []);
        % === SAVE AS IMAGE ===
        jItem = gui_component('MenuItem', jMenuSave, [], 'Save as image', IconLoader.ICON_SAVE, [], @(h,ev)bst_call(@out_figure_image, hFig), []);
        jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_I, KeyEvent.CTRL_MASK));
        % === OPEN AS IMAGE ===
        jItem = gui_component('MenuItem', jMenuSave, [], 'Open as image', IconLoader.ICON_IMAGE, [], @(h,ev)bst_call(@out_figure_image, hFig, 'Viewer'), []);
        jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_J, KeyEvent.CTRL_MASK));
        jMenuSave.addSeparator();
        
        % === CONTACT SHEET ===
        % Default output dir
        LastUsedDirs = bst_get('LastUsedDirs');
        DefaultOutputDir = LastUsedDirs.ExportImage;
        % Output menu
        gui_component('MenuItem', jMenuSave, [], 'Contact sheet', IconLoader.ICON_CONTACTSHEET, [], @(h,ev)view_contactsheet(hFig, 'time', 'fig', DefaultOutputDir), []);
        jMenuSave.addSeparator();
        
        % === EXPORT TO DATABASE ===
        if strcmpi(FigId.Type, 'DataTimeSeries') && ~isempty(FigId.Modality) && (FigId.Modality(1) ~= '$') && ~isempty(DataFile)
            gui_component('MenuItem', jMenuSave, [], 'Export to database', IconLoader.ICON_DATA, [], @(h,ev)bst_call(@out_figure_timeseries, hFig, 'Database', 'SelectedChannels'), []);
        end
        % === EXPORT TO FILE ===
        gui_component('MenuItem', jMenuSave, [], 'Export to file', IconLoader.ICON_TS_EXPORT, [], @(h,ev)bst_call(@out_figure_timeseries, hFig, [], 'SelectedChannels'), []);
        % === EXPORT TO MATLAB ===
        gui_component('MenuItem', jMenuSave, [], 'Export to Matlab', IconLoader.ICON_MATLAB_EXPORT, [], @(h,ev)bst_call(@out_figure_timeseries, hFig, 'Variable', 'SelectedChannels'), []);

    % ==== MENU: FIGURE ====    
    jMenuFigure = gui_component('Menu', jPopup, [], 'Figure', IconLoader.ICON_LAYOUT_SHOWALL, [], [], []);
        % === FIGURE CONFIG ===
        % Set fixed resolution
        if strcmpi(FigId.Type, 'DataTimeSeries')
            jItem = gui_component('CheckBoxMenuItem', jMenuFigure, [], 'Set axis resolution', IconLoader.ICON_MATRIX, [], @(h,ev)SetResolution(iDS, iFig), []);
            jItem.setSelected(TsInfo.NormalizeAmp);
        end
        % Normalize amplitudes
        jItem = gui_component('CheckBoxMenuItem', jMenuFigure, [], 'Uniform figure scales', IconLoader.ICON_TS_SYNCRO, [], @(h,ev)panel_record('UniformTimeSeries_Callback',h,ev), []);
        jItem.setSelected(bst_get('UniformizeTimeSeriesScales'));
        % Normalize amplitudes
        if strcmpi(FigId.Type, 'DataTimeSeries')
            jItem = gui_component('CheckBoxMenuItem', jMenuFigure, [], 'Normalize signals', [], [], @(h,ev)SetNormalizeAmp(iDS, iFig, ~TsInfo.NormalizeAmp), []);
            jItem.setSelected(TsInfo.NormalizeAmp);
        end
        % XGrid
        jMenuFigure.addSeparator();
        isXGrid = strcmpi(get(hAxes(1), 'XGrid'), 'on');
        jItem = gui_component('CheckBoxMenuItem', jMenuFigure, [], 'XGrid', IconLoader.ICON_GRID_X, [], @(h,ev)ToggleAxesProperty(hAxes, 'XGrid'), []);
        jItem.setSelected(isXGrid);
        % YGrid
        isYGrid = strcmpi(get(hAxes(1), 'YGrid'), 'on');
        jItem = gui_component('CheckBoxMenuItem', jMenuFigure, [], 'YGrid', IconLoader.ICON_GRID_Y, [], @(h,ev)ToggleAxesProperty(hAxes, 'YGrid'), []);
        jItem.setSelected(isYGrid);
        % Change background color
        jMenuFigure.addSeparator();
        gui_component('MenuItem', jMenuFigure, [], 'Change background color', IconLoader.ICON_COLOR_SELECTION, [], @(h,ev)bst_figures('ChangeBackgroundColor', hFig), []);
        
        % === MATLAB CONTROLS ===
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
        % Recordings
        if strcmpi(FigId.Type, 'DataTimeSeries') && ~isempty(FigId.Modality) && (FigId.Modality(1) ~= '$') && ~isempty(DataFile)
            jMenuFigure.addSeparator();
            % Copy figure properties
            jItem = gui_component('MenuItem', jMenuFigure, [], 'Apply view to all figures', IconLoader.ICON_TS_SYNCRO, [], @(h,ev)CopyDisplayOptions(hFig, 1, 1), []);
            jItem.setAccelerator(KeyStroke.getKeyStroke('=', 0));
            jItem = gui_component('MenuItem', jMenuFigure, [], 'Apply montage to all figures', IconLoader.ICON_TS_SYNCRO, [], @(h,ev)CopyDisplayOptions(hFig, 1, 0), []);
            jItem.setAccelerator(KeyStroke.getKeyStroke('*', 0));
            % Clone figure
            jMenuFigure.addSeparator();
            gui_component('MenuItem', jMenuFigure, [], 'Clone figure', IconLoader.ICON_COPY, [], @(h,ev)bst_figures('CloneFigure', hFig), []);
        end
    % Display Popup menu
    gui_popup(jPopup, hFig);
end

%% ===== LIMIT INTERVAL =====
function res = limitInterval(interval, bounds)
    % If interval is longer than the bounds segment
    if (interval(2) - interval(1) >= bounds(2) - bounds(1))
        res = bounds;
    % If interval begins before the bound
    elseif interval(1) < bounds(1)
        res = [bounds(1), ...
               bounds(1) + interval(2) - interval(1)];
    % If interval stops after the bound
    elseif interval(2) > bounds(2)
        res(1) = interval(1) - (interval(2) - bounds(2));
        res(2) = res(1) + interval(2) - interval(1);   
    else
        res = interval;
    end
end


%% ===========================================================================
%  ===== PLOT FUNCTIONS ======================================================
%  ===========================================================================
%% ===== GET FIGURE DATA =====
function [F, TsInfo] = GetFigureData(iDS, iFig)
    global GlobalData;
    % ===== GET INFORMATION =====
    hFig = GlobalData.DataSet(iDS).Figure(iFig).hFigure;
    TsInfo = getappdata(hFig, 'TsInfo');
    if isempty(TsInfo)
        return
    end
    % Get selected channels for figure
    selChan = GlobalData.DataSet(iDS).Figure(iFig).SelectedChannels;
    % Get values
    isGradMagScale = 1;
    F = bst_memory('GetRecordingsValues', iDS, selChan, [], isGradMagScale);
    if isempty(F)
        return;
    end
    
    % ===== APPLY MONTAGE =====
    % Get channel names 
    ChanNames = {GlobalData.DataSet(iDS).Channel(selChan).Name};
    iChannels = [];
    % Get montage selected in this figure
    if ~isempty(TsInfo.MontageName)
        % Get montage
        sMontage = panel_montage('GetMontage', TsInfo.MontageName, hFig);
        % Get channel indices in the figure montage
        if ~isempty(sMontage)
            [iChannels, iMatrixChan, iMatrixDisp] = panel_montage('GetMontageChannels', sMontage, ChanNames);
            % No signal to display
            if isempty(iMatrixDisp) && ~isempty(sMontage.ChanNames)
                bst_error(['Montage "' TsInfo.MontageName '" must be edited before being applied to this dataset.' 10 'Select "Edit montages" and check the name of the electrodes.'], 'Invalid montage', 0);
                iChannels = [];
            end
        end
    end
    % Apply montage
    if ~isempty(iChannels)
        % Get display names for the input channels
        F = sMontage.Matrix(iMatrixDisp,iMatrixChan) * F(iChannels,:);
        % Modify channel names
        TsInfo.LinesLabels = sMontage.DispNames(iMatrixDisp)';
    % No montage to apply
    else
        % Lines names=channel names
        TsInfo.LinesLabels = ChanNames';
        % Force: no montage on this figure
        TsInfo.MontageName = [];
    end
    % Convert to cell
    F = {F};
    % Update figure structure
    setappdata(hFig, 'TsInfo', TsInfo);
end


%% ===== PLOT FIGURE =====
% USAGE:  isOk = PlotTimeSeries(iDS, iFig, F)
%         isOk = PlotTimeSeries(iDS, iFig)
function isOk = PlotFigure(iDS, iFig, F)
    global GlobalData;
    isOk = 0;
    % Parse inputs
    if (nargin < 3)
        F = [];
    end
    hFig = GlobalData.DataSet(iDS).Figure(iFig).hFigure;

    % ===== GET DATA =====
    % Get data to display
    if isempty(F)
        [F, TsInfo] = GetFigureData(iDS, iFig);
        % No data
        if isempty(F)
            disp('BST> Error: no data could be found for this figure...');
            return
        end
    else
        hFig = GlobalData.DataSet(iDS).Figure(iFig).hFigure;
        TsInfo = getappdata(hFig, 'TsInfo');
    end
    % Make sure that F is a cell array
    nAxes = length(F);
    % Get time window indices
    [TimeVector, iTime] = bst_memory('GetTimeVector', iDS, [], 'UserTimeWindow');
    TimeVector = TimeVector(iTime);
    % Store the time vector
    setappdata(hFig, 'TimeVector', TimeVector);
    % Get display options
    [iDSRaw, isRaw] = panel_record('GetCurrentDataset', hFig);    
    % Normalize channels?
    if TsInfo.NormalizeAmp
        for ic = 1:length(F)
            F{ic} = bst_bsxfun(@rdivide, F{ic}, max(abs(F{ic}),[],2));
        end
    end
    
    % ===== DISPLAY =====
    % Clear current figure
    clf(hFig);
    % Loop on each axes to plot
    for iAxes = 1:nAxes
        % === GET DATA MAXIMUM ===
        % Displaying normalized data
        if TsInfo.NormalizeAmp
            DataMinMax = [-1, 1];
        % If existing MinMax, use it
        elseif ~TsInfo.AutoScaleY && isfield(GlobalData.DataSet(iDS).Figure(iFig).Handles, 'DataMinMax') && ...
                (iAxes <= length(GlobalData.DataSet(iDS).Figure(iFig).Handles)) && ~isempty(GlobalData.DataSet(iDS).Figure(iFig).Handles(iAxes).DataMinMax) && ...
                (GlobalData.DataSet(iDS).Figure(iFig).Handles(iAxes).DataMinMax(2) ~= GlobalData.DataSet(iDS).Figure(iFig).Handles(iAxes).DataMinMax(1))
            DataMinMax = GlobalData.DataSet(iDS).Figure(iFig).Handles(iAxes).DataMinMax;
        % Calculate minimum/maximum values
        else
            DataMinMax = [min(F{iAxes}(:)), max(F{iAxes}(:))];
        end
        
        % === PLOT AXES ===
        % Make sure that we are drawing in the right figure
        set(0, 'CurrentFigure', hFig);
        % Create axes
        hAxes(iAxes) = subplot('Position', [10*iAxes, 10, 10 10]);
        set(hAxes(iAxes), 'Units', 'pixels', 'UserData', iAxes);
        % Lines labels
        if ~isempty(TsInfo.LinesLabels) 
            if (size(TsInfo.LinesLabels, 2) == nAxes)
                LinesLabels = TsInfo.LinesLabels(:,iAxes);
                % Make sure that only the correct number of entries are taken (to fix case of multiple graphs with different numbers of signals)
                if (length(LinesLabels) > size(F{iAxes},1))
                    LinesLabels = LinesLabels(1:size(F{iAxes},1),:);
                end
            else
                LinesLabels = TsInfo.LinesLabels;
            end
        else
            LinesLabels = [];
        end
        % Lines colors
        if ~isempty(TsInfo.LinesColor) 
            if (size(TsInfo.LinesColor, 2) == nAxes)
                LinesColor = cat(1, TsInfo.LinesColor{:,iAxes});
            else
                LinesColor = cat(1, TsInfo.LinesColor{:});
            end
        else
            LinesColor = [];
        end
        % Plot data in the axes
        PlotHandles(iAxes) = PlotAxes(iDS, hAxes(iAxes), TimeVector, F{iAxes}, TsInfo, DataMinMax, LinesLabels, LinesColor);
        % X Axis legend
        if isRaw || (nAxes > 1)
            xlabel(hAxes(iAxes), ' ');
        else
            xlabel(hAxes(iAxes), 'Time (s)', ...
                'FontSize',    bst_get('FigFont'), ...
                'FontUnits',   'points', ...
                'Interpreter', 'none');
        end
        % Title
        if ~isempty(TsInfo.AxesLabels)
            title(hAxes(iAxes), TsInfo.AxesLabels{iAxes}, ...
                'FontSize',    bst_get('FigFont') + 1, ...
                'FontUnits',   'points', ...
                'Interpreter', 'none');
        end
        % Store initial XLim and YLim
        setappdata(hAxes(iAxes), 'XLimInit', get(hAxes(iAxes), 'XLim'));
        setappdata(hAxes(iAxes), 'YLimInit', get(hAxes(iAxes), 'YLim'));
    end
    % Resize here FOR MAC ONLY (don't now why, if not the display flickers)
    if strncmp(computer,'MAC',3)
        ResizeCallback(hFig, []);
    end
    % Link axes together for zooming/panning
    if (nAxes > 1)
        linkaxes(hAxes, 'x');
    end
    % Update figure list of handles
    GlobalData.DataSet(iDS).Figure(iFig).Handles = PlotHandles;
    % Get figure background color
    bgColor = get(hFig, 'Color');
    
    % ===== EVENT BAR =====
    % Is the time/events bar is required?
    allId = [GlobalData.DataSet(iDS).Figure(1:iFig-1).Id];
    NoTimeBar = isRaw && ((iFig ~= 1) && any(strcmpi({allId.Type}, 'DataTimeSeries')));
    setappdata(hFig, 'NoTimeBar', NoTimeBar);
    % Get figure type
    Modality = GlobalData.DataSet(iDS).Figure(iFig).Id.Modality;
    % If event bar should be displayed
    if (nAxes == 1) && ~NoTimeBar
        % Events bar: Create axes
        hEventsBar = axes('Position', [0, 0, .01, .01]);
        set(hEventsBar, ...
             'Interruptible', 'off', ...
             'BusyAction',    'queue', ...
             'Tag',           'AxesEventsBar', ...
             'YGrid',      'off', ...
             'XGrid',      'off', ...
             'XMinorGrid', 'off', ...
             'XTick',      [], ...
             'YTick',      [], ...
             'TickLength', [0,0], ...
             'Color',      bgColor, ...
             'XLim',       get(hAxes, 'XLim'), ...
             'YLim',       [0 1], ...
             'Box',        'off');   
        % Update events markers+labels in the events bar
        if ~isRaw
            % Plot events dots
            PlotEventsDots_EventsBar(hFig);
        end
    else
        hEventsBar = [];
    end
    
    % ===== TIME TEXT LABEL =====
    % Get background color
    bgcolor = get(hFig, 'Color');
    % Plot time text (for non-static datasets)
    if (GlobalData.DataSet(iDS).Measures.NumberOfSamples > 2) && (~isempty(hEventsBar) || (nAxes > 1))
        % Format current time
        [timeUnit, isRaw, precision] = panel_time('GetTimeUnit');
        textCursor = panel_time('FormatValue', GlobalData.UserTimeWindow.CurrentTime, timeUnit, precision);
        textCursor = [textCursor ' ' timeUnit];
        % Create text object
        PlotHandles(1).hTextCursor = uicontrol(...
            'Style',               'text', ...
            'String',              textCursor, ...
            'Units',               'Pixels', ...
            'HorizontalAlignment', 'left', ...
            'FontUnits',           'points', ...
            'FontSize',            bst_get('FigFont'), ...
            'FontWeight',          'bold', ...
            'ForegroundColor',     [0 0 0], ...
            'BackgroundColor',     bgcolor, ...
            'Parent',              hFig, ...
            'Tag',                 'TextCursor', ...
            'Visible',             get(hFig, 'Visible'));
        % Update figure list of handles
        GlobalData.DataSet(iDS).Figure(iFig).Handles = PlotHandles;
    end
    
    % ===== SELECTION TEXT =====
    if (GlobalData.DataSet(iDS).Measures.NumberOfSamples > 2) && (~isempty(hEventsBar) || (nAxes > 1))
        hTextTimeSel = uicontrol(...
            'Style',               'text', ...
            'String',              'Selection', ...
            'Units',               'Pixels', ...
            'HorizontalAlignment', 'center', ...
            'FontUnits',           'points', ...
            'FontSize',            bst_get('FigFont') + 0.5, ...
            'FontWeight',          'normal', ...
            'ForegroundColor',     [0 0 0], ...
            'BackgroundColor',     bgcolor, ...
            'Parent',              hFig, ...
            'Tag',                 'TextTimeSel', ...
            'Visible',             'off');
    end
    
    % ===== RAW TIME SLIDER =====
    % If the previous figures are also raw time series views: do not plot again the time bar
    if isRaw && ~isempty(Modality) && ~NoTimeBar
        PlotRawTimeBar(iDS, iFig);
    end
    % ===== SCALE BAR =====
    % For column displays: add a scale display
    if ~TsInfo.NormalizeAmp && strcmpi(TsInfo.DisplayMode, 'column') && (nAxes == 1)
        % Create axes
        PlotHandles(1).hColumnScale = axes('Position', [0, 0, .01, .01]);
        set(PlotHandles(1).hColumnScale, ...
            'Interruptible', 'off', ...
            'BusyAction',    'queue', ...
            'Tag',           'AxesColumnScale', ...
            'YGrid',      'off', ...
            'XGrid',      'off', ...
            'XMinorGrid', 'off', ...
            'XTick',      [], ...
            'YTick',      [], ...
            'TickLength', [0,0], ...
            'Color',      bgColor, ...
            'XLim',       [0 1], ...
            'YLim',       get(hAxes, 'YLim'), ...
            'Box',        'off');
        % Update figure list of handles
        GlobalData.DataSet(iDS).Figure(iFig).Handles = PlotHandles;
        % Update scale bar
        UpdateScaleBar(iDS, iFig);
    end
    % Create scale buttons
    if isempty(findobj(hFig, 'Tag', 'ButtonGainPlus'))
        CreateScaleButtons(iDS, iFig);
    end
    % Update sensor selection
    SelectedRowChangedCallback(iDS, iFig)
    % Resize callback if only one axes
    ResizeCallback(hFig, []);
    % Set current object/axes
    set(hFig, 'CurrentAxes', hAxes(1), 'CurrentObject', hAxes(1));
    isOk = 1;
end


%% ===== SHOW TIME CURSOR =====
function SetTimeVisible(hFig, isVisible) %#ok<*DEFNU>
    hTextCursor = findobj(hFig, '-depth', 1, 'Tag', 'TextCursor');
    if ~isempty(hTextCursor)
        if isVisible
            set(hTextCursor, 'Visible', 'on');
        else
            set(hTextCursor, 'Visible', 'off');
        end
    end
end


%% ===== PLOT AXES =====
function PlotHandles = PlotAxes(iDS, hAxes, TimeVector, F, TsInfo, DataMinMax, LinesLabels, LinesColor)
    global GlobalData;
    hold on;
    % Set color table for lines
    nLines = size(F,1);
    DefaultColor = [.2 .2 .2];
    if (nLines > 10)
        set(hAxes, 'ColorOrder', DefaultColor);
        LinesColor = [];
        isLegend = 0;
    elseif isempty(LinesColor)
        if (nLines > 5)
            set(hAxes, 'ColorOrder', DefaultColor);
            isLegend = 0;
        else
            set(hAxes, 'ColorOrder', panel_scout('GetScoutsColorTable'));
            isLegend = 1;
        end
    else
        isLegend = 1;
    end
    % Create handles structure
    PlotHandles = db_template('DisplayHandlesTimeSeries');
    PlotHandles.hAxes = hAxes;
    PlotHandles.DataMinMax = DataMinMax;
    % Replicate inputs when ScoutFunction='All'
    if ~isempty(LinesColor) && (size(LinesColor,1) == 1) && (nLines > 1)
        LinesColor = repmat(LinesColor, nLines, 1);
    end
    if ~isempty(LinesLabels) && (size(LinesLabels,1) == 1) && (nLines > 1)
        LinesLabels = repmat(LinesLabels, nLines, 1);
    end

    % ===== SWITCH DISPLAY MODE =====
    switch (lower(TsInfo.DisplayMode))
        case 'butterfly'
            PlotHandles = PlotAxesButterfly(iDS, hAxes, PlotHandles, TsInfo, TimeVector, F, LinesLabels, isLegend);
        case 'column'
            PlotHandles = PlotAxesColumn(hAxes, PlotHandles, TsInfo, TimeVector, F, LinesLabels);
        otherwise
            error('Invalid display mode.');
    end
    % Color
    if ~isempty(LinesColor)
        for i = 1:nLines
            set(PlotHandles.hLines(i), 'Color', LinesColor(i,:));
        end
        PlotHandles.LinesColor = LinesColor;
    else
        % Get selected lines colors
        tmpColor = get(PlotHandles.hLines, 'Color');
        if iscell(tmpColor)
            tmpColor = cat(1, tmpColor{:});
        end
        PlotHandles.LinesColor = tmpColor;
    end
    % Get lines initial colors
    PlotHandles.LinesLabels = LinesLabels;

    % ===== TIME CURSOR =====
    % Plot time cursor (for non-static datasets)
    if (GlobalData.DataSet(iDS).Measures.NumberOfSamples > 2)
        ZData = 1.6;
        % Get current time
        curTime = GlobalData.UserTimeWindow.CurrentTime;
        YLim = get(hAxes, 'YLim');
        % Vertical line at t=CurrentTime
        PlotHandles.hCursor = line(...
            [curTime curTime], YLim, [ZData ZData], ...
            'LineWidth', 1, ...
            'EraseMode', 'xor', ...
            'Color',     'r', ...
            'Tag',       'Cursor', ...
            'Parent',    hAxes);
    end
    
    % ===== TIME LINES =====
    % Time-zero line
    if ((TimeVector(1) <= 0) && (TimeVector(end) >= 0))
        ZData = 1.1;
        Ymax = max(abs(get(hAxes,'YLim')));
        YData = [-1000, +1000] * Ymax; 
        hTimeZeroLine = line([0 0], YData, [ZData ZData], ...
                             'LineWidth', 1, ...
                             'LineStyle', '--', ...
                             'Color',     .8*[1 1 1], ...
                             'Tag',       'TimeZeroLine', ...
                             'Parent',    hAxes);
    end

    % ===== SHOW AXES =====
    set(hAxes, 'Interruptible', 'off', ...
               'BusyAction',    'queue', ...
               'Tag',           'AxesGraph', ...
               'YGrid',      'off', ...
               'XGrid',      'off', 'XMinorGrid', 'off', ...
               'XLim',       [TimeVector(1), TimeVector(end)], ...
               'Box',        'on', ...
               'FontName',   'Default', ...
               'FontUnits',  'Points', ...
               'FontWeight', 'Normal',...
               'FontSize',   bst_get('FigFont'), ...
               'Units',      'pixels', ...
               'Visible',    'on');
end


%% ===== PLOT AXES BUTTERFLY =====
function PlotHandles = PlotAxesButterfly(iDS, hAxes, PlotHandles, TsInfo, TimeVector, F, LinesLabels, isLegend)
    global GlobalData;
    ZData = 1.5;
  
    % ===== YLIM =====
    % Get data units
    Fmax = max(abs(PlotHandles.DataMinMax));
    [fScaled, fFactor, fUnits] = bst_getunits( Fmax, TsInfo.Modality );
    % Set display Factor
    PlotHandles.DisplayFactor = fFactor;
    % Get automatic YLim
    if (Fmax ~= 0)
        % If data to plot are absolute values
        if (PlotHandles.DataMinMax(1) >= -eps)
            YLim = 1.05 * PlotHandles.DisplayFactor * [0, Fmax];
        % Else, there are positive and negative values
        else
            YLim = 1.05 * PlotHandles.DisplayFactor * [-Fmax, Fmax];
        end
    else
        YLim = [-1, 1];
    end
    
    % ===== PLOT TIME SERIES =====
    % Plot lines
    PlotHandles.hLines = line(TimeVector, ...
                          F' * fFactor, ...
                          ZData * ones(size(F)), ...
                          'Parent', hAxes);
    set(PlotHandles.hLines, 'Tag', 'DataLine');
    PlotHandles.ChannelOffsets = zeros(size(F,1), 1);

    % ===== SET UP AXIS =====
    % Set axes legend for Y axis
    if ~isempty(fUnits)
        strAmp = ['Amplitude (' fUnits ')'];
    else
        strAmp = 'Amplitude';
    end
    ylabel(hAxes, strAmp, ...
        'FontSize',    bst_get('FigFont'), ...
        'FontUnits',   'points', ...
        'Interpreter', 'tex');
    % Set Y ticks in auto mode
    set(hAxes, 'YLim',           YLim, ...
               'YTickMode',      'auto', ...
               'YTickLabelMode', 'auto');
    % Set axis orientation
    if TsInfo.FlipYAxis
        set(hAxes, 'YDir', 'reverse');
    else
        set(hAxes, 'YDir', 'normal');
    end
    
    % ===== LINES LEGENDS =====
    % Only if less than a certain amount of lines
    if ~isempty(LinesLabels) && isLegend && ((length(LinesLabels) > 1) || ~isempty(LinesLabels{1}))
        if (length(LinesLabels) == 1) && (length(PlotHandles.hLines) > 1)
            [hLegend, hLegendObjects] = legend(PlotHandles.hLines(1), LinesLabels{1});
        elseif (length(PlotHandles.hLines) == length(LinesLabels))
            [hLegend, hLegendObjects] = legend(PlotHandles.hLines, LinesLabels{:});
        else
            disp('BST> Error: Number of legend entries do not match the number of lines. Ignoring...');
            hLegend = [];
            hLegendObjects = [];
        end
        if ~isempty(hLegend)
            set(findobj(hLegendObjects, 'Type', 'Text'), ...
                'FontSize',  bst_get('FigFont'), ...
                'FontUnits', 'points');
            set(hLegend, 'Tag', 'legend', 'Interpreter', 'none');
        end
    end
           
    % ===== EXTRA LINES =====
    % Y=0 Line
    if (YLim(1) == 0)
        hLineY0 = line(get(hAxes,'XLim'), [0 0], [ZData ZData], 'Color', [0 0 0], 'Parent', hAxes);
    else
        hLineY0 = line(get(hAxes,'XLim'), [0 0], [ZData ZData], 'Color', .8*[1 1 1], 'Parent', hAxes);
    end

    % ===== DISPLAY GFP =====
    % If there are more than 5 channel
    if bst_get('DisplayGFP') && ~strcmpi(GlobalData.DataSet(iDS).Measures.DataType, 'stat') ...
                             && (GlobalData.DataSet(iDS).Measures.NumberOfSamples > 2) && (size(F,1) > 5) ...
                             && ~isempty(TsInfo.Modality) && ~strcmpi(TsInfo.Modality, 'sources') && (TsInfo.Modality(1) ~= '$')
        GFP = sqrt(sum((F * fFactor).^2, 1));
        PlotGFP(hAxes, TimeVector, GFP, TsInfo.FlipYAxis);
    end
end


%% ===== PLOT AXES: COLUMN =====
function PlotHandles = PlotAxesColumn(hAxes, PlotHandles, TsInfo, TimeVector, F, LinesLabels)
    ZData = 1.5;
    nLines = size(F,1);

    % ===== SPLIT IN BLOCKS =====
    % Normalized range of Y values
    YLim = [0, 1];
    % Data maximum
    Fmax = max(abs(PlotHandles.DataMinMax));
    % Subdivide Y-range in nDispChan blocks
    blockY = (YLim(2) - YLim(1)) / (nLines + 2);
    % Build an offset list for all channels 
    PlotHandles.ChannelOffsets = blockY * (nLines:-1:1)' + blockY / 2;
    % Normalize all channels to fit in one block only
    PlotHandles.DisplayFactor = blockY ./ Fmax;
    % Add previous display factor
    PlotHandles.DisplayFactor = PlotHandles.DisplayFactor * GetDefaultFactor(TsInfo.Modality);
    % Apply final factor to recordings + Keep only the displayed lines
    F = F .* PlotHandles.DisplayFactor;
    % Flip Y axis
    if TsInfo.FlipYAxis
        F = -F;
    end
    
    % ===== PLOT TIME SERIES =====
    % Add offset to each channel
    F = bst_bsxfun(@plus, F, PlotHandles.ChannelOffsets);
    % Display time series
    PlotHandles.hLines = line(TimeVector, F', ZData*ones(size(F)), 'Parent', hAxes);
    set(PlotHandles.hLines, 'Tag', 'DataLine');
    
    % ===== PLOT ZERO-LINES =====
    Xzeros = repmat(get(hAxes,'XLim'), [nLines, 1]);
    Yzeros = [PlotHandles.ChannelOffsets, PlotHandles.ChannelOffsets];
    Zzeros = repmat(.5 * [1 1], [nLines, 1]);
    hLineY0 = line(Xzeros', Yzeros', Zzeros', ...
                   'Color', .9*[1 1 1], ...
                   'Parent', hAxes);

    % ===== CHANNELS LABELS ======
    if ~isempty(LinesLabels)
        % Special case: If scout function is "All" 
        if (length(nLines) > 1) && (length(LinesLabels) == 1)
            Yticklabel = [];
        else
            Yticklabel = LinesLabels;
        end
        % Set Y Legend
        set(hAxes, 'YTickMode',      'manual', ...
                   'YTickLabelMode', 'manual', ...
                   'YTick',          flipdim(PlotHandles.ChannelOffsets, 1), ...
                   'Yticklabel',     flipdim(Yticklabel, 1));
    end
    % Set Y axis scale
    set(hAxes, 'YLim', YLim);
    % Remove axes legend for Y axis
    ylabel('');
end

%% ===== PLOT GFP =====
function PlotGFP(hAxes, TimeVector, GFP, isFlipY)
    ZData = 2;
    % Maximum of GFP
    maxGFP = max(GFP);
    if (maxGFP <= 0)
        return
    end
    % Get axes limits
    YLim = get(hAxes, 'YLim');
    % Make GFP displayable a the bottom of these axes
    GFP = GFP ./ maxGFP .* (YLim(2) - YLim(1)) .* 0.08 + YLim(1)*.95;
    maxGFP = double(max(GFP));
    % Flip if needed
    if isFlipY
        GFP = YLim(2) - GFP + YLim(1);
        maxGFP = YLim(2) - maxGFP + YLim(1);
    end
    % Plot GFP line
    line(TimeVector, GFP', ZData*ones(size(TimeVector)), ...
        'Color',  [0 1 0], ...
        'Parent', hAxes, ...
        'Tag',    'GFP');
    % Display GFP text legend
    text(double(0.01*TimeVector(end) + .99*TimeVector(1)), maxGFP, ZData, 'GFP',...
        'Horizontalalignment', 'left', ...
        'Color',        [0 1 0], ...
        'FontSize',     bst_get('FigFont') + 1, ...
        'FontWeight',   'bold', ...
        'FontUnits',    'points', ...
        'Tag',          'GFPTitle', ...
        'Interpreter',  'none', ...
        'Parent',       hAxes);
end


%% ===== UPDATE SCALE BAR =====
function UpdateScaleBar(iDS, iFig)
    global GlobalData;
    % Get figure data
    PlotHandles = GlobalData.DataSet(iDS).Figure(iFig).Handles(1);
    Modality    = GlobalData.DataSet(iDS).Figure(iFig).Id.Modality;
    % Get scale bar
    if isempty(PlotHandles.hColumnScale)
        return
    end
    % Get data units
    Fmax = max(abs(PlotHandles.DataMinMax));
    [fScaled, fFactor, fUnits] = bst_getunits( Fmax, Modality );
    barMeasure = fScaled / Fmax / PlotHandles.DisplayFactor / 2;
    % Get a channel in the middle of the display
    nChan = length(PlotHandles.hLines);
    iCenter = ceil(nChan / 2);
    centerOffset = PlotHandles.ChannelOffsets(iCenter);
    % Plot bar for the maximum amplitude
    xBar = .3;
    yBar = centerOffset + 1/(nChan+2) * [-1, 1];
    lineX = [xBar,xBar; xBar-.1,xBar+.1; xBar-.1,xBar+.1]';
    lineY = [yBar(1),yBar(2); yBar(1),yBar(1); yBar(2),yBar(2)]';
    if ~isempty(PlotHandles.hColumnScaleBar) && all(ishandle(PlotHandles.hColumnScaleBar))
        delete(PlotHandles.hColumnScaleBar);
    end
    PlotHandles.hColumnScaleBar = line(lineX, lineY, ...
         'Color',   'k', ... 
         'Tag',     'ColumnScaleBar', ...
         'Parent',  PlotHandles.hColumnScale);
    % Plot data units
    txtAmp = sprintf('%d %s', round(barMeasure), fUnits);
    if ~isempty(PlotHandles.hColumnScaleText) && ishandle(PlotHandles.hColumnScaleText)
        set(PlotHandles.hColumnScaleText, 'String', txtAmp);
    else
        % Scale text
        PlotHandles.hColumnScaleText = text(...
             .7, centerOffset, txtAmp, ...
             'FontSize',    bst_get('FigFont'), ...
             'FontUnits',   'points', ...
             'Color',       'k', ... 
             'Interpreter', 'tex', ...
             'HorizontalAlignment', 'center', ...
             'Rotation',    90, ...
             'Tag',         'ColumnScaleText', ...
             'Parent',      PlotHandles.hColumnScale);
    end
    % Update handles
    GlobalData.DataSet(iDS).Figure(iFig).Handles(1) = PlotHandles;
end


%% ===== CREATE SCALE BUTTON =====
function CreateScaleButtons(iDS, iFig)
    import org.brainstorm.icon.*;
    global GlobalData;
    % Get figure
    hFig  = GlobalData.DataSet(iDS).Figure(iFig).hFigure;
    isRaw = strcmpi(GlobalData.DataSet(iDS).Measures.DataType, 'raw');
    TsInfo = getappdata(hFig, 'TsInfo');
    % Get figure background color
    bgColor = get(hFig, 'Color');
    % Create scale buttons
    jButton = javaArray('java.awt.Component', 6);
    jButton(1) = javax.swing.JButton('^');
    jButton(2) = javax.swing.JButton('v');
    jButton(3) = javax.swing.JButton('...');
    jButton(4) = javax.swing.JToggleButton('AS');
    jButton(5) = gui_component('ToolbarToggle', [], [], [], IconLoader.ICON_FLIPY);
    jButton(6) = javax.swing.JButton('<');
    jButton(7) = javax.swing.JButton('>');
    % Configure buttons
    for i = 1:length(jButton)
        jButton(i).setBackground(java.awt.Color(bgColor(1), bgColor(2), bgColor(3)));
        jButton(i).setFocusPainted(0);
        jButton(i).setFocusable(0);
        jButton(i).setMargin(java.awt.Insets(0,0,0,0));
        jButton(i).setFont(bst_get('Font', 10));
    end
    % Create Matlab objects
    [j1, h1] = javacomponent(jButton(1), [0, 0, .01, .01], hFig);
    [j2, h2] = javacomponent(jButton(2), [0, 0, .01, .01], hFig);
    [j3, h3] = javacomponent(jButton(3), [0, 0, .01, .01], hFig);
    [j4, h4] = javacomponent(jButton(4), [0, 0, .01, .01], hFig);
    [j5, h5] = javacomponent(jButton(5), [0, 0, .01, .01], hFig);
    [j6, h6] = javacomponent(jButton(6), [0, 0, .01, .01], hFig);
    [j7, h7] = javacomponent(jButton(7), [0, 0, .01, .01], hFig);
    % Configure Gain buttons
    set(h1, 'Tag', 'ButtonGainPlus',  'Units', 'pixels');
    set(h2, 'Tag', 'ButtonGainMinus', 'Units', 'pixels');
    set(h3, 'Tag', 'ButtonSetScaleY', 'Units', 'pixels');
    set(h4, 'Tag', 'ButtonAutoScale', 'Units', 'pixels');
    set(h5, 'Tag', 'ButtonFlipY',     'Units', 'pixels');
    set(h6, 'Tag', 'ButtonZoomTimePlus',  'Units', 'pixels');
    set(h7, 'Tag', 'ButtonZoomTimeMinus', 'Units', 'pixels');
    j1.setToolTipText('<HTML><TABLE><TR><TD>Increase gain (vertical zoom)</TD></TR><TR><TD>Shortcuts:<BR><B> &nbsp; [+]<BR> &nbsp; [SHIFT+WHEEL]</B>');
    j2.setToolTipText('<HTML><TABLE><TR><TD>Decrease gain (vertical unzoom)</TD></TR><TR><TD>Shortcuts:<BR><B> &nbsp; [-]<BR> &nbsp; [SHIFT+WHEEL]</B>');
    j3.setToolTipText('Set scale manually');
    j4.setToolTipText('Auto-scale amplitude when changing page');
    j5.setToolTipText('<HTML><B>Flips the Y axis when displaying the recordings</B>:<BR><BR>Negative values are displayed oriented towards the top of the figures.');
    j6.setToolTipText('<HTML><TABLE><TR><TD>Horizontal unzoom</TD></TR><TR><TD>Shortcut: [MOUSE WHEEL]');
    j7.setToolTipText('<HTML><TABLE><TR><TD>Horizontal zoom</TD></TR><TR><TD>Shortcut: [MOUSE WHEEL]');
    java_setcb(j1, 'ActionPerformedCallback', @(h,ev)UpdateTimeSeriesFactor(hFig, 1.1));
    java_setcb(j2, 'ActionPerformedCallback', @(h,ev)UpdateTimeSeriesFactor(hFig, .9091));
    java_setcb(j3, 'ActionPerformedCallback', @(h,ev)SetScaleY(iDS, iFig));
    java_setcb(j4, 'ActionPerformedCallback', @(h,ev)AutoScale_Callback(ev.getSource(), hFig));
    java_setcb(j5, 'ActionPerformedCallback', @(h,ev)FlipY_Callback(ev.getSource(), hFig));
    java_setcb(j6, 'ActionPerformedCallback', @(h,ev)FigureZoomLinked(hFig, 'horizontal', .9091));
    java_setcb(j7, 'ActionPerformedCallback', @(h,ev)FigureZoomLinked(hFig, 'horizontal', 1.1));
    % Up button
    j1.setMargin(java.awt.Insets(3,0,0,0));
    j1.setFont(bst_get('Font', 12));    
    % Select buttons
    j4.setSelected(TsInfo.AutoScaleY);
    j5.setSelected(TsInfo.FlipYAxis);
    % Visible / not visible
    if isRaw
        set([h6 h7], 'Visible', 'off');
    end
    if ~strcmpi(GlobalData.DataSet(iDS).Figure(iFig).Id.Type, 'DataTimeSeries') || strcmpi(GlobalData.DataSet(iDS).Measures.DataType, 'stat')
        set([h3 h4 h5], 'Visible', 'off');
    end
end


%% ===== SET SCALE ====
% Change manually the scale of the data
% USAGE: SetScaleY(iDS, iFig, newScale)
%        SetScaleY(iDS, iFig)            : New scale is asked to the user
function SetScaleY(iDS, iFig, newScale)
    global GlobalData;
    % Parse input
    if (nargin < 3) || isempty(newScale)
        newScale = [];
    end
    % Get figure handles
    PlotHandles = GlobalData.DataSet(iDS).Figure(iFig).Handles(1);
    Modality    = GlobalData.DataSet(iDS).Figure(iFig).Id.Modality;
    hFig        = GlobalData.DataSet(iDS).Figure(iFig).hFigure;
    TsInfo      = getappdata(hFig, 'TsInfo');
    % Check the auto-scale property
    if TsInfo.AutoScaleY && strcmpi(TsInfo.DisplayMode, 'butterfly')
        bst_error('Cannot set the scale while the auto-scale button is on.', 'Set scale', 0);
        return;
    end
    % Get units
    Fmax = max(abs(PlotHandles.DataMinMax));
    [fScaled, fFactor, fUnits] = bst_getunits( Fmax, Modality );
    strUnits = strrep(fUnits, '\mu', '&mu;');
    
    % Columns
    if strcmpi(TsInfo.DisplayMode, 'column')
        % Get current scale
        oldScale = round(fScaled / Fmax / PlotHandles.DisplayFactor / 2);
        % If new scale not provided: ask the user
        if isempty(newScale)
            newScale = java_dialog('input', ['<HTML>Enter the amplitude scale (' strUnits '):'], 'Set scale', [], num2str(oldScale));
            if isempty(newScale)
                return
            end
            newScale = str2num(newScale);
            if isempty(newScale) || (newScale <= 0)
                bst_error('Invalid value', 'Set scale', 0);
                return;
            end
        end
        % If no changes: exit
        if (newScale == oldScale)
            return
        end
        % Update figure with new display factor
        UpdateTimeSeriesFactor(hFig, oldScale / newScale, 1);
    % Butterfly
    else
        % Get current scale
        hAxes = findobj(hFig, 'tag', 'AxesGraph');
        YLim = get(hAxes(1), 'YLim');
        % If new scale not provided: ask the user
        if isempty(newScale)
            newScale = java_dialog('input', ['<HTML>Enter the maximum (' strUnits '):'], 'Set maximum', [], num2str(max(YLim)));
            if isempty(newScale)
                return
            end
            newScale = str2num(newScale);
            if isempty(newScale) || (newScale <= 0)
                bst_error('Invalid value', 'Set maximum', 0);
                return;
            end
        end
        % Update scale
        if (newScale ~= max(YLim)) && (newScale ~= 0)
            if (YLim(1) == 0)
                newYLim = [0, newScale];
            else
                newYLim = [-newScale, newScale];
            end
            %set(hAxes, 'YLim', newYLim);
            newMinMax = newYLim / fFactor;
            [GlobalData.DataSet(iDS).Figure(iFig).Handles.DataMinMax] = deal(newMinMax / 1.05);
            % Update figure
            PlotFigure(iDS, iFig);
        end
    end
end

%% ===== FLIP Y AXIS =====
function FlipY_Callback(jButton, hFig)
    % Save preference
    isSel = jButton.isSelected();
    bst_set('FlipYAxis', isSel);
    % Display progress bar
    bst_progress('start', 'Display mode', 'Updating figures...');
    % Update figure structure
    TsInfo = getappdata(hFig, 'TsInfo');
    TsInfo.FlipYAxis = isSel;
    setappdata(hFig, 'TsInfo', TsInfo);
    % Re-plot figure
    bst_figures('ReloadFigures', hFig);
    % Hide progress bar
    bst_progress('stop');
end

%% ===== AUTO-SCALE TIME SERIES =====
function AutoScale_Callback(jButton, hFig)
    % Save preference
    isSel = jButton.isSelected();
    bst_set('AutoScaleY', isSel);
    % Display progress bar
    bst_progress('start', 'Display mode', 'Updating figures...');
    % Update figure structure
    TsInfo = getappdata(hFig, 'TsInfo');
    TsInfo.AutoScaleY = isSel;
    setappdata(hFig, 'TsInfo', TsInfo);
    % Re-plot figure
    bst_figures('ReloadFigures', hFig);
    % Hide progress bar
    bst_progress('stop');
end


%% ===== SET NORMALIZE AMPLITUDE =====
function SetNormalizeAmp(iDS, iFig, NormalizeAmp)
    global GlobalData;
    % Update value
    hFig = GlobalData.DataSet(iDS).Figure(iFig).hFigure;
    TsInfo = getappdata(hFig, 'TsInfo');
    TsInfo.NormalizeAmp = NormalizeAmp;
    setappdata(hFig, 'TsInfo', TsInfo);
    % Reset maximum values
    GlobalData.DataSet(iDS).Figure(iFig).Handles(1).DataMinMax = [];
    % Re-plot figure
    PlotFigure(iDS, iFig);
end

%% ===== SET FIXED RESOLUTION =====
function SetResolution(iDS, iFig, newResX, newResY)
    global GlobalData;
    % Parse inputs
    if (nargin < 4)
        newResX = [];
        newResY = [];
    end
    % Get current figure structure
    Figure = GlobalData.DataSet(iDS).Figure(iFig);
    hFig = Figure.hFigure;
    TsInfo = getappdata(hFig, 'TsInfo');
    hAxes = findobj(hFig, 'Tag', 'AxesGraph');
    Position = get(hAxes, 'Position');
    isRaw = strcmpi(GlobalData.DataSet(iDS).Measures.DataType, 'raw');
     % Get units
    Fmax = max(abs(Figure.Handles.DataMinMax));
    [fScaled, fFactor, fUnits] = bst_getunits( Fmax, Figure.Id.Modality );
    strUnits = strrep(fUnits, '\mu', '&mu;');
    % Get current time resolution
    XLim = get(hAxes, 'XLim');
    curResX = Position(3) / (XLim(2)-XLim(1));
    % Get current amplitude resolution
    if strcmpi(TsInfo.DisplayMode, 'butterfly')
        YLim = get(hAxes, 'YLim');
        curResY = (YLim(2)-YLim(1)) / Position(4);
    else
        nChan = length(Figure.Handles.hLines);
        interLines = fScaled / Fmax / Figure.Handles.DisplayFactor / 4 * (nChan+2);  % Distance between two lines * number of inter-lines, in units
        curResY = interLines / Position(4);
    end
    % Default values
    if (TsInfo.Resolution(1) == 0)
        defResX = '';
    else
        defResX = num2str(TsInfo.Resolution(1));
    end
    if (TsInfo.Resolution(2) == 0)
        defResY = '';
    else
        defResY = num2str(TsInfo.Resolution(2));
    end
    % Ask the new resolutions
    if isempty(newResX) && isempty(newResY)
        res = java_dialog('input', {['<HTML>Time resolution in pixels/second:     [current=' num2str(round(curResX)) ']<BR><FONT color="#555555">   1mm/s ~ 3px/s'], ...
                                    ['<HTML>Amplitude resolution in ' strUnits '/pixel:     [current=' num2str(curResY, '%1.2f') ']<BR><FONT color="#555555">   1' strUnits '/mm ~ 0.33' strUnits '/px']}, ...
                                    'Set axis resolution', [], ...
                                    {defResX, defResY});
        if isempty(res) || (length(res) ~= 2)
            return
        end
        newResX = str2num(res{1});
        newResY = str2num(res{2});
    end
    % Changing the time resolution of the figure
    if (length(newResX) == 1) && (newResX ~= TsInfo.Resolution(1)) && (newResX > 0)
        % Raw viewer: try to change the displayed time segment
        if isRaw
            % Change time length
            timeLength = Position(3) / newResX;
            panel_record('SetTimeLength', timeLength);
            % Update XLim after update of the figure
            hAxes = findobj(hFig, 'Tag', 'AxesGraph');
            XLim = get(hAxes, 'XLim');
            curResX = Position(3) / (XLim(2)-XLim(1));
        end
        % If there is more than a certain error between requested and current resolutions: Resize figure
        if (abs(curResX - newResX) / newResX > 0.02)
            % Get figure position and the difference between the size of the axes and the size of the figure
            PosFig = get(hFig, 'Position');
            Xdiff = PosFig(3) - Position(3);
            % Change figure size
            PosFig(3) = round((XLim(2)-XLim(1)) * newResX) + Xdiff;
            set(hFig, 'Position', PosFig);
        end
    end
    % Changing the amplitude resolution
    if (length(newResY) == 1) && (newResY ~= TsInfo.Resolution(2)) && (newResY > 0)
        % Butterfly: Update DataMinMax
        if strcmpi(TsInfo.DisplayMode, 'butterfly')
            newLength = Position(4) * newResY;
            if (YLim(1) == 0)
                newMinMax = [0, newLength] / fFactor;
            else
                newMinMax = [-newLength, newLength] / 2 / fFactor;
            end
            [GlobalData.DataSet(iDS).Figure(iFig).Handles.DataMinMax] = deal(newMinMax / 1.05);
            % Disable AutoScaleY
            if TsInfo.AutoScaleY
                TsInfo.AutoScaleY = 0;
                setappdata(hFig, 'TsInfo', TsInfo);
            end
            % Update figure
            PlotFigure(iDS, iFig);
        % Column: Update DisplayFactor
        else
            changeFactor = curResY / newResY;
            UpdateTimeSeriesFactor(hFig, changeFactor);
            
           %UpdateScaleBar(iDS, iFig);
            
           % GlobalData.DataSet(iDS).Figure(iFig).Handles.DisplayFactor = fScaled / Fmax / 4 * (nChan+2) / Position(4) / newResY;
        end
    end
end

%% ===== COPY DISPLAY OPTIONS =====
function CopyDisplayOptions(hFig, isMontage, isOptions)
    % Progress bar
    bst_progress('start', 'Copy display options', 'Updating figures...');
    % Get figure info
    TsInfoSrc = getappdata(hFig, 'TsInfo');
    % Get all figures
    hAllFigs = bst_figures('GetFiguresByType', {'DataTimeSeries', 'ResultsTimeSeries'});
    hAllFigs = setdiff(hAllFigs, hFig);
    % Process all figures
    for i = 1:length(hAllFigs)
        isModified = 0;
        % Get target figure info
        TsInfoDest = getappdata(hAllFigs(i), 'TsInfo');
        % Set montage
        if isMontage && ~isequal(TsInfoSrc.MontageName, TsInfoDest.MontageName)
            TsInfoDest.MontageName = TsInfoSrc.MontageName;
            isModified = 1;
        end
        % Set other options
        if isOptions && (~isequal(TsInfoSrc.DisplayMode, TsInfoDest.DisplayMode) || ~isequal(TsInfoSrc.FlipYAxis, TsInfoDest.FlipYAxis) || ~isequal(TsInfoSrc.NormalizeAmp, TsInfoDest.NormalizeAmp))
            TsInfoDest.DisplayMode  = TsInfoSrc.DisplayMode;
            TsInfoDest.FlipYAxis    = TsInfoSrc.FlipYAxis;
            TsInfoDest.NormalizeAmp = TsInfoSrc.NormalizeAmp;
            isModified = 1;
        end
        % Reload figure
        if isModified
            setappdata(hAllFigs(i), 'TsInfo', TsInfoDest);
            bst_figures('ReloadFigures', hAllFigs(i));
        end
    end
    bst_progress('stop');
end


%% ===========================================================================
%  ===== RAW VIEWER FUNCTIONS ================================================
%  ===========================================================================
%% ===== PLOT RAW TIME BAR =====
function PlotRawTimeBar(iDS, iFig)
    global GlobalData;
    % Get the full time window
    iEpoch = GlobalData.FullTimeWindow.CurrentEpoch;
    if isempty(iEpoch)
        return
    end
    FullTime = GlobalData.FullTimeWindow.Epochs(iEpoch).Time([1, end]);
    TimeBar = FullTime + [-1, +1].*GlobalData.DataSet(iDS).Measures.SamplingRate;
    % Get figure handles
    hFig        = GlobalData.DataSet(iDS).Figure(iFig).hFigure;
    hRawTimeBar = findobj(hFig, '-depth', 1, 'Tag', 'AxesRawTimeBar');
    % If time bar not create yet
    if isempty(hRawTimeBar)
        %figure(hFig);
        set(0, 'CurrentFigure', hFig);
        % Get figure background color
        bgColor = get(hFig, 'Color');
        % Time bar: Create axes
        hRawTimeBar = axes('Position', [0, 0, .01, .01]);
        set(hRawTimeBar, ...
             'Interruptible', 'off', ...
             'BusyAction',    'queue', ...
             'Tag',           'AxesRawTimeBar', ...
             'YGrid',      'off', ...
             'XGrid',      'off', ...
             'XMinorGrid', 'off', ...
             'XTick',      [], ...
             'YTick',      [], ...
             'TickLength', [0,0], ...
             'Color',      [.9 .9 .9], ...
             'XLim',       TimeBar, ...
             'YLim',       [0 1], ...
             'Box',        'off');
        % Check if buttons already exist
        if isempty(findobj(hFig, 'Tag', 'ButtonForward'))
            % Create all buttons
            jButton = javaArray('java.awt.Component', 3);
            jButton(1) = javax.swing.JButton('>>>');
            jButton(2) = javax.swing.JButton('<<<');
            jButton(3) = javax.swing.JButton('<<<');
            % Configure buttons
            for i = 1:length(jButton)
                jButton(i).setBackground(java.awt.Color(bgColor(1), bgColor(2), bgColor(3)));
                jButton(i).setFocusPainted(0);
                jButton(i).setFocusable(0);
                jButton(i).setMargin(java.awt.Insets(0,0,0,0));
                jButton(i).setFont(bst_get('Font', 10));
            end
            [j1, h1] = javacomponent(jButton(1), [0, 0, .01, .01], hFig);
            [j2, h2] = javacomponent(jButton(2), [0, 0, .01, .01], hFig);
            [j3, h3] = javacomponent(jButton(3), [0, 0, .01, .01], hFig);
            % Configure Forward/Backward buttons
            set(h1, 'Tag', 'ButtonForward',   'Units', 'pixels');
            set(h2, 'Tag', 'ButtonBackward',  'Units', 'pixels');
            set(h3, 'Tag', 'ButtonBackward2', 'Units', 'pixels');
            % Different shortcuts on MacOS
            if strncmp(computer,'MAC',3)
                j1.setToolTipText('<HTML><TABLE><TR><TD>Next page</TD></TR><TR><TD>Related shortcuts:<BR><B> - [CTRL+SHIFT+ARROW RIGHT]<BR> - [SHIFT+ARROW UP]<BR> - [Fn+F3]</B></TD></TR> <TR><TD>Slower data scrolling:<BR><B> - [Fn+F4]</B> : Half page</TD></TR></TABLE>');
                j2.setToolTipText('<HTML><TABLE><TR><TD>Previous page</TD></TR><TR><TD>Related shortcuts:<BR><B> - [CTRL+SHIFT+ARROW LEFT]<BR> - [SHIFT+ARROW DOWN]<BR> - [SHIFT+Fn+F3]</B></TD></TR> <TR><TD>Slower data scrolling:<BR><B> - [SHIFT+Fn+F4]</B> : Half page</TD></TR></TABLE>');
                j3.setToolTipText('<HTML><TABLE><TR><TD>Previous page</TD></TR><TR><TD>Related shortcuts:<BR><B> - [CTRL+SHIFT+ARROW LEFT]<BR> - [SHIFT+ARROW DOWN]<BR> - [SHIFT+Fn+F3]</B></TD></TR> <TR><TD>Slower data scrolling:<BR><B> - [SHIFT+Fn+F4]</B> : Half page</TD></TR></TABLE>');
            else
                j1.setToolTipText('<HTML><TABLE><TR><TD>Next page</TD></TR> <TR><TD>Related shortcuts:<BR><B> - [CTRL+ARROW RIGHT]<BR> - [SHIFT+ARROW UP]<BR> - [F3]</B></TD></TR> <TR><TD>Faster data scrolling:<BR><B> - [CTRL+PAGE UP]</B></TD></TR> <TR><TD>Slower data scrolling:<BR><B> - [F4]</B> : Half page</TD></TR></TABLE>');
                j2.setToolTipText('<HTML><TABLE><TR><TD>Previous page</TD></TR> <TR><TD>Related shortcuts:<BR><B> - [CTRL+ARROW LEFT]<BR> - [SHIFT+ARROW DOWN]<BR> - [SHIFT+F3]</B></TD></TR> <TR><TD>Faster data scrolling:<BR><B> - [CTRL+PAGE DOWN]</B></TD></TR> <TR><TD>Slower data scrolling:<BR><B> - [SHIFT+F4] : Half page</B></TD></TR></TABLE>');
                j3.setToolTipText('<HTML><TABLE><TR><TD>Previous page</TD></TR> <TR><TD>Related shortcuts:<BR><B> - [CTRL+ARROW LEFT]<BR> - [SHIFT+ARROW DOWN]<BR> - [SHIFT+F3]</B></TD></TR> <TR><TD>Faster data scrolling:<BR><B> - [CTRL+PAGE DOWN]</B></TD></TR> <TR><TD>Slower data scrolling:<BR><B> - [SHIFT+F4] : Half page</B></TD></TR></TABLE>'); 
            end
            % Callbacks
            % If full epoch is shown, and there are epochs => Next epoch
            if (length(GlobalData.FullTimeWindow.Epochs) > 1) && isequal(GlobalData.UserTimeWindow.Time, FullTime)
                keyNext = 'epoch+';
                keyPrev = 'epoch-';
            % Else: go to next page
            else
                keyNext.Key = 'rightarrow';
                keyNext.Modifier = {'control'};
                keyPrev.Key = 'leftarrow';
                keyPrev.Modifier = {'control'};
            end
            java_setcb(j1, 'ActionPerformedCallback', @(h,ev)panel_time('TimeKeyCallback', keyNext));
            java_setcb(j2, 'ActionPerformedCallback', @(h,ev)panel_time('TimeKeyCallback', keyPrev));
            java_setcb(j3, 'ActionPerformedCallback', @(h,ev)panel_time('TimeKeyCallback', keyPrev));
        end
        % Plot events dots on the raw time bar
        PlotEventsDots_TimeBar(hFig);
    end
    % Update raw time position
    UpdateRawTime(hFig);
end    
        

%% ===== UPDATE RAW EVENTS XLIM =====
function UpdateRawXlim(hFig, XLim)
    % Parse inputs
    if (nargin < 2) || isempty(XLim)
        hAxes = findobj(hFig, '-depth', 1, 'Tag', 'AxesGraph');
        XLim = get(hAxes(1), 'XLim');
    end
    % RAW: Set the time limits of the events bar
    hEventsBar = findobj(hFig, '-depth', 1, 'Tag', 'AxesEventsBar');
    if ~isempty(hEventsBar)
        set(hEventsBar, 'XLim', XLim);
    end
end


%% ===== UPDATE RAW TIME POSITION =====
function UpdateRawTime(hFig)
    global GlobalData;
    % Get raw time bar handle
    hRawTimeBar = findobj(hFig, '-depth', 1, 'Tag', 'AxesRawTimeBar');
    hEventsBar  = findobj(hFig, '-depth', 1, 'Tag', 'AxesEventsBar');
    if isempty(hRawTimeBar) || isempty(hEventsBar)
        return
    end
    % Get user time window
    Time = GlobalData.UserTimeWindow.Time;
    % Get user time band
    hUserTime = findobj(hRawTimeBar, '-depth', 1, 'tag', 'UserTime');
    % If not create yet: create it
    if isempty(hUserTime)
        hUserTime = patch('XData', [Time(1), Time(2), Time(2), Time(1)], ...
                          'YData', [.01 .01 .99 .99], ...
                          'ZData', 1.1 * [1 1 1 1], ...
                          'LineWidth', 1, ...
                          'FaceColor', [1 .3 .3], ...
                          ... 'FaceAlpha', 0.4, ...
                          'FaceAlpha', 1, ...
                          ... 'EdgeColor', [1 0 0], ...
                          'EdgeColor', 'None', ...
                          'EdgeAlpha', 1, ...
                          'Tag',       'UserTime', ...
                          'EraseMode', 'xor', ...
                          'Parent',    hRawTimeBar);
%         hUserTime = patch('XData', [Time(1), Time(2), Time(2), Time(1)], ...
%                           'YData', [.01 .01 .95 .95], ...
%                           'ZData', 1.1 * [1 1 1 1], ...
%                           'LineWidth', 1, ...
%                           'FaceColor', 'none', ...
%                           'EdgeColor', [1 0 0], ...
%                           'Tag',       'UserTime', ...
%                           'Parent',    hRawTimeBar);
    % Else just edit the position of the bar
    else
        set(hUserTime, 'XData', [Time(1), Time(2), Time(2), Time(1)]);
    end
    % Set the time limits of the events bar
    set(hEventsBar, 'XLim', Time);
    % Update events markers+labels in the events bar
    PlotEventsDots_EventsBar(hFig);
end


%% ===== PLOT EVENTS DOTS: TIME BAR =====
function PlotEventsDots_TimeBar(hFig)
    % Get raw time bar
    hRawTimeBar = findobj(hFig, '-depth', 1, 'Tag', 'AxesRawTimeBar');
    if isempty(hRawTimeBar)
        return
    end
    % Clear axes from previous objects
    cla(hRawTimeBar);
    % Get the raw events and time axes
    events = panel_record('GetEvents');
    % Loop on all the events types
    for iEvt = 1:length(events)
        % No occurrences: nothing to draw
        nOccur = size(events(iEvt).times, 2);
        if (nOccur == 0)
            continue;
        end
        % Get event color
        if isfield(events(iEvt), 'color') && ~isempty(events(iEvt).color)
            color = events(iEvt).color;
        else
            color = [0 1 0];
        end
        % Time bar: Plot all occurrences in the same line object 
        hEvtTime = line(mean(events(iEvt).times, 1), ...  % X
                        .1 + .9*(iEvt-1)/length(events) * ones(1,nOccur), ... % Y
                         1 * ones(1,nOccur), ... % Z
                        'LineStyle',       'none', ...
                        'MarkerFaceColor', color, ...
                        'MarkerEdgeColor', color, ...
                        'MarkerSize',      6, ...
                        'Marker',          '.', ...
                        'Tag',             'EventDots', ...
                        'UserData',        iEvt, ...
                        'Parent',          hRawTimeBar);
    end
end



%% ===== PLOT EVENTS DOTS: EVENTS BAR =====
function PlotEventsDots_EventsBar(hFig)
    % Get events bar
    hEventsBar = findobj(hFig, '-depth', 1, 'Tag', 'AxesEventsBar');
    if isempty(hEventsBar)
        return
    end
    % Clear axes from previous objects
    cla(hEventsBar);
    % Get the raw events and time axes
    events = panel_record('GetEventsInTimeWindow', hFig);
    % Loop on all the events types
    for iEvt = 1:length(events)
        % Get event color
        if isfield(events(iEvt), 'color') && ~isempty(events(iEvt).color)
            color = events(iEvt).color;
        else
            color = [0 1 0];
        end
        % Event bar: Plot same line object
        nOccur = size(events(iEvt).times, 2);
        % Simple events
        if (size(events(iEvt).times, 1) == 1)
            hEvtBar = line(events(iEvt).times, ...  % X
                           .2 * ones(1,nOccur), ... % Y
                            1 * ones(1,nOccur), ... % Z
                           'LineStyle',       'none', ...
                           'MarkerFaceColor', color, ...
                           'MarkerEdgeColor', color .* .6, ...
                           'MarkerSize',      6, ...
                           'Marker',          'o', ...
                           'Tag',             'EventDots', ...
                           'UserData',        iEvt, ...
                           'Parent',          hEventsBar);
        % Exented events
        else
            hEvtBar = line(events(iEvt).times, ...  % X
                           .2 * ones(size(events(iEvt).times)), ... % Y
                            1 * ones(size(events(iEvt).times)), ... % Z
                           'Color',           color, ...
                           'MarkerFaceColor', color, ...
                           'MarkerEdgeColor', color .* .6, ...
                           'MarkerSize',      6, ...
                           'Marker',          'o', ...
                           'Tag',             'EventDots', ...
                           'UserData',        iEvt, ...
                           'Parent',          hEventsBar);
        end
        % Event bar: Plot event labels
        hEvtLabel = text(mean(events(iEvt).times,1), ...  % X
                         .3 * ones(1,nOccur), ... % Y
                         events(iEvt).label, ...
                         'Color',               color, ...
                         'FontSize',            bst_get('FigFont'), ...
                         'FontUnits',           'points', ...
                         'VerticalAlignment',   'bottom', ...
                         'HorizontalAlignment', 'center', ...
                         'Interpreter',         'none', ...
                         'Tag',                 'EventLabels', ...
                         'Parent',              hEventsBar);
    end
end



