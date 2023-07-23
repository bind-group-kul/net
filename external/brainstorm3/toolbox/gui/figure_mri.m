function varargout = figure_mri(varargin)
% FIGURE_MRI: Application M-file for figure_mri.fig
%
% USAGE: hFig = figure_mri('CreateFigure',               FigureId);
%               figure_mri('SetWindowHasResults',        hFig, isResults);
%               figure_mri('ColormapChangedCallback',    iDS, iFig);
%               figure_mri('DisplayFigurePopup',         hFig);
%[sMri,handl] = figure_mri('SetupMri',                   hFig);
%[sMri,handl] = figure_mri('LoadLandmarks',              sMri, Handles)
%[sMri,handl] = figure_mri('LoadFiducial',               sMri, Handles, FidCategory, FidName, FidColor, hButton, hTitle, PtHandleName)
%               figure_mri('SaveMri',                    hFig)
%[hI,hCH,hCV] = figure_mri('SetupView',                  hAxes, xySize, imgSize, orientLabels)
%         XYZ = figure_mri('GetLocation',                cs, sMri, handles)
%               figure_mri('SetLocation',                cs, sMri, Handles, XYZ)
%               figure_mri('MriTransform',               hButton, Transf, iDim)
%               figure_mri('UpdateMriDisplay',           hFig, dims)
%               figure_mri('UpdateSurfaceColor',         hFig)
%               figure_mri('UpdateCrosshairPosition',    sMri, Handles)
%               figure_mri('UpdateCoordinates',          sMri, Handles)
%         hPt = figure_mri('PlotPoint',                  sMri, Handles, ptLoc, ptColor)
%               figure_mri('UpdateVisibleLandmarks',     sMri, Handles, slicesToUpdate)
%               figure_mri('SetFiducial',                hFig, FidCategory, FidName)
%               figure_mri('ViewFiducial',               hFig, FidCategory, FiducialName)
%               figure_mri('FiducialsValidation',        MriFile)
%               figure_mri('callback_name', ...) : Invoke the named callback.

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
% Authors: Sylvain Baillet, 2004
%          Francois Tadel, 2008-2012

macro_methodcall;
end


%% ===== CREATE FIGURE =====
function hFig = CreateFigure(FigureId) %#ok<DEFNU>
    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 0;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @figure_mri_OpeningFcn, ...
                       'gui_OutputFcn',  @figure_mri_OutputFcn, ...
                       'gui_LayoutFcn',  [] , ...
                       'gui_Callback',   []);
    hFig = gui_mainfcn(gui_State, 'Visible', 'off');
    % Set renderer
%     if (bst_get('DisableOpenGL') == 1)
        rendererName = 'zbuffer';
%     else
%         rendererName = 'opengl';
%     end
    set(hFig, 'Renderer', rendererName);
end


%% =======================================================================================
%  ===== FIGURE CALLBACKS ================================================================
%  =======================================================================================
%% ===== FIGURE INITIALIZATION =====
function figure_mri_OpeningFcn(hFig, ev, handles, varargin) %#ok<INUSL>
    import org.brainstorm.icon.*;
    
    % ===== REPLACE SLIDERS WITH JAVA SLIDERS =====
    % SAGITTAL
    sliderPos = get(handles.sliderSagittal, 'Position');
    delete(handles.sliderSagittal);
    [handles.jSliderSagittal, handles.sliderSagittal] = javacomponent(javax.swing.JSlider(0,10,0), [0 0 1 1], hFig);
    handles.jSliderSagittal.setBackground(java.awt.Color(0,0,0));
    set(handles.sliderSagittal, 'Units', 'Normalized', 'Position', sliderPos);
    % CORONAL
    sliderPos = get(handles.sliderCoronal, 'Position');
    delete(handles.sliderCoronal);
    [handles.jSliderCoronal, handles.sliderCoronal] = javacomponent(javax.swing.JSlider(0,10,0), [0 0 1 1], hFig);
    handles.jSliderCoronal.setBackground(java.awt.Color(0,0,0));
    set(handles.sliderCoronal, 'Units', 'Normalized', 'Position', sliderPos);
    % AXIAL
    sliderPos = get(handles.sliderAxial, 'Position');
    delete(handles.sliderAxial);
    [handles.jSliderAxial, handles.sliderAxial] = javacomponent(javax.swing.JSlider(0,10,0), [0 0 1 1], hFig);
    handles.jSliderAxial.setBackground(java.awt.Color(0,0,0));
    set(handles.sliderAxial, 'Units', 'Normalized', 'Position', sliderPos);
    
    % ===== ADD ZOOM BUTTONS =====
    % Zoom -
    jButtonZoomPlus = gui_component('button', [], 'br right', '', IconLoader.ICON_ZOOM_MINUS, '<HTML><B>Zoom out   [-]</B><BR><BR>Double-click to reset view', @(h,ev)ButtonZoom_Callback(hFig, '-'), []);
    [handles.jButtonZoomMinus, handles.hButtonZoomMinus] = javacomponent(jButtonZoomPlus, [0 0 1 1], hFig);
    handles.jButtonZoomMinus.setBackground(java.awt.Color(0,0,0));
    set(handles.hButtonZoomMinus, 'Units', 'Normalized', 'Position', [0.4784, 0.011, 0.035, 0.04]);
    % Zoom +
    jButtonZoomPlus = gui_component('button', [], 'br right', '', IconLoader.ICON_ZOOM_PLUS, '<HTML><B>Zoom in   [+]</B><BR><BR>Double-click to reset view', @(h,ev)ButtonZoom_Callback(hFig, '+'), []);
    [handles.jButtonZoomPlus, handles.hButtonZoomPlus] = javacomponent(jButtonZoomPlus, [0 0 1 1], hFig);
    handles.jButtonZoomPlus.setBackground(java.awt.Color(0,0,0));
    set(handles.hButtonZoomPlus, 'Units', 'Normalized', 'Position', [0.516, 0.011, 0.035, 0.04]);
    
    % ===== SET FIGURE HANDLES =====
    % Initialize other handles
    handles.hPointNAS  = [];
    handles.hPointLPA  = [];
    handles.hPointRPA  = [];
    handles.hPointAC   = [];
    handles.hPointPC   = [];
    handles.hPointIH   = [];
    handles.hLandmarks = [];
    handles.isReadOnly = 0;
    handles.isResults  = 0;
    handles.isModified = 0;
    % Choose default command line output for figure_mri
    handles.output = hFig;
    % Update handles structure
    guidata(hFig, handles);
    % Set appdata
    setappdata(hFig, 'Surface', repmat(db_template('TessInfo'), 0));
    setappdata(hFig, 'iSurface',    []);
    setappdata(hFig, 'StudyFile',   []);   
    setappdata(hFig, 'SubjectFile', []);      
    setappdata(hFig, 'DataFile',    []); 
    setappdata(hFig, 'ResultsFile', []);
    setappdata(hFig, 'isStatic',    1);
    setappdata(hFig, 'isStaticFreq',1);
    setappdata(hFig, 'Colormap',    db_template('ColormapInfo'));
    
    % ===== CONFIGURE FIGURE =====
    % Set button icons
    iconRotate  = java_geticon( 'ICON_MRI_ROTATE');
    iconFlip    = java_geticon( 'ICON_MRI_FLIP');
    iconPermute = java_geticon( 'ICON_MRI_PERMUTE');
    set(handles.buttonRotateC, 'CData', iconRotate);
    set(handles.buttonRotateA, 'CData', iconRotate);
    set(handles.buttonRotateS, 'CData', iconRotate);
    set(handles.buttonFlipC,   'CData', iconFlip);
    set(handles.buttonFlipA,   'CData', iconFlip);
    set(handles.buttonFlipS,   'CData', iconFlip);
    set(handles.buttonPermuteC, 'CData', iconPermute);
    set(handles.buttonPermuteA, 'CData', iconPermute);
    set(handles.buttonPermuteS, 'CData', iconPermute);
    % Set MIP anat/functional status
    MriOptions = bst_get('MriOptions');
    set(handles.checkMipAnatomy,    'Value', MriOptions.isMipAnatomy);
    set(handles.checkMipFunctional, 'Value', MriOptions.isMipFunctional);
    % On MAC: buttons must have a dark font
    if strncmp(computer,'MAC',3)
        set([handles.buttonNasSet, handles.buttonLpaSet, handles.buttonRpaSet, ...
             handles.buttonIhSet,  handles.buttonAcSet, handles.buttonPcSet, ...
             handles.buttonCancel, handles.buttonSave], ...
            'ForegroundColor', [0 0 0]);
    end
    
    % ===== DEFINE FIGURE CALLBACKS =====
    % Make all components callbacks uninterruptible
    set([hFig, handles.axa, handles.axs, handles.axc] , 'Interruptible', 'off', 'BusyAction', 'cancel');
    % Set figure callbacks
    set(hFig, 'KeyPressFcn',     @FigureKeyPress_Callback, ...    
              'CloseRequestFcn', @(h,ev)bst_figures('DeleteFigure',h,ev), ...
              'ResizeFcn',       @ResizeCallback);
    % Buttons callbacks: Fiducials
    set(handles.buttonNasSet,  'Callback',  @(h,ev)SetFiducial(hFig, 'SCS', 'NAS'));
    set(handles.buttonLpaSet,  'Callback',  @(h,ev)SetFiducial(hFig, 'SCS', 'LPA'));
    set(handles.buttonRpaSet,  'Callback',  @(h,ev)SetFiducial(hFig, 'SCS', 'RPA'));
    set(handles.buttonAcSet,   'Callback',  @(h,ev)SetFiducial(hFig, 'NCS', 'AC'));
    set(handles.buttonPcSet,   'Callback',  @(h,ev)SetFiducial(hFig, 'NCS', 'PC'));
    set(handles.buttonIhSet,   'Callback',  @(h,ev)SetFiducial(hFig, 'NCS', 'IH'));
    set(handles.buttonNasView, 'Callback',  @(h,ev)ViewFiducial(hFig, 'SCS', 'NAS'));
    set(handles.buttonLpaView, 'Callback',  @(h,ev)ViewFiducial(hFig, 'SCS', 'LPA'));
    set(handles.buttonRpaView, 'Callback',  @(h,ev)ViewFiducial(hFig, 'SCS', 'RPA'));
    set(handles.buttonAcView,  'Callback',  @(h,ev)ViewFiducial(hFig, 'NCS', 'AC'));
    set(handles.buttonPcView,  'Callback',  @(h,ev)ViewFiducial(hFig, 'NCS', 'PC'));
    set(handles.buttonIhView,  'Callback',  @(h,ev)ViewFiducial(hFig, 'NCS', 'IH'));
    % Buttons callback: MRI Transforms
    set(handles.buttonRotateS, 'Callback',  @(h,ev)MriTransform(hFig, 'Rotate', 1));
    set(handles.buttonRotateC, 'Callback',  @(h,ev)MriTransform(hFig, 'Rotate', 2));
    set(handles.buttonRotateA, 'Callback',  @(h,ev)MriTransform(hFig, 'Rotate', 3));
    set(handles.buttonFlipS,   'Callback',  @(h,ev)MriTransform(hFig, 'Flip',   2));
    set(handles.buttonFlipC,   'Callback',  @(h,ev)MriTransform(hFig, 'Flip',   1));
    set(handles.buttonFlipA,   'Callback',  @(h,ev)MriTransform(hFig, 'Flip',   1));
    set([handles.buttonPermuteA, handles.buttonPermuteS, handles.buttonPermuteC], 'Callback',  @(h,ev)MriTransform(hFig, 'Permute'));
    % Checkboxes
    set(handles.checkViewCrosshair, 'Callback', @checkCrosshair_Callback);
    set(handles.checkViewSliders,   'Callback', @checkViewSliders_Callback);
    set(handles.checkMipAnatomy,    'Callback', @checkMip_Callback);
    set(handles.checkMipFunctional, 'Callback', @checkMip_Callback);
    set(handles.checkViewSliders,   'Callback', @checkViewSliders_Callback);
    
    % Radiological / Neurological
    set(handles.radioRadiological, 'Callback',  @orientation_Callback);
    set(handles.radioNeurological, 'Callback',  @orientation_Callback);
    % Load previous value
    MriOptions = bst_get('MriOptions');
    if MriOptions.isRadioOrient
        set(handles.radioRadiological, 'Value', 1);
    	set([handles.axs,handles.axc,handles.axa],'XDir', 'reverse');
    else
        set(handles.radioNeurological, 'Value', 1);
        set([handles.axs,handles.axc,handles.axa],'XDir', 'normal');
    end
    
    % Cancel and save buttons
    set(handles.buttonSave,   'Callback',  @(h,ev)ButtonSave_Callback(hFig));
    set(handles.buttonCancel, 'Callback',  @(h,ev)ButtonCancel_Callback(hFig));
end

function varargout = figure_mri_OutputFcn(hFig, eventdata, handles)  %#ok<INUSL>
    % Get default command line output from handles structure
    varargout{1} = handles.output;
end

%% ===== SET WINDOW FOR RESULTS =====
function SetWindowHasResults(hFig, isResults) %#ok<DEFNU>
    % Update figure handles
    Handles = bst_figures('GetFigureHandles', hFig);
    Handles.isResults = isResults;
    bst_figures('SetFigureHandles', hFig, Handles);
    % Update window
%     if isResults
        set(Handles.checkMipFunctional, 'Visible', 'on');
%     else
%         set(Handles.checkMipFunctional, 'Visible', 'off');
%     end
end


%% ===== SET WINDOW READ ONLY =====
function SetWindowReadOnly(hFig, isReadOnly) %#ok<DEFNU>
    % Get figure handles
    Handles = bst_figures('GetFigureHandles', hFig);
    % If value did not change, exit
    if (isReadOnly == Handles.isReadOnly)
        return
    end
    % Update figure handles
    Handles.isReadOnly = isReadOnly;
    bst_figures('SetFigureHandles', hFig, Handles);
    % Get axes positions
    panelTitlePos = get(Handles.panelTitleCoronal, 'Position');
    axsPos = get(Handles.axs, 'Position');
    axcPos = get(Handles.axc, 'Position');
    axaPos = get(Handles.axa, 'Position');
    % Objects to hide or show
    hObjects = [Handles.panelTitleCoronal, Handles.panelTitleSagittal, Handles.panelTitleAxial, ...
               Handles.panelCS, Handles.buttonCancel, Handles.buttonSave, ...
               Handles.titleCoronal, Handles.titleAxial, Handles.titleSagittal, ...
               Handles.buttonRotateC, Handles.buttonRotateA, Handles.buttonRotateS, ...
               Handles.buttonFlipC, Handles.buttonFlipA, Handles.buttonFlipS, ...
               Handles.buttonPermuteC, Handles.buttonPermuteA, Handles.buttonPermuteS, ...
               Handles.titleNAS, Handles.titleLPA, Handles.titleRPA, Handles.titleAC, Handles.titlePC, Handles.titleIH,...
               Handles.buttonNasSet, Handles.buttonLpaSet, Handles.buttonRpaSet, Handles.buttonIhSet, Handles.buttonAcSet, Handles.buttonPcSet, ...
               Handles.buttonNasView, Handles.buttonLpaView, Handles.buttonRpaView, Handles.buttonIhView, Handles.buttonAcView, Handles.buttonPcView];
    % Hide / Show
    if isReadOnly
        set(hObjects, 'Visible', 'off');
        sizeModif = panelTitlePos(4);
    else
        set(hObjects, 'Visible', 'on');
        sizeModif = - panelTitlePos(4);
    end
	% Update axes positions
    axsPos(4) = axsPos(4) + sizeModif;
    axcPos(4) = axcPos(4) + sizeModif;
    axaPos(4) = axaPos(4) + sizeModif;
    % Set axes positions
    set(Handles.axs, 'Position', axsPos);
    set(Handles.axc, 'Position', axcPos);
    set(Handles.axa, 'Position', axaPos);
end


%% ===== RESIZE CALLBACK =====
function ResizeCallback(hFig, ev)
    % Get colorbar and axes handles
    hColorbar = findobj(hFig, '-depth', 1, 'Tag', 'Colorbar');
    if isempty(hColorbar)
        return
    end
    % Get figure position and size in pixels
    figPos = get(hFig, 'Position');
    % Define constants
    colorbarWidth = 15;
    marginHeight  = 20;
    marginWidth   = 45;
    % Reposition the colorbar
    set(hColorbar, 'Units', 'pixels', ...
                   'Position', [figPos(3) - marginWidth, ...
                                marginHeight + figPos(4) * .53, ...
                                colorbarWidth, ...
                                figPos(4) * .47 - marginHeight - 3]);
end


%% ===== KEYBOAD CALLBACK =====
function FigureKeyPress_Callback(hFig, keyEvent)   
    global TimeSliderMutex;
    % ===== PROCESS BY CHARACTERS =====
    switch (keyEvent.Character)
        % === SCOUTS : GROW/SHRINK ===
        case '+'
            ButtonZoom_Callback(hFig, '+');
        case '-'
            ButtonZoom_Callback(hFig, '-');
                                   
        otherwise
            % ===== PROCESS BY KEYS =====
            switch (keyEvent.Key)
                % === LEFT, RIGHT, PAGEUP, PAGEDOWN ===
                case {'leftarrow', 'rightarrow', 'pageup', 'pagedown', 'home', 'end'}
                    if isempty(TimeSliderMutex) || ~TimeSliderMutex
                        panel_time('TimeKeyCallback', keyEvent);
                    end
                % === DATABASE NAVIGATOR ===
                case {'f1', 'f2', 'f3', 'f4'}
                    bst_figures('NavigatorKeyPress', hFig, keyEvent);
                % CTRL+D : Dock figure
                case 'd'
                    if ismember('control', keyEvent.Modifier)
                        isDocked = strcmpi(get(hFig, 'WindowStyle'), 'docked');
                        bst_figures('DockFigure', hFig, ~isDocked);
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
            end
    end
end

    
%% ===== SLIDER CALLBACK =====
function sliderClicked_Callback(hFig, iSlider, ev)
    if ~ev.getSource.getModel.getValueIsAdjusting
        UpdateMriDisplay(hFig, iSlider);
    end
end


%% ===== CHECKBOX: MIP ANATOMY/FUNCTIONAL =====
function checkMip_Callback(hObject, varargin)
    % Get figure handles
    hFig = ancestor(hObject,'figure');
    Handles = bst_figures('GetFigureHandles', hFig);
    % Get values for MIP
    MriOptions = bst_get('MriOptions');
    MriOptions.isMipAnatomy    = get(Handles.checkMipAnatomy,    'Value');
    MriOptions.isMipFunctional = get(Handles.checkMipFunctional, 'Value');
    bst_set('MriOptions', MriOptions);
    % Update slices display
    UpdateMriDisplay(hFig);
end

%% ===== CHECKBOX: VIEW CROSSHAIR =====
function checkCrosshair_Callback(hObject, varargin)
    % Get figure handles
    hFig = ancestor(hObject,'figure');
    Handles = bst_figures('GetFigureHandles', hFig);
    % Update crosshairs visibility
    hCrosshairs = [Handles.crosshairCoronalH, Handles.crosshairCoronalV, ...
             Handles.crosshairSagittalH, Handles.crosshairSagittalV, ...
             Handles.crosshairAxialH, Handles.crosshairAxialV];
    if get(hObject, 'Value')
        set(hCrosshairs, 'Visible', 'on');
    else
        set(hCrosshairs, 'Visible', 'off');
    end
end

%% ===== CHECKBOX: VIEW SLIDERS =====
function checkViewSliders_Callback(hObject, varargin)
    % Get figure handles
    hFig = ancestor(hObject,'figure');
    Handles = bst_figures('GetFigureHandles', hFig);
    % Hide/Show sliders
    hSliders = [Handles.sliderAxial, Handles.sliderSagittal, Handles.sliderCoronal];
    if get(hObject, 'Value')
        set(hSliders, 'Visible', 'on');
    else
        set(hSliders, 'Visible', 'off');
    end
end

%% ===== ORIENT: NEURO/RADIO =====
function orientation_Callback(hObject, varargin)
    % Get figure handles
    hFig = ancestor(hObject,'figure');
    Handles = bst_figures('GetFigureHandles', hFig);
    % Make sure that one option is selected
    if ~get(Handles.radioRadiological, 'Value') && ~get(Handles.radioNeurological, 'Value')
        set(hObject, 'Value', 1);
    end
    % Get values
    isRadio = get(Handles.radioRadiological, 'Value');
    % Save value in user preferences
    MriOptions = bst_get('MriOptions');
    MriOptions.isRadioOrient = isRadio;
    bst_set('MriOptions', MriOptions);
    % If is radio
    if isRadio
    	set([Handles.axs,Handles.axc,Handles.axa],'XDir', 'reverse');
    else
        set([Handles.axs,Handles.axc,Handles.axa],'XDir', 'normal');
    end
    drawnow;
end


%% ===== BUTTON ZOOM =====
function ButtonZoom_Callback(hFig, action)
    % Get figure handles
    sMri = panel_surface('GetSurfaceMri', hFig);
    Handles = bst_figures('GetFigureHandles', hFig);
    % Get current axis position
    mmCoord = GetLocation('mm', sMri, Handles);
    % Zoom factor
    switch (action)
        case '+',     Factor = 1 ./ 1.5;
        case '-',     Factor = 1.5;
        case 'reset', Factor = 0;
    end
    % Prepare list to process
    hAxesList = [Handles.axs, Handles.axc, Handles.axa];
    axesCoord = [mmCoord([2 3]); mmCoord([1 3]); mmCoord([1 2])];
    % Loop on axes
    for i = 1:length(hAxesList)
        hAxes = hAxesList(i);
        % Get initial axis limits
        XLimInit = getappdata(hAxes, 'XLimInit');
        YLimInit = getappdata(hAxes, 'YLimInit');
        % Get current axis limits
        XLim = get(hAxes, 'XLim');
        YLim = get(hAxes, 'YLim');
        % Get new window length
        XLim = axesCoord(i,1) + (XLim(2)-XLim(1)) * Factor * [-.5, .5];
        YLim = axesCoord(i,2) + (YLim(2)-YLim(1)) * Factor * [-.5, .5];
        Len = [XLim(2)-XLim(1), YLim(2)-YLim(1)];
        % Get orientation labels
        hLabelOrient = findobj(hAxes, '-depth', 1, 'Tag', 'LabelOrient');
        % If window length is larger that initial: restore initial
        if any(Len == 0) || ((Len(1) >= XLimInit(2)-XLimInit(1)) || (Len(2) >= YLimInit(2)-YLimInit(1))) || (abs(Len(1) - (XLimInit(2)-XLimInit(1))) < 1e-2) || (abs(Len(2) - YLimInit(2)-YLimInit(1)) < 1e-2)
            XLim = XLimInit;
            YLim = YLimInit;
            % Restore orientation labels
            set(hLabelOrient, 'Visible', 'on');
        else
            % Move view to have a full image (X)
            if (XLim(1) < XLimInit(1))
                XLim = XLimInit(1) + [0, Len(1)];
            elseif (XLim(2) > XLimInit(2))
                XLim = XLimInit(2) + [-Len(1), 0];
            end
            % Move view to have a full image (Y)
            if (YLim(1) < YLimInit(1))
                YLim = YLimInit(1) + [0, Len(2)];
            elseif (YLim(2) > YLimInit(2))
                YLim = YLimInit(2) + [-Len(2), 0];
            end
            % Hide orientation labels
            set(hLabelOrient, 'Visible', 'off');
        end
        % Update zoom factor
        set(hAxes, 'XLim', XLim);
        set(hAxes, 'YLim', YLim);
    end
end


%% =======================================================================================
%  ===== EXTERNAL CALLBACKS ==============================================================
%  =======================================================================================
%% ===== COLORMAP CHANGED =====
% Usage:  ColormapChangedCallback(iDS, iFig) 
function ColormapChangedCallback(iDS, iFig) %#ok<DEFNU>
    global GlobalData;
    panel_surface('UpdateSurfaceColormap', GlobalData.DataSet(iDS).Figure(iFig).hFigure);
end


%% ===== POPUP MENU =====
% Show a popup dialog
function DisplayFigurePopup(hFig)
    import java.awt.event.KeyEvent;
    import javax.swing.KeyStroke;
    import org.brainstorm.icon.*;
    
    % Create popup menu
    jPopup = java_create('javax.swing.JPopupMenu');
    % Get figure options
    ColormapInfo = getappdata(hFig, 'Colormap');
    isOverlay = any(ismember({'source','stat1','stat2','timefreq'}, ColormapInfo.AllTypes));
    Handles = bst_figures('GetFigureHandles', hFig);
        
    % ==== Menu colormaps ====
    % Create the colormaps menus
    bst_colormaps('CreateAllMenus', jPopup, hFig);
    
    % === MRI Options ===
    % Smooth factor
    if isOverlay 
        jMenuMri = gui_component('Menu', jPopup, [], 'Smooth sources', IconLoader.ICON_ANATOMY, [], [], []);
        MriOptions = bst_get('MriOptions');
        jItem0 = gui_component('radiomenuitem', jMenuMri, [], 'None', [], [], @(h,ev)figure_3d('SetMriSmooth', hFig, 0), []);
        jItem1 = gui_component('radiomenuitem', jMenuMri, [], '1',    [], [], @(h,ev)figure_3d('SetMriSmooth', hFig, 1), []);
        jItem2 = gui_component('radiomenuitem', jMenuMri, [], '2',    [], [], @(h,ev)figure_3d('SetMriSmooth', hFig, 2), []);
        jItem3 = gui_component('radiomenuitem', jMenuMri, [], '3',    [], [], @(h,ev)figure_3d('SetMriSmooth', hFig, 3), []);
        jItem4 = gui_component('radiomenuitem', jMenuMri, [], '4',    [], [], @(h,ev)figure_3d('SetMriSmooth', hFig, 4), []);
        jItem5 = gui_component('radiomenuitem', jMenuMri, [], '5',    [], [], @(h,ev)figure_3d('SetMriSmooth', hFig, 5), []);
        jItem0.setSelected(MriOptions.OverlaySmooth == 0);
        jItem1.setSelected(MriOptions.OverlaySmooth == 1);
        jItem2.setSelected(MriOptions.OverlaySmooth == 2);
        jItem3.setSelected(MriOptions.OverlaySmooth == 3);
        jItem4.setSelected(MriOptions.OverlaySmooth == 4);
        jItem5.setSelected(MriOptions.OverlaySmooth == 5);
    end
    jPopup.addSeparator();
    % Set fiducials
    if ~Handles.isReadOnly
        gui_component('MenuItem', jPopup, [], 'Edit fiducial positions...', IconLoader.ICON_EDIT, [], @(h,ev)EditFiducials(hFig), []);
        jPopup.addSeparator();
    end

    % ==== Menu SNAPSHOT ====
    jMenuSave = gui_component('Menu', jPopup, [], 'Snapshot', IconLoader.ICON_SNAPSHOT, [], [], []);
        % Default output dir
        LastUsedDirs = bst_get('LastUsedDirs');
        DefaultOutputDir = LastUsedDirs.ExportImage;
        % === SAVE AS IMAGE ===
        jItem = gui_component('MenuItem', jMenuSave, [], 'Save as image', IconLoader.ICON_SAVE, [], @(h,ev)out_figure_image(hFig), []);
        jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_I, KeyEvent.CTRL_MASK));
        % === OPEN AS IMAGE ===
        jItem = gui_component('MenuItem', jMenuSave, [], 'Open as image', IconLoader.ICON_IMAGE, [], @(h,ev)out_figure_image(hFig, 'Viewer'), []);
        jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_J, KeyEvent.CTRL_MASK));
        % === CONTACT SHEETS ===
        if ~getappdata(hFig, 'isStatic')
            jMenuSave.addSeparator();
            gui_component('MenuItem', jMenuSave, [], 'Time contact sheet: Coronal',  IconLoader.ICON_CONTACTSHEET, [], @(h,ev)view_contactsheet(hFig, 'time', 'y', DefaultOutputDir), []);
            gui_component('MenuItem', jMenuSave, [], 'Time contact sheet: Sagittal', IconLoader.ICON_CONTACTSHEET, [], @(h,ev)view_contactsheet(hFig, 'time', 'x', DefaultOutputDir), []);
            gui_component('MenuItem', jMenuSave, [], 'Time contact sheet: Axial',    IconLoader.ICON_CONTACTSHEET, [], @(h,ev)view_contactsheet(hFig, 'time', 'z', DefaultOutputDir), []);
        end
        jMenuSave.addSeparator();
        gui_component('MenuItem', jMenuSave, [], 'Volume contact sheet: Coronal',  IconLoader.ICON_CONTACTSHEET, [], @(h,ev)view_contactsheet(hFig, 'volume', 'y', DefaultOutputDir), []);
        gui_component('MenuItem', jMenuSave, [], 'Volume contact sheet: Sagittal', IconLoader.ICON_CONTACTSHEET, [], @(h,ev)view_contactsheet(hFig, 'volume', 'x', DefaultOutputDir), []);
        gui_component('MenuItem', jMenuSave, [], 'Volume contact sheet: Axial',    IconLoader.ICON_CONTACTSHEET, [], @(h,ev)view_contactsheet(hFig, 'volume', 'z', DefaultOutputDir), []);
    
    % ==== Display menu ====
    gui_popup(jPopup, hFig);
end

%% =======================================================================================
%  ===== MRI FUNCTIONS ===================================================================
%  =======================================================================================    
%% ===== SETUP MRI =====
function [sMri, Handles] = SetupMri(hFig)
    global GlobalData;
    % Get Mri and figure handles
    [sMri, TessInfo, iTess, iMri] = panel_surface('GetSurfaceMri', hFig);
    Handles = bst_figures('GetFigureHandles', hFig);
    
    % ===== PREPARE DISPLAY =====
    cubeSize = size(sMri.Cube);
    FOV      = cubeSize .* sMri.Voxsize;
    % Empty axes
    cla(Handles.axs);
    cla(Handles.axc);
    cla(Handles.axa);
    % Sagittal
    [Handles.imgs_mri, Handles.crosshairSagittalH, Handles.crosshairSagittalV] = ...
        SetupView(Handles.axs, [FOV(2),FOV(3)], [cubeSize(3),cubeSize(2)], {'P','A'});
    % Coronal
    [Handles.imgc_mri, Handles.crosshairCoronalH, Handles.crosshairCoronalV] = ...
        SetupView(Handles.axc, [FOV(1),FOV(3)], [cubeSize(3),cubeSize(1)], {'L','R'});
    % Axial 
    [Handles.imga_mri, Handles.crosshairAxialH, Handles.crosshairAxialV] = ...
        SetupView(Handles.axa, [FOV(1),FOV(2)], [cubeSize(2),cubeSize(1)], {'L','R'});
    % Save handles
    bst_figures('SetFigureHandles', hFig, Handles);
    % Save slices handles in the surface
    TessInfo(iTess).hPatch = [Handles.imgs_mri, Handles.imgc_mri, Handles.imga_mri];
    setappdata(hFig, 'Surface', TessInfo);

    % === SET MOUSE CALLBACKS ===
    set(hFig, 'ButtonDownFcn', @(h,ev)MouseButtonDownAxes_Callback(hFig,[],sMri,Handles));
    set([Handles.axa, Handles.imga_mri, Handles.crosshairAxialH,    Handles.crosshairAxialV],    'ButtonDownFcn', @(h,ev)MouseButtonDownAxes_Callback(hFig,Handles.axa, sMri, Handles));
    set([Handles.axs, Handles.imgs_mri, Handles.crosshairSagittalH, Handles.crosshairSagittalV], 'ButtonDownFcn', @(h,ev)MouseButtonDownAxes_Callback(hFig,Handles.axs, sMri, Handles));
    set([Handles.axc, Handles.imgc_mri, Handles.crosshairCoronalH,  Handles.crosshairCoronalV],  'ButtonDownFcn', @(h,ev)MouseButtonDownAxes_Callback(hFig,Handles.axc, sMri, Handles));
    % Register MouseMoved and MouseButtonUp callbacks for current figure
    set(hFig, 'WindowButtonDownFcn',   @(h,ev)MouseButtonDownFigure_Callback(hFig, sMri, Handles), ...
              'WindowButtonMotionFcn', @(h,ev)MouseMove_Callback(hFig, sMri, Handles), ...
              'WindowButtonUpFcn',     @(h,ev)MouseButtonUp_Callback(hFig, sMri, Handles) );
    % Define Mouse wheel callback (not supported by old versions of Matlab)
    if isprop(hFig, 'WindowScrollWheelFcn')
        set(hFig, 'WindowScrollWheelFcn', @(h,ev)MouseWheel_Callback(hFig, sMri, Handles, ev));
    end
    
    % === LOAD LANDMARKS ===
    % Load landmarks/fiducials
    [sMri, Handles] = LoadLandmarks(sMri, Handles);
    % Save mri and handles
    GlobalData.Mri(iMri) = sMri;
    bst_figures('SetFigureHandles', hFig, Handles);
    
    % === CONFIGURE SLIDERS ===
    jSliders = [Handles.jSliderSagittal, Handles.jSliderCoronal, Handles.jSliderAxial];
    % Reset sliders callbacks
    java_setcb(jSliders, 'StateChangedCallback', []);
    % Configure each slider
    for i = 1:3
        % Set min and max bounds
        jSliders(i).setMinimum(1);
        jSliders(i).setMaximum(cubeSize(i));
    end
    % Set default location to middle of the volume
    SetLocation('mri', sMri, Handles, TessInfo(iTess).CutsPosition);
    % Set sliders callback
    for i = 1:3
        java_setcb(jSliders(i), 'StateChangedCallback', @(h,ev)sliderClicked_Callback(hFig,i,ev));
    end
end


%% ===== SETUP A VIEW =====
function [hImgMri, hCrossH, hCrossV] = SetupView(hAxes, xySize, imgSize, orientLabels)
    % MRI image
    hImgMri = image('XData',        [1, xySize(1)], ...
                    'YData',        [1, xySize(2)], ...
                    'CData',        zeros(imgSize(1), imgSize(2)), ...
                    'CDataMapping', 'scaled', ...
                    'Parent',       hAxes);
    % Axes
    axis(hAxes, 'image', 'off');
    % Crosshair
    hCrossH = line(get(hAxes, 'XLim'), [1 1], [2, 2], 'EraseMode', 'normal', 'Color', [.8 .8 .8], 'Parent', hAxes);
    hCrossV = line([1,1], get(hAxes, 'YLim'), [2, 2], 'EraseMode', 'normal', 'Color', [.8 .8 .8], 'Parent', hAxes);
    % Orientation markers
    V = axis(hAxes);
    fontSize = bst_get('FigFont');
    text(       6, 15, orientLabels{1}, 'verticalalignment', 'top', 'FontSize', fontSize, 'FontUnits', 'points', 'color','w', 'Parent', hAxes, 'Tag', 'LabelOrient');
    text(.95*V(2), 15, orientLabels{2}, 'verticalalignment', 'top', 'FontSize', fontSize, 'FontUnits', 'points', 'color','w', 'Parent', hAxes, 'Tag', 'LabelOrient');
    % Save initial axis limits
    setappdata(hAxes, 'XLimInit', get(hAxes, 'XLim'));
    setappdata(hAxes, 'YLimInit', get(hAxes, 'YLim'));
end



%% ===== SLICES LOCATION =====
% GET: MRI COORDINATES
function XYZ = GetLocation(cs, sMri, handles)
    % Get MRI coordinates of current point in volume
    XYZ(1) = handles.jSliderSagittal.getValue();
    XYZ(2) = handles.jSliderCoronal.getValue();
    XYZ(3) = handles.jSliderAxial.getValue();
    % Convert if necessary in 
    if strcmpi(cs, 'mm')
        XYZ = sMri.Voxsize .* XYZ;
    end
end

% GET: MRI COORDINATES
% Usage:  SetLocation(cs, sMri, Handles, XYZ)
%         SetLocation(cs, hFig,      [], XYZ)
function SetLocation(cs, sMri, Handles, XYZ)
    % If inputs are not defined
    if isnumeric(sMri)
        hFig = sMri;
        sMri = panel_surface('GetSurfaceMri', hFig);
        Handles = bst_figures('GetFigureHandles', hFig);
    end
    % Convert if necessary in 
    if strcmpi(cs, 'mm')
        XYZ = XYZ ./ sMri.Voxsize;
    end
    % Get that values are inside volume bounds
    XYZ(1) = bst_saturate(XYZ(1), [1, size(sMri.Cube,1)]);
    XYZ(2) = bst_saturate(XYZ(2), [1, size(sMri.Cube,2)]);
    XYZ(3) = bst_saturate(XYZ(3), [1, size(sMri.Cube,3)]);
    % Set sliders values
    Handles.jSliderSagittal.setValue(XYZ(1));
    Handles.jSliderCoronal.setValue(XYZ(2));
    Handles.jSliderAxial.setValue(XYZ(3));
end


%% ===== MRI ORIENTATION =====
% ===== ROTATION =====
function MriTransform(hButton, Transf, iDim)
    global GlobalData;
    if (nargin < 3)
        iDim = [];
    end
    % Progress bar
    bst_progress('start', 'MRI Viewer', 'Updating MRI...');
    % Get figure
    hFig = ancestor(hButton,'figure');
    % Get Mri and figure handles
    [sMri, TessInfo, iTess, iMri] = panel_surface('GetSurfaceMri', hFig);
    % Prepare the history of transformations
    if isempty(sMri.InitTransf)
        sMri.InitTransf = cell(0,2);
    end
    % Type of transformation
    switch(Transf)
        case 'Rotate'
            switch iDim
                case 1
                    % Permutation of dimensions Y/Z
                    sMri.Cube = permute(sMri.Cube, [1 3 2]);
                    sMri.InitTransf(end+1,[1 2]) = {'permute', [1 3 2]};
                    % Flip / Z
                    sMri.Cube = flipdim(sMri.Cube, 3);
                    sMri.InitTransf(end+1,[1 2]) = {'flipdim', [3 size(sMri.Cube,3)]};
                    % Update voxel size
                    sMri.Voxsize = sMri.Voxsize([1 3 2]);
                case 2
                    % Permutation of dimensions X/Z
                    sMri.Cube = permute(sMri.Cube, [3 2 1]);
                    sMri.InitTransf(end+1,[1 2]) = {'permute', [3 2 1]};
                    % Flip / Z
                    sMri.Cube = flipdim(sMri.Cube, 3);
                    sMri.InitTransf(end+1,[1 2]) = {'flipdim', [3 size(sMri.Cube,3)]};
                    % Update voxel size
                    sMri.Voxsize = sMri.Voxsize([3 2 1]);
                case 3
                    % Permutation of dimensions X/Y
                    sMri.Cube = permute(sMri.Cube, [2 1 3]);
                    sMri.InitTransf(end+1,[1 2]) = {'permute', [2 1 3]};
                    % Flip / Y
                    sMri.Cube = flipdim(sMri.Cube, 2);
                    sMri.InitTransf(end+1,[1 2]) = {'flipdim', [2 size(sMri.Cube,2)]};
                    % Update voxel size
                    sMri.Voxsize = sMri.Voxsize([2 1 3]);
            end
        case 'Flip'
            % Flip MRI cube
            sMri.Cube = flipdim(sMri.Cube, iDim);
            sMri.InitTransf(end+1,[1 2]) = {'flipdim', [iDim size(sMri.Cube,iDim)]};
        case 'Permute'
            % Permute MRI dimensions
            sMri.Cube = permute(sMri.Cube, [3 1 2]);
            sMri.InitTransf(end+1,[1 2]) = {'permute', [3 1 2]};
            % Update voxel size
            sMri.Voxsize = sMri.Voxsize([3 1 2]);
    end
    % Update MRI
    GlobalData.Mri(iMri) = sMri;
    % Redraw slices
    [sMri, Handles] = SetupMri(hFig);
    [sMri, Handles] = LoadLandmarks(sMri, Handles);
    % History: add operation
    if ~isempty(iDim)
        historyComment = [Transf ': dimension ' num2str(iDim)];
    else
        historyComment = Transf;
    end
    sMri = bst_history('add', sMri, 'edit', historyComment);
    % Mark MRI as modified
    Handles.isModified = 1;
    bst_figures('SetFigureHandles', hFig, Handles);
    GlobalData.Mri(iMri) = sMri;
    % Redraw MRI slices
    UpdateMriDisplay(hFig);
    bst_progress('stop');
end


%% =======================================================================================
%  ===== DISPLAY FUNCTIONS ===============================================================
%  =======================================================================================
%% ===== UPDATE MRI DISPLAY =====
% Usage:  UpdateMriDisplay(hFig, dims)
%         UpdateMriDisplay(hFig)
function UpdateMriDisplay(hFig, dims, varargin)
    % Parse inputs
    if (nargin < 2) || isempty(dims)
        dims = [1 2 3];
    end
    % Get MRI and handles
    sMri = panel_surface('GetSurfaceMri', hFig);
    Handles = bst_figures('GetFigureHandles', hFig);
    % Get slices locations
    XYZ = GetLocation('mri', sMri, Handles);
    newPos = [NaN,NaN,NaN];
    newPos(dims) = XYZ(dims);
    % Redraw slices
    panel_surface('PlotMri', hFig, newPos);
    
    % Display crosshair
    UpdateCrosshairPosition(sMri, Handles);
    % Display fiducials/other landmarks (Not if read only MRI)
    if ~Handles.isReadOnly
        UpdateVisibleLandmarks(sMri, Handles, dims);
    end
    % Update coordinates display
    UpdateCoordinates(sMri, Handles);
end

%% ===== UPDATE SURFACE COLOR =====
function UpdateSurfaceColor(hFig, varargin) %#ok<DEFNU>
    UpdateMriDisplay(hFig);
end

%% ===== DISPLAY CROSSHAIR =====
function UpdateCrosshairPosition(sMri, Handles)
    mmCoord = GetLocation('mm', sMri, Handles);
    if isempty(Handles.crosshairSagittalH) || ~ishandle(Handles.crosshairSagittalH)
        return
    end
    % Sagittal
    set(Handles.crosshairSagittalH, 'YData', mmCoord(3) .*[1 1]);
    set(Handles.crosshairSagittalV, 'XData', mmCoord(2) .*[1 1]);
    % Coronal
    set(Handles.crosshairCoronalH, 'YData', mmCoord(3) .*[1 1]);
    set(Handles.crosshairCoronalV, 'XData', mmCoord(1) .*[1 1]);
    % Axial
    set(Handles.crosshairAxialH, 'YData', mmCoord(2) .*[1 1]);
    set(Handles.crosshairAxialV, 'XData', mmCoord(1) .*[1 1]);
end
    

%% ===== DISPLAY COORDINATES =====
function UpdateCoordinates(sMri, Handles)
    % Millimeters (MRI cube coordinates)
    mmXYZ = GetLocation('mm', sMri, Handles);
    set(Handles.textCoordMriX, 'String', sprintf('x: %3.2f', mmXYZ(1)));
    set(Handles.textCoordMriY, 'String', sprintf('y: %3.2f', mmXYZ(2)));
    set(Handles.textCoordMriZ, 'String', sprintf('z: %3.2f', mmXYZ(3)));
    % === SCS (CTF) coordinates system ===
    if ~isempty(sMri.SCS.R)
        scsXYZ = cs_mri2scs(sMri, mmXYZ')';
        set(Handles.textCoordScsX, 'String', sprintf('x: %3.2f', scsXYZ(1)));
        set(Handles.textCoordScsY, 'String', sprintf('y: %3.2f', scsXYZ(2)));
        set(Handles.textCoordScsZ, 'String', sprintf('z: %3.2f', scsXYZ(3)));
    end
    % === MNI coordinates system ===
    if isfield(sMri, 'NCS') && isfield(sMri.NCS, 'R') && ~isempty(sMri.NCS.R)
        mniXYZ = cs_mri2mni(sMri, mmXYZ')';
        if ~isempty(mniXYZ)
            set(Handles.textCoordMniX, 'String', sprintf('x: %3.2f', mniXYZ(1)));
            set(Handles.textCoordMniY, 'String', sprintf('y: %3.2f', mniXYZ(2)));
            set(Handles.textCoordMniZ, 'String', sprintf('z: %3.2f', mniXYZ(3)));
            if isfield(Handles, 'textNoMni')
                set(Handles.textNoMni, 'Visible', 'off');
            end
        end
    end
end
   
    
    
%% =======================================================================================
%  ===== MOUSE CALLBACKS =================================================================
%  =======================================================================================
%% ===== MOUSE CLICK: AXES =====       
function MouseButtonDownAxes_Callback(hFig, hAxes, sMri, Handles)
    % Double-click: Reset view
    if strcmpi(get(hFig, 'SelectionType'), 'open')
        ButtonZoom_Callback(hFig, 'reset');
        setappdata(hFig,'clickAction','MouseDownOk');
        return;
    end
    % Check if MouseUp was executed before MouseDown
    if isappdata(hFig, 'clickAction') && strcmpi(getappdata(hFig,'clickAction'), 'MouseDownNotConsumed')
        % Should ignore this MouseDown event
        setappdata(hFig,'clickAction','MouseDownOk');
        return;
    end
    % Switch between different types of mouse actions
    clickAction = '';
    switch(get(hFig, 'SelectionType'))
        % Left click
        case 'normal'
            clickAction = 'LeftClick';
            % Move crosshair according to mouse position
            if ~isempty(hAxes)
                MouseMoveCrosshair(hAxes, sMri, Handles);
            end
        % CTRL+Mouse, or Mouse right
        case 'alt'
            clickAction = 'RightClick';
        % SHIFT+Mouse
        case 'extend'
            clickAction = 'ShiftClick';
    end
    % If no action was defined : nothing to do more
    if isempty(clickAction)
        return
    end
    
    % Reset the motion flag
    setappdata(hFig, 'hasMoved', 0);
    % Record mouse location in the figure coordinates system
    setappdata(hFig, 'clickAction', clickAction);
    setappdata(hFig, 'clickSource', hAxes);
    setappdata(hFig, 'clickPositionFigure', get(hFig, 'CurrentPoint'));
end


%% ===== MOUSE CLICK: FIGURE =====
function MouseButtonDownFigure_Callback(hFig, varargin)
    setappdata(hFig, 'clickPositionFigure', get(hFig, 'CurrentPoint'));
end

    
%% ===== MOUSE MOVE =====
function MouseMove_Callback(hFig, sMri, Handles) 
    % Get mouse actions
    clickSource = getappdata(hFig, 'clickSource');
    clickAction = getappdata(hFig, 'clickAction');
    if isempty(clickAction)
        return
    end
    % If MouseUp was executed before MouseDown
    if strcmpi(clickAction, 'MouseDownNotConsumed') || isempty(getappdata(hFig, 'clickPositionFigure'))
        % Ignore Move event
        return
    end
    % Set that mouse has moved
    setappdata(hFig, 'hasMoved', 1);
    % Get current mouse location in figure
    curptFigure = get(hFig, 'CurrentPoint');
    motionFigure = 0.3 * (curptFigure - getappdata(hFig, 'clickPositionFigure'));
    % Update click point location
    setappdata(hFig, 'clickPositionFigure', curptFigure);
    switch (clickAction)
        case 'LeftClick'
            if isempty(clickSource)
                return
            end
            hAxes = clickSource;
            % Move slices according to mouse position
            MouseMoveCrosshair(hAxes, sMri, Handles);
        case 'RightClick'
            % Define contrast/brightness transform
            modifContrast   = motionFigure(2)  .* .7 ./ 100;
            modifBrightness = -motionFigure(2) ./ 100;
            % Changes contrast
            sColormap = bst_colormaps('ColormapChangeModifiers', 'Anatomy', [modifContrast, modifBrightness], 0);
            set(hFig, 'Colormap', sColormap.CMap);
            % Display immediately changes if no results displayed
            ResultsFile = getappdata(hFig, 'ResultsFile');
            if isempty(ResultsFile)
                bst_colormaps('FireColormapChanged', 'Anatomy');
            end
        case 'colorbar'
            % Changes contrast
            ColormapInfo = getappdata(hFig, 'Colormap');
            sColormap = bst_colormaps('ColormapChangeModifiers', ColormapInfo.Type, [motionFigure(1), motionFigure(2)] ./ 100, 0);
            set(hFig, 'Colormap', sColormap.CMap);
    end
end

%% ===== MOUSE BUTTON UP =====       
function MouseButtonUp_Callback(hFig, varargin) 
    hasMoved = getappdata(hFig, 'hasMoved');
    clickAction = getappdata(hFig, 'clickAction');
    
    % Mouse was not moved during click
    if ~isempty(clickAction)
        if ~hasMoved
            switch (clickAction)
                case 'RightClick'
                    DisplayFigurePopup(hFig);
            end
        % Mouse was moved
        else
            switch (clickAction)
                case {'colorbar', 'RightClick'}
                    % Apply new colormap to all figures
                    ColormapInfo = getappdata(hFig, 'Colormap');
                    bst_colormaps('FireColormapChanged', ColormapInfo.Type);
            end
        end
    end
    % Set figure as current figure
    bst_figures('SetCurrentFigure', hFig, '3D');
    if isappdata(hFig, 'Timefreq') && ~isempty(getappdata(hFig, 'Timefreq'))
        bst_figures('SetCurrentFigure', hFig, 'TF');
    end
    
    % Remove mouse callbacks appdata
    if isappdata(hFig, 'clickPositionFigure')
        rmappdata(hFig, 'clickPositionFigure');
    end
    if isappdata(hFig, 'clickSource')
        rmappdata(hFig, 'clickSource');
    end
    if isappdata(hFig, 'clickAction')
        rmappdata(hFig, 'clickAction');
    else
        setappdata(hFig, 'clickAction', 'MouseDownNotConsumed');
    end
    setappdata(hFig, 'hasMoved', 0);
end


%% ===== FIGURE MOUSE WHEEL =====
function MouseWheel_Callback(hFig, sMri, Handles, event) 
    if isempty(event)
        return;
    end
    % Get which axis is selected
    hAxes = get(hFig, 'CurrentAxes');
    if isempty(hAxes)
        return
    end
    % Get dimension corresponding to this axes
    switch (hAxes)
        case Handles.axs,  dim = 1;
        case Handles.axc,  dim = 2;  
        case Handles.axa,  dim = 3; 
        otherwise,         return;
    end
    % Get current position
    XYZ = GetLocation('mri', sMri, Handles);
    % Update location
    XYZ(dim) = XYZ(dim) - event.VerticalScrollCount;
    SetLocation('mri', sMri, Handles, XYZ);
end
    
%% ===== MOVE CROSSHAIR =====
function MouseMoveCrosshair(hAxes, sMri, Handles)
    % Get mouse 2D position
    mouse2DPos = get(hAxes, 'CurrentPoint');
    mouse2DPos = [mouse2DPos(1,1), mouse2DPos(1,2)];
    % Remove axes offset
%     mouse2DPos(1) = mouse2DPos(1) + 0.5;
%     mouse2DPos(2) = mouse2DPos(2) + 0.5;
%     XLim = get(hAxes, 'XLim');
%     YLim = get(hAxes, 'YLim');
%     mouse2DPos(1) = mouse2DPos(1) + XLim(1);
%     mouse2DPos(2) = mouse2DPos(2) + YLim(1);
    % Get current slices
    slicesXYZ = GetLocation('mm', sMri, Handles);
    % Get 3D mouse position 
    mouse3DPos = [0 0 0];
    switch hAxes
        case Handles.axs
            mouse3DPos(1) = slicesXYZ(1);
            mouse3DPos(2) = mouse2DPos(1);
            mouse3DPos(3) = mouse2DPos(2);
        case Handles.axc
            mouse3DPos(2) = slicesXYZ(2);
            mouse3DPos(1) = mouse2DPos(1);
            mouse3DPos(3) = mouse2DPos(2);
        case Handles.axa
            mouse3DPos(3) = slicesXYZ(3);
            mouse3DPos(1) = mouse2DPos(1);
            mouse3DPos(2) = mouse2DPos(2);
    end
    % Convert 3D mouse points in MRI coordinates
    mouse3DPos = round(mouse3DPos ./ sMri.Voxsize);
    % Limit values to MRI cube
    mriSize = size(sMri.Cube);
    mouse3DPos(1) = min(max(mouse3DPos(1), 1), mriSize(1));
    mouse3DPos(2) = min(max(mouse3DPos(2), 1), mriSize(2));
    mouse3DPos(3) = min(max(mouse3DPos(3), 1), mriSize(3));
    % Set new slices location
    SetLocation('mri', sMri, Handles, mouse3DPos);
end

    
%% =======================================================================================
%  ===== LANDMARKS SELECTION =============================================================
%  =======================================================================================
%% ===== LOAD LANDMARKS =====
function [sMri, Handles] = LoadLandmarks(sMri, Handles)
    PtsColors = [0 .5 0;   0 .8 0;   .4 1 .4;   1 0 0;   1 .5 0;   1 1 0;   .8 0 .8];
    % Nasion
    [sMri,Handles] = LoadFiducial(sMri, Handles, 'SCS', 'NAS', PtsColors(1,:), Handles.buttonNasView, Handles.titleNAS, 'hPointNAS');
    [sMri,Handles] = LoadFiducial(sMri, Handles, 'SCS', 'LPA', PtsColors(2,:), Handles.buttonLpaView, Handles.titleLPA, 'hPointLPA');
    [sMri,Handles] = LoadFiducial(sMri, Handles, 'SCS', 'RPA', PtsColors(3,:), Handles.buttonRpaView, Handles.titleRPA, 'hPointRPA');
    [sMri,Handles] = LoadFiducial(sMri, Handles, 'NCS', 'AC',  PtsColors(4,:), Handles.buttonAcView,  Handles.titleAC,  'hPointAC');
    [sMri,Handles] = LoadFiducial(sMri, Handles, 'NCS', 'PC',  PtsColors(5,:), Handles.buttonPcView,  Handles.titlePC,  'hPointPC');
    [sMri,Handles] = LoadFiducial(sMri, Handles, 'NCS', 'IH',  PtsColors(6,:), Handles.buttonIhView,  Handles.titleIH,  'hPointIH');

    % ===== SCS transformation =====
    if ~isempty(sMri.SCS.NAS) && ~isempty(sMri.SCS.LPA) && ~isempty(sMri.SCS.RPA)
        try
            scsTransf = cs_mri2scs(sMri);
            sMri.SCS.R      = scsTransf.R;
            sMri.SCS.T      = scsTransf.T;
            sMri.SCS.Origin = scsTransf.Origin;
        catch
            bst_error('Impossible to identify the SCS coordinate system with the specified coordinates.', 'MRI Viewer', 0);
        end
    end   
    % ===== MNI transformation =====
    if ~isempty(sMri.NCS.AC) && ~isempty(sMri.NCS.PC) && ~isempty(sMri.NCS.IH)
        try
            mniTransf = cs_mri2mni(sMri);
            if ~isempty(mniTransf.R)
                sMri.NCS.R      = mniTransf.R;
                sMri.NCS.T      = mniTransf.T;
                sMri.NCS.Origin = mniTransf.Origin;
            end
        catch
            bst_error('Impossible to identify the NCS coordinate system with the specified coordinates.', 'MRI Viewer', 0);
        end
    end   
    % Update landmarks display
    if ~Handles.isReadOnly
        UpdateVisibleLandmarks(sMri, Handles);
    end
    % Update coordinates displayed in the bottom-right panel
    UpdateCoordinates(sMri, Handles);
end


%% ===== LOAD FIDUCIAL =====
function [sMri,Handles] = LoadFiducial(sMri, Handles, FidCategory, FidName, FidColor, hButton, hTitle, PtHandleName)
    % If point is not selected yet
    if ~isfield(sMri.(FidCategory), FidName) || isempty(sMri.(FidCategory).(FidName))
        % Mark that point is not selected yet
        sMri.(FidCategory).(FidName) = [];
        set(hButton, 'Enable', 'off', 'BackgroundColor', [0 0 0]);
        set(hTitle, 'ForegroundColor', [.9 0 0]);
    else
        % Mark that point was selected
        set(hButton, 'Enable', 'on', 'BackgroundColor', FidColor);
        set(hTitle, 'ForegroundColor', [.94 .94 .94]);
        % If point already exist : delete it
        if ~isempty(Handles.(PtHandleName))
            delete(Handles.(PtHandleName)(ishandle(Handles.(PtHandleName))));
        end
        % Create a marker object for this point
        Handles.(PtHandleName) = PlotPoint(sMri, Handles, sMri.(FidCategory).(FidName), FidColor);
    end
end

    
%% ===== PLOT POINT =====
function hPt = PlotPoint(sMri, Handles, ptLoc, ptColor)
    % Axes Sagittal
    hPt(1,1) = line(ptLoc(2), ptLoc(3), 1.5, ...
                  'MarkerFaceColor', ptColor, 'Marker', 'o', 'MarkerEdgeColor', [.4 .4 .4], 'MarkerSize', 7, ...
                  'Parent', Handles.axs, 'ButtonDownFcn', @(h,ev)MouseButtonDownAxes_Callback(Handles.MRIViewer, Handles.axs, sMri, Handles), 'Visible', 'off');
    hPt(1,2) = line(ptLoc(1), ptLoc(3), 1.5, ...
                  'MarkerFaceColor', ptColor, 'Marker', 'o', 'MarkerEdgeColor', [.4 .4 .4], 'MarkerSize', 7, ...
                  'Parent', Handles.axc, 'ButtonDownFcn', @(h,ev)MouseButtonDownAxes_Callback(Handles.MRIViewer, Handles.axc, sMri, Handles), 'Visible', 'off');
    hPt(1,3) = line(ptLoc(1), ptLoc(2), 1.5, ...
                  'MarkerFaceColor', ptColor, 'Marker', 'o', 'MarkerEdgeColor', [.4 .4 .4], 'MarkerSize', 7, ...
                  'Parent', Handles.axa, 'ButtonDownFcn', @(h,ev)MouseButtonDownAxes_Callback(Handles.MRIViewer, Handles.axa, sMri, Handles), 'Visible', 'off');
end

              
    
%% ===== UPDATE VISIBLE LANDMARKS =====
% For each point, if it is located close to a slice, display it; else hide it 
function UpdateVisibleLandmarks(sMri, Handles, slicesToUpdate)
    % Slices indices to update (direct indicing)
    if (nargin < 3)
        slicesToUpdate = [1 1 1];
    else
        slicesToUpdate = ismember([1 2 3], slicesToUpdate);
    end
    slicesLoc = GetLocation('mm', sMri, Handles);
    % Tolerance to display a point in a slice (in voxels)
    nTol = 2;
    
    function showPt(hPoint, locPoint)
        if ~isempty(locPoint) && ~isempty(hPoint) && all(ishandle(hPoint))
            isVisible    = slicesToUpdate & (abs(locPoint - slicesLoc) <= nTol);
            isNotVisible = slicesToUpdate & ~isVisible;
            set(hPoint(isVisible),    'Visible', 'on');
            set(hPoint(isNotVisible), 'Visible', 'off');
        end
    end
    
    % Show all points
    showPt(Handles.hPointNAS, sMri.SCS.NAS);
    showPt(Handles.hPointLPA, sMri.SCS.LPA);
    showPt(Handles.hPointRPA, sMri.SCS.RPA);
    showPt(Handles.hPointAC,  sMri.NCS.AC);
    showPt(Handles.hPointPC,  sMri.NCS.PC);
    showPt(Handles.hPointIH,  sMri.NCS.IH);
end

    
%% ===== SET FIDUCIALS ======
function SetFiducial(hFig, FidCategory, FidName)
    global GlobalData;
    % Get MRI
    [sMri,TessInfo,iTess,iMri] = panel_surface('GetSurfaceMri', hFig);
    % Get the file in the database
    [sSubject, iSubject, iAnatomy] = bst_get('MriFile', sMri.FileName);
    % If it is not the first MRI: can't edit the fiducuials
    if (iAnatomy > 1)
        bst_error('The fiducials can be edited only in the first MRI file.', 'Set fiducials', 0);
    end
    % Get handles
    Handles = bst_figures('GetFigureHandles', hFig);
    % Get current position
    XYZ = GetLocation('mm', sMri, Handles);
    % Save fiducial position
    sMri.(FidCategory).(FidName) = XYZ;
    % Reload fiducials
    [sMri, Handles] = LoadLandmarks(sMri, Handles);
    % Mark MRI as modified
    Handles.isModified = 1;
    bst_figures('SetFigureHandles', hFig, Handles);
    GlobalData.Mri(iMri) = sMri;
end


%% ===== VIEW FIDUCIALS =====
function ViewFiducial(hFig, FidCategory, FiducialName)
    % Reset zoom
    ButtonZoom_Callback(hFig, 'reset');
    % Get MRI
    sMri = panel_surface('GetSurfaceMri', hFig);
    % Get handles
    Handles = bst_figures('GetFigureHandles', hFig);
    % Get fiducial position
    switch (FiducialName)
        case {'NAS','LPA','RPA'}
            XYZ = sMri.(FidCategory).(FiducialName);
        case {'AC','PC','IH'}
            XYZ = sMri.(FidCategory).(FiducialName);
    end
    % Change slices positions
    SetLocation('mm', sMri, Handles, XYZ);
end


%% =======================================================================================
%  ===== VALIDATION BUTTONS ==============================================================
%  =======================================================================================
%% ===== BUTTON CANCEL =====
function ButtonCancel_Callback(hFig, varargin)
    global GlobalData;
    % Get figure handles
    [hFig,iFig,iDS] = bst_figures('GetFigure', hFig);
    % Mark that nothing changed
    GlobalData.DataSet(iDS).Figure(iFig).Handles.isModified = 0;
    % Unload all datasets that used this MRI
    sMri = panel_surface('GetSurfaceMri', hFig);
    bst_memory('UnloadMri', sMri.FileName);
    % Close figure
    if ishandle(hFig)
        close(hFig);
    end
end

%% ===== BUTTON SAVE =====
function ButtonSave_Callback(hFig, varargin)
    global GlobalData;
    % Get figure handles
    [hFig,iFig,iDS] = bst_figures('GetFigure', hFig);
    % If something was changed in the MRI
    if GlobalData.DataSet(iDS).Figure(iFig).Handles.isModified
        % Save MRI
        [isCloseAccepted, MriFile] = SaveMri(hFig);
        % If closing the window was not accepted: Cancel button click
        if ~isCloseAccepted
            return
        end
        % Mark that nothing was changed
        GlobalData.DataSet(iDS).Figure(iFig).Handles.isModified = 0;
        % Unload all datasets that used this MRI
        bst_memory('UnloadMri', MriFile);
    else
        % Close figure
        close(hFig);
    end
end


%% ===== SAVE MRI =====
function [isCloseAccepted, MriFile] = SaveMri(hFig)
    ProtocolInfo = bst_get('ProtocolInfo');
    % Get MRI
    sMri = panel_surface('GetSurfaceMri', hFig);
    MriFile = sMri.FileName;
    MriFileFull = bst_fullfile(ProtocolInfo.SUBJECTS, MriFile);
    % Do not accept "Save" if user did not select all the fiducials
    if isempty(sMri.SCS.NAS) || isempty(sMri.SCS.LPA) || isempty(sMri.SCS.RPA) || isempty(sMri.NCS.AC) || isempty(sMri.NCS.PC) || isempty(sMri.NCS.IH)
        bst_error(sprintf('You must select all the fiducials:\nNAS, LPA, RPA, AC, PC and IH.'), 'MRIViewer', 0);
        isCloseAccepted = 0;
        return;
    end
    isCloseAccepted = 1;

    % ==== GET REFERENCIAL CHANGES ====
    % Get subject in database, with subject directory
    [sSubject, iSubject, iAnatomy] = bst_get('MriFile', sMri.FileName);
    % Load the previous MRI fiducials
    warning('off', 'MATLAB:load:variableNotFound');
    sMriOld = load(MriFileFull, 'SCS');
    warning('on', 'MATLAB:load:variableNotFound');
    % If the fiducials were modified
    if isfield(sMriOld, 'SCS') && all(isfield(sMriOld.SCS,{'NAS','LPA','RPA'})) ...
            && ~isempty(sMriOld.SCS.NAS) && ~isempty(sMriOld.SCS.LPA) && ~isempty(sMriOld.SCS.RPA) ...
            && ((max(sMri.SCS.NAS - sMriOld.SCS.NAS) > 1e-3) || ...
                (max(sMri.SCS.LPA - sMriOld.SCS.LPA) > 1e-3) || ...
                (max(sMri.SCS.RPA - sMriOld.SCS.RPA) > 1e-3))
        % Nothing to do...
    else
        sMriOld = [];
    end
    
    % === HISTORY ===
    % History: Edited the fiducials
    if ~isfield(sMriOld, 'SCS') || ~isequal(sMriOld.SCS, sMri.SCS) || ~isfield(sMriOld, 'NCS') || ~isequal(sMriOld.NCS, sMri.NCS)
        sMri = bst_history('add', sMri, 'edit', 'User edited the fiducials');
    end
    
    % ==== SAVE MRI ====
    bst_progress('start', 'MRI Viewer', 'Saving MRI...');
    try
        bst_save(MriFileFull, sMri, 'v7');
    catch
        bst_error(['Cannot save MRI in file "' sMri.FileName '"'], 'MRI Viewer');
        return;
    end
    bst_progress('stop');
 
    % ==== UPDATE OTHER MRI FILES ====
    if ~isempty(sMriOld) && (length(sSubject.Anatomy) > 1)
        % New fiducials
        s.SCS = sMri.SCS;
        s.NCS = sMri.NCS;
        % Update each MRI file
        for iAnat = 1:length(sSubject.Anatomy)
            % Skip the current one
            if (iAnat == iAnatomy)
                continue;
            end
            % Save NCS and SCS structures
            updateMriFile = file_fullpath(sSubject.Anatomy(iAnat).FileName);
            bst_save(updateMriFile, s, 'v7', 1);
        end
    end
    
    % ==== REALIGN SURFACES ====
    if ~isempty(sMriOld)
        UpdateSurfaceCS({sSubject.Surface.FileName}, sMriOld, sMri);
    end
end


%% ===== UPDATE SURFACE CS =====
function UpdateSurfaceCS(SurfaceFiles, sMriOld, sMriNew)
    % Progress bar
    bst_progress('start', 'MRI Viewer', 'Updating surfaces...', 0, length(SurfaceFiles));
    % Process all surfaces
    for i = 1:length(SurfaceFiles)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%% WARNING: DELETE THE SCS FIELD FROM THE SURFACE
        %%%%          Losing the conversion: surface file CS => SCS
        %%%%          => Impossible to import new surfaces after that
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Load surface
        sSurf = in_tess_bst(SurfaceFiles{i});
        % Create new surface
        sSurfNew.Vertices = sSurf.Vertices;
        sSurfNew.Faces    = sSurf.Faces;
        sSurfNew.Comment  = sSurf.Comment;
        if isfield(sSurf, 'History')
            sSurfNew.History  = sSurf.History;
        end
        if isfield(sSurf, 'Atlas') && isfield(sSurf, 'iAtlas')
            sSurfNew.Atlas  = sSurf.Atlas;
            sSurfNew.iAtlas  = sSurf.iAtlas;
        end
        % Realiagn vertices in new coordinates system
        sSurfNew.Vertices = cs_scs2mri(sMriOld, sSurfNew.Vertices' .* 1000)';
        sSurfNew.Vertices = cs_mri2scs(sMriNew, sSurfNew.Vertices')' ./ 1000;
        % Add history record
        sSurfNew = bst_history('add', sSurfNew, 're-orient', 'User edited the fiducials.');
        % Increment progress bar
        bst_progress('inc', 1);
        % Save surface
        bst_save(file_fullpath(SurfaceFiles{i}), sSurfNew, 'v7');
    end
    bst_progress('stop');
end


%% ===== SET FIDUCIALS FOR SUBJECT =====
% WARNING: Inputs are in millimeters
function SetSubjectFiducials(iSubject, NAS, LPA, RPA, AC, PC, IH) %#ok<DEFNU>
    % Get the updated subject structure
    sSubject = bst_get('Subject', iSubject);
    if isempty(sSubject.iAnatomy)
        error('No MRI defined for this subject');
    end
    % Build full MRI file
    BstMriFile = file_fullpath(sSubject.Anatomy(sSubject.iAnatomy).FileName);
    % Load MRI structure
    sMri = in_mri_bst(BstMriFile);
    % Set fiducials
    if ~isempty(NAS)
        sMri.SCS.NAS = NAS(:)'; % Nasion (in MRI coordinates)
    end
    if ~isempty(LPA)
        sMri.SCS.LPA = LPA(:)'; % Left ear
    end
    if ~isempty(RPA)
        sMri.SCS.RPA = RPA(:)'; % Right ear
    end
    if ~isempty(AC)
        sMri.NCS.AC  = AC(:)';  % Anterior commissure
    end
    if ~isempty(PC)
        sMri.NCS.PC  = PC(:)';  % Posterior commissure
    end
    if ~isempty(IH)
        sMri.NCS.IH  = IH(:)';  % Inter-hemispherical point
    end
    % Compute MRI -> SCS transformation
    if ~isempty(NAS) && ~isempty(LPA) && ~isempty(RPA)
        scsTransf = cs_mri2scs(sMri);
        if ~isempty(scsTransf)
            sMri.SCS.R      = scsTransf.R;
            sMri.SCS.T      = scsTransf.T;
            sMri.SCS.Origin = scsTransf.Origin;
        end
    end
    % Compute MRI -> MNI transformation
    if ~isempty(AC) && ~isempty(PC) && ~isempty(IH)
        mniTransf = cs_mri2mni(sMri);
        if ~isempty(mniTransf)
            sMri.NCS.R      = mniTransf.R;
            sMri.NCS.T      = mniTransf.T;
            sMri.NCS.Origin = mniTransf.Origin;
        end
    end
    % Save MRI structure (with fiducials)
    bst_save(BstMriFile, sMri, 'v7');
end


%% ===== CHECK FIDUCIALS VALIDATION =====
function isChecked = FiducialsValidation(MriFile) %#ok<DEFNU>
    isChecked = 0;
    % Get subject
    [sSubject, iSubject] = bst_get('MriFile', MriFile);
    % Check that it is the default anatomy
    if (iSubject ~= 0)
        return
    end
    % Read the history field of the MRI file
    MriFileFull = file_fullpath(MriFile);
    MriMat = load(MriFileFull, 'History');
    % If fiducials haven't been validated yet
    if ~isfield(MriMat, 'History') || isempty(MriMat.History) || ~any(strcmpi(MriMat.History(:,2), 'validate'))
        % Add a "validate" entry for the default anatomy
        MriMat = bst_history('add', MriMat, 'validate', 'User validated the fiducials');
        bst_save(MriFileFull, MriMat, 'v7', 1);
        % MRI viewer
        hFig = view_mri(MriFile, 'EditMri');
        drawnow;
        % Ask user to check/fix the fiducials
        java_dialog('msgbox', ['You have imported a standard anatomy, with standard fiducials positions (ears, nasion),' 10 ...
                               'but during the acquisition of your recordings, you may have used different positions.' 10 ...
                               'If you do not fix this now, the source localizations might be very unprecise.' 10 10 ...
                               'Please check and fix now the following points:' 10 ...
                               '   - NAS (Nasion)' 10 ...
                               '   - LPA (Left pre-auricular)' 10 ...
                               '   - RPA (Right pre-auricular)'], 'Default anatomy');
        % The check was performed
        isChecked = 1;
        % Wait for the MRI viewer to be closed
        waitfor(hFig);
    end
end


%% ===== EDIT FIDUCIALS =====
function EditFiducials(hFig)
    global GlobalData;
    % Get MRI
    [sMri,TessInfo,iTess,iMri] = panel_surface('GetSurfaceMri', hFig);
    % Get handles
    Handles = bst_figures('GetFigureHandles', hFig);
    % Add basic structures
    if ~isfield(sMri, 'SCS') || isempty(sMri.SCS)
        SCS.NAS = [];
        SCS.LPA = [];
        SCS.RPA = [];
        SCS.R = [];
        SCS.T = [];
    else
        SCS = sMri.SCS;
    end
    if ~isfield(sMri, 'NCS') || isempty(sMri.NCS)
        NCS.AC = [];
        NCS.PC = [];
        NCS.IH = [];
    else
        NCS = sMri.NCS;
    end
    strMsg = '';
    % Edit all the positions at once
    res = java_dialog('input', {...
        '<HTML>MRI coordinates [x,y,z], in millimeters:<BR><BR>Nasion (NAS):', ...
        'Left (LPA):', 'Right (RPA):', ...
        'Anterior commissure (AC):', 'Posterior commissure (PC):', 'Inter-hemispheric (IH):'}, ...
        'Edit fiducials', [], ...
        {num2str(SCS.NAS), num2str(SCS.LPA), num2str(SCS.RPA), ...
         num2str(NCS.AC),  num2str(NCS.PC),  num2str(NCS.IH)});
    % User cancelled
    if isempty(res) || ~iscell(res) || (length(res) ~= 6)
        return;
    end
    % Save new values: SCS
    fidNames = {'NAS','LPA','RPA'};
    for i = 1:length(fidNames)
        if ~isempty(res{i})
            fidPos = str2num(res{i});
            if (length(fidPos) == 3)
                SCS.(fidNames{i}) = fidPos;
            else
                strMsg = [strMsg, 'Invalid coordinates: ' fidNames{i} 10];
            end
        end
    end
    % Save new values: NCS
    fidNames = {'AC','PC','IH'};
    for i = 1:length(fidNames)
        if ~isempty(res{3+i})
            fidPos = str2num(res{3+i});
            if (length(fidPos) == 3)
                NCS.(fidNames{i}) = fidPos;
            else
                strMsg = [strMsg, 'Invalid coordinates: ' fidNames{i} 10];
            end
        end
    end
    % Display warning message
    if ~isempty(strMsg)
        java_dialog('error', strMsg, 'Edit fiducials');
    end
    % If no modifications with the original points
    if isequal(sMri.SCS, SCS) && isequal(sMri.NCS, NCS)
        return;
    end
    % Save modifications
    sMri.SCS = SCS;
    sMri.NCS = NCS;
    % Reload fiducials
    [sMri, Handles] = LoadLandmarks(sMri, Handles);
    % Mark MRI as modified
    Handles.isModified = 1;
    bst_figures('SetFigureHandles', hFig, Handles);
    GlobalData.Mri(iMri) = sMri;
end




