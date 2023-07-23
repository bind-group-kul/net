function varargout = panel_noisecov(varargin)
% PANEL_NOISECOV: Options for noise covariance computation.
% 
% USAGE:  bstPanelNew = panel_noisecov('CreatePanel')
%                   s = panel_noisecov('GetPanelContents')

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

macro_methodcall;
end


%% ===== CREATE PANEL =====
function [bstPanelNew, panelName] = CreatePanel(OPTIONS)  %#ok<DEFNU>  
    % ===== PARSE INPUTS =====
    % OPTIONS:
    %    - nFiles     : Number of files to compute the noise covariance matrix
    %    - timeWindow : Maximum time window over all the files
    %    - freq       : Sampling frequency for all the files (NaN if differs between files) 
    % Time window string
    timeWindow = [min(OPTIONS.timeSamples), max(OPTIONS.timeSamples)];
    if (max(abs(timeWindow)) > 2)
        strTime = sprintf('[%1.4f, %1.4f] s', timeWindow(1), timeWindow(2));
    else
        strTime = sprintf('[%1.2f, %1.2f] ms', timeWindow(1) .* 1000, timeWindow(2) .* 1000);
    end
    % Frequency string
    if isnan(OPTIONS.freq)
        strFreq = 'Different values';
    else
        strFreq = sprintf('%d Hz', round(OPTIONS.freq));
    end
    % Default baseline
    if (timeWindow(1) < 0) && (timeWindow(2) > 0)
        defBaseline = [timeWindow(1), -1/OPTIONS.freq];
    else
        defBaseline = timeWindow;
    end
    % Diagonal matrix by default if not enough samples
    n = OPTIONS.nChannels;
    isDefaultDiag = (length(OPTIONS.timeSamples) < n*(n+1)/2);
    if isDefaultDiag
        strFullRecomm = '';
        strDiagRecomm = '  (recommended)';
    else
        strFullRecomm = '  (recommended)';
        strDiagRecomm = '';
    end
    
    % ===== CREATE GUI =====
    panelName = 'NoiseCovOptions';
    % Java initializations
    import java.awt.*;
    import javax.swing.*;
    % Constants
    TEXT_WIDTH     = 70;
    DEFAULT_HEIGHT = 20;
    jFontText = bst_get('Font', 11);
    % Create main main panel
    jPanelNew = gui_river();
    
    % FILES PANEL
    jPanelFiles = gui_river([5,5], [0,10,15,0], 'Files');
        % Number of files
        jPanelFiles.add(JLabel('Number of files :   '));
        jPanelFiles.add('tab', JLabel(sprintf('%d', OPTIONS.nFiles)));
        % Number of samples
        jPanelFiles.add('br',  JLabel('Number of samples : '));
        jLabelNumSamples = JLabel('0');
        jPanelFiles.add('tab', jLabelNumSamples);
        % Time window
        jPanelFiles.add('br',  JLabel('Time window : '));
        jPanelFiles.add('tab', JLabel(strTime));
        % Frequency
        jPanelFiles.add('br',  JLabel('Frequency : '));
        jPanelFiles.add('tab', JLabel(strFreq));
    jPanelNew.add('hfill', jPanelFiles);

    % OPTIONS PANEL
    jPanelOptions = gui_river([5,2], [0,10,15,0], 'Options');
        % Baseline title
        jPanelOptions.add(JLabel('Baseline: '));
        % Baseline START
        jTextTimeStart = JTextField('');
        jTextTimeStart.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTextTimeStart.setHorizontalAlignment(JTextField.RIGHT);
        jTextTimeStart.setFont(jFontText);
        jPanelOptions.add('tab', jTextTimeStart);
        % Baseline STOP
        jPanelOptions.add(JLabel('-'));
        jTextTimeStop = JTextField('');
        jTextTimeStop.setPreferredSize(Dimension(TEXT_WIDTH, DEFAULT_HEIGHT));
        jTextTimeStop.setHorizontalAlignment(JTextField.RIGHT);
        jTextTimeStop.setFont(jFontText);
        jPanelOptions.add(jTextTimeStop);
        % Define validation callbacks
        TimeUnit = gui_validate_text(jTextTimeStart, [], jTextTimeStop, unique(OPTIONS.timeSamples), 'time', [], defBaseline(1), @UpdatePanel);
        TimeUnit = gui_validate_text(jTextTimeStop, jTextTimeStart, [], unique(OPTIONS.timeSamples), 'time', [], defBaseline(2), @UpdatePanel);
        % Time units
        jPanelOptions.add(JLabel(TimeUnit));
        jPanelOptions.add('br', JLabel('    '));
        
        % Remove DC offset
        jLabelRemoveDc = JLabel('Remove DC offset: ');
        jPanelOptions.add('p', jLabelRemoveDc);
        jButtonGroupRemove = ButtonGroup();
        % Output type: Full matrix
        jPanelOptions.add('br', JLabel('    '));
        jRadioRemoveDcFile = JRadioButton('Block by block, to avoid effects of slow shifts in data', 1);
        jButtonGroupRemove.add(jRadioRemoveDcFile);
        jPanelOptions.add(jRadioRemoveDcFile);
        % Output type: Diagonal matrix
        jPanelOptions.add('br', JLabel('    '));
        jRadioRemoveDcAll = JRadioButton('Compute global average and remove it to from all the blocks');
        jButtonGroupRemove.add(jRadioRemoveDcAll);
        jPanelOptions.add(jRadioRemoveDcAll);
        % Disable these controls if only one file
        if (OPTIONS.nFiles == 1)
            jRadioRemoveDcAll.setEnabled(0);
        end
        
        % Output type
        jPanelOptions.add('p', JLabel('Output: '));
        jButtonGroupOutput = ButtonGroup();
        % Output type: Full matrix
        jPanelOptions.add('br', JLabel('    '));
        jRadioFull = JRadioButton(['Full noise covariance matrix' strFullRecomm], ~isDefaultDiag);
        jButtonGroupOutput.add(jRadioFull);
        jPanelOptions.add(jRadioFull);
        % Output type: Diagonal matrix
        jPanelOptions.add('br', JLabel('    '));
        jRadioDiag = JRadioButton(['Diagonal matrix' strDiagRecomm], isDefaultDiag);
        jButtonGroupOutput.add(jRadioDiag);
        jPanelOptions.add(jRadioDiag);
    jPanelNew.add('br hfill', jPanelOptions);
        
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
    ctrl = struct('jTextTimeStart',     jTextTimeStart, ...
                  'jTextTimeStop',      jTextTimeStop, ...
                  'TimeUnit',           TimeUnit, ...
                  'jRadioRemoveDcFile', jRadioRemoveDcFile, ...
                  'jRadioRemoveDcAll',  jRadioRemoveDcAll, ...
                  'jRadioFull',         jRadioFull, ...
                  'jRadioDiag',         jRadioDiag);
    % Create the BstPanel object that is returned by the function
    % => constructor BstPanel(jHandle, panelName, sControls)
    bstPanelNew = BstPanel(panelName, jPanelNew, ctrl);
    
    UpdatePanel();
    
    
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

%% ===== UPDATE PANEL =====
    function UpdatePanel(varargin)
        % Get baseline
        start = str2num(char(jTextTimeStart.getText()));
        stop = str2num(char(jTextTimeStop.getText()));
        % Apply time units
        if strcmpi(TimeUnit, 'ms')
            start = start / 1000;
            stop = stop / 1000;
        end
        % Compute number of samples for all the baselines grouped
        iTime = panel_time('GetTimeIndices', OPTIONS.timeSamples, [start, stop]);
        % Add the multiple times at the beginning and end
        iTime = union(iTime, find(OPTIONS.timeSamples(iTime(1)) == OPTIONS.timeSamples));
        iTime = union(iTime, find(OPTIONS.timeSamples(iTime(end)) == OPTIONS.timeSamples));
        % Update number of samples in GUI
        jLabelNumSamples.setText(sprintf('%d', length(iTime)));
    end
end


%% =================================================================================
%  === EXTERNAL CALLBACKS ==========================================================
%  =================================================================================   
%% ===== GET PANEL CONTENTS =====
function s = GetPanelContents() %#ok<DEFNU>
    % Get panel controls
    ctrl = bst_get('PanelControls', 'NoiseCovOptions');
    % Default options
    s = bst_noisecov();
    % Get baseline time window
    s.Baseline = [str2double(char(ctrl.jTextTimeStart.getText())), ...
                  str2double(char(ctrl.jTextTimeStop.getText()))];
    % Convert time values in seconds
    if strcmpi(ctrl.TimeUnit, 'ms')
        s.Baseline = s.Baseline ./ 1000;
    end
    % Get average computation mode
    if ctrl.jRadioRemoveDcFile.isSelected()
        s.RemoveDcOffset = 'File';
    elseif ctrl.jRadioRemoveDcAll.isSelected()
        s.RemoveDcOffset = 'All';
    end
    % Get output type: full or diagonal
    if ctrl.jRadioFull.isSelected()
        s.NoiseCovMethod = 'Full';
    elseif ctrl.jRadioDiag.isSelected()
        s.NoiseCovMethod = 'Diag';
    end
end



