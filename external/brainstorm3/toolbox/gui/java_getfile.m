function [ fileList, fileFormat, fileFilter ] = java_getfile( DialogType, WindowTitle, DefaultDir, SelectionMode, FilesOrDir, Filters, defaultFilter)
% JAVA_GETFILE: Java-based file selection for opening and saving.
%
% USAGE: [fileList, fileFormat, fileFilter] = java_getfile(DialogType,WindowTitle,DefaultDir,SelectionMode, FilesOrDir,Filters,defaultFilter)
%
% INPUT :
%    - DialogType    : {'open', 'save'}
%    - WindowTitle   : String
%    - DefaultDir    : To ignore, set to []
%    - SelectionMode : {'single', 'multiple'}
%    - FilesOrDir    : {'files', 'dirs', 'files_and_dirs'}
%    - Filters       : {NbFilters x 2} cell array
%                      Filters(i,:) = {{'.ext1', '.ext2', '_tag1'...}, Description}
%    - defaultFilter : can be 1) the index of the default file filter
%                             2) the name of the filer to be used
% OUTPUT:
%    - fileList      : Cell-array of strings, full paths to the files that were selected
%    - fileFormat    : String that represents the format of the files that were selected
%    - fileFilter    : File filter that was selected when selecting the files

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

import org.brainstorm.file.*;

global GlobalData FileSelectorStatus;

%% ===== CONFIGURE DIALOG =====
% Initialize returned variables
fileList   = {};
fileFormat = '';
fileFilter = [];

% DialogType
if strcmpi(DialogType, 'save')
    DialogType = BstFileSelector.TYPE_SAVE;
else
    DialogType = BstFileSelector.TYPE_OPEN;
end
% SelectionMode
if strcmpi(SelectionMode, 'multiple')
    SelectionMode = BstFileSelector.SELECTION_MULTIPLE;
else
    SelectionMode = BstFileSelector.SELECTION_SINGLE;
end
% Files and/or directories
switch lower(FilesOrDir)
    case 'dirs'
        FilesOrDir = BstFileSelector.DIRECTORIES_ONLY;
    case 'files_and_dirs'
        FilesOrDir = BstFileSelector.FILES_AND_DIRECTORIES;
    otherwise
        FilesOrDir = BstFileSelector.FILES_ONLY;
end


% Filters
iDefaultFileFilter = 1;
for i=1:size(Filters, 1)
    % Filters cell array has the following format:
    %   - One row per filter,
    %   - A filter row can be {{'extensions_list'}, 'Description', 'FormatName'}
    %                      or {{'extensions_list'}, 'Description'}
    if (size(Filters, 2) == 3)
        fileFilters(i) = BstFileFilter(Filters{i,1}, Filters{i,2}, Filters{i,3});
    else
        fileFilters(i) = BstFileFilter(Filters{i,1}, Filters{i,2});
    end
    % If it is default file filter
    if ~isempty(defaultFilter) && (isnumeric(defaultFilter) && (i == defaultFilter)) || ...
            (ischar(defaultFilter) && (size(Filters, 2) == 3) && strcmpi(Filters{i,3}, defaultFilter))
        iDefaultFileFilter = i; 
    end
end

% If a progress bar is displayed : hide it while displaying the file selector
pBar = GlobalData.Program.ProgressBar;
if ~isempty(pBar) && isfield(pBar, 'jWindow') && pBar.jWindow.isVisible()
    pBarHidden = 1;
    bst_progress('hide');
else
    pBarHidden = 0;
end


%% ===== HIDE MODAL WINDOWS =====
% Get brainstorm frame
jBstFrame = bst_get('BstFrame');
% If the frame is defined
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


%% ===== CREATE SELECTION DIALOG =====
jSelector = BstFileSelector(DialogType, ...
                         WindowTitle, ...
                         DefaultDir, ...
                         SelectionMode, ...
                         FilesOrDir, ...
                         fileFilters, ...
                         iDefaultFileFilter - 1);
% Initialize a mutex (a figure that will be closed in the BstFileSelector close callback)
bst_mutex('create', 'FileSelector');
FileSelectorStatus = 0;
% Set dialog callback 
java_setcb(jSelector.getJFileChooser(), 'ActionPerformedCallback', @FileSelectorAction, ...
                                        'PropertyChangeCallback',  @FileSelectorPropertyChanged);
% Display file selector
jSelector.show();
bst_mutex('waitfor', 'FileSelector');


%% ===== PROCESS SELECTED FILES =====
% If user clicked OK after having selected a valid file
if FileSelectorStatus
    % Get file filter => file format
    fileFilter = jSelector.getJFileChooser.getFileFilter();
    fileFormat = char(fileFilter.getFormatName());
    
    % If multiple selection
    if (SelectionMode == BstFileSelector.SELECTION_MULTIPLE)    
        % Get selected files
        fs = jSelector.getJFileChooser.getSelectedFiles();
        % Convert them to a cell array of filenames
        fileList = cell(length(fs), 1);
        for i=1:length(fs)
            fileList{i} = char(fs(i).getAbsolutePath());
        end
    % Else: single selection
    else
        % Get selected file
        fileList = char(jSelector.getJFileChooser.getSelectedFile());
        
        % If SAVE dialog
        if (DialogType == BstFileSelector.TYPE_SAVE)
            % Get required extension
            suffix = fileFilter.getSuffixes();
            suffix = char(suffix(1));
            % Replace current extension with required extension (ONLY IF SUFFIX IS EXTENSION)
            if (suffix(1) == '.') && ~isequal(suffix, '.folder')
                [selPath, selBase, selExt] = bst_fileparts(fileList);
                fileList = bst_fullfile(selPath, [selBase, suffix]);
            end
            
            % If file already exist
            if file_exist(fileList) && ~isequal(suffix, '.folder')
                if ~java_dialog('confirm', sprintf('File already exist.\nDo you want to overwrite it?'), 'Save file')
                    fileList = [];
                    fileFormat = [];
                    fileFilter = [];
                end
            end
        end
    end
else
    fileList = [];
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
if pBarHidden
    bst_progress('show');
end



%% ===== CALLBACK FUNCTION =====
    function FileSelectorAction(h, ev)
        switch (char(ev.getActionCommand()))
            case 'ApproveSelection'
                FileSelectorStatus = 1;
            otherwise
                FileSelectorStatus = 0;
        end
        % Release mutex
        bst_mutex('release', 'FileSelector');
    end

    function FileSelectorPropertyChanged(h, ev)
        import org.brainstorm.file.*;
        % Only when saving 
        if (DialogType == BstFileSelector.TYPE_SAVE)
            switch char(ev.getPropertyName())
                case 'fileFilterChanged'
                    % Get old filter
                    %oldFilter = ev.getOldValue();
                    % Get new filter
                    newFilter = ev.getNewValue();
                    % New suffix
                    newSuffix = newFilter.getSuffixes();
                    newSuffix = char(newSuffix(1));
                    if isequal(newSuffix, '.folder')
                        newSuffix = '';
                    end
                    % Get old filename 
                    selFile = jSelector.getJFileChooser().getSelectedFile();
                    if isempty(selFile)
                        oldFilename = DefaultDir;
                    else
                        oldFilename = char(jSelector.getJFileChooser().getSelectedFile().getAbsolutePath());
                    end

                    % Replace old extension by new one
                    [fPath, fBase, fExt] = bst_fileparts(oldFilename);
                    % Brainstorm or external file
                    if ~isempty(newSuffix) && (newSuffix(1) == '_')
                        fBase = strrep(fBase, ['_' newSuffix(2:end)], '');
                        fBase = strrep(fBase, [newSuffix(2:end) '_'], '');
                        fBase = [newSuffix(2:end) '_' fBase];
                        fExt  = '.mat';
                    else
                        fExt = newSuffix;
                    end
                    newFilename = bst_fullfile(fPath, [fBase, fExt]);

                    jSelector.getJFileChooser.setSelectedFile(java.io.File(newFilename))
                    % Update default filename


                case 'directoryChanged'
                    DefaultDir = strrep(DefaultDir, char(ev.getOldValue()), char(ev.getNewValue()));
            end
        end
    end
end




    
