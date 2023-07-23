function varargout = panel_inverse(varargin)
% PANEL_INVERSE: Inverse modeling GUI.
%
% USAGE:  bstPanelNew = panel_inverse('CreatePanel')

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


%% ===== CREATE PANEL =====
function [bstPanelNew, panelName] = CreatePanel(Modalities, isShared, HeadModelType) %#ok<DEFNU>
    panelName = 'InverseOptions';
    % Java initializations
    import java.awt.*;
    import javax.swing.*;
    % Constants
    global ALLOW_MEM ALLOW_TEST
    HFILLED_WIDTH  = 10;
    DEFAULT_HEIGHT = 20;
    % Initializations
    isFirstCombinationWarning = 1;
    
    % Create tool panel
    jPanelNew = java_create('javax.swing.JPanel');
    jPanelNew.setLayout(BoxLayout(jPanelNew, BoxLayout.Y_AXIS));
    jPanelNew.setBorder(BorderFactory.createEmptyBorder(12,12,12,12));
    
    % ==== COMMENT ====
    jPanelTitle = gui_river([1,1], [0,6,6,6]);
        jPanelTitle.add('br', JLabel('Comment:'));
        jTextComment = JTextField('');
        jTextComment.setPreferredSize(Dimension(HFILLED_WIDTH, DEFAULT_HEIGHT));
        jPanelTitle.add('hfill', jTextComment);
    jPanelNew.add(jPanelTitle);
    
    % ==== PANEL: METHOD ====
    jPanelMethod = gui_river([1,1], [0,6,6,6], 'Method');
        jButtonGroupMethod = ButtonGroup();
        % All MNE methods        
        jRadioWMNE   = gui_component('Radio', jPanelMethod, [], 'Minimum norm estimate (wMNE)', jButtonGroupMethod, '', @(h,ev)UpdatePanel(), []);
        jRadioDSPM   = gui_component('Radio', jPanelMethod, 'br', 'dSPM',                       jButtonGroupMethod, '', @(h,ev)UpdatePanel(), []);
        jRadioLoreta = gui_component('Radio', jPanelMethod, 'br', 'sLORETA',                    jButtonGroupMethod, '', @(h,ev)UpdatePanel(), []);
        jRadioWMNE.setSelected(1);
        % EXPERT MODE
        jRadioMosherGls  = gui_component('Radio', [], [], '[Test] Mosher GLS',      jButtonGroupMethod, '', @(h,ev)UpdatePanel(), []);
        jRadioMosherGlsr = gui_component('Radio', [], [], '[Test] Mosher GLS(Reg)', jButtonGroupMethod, '', @(h,ev)UpdatePanel(), []);
        jRadioMosherMNE  = gui_component('Radio', [], [], '[Test] Mosher MNE',      jButtonGroupMethod, '', @(h,ev)UpdatePanel(), []);
        jRadioLCMV = [];
        jRadioMEM = [];
        if strcmpi(HeadModelType, 'surface') && ~isShared
            % Beamformer & Tests John
            if ~isempty(ALLOW_TEST) && ALLOW_TEST
                jRadioLCMV  = gui_component('Radio', [], [], '[Unstable] Cortical LCMV Beamformer',   jButtonGroupMethod, '', @(h,ev)UpdatePanel(), []);
            end
            % BrainEntropy MEM
            if ~isempty(ALLOW_MEM) && ALLOW_MEM 
                jRadioMEM = gui_component('Radio', [], [], '[Experimental] BrainEntropy MEM', jButtonGroupMethod, '', @(h,ev)UpdatePanel(), []);
            end
        end
    % Add 'Method' panel to main panel
    jPanelNew.add(jPanelMethod);

    % ===== PANEL: DATA TYPE =====
    jPanelDataType = gui_river([1,1], [0,6,6,6], 'Sensors type');
        jCheckDataMeg = [];
        jCheckDataMegGradio = [];
        jCheckDataMegMagneto = [];
        jCheckDataEeg = [];
        jCheckDataEcog = [];
        jCheckDataSeeg = [];
        % === MEG ===
        if ismember('MEG', Modalities)
            jCheckDataMeg = JCheckBox('MEG');
            java_setcb(jCheckDataMeg, 'ActionPerformedCallback', @Modality_Callback);
            jPanelDataType.add('br', jCheckDataMeg);
        end
        % === MEG GRAD ===
        if ismember('MEG GRAD', Modalities)
            jCheckDataMegGradio = JCheckBox('MEG Gradiometers');
            java_setcb(jCheckDataMegGradio, 'ActionPerformedCallback', @Modality_Callback);
            jPanelDataType.add('br', jCheckDataMegGradio);
        end
        % === MEG GRAD ===
        if ismember('MEG MAG', Modalities)
            jCheckDataMegMagneto = JCheckBox('MEG Magnetometers');
            java_setcb(jCheckDataMegMagneto, 'ActionPerformedCallback', @Modality_Callback);
            jPanelDataType.add('br', jCheckDataMegMagneto);
        end
        % === EEG ===
        if ismember('EEG', Modalities)
            jCheckDataEeg = JCheckBox('EEG');
            java_setcb(jCheckDataEeg, 'ActionPerformedCallback', @Modality_Callback);
            jPanelDataType.add('br', jCheckDataEeg);
        end
        % === ECOG ===
        if ismember('ECOG', Modalities)
            jCheckDataEcog = JCheckBox('ECOG');
            java_setcb(jCheckDataEcog, 'ActionPerformedCallback', @Modality_Callback);
            jPanelDataType.add('br', jCheckDataEcog);
        end
        % === SEEG ===
        if ismember('SEEG', Modalities)
            jCheckDataSeeg = JCheckBox('SEEG');
            java_setcb(jCheckDataSeeg, 'ActionPerformedCallback', @Modality_Callback);
            jPanelDataType.add('br', jCheckDataSeeg);
        end
        % === SELECT DEFAULT ===
        if ismember('MEG', Modalities)
            jCheckDataMeg.setSelected(1);
        end
        if ismember('MEG GRAD', Modalities)
            jCheckDataMegGradio.setSelected(1);
        end
        if ismember('MEG MAG', Modalities)
            jCheckDataMegMagneto.setSelected(1);
        end
        if ismember('EEG', Modalities) && (length(Modalities) == 1)
            jCheckDataEeg.setSelected(1);
        end
        if ismember('ECOG', Modalities) && (length(Modalities) == 1)
            jCheckDataEcog.setSelected(1);
        end
        if ismember('SEEG', Modalities) && (length(Modalities) == 1)
            jCheckDataSeeg.setSelected(1);
        end
    % Add 'Data type' panel to main panel
    jPanelNew.add(jPanelDataType);
    
    
    % ===== PANEL: OUTPUT MODE =====
    jPanelOutputMode = gui_river([1,1], [0,6,6,6], 'Output mode');
        % Output format
        jButtonGroupOutput = ButtonGroup();
        % Kernel only
        jRadioOutputKernel = JRadioButton('Kernel only', 1);
        jRadioOutputKernel.setToolTipText('<HTML>Time independant computation.<BR>To get the sources estimations for a time frame, <BR> the kernel is applied to the recordings (matrix product).');
        jButtonGroupOutput.add(jRadioOutputKernel);
        jPanelOutputMode.add('tab', jRadioOutputKernel);
        % Full results
        jRadioOutputFull = JRadioButton('Full results (Kernel*Recordings)');
        jRadioOutputFull.setToolTipText('Compute sources for all the time samples.');
        jButtonGroupOutput.add(jRadioOutputFull);
        jPanelOutputMode.add('br tab', jRadioOutputFull);
    % Add 'Output mode' panel to main panel
    jPanelNew.add(jPanelOutputMode);

    % ===== VALIDATION BUTTONS =====
    jPanelValid = gui_river([1,1], [0,6,6,6]);
    % Expert/normal mode
    jButtonExpert = gui_component('Button', jPanelValid, [], 'Expert mode', [], [], @SwitchExpertMode_Callback, []);
    gui_component('label', jPanelValid, 'hfill', ' ');
    % Ok/Cancel
    gui_component('Button', jPanelValid, 'right', 'Cancel', [], [], @ButtonCancel_Callback, []);
    gui_component('Button', jPanelValid, [], 'Ok', [], [], @ButtonOk_Callback, []);
    jPanelNew.add(jPanelValid);


    % ===== PANEL CREATION =====
    % Update comments
    UpdatePanel(1);
    % Return a mutex to wait for panel close
    bst_mutex('create', panelName);
    % Create the BstPanel object that is returned by the function
    ctrl = struct(...
            'jPanelTop',           jPanelNew, ...
            'jTextComment', jTextComment, ...
            ... ==== METHOD PANEL ====
            'jRadioWMNE',          jRadioWMNE, ...
            'jRadioMosherGls',     jRadioMosherGls, ...
            'jRadioMosherGlsr',    jRadioMosherGlsr, ...
            'jRadioMosherMNE',     jRadioMosherMNE, ...
            'jRadioLoreta',        jRadioLoreta, ...
            'jRadioDSPM',          jRadioDSPM, ...
            'jRadioLCMV',          jRadioLCMV, ...
            'jRadioMEM',           jRadioMEM, ...
            ... ==== DATA TYPE PANEL ====
            'jPanelDataType',      jPanelDataType, ...
            'jCheckDataEeg',       jCheckDataEeg, ...
            'jCheckDataMeg',       jCheckDataMeg, ...
            'jCheckDataMegGradio', jCheckDataMegGradio, ...
            'jCheckDataMegMagneto',jCheckDataMegMagneto, ...
            'jCheckDataEcog',      jCheckDataEcog, ...
            'jCheckDataSeeg',      jCheckDataSeeg, ...
            ... ==== OUTPUT MODE PANEL =====
            'jPanelOutputMode',    jPanelOutputMode, ...
            'jRadioOutputFull',    jRadioOutputFull, ...
            'jRadioOutputKernel',  jRadioOutputKernel);
    % Create the BstPanel object that is returned by the function
    bstPanelNew = BstPanel(panelName, jPanelNew, ctrl);
    


%% =================================================================================
%  === LOCAL CALLBACKS  ============================================================
%  =================================================================================
    %% ===== BUTTON: CANCEL =====
    function ButtonCancel_Callback(varargin)
        % Close panel
        gui_hide(panelName);
    end

    %% ===== BUTTON: OK =====
    function ButtonOk_Callback(varargin)
        % Release mutex and keep the panel opened
        bst_mutex('release', panelName);
    end

    %% ===== MODALITY CALLBACK =====
    function Modality_Callback(hObject, event)
        % If only one checkbox: can't deselect it
        if (length(Modalities) == 1)
            event.getSource().setSelected(1);
        % Warning if both MEG and EEG are selected
        elseif isFirstCombinationWarning && ~isempty(jCheckDataEeg) && jCheckDataEeg.isSelected() && (...
                (~isempty(jCheckDataMeg) && jCheckDataMeg.isSelected()) || ...
                (~isempty(jCheckDataMegGradio) && jCheckDataMegGradio.isSelected()) || ...
                (~isempty(jCheckDataMegMagneto) && jCheckDataMegMagneto.isSelected()))
            java_dialog('warning', ['Warning: Brainstorm inverse models do not properly handle the combination of MEG and EEG yet.' 10 10 ...
                                       'For now, we recommend to compute separatly the sources for MEG and EEG.'], 'EEG/MEG combination');
            isFirstCombinationWarning = 0;
        end
        % Update comment
        UpdatePanel();
    end


    %% ===== SWITCH EXPERT MODE =====
    function SwitchExpertMode_Callback(varargin)
        % Toggle expert mode
        ExpertMode = bst_get('ExpertMode');
        bst_set('ExpertMode', ~ExpertMode);
        % Set value 
        jRadioWMNE.setSelected(1);
        % Update comment
        UpdatePanel(1);
        % Get old panel
        [bstPanelOld, iPanel] = bst_get('Panel', 'InverseOptions');
        container = get(bstPanelOld, 'container');
        jFrame = container.handle{1};
        % Re-pack frame
        jFrame.pack();
    end
    

    %% ===== UPDATE PANEL ======
    % USAGE:  UpdatePanel(isForced = 0)
    function UpdatePanel(isForced)
        % Default values
        if (nargin < 1) || isempty(isForced)
            isForced = 0;
        end
        % Expert mode / Normal mode
        if isForced
            ExpertMode = bst_get('ExpertMode');
            jPanelOutputMode.setVisible(ExpertMode);
            if ExpertMode
                jButtonExpert.setText('Normal mode');
                jPanelMethod.add('br', jRadioMosherGls);
                jPanelMethod.add('br', jRadioMosherGlsr);
                jPanelMethod.add('br', jRadioMosherMNE);
            else
                jButtonExpert.setText('Expert mode');
                jPanelMethod.remove(jRadioMosherGls);
                jPanelMethod.remove(jRadioMosherGlsr);
                jPanelMethod.remove(jRadioMosherMNE);
            end
            if ~isempty(jRadioLCMV)
                if ~ExpertMode
                    jPanelMethod.remove(jRadioLCMV);
                else
                    jPanelMethod.add('br', jRadioLCMV);
                end
            end
            if ~isempty(jRadioMEM)
                if ~ExpertMode
                    jPanelMethod.remove(jRadioMEM);
                else
                    jPanelMethod.add('br', jRadioMEM);
                end
            end
        end
        
        % Selected modalities
        selModalities = {};
        if ~isempty(jCheckDataMeg) && jCheckDataMeg.isSelected()
            selModalities{end+1} = 'MEG';
        end
        if ~isempty(jCheckDataMegGradio) && jCheckDataMegGradio.isSelected()
            selModalities{end+1} = 'MEG GRAD';
        end
        if ~isempty(jCheckDataMegMagneto) && jCheckDataMegMagneto.isSelected()
            selModalities{end+1} = 'MEG MAG';
        end
        if ~isempty(jCheckDataEeg) && jCheckDataEeg.isSelected()
            selModalities{end+1} = 'EEG';
        end
        if ~isempty(jCheckDataEcog) && jCheckDataEcog.isSelected()
            selModalities{end+1} = 'ECOG';
        end
        if ~isempty(jCheckDataSeeg) && jCheckDataSeeg.isSelected()
            selModalities{end+1} = 'SEEG';
        end
        % Method name
        if jRadioWMNE.isSelected()
            Comment = 'MN: ';
            allowKernel = 1;
        elseif jRadioDSPM.isSelected()
            Comment = 'dSPM: ';
            allowKernel = 1;
        elseif jRadioLoreta.isSelected()
            Comment = 'sLORETA: ';
            allowKernel = 1;
        elseif jRadioMosherGls.isSelected() 
            Comment = 'GLS: ';
            allowKernel = 1;
        elseif jRadioMosherGlsr.isSelected() 
            Comment = 'GLS(Reg): ';
            allowKernel = 1;
        elseif jRadioMosherMNE.isSelected() 
            Comment = 'MNE(JCM): ';
            allowKernel = 1;
        elseif ~isempty(jRadioLCMV) && jRadioLCMV.isSelected()
            Comment = 'LCMV: ';
            allowKernel = 0;
            jRadioLCMV.setEnabled(~isShared);
        elseif ~isempty(jRadioMEM) && jRadioMEM.isSelected()
            Comment = 'MEM: ';
            allowKernel = 0;
            jRadioMEM.setEnabled(~isShared);
        else
            return
        end
        % Add modality comment
        Comment = [Comment, GetModalityComment(selModalities)];
        % Update comment field
        jTextComment.setText(Comment);

        % ===== OUTPUT MODE =====
        % If the user can select output type
        if ~isempty(jRadioOutputFull)
            % If no data defined: Only Kernel
            jRadioOutputFull.setEnabled(~isShared);
            % If method does not allow kernel: Full only
            jRadioOutputKernel.setEnabled(allowKernel);
            % Select the best available option
            if allowKernel
                jRadioOutputKernel.setSelected(1);
            elseif ~isShared
                jRadioOutputFull.setSelected(1);
            end
        end
    end
end


%% =================================================================================
%  === EXTERNAL CALLBACKS  =========================================================
%  =================================================================================
%% ===== GET PANEL CONTENTS =====
function s = GetPanelContents() %#ok<DEFNU>
    % Get panel controls handles
    ctrl = bst_get('PanelControls', 'InverseOptions');
    if isempty(ctrl)
        s = [];
        return; 
    end
    % Comment
    s.Comment = char(ctrl.jTextComment.getText());
    % Get selected method
    if ctrl.jRadioWMNE.isSelected()
        s.InverseMethod = 'wmne';
    elseif ctrl.jRadioDSPM.isSelected()
        s.InverseMethod = 'dspm';
    elseif ctrl.jRadioLoreta.isSelected()
        s.InverseMethod = 'sloreta';
    elseif ctrl.jRadioMosherGls.isSelected()
        s.InverseMethod = 'gls';
    elseif ctrl.jRadioMosherGlsr.isSelected()
        s.InverseMethod = 'glsr';
    elseif ctrl.jRadioMosherMNE.isSelected()
        s.InverseMethod = 'mnej';
    elseif ~isempty(ctrl.jRadioLCMV) && ctrl.jRadioLCMV.isSelected()
        s.InverseMethod = 'lcmvbf';
    elseif ~isempty(ctrl.jRadioMEM) && ctrl.jRadioMEM.isSelected()
        s.InverseMethod = 'mem';
    end
    % Selected modalities
    s.DataTypes = {};
    if ~isempty(ctrl.jCheckDataMeg) && ctrl.jCheckDataMeg.isSelected()
        s.DataTypes{end+1} = 'MEG';
    end
    if ~isempty(ctrl.jCheckDataMegGradio) && ctrl.jCheckDataMegGradio.isSelected()
        s.DataTypes{end+1} = 'MEG GRAD';
    end
    if ~isempty(ctrl.jCheckDataMegMagneto) && ctrl.jCheckDataMegMagneto.isSelected()
        s.DataTypes{end+1} = 'MEG MAG';
    end
    if ~isempty(ctrl.jCheckDataEeg) && ctrl.jCheckDataEeg.isSelected()
        s.DataTypes{end+1} = 'EEG';
    end
    if ~isempty(ctrl.jCheckDataEcog) && ctrl.jCheckDataEcog.isSelected()
        s.DataTypes{end+1} = 'ECOG';
    end
    if ~isempty(ctrl.jCheckDataSeeg) && ctrl.jCheckDataSeeg.isSelected()
        s.DataTypes{end+1} = 'SEEG';
    end
    % Output mode
    if ctrl.jPanelOutputMode.isVisible() && ctrl.jRadioOutputFull.isSelected()
        s.ComputeKernel = 0;
    else
        s.ComputeKernel = 1;
    end
end


%% ===== GET MODALITY COMMENT =====
function Comment = GetModalityComment(Modalities)
    % Replace "MEG GRAD+MEG MAG" with "MEG ALL"
    if all(ismember({'MEG GRAD', 'MEG MAG'}, Modalities))
        Modalities = setdiff(Modalities, {'MEG GRAD', 'MEG MAG'});
        Modalities{end+1} = 'MEG ALL';
    end
    % Loop to build comment
    Comment = '';
    for im = 1:length(Modalities)
        if (im >= 2)
            Comment = [Comment, '+'];
        end
        Comment = [Comment, Modalities{im}];
    end    
end


%% ===== COMPUTE INVERSE SOLUTION =====
function [OutputFiles, errMessage] = ComputeInverse(iStudies, iDatas, OPTIONS) %#ok<DEFNU>
    % Initialize returned variables
    OutputFiles = {};
    errMessage = [];
    % Parse inputs
    if (nargin < 3) || isempty(OPTIONS)
        % Default options
        OPTIONS = bst_sourceimaging();
    end
    
    % ===== GET INPUT INFORMATION =====
    isShared = isempty(iDatas);
    % Get all the study structures
    sStudies = bst_get('Study', unique(iStudies));
    % Get channel studies
    if isShared
        sChanStudies = sStudies;
    else
        [tmp, iChanStudies] = bst_get('ChannelForStudy', unique(iStudies));
        sChanStudies = bst_get('Study', iChanStudies);
    end
    % Check that there are channel files available
    if any(cellfun(@isempty, {sChanStudies.Channel}))
        errMessage = 'No channel file available.';
        return;
    end
    % Check head model
    if any(cellfun(@isempty, {sChanStudies.HeadModel}))
        errMessage = 'No head model available.';
        return;
    end
    % Check noise covariance
    if any(cellfun(@isempty, {sChanStudies.NoiseCov}))
        errMessage = 'No noise covariance matrix available.';
        return;
    end
    % Loop through all the channel files to find the available modalities and head model types
    AllMod = {};
    HeadModelType = 'surface';
    MEGMethod = [];
    for i = 1:length(sChanStudies)
        AllMod = union(AllMod, sChanStudies(i).Channel.DisplayableSensorTypes);
        if isempty(sChanStudies(i).HeadModel(sChanStudies(i).iHeadModel).MEGMethod)
            AllMod = setdiff(AllMod, {'MEG GRAD','MEG MAG','MEG'});
        end
        if isempty(sChanStudies(i).HeadModel(sChanStudies(i).iHeadModel).EEGMethod)
            AllMod = setdiff(AllMod, {'EEG'});
        end
        if isempty(sChanStudies(i).HeadModel(sChanStudies(i).iHeadModel).ECOGMethod)
            AllMod = setdiff(AllMod, {'ECOG'});
        end
        if isempty(sChanStudies(i).HeadModel(sChanStudies(i).iHeadModel).SEEGMethod)
            AllMod = setdiff(AllMod, {'SEEG'});
        end
        if ~strcmpi(sChanStudies(i).HeadModel(sChanStudies(i).iHeadModel).HeadModelType, 'surface')
            HeadModelType = sChanStudies(i).HeadModel(sChanStudies(i).iHeadModel).HeadModelType;
        end
        if ~isempty(sChanStudies(i).HeadModel(sChanStudies(i).iHeadModel).MEGMethod) && isempty(MEGMethod)
            MEGMethod = sChanStudies(i).HeadModel(sChanStudies(i).iHeadModel).MEGMethod;
        end
    end
    % 
    % Keep only MEG and EEG
    if any(ismember(AllMod, {'MEG GRAD','MEG MAG'}))
        AllMod = intersect(AllMod, {'MEG GRAD', 'MEG MAG', 'EEG', 'ECOG', 'SEEG'});
    else
        AllMod = intersect(AllMod, {'MEG', 'EEG', 'ECOG', 'SEEG'});
    end
    % Check that at least one modality is available
    if isempty(AllMod)
        errMessage = 'No valid sensor types to estimate sources: please calculate an appropriate headmodel.';
        return;
    end

    % ===== SELECT INVERSE METHOD =====
    % Select method
    if OPTIONS.DisplayMessages
        % Options dialog window
        sMethod = gui_show_dialog('Compute sources', @panel_inverse, 1, [], AllMod, isShared, HeadModelType);
        if isempty(sMethod)
            return;
        end
        % Override default options
        OPTIONS = struct_copy_fields(OPTIONS, sMethod, 1);
    end
    % If no MEG and no EEG selected
    if isempty(OPTIONS.DataTypes)
        errMessage = 'Please select at least one modality.';
        return;
    end

    % ===== METHOD OPTIONS =====
    if OPTIONS.DisplayMessages
        switch (OPTIONS.InverseMethod)
            % === MINIMUM NORM ===
            case {'wmne','dspm','sloreta','gls','glsr','mnej'}
                % Default options
                MethodOptions = bst_wmne();
                MethodOptions.InverseMethod = OPTIONS.InverseMethod;
                % Remove radial sources in MEG with spherical headmodels ?
                RemoveSilentComp = any(ismember(AllMod, {'MEG GRAD', 'MEG MAG', 'MEG'})) && strcmpi(MEGMethod, 'meg_sphere');
                % sLORETA and spherical models: Truncated source model must be the default
                if RemoveSilentComp && strcmpi(OPTIONS.InverseMethod, 'sloreta')
                    MethodOptions.flagSourceOrient = [1 0 0 2];
                % Else: All source models available
                else
                    MethodOptions.flagSourceOrient = [1 1 1 RemoveSilentComp];
                end
                % Default source model
                switch lower(MethodOptions.SourceOrient{1})
                    case 'fixed',  MethodOptions.flagSourceOrient(1) = 2;
                    case 'loose',  MethodOptions.flagSourceOrient(2) = 2;
                    case 'free',   MethodOptions.flagSourceOrient(3) = 2;
                end
                % Default options are different depending on the head model type
                switch (HeadModelType)
                    case {'surface', 'ImageGrid'}
                        MethodOptions.SourceOrient{1} = 'fixed';
                    case 'volume'
                        MethodOptions.SourceOrient{1} = 'free';
                        MethodOptions.flagSourceOrient = [0 0 2 0];
                    case 'dba'
                        MethodOptions.SourceOrient{1} = 'fixed';
                end
                % For sLORETA: no depth weighting
                if strcmpi(OPTIONS.InverseMethod, 'sloreta')
                    MethodOptions.depth = 0;
                end
                % Interface to edit options
                if bst_get('ExpertMode')
                    MethodOptions = gui_show_dialog('Minimum norm options', @panel_wmne, 1, [], MethodOptions, OPTIONS.DataTypes);
                end

            % === BEAMFORMER ===
            case 'lcmvbf'
                % No data files found
                if isShared
                    errMessage = 'Cannot compute shared kernels with this beamformer.';
                    return
                end
                % Interface to edit options
                MethodOptions = gui_show_dialog('Beamformer options', @panel_beamformer, 1, [], iStudies, iDatas);

            % === BRAINENTROPY MEM ===
            case 'mem'
                % No data files found
                if isShared
                    errMessage = 'Cannot compute shared kernels with this method.';
                    return
                end
                % Default options
                MethodOptions = be_main();
                % Interface to edit options
                MethodOptions = gui_show_dialog('MEM options', @panel_brainentropy, [], [], MethodOptions);
        end
        % Canceled by user
        if isempty(MethodOptions)
            return
        end
        % Add options to list
        OPTIONS = struct_copy_fields(OPTIONS, MethodOptions, 1);
    end

    % ===== COMMENT =====
    % Base comment: "METHOD: MODALITIES"
    if isempty(OPTIONS.Comment)
        switch (OPTIONS.InverseMethod)
            case 'wmne',      OPTIONS.Comment = 'MN';
            case 'dspm',      OPTIONS.Comment = 'dSPM';
            case 'sloreta',   OPTIONS.Comment = 'sLORETA';
            case 'gls',       OPTIONS.Comment = 'GLS';
            case 'glsr',      OPTIONS.Comment = 'GLS(Reg)';
            case 'mnej',      OPTIONS.Comment = 'MNE(JCM)';
            case 'lcmvbf',    OPTIONS.Comment = 'LCMV';
            case 'mem',       OPTIONS.Comment = 'MEM';
        end
        OPTIONS.Comment = [OPTIONS.Comment, ': ' GetModalityComment(OPTIONS.DataTypes)];
    end
    % Add source orientation option string
    strOptions = '';
    if any(strcmpi(OPTIONS.InverseMethod, {'wmne','dspm','sloreta','gls','glsr','mnej'}))
        switch (OPTIONS.SourceOrient{1})
            case 'fixed',      strOptions = 'Constr';
            case 'loose',      strOptions = 'Loose';
            case 'free',       strOptions = 'Unconstr';
            case 'truncated',  strOptions = 'Trunc';
        end
    end
    % Add Kernel/Full option string
    if ~OPTIONS.ComputeKernel
        if ~isempty(strOptions)
            strOptions = [',' strOptions];
        end
        strOptions = ['Full', strOptions];
    end
    % Final comment
    if ~isempty(strOptions)
        OPTIONS.Comment = [OPTIONS.Comment, '(', strOptions, ')'];
    end
    
    % ===== LOOP ON INPUT FILES =====
    % Initializations
    initOPTIONS = OPTIONS;
    isFirstWarnAvg = 1;
    % Display progress bar
    bst_progress('start', 'Compute sources', 'Initialize...', 0, length(iStudies) + 1);
    % Process each input
    for iEntry = 1:length(iStudies)
        OPTIONS = initOPTIONS;
        % ===== CHANNEL FILE & NOISE COVARIANCE =====
        bst_progress('text', 'Reading channel information...');
        % Get study structure
        iStudy = iStudies(iEntry);
        sStudy = bst_get('Study', iStudy);
        % Check if default study
        isDefaultStudy = strcmpi(sStudy.Name, bst_get('DirDefaultStudy'));
        % Get channel structure for study
        [sChannel, iStudyChannel] = bst_get('ChannelForStudy', iStudy);
        % Get study channel
        sStudyChannel = bst_get('Study', iStudyChannel);
        % Load NoiseCov file 
        NoiseCovMat = load(file_fullpath(sStudyChannel.NoiseCov.FileName), 'NoiseCov');
        % Options
        OPTIONS.ChannelFile   = sChannel.FileName;
        OPTIONS.NoiseCovRaw   = NoiseCovMat.NoiseCov;
        OPTIONS.HeadModelFile = sStudyChannel.HeadModel(sStudyChannel.iHeadModel).FileName;

        % ===== DATA FILES =====
        if ~isShared
            % Get only one file
            OPTIONS.DataFile = sStudy.Data(iDatas(iEntry)).FileName;
        else
            % Progress bar
            bst_progress('text', 'Getting bad channels...');
            % Get all the dependent data files
            [iRelatedStudies, iRelatedData] = bst_get('DataForStudy', iStudy);
            % List all the data files
            nAvgAll     = zeros(1,length(iRelatedStudies));
            BadChannels = [];
            nChannels   = [];
            for i = 1:length(iRelatedStudies)
                % Get data file
                sStudyRel = bst_get('Study', iRelatedStudies(i));
                DataFull = file_fullpath(sStudyRel.Data(iRelatedData(i)).FileName);
                % Read bad channels and nAvg
                DataMat = load(DataFull, 'ChannelFlag', 'nAvg');
                if isfield(DataMat, 'nAvg') && ~isempty(DataMat.nAvg)
                    nAvgAll(i) = DataMat.nAvg;
                else
                    nAvgAll(i) = 1;
                end
                % Count number of times the channe is bad
                if isempty(BadChannels)
                    BadChannels = double(DataMat.ChannelFlag < 0);
                else
                    BadChannels = BadChannels + (DataMat.ChannelFlag < 0);
                end
                % Channel number
                if isempty(nChannels)
                    nChannels = length(DataMat.ChannelFlag);
                elseif (nChannels ~= length(DataMat.ChannelFlag))
                    errMessage = 'All data files must have the same number of channels.';
                    continue;
                end
            end
            
            % === CHECK nAVG ===
            if ~isempty(iRelatedStudies) && any(nAvgAll ~= nAvgAll(1)) && isFirstWarnAvg
%                 % Display a warning in a dialog window
%                 if OPTIONS.DisplayMessages
%                     isConfirm = java_dialog('confirm', ...
%                         ['Warning: You should estimate separataley the sources for the averages and the single trials.', 10 ...
%                         'The level of noise in the files might be different, this may cause inaccurate results.' 10 10 ... 
%                         ' - For several averages: compute sources separately for each file.' 10 ...
%                         ' - For single trials: compute a shared solution, and move the averages in another condition.' 10 10 ...
%                         'Ignore this warning and compute sources ?'], 'Compute sources');
%                     if ~isConfirm
%                         return
%                     end
%                 % Return a warning message
%                 else
%                     errMessage = [errMessage 'Mixing averages and single trials. Result might be inaccurate.' 10];
%                 end
%                 isFirstWarnAvg = 0;
            end
            OPTIONS.nAvg = min(nAvgAll);
            
            % === BAD CHANNELS ===
            if any(BadChannels)
                % Display a warning in a dialog window
                if OPTIONS.DisplayMessages
                    % Build list of bad channels
                    strBad = '';
                    iBad = find(BadChannels);
                    for i = 1:length(iBad)
                        strBad = [strBad sprintf('%d(%d)   ', iBad(i), BadChannels(iBad(i)))];
                        if (mod(i,6) == 0)
                            strBad = [strBad 10];
                        end
                    end
                    % Ask user confirmation
                    res = java_dialog('input', ...
                        ['Some channels are bad in at least one file (total ' num2str(length(iRelatedStudies)) ' files): ' 10 ...
                         '(in parentheses, the number of files for which the channel is bad)' 10 10 ...
                         strBad 10 10 ...
                         'The following channels will be considered as BAD for' 10 ...
                         'all the recordings and excluded from the source estimation:' 10 10], ...
                        'Exclude bad channels', [], sprintf('%d ', iBad));
                    if ~isempty(res) && isempty(str2num(res))
                        errMessage = [];
                        continue
                    end
                    % Get bad channels
                    BadChannels = 0 * BadChannels;
                    if ~isempty(res)
                        iBad = str2num(res);
                        BadChannels(iBad) = 1;
                    end
                % Return a warning message
                else
                    errMessage = [errMessage 'Bad channels for all the trials: ' sprintf('%d ', find(BadChannels)) 10];
                end
            end
            % Build a resulting ChannelFlag
            OPTIONS.ChannelFlag = ones(nChannels, 1);
            OPTIONS.ChannelFlag(BadChannels > 0) = -1;
            OPTIONS.DataFile = '';
        end
        
        % ===== COMPUTE INVERSE SOLUTION =====
        bst_progress('text', 'Estimating sources...');
        bst_progress('inc', 1);
        % Call generic command line function
        [OPTIONS,Result] = bst_sourceimaging(OPTIONS);
        % An error occurred
        if isempty(Result)
            errMessage = [errMessage 'Unknown error, skipping file.' 10];
            continue;
        end
        % Create new results structure
        newResult = db_template('Results');
        newResult(1).Comment    = Result.Comment;
        newResult.FileName      = OPTIONS.ResultFile;
        newResult.DataFile      = OPTIONS.DataFile;
        newResult.isLink        = 0;
        newResult.HeadModelType = Result.HeadModelType;
        % Add new entry to the database
        iResult = length(sStudy.Result) + 1;
        sStudy.Result(iResult) = newResult;

        % Mosher's solutions: require the calculation of a second file
        if ismember(OPTIONS.InverseMethod, {'gls', 'glsr', 'mnej'})
            OPTIONS.ResultFile = [];
            % OPTIONS.Comment = strrep(OPTIONS.Comment, upper(OPTIONS.InverseMethod), [upper(OPTIONS.InverseMethod) '_P']);
            OPTIONS.Comment = [OPTIONS.Comment(1:3) '_P' OPTIONS.Comment(4:end)];
            OPTIONS.InverseMethod = [OPTIONS.InverseMethod, '_p'];
            [OPTIONS, Result] = bst_sourceimaging(OPTIONS);
            % Add new entry to the database
            iResult = length(sStudy.Result) + 1;
            newResult.Comment  = Result.Comment;
            newResult.FileName = OPTIONS.ResultFile;
            sStudy.Result(iResult) = newResult;
        end
        
        % Update Brainstorm database
        bst_set('Study', iStudy, sStudy);
        
        % ===== UPDATE DISPLAY =====
        % Update tree
        panel_protocols('UpdateNode', 'Study', iStudy);
        % Update links
        if isShared
            if isDefaultStudy
                % If added to a 'default_study' node: need to update results links 
                OutputLinks = db_links('Subject', sStudy.BrainStormSubject);
                % Update whole tree display
                panel_protocols('UpdateTree');
            else
                % Update links to the new results file 
                OutputLinks = db_links('Study', iStudy);
                % Update display of the study node
                panel_protocols('UpdateNode', 'Study', iStudy);
            end
            % Find in the links the ones that are based on the node that was just calculated
            isNewLink = ~cellfun(@(c)isempty(strfind(c, newResult.FileName)), OutputLinks);
            OutputFiles = cat(2, OutputFiles, OutputLinks(isNewLink));
        else
            % Store output filename
            OutputFiles{end+1} = newResult.FileName;
        end
        % Expand data node
        panel_protocols('SelectNode', [], newResult.FileName);
    end
    % Save database
    db_save();
    % Hide progress bar
    bst_progress('stop');
end




