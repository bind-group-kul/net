% TUTORIAL_01_FIRST_STEPS:  Script that follows Brainstorm online tutorial #1: "First steps"
%
% USAGE: 
%     1) Edit the 'bst_db_dir' path
%     2) Run this script
% 
% DESCRIPTION: Illustrates the use of the following functions:
%     - brainstorm nogui      : Start Brainstorm without the displaying the GUI
%     - brainstorm stop       : Stop Brainstorm
%     - bst_set               (VariableName, value)   : Set a Brainstorm variable
%     - db_template           (VariableName)          : Get a default structure
%     - db_delete_protocol    (ProtocolName)          : Delete an existing protocol
%     - db_edit_protocol      ('create', sProtocol)   : Creates a protocol
%     - gui_brainstorm        ('SetCurrentProtocol', iProtocol)                : Set current protocol
%     - db_add_subject        (SubjectName, UseDefaultAnat, UseDefaultChannel) : Add a subject in current protocol

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
% Author: Francois Tadel, 2009

%% ===== TO EDIT =====
% Define the directory where the Brainstorm directory has to be stored
bst_db_dir = 'C:\Francois\Protocols';

%% ===== START BRAINSTORM =====
% Start brainstorm without the GUI
brainstorm nogui
% Define the directory where the brainstorm database is stored
bst_set('BrainstormDbDir', bst_db_dir);


%% ===== CREATE PROTOCOL =====
% Protocol name has to be a valid folder name (no spaces, no weird characters...)
ProtocolName = 'TutorialFirstSteps';       
% Removing existing protocol with the same name
isUserConfirm = 0;
isRemoveFiles = 1;
db_delete_protocol(ProtocolName, isUserConfirm, isRemoveFiles);
% Get default structure for protocol description
sProtocol = db_template('ProtocolInfo');
% Fill with the properties we want to use
sProtocol.Comment  = ProtocolName;
sProtocol.SUBJECTS = fullfile(bst_db_dir, ProtocolName, 'anat');
sProtocol.STUDIES  = fullfile(bst_db_dir, ProtocolName, 'data');
% Create a protocol called 'TutorialCTF' in Brainstorm database
iProtocol = db_edit_protocol('create', sProtocol);
% If an error occured in protocol creation (protocol already exists, impossible to create folders...)
if (iProtocol <= 0)
    error('Could not create protocol.');
end
% Set new protocol as current protocol
gui_brainstorm('SetCurrentProtocol', iProtocol);
% Set Colin27 anatomy as the default anatomy
sColin = bst_get('AnatomyDefaults', 'Colin27');
db_set_template(0, sColin, 0);


%% ===== CREATE SUBJECT =====
SubjectName = 'Subject01';
UseDefaultAnat = 0;
UseDefaultChannel = 0;
[sSubject, iSubject] = db_add_subject(SubjectName, [], UseDefaultAnat, UseDefaultChannel);
% If an error occured in subject creation (subject already exists, impossible to create folders...)
if isempty(sSubject)
    error('Could not create subject.');
end

% Stop brainstorm
%brainstorm stop






