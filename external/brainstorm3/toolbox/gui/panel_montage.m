function varargout = panel_montage(varargin)
% PANEL_MONTAGE: Edit sensor montages.
%
% USAGE:  panel_montage('ShowEditor');

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
    import org.brainstorm.icon.*;
    panelName = 'EditMontages';
    % Constants
    global GlobalData;
    OldMontages = GlobalData.ChannelMontages;
    
    % Create main panel
    jPanelNew = gui_component('Panel');
    jPanelNew.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));
    
    % PANEL: left panel (list of available montages)
    jPanelMontages = gui_component('Panel');
    jPanelMontages.setBorder(BorderFactory.createCompoundBorder(...
                             BorderFactory.createTitledBorder('Montages'), ...
                             BorderFactory.createEmptyBorder(3, 10, 10, 10)));
        % ===== TOOLBAR =====
        jToolbar = gui_component('Toolbar', jPanelMontages, BorderLayout.NORTH);
        jToolbar.setPreferredSize(Dimension(100,25));
            TB_SIZE = Dimension(25,25);
            jButtonNew      = gui_component('ToolbarButton', jToolbar, [], [], {IconLoader.ICON_MONTAGE_MENU, Dimension(35,25)}, 'New montage', []);
            jButtonLoadFile = gui_component('ToolbarButton', jToolbar, [], [], {IconLoader.ICON_FOLDER_OPEN, TB_SIZE}, 'Load montage', []);
            jButtonSaveFile = gui_component('ToolbarButton', jToolbar, [], [], {IconLoader.ICON_SAVE, TB_SIZE}, 'Save montage', []);
            jToolbar.addSeparator();
            jButtonAll = gui_component('ToolbarToggle', jToolbar, [], [], {IconLoader.ICON_SCOUT_ALL, TB_SIZE}, 'Display all the montages', []);
        % LIST: Create list
        jListMontages = JList({'Montage #1', 'Montage #2', 'Montage #3'});
            jListMontages.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
            java_setcb(jListMontages, 'ValueChangedCallback', [], ...
                                      'KeyTypedCallback',     [], ...
                                      'MouseClickedCallback', []);
            % Create scroll panel
            jScrollPanelSel = JScrollPane(jListMontages);
            jScrollPanelSel.setPreferredSize(Dimension(150,200));
        jPanelMontages.add(jScrollPanelSel, BorderLayout.CENTER);
    jPanelNew.add(jPanelMontages, BorderLayout.WEST);
    
    % PANEL: right panel (sensors list OR text editor)
    jPanelRight = gui_component('Panel');
        % === SENSOR SELECTION ===
        jPanelSelection = gui_component('Panel');
        jPanelSelection.setBorder(BorderFactory.createCompoundBorder(...
                                  BorderFactory.createTitledBorder('Channel selection'), ...
                                  BorderFactory.createEmptyBorder(10, 10, 10, 10)));
        % LABEL: Title
        jPanelSelection.add(JLabel('<HTML><DIV style="height:15px;">Available sensors:</DIV>'), BorderLayout.NORTH);
        % LIST: Create list (display labels of all clusters)
        jListSensors = JList({'Sensor #1', 'Sensor #2', 'Sensor #3','Sensor #4', 'Sensor #5', 'Sensor #6','Sensor #7', 'Sensor #8', 'Sensor #9','Sensor #10', 'Sensor #11', 'Sensor #12'});
            jListSensors.setLayoutOrientation(jListSensors.VERTICAL_WRAP);
            jListSensors.setVisibleRowCount(-1);
            jListSensors.setSelectionMode(ListSelectionModel.MULTIPLE_INTERVAL_SELECTION);
            % Create scroll panel
            jScrollPanel = JScrollPane(jListSensors);
        jPanelSelection.add(jScrollPanel, BorderLayout.CENTER);
        
        % === TEXT VIEWER ===
        jPanelViewer = gui_component('Panel');
        jPanelViewer.setBorder(BorderFactory.createCompoundBorder(...
                             BorderFactory.createTitledBorder('Channel selection [Read-only]'), ...
                             BorderFactory.createEmptyBorder(10, 10, 10, 10)));
        jTextViewer = JTextArea(6, 12);
        jTextViewer.setFont(Font(Font.MONOSPACED, Font.PLAIN, 11));
        jTextViewer.setEditable(0);
        % Create scroll panel
        jScrollPanel = JScrollPane(jTextViewer);
        jPanelViewer.add(jScrollPanel, BorderLayout.CENTER);
                
        % === TEXT EDITOR ===
        jPanelText = gui_component('Panel');
        jPanelText.setBorder(BorderFactory.createCompoundBorder(...
                             BorderFactory.createTitledBorder('Custom montage'), ...
                             BorderFactory.createEmptyBorder(10, 10, 10, 10)));
        % LABEL: Title
        strHelp = ['Examples:<BR>' ...
            '  Cz-C4 : Cz,-C4<BR>' ...
            '  MC    : 0.5*M1, 0.5*M2<BR>' ...
            '  EOG   : EOG<BR>'];
        jPanelText.add(JLabel(['<HTML><PRE>' strHelp '</PRE>']), BorderLayout.NORTH);
        % TEXT: Create text editor
        jTextMontage = JTextArea(6, 12);
        jTextMontage.setFont(Font(Font.MONOSPACED, Font.PLAIN, 11));
        % Create scroll panel
        jScrollPanel = JScrollPane(jTextMontage);
        jPanelText.add(jScrollPanel, BorderLayout.CENTER);

        % === MATRIX EDITOR ===
        jPanelMatrix = gui_component('Panel');
        jPanelMatrix.setBorder(BorderFactory.createCompoundBorder(...
                             BorderFactory.createTitledBorder('Matrix viewer'), ...
                             BorderFactory.createEmptyBorder(10, 10, 10, 10)));
        % Create JTable
        jTableMatrix = JTable();
        %jTableMatrix.setRowHeight(22);
        jTableMatrix.setEnabled(0);
        jTableMatrix.setAutoResizeMode( JTable.AUTO_RESIZE_OFF );
        jTableMatrix.getTableHeader.setReorderingAllowed(0);
        jTableMatrix.setPreferredScrollableViewportSize(Dimension(5,5))
        % Create scroll panel
        jScrollPanel = JScrollPane(jTableMatrix);
        jScrollPanel.setBorder([]);
        jPanelMatrix.add(jScrollPanel, BorderLayout.CENTER);          
        
    jPanelRight.setPreferredSize(Dimension(400,550));
    % PANEL: Selections buttons
    jPanelBottom = gui_component('Panel');
    jPanelBottomLeft = gui_river([10 0], [10 10 0 10]);
    jPanelBottomRight = gui_river([10 0], [10 10 0 10]);
        jButtonValidate = gui_component('button', jPanelBottomLeft,  [], 'Validate', [], [], [], []);
        jButtonValidate.setVisible(0);
        gui_component('button', jPanelBottomRight, [], 'Cancel', [], [], @(h,ev)ButtonCancel_Callback(), []);
        jButtonSave = gui_component('button', jPanelBottomRight, [], 'Save', [], [], [], []);
    jPanelBottom.add(jPanelBottomLeft, BorderLayout.WEST);
    jPanelBottom.add(jPanelBottomRight, BorderLayout.EAST);
    jPanelRight.add(jPanelBottom, BorderLayout.SOUTH);
    jPanelNew.add(jPanelRight, BorderLayout.CENTER);
    % Create object to track modifications to the selected montage
    MontageModified = java.util.Vector();
    MontageModified.add('');
    % Create the BstPanel object that is returned by the function
    % => constructor BstPanel(jHandle, panelName, sControls)
    bstPanelNew = BstPanel(panelName, ...
                           jPanelNew, ...
                           struct('jButtonAll',       jButtonAll, ...
                                  'jPanelRight',      jPanelRight, ...
                                  'jPanelSelection',  jPanelSelection, ...
                                  'jPanelText',       jPanelText, ...
                                  'jPanelMatrix',     jPanelMatrix, ...
                                  'jPanelViewer',     jPanelViewer, ...
                                  'jListMontages',    jListMontages, ...
                                  'jTextMontage',     jTextMontage, ...
                                  'jTableMatrix',     jTableMatrix, ...
                                  'jTextViewer',      jTextViewer, ...
                                  'jButtonNew',       jButtonNew, ...
                                  'jButtonLoadFile',  jButtonLoadFile, ...
                                  'jButtonSaveFile',  jButtonSaveFile, ...
                                  'jListSensors',     jListSensors, ...
                                  'jButtonValidate',  jButtonValidate, ...
                                  'jButtonSave',      jButtonSave, ...
                                  'MontageModified',  MontageModified));
              
                               

%% =================================================================================
%  === CONTROLS CALLBACKS  =========================================================
%  =================================================================================
%% ===== CANCEL BUTTONS =====
    function ButtonCancel_Callback(varargin)
        % Revert changes
        GlobalData.ChannelMontages = OldMontages;
        % Close panel without saving
        gui_hide(panelName);
    end
end

%% ===== SAVE BUTTON =====
function ButtonSave_Callback(hFig)
    % Save last modifications
    SaveModifications(hFig);
    % If a figure is selected
    if ~isempty(hFig)
        % Get panel controls handles
        ctrl = bst_get('PanelControls', 'EditMontages');
        if isempty(ctrl)
            return;
        end
        % Get last montage selected
        jMontage = ctrl.jListMontages.getSelectedValue();
        % Update changes (re-select the current montage)
        if ~isempty(jMontage)
            % Get selected montage in the interface
            MontageName = char(jMontage.getName());
            % Get figure montages
            sFigMontages = GetMontagesForFigure(hFig);
            % If the selected montage is a valid montage for the figure: set it as the current montage
            if any(strcmpi(MontageName, {sFigMontages.Name}))
                SetCurrentMontage(hFig, MontageName);
            end
        end
    end
    % Close panel
    gui_hide('EditMontages');
end


%% ===== JLIST: MONTAGE SELECTION CHANGE =====
function MontageChanged_Callback(ev, hFig)
    if ~ev.getValueIsAdjusting()
        % Save previous modifications
        SaveModifications(hFig);
        % Update editor for new selected montage
        UpdateEditor(hFig);
    end
end

%% ===== JLIST: MOUSE CLICK =====
function MontageClick_Callback(ev, hFig)
    % If DOUBLE CLICK
    if (ev.getClickCount() == 2)
        % Rename selected montage
        ButtonRename_Callback(hFig);
    end
end

%% ===== JLIST: KEY TYPE =====
function MontageKeyTyped_Callback(ev, hFig)
    switch(uint8(ev.getKeyChar()))
        % DELETE
        case ev.VK_DELETE
            ButtonDelete_Callback(hFig);
    end
end

%% ===== CHANNELS SELECTION CHANGED =====
function ChannelsChanged_Callback(hObj, ev)
    if ~ev.getValueIsAdjusting()
        % Get panel controls handles
        ctrl = bst_get('PanelControls', 'EditMontages');
        if isempty(ctrl)
            return;
        end
        % Get selected montage
        jMontage = ctrl.jListMontages.getSelectedValue();
        % Set as modified
        if ~isempty(jMontage)
            % Update changes (re-select the current montage)
            ctrl.MontageModified.set(0, jMontage.getName());
        else
            ctrl.MontageModified.set(0, '');
        end
    end
end
    
%% ===== EDITOR KEY TYPED =====
function EditorKeyTyped_Callback(hObj, ev)
    % Get panel controls handles
    ctrl = bst_get('PanelControls', 'EditMontages');
    if isempty(ctrl)
        return;
    end
    % Get selected montage
    jMontage = ctrl.jListMontages.getSelectedValue();
    % Set as modified
    if ~isempty(jMontage)
        % Update changes (re-select the current montage)
        ctrl.MontageModified.set(0, jMontage.getName());
    else
        ctrl.MontageModified.set(0, '');
    end
end



%% =================================================================================
%  === PANEL FUNCTIONS =============================================================
%  =================================================================================
    
%% ===== BUTTON: DELETE =====
function ButtonDelete_Callback(hFig)
	% Get selected montage
    sMontage = GetSelectedMontage(hFig);
    if isempty(sMontage)
        return
    end
    % Remove montage
    DeleteMontage(sMontage.Name);
    % Update montages list
    UpdateMontagesList(hFig);
    % Update montage editor
    UpdateEditor(hFig);
end
    
%% ===== BUTTON: RENAME =====
function ButtonRename_Callback(hFig)
	% Get selected montage
    sMontage = GetSelectedMontage(hFig);
    if isempty(sMontage)
        return
    end
	% Rename montage
    newName = RenameMontage(sMontage.Name);
    % Update panel
    if ~isempty(newName)
        % Update montage list
        UpdateMontagesList(hFig, newName);
        % Update montage editor
        UpdateEditor(hFig);
    end
end
    
%% ===== BUTTON: DUPLICATE =====
function ButtonDuplicate_Callback(hFig)
	% Get selected montage
    sMontage = GetSelectedMontage(hFig);
    if isempty(sMontage)
        return
    end
	% Add again the same montage
    MontageName = SetMontage(sMontage.Name, sMontage, 0);
    % If a figure is passed in argument
    if ~isempty(MontageName)
        % Update montage list
        UpdateMontagesList(hFig, MontageName);
        % Update montage editor
        UpdateEditor(hFig);
    end
end

%% ===== BUTTON: LOAD FILE =====
function ButtonLoadFile_Callback(hFig)
	% Load file
    sNewMontage = LoadMontageFile();
    % Update panel
    if ~isempty(sNewMontage)
        % If the montage is not part of this figure: switch to ALL
        if ~isempty(hFig)
            % Get figure montages
            sFigMontages = GetMontagesForFigure(hFig);
            % If last montage loaded is not part of the figure
            if ~any(strcmpi(sNewMontage(end).Name, {sFigMontages.Name}))
                % Get panel controls handles
                ctrl = bst_get('PanelControls', 'EditMontages');
                % Select ALL button
                if ~isempty(ctrl)
                    ctrl.jButtonAll.setSelected(1);
                end
            end
        end
        % Update montage list
        UpdateMontagesList(hFig, sNewMontage(end).Name);
        % Update montage editor
        UpdateEditor(hFig);
    end
end

%% ===== BUTTON: SAVE FILE =====
function ButtonSaveFile_Callback()
    % Get current montage
    sMontage = GetSelectedMontage();
    % Save file
    SaveMontageFile(sMontage);
end

%% ===== BUTTON: ALL =====
function ButtonAll_Callback(hFig)
    % Update montage list
    UpdateMontagesList(hFig);
    % Update montage editor
    UpdateEditor(hFig);
end


%% ===== LOAD FIGURE =====
function LoadFigure(hFig)
    import org.brainstorm.list.*;
    global GlobalData;
    % Get panel controls handles
    ctrl = bst_get('PanelControls', 'EditMontages');
    % Find figure info
    [hFig,iFig,iDS] = bst_figures('GetFigure', hFig);
    % Update montage list
    UpdateMontagesList(hFig);
    % Remove JList callbacks
    java_setcb(ctrl.jListSensors, 'ValueChangedCallback', []);
    java_setcb(ctrl.jTextMontage, 'KeyTypedCallback', []);
    % Get channels displayed in this figure
    iChannels = GlobalData.DataSet(iDS).Figure(iFig).SelectedChannels;
    Channels = {GlobalData.DataSet(iDS).Channel(iChannels).Name};
    % Create a list with all the available selections
    listModel = javax.swing.DefaultListModel();
    for i = 1:length(Channels)
        listModel.addElement(BstListItem('', '', [Channels{i} '       '], i));
    end
    ctrl.jListSensors.setModel(listModel);
    % Update channel selection fot the first time
    UpdateEditor(hFig);
    % Set callbacks
    java_setcb(ctrl.jButtonAll,      'ActionPerformedCallback', @(h,ev)ButtonAll_Callback(hFig));
    java_setcb(ctrl.jListSensors,    'ValueChangedCallback',    @ChannelsChanged_Callback);
    java_setcb(ctrl.jTextMontage,    'KeyTypedCallback',        @EditorKeyTyped_Callback)
    java_setcb(ctrl.jButtonNew,      'ActionPerformedCallback', @(h,ev)CreateMontageMenu(ev.getSource(), hFig));
    java_setcb(ctrl.jButtonLoadFile, 'ActionPerformedCallback', @(h,ev)ButtonLoadFile_Callback(hFig));
    java_setcb(ctrl.jButtonSaveFile, 'ActionPerformedCallback', @(h,ev)ButtonSaveFile_Callback());
    java_setcb(ctrl.jButtonValidate, 'ActionPerformedCallback', @(h,ev)ValidateEditor(hFig));
    java_setcb(ctrl.jButtonSave,     'ActionPerformedCallback', @(h,ev)ButtonSave_Callback(hFig));
end


%% ===== UPDATE MONTAGES LIST =====
function [sFigMontages, iFigMontages] = UpdateMontagesList(hFig, SelMontageName)
    import org.brainstorm.list.*;
    % Parse inputs
    if (nargin < 2) || isempty(SelMontageName)
        SelMontageName = [];
    end
    % Get panel controls handles
    ctrl = bst_get('PanelControls', 'EditMontages');
    % Remove JList callbacks
    java_setcb(ctrl.jListMontages, 'ValueChangedCallback', []);
    % Get available montages
    [sAllMontages, iAllMontages] = GetMontage([], hFig);
    if ~isempty(hFig)
        [sFigMontages, iFigMontages] = GetMontagesForFigure(hFig);
    else
        sFigMontages = sAllMontages;
        iFigMontages = iAllMontages;
    end
    % Displayed montages depend on the "ALL" button
    isAll = ctrl.jButtonAll.isSelected();
    if isAll
        iDispMontages = iAllMontages;
    else
        iDispMontages = iFigMontages;
    end
    % If the selected montage was not passed in argument: Get previously selected montage
    if isempty(SelMontageName)
        prevSel = ctrl.jListMontages.getSelectedValue();
        if ~isempty(prevSel) && ~ischar(prevSel)          
            SelMontageName = prevSel.getType();
        end
    end
    % No previously selected montage: Get the selected montage from the current figure
    if isempty(SelMontageName)
        sMontage = GetCurrentMontage(hFig);
        if ~isempty(sMontage)
            SelMontageName = sMontage.Name;
        end
    end
    % Create a list with all the available montages
    listModel = javax.swing.DefaultListModel();
    for i = 1:length(iDispMontages)
        iMontage = iDispMontages(i);
        if ~isAll || ismember(iMontage, iFigMontages)
            strMontage = sAllMontages(iMontage).Name;
        else
            strMontage = ['[' sAllMontages(iMontage).Name ']'];
        end
        listModel.addElement(BstListItem(sAllMontages(iMontage).Name, '', strMontage, iMontage));
    end
    ctrl.jListMontages.setModel(listModel);
    % Look for selected montage index in the list of displayed montages
    if ~isempty(SelMontageName)
        if isAll
            iCurSel = find(strcmpi({sAllMontages.Name}, SelMontageName));
        else
            iCurSel = find(strcmpi({sFigMontages.Name}, SelMontageName));
        end
        if isempty(iCurSel)
            iCurSel = 1;
        end
    else
        iCurSel = 1;
    end
    % Select one item
    ctrl.jListMontages.setSelectedIndex(iCurSel - 1);
    % Scroll to see the selected scout in the list
    if ~isequal(iCurSel, 0)
        selRect = ctrl.jListMontages.getCellBounds(iCurSel-1, iCurSel-1);
        ctrl.jListMontages.scrollRectToVisible(selRect);
        ctrl.jListMontages.repaint();
    end
    % Set callbacks
    java_setcb(ctrl.jListMontages, 'ValueChangedCallback', @(h,ev)MontageChanged_Callback(ev,hFig), ...
                                   'KeyTypedCallback',     @(h,ev)MontageKeyTyped_Callback(ev,hFig), ...
                                   'MouseClickedCallback', @(h,ev)MontageClick_Callback(ev,hFig));
end


%% ===== GET SELECTED MONTAGE =====
function [sMontage, iMontage] = GetSelectedMontage(hFig)
    % Parse inputs
    if (nargin < 1) || isempty(hFig)
        hFig = [];
    end
    % Get panel controls handles
    ctrl = bst_get('PanelControls', 'EditMontages');
    % Get all montages
    sMontages = GetMontage([], hFig);
    % Get the index of the montage
    jMontage = ctrl.jListMontages.getSelectedValue();
    % Get the target montage
    if ~isempty(jMontage)
        iMontage = jMontage.getUserData();
        sMontage = sMontages(iMontage);
    else
        sMontage = [];
        iMontage = [];
    end
end

%% ===== UPDATE MONTAGE =====
function UpdateEditor(hFig)
    global GlobalData;
    % Get panel controls handles
    ctrl = bst_get('PanelControls', 'EditMontages');
    % Get montages for this figure
    [sMontage, iMontage] = GetSelectedMontage(hFig);
    % If nothing selected: unselect all channels and return
    if isempty(sMontage)
        ctrl.jListSensors.setSelectedIndex(-1);
        return;
    end
    % Get the montages for the current figure
    if ~isempty(hFig)
        [sFigMontages, iFigMontages] = GetMontagesForFigure(hFig);
        isFigMontage = ismember(iMontage, iFigMontages);
    else
        [sFigMontages, iFigMontages] = GetMontage([], hFig);
        isFigMontage = 0;
    end
    % Remove all the previous panels
    ctrl.jPanelRight.remove(ctrl.jPanelSelection);
    ctrl.jPanelRight.remove(ctrl.jPanelText);
    ctrl.jPanelRight.remove(ctrl.jPanelMatrix);
    ctrl.jPanelRight.remove(ctrl.jPanelViewer);
    
    % === TEXT VIEWER: CHANNEL LISTS ===
    if strcmpi(sMontage.Type, 'selection') && ~isFigMontage
        % Make selection panel visible
        ctrl.jButtonValidate.setVisible(0);
        ctrl.jPanelRight.add(ctrl.jPanelViewer, java.awt.BorderLayout.CENTER);
        % Build a string to represent the channels list
        strChan = '';
        for iChan = 1:length(sMontage.ChanNames)
            if (mod(iChan-1,5) == 0) && (iChan ~= 1)
                strChan = [strChan, 10];
            end
            strChan = [strChan, ' ' sMontage.ChanNames{iChan}];
            if (iChan ~= length(sMontage.ChanNames))
                strChan = [strChan, ','];
            end
        end
        ctrl.jTextViewer.setText(strChan);
        
    % === SELECTION EDITOR ===
    elseif strcmpi(sMontage.Type, 'selection')
        % Make selection panel visible
        ctrl.jButtonValidate.setVisible(0);
        ctrl.jPanelRight.add(ctrl.jPanelSelection, java.awt.BorderLayout.CENTER);
        % Remove JList callbacks
        java_setcb(ctrl.jListSensors, 'ValueChangedCallback', []);
        % Find figure info
        [hFig,iFig,iDS] = bst_figures('GetFigure', hFig);
        % Get channels displayed in this figure
        iChannels = GlobalData.DataSet(iDS).Figure(iFig).SelectedChannels;
        Channels = {GlobalData.DataSet(iDS).Channel(iChannels).Name};
        % Build the list of elements to select in sensors list
        iSelChan = [];
        for i = 1:length(sMontage.ChanNames)
            iTmp = find(strcmpi(Channels, sMontage.ChanNames{i}));
            if ~isempty(iTmp)
                iSelChan = [iSelChan, iTmp];
            end
        end
        % Select channels
        if isempty(iSelChan)
            iSelChan = 0;
        end
        ctrl.jListSensors.setSelectedIndices(iSelChan - 1);
        % Restore JList callbacks
        java_setcb(ctrl.jListSensors, 'ValueChangedCallback', @ChannelsChanged_Callback);
        
    % === TEXT EDITOR ===
    elseif strcmpi(sMontage.Type, 'text')
        % Make editor panel visible
        ctrl.jButtonValidate.setVisible(1);
        ctrl.jPanelRight.add(ctrl.jPanelText, java.awt.BorderLayout.CENTER);
        % Set the text corresponding to the montage
        strEdit = out_montage_mon([], sMontage);
        iFirstCr = find(strEdit == 10, 1);
        ctrl.jTextMontage.setText(strEdit(iFirstCr+1:end));
        
    % === MATRIX VIEWER ===
    elseif strcmpi(sMontage.Type, 'matrix') && ~isempty(sMontage.Matrix)
        % Make editor panel visible
        ctrl.jButtonValidate.setVisible(0);
        ctrl.jPanelRight.add(ctrl.jPanelMatrix, java.awt.BorderLayout.CENTER);
        % Create table model
        model = javax.swing.table.DefaultTableModel(size(sMontage.Matrix,1)+1, size(sMontage.Matrix,2)+1);
        for iDisp = 1:size(sMontage.Matrix,1)
            row = cell(1, size(sMontage.Matrix,2)+1);
            row{1} = sMontage.DispNames{iDisp};
            for iChan = 1:size(sMontage.Matrix,2)
                row{iChan+1} = num2str(sMontage.Matrix(iDisp,iChan));
                if (length(row{iChan+1}) > 5)
                    row{iChan+1} = row{iChan+1}(1:5);
                end
            end
            model.insertRow(iDisp-1, row);
        end
        ctrl.jTableMatrix.setModel(model);
        % Resize all the columns
        for iCol = 0:size(sMontage.Matrix,2)
            ctrl.jTableMatrix.getColumnModel().getColumn(iCol).setPreferredWidth(50);
            if (iCol > 0)
                ctrl.jTableMatrix.getColumnModel().getColumn(iCol).setHeaderValue(sMontage.ChanNames{iCol});
            else
                ctrl.jTableMatrix.getColumnModel().getColumn(iCol).setHeaderValue(' ');
            end
        end
        
    % === ERROR ===
    else
        % Make selection panel visible
        ctrl.jButtonValidate.setVisible(0);
        ctrl.jPanelRight.add(ctrl.jPanelViewer, java.awt.BorderLayout.CENTER);
        % Display error message
        ctrl.jTextViewer.setText(['This montage cannot be loaded for this dataset.']);
    end
    % Force update of the display
    ctrl.jPanelRight.revalidate();
    ctrl.jPanelRight.repaint();
end

%% ===== VALIDATE EDITOR CONTENTS =====
function ValidateEditor(hFig)
    % Get panel controls handles
    ctrl = bst_get('PanelControls', 'EditMontages');
    % Convert text in editor to montage structure
    strText = char(ctrl.jTextMontage.getText());
    strText = ['Validate', 10, strText];
    [sMontage, errMsg] = in_montage_mon(strText);
    % Set the text corresponding to the montage
    strEdit = out_montage_mon([], sMontage);
    iFirstCr = find(strEdit == 10, 1);
    ctrl.jTextMontage.setText(strEdit(iFirstCr+1:end));
    % Display error messages
    if ~isempty(errMsg)
        bst_error(errMsg, 'Validate montage', 0);
    end
    % Change figure selection: save modifications
    if ~isempty(hFig)
        SaveModifications(hFig);
    end
end


%% ===== SAVE MODIFICATIONS =====
function SaveModifications(hFig)
    % Parse inputs
    if (nargin < 1) || isempty(hFig)
        hFig = [];
    end
    % Get panel controls handles
    ctrl = bst_get('PanelControls', 'EditMontages');
    % Check if there were modifications
    MontageName = ctrl.MontageModified.get(0);
    if isempty(MontageName)
        return;
    end
    % Reset the modification
    ctrl.MontageModified.set(0, '');
    % Get montage structure
    sMontage = GetMontage(MontageName, hFig);
    % Channel selection
    if strcmpi(sMontage.Type, 'selection')
        % Get selected channels
        selChans = ctrl.jListSensors.getSelectedValues();
        % Build list of channels for updated setup
        ChanNames = cell(1,length(selChans));
        for i = 1:length(selChans)
            % Get directly the name of the channel (and remove the trailing spaces added for display)
            chName = char(selChans(i).getName());
            ChanNames{i} = chName(1:end-7);
        end
        % Update montage
        sMontage.ChanNames = ChanNames;
        sMontage.DispNames = ChanNames;
        sMontage.Matrix = eye(length(ChanNames));
    % Text editor
    elseif strcmpi(sMontage.Type, 'text')
        % Get text from the editor
        strText = char(ctrl.jTextMontage.getText());
        % Add montage name
        strText = [sMontage.Name, 10, strText];
        % Convert to montage structure
        sMontage = in_montage_mon(strText);
    end
    % Save updated montage
    SetMontage(MontageName, sMontage);
end


%% ===== EDIT SELECTIONS =====
% USAGE:  EditMontages(hFig)
%         EditMontages()
function EditMontages(hFig)
    % No specific figure
    if (nargin < 1)
        hFig = [];
    end
    % Display edition panel
    gui_show('panel_montage', 'JavaWindow', 'Montage editor', [], 0, 1, 0);
    % Load montages for figure
    LoadFigure(hFig);
end

%% ===== NEW MONTAGE =====
function newName = NewMontage(MontageType, ChanNames, hFig)
    % Parse inputs
    if (nargin < 3) || isempty(hFig)
        hFig = [];
    end
    % Ask user the name for the new montage
    newName = java_dialog('input', 'New montage name:', 'New montage');
    if isempty(newName)
        return;
    elseif ~isempty(GetMontage(newName, hFig))
        bst_error('This montage name already exists.', 'New montage', 0);
        newName = [];
        return
    end
    % Make sure Channels is a cell list of strings
    if isempty(ChanNames) || ~iscell(ChanNames)
        ChanNames = {};
    end
    % Create new montage structure
    sMontage = db_template('Montage');
    sMontage.Name      = newName;
    sMontage.Type      = MontageType;
    sMontage.ChanNames = ChanNames;
    sMontage.DispNames = ChanNames;
    sMontage.Matrix    = eye(length(ChanNames));
    % Save new montage
    SetMontage(newName, sMontage);
    % Update panel
    if ~isempty(hFig)
        % Get panel controls handles
        ctrl = bst_get('PanelControls', 'EditMontages');
        % If the panel is available: update it
        if ~isempty(ctrl)
            % Update montages list
            UpdateMontagesList(hFig);
            % Select last element in list
            iNewInd = ctrl.jListMontages.getModel().getSize() - 1;
            ctrl.jListMontages.setSelectedIndex(iNewInd);
            % Update channels selection
            UpdateEditor(hFig);
        end
        % Reset selection
        bst_figures('SetSelectedRows', []);
    end
end


%% =================================================================================
%  === CORE FUNCTIONS ==============================================================
%  =================================================================================

%% ===== LOAD DEFAULT MONTAGES ======
function LoadDefaultMontages() %#ok<DEFNU>
    % Set average reference montage
    sMontage = db_template('Montage');
    sMontage.Name = 'Average reference';
    sMontage.Type = 'matrix';
    SetMontage(sMontage.Name, sMontage);
    % Get the path to the default .sel/.mon files
    MontagePath = bst_fullfile(bst_get('BrainstormHomeDir'), 'toolbox', 'sensors', 'private');    
    % Load MNE selection files
    MontageFiles = dir(bst_fullfile(MontagePath, '*.sel'));
    for i = 1:length(MontageFiles)
        LoadMontageFile(bst_fullfile(MontagePath, MontageFiles(i).name), 'MNE');
    end
    % Load Brainstorm EEG montage files
    MontageFiles = dir(bst_fullfile(MontagePath, '*.mon'));
    for i = 1:length(MontageFiles)
        LoadMontageFile(bst_fullfile(MontagePath, MontageFiles(i).name), 'MON');
    end
end
   

%% ===== GET MONTAGE ======
function [sMontage, iMontage] = GetMontage(MontageName, hFig)
    global GlobalData;
    % Parse inputs
    if (nargin < 2) || isempty(hFig)
        hFig = [];
    end
    % If no montage defined
    if isempty(GlobalData.ChannelMontages.Montages)
        sMontage = [];
        iMontage = [];
    % Else: Look for required montage in loaded list
    else
        % Find montage in valid list of montages
        if ~isempty(MontageName)
            iMontage = find(strcmpi({GlobalData.ChannelMontages.Montages.Name}, MontageName));
        else
            iMontage = 1:length(GlobalData.ChannelMontages.Montages);
        end
        % If montage is found
        if ~isempty(iMontage)
            sMontage = GlobalData.ChannelMontages.Montages(iMontage);
            % Find average reference montage
            iAvgRef = find(strcmpi({sMontage.Name}, 'Average reference'));
            if ~isempty(iAvgRef)
                if ~isempty(hFig)
                    [sTmp, iTmp] = GetMontageAvgRef(hFig);
                    if ~isempty(sTmp)
                        sMontage(iAvgRef) = sTmp;
                        iMontage(iAvgRef) = iTmp;
                    end
                else
                    %disp('BST> Warning: Cannot expand average reference montage...');
                end
            end
        else
            sMontage = [];
        end
    end
end

%% ===== SET MONTAGE ======
% USAGE:  SetMontage(MontageName, ChanNames, isOverwrite=1)
%         SetMontage(MontageName, sMontage, isOverwrite=1)
function MontageName = SetMontage(MontageName, sMontage, isOverwrite)
    global GlobalData;
    % Parse inputs
    if (nargin < 3) || isempty(isOverwrite)
        isOverwrite = 1;
    end
    % Input is a list of channel names
    if iscell(sMontage)
        ChanNames = sMontage;
        % Remove all the spaces in channels names
        ChanNames = cellfun(@(c)c(c~=' '), ChanNames, 'UniformOutput', 0);
        % Create new structure
        sMontage = db_template('Montage');
        sMontage.Name      = MontageName;
        sMontage.Type      = 'selection';
        sMontage.ChanNames = ChanNames;
        sMontage.DispNames = ChanNames;
        sMontage.Matrix    = eye(length(ChanNames));
    end
    % If list of montages is still empty
    if isempty(GlobalData.ChannelMontages.Montages)
        GlobalData.ChannelMontages.Montages = sMontage;
    else
        % Try to get an existing montage
        [tmp__, iMontage] = GetMontage(MontageName);
        % If montage already exists, but we don't want to overwrite it: create a unique name
        if ~isempty(iMontage) && ~isOverwrite
            MontageName = file_unique(MontageName, {GlobalData.ChannelMontages.Montages.Name});
            sMontage.Name = MontageName;
            iMontage = [];
        end
        % If no existing montage, append new montage at the end of the list
        if isempty(iMontage)
            iMontage = length(GlobalData.ChannelMontages.Montages) + 1;
        end
        % Save montage
        GlobalData.ChannelMontages.Montages(iMontage) = sMontage;
    end
end

%% ===== GET CURRENT MONTAGE ======
% USAGE:  sMontage = GetCurrentMontage(hFig)
%         sMontage = GetCurrentMontage(Modality)
function sMontage = GetCurrentMontage(hFig)
    global GlobalData;
    sMontage = [];
    % Get modality
    if (nargin < 1) || isempty(hFig)
        disp('BST> Error: Invalid call to GetCurrentMontage()');
        return;
    elseif ischar(hFig)
        Modality = hFig;
        hFig = [];
    else
        % Get modality
        TsInfo = getappdata(hFig, 'TsInfo');
        if isempty(TsInfo) || isempty(TsInfo.Modality)
            disp('BST> Error: Invalid figure for GetCurrentMontage()');
            return;
        end
        Modality = TsInfo.Modality;
    end
    % Storage field 
    FieldName = ['mod_' lower(file_standardize(Modality))];
    % Check that this category exists
    if ~isfield(GlobalData.ChannelMontages.CurrentMontage, FieldName)
        % disp(['BST> Error: Invalid modality "' Modality '"']);
        return;
    end
    % Get current montage name
    MontageName = GlobalData.ChannelMontages.CurrentMontage.(FieldName);
    % Get current montage definition
    if ~isempty(MontageName)
        sMontage = GetMontage(MontageName, hFig);
    end
end

%% ===== DELETE MONTAGE =====
function DeleteMontage(MontageName)
    global GlobalData;
    % Get montage index
    [sMontage, iMontage] = GetMontage(MontageName);
    % Remove montage if it exists
    if ~isempty(iMontage)
        GlobalData.ChannelMontages.Montages(iMontage) = [];
    end
    % Check if is the current montage
    for structField = fieldnames(GlobalData.ChannelMontages.CurrentMontage)'
        if strcmpi(GlobalData.ChannelMontages.CurrentMontage.(structField{1}), sMontage.Name)
            GlobalData.ChannelMontages.CurrentMontage.(structField{1}) = sMontage.Name;
        end
    end
end

%% ===== GET MONTAGES FOR FIGURE =====
function [sMontage, iMontage] = GetMontagesForFigure(hFig)
    global GlobalData;
    sMontage = [];
    iMontage = [];
    % If no available montages: return
    if isempty(GlobalData.ChannelMontages.Montages)
        return
    end
    % If menu is designed to fit a specific figure: get only the ones that fits to this figure
    if ~isempty(hFig)
        % Get figure description
        [hFig, iFig, iDS] = bst_figures('GetFigure', hFig);
        % Get channels displayed in this figure
        iFigChannels = GlobalData.DataSet(iDS).Figure(iFig).SelectedChannels;
        FigChannels = {GlobalData.DataSet(iDS).Channel(iFigChannels).Name};
        FigId = GlobalData.DataSet(iDS).Figure(iFig).Id;
        isStat = strcmpi(GlobalData.DataSet(iDS).Measures.DataType, 'stat');
        % Remove all the spaces
        FigChannels = cellfun(@(c)c(c~=' '), FigChannels, 'UniformOutput', 0);
        % Get the predefined montages that match this list of channels
        iMontage = [];
        for i = 1:length(GlobalData.ChannelMontages.Montages)
            % Topography figures: Skip "selection" montage types
            if strcmpi(FigId.Type, 'Topography') && strcmpi(GlobalData.ChannelMontages.Montages(i).Type, 'selection')
                continue;
            end
            % Stat figures: Skip "text" and "matrix" montage types
            if isStat && ~strcmpi(GlobalData.ChannelMontages.Montages(i).Type, 'selection')
                continue;
            end
            % Not EEG: Skip average reference
            if strcmpi(GlobalData.ChannelMontages.Montages(i).Name, 'Average reference') && ~isempty(FigId.Modality) && ~ismember(FigId.Modality, {'EEG','SEEG','ECOG'})
                continue
            end
            % Skip montages that have no common channels with the current figure
            curSelChannels = GlobalData.ChannelMontages.Montages(i).ChanNames;
            if ~isempty(curSelChannels) && isempty(intersect(curSelChannels, FigChannels))
                continue;
            end
            % Add montage
            iMontage(end+1) = i;
        end
    % Else: get all the montages
    else
        iMontage = 1:length(GlobalData.ChannelMontages.Montages);
    end
    % Return montages
    sMontage = GlobalData.ChannelMontages.Montages(iMontage);
end

%% ===== GET MONTAGE CHANNELS =====
% Find a list of channels in a target montage
function [iChannels, iMatrixChan, iMatrixDisp] = GetMontageChannels(sMontage, ChanNames) %#ok<DEFNU>
    % Initialize returned variables
    iChannels = [];
    iMatrixChan = [];
    iMatrixDisp = [];
    % No montage: no selection
    if isempty(sMontage)
        return;
    end
    % Get target channels in this montage
    if ~isempty(sMontage) && ~isempty(sMontage.ChanNames)
        % Remove all the spaces
        sMontage.ChanNames = cellfun(@(c)c(c~=' '), sMontage.ChanNames, 'UniformOutput', 0);
        ChanNames          = cellfun(@(c)c(c~=' '), ChanNames,          'UniformOutput', 0);
        % Look for each of these selected channels in the list of loaded channels
        for i = 1:length(sMontage.ChanNames)
            iTmp = find(strcmpi(sMontage.ChanNames{i}, ChanNames));
            % If channel was found: add it to the display list
            if ~isempty(iTmp)
                iChannels(end+1) = iTmp;
                iMatrixChan(end+1) = i;
            end
        end
        % Get the display rows that we can display with these input channels
        if ~isempty(iChannels)
            sumDisp = sum(sMontage.Matrix(:,iMatrixChan) ~= 0, 2);
            sumTotal = sum(sMontage.Matrix ~= 0,2);
            iMatrixDisp = find((sumDisp == sumTotal) | (sumDisp >= 4));
        end
    end
end

%% ===== GET AVERAGE REF MONTAGE =====
% USAGE:  [sMontage, iMontage] = GetMontageAvgRef(hFig)
%         [sMontage, iMontage] = GetMontageAvgRef(Channels, ChannelFlag)
function [sMontage, iMontage] = GetMontageAvgRef(Channels, ChannelFlag)
    global GlobalData;
    sMontage = [];
    iMontage = [];
    % Get info from figure
    if (nargin == 1)
        hFig = Channels;
        % Create EEG average reference menus
        TsInfo = getappdata(hFig,'TsInfo');
        if isempty(TsInfo.Modality) || ~ismember(TsInfo.Modality, {'EEG','SEEG','ECOG'})
            return;
        end
        % Get figure description
        [hFig, iFig, iDS] = bst_figures('GetFigure', hFig);
        % Get selected channels
        iChannels = GlobalData.DataSet(iDS).Figure(iFig).SelectedChannels;
        Channels = GlobalData.DataSet(iDS).Channel(iChannels);
        ChannelFlag = GlobalData.DataSet(iDS).Measures.ChannelFlag(iChannels);
    else
        iChannels = 1:length(Channels);
    end
    % Set montage structure
    iMontage = find(strcmpi({GlobalData.ChannelMontages.Montages.Name}, 'Average reference'), 1);
    if ~isempty(iMontage)
        sMontage = GlobalData.ChannelMontages.Montages(iMontage);
        sMontage.DispNames = {Channels.Name};
        sMontage.ChanNames = {Channels.Name};
        sMontage.Matrix    = eye(length(iChannels));
        % Get EEG channels
        [iEEG, GroupNames] = GetEegGroups(Channels, ChannelFlag);
        % Computation
        for i = 1:length(iEEG)
            nChan = length(iEEG{i});
            if (nChan >= 2)
                sMontage.Matrix(iEEG{i},iEEG{i}) = eye(nChan) - ones(nChan) ./ nChan;
            end
        end
    end
end


%% ===== SET CURRENT MONTAGE ======
% USAGE:  SetCurrentMontage(Modality, MontageName)
%         SetCurrentMontage(hFig,     MontageName)
function SetCurrentMontage(Modality, MontageName)
    global GlobalData;
    % Get modality
    if (nargin < 2) || isempty(Modality)
        disp('BST> Error: Invalid call to SetCurrentMontage()');
        return;
    elseif isnumeric(Modality)
        hFig = Modality;
        TsInfo = getappdata(hFig, 'TsInfo');
        if isempty(TsInfo) || isempty(TsInfo.Modality)
            disp('BST> Error: Invalid figure for SetCurrentMontage()');
            return;
        end
        Modality = TsInfo.Modality;
    else
        hFig = [];
    end
    % Storage field 
    FieldName = ['mod_' lower(file_standardize(Modality))];
    % Update default montage
    GlobalData.ChannelMontages.CurrentMontage.(FieldName) = MontageName;
    % Update figure
    if ~isempty(hFig)
        bst_progress('start', 'Montage selection', 'Updating figures...');
        % Update config structure
        TsInfo = getappdata(hFig, 'TsInfo');
        TsInfo.MontageName = MontageName;
        setappdata(hFig, 'TsInfo', TsInfo);
        % Update panel Recorf
        panel_record('UpdateDisplayOptions', hFig);
        % Update figure plot
        bst_figures('ReloadFigures', hFig);
        % Close progress bar
        bst_progress('stop');
    end
end

%% ===== CREATE POPUP MENU ======
function CreateFigurePopupMenu(jMenu, hFig) %#ok<DEFNU>
    import java.awt.event.*;
    import javax.swing.*;
    import java.awt.*;

    % Remove all previous menus
    jMenu.removeAll();
    % Get montages
    sFigMontages = GetMontagesForFigure(hFig);
    % Get current montage
    TsInfo = getappdata(hFig, 'TsInfo');
    
    % MENU: Edit montages
    gui_component('MenuItem', jMenu, [], 'Edit montages...', [], [], @(h,ev)EditMontages(hFig));
    % MENU: Create from mouse selection
    SelChannels = figure_timeseries('GetFigSelectedRows', hFig);
    if ~isempty(hFig) && ~isempty(SelChannels)
        gui_component('MenuItem', jMenu, [], 'Create from selection', [], [], @(h,ev)NewMontage('selection', SelChannels, hFig));
    end
    jMenu.addSeparator();

    % MENU: All channels
    jItem = gui_component('CheckBoxMenuItem', jMenu, [], 'All channels', [], [], @(h,ev)SetCurrentMontage(hFig, []));
    jItem.setSelected(isempty(TsInfo.MontageName));
    jItem.setAccelerator(KeyStroke.getKeyStroke(int32(KeyEvent.VK_A), KeyEvent.SHIFT_MASK));
    % MENUS: List of available montages
    for i = 1:length(sFigMontages)
        % Is it the selected one
        if ~isempty(TsInfo.MontageName)
            isSelected = strcmpi(sFigMontages(i).Name, TsInfo.MontageName);
        else
            isSelected = 0;
        end
        % Create menu
        jItem = gui_component('CheckBoxMenuItem', jMenu, [], sFigMontages(i).Name, [], [], @(h,ev)SetCurrentMontage(hFig, sFigMontages(i).Name));
        jItem.setSelected(isSelected);
        if (i <= 25)
            jItem.setAccelerator(KeyStroke.getKeyStroke(int32(KeyEvent.VK_A + i), KeyEvent.SHIFT_MASK));
        end
    end
    drawnow;
    jMenu.repaint();
end

%% ===== CREATE MONTAGE MENU =====
function CreateMontageMenu(jButton, hFig)
    import org.brainstorm.icon.*;
    % Create popup menu
    jPopup = java_create('javax.swing.JPopupMenu');
    % Get figure info
    if ~isempty(hFig)
        TsInfo = getappdata(hFig, 'TsInfo');
    end
    % Create new montages
    if isempty(hFig) || ~strcmpi(TsInfo.DisplayMode, 'topography')
        gui_component('MenuItem', jPopup, [], 'New channel selection', IconLoader.ICON_EEG_NEW, [], @(h,ev)NewMontage('selection', [], hFig), []);
    end
    gui_component('MenuItem', jPopup, [], 'New custom montage', IconLoader.ICON_EEG_NEW, [], @(h,ev)NewMontage('text', [], hFig), []);
    jPopup.addSeparator();
    gui_component('MenuItem', jPopup, [], 'Duplicate montage', IconLoader.ICON_COPY, [], @(h,ev)ButtonDuplicate_Callback(hFig), []);
    gui_component('MenuItem', jPopup, [], 'Rename montage', IconLoader.ICON_EDIT, [], @(h,ev)ButtonRename_Callback(hFig), []);
    gui_component('MenuItem', jPopup, [], 'Delete montage', IconLoader.ICON_DELETE, [], @(h,ev)ButtonDelete_Callback(hFig), []);
    % Show popup menu
    jPopup.show(jButton, 0, jButton.getHeight());
end

%% ===== RENAME MONTAGE =====
function newName = RenameMontage(oldName, newName)
    global GlobalData;
    % Look for existing montage
    [sMontage, iMontage] = GetMontage(oldName);
    % If montage does not exist
    if isempty(sMontage)
        error('Condition does not exist.');
    end
    % If new name was not provided: Ask the user
    if (nargin < 2) || isempty(newName)
        newName = java_dialog('input', 'Enter a new name for this montage:', 'Rename montage', [], oldName);
        if isempty(newName)
            return;
        elseif ~isempty(GetMontage(newName))
            bst_error('This montage name already exists.', 'Rename montage', 0);
            newName = [];
            return
        end
    end
    % Rename montage
    GlobalData.ChannelMontages.Montages(iMontage).Name = newName;
end


%% ===== PROCESS KEYPRESS =====
function isProcessed = ProcessKeyPress(hFig, Key) %#ok<DEFNU>
    isProcessed = 0;
    % Get montages for the figure
    sMontages = GetMontagesForFigure(hFig);
    if isempty(sMontages)
        return
    end
    % Accept only alphabetical chars
    Key = uint8(lower(Key));
    if (length(Key) ~= 1) || (Key < uint8('a')) || (Key > uint8('z'))
        return
    end
    % Get the selection indicated by the key
    iSel = Key - uint8('a');
    if (iSel > length(sMontages))
        return
    elseif (iSel == 0)
        newName = [];
    else
        newName = sMontages(iSel).Name;
    end
    % Process key pressed: switch to new montage
    SetCurrentMontage(hFig, newName);
    isProcessed = 1;
end


%% ===== LOAD MONTAGE FILE =====
% USAGE:  LoadMontageFile(FileName, FileFormat)
%         LoadMontageFile()   : Ask user the file to load
function sMontages = LoadMontageFile(FileName, FileFormat)
    sMontages = [];
    % Ask filename to user
    if (nargin < 2) || isempty(FileName) || isempty(FileFormat)
        DefaultDir = bst_fullfile(bst_get('BrainstormHomeDir'), 'toolbox', 'sensors', 'private');
        [FileName, FileFormat] = java_getfile( 'open', 'Import MNE selections file', DefaultDir, 'single', 'files', ...
            {{'.sel'},     'MNE selection files (*.sel)',              'MNE'; ...
             {'.mon'},     'Text montage files (*.mon)',               'MON'; ...
             {'_montage'}, 'Brainstorm montage files (montage_*.mat)', 'BST'}, 2);
        if isempty(FileName)
            return
        end
    end
    % Load file
    switch (FileFormat)
        case 'MNE'
            sMontages = in_montage_mne(FileName);
        case 'MON'
            sMontages = in_montage_mon(FileName);
        case 'BST'
            DataMat = load(FileName);
            sMontages = DataMat.Montages;
    end
    % If file was not read: return
    if isempty(sMontages) || ~isequal(fieldnames(sMontages), fieldnames(db_template('Montage')))
        return
    end
    % Loop to add all montages 
    for i = 1:length(sMontages)
        sMontages(i).Name = SetMontage(sMontages(i).Name, sMontages(i), 0);
    end
end


%% ===== SAVE MONTAGE FILE =====
% USAGE:  SaveMontageFile(sMontages, FileName, FileFormat)
%         SaveMontageFile(sMontages)           : Ask user the file to be loaded
function SaveMontageFile(sMontages, FileName, FileFormat)
    % Ask filename to user
    if (nargin < 3) || isempty(FileName)
        DefaultFile = [file_standardize(sMontages(1).Name), '.mon'];
        [FileName, FileFormat] = java_getfile( 'save', 'Export MNE selections file', DefaultFile, 'single', 'files', ...
            {{'.sel'},     'MNE selection files (*.sel)',              'MNE'; ...
             {'.mon'},     'Text montage files (*.mon)',               'MON'; ...
             {'_montage'}, 'Brainstorm montage files (montage_*.mat)', 'BST'}, 2);
        if isempty(FileName)
            return
        end
    end
    % Save file
    switch (FileFormat)
        case 'MNE'
            out_montage_mne(FileName, sMontages);
        case 'MON'
            if (length(sMontages) > 1)
                error('Cannot save more than one montage per file.');
            end
            out_montage_mon(FileName, sMontages);
        case 'BST'
            DataMat.Montages = sMontages;
            bst_save(FileName, DataMat, 'v6');
    end    
end


%% ===== GET EEG GROUPS =====
function [iEEG, GroupNames] = GetEegGroups(Channel, ChannelFlag)
%     % All the EEG channels = one block
%     iEEG = {good_channel(Channel, ChannelFlag, 'EEG')};
%     GroupNames = {'EEG'};
    GroupNames = {};
    iEEG = {};
    % Try to split SEEG and ECOG with the Comment field
    for Modality = {'EEG', 'SEEG', 'ECOG'}
        % Get channels for modality
        iMod = good_channel(Channel, ChannelFlag, Modality{1});
        if isempty(iMod)
            continue;
        end
        % Get all comments
        AllComments = unique({Channel(iMod).Comment});
        % If not all the sensors have a group defined in the Comments
        if any(ismember({'', 'AVERAGE REF'}, AllComments)) || (length(AllComments) == 1)
            % All the channels = one block
            iEEG{end+1}  = iMod;
            GroupNames{end+1} = Modality{1};
        % If all the electrodes are part of a group: split in groups
        else
            for iGroup = 1:length(AllComments)
                iEEG{end+1}  = iMod(find(strcmp({Channel(iMod).Comment}, AllComments{iGroup})));
                GroupNames{end+1} = AllComments{iGroup};
            end
        end
    end
    % If there is more that one: display a message
    if (length(GroupNames) > 2)
        strNames = '';
        for i = 1:length(GroupNames)
            strNames = [strNames GroupNames{i} ', '];
        end
        disp(['BST> Groups of electrodes processed separately:  ' strNames(1:end-2)]);
    end
end


%% ===== SHOW EDITOR =====
function ShowEditor() %#ok<DEFNU>
    gui_show('panel_montage', 'JavaWindow', 'Montage editor', [], 0, 1, 0);
    UpdateMontagesList([]);
end



