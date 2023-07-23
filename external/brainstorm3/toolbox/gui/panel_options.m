function varargout = panel_options(varargin)
% PANEL_OPTIONS:  Set general Brainstorm configuration.
% USAGE:  [bstPanelNew, panelName] = panel_options('CreatePanel')

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
% Authors: Francois Tadel, 2009-2014

macro_methodcall;
end


%% ===== CREATE PANEL =====
function [bstPanelNew, panelName] = CreatePanel() %#ok<DEFNU>
    % Java initializations
    import java.awt.*;
    import javax.swing.*;   
    % Constants
    panelName = 'Preferences';
    
    % Create main main panel
    jPanelNew = gui_river();
    
    % ===== LEFT =====
    jPanelLeft = gui_river();
    jPanelNew.add(jPanelLeft);
    % ===== SYSTEM =====
    jPanelSystem = gui_river([5 2], [0 15 8 15], 'System');
        jCheckUpdates    = gui_component('CheckBox', jPanelSystem, 'br', 'Automatic updates', [], [], [], []);
        jCheckGfp        = gui_component('CheckBox', jPanelSystem, 'br', 'Display GFP over time series', [], [], [], []);
        jCheckForceComp  = gui_component('CheckBox', jPanelSystem, 'br', 'Force mat-files compression (slower)', [], [], [], []);
    jPanelLeft.add('hfill', jPanelSystem);
    % ===== OPEN GL =====
    jPanelOpengl = gui_river([5 2], [0 15 8 15], 'OpenGL rendering');
        jRadioOpenNone = gui_component('Radio', jPanelOpengl, '',   'OpenGL: Disabled (no transparency)', [], [], [], []);
        jRadioOpenSoft = gui_component('Radio', jPanelOpengl, 'br', 'OpenGL: Software (slow)', [], [], [], []);
        jRadioOpenHard = gui_component('Radio', jPanelOpengl, 'br', 'OpenGL: Hardware (accelerated)', [], [], [], []);
        % Group buttons
        jButtonGroup = ButtonGroup();
        jButtonGroup.add(jRadioOpenNone);
        jButtonGroup.add(jRadioOpenSoft);
        jButtonGroup.add(jRadioOpenHard);
        % On mac systems: opengl software is not supported
        if strncmp(computer,'MAC',3)
            jRadioOpenSoft.setEnabled(0);
        end
    jPanelLeft.add('br hfill', jPanelOpengl);
    % ===== OPEN GL BUGS=====
    jPanelOpengl = gui_river([5 2], [0 15 8 15], 'OpenGL bug workarounds');
        jCheckBugs.OpenGLEraseModeBug         = gui_component('CheckBox', jPanelOpengl, '',   'Erase mode bug',        [], 'Symptom: Time cursor and selection rectangle do not draw well (EraseMode=xor)', [], []);  % OpenGLEraseModeBug
        jCheckBugs.OpenGLBitmapZbufferBug     = gui_component('CheckBox', jPanelOpengl, 'br', 'Bitmap Zbuffer bug',    [], 'Symptom: Text with background color or displayed on image on patch objects is not visible.', [], []);  % OpenGLBitmapZbufferBug
        jCheckBugs.OpenGLWobbleTesselatorBug  = gui_component('CheckBox', jPanelOpengl, 'br', 'Wobble tesselator bug', [], 'Symptom: Rendering complex patch object causes segmentation violation.', [], []);  % OpenGLWobbleTesselatorBug 
        jCheckBugs.OpenGLLineSmoothingBug     = gui_component('CheckBox', jPanelOpengl, 'br', 'Line smoothing bug',    [], 'Symptom: Lines with a LineWidth greater than 3 look bad.', [], []);  % OpenGLLineSmoothingBug
        jCheckBugs.OpenGLDockingBug           = gui_component('CheckBox', jPanelOpengl, 'br', 'Docking bug',           [], 'Symptom: MATLAB crashes when you dock a figure.', [], []);  % OpenGLDockingBug
        jCheckBugs.OpenGLClippedImageBug      = gui_component('CheckBox', jPanelOpengl, 'br', 'Clipped image bug',     [], 'Symptom: Images and colorbar do not display.', [], []);  % OpenGLClippedImageBug
    jPanelLeft.add('br hfill', jPanelOpengl);

    % ===== RIGHT =====
    jPanelRight = gui_river();
    jPanelNew.add(jPanelRight);   
    % ===== DATA IMPORT =====
    jPanelImport = gui_river([5 5], [0 15 15 15], 'Data import');
        % Temporary directory
        gui_component('Label', jPanelImport, '', 'Temporary directory: ', [], [], [], []);
        jTextTempDir   = gui_component('Text', jPanelImport, 'br hfill', '', [], [], [], []);
        jButtonTempDir = gui_component('Button', jPanelImport, [], '...', [], [], @TempDirectory_Callback, []);
        jButtonTempDir.setMargin(Insets(2,2,2,2));
        jButtonTempDir.setFocusable(0);
        % Byte order
        gui_component('Label', jPanelImport, 'br', 'Byte order: ', [], [], [], []);
        jRadioByteBig    = gui_component('Radio', jPanelImport, [], 'Big endian', [], [], [], []);
        jRadioByteLittle = gui_component('Radio', jPanelImport, [], 'Little endian', [], [], [], []);
        % Group buttons
        jButtonGroup = ButtonGroup();
        jButtonGroup.add(jRadioByteBig);
        jButtonGroup.add(jRadioByteLittle);

    jPanelRight.add('br hfill', jPanelImport);
    
    % ===== SIGNAL PROCESSING =====
    jPanelSigProc = gui_river([5 5], [0 15 15 15], 'Signal processing');
        jCheckUseSigProc = gui_component('CheckBox', jPanelSigProc, 'br', 'Use Signal Processing Toolbox (Matlab)', [], 'If selected, some processes will use the Matlab''s Signal Processing Toolbox functions. Else, use only the basic Matlab function.', [], []);
                           gui_component('Label',    jPanelSigProc, 'br', '         Process data by blocks of:', [], [], [], []);
        jTextMaxSize     = gui_component('TextTime', jPanelSigProc, [], '', [], [], [], []);
                           gui_component('Label',    jPanelSigProc, [], ' Mb', [], [], [], []);
    jPanelRight.add('br hfill', jPanelSigProc);
    
    % ===== MAGNETIC INTERPOLATION =====
    jPanelMagInterp = gui_river([5 5], [0 15 15 15], 'Magnetic field extrapolation');
        % TEXT: Regularization parameter
        jPanelMagInterp.add(JLabel('Regularization parameter: '));
        jTextRegParam = JTextField();
        jTextRegParam.setPreferredSize(Dimension(70, 20));
        jTextRegParam.setToolTipText('Set the value of the regularization parameter for the magnetic extrapolaiton algorithm.');
        jTextRegParam.setHorizontalAlignment(JLabel.RIGHT);
        jPanelMagInterp.add(jTextRegParam);
        % CHECK: Force whitening
        jCheckForceWhite = JCheckBox('Force whitening');
        jCheckForceWhite.setToolTipText('<HTML>If enabled: always whitens MEG recordings before extrapolating them to a high-definition surface.<BR>If disabled: only whitens the combination gradiometers/magnetometers for Neuromag MEG.');
        jPanelMagInterp.add('br', jCheckForceWhite);
    jPanelRight.add('br hfill', jPanelMagInterp);
    
    % ===== RESET =====
    jPanelReset = gui_river([5 5], [0 15 15 15], 'Reset Brainstorm');
        gui_component('Label',  jPanelReset, [], 'Reset database and options to defaults: ', [], [], [], []);
        gui_component('Button', jPanelReset, [], 'Reset', [], [], @ButtonReset_Callback, []);
    jPanelRight.add('br hfill', jPanelReset);
    
    % ===== VALIDATION BUTTONS =====
    gui_component('Label', jPanelRight, 'br', ' ');
    gui_component('Button', jPanelRight, 'br right', 'Cancel', [], [], @ButtonCancel_Callback, []);
    gui_component('Button', jPanelRight, [],         'Save',   [], [], @ButtonSave_Callback,   []);

    % ===== LOAD OPTIONS =====
    LoadOptions();
    
    % ===== CREATE PANEL =====   
    bstPanelNew = BstPanel(panelName, ...
                           jPanelNew, ...
                           struct());
                              

%% =================================================================================
%  === CONTROLS CALLBACKS  =========================================================
%  =================================================================================
%% ===== LOAD OPTIONS =====
    function LoadOptions()
        % GUI
        jCheckForceComp.setSelected(bst_get('ForceMatCompression'));
        jCheckUpdates.setSelected(bst_get('AutoUpdates'));
        jCheckGfp.setSelected(bst_get('DisplayGFP'));
        switch bst_get('DisableOpenGL')
            case 0
                jRadioOpenHard.setSelected(1);
            case 1
                jRadioOpenNone.setSelected(1);
            case 2
                if strncmp(computer,'MAC',3)
                    jRadioOpenHard.setSelected(1);
                else
                    jRadioOpenSoft.setSelected(1);
                end
        end
        % Get current configuration
        OpenGLBugs = bst_get('OpenGLBugs');
        % Set up controls accordingly
        allBugs = fieldnames(jCheckBugs);
        for i = 1:length(allBugs)
            if (OpenGLBugs.(allBugs{i}) == -2)
                jCheckBugs.(allBugs{i}).setEnabled(0);
            elseif (OpenGLBugs.(allBugs{i}) == 1)
                jCheckBugs.(allBugs{i}).setSelected(1);
            end
        end
        
        % Byte order
        switch lower(bst_get('ByteOrder'))
            case 'l'
                jRadioByteLittle.setSelected(1);
            case 'b'
                jRadioByteBig.setSelected(1);
        end
        % Temporary directory
        jTextTempDir.setText(bst_get('BrainstormTmpDir'));       
        % Magnetic extrapolation
        MagneticExtrapOptions = bst_get('MagneticExtrapOptions');
        jTextRegParam.setText(sprintf('%.6f',MagneticExtrapOptions.EpsilonValue));
        jCheckForceWhite.setSelected(MagneticExtrapOptions.ForceWhitening);
        % Use signal processing toolbox
        isToolboxInstalled = (exist('fir2', 'file') > 0);
        jCheckUseSigProc.setEnabled(isToolboxInstalled);
        jCheckUseSigProc.setSelected(bst_get('UseSigProcToolbox'));
        % Max block size for processing
        ProcessOptions = bst_get('ProcessOptions');
        jTextMaxSize.setText(sprintf('%d', round(ProcessOptions.MaxBlockSize * 8 / 1024 / 1024)));
    end


%% ===== SAVE OPTIONS =====
    function SaveOptions()
        bst_progress('start', 'Brainstorm preferences', 'Applying preferences...');
        % ===== GUI =====
        bst_set('ForceMatCompression', jCheckForceComp.isSelected());
        bst_set('AutoUpdates', jCheckUpdates.isSelected());
        bst_set('DisplayGFP',  jCheckGfp.isSelected());
        % === OpenGL ===
        if jRadioOpenHard.isSelected()
            DisableOpenGL = 0;
        elseif jRadioOpenNone.isSelected()
            DisableOpenGL = 1;
        else
            DisableOpenGL = 2;
        end
        bst_set('DisableOpenGL', DisableOpenGL);
        
        % === OpenGL Bugs ===
        % Get current configuration
        OpenGLBugs = bst_get('OpenGLBugs');
        % Set up controls accordingly
        allBugs = fieldnames(jCheckBugs);
        for i = 1:length(allBugs)
            if jCheckBugs.(allBugs{i}).isSelected()
                OpenGLBugs.(allBugs{i}) = 1;
            else
                OpenGLBugs.(allBugs{i}) = -1;
            end
        end
        bst_set('OpenGLBugs', OpenGLBugs);
        % Apply changes
        StartOpenGL();
        
        % ===== DATA IMPORT =====
        % Byte order
        if jRadioByteLittle.isSelected()
            bst_set('ByteOrder', 'l');
        elseif jRadioByteBig.isSelected()
            bst_set('ByteOrder', 'b');
        end
        % Temporary directory
        oldTmpDir = bst_get('BrainstormTmpDir');
        newTmpDir = char(jTextTempDir.getText());
        if ~file_compare(oldTmpDir, newTmpDir)
            % If temp directory changed: create directory if it doesn't exist
            if file_exist(newTmpDir) || mkdir(newTmpDir)
                bst_set('BrainstormTmpDir', newTmpDir);
            else
                java_dialog('warning', 'Could not create temporary directory.');
            end
        end

        % ===== MAGNETIC EXTRAPOLATION =====
        MagneticExtrapOptions = bst_get('MagneticExtrapOptions');
        % Regularization parameter
        epsVal = str2double(char(jTextRegParam.getText()));
        if ~isnan(epsVal)
            MagneticExtrapOptions.EpsilonValue = epsVal;
        else
            java_dialog('warning', 'Regularization parameter is not valid.');
        end
        % Force Whitening
        MagneticExtrapOptions.ForceWhitening = jCheckForceWhite.isSelected();
        bst_set('MagneticExtrapOptions', MagneticExtrapOptions);
        
        % ===== SIGNAL PROCESSING =====
        % Use signal processing toolbox
        bst_set('UseSigProcToolbox', jCheckUseSigProc.isSelected());
        % Max size for processing block
        ProcessOptions = bst_get('ProcessOptions');
        maxsize = str2double(char(jTextMaxSize.getText()));
        if ~isnan(maxsize)
            ProcessOptions.MaxBlockSize = maxsize / 8 * 1024 * 1024;
        else
            java_dialog('warning', 'Maximum block size for signal processing is not valid.');
        end
        bst_set('ProcessOptions', ProcessOptions);
        bst_progress('stop');
    end


%% ===== SAVE OPTIONS =====
    function ButtonSave_Callback(varargin)
        % Save options
        SaveOptions()
        % Hide panel
        gui_hide(panelName);
    end

%% ===== CANCEL BUTTON =====
    function ButtonCancel_Callback(varargin)
        % Hide panel
        gui_hide(panelName);
    end


%% ===== TEMP DIRECTORY SELECTION =====
    % Callback for '...' button
    function TempDirectory_Callback(varargin)
        % Get the initial path
        initDir = bst_get('BrainstormTmpDir', 1);
        % Open 'Select directory' dialog
        tempDir = uigetdir(initDir, 'Select temporary directory.');
        % If no directory was selected : return without doing anything
        if (isempty(tempDir) || (tempDir(1) == 0))
            return
        end
        % Else : update control text
        jTextTempDir.setText(tempDir);
        % Focus main brainstorm figure
        jBstFrame = bst_get('BstFrame');
        jBstFrame.setVisible(1);
    end

end


%% ===== START OPENGL =====
function [isOpenGL, DisableOpenGL] = StartOpenGL()
    global GlobalOpenGLStatus;
    % Get configuration 
    DisableOpenGL = bst_get('DisableOpenGL');
    isOpenGL = 1;
    
    % ===== SET OPENGL =====
    % Define OpenGL options
    switch DisableOpenGL
        case 0
            if strncmp(computer,'MAC',3)
                OpenGLMode = 'autoselect';
            elseif isunix && ~isempty(GlobalOpenGLStatus)
                OpenGLMode = 'autoselect';
                disp('BST> Warning: You have to restart Matlab to switch between software and hardware OpenGL.');
            else
                OpenGLMode = 'hardware';
            end
            FigureRenderer = 'opengl';
        case 1
            OpenGLMode = 'neverselect';
            FigureRenderer = 'zbuffer';
        case 2
            if strncmp(computer,'MAC',3)
                OpenGLMode = 'autoselect';
            elseif isunix && ~isempty(GlobalOpenGLStatus)
                OpenGLMode = 'autoselect';
                disp('BST> Warning: You have to restart Matlab to switch between software and hardware OpenGL.');
            else
                OpenGLMode = 'software';
            end
            FigureRenderer = 'opengl';
    end
    % Start OpenGL
    try
        opengl(OpenGLMode);
    catch
        isOpenGL = 0;
    end
    % Check that OpenGL is running
    s = opengl('data');
    if isempty(s) || isempty(s.Version)
        isOpenGL = 0;
    end
    % If OpenGL is running: save status
    if isOpenGL
        GlobalOpenGLStatus = DisableOpenGL;
    else
        GlobalOpenGLStatus = -1;
    end
    
    % ===== ENABLE BUGS WORKAROUNDS =====
    % If OpenGL is selected: apply the bug workarounds
    if isOpenGL
        % Get current configuration
        OpenGLBugs = bst_get('OpenGLBugs');
        % Process all the bugs
        allBugs = fieldnames(OpenGLBugs);
        for i = 1:length(allBugs)
            switch (OpenGLBugs.(allBugs{i}))
                case 0,   opengl(allBugs{i}, 0);
                case 1,   opengl(allBugs{i}, 1);
                case -1,  opengl(allBugs{i}, -1); 
            end
        end
    end
    
    % ===== UPDATE FIGURES =====
    % Get all figures
    hFigAll = [findobj(0, '-depth', 1, 'Tag', '3DViz'), ...
               findobj(0, '-depth', 1, 'Tag', 'Topography'), ...
               findobj(0, '-depth', 1, 'Tag', 'MriViewer'), ...
               findobj(0, '-depth', 1, 'Tag', 'Timefreq'), ...
               findobj(0, '-depth', 1, 'Tag', 'Pac')];
    % Set figures renderers
    if ~isempty(hFigAll)
        set(hFigAll, 'Renderer', FigureRenderer);
    end
end


%% ===== BUTTON: RESET =====
function ButtonReset_Callback(varargin)
    % Ask user confirmation
    isConfirm = java_dialog('confirm', ...
        ['You are about to reinitialize your Brainstorm installation, this will:' 10 10 ...
         ' - Detach all the protocols from the database (without deleting any file)' 10 ...
         ' - Reset all the Brainstorm and processes preferences' 10 ...
         ' - Restart Brainstorm as if it was the first time on this computer' 10 10 ...
         'Reset Brainstorm now?' 10 10], ...
        'Reset Brainstorm');
    if ~isConfirm
        return;
    end
    % Close panel
    gui_hide('Preferences');
    % Reset and restart brainstorm
    brainstorm stop;
    brainstorm reset;
    brainstorm;
end



