function varargout = panel_process2(varargin)
% PANEL_PROCESS2: Creation and management of samples sets.
%
% USAGE:  bstPanelNew = panel_process2('CreatePanel')

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
function bstPanelNew = CreatePanel()
    panelName = 'Process2';
    % Java initializations
    import java.awt.*;
    import javax.swing.*;
    
    % Create two lists of nodes
    jPanelNew = java_create('javax.swing.JPanel');
    jPanelNew.setLayout(BoxLayout(jPanelNew, BoxLayout.LINE_AXIS));
    nodelistA = panel_nodelist('CreatePanel', 'Process2A', 'Files A', 'tree');
    jPanelNew.add(nodelistA.jPanel);
    nodelistB = panel_nodelist('CreatePanel', 'Process2B', 'Files B', 'tree');
    jPanelNew.add(nodelistB.jPanel);
    
    % Create the BstPanel object that is returned by the function
    % => constructor BstPanel(jHandle, panelName, sControls)
    bstPanelNew = BstPanel(panelName, ...
                           jPanelNew, ...
                           struct('nodelistA', nodelistA, ...
                                  'nodelistB', nodelistB));
end




%% =========================================================================
%  ===== PROCESSING FUNCTIONS ==============================================
%  =========================================================================
%% ===== RUN STATS =====
function sOutputs = RunProcess(varargin) %#ok<DEFNU>
    nodelistNameA = 'Process2A';
    nodelistNameB = 'Process2B';
    % Get files
    sFilesA = panel_nodelist('GetFiles', nodelistNameA);
    sFilesB = panel_nodelist('GetFiles', nodelistNameB);
    if isempty(sFilesA) || isempty(sFilesB)
        return
    end
    % Warning for read-only
    if bst_get('ReadOnly')
        java_dialog('warning', ['The protocol is opened in read-only mode.' 10 ...
                                'All the processes will crash because they cannot save the results.' 10], ...
                                'Read-only');
    end
    % Check for RAW files in Process2 tab
    if any(strcmpi({sFilesA.FileType}, 'raw')) || any(strcmpi({sFilesB.FileType}, 'raw'))
        bst_error('Cannot process raw recordings with this tab.', 'Process', 0);
        return;
    end
    % If pipeline editor is already open: close it and open it again
    bstPanel1 = bst_get('Panel', 'ProcessOne');
    if ~isempty(bstPanel1)
        disp('BST> Pipeline editor is already open: closing it...');
        gui_hide(bstPanel1);
    end
    bstPanel2 = bst_get('Panel', 'ProcessTwo');
    if ~isempty(bstPanel2)
        disp('BST> Pipeline editor is already open: closing it...');
        gui_hide(bstPanel2);
    end
    
    % Disable all the controls in the lists
    panel_nodelist('SetListEnabled', 0);
    % Get process to apply
    sProcesses = gui_show_dialog('Pipeline editor', @panel_process_select, 0, [], sFilesA, sFilesB);
    % Enables the controls again
    panel_nodelist('SetListEnabled', 1);
    % No selected processes: nothing to do
    if isempty(sProcesses)
        return
    end   
    
    % Call process function
    sOutputs = bst_process('Run', sProcesses, sFilesA, sFilesB, 1);
    
    % Update files list
    bst_progress('start', 'File selection', 'Updating file count...');
    %panel_nodelist('UpdatePanel', {'Process2A', 'Process2B'}, 1, 0);
    panel_nodelist('CheckContents', 'Process2A');
    panel_nodelist('CheckContents', 'Process2B');
    bst_progress('stop');   
end




