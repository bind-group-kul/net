function varargout = panel_beamformer(varargin)
% PANEL_BEAMFORMER: Options for LCMV Beamformer (GUI).
% 
% USAGE:  bstPanelNew = panel_beamformer('CreatePanel')
%                   s = panel_beamformer('GetPanelContents')

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
function [bstPanelNew, panelName] = CreatePanel(iStudies, iDatas)  %#ok<DEFNU>  
    panelName = 'InverseOptionsBeamformer';
    % Java initializations
    import java.awt.*;
    import javax.swing.*;
    % Constants
    SPINNER_WIDTH  = 50;
    DEFAULT_HEIGHT = 20;
    TEXT_WIDTH     = 50;
    
    % Check if data available
    if isempty(iDatas)
        error('No data available.');
    end
    
    % ===== GET TIME DEFINITION =====
    % Get first study
    sStudy = bst_get('Study', iStudies(1));
    % Load time for first file
    DataMat = in_bst_data(sStudy.Data(iDatas(1)).FileName, 'Time');
    TimeVector = DataMat.Time;
    % Get default values for baseline
    if (TimeVector(1) < 0) && (TimeVector(end) > 0)
        BaselineBounds = [TimeVector(1), 0];
    else
        BaselineBounds = [TimeVector(1), TimeVector(2)];
    end
    
    % ===== CREATE PANEL =====
    % Create main main panel
    jPanelNew = gui_river([1 1], [5 10 5 10]);
    % Create parameters panel
    jPanelLcmv = gui_river([1,1], [5,10,5,10], 'LCMV Beamformer');
        % ===== TIKHONOV =====
        % Tikhonov regularization (Checkbox)
        jPanelLcmv.add(JLabel('Tikhonov regularization:'));
        % Tikhonov regularization (Spinner)
        spinmodel = SpinnerNumberModel(10, 1, 100, 1);
        jSpinnerTikhonov = JSpinner(spinmodel);  
        jSpinnerTikhonov.setPreferredSize(Dimension(SPINNER_WIDTH, DEFAULT_HEIGHT));
        jPanelLcmv.add(jSpinnerTikhonov);
        jPanelLcmv.add(JLabel('%'));
        % Separator
        jPanelLcmv.add('br', JLabel(' '));
        
        % ===== SOURCE ORIENTATION =====
        jLabelOrientTitle = JLabel('Source orientation:');
        jPanelLcmv.add('br', jLabelOrientTitle);
        jButtonGroupOrient = ButtonGroup();
        % Source orientation : Constrained (RadioButton)
        jRadioOrientConstr = JRadioButton('Constrained (Normal/surface)', 1);
        jButtonGroupOrient.add(jRadioOrientConstr);
        jPanelLcmv.add('br', JLabel('     '));
        jPanelLcmv.add(jRadioOrientConstr);
        % Source orientation : Unconstrained (RadioButton)
        jRadioOrientUnconstr = JRadioButton('Unconstrained');
        jButtonGroupOrient.add(jRadioOrientUnconstr);
        jPanelLcmv.add('br', JLabel('     '));
        jPanelLcmv.add(jRadioOrientUnconstr);
        % Separator
        jPanelLcmv.add('br', JLabel(' '));
        
        % ===== OUTPUT FORMAT =====
        jLabelOutputTitle = JLabel('Output format:');
        jPanelLcmv.add('br', jLabelOutputTitle);
        jButtonGroupOutput = ButtonGroup();
        jRadioOutputFilter     = JRadioButton('Filter output');
        jRadioOutputNormalized = JRadioButton('Normalized output', 1);
        jRadioOutputNeural     = JRadioButton('Neural indice');
        jRadioOutputPower      = JRadioButton('Source power');
        jButtonGroupOutput.add(jRadioOutputFilter);
        jButtonGroupOutput.add(jRadioOutputNormalized);    
        jButtonGroupOutput.add(jRadioOutputNeural);
        jButtonGroupOutput.add(jRadioOutputPower);
        java_setcb(jRadioOutputFilter,     'ActionPerformedCallback', @OutputFormat_Callback);
        java_setcb(jRadioOutputNormalized, 'ActionPerformedCallback', @OutputFormat_Callback);
        java_setcb(jRadioOutputNeural,     'ActionPerformedCallback', @OutputFormat_Callback);
        java_setcb(jRadioOutputPower,      'ActionPerformedCallback', @OutputFormat_Callback);

        jPanelLcmv.add('br', JLabel('     '));
        jPanelLcmv.add(jRadioOutputFilter);
        jPanelLcmv.add('br', JLabel('     '));
        jPanelLcmv.add(jRadioOutputNormalized);
        jPanelLcmv.add('br', JLabel('     '));
        jPanelLcmv.add(jRadioOutputNeural);
        jPanelLcmv.add('br', JLabel('     '));
        jPanelLcmv.add(jRadioOutputPower);
        % Separator
        jPanelLcmv.add('br', JLabel(' '));
        
        % ===== TIME SEGMENT =====
        % Noise Normalization : Baseline title
        jLabelTime = JLabel('Time window: ');
        jPanelLcmv.add('p', jLabelTime);
        % Noise Normalization : Baseline START
        jTextTimeStart = JTextField('');
        jTextTimeStart.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTextTimeStart.setHorizontalAlignment(JTextField.RIGHT);
        jPanelLcmv.add('tab', jTextTimeStart);
        % Noise Normalization : Baseline STOP
        jPanelLcmv.add(JLabel('-'));
        jTextTimeStop = JTextField('');
        jTextTimeStop.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTextTimeStop.setHorizontalAlignment(JTextField.RIGHT);
        jPanelLcmv.add(jTextTimeStop);
        
        % Set time controls callbacks
        TimeUnit = gui_validate_text(jTextTimeStart, [], jTextTimeStop, TimeVector, 'time', [], TimeVector(1),   []);
        TimeUnit = gui_validate_text(jTextTimeStop, jTextTimeStart, [], TimeVector, 'time', [], TimeVector(end), []);
        % Display time unit
        jLabelTimeUnit = JLabel(TimeUnit);
        jPanelLcmv.add(jLabelTimeUnit);
            
        % ===== BASELINE =====
        % Noise Normalization : Baseline title
        jLabelBaseline = JLabel('Baseline: ');
        jPanelLcmv.add('p', jLabelBaseline);
        % Noise Normalization : Baseline START
        jTextBaselineStart = JTextField('');
        jTextBaselineStart.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTextBaselineStart.setHorizontalAlignment(JTextField.RIGHT);
        jPanelLcmv.add('tab', jTextBaselineStart);
        % Noise Normalization : Baseline STOP
        jPanelLcmv.add(JLabel('-'));
        jTextBaselineStop = JTextField('');
        jTextBaselineStop.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTextBaselineStop.setHorizontalAlignment(JTextField.RIGHT);
        jPanelLcmv.add(jTextBaselineStop);
        
        % Set time controls callbacks
        gui_validate_text(jTextBaselineStart, [], jTextBaselineStop, TimeVector, TimeUnit, [], BaselineBounds(1),   []);
        gui_validate_text(jTextBaselineStop, jTextBaselineStart, [], TimeVector, TimeUnit, [], BaselineBounds(end), []);
        % Display time unit
        jLabelBaselineUnit = JLabel(TimeUnit);
        jPanelLcmv.add(jLabelBaselineUnit);
        % Separator
        jPanelLcmv.add('br', JLabel(' '));
    % Add 'Method' panel to main panel (jPanelNew)
    jPanelNew.add('hfill', jPanelLcmv);
        
        
    % ===== VALIDATION BUTTONS =====
    % Cancel
    jButtonCancel = JButton('Cancel');
    java_setcb(jButtonCancel, 'ActionPerformedCallback', @ButtonCancel_Callback);
    jPanelNew.add('br right', jButtonCancel);
    % Run
    jButtonRun = JButton('OK');
    java_setcb(jButtonRun, 'ActionPerformedCallback', @ButtonOk_Callback);
    jPanelNew.add(jButtonRun);
    
    % ===== PANEL CREATION =====
    % Return a mutex to wait for panel close
    bst_mutex('create', panelName);
    
    % Controls list
    ctrl = struct('jLabelBaseline',         jLabelBaseline, ...
                  'jTextTimeStart',         jTextTimeStart, ...
                  'jTextTimeStop',          jTextTimeStop, ...
                  'jTextBaselineStart',     jTextBaselineStart, ...
                  'jTextBaselineStop',      jTextBaselineStop, ...
                  'jLabelTimeUnit',         jLabelTimeUnit, ...
                  'jSpinnerTikhonov',       jSpinnerTikhonov, ...
                  'jRadioOrientConstr',     jRadioOrientConstr, ...
                  'jRadioOrientUnconstr',   jRadioOrientUnconstr, ...
                  'jRadioOutputFilter',     jRadioOutputFilter, ...
                  'jRadioOutputNormalized', jRadioOutputNormalized, ...
                  'jRadioOutputNeural',     jRadioOutputNeural, ...
                  'jRadioOutputPower',      jRadioOutputPower);
              
    % Create the BstPanel object that is returned by the function
    % => constructor BstPanel(jHandle, panelName, sControls)
    bstPanelNew = BstPanel(panelName, jPanelNew, ctrl);



%% =================================================================================
%  === INTERNAL CALLBACKS ==========================================================
%  =================================================================================
%% ===== CANCEL BUTTON =====
    function ButtonCancel_Callback(hObject, event)
        % Close panel without saving (release mutex automatically)
        gui_hide(panelName);
    end

%% ===== OK BUTTON =====
    function ButtonOk_Callback(varargin)
        % Release mutex and keep the panel opened
        bst_mutex('release', panelName);
    end


%% ===== OUTPUT FORMAT =====
    function OutputFormat_Callback(varargin)
        NNormalization = jRadioOutputNormalized.isSelected() || ctrl.jRadioOutputNeural.isSelected();
        % If noise normalization is ON (NormalizedOutput or NeuralIndex)
        jLabelBaseline.setEnabled(NNormalization);
        jTextBaselineStart.setEnabled(NNormalization);
        jTextBaselineStop.setEnabled(NNormalization);     
    end
end



%% =================================================================================
%  === EXTERNAL CALLBACKS ==========================================================
%  =================================================================================   
%% ===== GET PANEL CONTENTS =====
function s = GetPanelContents() %#ok<DEFNU>
    % Get panel controls
    ctrl = bst_get('PanelControls', 'InverseOptionsBeamformer');
    % Get time unit
    TimeUnit = char(ctrl.jLabelTimeUnit.getText());
    switch TimeUnit
        case 's'
            Multiplicator = 1;
        case 'ms'
            Multiplicator = 1e-3;
    end
    % Get time bounds
    s.TimeSegment = [getValue(ctrl.jTextTimeStart), getValue(ctrl.jTextTimeStop)] .* Multiplicator;
    % Get baseline bounds
    if ctrl.jTextBaselineStart.isEnabled()
        s.BaselineSegment = [getValue(ctrl.jTextBaselineStart), getValue(ctrl.jTextBaselineStop)] .* Multiplicator;
    end
    
    % ===== GET OPTIONS =====   
    % Get options values
    if ctrl.jRadioOutputFilter.isSelected()
        s.OutputFormat = 0;
    elseif ctrl.jRadioOutputNormalized.isSelected()
        s.OutputFormat = 2;
    elseif ctrl.jRadioOutputNeural.isSelected()
        s.OutputFormat = 1;
    elseif ctrl.jRadioOutputPower.isSelected()
        s.OutputFormat = 3;
    end
    s.Tikhonov        = ctrl.jSpinnerTikhonov.getValue();
    s.isConstrained   = ctrl.jRadioOrientConstr.isSelected();
    % Computation type
    switch (s.OutputFormat)
        case 0, s.strOptions = 'Filter';
        case 2, s.strOptions = 'Norm';
        case 1, s.strOptions = 'Neural';
        case 3, s.strOptions = 'Power';
    end
    % Unconstrained
    if ~s.isConstrained
        s.strOptions = ['Unconstr' s.strOptions];
    end
end


%% ===== GET VALUES =====
function val = getValue(jText)
    % Get and check value
    val = str2double(char(jText.getText()));
    if isnan(val) || isempty(val)
        val = [];
    end
end

