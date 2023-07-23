function varargout = panel_ssp_selection(varargin)
% PANEL_SSP_SELECTION: Select active SSP.
%
% USAGE:  panel_ssp_selection('OpenRaw')

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
% Authors: Francois Tadel, 2012-2013

macro_methodcall;
end


%% ===== CREATE PANEL =====
function [bstPanelNew, panelName] = CreatePanel() %#ok<DEFNU>
    % Java initializations
    import java.awt.*;
    import javax.swing.*;
    import org.brainstorm.icon.*;
    import org.brainstorm.list.*;
    panelName = 'EditSsp';
    
    % Create main panel
    jPanelNew = gui_component('Panel');
    jPanelNew.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));
    
    % PANEL: left panel (list of available categories)
    jPanelCat = gui_component('Panel');
    jPanelCat.setBorder(BorderFactory.createCompoundBorder(...
                        BorderFactory.createTitledBorder('Projector categories'), ...
                        BorderFactory.createEmptyBorder(3, 10, 10, 10)));
        % ===== TOOLBAR =====
        jToolbar = gui_component('Toolbar', jPanelCat, BorderLayout.NORTH);
        jToolbar.setPreferredSize(Dimension(100,25));
            TB_SIZE = Dimension(25,25);
            gui_component('ToolbarButton', jToolbar, [], [], {IconLoader.ICON_FOLDER_OPEN, TB_SIZE}, 'Load projectors', @(h,ev)bst_call(@ButtonLoadFile_Callback));
            gui_component('ToolbarButton', jToolbar, [], [], {IconLoader.ICON_SAVE, TB_SIZE}, 'Save active projectors', @(h,ev)bst_call(@ButtonSaveFile_Callback));
            jToolbar.addSeparator();
            gui_component('ToolbarButton', jToolbar, [], [], {IconLoader.ICON_EDIT, TB_SIZE},   'Rename category', @(h,ev)bst_call(@ButtonRename_Callback));
            gui_component('ToolbarButton', jToolbar, [], [], {IconLoader.ICON_DELETE, TB_SIZE}, 'Delete category', @(h,ev)bst_call(@ButtonDelete_Callback));
            jToolbar.addSeparator();
            gui_component('ToolbarButton', jToolbar, [], [], {IconLoader.ICON_TOPOGRAPHY, TB_SIZE}, 'Display component topography', @(h,ev)bst_call(@(h,ev)ButtonCompTopo_Callback([])));
            jButtonNoInterp = gui_component('ToolbarButton', jToolbar, [], 'No interp', IconLoader.ICON_TOPOGRAPHY, 'Display component topography [No magnetic interpolation]', @(h,ev)bst_call(@(h,ev)ButtonCompTopo_Callback(0)));
            
        % LIST: Create list
        jListCat = JList([BstListItem('', '', 'Projector 1', int32(0)), BstListItem('', '', 'Projector 2', int32(1))]);
            jListCat.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
            jListCat.setCellRenderer(BstCheckListRenderer());
            java_setcb(jListCat, 'MouseClickedCallback', @ListCatClick_Callback, ...
                                 'KeyTypedCallback',     @ListCatKey_Callback, ...
                                 'ValueChangedCallback', []);
            % Create scroll panel
            jScrollPanelCat = JScrollPane(jListCat);
            jScrollPanelCat.setPreferredSize(Dimension(220,200));
        jPanelCat.add(jScrollPanelCat, BorderLayout.CENTER);
    jPanelNew.add(jPanelCat, BorderLayout.WEST);
    
    % PANEL: right panel (sensors list)
    jPanelRight = gui_component('Panel');
    jPanelComp = gui_component('Panel');
    jPanelComp.setBorder(BorderFactory.createCompoundBorder(...
                            BorderFactory.createTitledBorder('Projector components'), ...
                            BorderFactory.createEmptyBorder(10, 10, 10, 10)));
        % LABEL: Title
        jPanelComp.add(JLabel('<HTML><DIV style="height:15px;">Available components:</DIV>'), BorderLayout.NORTH);
        % LIST: Create list (display labels of all clusters)
        jListComp = JList([BstListItem('', '', 'Component 1', int32(0)), BstListItem('', '', 'Component 2', int32(1))]);
            %jListComp.setVisibleRowCount(-1);
            %jListComp.setSelectionMode(ListSelectionModel.MULTIPLE_INTERVAL_SELECTION);
            %jListComp.setLayoutOrientation(jListComp.VERTICAL_WRAP);
            jListComp.setCellRenderer(BstCheckListRenderer());
            java_setcb(jListComp, 'MouseClickedCallback', @ListCompClick_Callback);
            % Create scroll panel
            jScrollPanelComp = JScrollPane(jListComp);
            jScrollPanelComp.setPreferredSize(Dimension(180,200));
        jPanelComp.add(jScrollPanelComp, BorderLayout.CENTER);
    jPanelRight.add(jPanelComp, BorderLayout.CENTER);
    % PANEL: Selections buttons
    jPanelValidation = gui_river([10 0], [10 10 0 10]);
        % Cancel
        jButtonCancel = JButton('Cancel');
        java_setcb(jButtonCancel, 'ActionPerformedCallback', @ButtonCancel_Callback);
        jPanelValidation.add('br right', jButtonCancel);
        % Save
        jButtonSave = JButton('Save');
        java_setcb(jButtonSave, 'ActionPerformedCallback', @ButtonSave_Callback);
        jPanelValidation.add(jButtonSave);
    jPanelRight.add(jPanelValidation, BorderLayout.SOUTH);
    jPanelNew.add(jPanelRight, BorderLayout.CENTER);
    
    % Create the BstPanel object that is returned by the function
    % => constructor BstPanel(jHandle, panelName, sControls)
    bstPanelNew = BstPanel(panelName, ...
                           jPanelNew, ...
                           struct('jListCat',         jListCat, ...
                                  'jListComp',        jListComp, ...
                                  'jButtonNoInterp',  jButtonNoInterp));

                              
%% =================================================================================
%  === CONTROLS CALLBACKS  =========================================================
%  =================================================================================
    %% ===== VALIDATION BUTTONS =====
    function ButtonCancel_Callback(varargin)
        % Close panel without saving
        gui_hide(panelName);
    end
    function ButtonSave_Callback(varargin)
        global EditSspPanel;
        % Mark that modifications have to be saved permanently
        EditSspPanel.isSave = 1;
        % Close panel
        gui_hide(panelName);
    end

    %% ===== LISTS CLICKS =====
    function ListCatClick_Callback(h,ev)
        global EditSspPanel;
        % Double-click
        if (ev.getClickCount() == 2)
            ButtonRename_Callback();
        % Single click
        else
            % Toggle checkbox status
            [iCat, Status] = ToggleCheck(ev);
            if (Status == 2)
                return
            end
            % Propagate changes
            if ~isempty(iCat)
                % Update loaded structure
                EditSspPanel.Projector(iCat).Status = Status;
                % Update displays
                if EditSspPanel.isRaw
                    UpdateRaw();
                end
                % Update components list
                UpdateComp();
            end
        end
    end
    function ListCompClick_Callback(h,ev)
        global EditSspPanel;
        % Toggle checkbox status
        [iComp,Status] = ToggleCheck(ev);
        if (Status == 2)
            return
        end
        % Get selected catgory
        [sCat,iCat] = GetSelectedCat();
        % Propagate changes
        if ~isempty(iCat) && ~isempty(iComp)
            % Update loaded structure
            EditSspPanel.Projector(iCat).CompMask(iComp) = Status;
            % Update displays
            if EditSspPanel.isRaw
                UpdateRaw();
            end
        end
    end
    % Toggle checkbox status
    function [i, newStatus] = ToggleCheck(ev)
        i = [];
        newStatus = [];
        % Ignore all the clicks if the JList is disabled
        if ~ev.getSource().isEnabled()
            return
        end
        % Only consider that it was selected if it was clicked next to the left of the component
        if (ev.getPoint().getX() > 17)
            return;
        end
        % Get selected element
        jList = ev.getSource();
        i    = jList.locationToIndex(ev.getPoint());
        item = jList.getModel().getElementAt(i);
        status = item.getUserData();
        % Process click (0:Not selected, 1:Selected, 2:Forced selected)
        switch(status)
            case 0,  newStatus = 1;
            case 1,  newStatus = 0;
            case 2,  newStatus = 2;
        end
        item.setUserData(int32(newStatus));
        jList.repaint(jList.getCellBounds(i, i));
        % Convert index to 1-based
        i = i + 1;
    end

    %% ===== LIST: KEY TYPED CALLBACK =====
    function ListCatKey_Callback(h, ev)
        switch(uint8(ev.getKeyChar()))
            case ev.VK_DELETE
                ButtonDelete_Callback();
        end
    end
end


%% =================================================================================
%  === INTERFACE CALLBACKS =========================================================
%  =================================================================================
%% ===== CLOSING CALLBACK =====
function PanelHidingCallback(varargin) %#ok<DEFNU>
    global GlobalData EditSspPanel;
    % If there were modifications, process them
    if ~isequal(EditSspPanel.Projector, EditSspPanel.InitProjector)
        % Save modifications
        if EditSspPanel.isSave
            % Save modifications to channel file
            ChannelMat.Projector = EditSspPanel.Projector;
            ChannelFileFull = file_fullpath(GlobalData.DataSet(EditSspPanel.iDS).ChannelFile);
            bst_save(ChannelFileFull, ChannelMat, 'v7', 1);
            % Save modifications to sFile structure (DataMat.F)
            if EditSspPanel.isRaw
                GlobalData.DataSet(EditSspPanel.iDS).Measures.sFile.channelmat.Projector = EditSspPanel.Projector;
                panel_record('SaveModifications', EditSspPanel.iDS);
            end
        % Cancel modifications
        else
            % Restore initial projectors
            EditSspPanel.Projector = EditSspPanel.InitProjector;
            % Propagate
            if EditSspPanel.isRaw
                UpdateRaw();
            end
        end
    end
    % Reset field
    EditSspPanel = [];
end

%% ===== LISTS SELECTION CHANGE =====
function ListCatSelectionChange_Callback(hObj, ev)
    if ~ev.getValueIsAdjusting()
        UpdateComp();
    end
end

%% ===== BUTTON: DELETE =====
function ButtonDelete_Callback()
    global EditSspPanel;
    % Get selected category
    [sCat, iCat] = GetSelectedCat();
    if isempty(sCat) || (sCat.Status == 2)
        return
    end
    % Save new name
    EditSspPanel.Projector(iCat) = [];
    % Update changes
    UpdateCat();
    if EditSspPanel.isRaw
        UpdateRaw();
    end
end

%% ===== BUTTON: RENAME =====
function ButtonRename_Callback()
    global EditSspPanel;
    % Get selected category
    [sCat, iCat] = GetSelectedCat();
    if isempty(sCat)
        return
    end
    % Ask new label to the user
    newComment = java_dialog('input', 'Enter new projector comment:', 'Rename projectors', [], sCat.Comment);
    if isempty(newComment)
        return
    end
    % Save new name
    EditSspPanel.Projector(iCat).Comment = newComment;
    % Update changes
    UpdateCat();
end

%% ===== BUTTON: LOAD PROJECTORS =====
function ButtonLoadFile_Callback()
    global EditSspPanel;
    % Load projectors
    newProj = import_ssp(EditSspPanel.ChannelFile, [], 0, 0);
    if isempty(newProj)
        return
    end
    % Save new name
    if isempty(EditSspPanel.Projector)
        EditSspPanel.Projector = newProj;
    else
        % Check number of sensors for new projectors
        for i = 1:length(newProj)
            nNew = size(newProj(i).Components,1);
            nOld = size(EditSspPanel.Projector(1).Components,1);
            if (nNew ~= nOld)
                bst_error(sprintf('Number of sensors in the loaded projectors (%d) do not match the other projectors (%d).', nNew, nOld), 'Load projectors', 0);
                return;
            end
        end
        % Add to existing list
        EditSspPanel.Projector = [EditSspPanel.Projector, newProj];
    end
    % Update changes
    UpdateCat();
    if EditSspPanel.isRaw
        UpdateRaw();
    end
end


%% ===== BUTTON: SAVE PROJECTORS =====
function ButtonSaveFile_Callback()
    global GlobalData EditSspPanel;
    % Nothing to save
    if isempty(EditSspPanel.iDS) || isempty(EditSspPanel.Projector)
        return;
    end
    % Get projectors to save
    %Projectors = GetSelectedCat();
    Projectors = EditSspPanel.Projector;
    if isempty(Projectors)
        bst_error('No selected projector', 'Save SSP projectors', 0);
        return;
    end
    % Build a default file name
    ProjFile = bst_process('GetNewFilename', '', 'proj.mat');
    [fPath,fBase,fExt] = bst_fileparts(ProjFile);
    ProjFile = [fBase,fExt];
    % Get filename where to store the filename
    [ProjFile, ProjFormat] = java_getfile('save', 'Save projectors', ProjFile, 'single', 'files', ...
                            {{'.fif'}, 'Neuromag/MNE (*.fif)',        'FIF'; ...
                            {'_proj'}, 'Brainstorm SSP (*proj*.mat)', 'BST'}, 2);
    if isempty(ProjFile)
        return;
    end
    % Save file
    switch (ProjFormat)
        case 'FIF'
            ChannelNames = {GlobalData.DataSet(EditSspPanel.iDS).Channel.Name};
            out_projector_fif(ProjFile, ChannelNames, Projectors);
        case 'BST'
            NewMat.Projector = Projectors;
            bst_save(ProjFile, NewMat, 'v7');
    end
end

%% ===== BUTTON: COMPONENT TOPOGRAPHY =====
function ButtonCompTopo_Callback(UseMagneticExtrap)
    global GlobalData EditSspPanel;
    % Get selected components
    [sCat, iCat, iComp] = GetSelectedCat();
    % If there is nothing to display, exit
    if isempty(iCat) || isempty(iComp)
        return;
    end
    % Get information to plot
    DataFile = GlobalData.DataSet(EditSspPanel.iDS).DataFile;
%     % Get modality from open figures
%     if ~isempty(GlobalData.DataSet(EditSspPanel.iDS).Figure) && ~isempty(GlobalData.DataSet(EditSspPanel.iDS).Figure(1).Id.Modality)
%         Modality = GlobalData.DataSet(EditSspPanel.iDS).Figure(1).Id.Modality;
%     else
%         [Mod, DispMod] = channel_get_modalities(GlobalData.DataSet(EditSspPanel.iDS).Channel);
%         if ~isempty(DispMod)
%             Modality = DispMod{1};
%         else
%             Modality = [];
%         end
%     end
    % Get modalities from projector
    allMod = unique({GlobalData.DataSet(EditSspPanel.iDS).Channel(any(sCat.Components,2)).Type});
    % Loop on all the modalities
    for i = 1:length(allMod)
        % Get sensors for this topography
        iChannels = good_channel(GlobalData.DataSet(EditSspPanel.iDS).Channel, GlobalData.DataSet(EditSspPanel.iDS).Measures.ChannelFlag, allMod{i});
        % Plot topography
        F = sCat.Components(iChannels, iComp);
        view_topography(DataFile, allMod{i}, [], F, UseMagneticExtrap, 1);
    end
end



%% =================================================================================
%  === HELPER FUNCTIONS ============================================================
%  =================================================================================

%% ===== GET SELECTED CATEGORY =====
function [sCat, iCat, iComp] = GetSelectedCat()
    global EditSspPanel;
    % Get panel controls handles
    ctrl = bst_get('PanelControls', 'EditSsp');
    % Get selected category
    iCat = ctrl.jListCat.getSelectedIndex() + 1;
    % If something is selected
    if (iCat >= 1) && ~isempty(EditSspPanel.Projector)
        sCat = EditSspPanel.Projector(iCat);
    else
        sCat = [];
        iCat = [];
    end
    % Get selected components
    if (nargout >= 3) && (length(iCat) == 1) && ~isempty(sCat.CompMask)
        %iComp = double(ctrl.jListComp.getSelectedIndices())' + 1;
        iComp = ctrl.jListComp.getSelectedIndex() + 1;
        if (iComp == 0)
            iComp = [];
        end
    else
        iComp = [];
    end
end


%% ===== OPEN INTERFACE FOR CURRENT RAW FILE =====
function OpenRaw() %#ok<DEFNU>
    global EditSspPanel;
    global GlobalData;
    % Get current raw dataset
    iDS = bst_memory('GetRawDataSet');
    if isempty(iDS)
        error('No continuous/raw dataset currently open.');
    end
    % Build structure of data needed by this panel
    EditSspPanel.iDS           = iDS;
    EditSspPanel.ChannelFile   = GlobalData.DataSet(EditSspPanel.iDS).ChannelFile;
    if isfield(GlobalData.DataSet(EditSspPanel.iDS).Measures.sFile, 'channelmat') && isfield(GlobalData.DataSet(EditSspPanel.iDS).Measures.sFile.channelmat, 'Projector')
        EditSspPanel.Projector = GlobalData.DataSet(EditSspPanel.iDS).Measures.sFile.channelmat.Projector;
    else
        EditSspPanel.Projector = repmat(db_template('projector'), 0);
    end
    EditSspPanel.InitProjector = EditSspPanel.Projector;
    EditSspPanel.isRaw         = 1;
    EditSspPanel.isSave        = 0;
    % Display panel
    [panelContainer, bstPanel] = gui_show('panel_ssp_selection', 'JavaWindow', 'Signal-space projections', [], 0, 1, 0);
    % Load current projectors
    UpdateCat();
    UpdateComp();
    % Get modalities from projector
    allMod = unique({GlobalData.DataSet(EditSspPanel.iDS).Channel.Type});
    % Enable or disable the "No interp" button
    if ~any(ismember({'MEG','MEG GRAD', 'MEG MAG'}, allMod))
        sControls = get(bstPanel, 'sControls');
        sControls.jButtonNoInterp.setVisible(0);
    end
end


%% ===== UPDATE PROJECTORS =====
function UpdateCat()
    import org.brainstorm.list.*;
    global EditSspPanel;
    % Get panel controls handles
    ctrl = bst_get('PanelControls', 'EditSsp');
    % Suspend callbacks
    java_setcb(ctrl.jListCat, 'ValueChangedCallback', @ListCatSelectionChange_Callback);
    % Create projector categories list
    listModel = javax.swing.DefaultListModel();
    for i = 1:length(EditSspPanel.Projector)
        listModel.addElement(BstListItem('', '', EditSspPanel.Projector(i).Comment, int32(EditSspPanel.Projector(i).Status)));
    end
    % Update JList
    ctrl.jListCat.setModel(listModel);
    ctrl.jListCat.repaint();
    % Select first element in the list
    if ~isempty(EditSspPanel.Projector)
        ctrl.jListCat.setSelectedIndex(0);
    end
    drawnow;
    % Restore callbacks
    java_setcb(ctrl.jListCat, 'ValueChangedCallback', @ListCatSelectionChange_Callback);
end


%% ===== UPDATE COMPONENTS =====
function UpdateComp()
    import org.brainstorm.list.*;
    % Get panel controls handles
    ctrl = bst_get('PanelControls', 'EditSsp');
    % Initialize new list
    listModel = javax.swing.DefaultListModel();
    % Get selected category
    [sCat, iCat] = GetSelectedCat();
    % If there is something selected: Add components
    if ~isempty(sCat)
        if (length(sCat.CompMask) > 1)
            % Get only the components that grab 95% of the signal
            Singular = sCat.SingVal ./ sum(sCat.SingVal);
            iDispComp = union(1, find(cumsum(Singular)<=.95));
            % Keep only the 30 first components
            iDispComp = intersect(iDispComp, 1:30);
            % Always show at least the 10 first components
            iDispComp = union(iDispComp, 1:10);
            % Add all the components
            for i = iDispComp
                strComp = sprintf('Component #%d', i);
                if ~isempty(sCat.SingVal)
                    strComp = [strComp, sprintf(' [%d%%]', round(100 * Singular(i)))];
                end
                listModel.addElement(BstListItem('', '', strComp, int32(sCat.CompMask(i))));
            end
        else
            listModel.addElement(BstListItem('', '', 'Single component', int32(2)));
        end
    end
    % Enable / disable JList
    isEnableComp = ~isempty(sCat) && (sCat.Status == 1);
    ctrl.jListComp.setEnabled(isEnableComp);
    % Update JList
    ctrl.jListComp.setModel(listModel);
    ctrl.jListComp.repaint();
end


%% ===== UPDATE LOADED RAW FILE =====
function UpdateRaw()
    global EditSspPanel;
    global GlobalData;
    % Get current raw dataset
    if isempty(EditSspPanel) || isempty(EditSspPanel.iDS) || ~EditSspPanel.isRaw
        return;
    end
    % Update loaded projectors
    GlobalData.DataSet(EditSspPanel.iDS).Measures.sFile.channelmat.Projector = EditSspPanel.Projector;
    % Reload windows
    panel_record('ReloadRecordings', 1);
end

