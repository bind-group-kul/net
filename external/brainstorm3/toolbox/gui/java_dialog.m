function res = java_dialog( msgType, msg, msgTitle, jParent, varargin )
% JAVA_DIALOG: Display a Java-based dialog.
%
% USAGE:  res = java_dialog( msgType, msg )
%         res = java_dialog( msgType, msg, msgTitle )
%         res = java_dialog( msgType, msg, msgTitle, jParent )
%         res = java_dialog( msgType, msg, msgTitle, jParent, OPTIONS )
%         
% INPUT:
%    - msgType  : String that defines the icon and controls displayed in the dialog box. Possible values:
%                 {'error', 'warning', 'msgbox', 'confirm', 'question', 'input', 'checkbox', 'radio', 'combo'}
%    - msg      : Message in the dialog box 
%                 (can be a cell array of strings for 'input' message type)
%    - msgTitle : Title of the dialog box
%    - jParent  : Handle to the parent JFrame. 
%                 If no parent, or unknown, set to [].
%    - OPTIONS  : Depends on the dialog type
%                  - 'question' : OPTIONS = buttonList
%                                 OPTIONS = buttonList, defaultButton
%                  - 'combo'    : OPTIONS = buttonList
%                                 OPTIONS = buttonList, defaultButton
%                  - 'input'    : OPTIONS = defaultVals
%                  - 'checkbox' : OPTIONS = buttonList
%                                 OPTIONS = buttonList, defaultVals
%                  - 'radio'    : OPTIONS = buttonList
%                                 OPTIONS = buttonList, defaultInd
% OUTPUT:
%    - res : 1 if user validated the dialog, 0 else.

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

global GlobalData;

% Get brainstorm frame
jBstFrame = bst_get('BstFrame');

% Parse inputs
if (nargin < 2)
    error('Invalid call to java_dialog()');
end
if (nargin < 3)
    msgTitle = '';
end
if (nargin < 4) || isempty(jParent)
    jParent = jBstFrame;
end

% Hide progress bar
isProgress = bst_progress('isvisible');
if isProgress
    bst_progress('hide');
end

% Get all the modal JDialogs
if ~isempty(jBstFrame)
    jDialogModal = [];
    jDialogAlwaysOnTop = [];
    for i=1:length(GlobalData.Program.GUI.panels)
        panelContainer = get(GlobalData.Program.GUI.panels(i), 'container');
        panelContainer = panelContainer.handle{1};
        if isa(panelContainer, 'javax.swing.JDialog') && panelContainer.isModal()
            % A modal JDialog is found => Set it non non-modal
            jDialogModal = panelContainer;
            jDialogModal.setModal(0);
        end
        if (isa(panelContainer, 'javax.swing.JDialog') || isa(panelContainer, 'javax.swing.JFrame')) && panelContainer.isAlwaysOnTop()
            % An AlwaysOnTop frame is found => Remove always on top attribute
            jDialogAlwaysOnTop = panelContainer;
            jDialogAlwaysOnTop.setAlwaysOnTop(0);
        end
    end
end

% Show java dialog
switch(lower(msgType))
    case 'error'
        if isempty(msgTitle)
            msgTitle = 'Error';
        end
        java_call('javax.swing.JOptionPane', 'showMessageDialog', 'Ljava.awt.Component;Ljava.lang.Object;Ljava.lang.String;I', jParent, msg, msgTitle, javax.swing.JOptionPane.ERROR_MESSAGE);
    case 'warning'
        if isempty(msgTitle)
            msgTitle = 'Warning';
        end
        java_call('javax.swing.JOptionPane', 'showMessageDialog', 'Ljava.awt.Component;Ljava.lang.Object;Ljava.lang.String;I', jParent, msg, msgTitle, javax.swing.JOptionPane.WARNING_MESSAGE);
    case 'msgbox'
        if isempty(msgTitle)
            msgTitle = 'Information';
        end
        java_call('javax.swing.JOptionPane', 'showMessageDialog', 'Ljava.awt.Component;Ljava.lang.Object;Ljava.lang.String;I', jParent, msg, msgTitle, javax.swing.JOptionPane.INFORMATION_MESSAGE);
    case 'confirm'
        if isempty(msgTitle)
            msgTitle = 'Confirmation';
        end
        reponse = java_call('javax.swing.JOptionPane', 'showConfirmDialog', 'Ljava.awt.Component;Ljava.lang.Object;Ljava.lang.String;I', jParent, msg, msgTitle, javax.swing.JOptionPane.YES_NO_OPTION);
        res = (reponse == javax.swing.JOptionPane.OK_OPTION);
        
    % OPTIONS: buttonList; buttonDefault
    case 'question'
        % Button list
        if (length(varargin) < 1)
            buttonList = {'Yes','No'};
        elseif iscell(varargin{1})
            buttonList = varargin{1};
        else
            error('Invalid call.');
        end
        % Default button
        if (length(varargin) < 2)
            buttonDefault = buttonList{1};
        elseif ischar(varargin{2})
            buttonDefault = varargin{2};
        else
            error('Invalid call.');
        end
        % Show dialog
        java_res = java_call('org.brainstorm.dialogs.MsgServer', 'dlgQuest', 'Ljava.awt.Component;Ljava.lang.String;Ljava.lang.String;[Ljava.lang.String;Ljava.lang.String;', jParent, msg, msgTitle, buttonList, buttonDefault);
        if isempty(java_res)
            res = [];
        else
            res = char(java_res);
        end
        
    % OPTIONS: defaultVals
    case 'input'
        % Default values
        if (length(varargin) < 1)
            if ischar(msg) 
                defaultVals = '';
            elseif iscell(msg)
                defaultVals = repmat({''}, 1, length(msg));
            end
        elseif ~((ischar(msg) && ischar(varargin{1})) || (iscell(msg) && iscell(varargin{1}) && (length(varargin{1}) == length(msg))))
            error('First and third argument must have the same type and the same size.');
        else
            defaultVals = varargin{1};
        end
        % === CALL INPUT DIALOG ===
        if iscell(msg)
            java_res = java_call('org.brainstorm.dialogs.MsgServer', 'dlgInput', 'Ljava/awt/Component;[Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;', jParent, msg, msgTitle, defaultVals);
        else
            java_res = java_call('org.brainstorm.dialogs.MsgServer', 'dlgInput', 'Ljava/awt/Component;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;', jParent, msg, msgTitle, defaultVals);
        end
        % === GET RESULTS ===
        if isempty(java_res)
            res = [];
        elseif ischar(msg)
            res = char(java_res);
        elseif iscell(msg)
            nbInputs = length(java_res);
            res = cell(1, nbInputs);
            for i=1:nbInputs
                res{i} = char(java_res(i));
            end
        end
        
    % Options: buttonList, defaultVal
    case 'checkbox'
        % List of options
        if iscell(varargin{1})
            buttonList = varargin{1};
        else
            error('Invalid call.');
        end
        % Default values
        if (length(varargin) >= 2)
            defaultVal = varargin{2};
        else
            defaultVal = [];
        end
        
        % Create a dialog message
        if ~isempty(buttonList)
            jPanel = gui_river([2,2], [3,3,3,3]);
            jCheck = javaArray('javax.swing.JCheckBox', length(buttonList));
            for i = 1:length(buttonList)
                % Create check box
                jCheck(i) = javax.swing.JCheckBox(buttonList{i});
                % Box size
                isLongText = (length(buttonList{i}) > 10);
                if ~isLongText
                    jCheck(i).setPreferredSize(java.awt.Dimension(80, 20));
                end
                % Default value
                if ~isempty(defaultVal)
                    jCheck(i).setSelected(defaultVal(i));
                end
                % Add: right after of on the next row ?
                if (mod(i-1, 5) == 0) || isLongText
                    jPanel.add('br', jCheck(i));
                else
                    jPanel.add(jCheck(i));
                end
            end
        end
        message = javaArray('java.lang.Object',2);
        message(1) = java.lang.String(msg);
        message(2) = jPanel;
        % Show question
        answer = java_call('javax.swing.JOptionPane', 'showConfirmDialog', 'Ljava.awt.Component;Ljava.lang.Object;Ljava.lang.String;I', jParent, message, msgTitle, javax.swing.JOptionPane.OK_CANCEL_OPTION);
        if (answer ~= javax.swing.JOptionPane.OK_OPTION)
            res = [];
            return;
        end
        % Else look for the selected options
        if isempty(defaultVal)
            res = {};
            for i = 1:length(buttonList)
                if (jCheck(i).isSelected())
                    res{end+1} = buttonList{i};
                end
            end
        else
            res = [];
            for i = 1:length(buttonList)
                res(end+1) = double(jCheck(i).isSelected());
            end
        end
        
    % Options: buttonList, defaultInd
    case 'radio'
        % List of options
        if iscell(varargin{1})
            buttonList = varargin{1};
        else
            error('Invalid call.');
        end
        % Default values
        if (length(varargin) >= 2)
            defaultInd = varargin{2};
        else
            defaultInd = [];
        end
        
        % Create a dialog message
        if ~isempty(buttonList)
            jPanel = gui_river([2,2], [3,3,3,3]);
            jRadio = javaArray('javax.swing.JRadioButton', length(buttonList));
            jGroup = javax.swing.ButtonGroup;
            for i = 1:length(buttonList)
                % Create check box
                jRadio(i) = javax.swing.JRadioButton(buttonList{i});
                % Add it to button group
                jGroup.add(jRadio(i));
                % Box size
                isLongText = (length(buttonList{i}) > 10);
                if ~isLongText
                    jRadio(i).setPreferredSize(java.awt.Dimension(80, 20));
                end
                % Default value
                if ~isempty(defaultInd) && (i == defaultInd)
                    jRadio(i).setSelected(1);
                end
                % Add: right after of on the next row ?
                if (mod(i-1, 5) == 0) || isLongText
                    jPanel.add('br', jRadio(i));
                else
                    jPanel.add(jRadio(i));
                end
            end
        end
        message = javaArray('java.lang.Object',2);
        message(1) = java.lang.String(msg);
        message(2) = jPanel;
        % Show question
        answer = java_call('javax.swing.JOptionPane', 'showConfirmDialog', 'Ljava.awt.Component;Ljava.lang.Object;Ljava.lang.String;I', jParent, message, msgTitle, javax.swing.JOptionPane.OK_CANCEL_OPTION);
        if (answer ~= javax.swing.JOptionPane.OK_OPTION)
            res = [];
            return;
        end
        % Else look for the selected option
        for i = 1:length(jRadio)
            if (jRadio(i).isSelected())
                res = i;
                break;
            end
        end
        
    % OPTIONS: buttonList; buttonDefault
    case 'combo'
        % List of options
        if iscell(varargin{1})
            buttonList = varargin{1};
        else
            error('Invalid call.');
        end
        % Default values
        if (length(varargin) >= 2)
            iSelect = find(strcmpi(varargin{2}, buttonList));
        else
            iSelect = [];
        end
        
        % Create a dialog message
        jCombo = gui_component('ComboBox', [], [], [], {buttonList}, [], [], []);
        % Default selection
        if ~isempty(iSelect)
            jCombo.setSelectedIndex(iSelect - 1);
        end
        % Message
        message = javaArray('java.lang.Object',2);
        message(1) = java.lang.String(msg);
        message(2) = jCombo;
        % Show question
        answer = java_call('javax.swing.JOptionPane', 'showConfirmDialog', 'Ljava.awt.Component;Ljava.lang.Object;Ljava.lang.String;I', jParent, message, msgTitle, javax.swing.JOptionPane.OK_CANCEL_OPTION);
        if (answer ~= javax.swing.JOptionPane.OK_OPTION)
            res = [];
            return;
        end
        % Else look for the selected options
        iSelect = jCombo.getSelectedIndex() + 1;
        res = buttonList{iSelect};
end

% Restore modal panels
if ~isempty(jBstFrame)
    if ~isempty(jDialogModal)
        jDialogModal.setModal(1);
    end
    if ~isempty(jDialogAlwaysOnTop)
        jDialogAlwaysOnTop.setAlwaysOnTop(1);
    end
end

% Restore progress bar
if isProgress
    bst_progress('show');
end





