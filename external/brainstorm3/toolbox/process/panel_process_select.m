function varargout = panel_process_select(varargin)
% PANEL_PROCESS_SELECT: Creation and management of list of files to apply some batch proccess.
%
% USAGE:             bstPanelNew = panel_process_select('CreatePanel')
%         [sOutputs, sProcesses] = panel_process_select('ShowPanel', FileNames, ProcessNames, FileTimeVector)
%         [sOutputs, sProcesses] = panel_process_select('ShowPanel', FileNames, ProcessNames)
%                                  panel_process_select('ParseProcessFolder')

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
% Authors: Francois Tadel, 2010-2013

macro_methodcall;
end

%% ===== CREATE PANEL ===== 
function [bstPanel, panelName] = CreatePanel(sFiles, sFiles2, FileTimeVector)
    panelName = 'ProcessOne';
    % Java initializations
    import java.awt.*;
    import javax.swing.*;
    import org.brainstorm.list.*;
    import org.brainstorm.icon.*;
    % Global variable used by this panel
    global GlobalData;
    GlobalData.Processes.Current = [];

    % Parse inputs
    if (nargin < 3) || isempty(FileTimeVector)
        FileTimeVector = [];
    end
    if (nargin < 2) || isempty(sFiles2)
        nInputs = 1;
        nFiles = length(sFiles);
        sFiles2 = [];
    else
        nInputs = 2;
        nFiles = [length(sFiles), length(sFiles2)];
    end
    % Get initial type and subject
    InitialDataType = sFiles(1).FileType;
    InitialSubjectName = sFiles(1).SubjectName;

    % Progress bar
    bst_progress('start', 'Process', 'Initialization...');
    % Get time vector for the first file of the list
    if (sFiles(1).FileName)
        FileTimeVector = in_bst(sFiles(1).FileName, 'Time');
    elseif isempty(FileTimeVector)
        FileTimeVector = -500:0.001:500;
    end
    % Get channel names and types
    if ~isempty(sFiles(1).ChannelFile)
        ChannelMat = load(file_fullpath(sFiles(1).ChannelFile), 'Channel');
        ChannelNames = {ChannelMat.Channel.Name};
        ChannelNames(cellfun(@isempty, ChannelNames)) = [];
    else
        ChannelNames = {'No channel info'};
    end
    % Get all the subjects names
    ProtocolSubjects = bst_get('ProtocolSubjects');
    ProtocolInfo     = bst_get('ProtocolInfo');
    SubjectNames = {};
    iSelSubject = [];
    if ~isempty(ProtocolSubjects)
        SubjectNames = {ProtocolSubjects.Subject.Name};
        if ~isempty(ProtocolInfo.iStudy)
            sSelStudy = bst_get('Study', ProtocolInfo.iStudy);
            [sSelSubject, iSelSubject] = bst_get('Subject', sSelStudy.BrainStormSubject);
        end
    end
    
    % Reload processes
    panel_process_select('ParseProcessFolder');
    % Initialize list of current processes
    sProcesses = repmat(GlobalData.Processes.All, 0);
    % Progress bar
    bst_progress('stop');
    
    % Other initializations
    WarningMsg = '';
    LIST_ELEMENT_HEIGHT = 28;
    isUpdatingPipeline = 0;
    
    % Create main panel
    jPanelMain = java_create('javax.swing.JPanel');
    jPanelMain.setLayout(java_create('java.awt.GridBagLayout'));
    c = GridBagConstraints();
    c.fill = GridBagConstraints.BOTH;
    c.gridx = 1;
    c.weightx = 1;
    c.insets = Insets(3,5,3,5);
    
    % ===== PROCESS SELECTION =====
    jPanelProcess = gui_component('Panel');
    jPanelProcess.setBorder(BorderFactory.createTitledBorder('Process selection'));
    % Toolbar
    jToolbar = gui_component('Toolbar', jPanelProcess, BorderLayout.NORTH);
    jToolbar.setPreferredSize(Dimension(10, 25));
    jButtonAdd = gui_component('ToolbarButton', jToolbar, [], '', IconLoader.ICON_PROCESS_SELECT,    'Add process', @(h,ev)ShowProcessMenu('insert'), []);
    jToolbar.addSeparator();
    jButtonUp     = gui_component('ToolbarButton', jToolbar, [], '', IconLoader.ICON_ARROW_UP,       'Move process up', @(h,ev)MoveSelectedProcess('up'), []);
    jButtonDown   = gui_component('ToolbarButton', jToolbar, [], '', IconLoader.ICON_ARROW_DOWN,     'Move process down', @(h,ev)MoveSelectedProcess('down'), []);
    jButtonRemove = gui_component('ToolbarButton', jToolbar, [], '', IconLoader.ICON_DELETE,         'Delete process', @(h,ev)RemoveSelectedProcess(), []);
    jToolbar.addSeparator();
    jButtonPipeline = gui_component('ToolbarButton', jToolbar, [], '', IconLoader.ICON_PIPELINE_LIST, 'Load/save processing pipeline', @(h,ev)ShowPipelineMenu(ev.getSource()), []);
    jButtonWarning  = gui_component('ToolbarButton', jToolbar, [], 'Error', [], 'There are errors in the process pipeline.', @(h,ev)ShowWarningMsg(), []);
    % Set sizes
    dimLarge = Dimension(36,25);
    dimSmall = Dimension(25,25);
    %jButtonSelect.setMaximumSize(dimLarge);
    jButtonAdd.setMaximumSize(dimLarge);
    jButtonUp.setMaximumSize(dimSmall);
    jButtonDown.setMaximumSize(dimSmall);
    jButtonRemove.setMaximumSize(dimSmall);
    jButtonPipeline.setMaximumSize(dimLarge);
    jButtonWarning.setForeground(Color(.7, 0, 0));
    jButtonWarning.setVisible(0);
    % Process list
    jListProcess = java_create('javax.swing.JList');
    jListProcess.setSelectionMode(jListProcess.getSelectionModel().SINGLE_SELECTION);
    jListProcess.setCellRenderer(BstProcessListRenderer());
    java_setcb(jListProcess, 'ValueChangedCallback', @ListProcess_ValueChangedCallback, ...
                             'KeyTypedCallback',     @ListProcess_KeyTypedCallback);
    % Scroll panel
    jScrollProcess = JScrollPane(jListProcess);
    jScrollProcess.setBorder([]);
    jScrollProcess.setVisible(0);
    jPanelProcess.add(jScrollProcess);
    % Empty message
    jLabelEmpty = JLabel('      [Please select a process]');
    jLabelEmpty.setOpaque(1);
    jLabelEmpty.setBackground(Color(1,1,1));
    jLabelEmpty.setForeground(Color(.7,.7,.7));
    jPanelProcess.add(jLabelEmpty, BorderLayout.WEST);
    
    % Set list size
    UpdateListSize();
    % Add panel
    c.gridy = 0;
    c.weighty = 1;
    jPanelMain.add(jPanelProcess, c);
    
    % ===== OPTIONS: INPUT =====
    jPanelInput = gui_river([0,0], [0,0,5,0], 'Input options');
    jPanelInput.setVisible(0);
    % Add panel
    c.gridy = 2;
    c.weighty = 0;
    jPanelMain.add(jPanelInput, c);
    
    % ===== OPTIONS: PROCESS =====
    jPanelOptions = gui_component('Panel');
    jPanelOptions.setLayout(BoxLayout(jPanelOptions, BoxLayout.Y_AXIS));
    jBorder = BorderFactory.createTitledBorder('Process options');
    jBorder.setTitleFont(bst_get('Font', 11));
    jPanelOptions.setBorder(jBorder);
    jPanelOptions.setVisible(0);
    % Add panel
    c.gridy = 3;
    c.weighty = 0;
    jPanelMain.add(jPanelOptions, c);
    
    % ===== OPTIONS: OUTPUT =====
    jPanelOutput = gui_river([0,0], [0,0,5,0], 'Output options');
    jPanelOutput.setVisible(0);
    % Add panel
    c.gridy = 4;
    c.weighty = 0;
    jPanelMain.add(jPanelOutput, c);
    
    % ===== VALIDATION BUTTONS =====
    jPanelOk = gui_river([6,0], [3,3,3,12]);
    gui_component('button', jPanelOk, 'right', 'Cancel', [], [], @ButtonCancel_Callback, []);
    gui_component('button', jPanelOk, [],      'Run',    [], [], @ButtonOk_Callback, []);
    % Add panel
    c.gridy = 5;
    c.weighty = 0;
    jPanelMain.add(jPanelOk, c);
    
    % Return a mutex to wait for panel close
    bst_mutex('release', panelName);
    bst_mutex('create', panelName);
    % Create the BstPanel object that is returned by the function
    bstPanel = BstPanel(panelName, ...
                        jPanelMain, ...
                        struct('UpdatePipeline', @UpdatePipeline));

                              
%% =========================================================================
%  ===== LOCAL CALLBACKS ===================================================
%  =========================================================================
    %% ===== BUTTON: CANCEL =====
    function ButtonCancel_Callback(hObject, event) %#ok<*INUSD>
        % Close panel without saving (release mutex automatically)
        gui_hide(panelName);
        % Empty global variable
        GlobalData.Processes.Current = [];
    end

    %% ===== BUTTON: OK =====
    function ButtonOk_Callback(varargin)
        % Check validity of pipeline
        if ~isempty(WarningMsg)
            ShowWarningMsg();
            return;
        end
        % Release mutex and keep the panel opened
        bst_mutex('release', panelName);
    end

    %% ===== BUTTON: SAVE =====
    function ButtonHelp_Callback(varargin)       

    end

    %% ===== LIST: VALUE CHANGED =====
    function ListProcess_ValueChangedCallback(h, ev)
        if ~ev.getValueIsAdjusting() && ~isUpdatingPipeline
            UpdateProcessOptions();
        end
    end

    %% ===== LIST: KEY TYPED =====
    function ListProcess_KeyTypedCallback(h, ev)
        switch(uint8(ev.getKeyChar()))
            case ev.VK_DELETE
                RemoveSelectedProcess();
        end
    end

    
%% =========================================================================
%  ===== PROCESS LIST FUNCTIONS ============================================
%  =========================================================================
    %% ===== GET CURRENT DATA TYPE =====
    function [DataType, SubjectName] = GetProcessDataType(iLastProc)
        if (nargin < 1) || isempty(iLastProc) || (iLastProc > length(GlobalData.Processes.Current))
            iLastProc = length(GlobalData.Processes.Current);
        end
        % Initial data type
        DataType = InitialDataType;
        SubjectName = InitialSubjectName;
        % Loop through all the processes to see what is the current data type at the end
        for iProc = 1:iLastProc
            sCurProcess = GlobalData.Processes.Current(iProc);
            % Get the correct input type for the process
            iType = find(strcmpi(sCurProcess.InputTypes, DataType));
            % If the input type of the process do not match the current data type: error
            if isempty(iType) || (iType > length(sCurProcess.OutputTypes))
                DataType = [];
                % Show warning button
                jButtonWarning.setVisible(1);
                % Define warning message
                WarningMsg = ['Error: Data type mismatch.' 10 10 ...
                              'Invalid inputs for process:' 10 '"' sCurProcess.Comment '"' 10];
                return
            end
            % Get the corresponding output type
            DataType = sCurProcess.OutputTypes{iType};
            % Find an option with the type "subjectname"
            if (nargout >= 2) && ~isempty(sCurProcess.options) && isstruct(sCurProcess.options)
                optNames = fieldnames(sCurProcess.options);
                for iOpt = 1:length(optNames)
                    opt = sCurProcess.options.(optNames{iOpt});
                    if isfield(opt, 'Type') && ~isempty(opt.Type) && strcmpi(opt.Type, 'subjectname') && isfield(opt, 'Value') && ~isempty(opt.Value)
                        SubjectName = opt.Value;
                    end
                end
            end
        end
        % No error: hide warning button
        jButtonWarning.setVisible(0);
        WarningMsg = [];
    end


    %% ===== SHOW ERROR MESSAGE =====
    function ShowWarningMsg()
        bst_error(WarningMsg, 'Data type mismatch', 0);
    end

        
    %% ===== PROCESS: GET AVAILABLE =====
    function [sProcesses, iSelProc] = GetAvailableProcesses(DataType, procFiles)
        % Get all the processes
        iSelProc = [];
        sProcessesAll = GlobalData.Processes.All;
        sProcesses = repmat(sProcessesAll, 0);
        % Loop through the processes and look for the valid ones
        for iProc = 1:length(sProcessesAll)
            % === ADAPT PROCESS TO CURRENT INPUT ===
            % Absolute values of sources before process
            % ONLY FOR FILTER AND FILTER2 (not used in other categories)
            if isempty(DataType) || (strcmpi(DataType, 'results') && any(strcmpi(sProcessesAll(iProc).Category, {'Filter', 'Filter2'})) && ...
                                     ismember(sProcessesAll(iProc).isSourceAbsolute, [0,1]))
                sProcessesAll(iProc).options.source_abs.Comment = 'Use absolute values of source activations';
                sProcessesAll(iProc).options.source_abs.Type    = 'checkbox';
                sProcessesAll(iProc).options.source_abs.Value   = sProcessesAll(iProc).isSourceAbsolute;
            end
            % Replace "Cluster" string with "Scouts"
            if ismember(DataType, {'results', 'timefreq'}) && isfield(sProcessesAll(iProc).options, 'clusters')
                sProcessesAll(iProc).Comment = strrep(sProcessesAll(iProc).Comment, 'Cluster', 'Scout');
                sProcessesAll(iProc).Comment = strrep(sProcessesAll(iProc).Comment, 'cluster', 'scout');
                sProcessesAll(iProc).options.clusters.Comment = strrep(sProcessesAll(iProc).options.clusters.Comment, 'Cluster', 'Scout');
                sProcessesAll(iProc).options.clusters.Comment = strrep(sProcessesAll(iProc).options.clusters.Comment, 'cluster', 'scout');
            end
            
            % === IS PROCESS CURRENTLY AVAILABLE ? ===
            % Check number of input sets
            if (sProcessesAll(iProc).nInputs ~= nInputs)
                continue;
            end
            % Process is "listed"
            sProcesses(end+1) = sProcessesAll(iProc);
            % Test data type and number of inputs
            if isempty(DataType) || ~ismember(DataType, sProcessesAll(iProc).InputTypes)
                continue;
            end
            % Test the number of input files
            if (procFiles(1) < sProcessesAll(iProc).nMinFiles)
                continue;
            end
            % Two input variables: check if the number of inputs in each list must be the same
            if (nInputs == 2) && sProcessesAll(iProc).isPaired && (nFiles(1) ~= nFiles(2))
                continue;
            end           
            % Keep process
            iSelProc(end+1) = length(sProcesses);
        end
    end


    %% ===== PROCESS: SHOW POPUP MENU =====
    % AddMode: {'select', 'add', 'insert'}
    function ShowProcessMenu(AddMode)
        import java.awt.Insets;
        import java.awt.Color;
        % Get the current data type and time vector (after the process pipeline)
        procTimeVector = FileTimeVector;
        procFiles = nFiles;
        switch (AddMode)
            case 'select'
                procDataType = InitialDataType;
            case 'add'
                procDataType = GetProcessDataType();
                if ~isempty(GlobalData.Processes.Current)
                    [procTimeVector, procFiles] = GetProcessFileVector(GlobalData.Processes.Current, FileTimeVector, procFiles);
                end
            case 'insert'
                iSelProc = GetSelectedProcess();
                if ~isempty(iSelProc)
                    procDataType = GetProcessDataType(iSelProc);
                    [procTimeVector, procFiles] = GetProcessFileVector(GlobalData.Processes.Current(1:iSelProc), FileTimeVector, procFiles);
                else
                    procDataType = GetProcessDataType();
                    if ~isempty(GlobalData.Processes.Current)
                        [procTimeVector, procFiles] = GetProcessFileVector(GlobalData.Processes.Current, FileTimeVector, procFiles);
                    end
                end
        end
        % Get processes for this specific case
        [sProcesses, iSelProc] = GetAvailableProcesses(procDataType, procFiles);
        % Set default values for the file-dependent options
        sProcesses = SetDefaultOptions(sProcesses, procTimeVector);
        
        % Create popup menu
        jPopup = java_create('javax.swing.JPopupMenu');
        hashGroups = java.util.Hashtable();
        % Fill the combo box
        for iProc = 1:length(sProcesses)
            % If "Select", ignore non-available menus
            isSelected = ismember(iProc, iSelProc);
            if strcmpi(AddMode, 'select') && ~isSelected
                continue;
            end
            % Get parent menu
            % If no sub group: parent menu is the popup menu
            if isempty(sProcesses(iProc).SubGroup)
                jParent = jPopup;
            % Else: create a sub-menu for the sub-group
            else
                hashKey = java.lang.String(sProcesses(iProc).SubGroup);
                % Get existing menu
                jParent = hashGroups.get(hashKey);
                % Menu not created yet: create it
                if isempty(jParent)
                    jParent = gui_component('Menu', jPopup, [], sProcesses(iProc).SubGroup, [], [], [], []);
                    jParent.setMargin(Insets(5,0,4,0));
                    jParent.setForeground(Color(.6,.6,.6));
                    hashGroups.put(hashKey, jParent);
                end
            end
            % Create process menu
            jItem = gui_component('MenuItem', jParent, [], sProcesses(iProc).Comment, [], [], @(h,ev)AddProcess(iProc, AddMode));
            jItem.setMargin(Insets(5,0,4,0));
            % Change menu color for unavailable menus
            if ~isSelected
                jItem.setForeground(Color(.6,.6,.6));
            else
                jParent.setForeground(Color(0,0,0));
            end
            % Add separator?
            if sProcesses(iProc).isSeparator
                jParent.addSeparator();
            end
        end
        % Show popup menu
        try
            jPopup.show(jButtonAdd, 0, jButtonAdd.getHeight());
        catch
            % Try again to call the same function
            pause(0.1);
            disp('Call failed: calling again...');
            ShowProcessMenu(AddMode);
        end
    end


    %% ===== PROCESS: ADD =====
    function AddProcess(iProcess, AddMode)
        % Get process data type for this process
        iSelProc = GetSelectedProcess();
        sCurProcesses = GlobalData.Processes.Current;
        % Select unique process
        if strcmpi(AddMode, 'select') || isempty(sCurProcesses)
            sCurProcesses = sProcesses(iProcess);
            % First of the list: no overwrite by default
            if strcmpi(sCurProcesses.Category, 'Filter') && isfield(sCurProcesses.options, 'overwrite')
                sCurProcesses.options.overwrite.Value = 0;
            end
            DataType = InitialDataType;
            iNewProc = 1;
        elseif strcmpi(AddMode, 'add') || isempty(iSelProc) || (iSelProc == length(sCurProcesses))
            DataType = GetProcessDataType();
            sCurProcesses(end+1) = sProcesses(iProcess);
            iNewProc = length(sCurProcesses);
        elseif strcmpi(AddMode, 'insert')
            DataType = GetProcessDataType(iSelProc);
            sCurProcesses = [sCurProcesses(1:iSelProc), sProcesses(iProcess), sCurProcesses(iSelProc+1:end)];
            iNewProc = iSelProc + 1;
        end
        % Check the options data type
        if ~isempty(sCurProcesses(iNewProc).options)
            % Get list of options
            optNames = fieldnames(sCurProcesses(iNewProc).options);
            % Remove the options that do not meet the current file type requirements
            for iOpt = 1:length(optNames)
                option = sCurProcesses(iNewProc).options.(optNames{iOpt});
                if isfield(option, 'InputTypes') && iscell(option.InputTypes) && ~any(strcmpi(DataType, option.InputTypes))
                    % Not a valid option for this type of data: remove
                    sCurProcesses(iNewProc).options = rmfield(sCurProcesses(iNewProc).options, optNames{iOpt});
                end
            end
        end
        GlobalData.Processes.Current = sCurProcesses;
        % Update pipeline
        UpdatePipeline(iNewProc);
    end

    
    %% ===== GET SELECTED PROCESS =====
    function iSel = GetSelectedProcess()
        iSel = jListProcess.getSelectedIndex();
        if (iSel == -1)
            iSel = [];
        else
            iSel = iSel + 1;
        end        
    end


    %% ===== PROCESS: REMOVE SELECTED =====
    function RemoveSelectedProcess()
        % Get selected indice
        iSel = GetSelectedProcess();
        if isempty(iSel)
            return
        end
        drawnow;
        % Select the previous process
        if (iSel > 0)
            jListProcess.setSelectedIndex(iSel - 2);
        end
        % Remove process
        GlobalData.Processes.Current(iSel) = [];
        % Set size of the list
        UpdateListSize();
        % Update processes list
        UpdateProcessesList();
        drawnow;
        % Update options
        UpdateProcessOptions();
        % Update warning button
        GetProcessDataType();
    end

    %% ===== PROCESS: MOVE SELECTED =====
    function MoveSelectedProcess(action)
        % Get selected indice
        iSelProc = GetSelectedProcess();
        if isempty(iSelProc)
            return
        end
        % Action
        switch(action)
            case 'up'
                % Already first in the list
                if (iSelProc <= 1)
                    return
                end
                % Swap with previous process
                iTargetProc = iSelProc - 1;
            case 'down'
                % Already last in the list
                if (iSelProc >= length(GlobalData.Processes.Current))
                    return
                end
                % Swap with next process
                iTargetProc = iSelProc + 1;
        end
        % Swap processes
        tmp = GlobalData.Processes.Current(iTargetProc);
        GlobalData.Processes.Current(iTargetProc) = GlobalData.Processes.Current(iSelProc);
        GlobalData.Processes.Current(iSelProc) = tmp;
        % Update processes list
        UpdateProcessesList();
        % Select moved process
        jListProcess.setSelectedIndex(iTargetProc - 1);
        % Check if pipeline is valid
        GetProcessDataType();
    end


%% =========================================================================
%  ===== PANEL AND OPTIONS FUNCTIONS =======================================
%  =========================================================================
    %% ===== PANEL: UPDATE LIST SIZE =====
    function UpdateListSize()
        % Set size of the list
        listHeight = bst_saturate(length(GlobalData.Processes.Current), [1,10]) * LIST_ELEMENT_HEIGHT;
        jScrollProcess.setPreferredSize(java.awt.Dimension(350, listHeight));
        jLabelEmpty.setPreferredSize(java.awt.Dimension(350, listHeight));
    end


    %% ===== PANEL: UPDATE PIPELINE =====
    function UpdatePipeline(iSelProc)
        if (nargin < 1) || isempty(iSelProc)
            iSelProc = length(GlobalData.Processes.Current);
        end
        % Set size of the list
        UpdateListSize();
        % Update processes list
        UpdateProcessesList();
        % Select last process added
        jListProcess.setSelectedIndex(iSelProc - 1);
        % Force update of options for "select" button (it does not change the selection in the JList)
        UpdateProcessOptions();
        % Check if pipeline is valid
        GetProcessDataType();
        % Scroll down to see the last process added
        if (iSelProc > 5)
            drawnow;
            selRect = jListProcess.getCellBounds(iSelProc-1, iSelProc-1);
            jListProcess.scrollRectToVisible(selRect);
            jListProcess.repaint();
            jListProcess.getParent().getParent().repaint();
            jPanelOptions.repaint();
        end
    end
    

    %% ===== PANEL: UPDATE PROCESSES LIST =====
    function UpdateProcessesList()
        import org.brainstorm.list.*;
        % Get selected indice
        iSel = jListProcess.getSelectedIndex();
        % Remove JList callbacks
        java_setcb(jListProcess, 'ValueChangedCallback', []);
        % Create a list of all the current selected processes
        listModel = javax.swing.DefaultListModel();
        for iProc = 1:length(GlobalData.Processes.Current)
            sCurProcess = GlobalData.Processes.Current(iProc);
            % Get process comment
            try
                procComment = sCurProcess.Function('FormatComment', sCurProcess);
            catch
                procComment = ['Error: Function "' func2str(sCurProcess.Function) '" is not accessible'];
            end
            % Add "overwrite" option
            if isfield(sCurProcess.options, 'overwrite') && sCurProcess.options.overwrite.Value
                itemType = 'overwrite';
            else
                itemType = '';
            end
            % Create list element
            listModel.addElement(BstListItem(itemType, '', procComment, iProc));
        end
        jListProcess.setModel(listModel);
        % Set selected indice
        jListProcess.setSelectedIndex(iSel);
        % Set callbacks
        java_setcb(jListProcess, 'ValueChangedCallback', @ListProcess_ValueChangedCallback);
        % Hide/show empty label indication
        jLabelEmpty.setVisible(isempty(GlobalData.Processes.Current));
        jScrollProcess.setVisible(~isempty(GlobalData.Processes.Current));
    end


    %% ===== PANEL: UPDATE PROCESS OPTIONS =====
    function UpdateProcessOptions()
        import java.awt.Dimension;
        % Starting the update
        isUpdatingPipeline = 1;
        % Font size for the options
        if strncmp(computer,'MAC',3)
            FONT_SIZE = 12;
        else
            FONT_SIZE = [];
        end
        TEXT_DIM = java.awt.Dimension(70, 20);
        % Empty options panels
        jPanelInput.removeAll();
        jPanelOptions.removeAll();
        jPanelOutput.removeAll();
        % Get selected process
        iProcess = GetSelectedProcess();
        % No selected process
        if isempty(iProcess) || isempty(GlobalData.Processes.Current(iProcess).options)
            optNames = [];
        else
            sProcess = GlobalData.Processes.Current(iProcess);
            % Get all the options
            optNames = fieldnames(sProcess.options);
        end
        % Get data type for the selected process
        if (iProcess == 1)
            curDataType = InitialDataType;
            curTimeVector = FileTimeVector;
            curSubjectName = InitialSubjectName;
        else
            [curDataType, curSubjectName] = GetProcessDataType(iProcess-1);
            curTimeVector = GetProcessFileVector(GlobalData.Processes.Current(1:iProcess-1), FileTimeVector, nFiles);
        end
        % Sampling frequency 
        curSampleFreq = 1 / (curTimeVector(2) - curTimeVector(1));
        
        % === PROTOCOL OPTIONS ===
        for iOpt = 1:length(optNames)
            % Get option
            option = sProcess.options.(optNames{iOpt});
            % Check the option integrity
            if ~isfield(option, 'Type')
                disp(['BST> ' func2str(sProcesses(iProcess).Function) ': Invalid option "' optNames{iOpt} '"']);
                continue;
            end
            % If option is hidden: skip
            if isfield(option, 'Hidden') && isequal(option.Hidden, 1)
                continue;
            end
            % Enclose option line in a River panel
            jPanelOpt = gui_river([2,2], [2,4,2,4]);
            % Define to which panel it should be added
            switch optNames{iOpt}
                case 'overwrite'
                    jPanelOutput.add(jPanelOpt);
                case 'source_abs'
                    jPanelInput.add(jPanelOpt);
                otherwise
                    jPanelOptions.add(jPanelOpt);
            end
            prefPanelSize = [];
            
            % Get timing/gridding information, for all the values related controls
            if ismember(option.Type, {'range', 'timewindow', 'baseline', 'poststim', 'value'})
                % Get units
                if (length(option.Value) >= 2) && ~isempty(option.Value{2})
                    valUnits = option.Value{2};
                else
                    valUnits = ' ';
                end
                % Get precision
                if (length(option.Value) >= 3) && ~isempty(option.Value{3})
                    precision = option.Value{3};
                else
                    precision = [];
                end
                % Frequency: file, or 100
                if ismember(valUnits, {'s', 'ms', 'time'})
                    valFreq = curSampleFreq;
                elseif ~isempty(precision)
                    valFreq = 10^(precision);
                else
                    valFreq = 100;
                end
                % Bounds
                if ismember(option.Type, {'timewindow', 'baseline', 'poststim'})   % || ismember(valUnits, {'s', 'ms', 'time'})
                    if (length(curTimeVector) == 2)
                        bounds = [curTimeVector(1), curTimeVector(2), 10000];
                    else
                        bounds = curTimeVector;
                    end
                elseif strcmpi(option.Type, 'value') && ~isempty(valUnits) && strcmpi(valUnits, 'Hz')
                    bounds = [0, 100000, valFreq];
                else
                    bounds = [-1e30, 1e30, valFreq];
                end
            end
            
            % Create the appropriate controls
            switch (option.Type)
                % RANGE: {[start,stop], units, precision}
                case {'range', 'timewindow', 'baseline', 'poststim'}
                    gui_component('label',    jPanelOpt, [], ['<HTML>&nbsp;', option.Comment], [],[],[],FONT_SIZE);
                    jTextMin = gui_component('texttime', jPanelOpt, [], ' ', TEXT_DIM,[],[],FONT_SIZE);
                    gui_component('label',    jPanelOpt, [], ' - ', [],[],[],FONT_SIZE);
                    jTextMax = gui_component('texttime', jPanelOpt, [], ' ', TEXT_DIM,[],[],FONT_SIZE);
                    % Set controls callbacks
                    if ~isempty(option.Value) && iscell(option.Value) && ~isempty(option.Value{1})
                        initStart = option.Value{1}(1);
                        initStop  = option.Value{1}(2);
                    else
                        initStart = [];
                        initStop  = [];
                    end
                    valUnits = gui_validate_text(jTextMin, [], jTextMax, bounds, valUnits, precision, initStart, @(h,ev)OptionRange_Callback(iProcess, optNames{iOpt}, jTextMin, jTextMax));
                    valUnits = gui_validate_text(jTextMax, jTextMin, [], bounds, valUnits, precision, initStop,  @(h,ev)OptionRange_Callback(iProcess, optNames{iOpt}, jTextMin, jTextMax));
                    % Add unit label
                    gui_component('label', jPanelOpt, [], ['<HTML>' valUnits], [],[],[],FONT_SIZE);
                    % Save units
                    GlobalData.Processes.Current(iProcess).options.(optNames{iOpt}).Value{2} = valUnits;
                    
                % VALUE: {value, units, precision}
                case 'value'
                    % Label title
                    gui_component('label', jPanelOpt, [], ['<HTML>&nbsp;', option.Comment], [],[],[],FONT_SIZE);
                    % Constrain depends on the units: list fill the space horizontally
                    if strcmpi(valUnits, 'list')
                        jText = gui_component('text', jPanelOpt, 'hfill', ' ', [],[],[],FONT_SIZE);
                    else
                        jText = gui_component('texttime', jPanelOpt, [], ' ', [],[],[],FONT_SIZE);
                    end
                    % Set controls callbacks
                    valUnits = gui_validate_text(jText, [], [], bounds, valUnits, precision, option.Value{1}, @(h,ev)OptionValue_Callback(iProcess, optNames{iOpt}, jText));
                    % Add unit label
                    if ~strcmpi(valUnits, 'list')
                        gui_component('label', jPanelOpt, [], [' ' valUnits], [],[],[],FONT_SIZE);
                    else
                        jText.setHorizontalAlignment(javax.swing.JLabel.LEFT);
                    end
                    % Save units
                    GlobalData.Processes.Current(iProcess).options.(optNames{iOpt}).Value{2} = valUnits;
                    
                case 'label'
                    gui_component('label', jPanelOpt, [], ['<HTML>&nbsp;', option.Comment], [],[],[],FONT_SIZE);
                case 'text'
                    gui_component('label', jPanelOpt, [], ['<HTML>&nbsp;', option.Comment], [],[],[],FONT_SIZE);
                    jText = gui_component('text', jPanelOpt, 'hfill', option.Value, [],[],[],FONT_SIZE);
                    % Set validation callbacks
                    java_setcb(jText, 'ActionPerformedCallback', @(h,ev)SetOptionValue(iProcess, optNames{iOpt}, char(ev.getSource().getText())), ...
                                      'FocusLostCallback',       @(h,ev)SetOptionValue(iProcess, optNames{iOpt}, char(ev.getSource().getText())));
                case 'textarea'
                    gui_component('label', jPanelOpt, [], ['<HTML>&nbsp;', option.Comment], [],[],[],FONT_SIZE);
                    jText = gui_component('TextFreq', jPanelOpt, 'br hfill', option.Value, [], [], [], FONT_SIZE);
                    % Set validation callbacks
                    java_setcb(jText, 'FocusLostCallback', @(h,ev)SetOptionValue(iProcess, optNames{iOpt}, char(ev.getSource().getText())));
                case 'groupbands'
                    gui_component('label', jPanelOpt, [], option.Comment, [],[],[],FONT_SIZE);
                    strBands = process_tf_bands('FormatBands', option.Value);
                    gui_component('TextFreq', jPanelOpt, 'br hfill', strBands, [], [], @(h,ev)OptionBands_Callback(iProcess, optNames{iOpt}, ev.getSource()), FONT_SIZE);

                case 'checkbox'
                    jCheck = gui_component('checkbox', jPanelOpt, [], option.Comment, [], [], @(h,ev)SetOptionValue(iProcess, optNames{iOpt}, double(ev.getSource().isSelected())), FONT_SIZE);
                    jCheck.setSelected(logical(option.Value));
                case 'radio'
                    jButtonGroup = javax.swing.ButtonGroup();
                    constr = [];
                    for iRadio = 1:length(option.Comment)
                        jCheck = gui_component('radio', jPanelOpt, constr, option.Comment{iRadio}, [], [], @(h,ev)OptionRadio_Callback(iProcess, optNames{iOpt}, iRadio, ev.getSource().isSelected()), FONT_SIZE);
                        jCheck.setSelected(option.Value == iRadio);
                        jButtonGroup.add(jCheck);
                        constr = 'br';
                    end
                case 'combobox'
                    gui_component('label', jPanelOpt, [], ['<HTML>&nbsp;', option.Comment, '&nbsp;&nbsp;'], [],[],[],FONT_SIZE);
                    % Combo box
                    jCombo = gui_component('ComboBox', jPanelOpt, [], [], option.Value(2), [], [], FONT_SIZE);
                    jCombo.setEditable(false);
                    jPanelOpt.add(jCombo);
                    % Select previously selected channel
                    jCombo.setSelectedIndex(option.Value{1} - 1);
                    % Set validation callbacks
                    java_setcb(jCombo, 'ActionPerformedCallback', @(h,ev)SetOptionValue(iProcess, optNames{iOpt}, {ev.getSource().getSelectedIndex()+1, option.Value{2}}));
                    
                case {'cluster', 'cluster_confirm'}
                    % Get available and selected clusters
                    [jList, sClusters] = GetClusterList(iProcess, optNames{iOpt});
                    % Clusters/scouts?
                    if strcmpi(curDataType, 'data')
                        strClustType = 'clusters';
                    else
                        strClustType = 'scouts';
                    end
                    % If no clusters
                    if isempty(jList)
                        gui_component('label', jPanelOpt, [], ['<HTML>&nbsp;No ' strClustType ' available.'], [],[],[],FONT_SIZE);
                    else
                        % Confirm selection of not
                        if strcmpi(option.Type, 'cluster_confirm')
                            if ~isempty(option.Comment)
                                strCheck = option.Comment;
                            else
                                strCheck = ['Use ' strClustType ' time series'];
                            end
                            jCheckCluster = gui_component('checkbox', jPanelOpt, [], strCheck, [], [], [], FONT_SIZE);
                            java_setcb(jCheckCluster, 'ActionPerformedCallback', @(h,ev)Cluster_ValueChangedCallback(iProcess, optNames{iOpt}, sClusters, jList, jCheckCluster, []));
                            if ~isempty(option.Value)
                                jCheckCluster.setSelected(1)
                                jList.setEnabled(1);
                            else
                                jList.setEnabled(0);
                            end
                        else
                            jCheckCluster = [];
                            gui_component('label', jPanelOpt, [], [' Select ', strClustType, ':'], [],[],[],[]);
                        end
                        % Set callbacks
                        java_setcb(jList, 'ValueChangedCallback', @(h,ev)Cluster_ValueChangedCallback(iProcess, optNames{iOpt}, sClusters, jList, jCheckCluster, ev));
                        Cluster_ValueChangedCallback(iProcess, optNames{iOpt}, sClusters, jList, jCheckCluster, []);
                        
                        % Create scroll panel
                        jScroll = javax.swing.JScrollPane(jList);
                        jPanelOpt.add('br hfill vfill', jScroll);
                        % Set preferred size for the container
                        prefPanelSize = java.awt.Dimension(250,120);
                    end
                    
                case 'channelname'
                    gui_component('label', jPanelOpt, [], ['<HTML>&nbsp;', option.Comment, '&nbsp;&nbsp;'], [],[],[],FONT_SIZE);
                    % Combo box
                    jCombo = gui_component('ComboBox', jPanelOpt, [], [], {ChannelNames}, [], [], FONT_SIZE);
                    jCombo.setEditable(true);
                    % Select previously selected channel
                    jCombo.setSelectedItem(option.Value);
                    % Set validation callbacks
                    java_setcb(jCombo, 'ActionPerformedCallback', @(h,ev)SetOptionValue(iProcess, optNames{iOpt}, char(ev.getSource().getSelectedItem())));
                    
                case 'subjectname'
                    gui_component('label', jPanelOpt, [], ['<HTML>&nbsp;', option.Comment, '&nbsp;&nbsp;'], [],[],[],FONT_SIZE);
                    % Default subject: current subject, or previous call
                    if ~isempty(curSubjectName)
                        defSubjectName = curSubjectName;
                    elseif ~isempty(option.Value)
                        defSubjectName = option.Value;
                    else
                        defSubjectName = [];
                    end
                    % Combo box: create list of subjects
                    listSubj = SubjectNames;
                    if ~isempty(defSubjectName) && ~ismember(defSubjectName, listSubj)
                        listSubj{end+1} = defSubjectName;
                    end
                    if isempty(listSubj)
                        listSubj = {'NewSubject'};
                    end
                    jCombo = gui_component('ComboBox', jPanelOpt, [], [], {listSubj}, [], [], FONT_SIZE);
                    jCombo.setEditable(true);
                    % Select previously selected subject
                    if ~isempty(defSubjectName)
                        iDefault = find(strcmpi(listSubj, defSubjectName));
                    elseif ~isempty(iSelSubject)
                        iDefault = iSelSubject;
                    else
                        iDefault = 1;
                    end
                    % Select element in the combobox
                    jCombo.setSelectedIndex(iDefault - 1);
                    % Save the selected value
                    SetOptionValue(iProcess, optNames{iOpt}, listSubj{iDefault});
                    % Set validation callbacks
                    java_setcb(jCombo, 'ActionPerformedCallback', @(h,ev)SetOptionValue(iProcess, optNames{iOpt}, char(ev.getSource().getSelectedItem())));
                    
                case 'atlas'
                    gui_component('label', jPanelOpt, [], ['<HTML>&nbsp;', option.Comment, '&nbsp;&nbsp;'], [],[],[],FONT_SIZE);
                    % Get available atlases for target subject
                    atlasNames = {''};
                    iAtlas = [];
                    if ~isempty(sFiles(1).SubjectFile) % && strcmpi(curDataType, 'results')
                        % Read the subject structure
                        sSubject = bst_get('Subject', sFiles(1).SubjectFile);
                        if ~isempty(sSubject) && ~isempty(sSubject.iCortex)
                            surfFile = file_fullpath(sSubject.Surface(sSubject.iCortex).FileName);
                            if ~isempty(surfFile) && file_exist(surfFile)
                                surfMat = load(surfFile, 'Atlas', 'iAtlas');
                                if isfield(surfMat, 'Atlas') && isfield(surfMat, 'iAtlas') && ~isempty(surfMat.Atlas) && ~isempty(surfMat.iAtlas)
                                    atlasNames = {surfMat.Atlas.Name};
                                    iAtlas = surfMat.iAtlas;
                                end
                            end
                        end
                    end
                    % Create combo box
                    jCombo = gui_component('ComboBox', jPanelOpt, [], [], {atlasNames}, [], [], FONT_SIZE);
                    jCombo.setEditable(true);
                    % Select previously selected subject
                    iDefault = [];
                    if ~isempty(option.Value) && ~isempty(atlasNames)
                        iDefault = find(strcmpi(option.Value, atlasNames));
                    end
                    if isempty(iDefault) && ~isempty(iAtlas)
                        iDefault = iAtlas;
                    end
                    if ~isempty(iDefault)
                        jCombo.setSelectedIndex(iDefault - 1);
                    else
                        SetOptionValue(iProcess, optNames{iOpt}, atlasNames{1});
                    end
                    % Set validation callbacks
                    java_setcb(jCombo, 'ActionPerformedCallback', @(h,ev)SetOptionValue(iProcess, optNames{iOpt}, char(ev.getSource().getSelectedItem())));

                case {'filename', 'datafile'}
                    % Get filename
                    FileNames = option.Value{1};
                    if isempty(FileNames)
                        strFiles = '';
                    elseif ischar(FileNames)
                        % [tmp,fBase,fExt] = bst_fileparts(FileNames);
                        % strFiles = [fBase,fExt];
                        strFiles = FileNames;
                    else
                        if (length(FileNames) == 1)
                            % [tmp,fBase,fExt] = bst_fileparts(FileNames{1});
                            % strFiles = [fBase,fExt];
                            strFiles = FileNames{1};
                        else
                            strFiles = sprintf('[%d files]', length(FileNames));
                        end
                    end
                    % Create controls
                    gui_component('label', jPanelOpt, [], ['<HTML>&nbsp;', option.Comment, '&nbsp;&nbsp;'], [],[],[],FONT_SIZE);
                    jText = gui_component('text', jPanelOpt, [], strFiles, [],[],[],FONT_SIZE);
                    jText.setEditable(0);
                    jText.setPreferredSize(Dimension(210, 20));
                    isUpdateTime = strcmpi(option.Type, 'datafile');
                    gui_component('button', jPanelOpt, '', '...', [],[], @(h,ev)PickFile_Callback(iProcess, optNames{iOpt}, jText, isUpdateTime));
                    
                case 'editpref'
                    gui_component('label',  jPanelOpt, [], ['<HTML>&nbsp;', option.Comment{2}, '&nbsp;&nbsp;&nbsp;'], [],[],[],FONT_SIZE);
                    gui_component('button', jPanelOpt, [], 'Edit...', [],[], @(h,ev)EditProperties_Callback(iProcess, optNames{iOpt}));
                    
                case 'separator'
                    gui_component('label', jPanelOpt, [], ' ');
                    jsep = gui_component('label', jPanelOpt, 'br hfill', ' ');
                    jsep.setBackground(java.awt.Color(.4,.4,.4));
                    jsep.setOpaque(1);
                    jsep.setPreferredSize(Dimension(1,1));
                    gui_component('label', jPanelOpt, 'br', ' ');
            end
            jPanelOpt.setPreferredSize(prefPanelSize);
        end
        % If there are no components in the options panel: display "no options"
        isEmptyOptions = (jPanelOptions.getComponentCount() == 0);
        if isEmptyOptions
            if ~isempty(iProcess)
                strEmpty = '<HTML>&nbsp;&nbsp;&nbsp;&nbsp;<FONT color="#777777"> No options for this process</FONT><BR>';
            else
                strEmpty = '<HTML>&nbsp;&nbsp;&nbsp;&nbsp;<FONT color="#777777"> No process selected</FONT><BR>';
            end
            jPanelOpt = gui_river([2,2], [2,4,2,4]);
            gui_component('label', jPanelOpt, 'hfill', strEmpty, [],[],[],FONT_SIZE);
            jPanelOptions.add(jPanelOpt);
        end
        % Hide/show other options panels
        jPanelInput.setVisible(jPanelInput.getComponentCount() > 0);
        jPanelOptions.setVisible(~isempty(GlobalData.Processes.Current));
        jPanelOutput.setVisible(jPanelOutput.getComponentCount() > 0);
        % Update figure size
        jParent = jPanelMain.getTopLevelAncestor();
        if ~isempty(jParent)
            jParent.pack();
        end
        % Stopping the update
        isUpdatingPipeline = 0;
    end

    %% ===== OPTIONS: FREQ BANDS CALLBACK =====
    function OptionBands_Callback(iProcess, optName, jText)
        % Get bands
        value = process_tf_bands('ParseBands', char(jText.getText()));
        % Update interface
        SetOptionValue(iProcess, optName, value);
    end

    %% ===== OPTIONS: RANGE CALLBACK =====
    function OptionRange_Callback(iProcess, optName, jTextMin, jTextMax)
        % Get current options
        try
            value = GlobalData.Processes.Current(iProcess).options.(optName).Value;
            valUnits = value{2};
            % Get new value
            value{1} = [GetValue(jTextMin, valUnits), GetValue(jTextMax, valUnits)];
            % Update interface
            SetOptionValue(iProcess, optName, value);
        catch
        end
    end


    %% ===== OPTIONS: VALUE CALLBACK =====
    function OptionValue_Callback(iProcess, optName, jText)
        try
            % Get current options
            value = GlobalData.Processes.Current(iProcess).options.(optName).Value;
            valUnits = value{2};
            % Get new value
            value{1} = GetValue(jText, valUnits);
            % Update interface
            SetOptionValue(iProcess, optName, value);
        catch
        end
    end

    %% ===== OPTIONS: PICK FILE CALLBACK =====
    function PickFile_Callback(iProcess, optName, jText, isUpdateTime)
        % Get default import directory and formats
        LastUsedDirs = bst_get('LastUsedDirs');
        DefaultFormats = bst_get('DefaultFormats');
        % Get file selection options
        selectOptions = GlobalData.Processes.Current(iProcess).options.(optName).Value;
        if (length(selectOptions) == 9)
            DialogType    = selectOptions{3};
            WindowTitle   = selectOptions{4};
            DefaultDir    = selectOptions{5};
            SelectionMode = selectOptions{6};
            FilesOrDir    = selectOptions{7};
            Filters       = selectOptions{8};
            DefaultFormat = selectOptions{9};
            % Default dir type
            if isfield(LastUsedDirs, DefaultDir)
                DefaultFile = LastUsedDirs.(DefaultDir);
            else
                DefaultFile = DefaultDir;
                DefaultDir = [];
            end
            % Default filter
            if isfield(DefaultFormats, DefaultFormat)
                defaultFilter = DefaultFormats.(DefaultFormat);
            else
                defaultFilter = [];
                DefaultFormat = [];
            end
        else
            DialogType    = 'open';
            WindowTitle   = 'Open file';
            DefaultDir    = '';
            DefaultFile   = '';
            SelectionMode = 'single';
            FilesOrDir    = 'files_and_dirs';
            Filters       = {{'*'}, 'All files (*.*)', 'ALL'};
            DefaultFormat = [];
            defaultFilter = [];
        end
        
        % Pick a file
        [OutputFiles, FileFormat] = java_getfile(DialogType, WindowTitle, DefaultFile, SelectionMode, FilesOrDir, Filters, defaultFilter);
        % If nothing selected
        if isempty(OutputFiles)
            return
        end
        % Progress bar
        bst_progress('start', 'Import MEG/EEG recordings', 'Reading the file header...');
        % Save default import directory
        if ~isempty(DefaultDir)
            if ischar(OutputFiles)
                newDir = OutputFiles;
            elseif iscell(OutputFiles)
                newDir = OutputFiles{1};
            end
            % Get parent folder if needed
            if ~isdir(newDir)
                newDir = bst_fileparts(newDir);
            end
            LastUsedDirs.(DefaultDir) = newDir;
            bst_set('LastUsedDirs', LastUsedDirs);
        end
        % Save default import format
        if ~isempty(DefaultFormat)
            DefaultFormats.(DefaultFormat) = FileFormat;
            bst_set('DefaultFormats',  DefaultFormats);
        end
        % Get file descriptions (one/many)
        if ischar(OutputFiles)
            % [tmp,fBase,fExt] = bst_fileparts(OutputFiles);
            % strFiles = [fBase,fExt];
            strFiles = OutputFiles;
            FirstFile = OutputFiles;
        else
            if (length(OutputFiles) == 1)
                % [tmp,fBase,fExt] = bst_fileparts(OutputFiles{1});
                % strFiles = [fBase,fExt];
                strFiles = OutputFiles{1};
            else
                strFiles = sprintf('[%d files]', length(OutputFiles));
            end
            FirstFile = OutputFiles{1};
        end
        
        % Update the values
        selectOptions{1} = OutputFiles;
        selectOptions{2} = FileFormat;
        % Save the new values
        SetOptionValue(iProcess, optName, selectOptions);
        % Update the text field
        jText.setText(strFiles);
        
        % Try to open the file and update the current time vector
        if isUpdateTime
            % Load RAW FileTimeVector
            TimeVector = LoadRawTime(FirstFile, FileFormat);
            if ~isempty(TimeVector)
                FileTimeVector = TimeVector;
                % Reload options
                GlobalData.Processes.Current = SetDefaultOptions(GlobalData.Processes.Current, FileTimeVector, 0);
                UpdateProcessOptions();
            end
        end
        % Close progress bar
        bst_progress('stop');
    end


    %% ===== OPTIONS: EDIT PROPERTIES CALLBACK =====
    function EditProperties_Callback(iProcess, optName)
        % Get current value: {@panel, sOptions}
        sCurProcess = GlobalData.Processes.Current(iProcess);
        fcnPanel = sCurProcess.options.(optName).Comment{1};
        % Hide pipeline editor
        jDialog = jPanelProcess.getTopLevelAncestor();
        jDialog.setAlwaysOnTop(0);
        jDialog.setVisible(0);
%         isModal = jDialog.isModal();
%         jDialog.setModal(0);
        drawnow;
        % Display options dialog window
        value = gui_show_dialog(sCurProcess.Comment, fcnPanel, 1, [], sCurProcess, sFiles);
        drawnow;
        % Restore pipeline editor
        jDialog.setVisible(1);
        jDialog.setAlwaysOnTop(1);
%         jDialog.setModal(isModal);
        drawnow;
        
        % Editing was cancelled
        if isempty(value)
            return
        end
        % Save the new values
        SetOptionValue(iProcess, optName, value);
    end

    %% ===== OPTIONS: RADIO CALLBACK =====
    function OptionRadio_Callback(iProcess, optName, iRadio, isSelected)
        if isSelected
            SetOptionValue(iProcess, optName, iRadio);
        end
    end

    %% ===== OPTIONS: GET CLUSTER LIST =====
    function [jList, sClusters] = GetClusterList(iProcess, optName)
        import org.brainstorm.list.*;
        jList = [];
        sClusters = [];
        % Get data type for the selected process
        if (iProcess == 1)
            curDataType = InitialDataType;
        else
            curDataType = GetProcessDataType(iProcess-1);
        end
        if isempty(curDataType)
            return;
        end
        % Get available clusters or scouts
        switch (curDataType)
            case {'data', 'raw'}
                % Get available clusters 
                sClusters = panel_cluster('GetClusters');
                if isempty(sClusters)
                    return
                end
                % Get selected clusters
                [tmp__, iSelClusters] = panel_cluster('GetSelectedClusters');
                % Get all clusters labels
                allLabels = {sClusters.Label};
                
            case {'results', 'timefreq'}
                % Get currently available scouts
                sClusters = panel_scout('GetScouts');
                % If some scouts are available in the GUI: Get the selected scouts
                if ~isempty(sClusters)
                    [tmp__, iSelClusters] = panel_scout('GetSelectedScouts');
                % Else: Get scouts from the current cortex surface file
                else
                    SurfaceFile = [];
                    % Get surface file
                    if strcmpi(sFiles(1).FileType, 'results')
                        ResultsMat = in_bst_results(sFiles(1).FileName, 0, 'SurfaceFile');
                        SurfaceFile = ResultsMat.SurfaceFile;
                    elseif strcmpi(sFiles(1).FileType, 'timefreq')
                        ResultsMat = in_bst_timefreq(sFiles(1).FileName, 0, 'SurfaceFile');
                        SurfaceFile = ResultsMat.SurfaceFile;
                    end
                    % Else: Get default cortex for the subject
                    if isempty(SurfaceFile)
                        sSubject = bst_get('Subject', sFiles(1).SubjectFile);
                        if isempty(sSubject.iCortex)
                            return;
                        end
                        SurfaceFile = sSubject.Surface(sSubject.iCortex).FileName;
                    end
                    % Read subject cortex file
                    CortexMat = load(file_fullpath(SurfaceFile), 'Atlas', 'iAtlas');
                    if ~isfield(CortexMat, 'Atlas') || ~isfield(CortexMat, 'iAtlas') || isempty(CortexMat.Atlas) || isempty(CortexMat.iAtlas) || (CortexMat.iAtlas > length(CortexMat.Atlas)) || isempty(CortexMat.Atlas(CortexMat.iAtlas).Scouts)
                        return;
                    end
                    % Use the available scouts
                    sClusters = CortexMat.Atlas(CortexMat.iAtlas).Scouts;
                    iSelClusters = 1:length(sClusters);
                end
                % Format scouts labels
                % allLabels = panel_scout('FormatScoutLabel', sClusters, 0);
                allLabels = {sClusters.Label};
                
            case 'matrix'
                % Get subject
                sSubject = bst_get('Subject', sFiles(1).SubjectFile);
                if isempty(sSubject) || isempty(sSubject.iCortex)
                    return;
                end
                % Get default cortex 
                SurfaceFile = sSubject.Surface(sSubject.iCortex).FileName;
                % Read subject cortex file
                CortexMat = load(file_fullpath(SurfaceFile), 'Atlas', 'iAtlas');
                if ~isfield(CortexMat, 'Atlas') || ~isfield(CortexMat, 'iAtlas') || isempty(CortexMat.Atlas) || isempty(CortexMat.iAtlas) || (CortexMat.iAtlas > length(CortexMat.Atlas)) || isempty(CortexMat.Atlas(CortexMat.iAtlas).Scouts)
                    return;
                end
                % Use the available scouts
                sClusters = CortexMat.Atlas(CortexMat.iAtlas).Scouts;
                iSelClusters = 1:length(sClusters);
                % Format scouts labels
                allLabels = {sClusters.Label};
                
            otherwise
                sClusters = [];
                return;
        end

        % Create a list mode of the existing clusters/scouts
        listModel = javax.swing.DefaultListModel();
        for iClust = 1:length(sClusters)
            listModel.addElement(BstListItem(sClusters(iClust).Label, '', [' ' allLabels{iClust} ' '], iClust));
        end

        % Create list
        jList = javax.swing.JList();
        jList.setModel(listModel);
        jList.setLayoutOrientation(jList.HORIZONTAL_WRAP);
        jList.setVisibleRowCount(-1);

        % Get selected indices
        sCurProcess = GlobalData.Processes.Current(iProcess);
        if ~isempty(sCurProcess.options.(optName).Value)
            labels = {sCurProcess.options.(optName).Value.Label};
        else
            labels = {};
        end
        % If a selection has already been made for this option
        if ~isempty(labels)
            % Get the selected clusters indices
            iSelClusters = [];
            for i = 1:length(labels)
                iSelClusters = [iSelClusters, find(strcmpi(labels{i}, {sClusters.Label}))];
            end
        elseif ~isempty(iSelClusters)
            sCurProcess.options.(optName).Value = sClusters(iSelClusters);
        end
        if ~isempty(iSelClusters)
            jList.setSelectedIndices(iSelClusters - 1);
        end
    end

    %% ===== OPTIONS: CLUSTER CALLBACK =====
    function Cluster_ValueChangedCallback(iProcess, optName, sClusters, jList, jCheck, ev)
        % Enable/disable jList
        if ~isempty(jCheck)
            isChecked = jCheck.isSelected();
        else
            isChecked = 1;
        end
        jList.setEnabled(isChecked);
        % If cluster/scout not selected
        if ~isChecked
            SetOptionValue(iProcess, optName, []);
        % If not currently editing
        elseif isempty(ev) || ~ev.getValueIsAdjusting()
            % Get selected clusters
            iSel = jList.getSelectedIndices() + 1;
            % Set value
            SetOptionValue(iProcess, optName, sClusters(iSel));
        end
    end


    %% ===== OPTIONS: SET OPTION VALUE =====
    function SetOptionValue(iProcess, optName, value)
        % Check for weird effects of events processed in the wrong order
        if (iProcess > length(GlobalData.Processes.Current)) || ~isfield(GlobalData.Processes.Current(iProcess).options, optName)
            return;
        end
        % Update value
        GlobalData.Processes.Current(iProcess).options.(optName).Value = value;
        % Update list
        UpdateProcessesList();
        % Save option value for future uses
        optType = GlobalData.Processes.Current(iProcess).options.(optName).Type;
        if ismember(optType, {'value', 'range', 'checkbox', 'radio', 'text', 'textarea', 'channelname', 'subjectname', 'atlas', 'groupbands'}) || (strcmpi(optType, 'filename') && (length(value)>=7) && strcmpi(value{7},'dirs') && strcmpi(value{3},'save'))            
            % Get processing options
            ProcessOptions = bst_get('ProcessOptions');
            % Save option value
            field = [func2str(GlobalData.Processes.Current(iProcess).Function), '__', optName];
            ProcessOptions.SavedParam.(field) = value;
            % Save processing options
            bst_set('ProcessOptions', ProcessOptions);
        end
    end

    %% ===== TEXT: GET VALUE =====
    function val = GetValue(jText, valUnits)
        % Get and check value
        val = str2num(char(jText.getText()));
        if isempty(val)
            val = [];
        end
        % If units are defined and milliseconds: convert to ms
        if (nargin >= 2) && ~isempty(valUnits)
            if strcmpi(valUnits, 'ms')
                val = val / 1000;
            end
        end
    end


%% =========================================================================
%  ===== LOAD/SAVE FUNCTIONS ===============================================
%  =========================================================================
    %% ===== SAVE PIPELINE =====
    function SavePipeline(iPipe)
        % Create new pipeline
        if (nargin < 1) || isempty(iPipe)
            % Ask user the name for the new pipeline
            newName = java_dialog('input', 'Enter a name for the new pipeline:', 'Save pipeline');
            if isempty(newName)
                return;
            end
            % Check if pipeline already exists
            if ~isempty(GlobalData.Processes.Pipelines) && any(strcmpi({GlobalData.Processes.Pipelines.Name}, newName))
                bst_error('This pipeline name already exists.', 'Save pipeline', 0);
                return
            end
            % Create new structure
            newPipeline.Name = newName;
            newPipeline.Processes = GlobalData.Processes.Current;
            % Add to list
            if isempty(GlobalData.Processes.Pipelines)
                GlobalData.Processes.Pipelines = newPipeline;
            else
                GlobalData.Processes.Pipelines(end+1) = newPipeline;
            end
        % Update existing pipeline
        else
            % Ask for confirmation
            isConfirm = java_dialog('confirm', ['Overwrite pipeline "' GlobalData.Processes.Pipelines(iPipe).Name '"?'], 'Save pipeline');
            % Overwrite existing entry
            if isConfirm
                GlobalData.Processes.Pipelines(iPipe).Processes = GlobalData.Processes.Current;
            end
        end
    end


    %% ===== EXPORT PIPELINE =====
    function ExportPipeline()
        % USING FILE_SELECT BECAUSE OF WEIRD CRASHES WITH COMBINATION OF TF OPTIONS AND JAVA_GETFILE
        OutputFile = file_select('save', 'Save pipeline', 'pipeline_new.mat', {'*.mat', 'Brainstorm processing pipelines (pipeline*.mat)'});
        if isempty(OutputFile)
            return;
        end
        % Create new structure
        s.Processes = GlobalData.Processes.Current;
        % Save new pipeline
        bst_save(OutputFile, s, 'v7');
    end


    %% ===== SHOW PIPELINE LOAD MENU =====
    function ShowPipelineMenu(jButton)
        import org.brainstorm.icon.*;
        % Create popup menu
        jPopup = java_create('javax.swing.JPopupMenu');
        % === LOAD PIPELINE ===
        % Load pipeline
        jMenuLoad = gui_component('Menu', jPopup, [], 'Load', IconLoader.ICON_FOLDER_OPEN, [], [], []);
        % List all the pipelines
        for iPipe = 1:length(GlobalData.Processes.Pipelines)
            gui_component('MenuItem', jMenuLoad, [], GlobalData.Processes.Pipelines(iPipe).Name, IconLoader.ICON_CONDITION, [], @(h,ev)LoadPipeline(iPipe));
        end
        % Load from file
        gui_component('MenuItem', jPopup, [], 'Load from .mat file', IconLoader.ICON_FOLDER_OPEN, [], @(h,ev)LoadPipelineFromFile());
        jPopup.addSeparator();
        
        % === SAVE PIPELINE ===
        % If some processes are defined
        if ~isempty(GlobalData.Processes.Current)
            % Save pipeline
            jMenuSave = gui_component('Menu', jPopup, [], 'Save', IconLoader.ICON_SAVE, [], [], []);
            % List all the pipelines
            for iPipe = 1:length(GlobalData.Processes.Pipelines)
                gui_component('MenuItem', jMenuSave, [], GlobalData.Processes.Pipelines(iPipe).Name, IconLoader.ICON_SAVE, [], @(h,ev)SavePipeline(iPipe));
            end
            % Separator
            if ~isempty(GlobalData.Processes.Pipelines)
                jMenuSave.addSeparator();
            end
            % Save new
            gui_component('MenuItem', jMenuSave, [], 'New...', IconLoader.ICON_SAVE, [], @(h,ev)SavePipeline());
            % Save as
            gui_component('MenuItem', jPopup, [], 'Save as .mat file', IconLoader.ICON_MATLAB, [], @(h,ev)ExportPipeline());
            jPopup.addSeparator();
            % Generate script
            gui_component('MenuItem', jPopup, [], 'Generate .m script', IconLoader.ICON_MATLAB, [], @(h,ev)GenerateMatlabScript(1));
            jPopup.addSeparator();
        end
        
        % === DELETE PIPELINE ===
        jMenuDel = gui_component('Menu', jPopup, [], 'Delete', IconLoader.ICON_DELETE, [], [], []);
        % List all the pipelines
        for iPipe = 1:length(GlobalData.Processes.Pipelines)
            gui_component('MenuItem', jMenuDel, [], GlobalData.Processes.Pipelines(iPipe).Name, IconLoader.ICON_CONDITION, [], @(h,ev)DeletePipeline(iPipe));
        end
        
        % === RESET OPTIONS ===
        jPopup.addSeparator();
        gui_component('MenuItem', jPopup, [], 'Reset options', IconLoader.ICON_RELOAD, [], @(h,ev)ResetOptions, []);
        
        % Show popup menu
        jPopup.show(jButton, 0, jButton.getHeight());
    end


    %% ===== LOAD PIPELINE =====
    function LoadPipeline(iPipeline)
        bst_progress('start', 'Load pipeline', 'Loading...');
        % Select first item in the pipeline
        if ~isempty(GlobalData.Processes.Current)
            jListProcess.setSelectedIndex(0);
        end
        % Replace existing list with saved list
        GlobalData.Processes.Current = GlobalData.Processes.Pipelines(iPipeline).Processes;
        % Load file time is possible
        TimeVector = FindRawFileTime(GlobalData.Processes.Current);
        if ~isempty(TimeVector)
            FileTimeVector = TimeVector;
        end
        % Update pipeline
        UpdatePipeline();
        bst_progress('stop');
    end


    %% ===== DELETE PIPELINE =====
    function DeletePipeline(iPipeline)
        % Ask confirmation
        if ~java_dialog('confirm', ['Delete pipeline "' GlobalData.Processes.Pipelines(iPipeline).Name '"?'], 'Processing pipeline');
            return;
        end    
        % Select first item in the pipeline
        GlobalData.Processes.Pipelines(iPipeline) = [];
        % Replace existing list with saved list
        GlobalData.Processes.Current = [];
        % Update pipeline
        UpdatePipeline();
    end


    %% ===== LOAD PIPELINE FROM FILE =====
    function LoadPipelineFromFile()
        % USING FILE_SELECT BECAUSE OF WEIRD CRASHES WITH COMBINATION OF TF OPTIONS AND JAVA_GETFILE
        PipelineFile = file_select('open', 'Import processing pipeline', '', {'*.mat', 'Brainstorm processing pipelines (pipeline*.mat)'});
        if isempty(PipelineFile)
            return;
        end
        % Load pipeline file
        newMat = load(PipelineFile);
        if ~isfield(newMat, 'Processes') || isempty(newMat.Processes)
            error('Invalid pipeline file.');
        end
        % Ask user the name for the new pipeline
        newName = java_dialog('input', 'Enter a name for the new pipeline:', 'Save pipeline');
        if isempty(newName)
            return;
        end
        % Check if pipeline already exists
        if ~isempty(GlobalData.Processes.Pipelines) && any(strcmpi({GlobalData.Processes.Pipelines.Name}, newName))
            bst_error('This pipeline name already exists.', 'Save pipeline', 0);
            return
        end
        % Create new structure
        newPipeline.Name = newName;
        newPipeline.Processes = newMat.Processes;
        % Add to list
        if isempty(GlobalData.Processes.Pipelines)
            iPipeline = 1;
            GlobalData.Processes.Pipelines = newPipeline;
        else
            iPipeline = length(GlobalData.Processes.Pipelines) + 1;
            GlobalData.Processes.Pipelines(iPipeline) = newPipeline;
        end
        % Update pipeline
        LoadPipeline(iPipeline);
    end

    
    %% ===== GENERATE MATLAB SCRIPT =====
    function str = GenerateMatlabScript(isSave)
        str = [];
        % Write header
        bstVersion = bst_get('Version');
        str = [str '% Script generated by Brainstorm v' bstVersion.Version ' (' bstVersion.Date ')' 10 10];
        % Write comment
        str = [str '% Input files' 10];
        % Grab all the subject names
        [SubjNames, RawFiles] = GetSeparateInputs(GlobalData.Processes.Current);
        % Write input filenames
        str = [str, WriteFileNames(sFiles,     'sFiles',    1)];
        str = [str, WriteFileNames(sFiles2,    'sFiles2',   0)];
        str = [str, WriteFileNames(SubjNames,  'SubjectNames', 0)];
        str = [str, WriteFileNames(RawFiles,   'RawFiles',     0)];
        str = [str, 10];
        % Reporting
        str = [str '% Start a new report' 10];
        str = [str 'bst_report(''Start'', sFiles);' 10 10];

        % Optimize pipeline
        sExportProc = bst_process('OptimizePipeline', GlobalData.Processes.Current);
        % Loop on each process to apply
        for iProc = 1:length(sExportProc)
            % Process comment
            procComment = sExportProc(iProc).Function('FormatComment', sExportProc(iProc));
            procFunc    = func2str(sExportProc(iProc).Function);
            strIdent    = '    ';
            str = [str '% Process: ' procComment 10];
            % Process call
            str = [str 'sFiles = bst_process(...' 10];
            str = [str strIdent '''CallProcess'', ''' procFunc ''', ...' 10];
            % Print filenames
            if ~isempty(sFiles2)
                str = [str strIdent 'sFiles, sFiles2'];
            else
                str = [str strIdent 'sFiles, []'];
            end
            strComment = '';
            % Options
            if isstruct(sExportProc(iProc).options)
                optNames = fieldnames(sExportProc(iProc).options);
                for iOpt = 1:length(optNames)
                    opt = sExportProc(iProc).options.(optNames{iOpt});
                    % Writing a line for the option
                    if isfield(opt, 'Value')
                        % For some options types: write only the value, not the selection parameters
                        if isfield(opt, 'Type') && ismember(opt.Type, {'timewindow','baseline','poststim','value','range','combobox'}) && iscell(opt.Value)
                            optValue = opt.Value{1};
                        elseif isfield(opt, 'Type') && ismember(opt.Type, {'filename','datafile'}) && iscell(opt.Value)
                            optValue = opt.Value(1:2);
                        else
                            optValue = opt.Value;
                        end
                        % Create final string
                        optStr = [', ...' strComment, 10 strIdent '''' optNames{iOpt} ''', ' str_format(optValue, 1, 2)];
                        % Replace raw filenames and subject names
                        if isfield(opt, 'Type') && ismember(opt.Type, {'filename','datafile'}) && iscell(opt.Value)
                            % List of files
                            if iscell(optValue{1})
                                for ic = 1:length(optValue{1})
                                    iFile = find(strcmpi(RawFiles, optValue{1}{ic}));
                                    optStr = strrep(optStr, ['''' optValue{1}{ic} ''''], ['RawFiles{' num2str(iFile) '}']);  
                                end
                            % Single file
                            else
                                iFile = find(strcmpi(RawFiles, optValue{1}));
                                optStr = strrep(optStr, ['''' optValue{1} ''''], ['RawFiles{' num2str(iFile) '}']);                                
                            end
                        elseif isfield(opt, 'Type') && strcmpi(opt.Type, 'subjectname')
                            iFile = find(strcmpi(SubjNames, optValue));
                            optStr = strrep(optStr, ['''' optValue ''''], ['SubjectNames{' num2str(iFile) '}']);
                        end
                        % Add option to complete text
                        str = [str, optStr];
                        % Add comment for some options types
                        if isfield(opt, 'Type') && isfield(opt, 'Comment') && strcmpi(opt.Type, 'radio')
                            strComment = ['  % ' opt.Comment{opt.Value}];
                        elseif isfield(opt, 'Type') && strcmpi(opt.Type, 'combobox')
                            strComment = ['  % ' opt.Value{2}{opt.Value{1}}];
                        else
                            strComment = '';
                        end
                    else
                        strComment = '';
                    end
                end
            end
            str = [str ');' strComment 10 10];
        end
        % Show report
        str = [str '% Save and display report' 10];
        str = [str 'ReportFile = bst_report(''Save'', sFiles);' 10];
        str = [str 'bst_report(''Open'', ReportFile);' 10 10];
        
        % Save script
        if isSave
            % Get default folders
            LastUsedDirs = bst_get('LastUsedDirs');
            if isempty(LastUsedDirs.ExportScript)
                LastUsedDirs.ExportScript = bst_get('UserDir');
            end
            DefaultOutputFile = bst_fullfile(LastUsedDirs.ExportScript, 'script_new.m');
            % Get file to create
            % USING FILE_SELECT BECAUSE OF WEIRD CRASHES WITH COMBINATION OF TF OPTIONS AND JAVA_GETFILE
            ScriptFile = file_select('save', 'Generate Matlab script', DefaultOutputFile, {'*.m', 'Matlab script (*.m)'});
            if isempty(ScriptFile)
                return;
            end
            
            % Save new default export path
            LastUsedDirs.ExportScript = bst_fileparts(ScriptFile);
            bst_set('LastUsedDirs', LastUsedDirs);
            % Open file
            fid = fopen(ScriptFile, 'wt');
            if (fid == -1)
                error('Cannot open file.');
            end
            % Write file
            fwrite(fid, str);
            % Close file
            fclose(fid);
            % Open in editor
            try
                edit(ScriptFile);
            catch
            end
        % View script
        else
            view_text(str, 'Generated Matlab script');
        end
    end


    %% ===== RESET OPTIONS =====
    function ResetOptions()
        % Reset all the saved options
        bst_set('ProcessOptions', []);
        % Empty list of selected processes
        GlobalData.Processes.Current = [];
        % Update pipeline
        UpdatePipeline();
    end
end


%% =========================================================================
%  ===== EXTERNAL FUNCTION =================================================
%  =========================================================================
%% ===== GET PANEL CONTENTS =====
function sProcesses = GetPanelContents()
    % Get edited processes in global variable
    global GlobalData;
    sProcesses = GlobalData.Processes.Current;
    % Empty global variable
    GlobalData.Processes.Current = [];
    % Loop through the processes, and convert back some options
    for iProc = 1:length(sProcesses)
        % Absolute values of sources
        if isfield(sProcesses(iProc).options, 'source_abs')
            sProcesses(iProc).isSourceAbsolute = sProcesses(iProc).options.source_abs.Value;
        elseif (sProcesses(iProc).isSourceAbsolute < 0)
            sProcesses(iProc).isSourceAbsolute = 0;
        elseif (sProcesses(iProc).isSourceAbsolute > 1)
            sProcesses(iProc).isSourceAbsolute = 1;
        end
    end
end

%% ===== PARSE PROCESS FOLDER =====
function ParseProcessFolder(isForced) %#ok<DEFNU>
    global GlobalData;
    % Parse inputs
    if (nargin < 1) || isempty(isForced)
        isForced = 0;
    end
    
    % ===== LIST PROCESS FILES =====
    % Get the contents of sub-folder "functions"
    bstList = dir(bst_fullfile(bst_fileparts(mfilename('fullpath')), 'functions', 'process_*.m'));
    bstFunc = {bstList.name};
    % Get the contents of user's custom processes (~user/.brainstorm/process)
    usrList = dir(bst_fullfile(bst_get('UserProcessDir'), 'process_*.m'));
    usrFunc = {usrList.name};
    % Display warning for overridden processes
    override = intersect(usrFunc, bstFunc);
    for i = 1:length(override)
        disp(['BST> ' override{i} ' overridden by user (' bst_get('UserProcessDir') ')']);
    end
    % Final list of processes
    bstFunc = union(usrFunc, bstFunc);

    % ===== CHECK FOR MODIFICATIONS =====
    % Build a signature for both folders
    sig = '';
    for i = 1:length(bstList)
        sig = [sig, bstList(i).name, bstList(i).date, num2str(bstList(i).bytes)];
    end
    for i = 1:length(usrList)
        sig = [sig, usrList(i).name, usrList(i).date, num2str(usrList(i).bytes)];
    end
    % If signature is same as previously: do not reload all the files
    if ~isForced
        if isequal(sig, GlobalData.Processes.Signature)
            return;
        else
            disp('BST> Processes functions were modified: Reloading...'); 
        end
    end
    % Save current folder signature
    GlobalData.Processes.Signature = sig;
    
    % ===== GET PROCESSES DESCRIPTION =====
    % Returned variable
    defProcess = db_template('ProcessDesc');
    sProcesses = repmat(defProcess, 0);
    % Get description for each file
    for iFile = 1:length(bstFunc)
        % Get function handle
        Function = str2func(strrep(bstFunc{iFile}, '.m', ''));
        % Call description function
        try
            desc = Function('GetDescription');
        catch
            disp(['BST> Invalid plug-in function in /toolbox/process/functions/: "' bstFunc{iFile} '"']);
            continue;
        end
        % Ignore if Index is set to 0
        if (desc.Index == 0)
            continue;
        end
        % Copy fields to returned structure
        iProc = length(sProcesses) + 1;
        sProcesses(iProc) = defProcess;
        sProcesses(iProc) = struct_copy_fields(sProcesses(iProc), desc);
        sProcesses(iProc).Function = Function;
        
        % === ADD CATEGORY OPTIONS ===
        switch (sProcesses(iProc).Category)
            case 'Filter'
                if ~isfield(sProcesses(iProc).options, 'overwrite')
                    sProcesses(iProc).options.overwrite.Comment    = 'Overwrite input files';
                    sProcesses(iProc).options.overwrite.Type       = 'checkbox';
                    sProcesses(iProc).options.overwrite.Value      = 1;
                    sProcesses(iProc).options.overwrite.InputTypes = {'data', 'results', 'timefreq', 'matrix'};
                end
        end
    end
    % Order processes with the Index value
    [tmp__, iSort] = sort([sProcesses.Index]);
    sProcesses = sProcesses(iSort);
    % Save in global structure
    GlobalData.Processes.All = sProcesses;
end


%% ===== SET DEFAULT OPTIONS =====
function sProcesses = SetDefaultOptions(sProcesses, FileTimeVector, UseDefaults)
    % Parse inputs 
    if (nargin < 3) || isempty(UseDefaults)
        UseDefaults = 1;
    end
    if (nargin < 2) || isempty(FileTimeVector)
        FileTimeVector = [];
    end
    % Get processing options
    ProcessOptions = bst_get('ProcessOptions');
    % For each process
    for iProcess = 1:length(sProcesses)
        % No options: next process
        if isempty(sProcesses(iProcess).options)
            continue;
        end
        % Get all the options
        optNames = fieldnames(sProcesses(iProcess).options);
        % Add list of options
        for iOpt = 1:length(optNames)
            % Get option
            option = sProcesses(iProcess).options.(optNames{iOpt});
            % Do not add default values to Hidden options
            if isfield(option, 'Hidden') && isequal(option.Hidden, 1)
                continue;
            end
            % Check for option integrity
            if ~isfield(option, 'Type') || ~isfield(option, 'Comment') || ~isfield(option, 'Value')
                if ~isfield(option, 'Type') || (~strcmpi(option.Type, 'label') && ~strcmpi(option.Type, 'separator'))
                    disp(['BST> ' func2str(sProcesses(iProcess).Function) ': Invalid option "' optNames{iOpt} '"']);
                end
                continue;
            end
            % Option type
            switch (option.Type)
                case {'timewindow', 'baseline', 'poststim'}
                    if ~isempty(FileTimeVector)
                        % Define initial values
                        if strcmpi(option.Type, 'baseline') && (FileTimeVector(1) < 0) && (FileTimeVector(end) > 0)
                            iStart = 1;
                            iEnd = bst_closest(0, FileTimeVector);
                            if (iEnd > 1)
                                iEnd = iEnd - 1;
                            end
                        elseif strcmpi(option.Type, 'poststim') && (FileTimeVector(1) < 0) && (FileTimeVector(end) > 0)
                            iStart = bst_closest(0, FileTimeVector);
                            iEnd   = length(FileTimeVector);
                        elseif strcmpi(option.Type, 'timewindow') 
                            iStart = 1;
                            iEnd   = length(FileTimeVector);
                        else
                            iStart = 1;
                            iEnd   = length(FileTimeVector);
                        end
                        % Final option
                        option.Value = {[FileTimeVector(iStart), FileTimeVector(iEnd)], 'time', []};
                    end
            end
            % Override with previously defined values
            if UseDefaults
                % Define field name: process__option
                field = [func2str(sProcesses(iProcess).Function), '__', optNames{iOpt}];
                % If this field was saved in the user preferences, and if is of the correct type
                if isfield(ProcessOptions.SavedParam, field) && strcmpi(class(ProcessOptions.SavedParam.(field)), class(option.Value))
                    % Radio button: check the index of the selection
                    if strcmpi(option.Type, 'radio') && (ProcessOptions.SavedParam.(field) > length(option.Comment))
                        % Error: ignoring previous option
                    % Value: restore the 'time' units, if it was updated
                    elseif strcmpi(option.Type, 'value') && iscell(option.Value) && strcmpi(option.Value{2}, 'time')
                        option.Value = ProcessOptions.SavedParam.(field);
                        option.Value{2} = 'time';
                    % Else: use the saved option
                    else
                        option.Value = ProcessOptions.SavedParam.(field);
                    end
                end
            end
            % Update option
            sProcesses(iProcess).options.(optNames{iOpt}) = option;
        end
    end
end


%% ===== GET PROCESS =====
% USAGE:  sProcesses = panel_process_select('GetProcess')
%           sProcess = panel_process_select('GetProcess', ProcessName)
function sProcess = GetProcess(ProcessName)
    global GlobalData;
    % Parse inputs
    if (nargin == 0)
        ProcessName = [];
    end
    % Get selected process
    if isempty(ProcessName)
        sProcess = GlobalData.Processes.All;
    else
        iProc = [];
        % Look for process name
        for i = 1:length(GlobalData.Processes.All)
            strFunc = func2str(GlobalData.Processes.All(i).Function);
            if strcmpi(strFunc, ProcessName)
                iProc = i;
                break;
            end
        end
        % Return process if found
        if ~isempty(iProc)
            sProcess = GlobalData.Processes.All(iProc);
        else
            sProcess = [];
        end
    end
end


%% ===== SELECT FILE AND OPEN PANEL =====
function [sOutputs, sProcesses] = ShowPanelForFile(FileNames, ProcessNames) %#ok<DEFNU>
    % Add files
    panel_nodelist('ResetAllLists');
    panel_nodelist('AddFiles', 'Process1', FileNames);
    % Load Time vector
    FileTimeVector = in_bst(FileNames{1}, 'Time');
    % Load the processes in the pipeline editor
    [sOutputs, sProcesses] = panel_process_select('ShowPanel', FileNames, ProcessNames, FileTimeVector);
end

%% ===== OPEN PANEL =====
% Open the pipeline editor with one or more processes already selected
% USAGE:  [sOutputs, sProcesses] = ShowPanel(FileNames, ProcessNames, FileTimeVector=[])
%         [sOutputs, sProcesses] = ShowPanel(FileNames, sProcesses)
function [sOutputs, sProcesses] = ShowPanel(FileNames, ProcessNames, FileTimeVector) %#ok<DEFNU>
    global GlobalData;
    % Parse inputs
    if (nargin < 3) || isempty(FileTimeVector)
        FileTimeVector = [];
    end
    if isempty(ProcessNames)
        error('Invalid call');
    end
    if ~isempty(FileNames) && ~iscell(FileNames)
        FileNames = {FileNames};
    end
    if isstruct(ProcessNames)
        sSelProcesses = ProcessNames;
    elseif ischar(ProcessNames)
        ProcessNames = {ProcessNames};
        sSelProcesses = [];
    end
    sProcesses = [];
    sOutputs = [];
    % Get files structures
    if ~isempty(FileNames)
        sInputs = bst_process('GetInputStruct', FileNames);
        if isempty(sInputs)
            return
        end
    else
        sInputs = db_template('importfile');
    end
    % If providing the process name: get the structure
    if isempty(sSelProcesses)
        % Find processes indices
        for i = 1:length(ProcessNames)
            tmp = GetProcess(ProcessNames{i});
            if isempty(tmp)
                error(['Unknown process name: "' ProcessNames{i} '"']);
            elseif isempty(sSelProcesses)
                sSelProcesses = tmp;
            else
                sSelProcesses = [sSelProcesses, tmp];
            end
        end
        % Set default values (previously used)
        sSelProcesses = SetDefaultOptions(sSelProcesses, FileTimeVector);
    end
    % Load file time is possible
    TimeVector = FindRawFileTime(sSelProcesses);
    % Expand optimized pipelines
    sSelProcesses = bst_process('OptimizePipelineRevert', sSelProcesses);
    % Open pipeline editor
    [bstPanel, panelName] = CreatePanel(sInputs, [], TimeVector);
    gui_show(bstPanel, 'JavaWindow', 'Pipeline editor', [], 0, 1, 0);
    sControls = get(bstPanel, 'sControls');
    % Add processes
    GlobalData.Processes.Current = sSelProcesses;
    sControls.UpdatePipeline();
    % Wait for the end of execution
    bst_mutex('waitfor', panelName);
    % Check if panel is still existing (if user did not abort the operation)
    if gui_brainstorm('isTabVisible', get(bstPanel,'name'))
        % Try to execute 'GetPanelContents'
        sProcesses = GetPanelContents();
        % Close panel
        gui_hide(bstPanel);
    else
        % User cancelled the operation
        return;
    end
    % Empty process list
    if isempty(sProcesses)
        return;
    end
    % Call process function
    sOutputs = bst_process('Run', sProcesses, sInputs, [], 1);
end

%% ===== FIND RAW FILE =====
function TimeVector = FindRawFileTime(sProcesses)
    TimeVector = [];
    for iProc = 1:length(sProcesses)
        if isfield(sProcesses(iProc).options, 'datafile') && ~isempty(sProcesses(iProc).options.datafile.Value) && ~isempty(sProcesses(iProc).options.datafile.Value{1})
            RawFile = sProcesses(iProc).options.datafile.Value{1};
            if iscell(RawFile)
                RawFile = RawFile{1};
            end
            FileFormat = sProcesses(iProc).options.datafile.Value{2};
            TimeVector = LoadRawTime(RawFile, FileFormat);
            break;
        end
    end
end

%% ===== LOAD RAW TIME =====
function TimeVector = LoadRawTime(RawFile, FileFormat)
    TimeVector = [];
    % Open file, just to get the new file vector
    ImportOptions = db_template('ImportOptions');
    ImportOptions.EventsMode      = 'ignore';
    ImportOptions.ChannelAlign    = 0;
    ImportOptions.DisplayMessages = 0;
    try
        sFile = in_fopen(RawFile, FileFormat, ImportOptions);
        if isempty(sFile)
            return
        end
    catch
        bst_error(['Could not open the following file as "' FileFormat '":' 10 RawFile 10 10 'Please try again selecting another file format or import mode.'], 'Import MEG/EEG recordings', 0);
        return;
    end
    % Update time vector
    if ~isempty(sFile.epochs)
        NumberOfSamples = sFile.epochs(1).samples(2) - sFile.epochs(1).samples(1) + 1;
        TimeVector = linspace(sFile.epochs(1).times(1), sFile.epochs(1).times(2), NumberOfSamples);
    else
        NumberOfSamples = sFile.prop.samples(2) - sFile.prop.samples(1) + 1;
        TimeVector = linspace(sFile.prop.times(1), sFile.prop.times(2), NumberOfSamples);
    end
end
    

%% ===== GET PROCESS TIME VECTOR =====
function [procTimeVector, nFiles] = GetProcessFileVector(sProcesses, FileTimeVector, nFiles)
    % Default value
    procTimeVector = FileTimeVector;
    if isempty(sProcesses)
        return;
    end
    % Look for an epoching process that changes the time vector of the files
    for iProc = 1:length(sProcesses)
        % Recalculate the frequency at this process
        procSampleFreq = 1 ./ (procTimeVector(2) - procTimeVector(1));
        % Processes names
        switch func2str(sProcesses(iProc).Function) 
            case 'process_import_data_event'
                % Get the epoch time range
                EventsTimeRange = sProcesses(iProc).options.epochtime.Value{1};
                % Build the epoch time vector
                EventsSampleRange = round(EventsTimeRange * procSampleFreq);
                procTimeVector = (EventsSampleRange(1):EventsSampleRange(2)) / procSampleFreq;
                % Increase the number of available files
                nFiles = 10 + zeros(size(nFiles));
            case {'process_import_data_epoch', 'process_import_data_time'}
                % Increase the number of available files
                nFiles = 10 + zeros(size(nFiles));
            case 'process_resample'
                newFreq = sProcesses(iProc).options.freq.Value{1};
                procTimeVector = linspace(procTimeVector(1), procTimeVector(end), round(newFreq / procSampleFreq * length(procTimeVector)));
            case 'process_timeoffset'
                procTimeVector = procTimeVector + sProcesses(iProc).options.offset.Value{1};
            case 'process_average_time'
                procTimeVector = [procTimeVector(1), procTimeVector(end)];
            case 'process_extract_time'
                optVal = sProcesses(iProc).options.timewindow.Value;
                if ~isempty(optVal) && iscell(optVal)
                    iTime = panel_time('GetTimeIndices', procTimeVector, optVal{1});
                    procTimeVector = procTimeVector(iTime);
                end
        end
    end
end


%% ===== SCRIPT: GET SEPARATE INPUT =====
function [SubjNames, RawFiles] = GetSeparateInputs(sProcesses)
    % Initialize returned variables
    SubjNames = {};
    RawFiles = {};
    % Loop on each process
    for iProc = 1:length(sProcesses)
        % No options: skip
        if ~isstruct(sProcesses(iProc).options) || isempty(sProcesses(iProc).options)
            continue;
        end
        % Loop on options
        optNames = fieldnames(sProcesses(iProc).options);
        for iOpt = 1:length(optNames)
            % Get option
            opt = sProcesses(iProc).options.(optNames{iOpt});
            % If the options is not complete: skip
            if ~isfield(opt, 'Value') || isempty(opt.Value) || ~isfield(opt, 'Type') || isempty(opt.Type)
                continue;
            end
            % Subject name
            if strcmpi(opt.Type, 'subjectname')
                iFile = find(strcmpi(SubjNames, opt.Value));
                if isempty(iFile)
                    SubjNames{end+1} = opt.Value;
                end
            % Raw files
            elseif ismember(opt.Type, {'datafile', 'filename'}) && iscell(opt.Value)
                % Multiple files
                if iscell(opt.Value{1})
                    for ic = 1:length(opt.Value{1})
                        iFile = find(strcmpi(RawFiles, opt.Value{1}{ic}));
                        if isempty(iFile)
                            RawFiles{end+1} = opt.Value{1}{ic};
                        end
                    end
                else
                    iFile = find(strcmpi(RawFiles, opt.Value{1}));
                    if isempty(iFile)
                        RawFiles{end+1} = opt.Value{1};
                    end
                end
            end
        end
    end
end


%% ===== SCRIPT: WRITE FILENAMES =====
%  USAGE:  str = WriteFileNames(FileNames, VarName, isDefault)
%          str = WriteFileNames(sFiles,    VarName, isDefault)
function str = WriteFileNames(FileNames, VarName, isDefault)
    % Initialize output
    str = [];
    % Parse inputs
    if isstruct(FileNames)
        FileNames = {FileNames.FileName};
    end
    % Empty entry
    if isempty(FileNames) || ((length(FileNames) == 1) && isempty(FileNames{1}))
        % Display only if it is really needed (default variable)
        if isDefault
            str = [str VarName ' = [];' 10];
        end
    % Write file list
    else
        str = [str VarName ' = {...' 10];
        for i = 1:length(FileNames)
            str = [str '    ''' FileNames{i} ''''];
            if (i ~= length(FileNames))
                str = [str ', ...' 10];
            else
                str = [str '};' 10];
            end
        end
    end
end


