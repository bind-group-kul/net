function varargout = panel_stat(varargin)
% PANEL_STAT: Create a panel for online statistical thresholding.
% 
% USAGE:  bstPanelNew = panel_stat('CreatePanel')
%                       panel_stat('UpdatePanel')

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
% Authors: Francois Tadel, 2010-2014

macro_methodcall;
end


%% ===== CREATE PANEL =====
function bstPanelNew = CreatePanel() %#ok<DEFNU>
    panelName = 'Stat';
    % Java initializations
    import java.awt.*;
    import javax.swing.*;

    % Create tools panel
    jPanelNew = gui_river([0 4], [7 9 7 7]);

    % ===== THRESHOLDING =====
    jPanelThresh = gui_river([4,1], [2,8,4,0], 'Thresholding');
        % Threshold p-value: Title
        gui_component('Label', jPanelThresh, [], 'p-value threshold: ');
        % Threshold p-value: Value
        jTextPThresh = gui_component('Text', jPanelThresh, [], '');
        jTextPThresh.setHorizontalAlignment(JLabel.RIGHT);
        jTextPThresh.setPreferredSize(Dimension(60,23));
        java_setcb(jTextPThresh, 'ActionPerformedCallback', @(h,ev)SaveOptions(1), ...
                                 'FocusLostCallback',       @(h,ev)SaveOptions(0));
    jPanelNew.add('hfill', jPanelThresh);
        
    % ===== OPTIONS =====
    jPanelOptions = gui_river([4,2], [2,8,4,0], 'Options');
        % Correction for multiple comparison
        gui_component('Label', jPanelOptions, 'br', 'Multiple comparisons:');
        gui_component('Label', jPanelOptions, 'br', '    ');
        jRadioCorrNo   = gui_component('radio', jPanelOptions, '', 'Uncorrected', [], [], @(h,ev)SaveOptions(1));
        gui_component('Label', jPanelOptions, 'br', '    ');
        jRadioCorrBonf = gui_component('radio', jPanelOptions, '', 'Bonferroni', [], [], @(h,ev)SaveOptions(1));
        gui_component('Label', jPanelOptions, 'br', '    ');
        jRadioCorrFdr  = gui_component('radio', jPanelOptions, '', 'False discovery rate (FDR)', [], [], @(h,ev)SaveOptions(1));
        % Create button group
        jButtonGroup = ButtonGroup();
        jButtonGroup.add(jRadioCorrNo);
        jButtonGroup.add(jRadioCorrBonf);
        jButtonGroup.add(jRadioCorrFdr);

        % Control
        gui_component('Label', jPanelOptions, 'br', 'Control over dimensions: ');
        gui_component('Label', jPanelOptions, 'br', '    ');
        jRadioControlSpace = gui_component('checkbox', jPanelOptions, '', '1: Signals', [], [], @(h,ev)SaveOptions(1));
        gui_component('Label', jPanelOptions, 'br', '    ');
        jRadioControlTime     = gui_component('checkbox', jPanelOptions, '', '2: Time', [], [], @(h,ev)SaveOptions(1));
        gui_component('Label', jPanelOptions, 'br', '    ');
        jRadioControlFreq     = gui_component('checkbox', jPanelOptions, '', '3: Frequency', [], [], @(h,ev)SaveOptions(1));
    jPanelNew.add('br hfill', jPanelOptions);

    % === HELP ===
%     jButtonHelp = JButton('Help');
%     jButtonHelp.setForeground(Color(.7, 0, 0));
%     java_setcb(jButtonHelp, 'ActionPerformedCallback', @(h,ev)bst_help('PanelFilter.html'));
%     jPanelMain.add('br right', jButtonHelp);
%     % === UPDATE BUTTON ===
%     jButtonUpdate = JButton('Apply');
%     java_setcb(jButtonUpdate, 'ActionPerformedCallback', @ButtonUpdate_Callback);
%     jPanelNew.add('br right', jButtonUpdate);
    
    % Controls list
    ctrl = struct('jTextPThresh',           jTextPThresh, ...
                  'jRadioCorrNo',           jRadioCorrNo, ...
                  'jRadioCorrBonf',         jRadioCorrBonf, ...
                  'jRadioCorrFdr',          jRadioCorrFdr, ...
                  'jRadioControlSpace',     jRadioControlSpace, ...
                  'jRadioControlTime',      jRadioControlTime, ...
                  'jRadioControlFreq',      jRadioControlFreq);
    % Set current options
    UpdatePanel(ctrl);

    % Create the BstPanel object that is returned by the function
    bstPanelNew = BstPanel(panelName, jPanelNew, ctrl);

    
%% =================================================================================
%  === CONTROLS CALLBACKS  =========================================================
%  =================================================================================            
end

%% =================================================================================
%  === EXTERNAL PANEL CALLBACKS  ===================================================
%  =================================================================================
%% ===== UPDATE PANEL =====
function UpdatePanel(ctrl)
    % Get panel controls
    if (nargin == 0) || isempty(ctrl)
        ctrl = bst_get('PanelControls', 'Stat');
    end
    % Get current options
    StatThreshOptions = bst_get('StatThreshOptions');
    % p-threshold
    ctrl.jTextPThresh.setText(num2str(StatThreshOptions.pThreshold, '%g'));
    % Multiple comparisons
    switch (StatThreshOptions.Correction)
        case 'none',       ctrl.jRadioCorrNo.setSelected(1);
        case 'bonferroni', ctrl.jRadioCorrBonf.setSelected(1);
        case 'fdr',        ctrl.jRadioCorrFdr.setSelected(1);
    end
    % Control
    if ismember(1, StatThreshOptions.Control)
        ctrl.jRadioControlSpace.setSelected(1);
    end
    if ismember(2, StatThreshOptions.Control)
        ctrl.jRadioControlTime.setSelected(1);
    end
    if ismember(3, StatThreshOptions.Control)
        ctrl.jRadioControlFreq.setSelected(1);
    end
end


%% ===== CURRENT FIGURE CHANGED =====
function CurrentFigureChanged_Callback(hFig) %#ok<DEFNU>

end


%% ===== SAVE OPTIONS =====
function SaveOptions(isUpdateFigures)
    % Get panel
    ctrl = bst_get('PanelControls', 'Stat');
    if isempty(ctrl)
        return;
    end
    % Get options structure
    StatThreshOptions = bst_get('StatThreshOptions');
    % p-value
    pThresh = str2double(char(ctrl.jTextPThresh.getText()));
    if isnan(pThresh) || (pThresh <= 0) || (pThresh >= 1)
        pThresh = StatThreshOptions.pThreshold;
    else
        StatThreshOptions.pThreshold = pThresh;
    end
    ctrl.jTextPThresh.setText(num2str(StatThreshOptions.pThreshold, '%g'));
    % Multiple comparisons
    if ctrl.jRadioCorrBonf.isSelected()
        StatThreshOptions.Correction = 'bonferroni';
    elseif ctrl.jRadioCorrFdr.isSelected()
        StatThreshOptions.Correction = 'fdr';
    else
        StatThreshOptions.Correction = 'none';
    end
    % Control
    StatThreshOptions.Control = [];
    if ctrl.jRadioControlSpace.isSelected()
        StatThreshOptions.Control(end+1) = 1;
    end
    if ctrl.jRadioControlTime.isSelected()
        StatThreshOptions.Control(end+1) = 2;
    end
    if ctrl.jRadioControlFreq.isSelected()
        StatThreshOptions.Control(end+1) = 3;
    end
    % Set options structure
    bst_set('StatThreshOptions', StatThreshOptions);
    
    % ===== UPDATE FIGURES =====
    if isUpdateFigures
        UpdateFigures();
    end
end


% ===== BUTTON UPDATE CALLBACK =====
function UpdateFigures(varargin)
    % Display progress bar
    bst_progress('start', 'Statistic thresholding', 'Apply new options...');
    % Reload all the datasets, to apply the new filters
    bst_memory('ReloadStatDataSets');
    % Notify all the figures that they should be redrawn
    bst_figures('ReloadFigures', 'Stat');
    % Hide progress bar
    bst_progress('stop');
end



