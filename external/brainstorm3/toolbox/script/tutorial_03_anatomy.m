% TUTORIAL_03_ANATOMY:  Script that follows Brainstorm online tutorial #3: "Importing individual anaotmy"
%
% USAGE: 
%     1) Edit the 'tutorial_dir' path
%     2) Edit the 'bst_db_dir' path
%     3) Run this script
% 
% DESCRIPTION: Illustrates the use of the following functions:
%
% - Brainstorm application:
%     - brainstorm nogui
%     - brainstorm stop
%     - bst_get             (VariableName)          : Get a Brainstorm variable
%     - bst_set             (VariableName, value)   : Set a Brainstorm variable
%     - db_template         (VariableName)          : Get a default structure of Brainstorm database
%
% - Protocols:
%     - db_delete_protocol    (ProtocolName)        : Delete an existing protocol
%     - db_edit_protocol      ('create', sProtocol) : Creates a protocol
%     - gui_brainstorm        ('SetCurrentProtocol', iProtocol) : Set current protocol
%
% - Database:
%     - db_set_template       (iSubject, templateDir, CheckFiducials)          : Assign a template anatomy to a subject
%
% - Display:
%     - view_mri         (MriFile)              : View MRI in MRI Viewer
%     - view_mri_slices  (MriFile, 'x', 20)     : View MRI as a list of parallel slices
%     - view_mri_3d      (MriFile, 'NewFigure') : View MRI in 3D figure
%     - view_surface     (NewScalpFile)         : View surface in 3D figure

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
% Author: Francois Tadel, 2009-2013

%% ===== TO EDIT =====
% Define the directory where the bst_sample_ctf.zip file has been unzipped
tutorial_dir = 'C:\Work\RawData\Tutorials\sample_ctf';
% Define the directory where the Brainstorm directory has to be stored
bst_db_dir = 'C:\Work\Protocols';


%% ===== FILES LOCATIONS =====
% Build the files name of the all files to import
MriFile       = fullfile(tutorial_dir, 'Anatomy', '01.nii');
SurfFileHead  = fullfile(tutorial_dir, 'Anatomy', 'BrainVisa', '01_head.mesh');
SurfFileLhemi = fullfile(tutorial_dir, 'Anatomy', 'BrainVisa', '01_Lhemi.mesh');
SurfFileRhemi = fullfile(tutorial_dir, 'Anatomy', 'BrainVisa', '01_Rhemi.mesh');
DsFileRight   = fullfile(tutorial_dir, 'Data', 'somMDYO-18av.ds');
DsFileLeft    = fullfile(tutorial_dir, 'Data', 'somMGYO-18av.ds');
% Check if the folder contains the required files
if ~file_exist(MriFile) || ~file_exist(DsFileRight)
    error(['Please edit this script and change ''tutorial_dir'' to the path where' 10 ...
           'you unzipped the file bst_sample_ctf.zip (downloaded from the website).']);
end

%% ===== START BRAINSTORM =====
% Add brainstorm.m path to the path
addpath(fileparts(fileparts(fileparts(mfilename('fullpath')))));
% Start brainstorm without the GUI
brainstorm nogui
% Define the directory where the brainstorm database is stored
bst_set('BrainstormDbDir', bst_db_dir);


%% ===== CREATE PROTOCOL =====
% Protocol name has to be a valid folder name (no spaces, no weird characters...)
ProtocolName = 'TutorialCTF';       
% Get default structure for protocol description
sProtocol = db_template('ProtocolInfo');
% Fill with the properties we want to use
sProtocol.Comment  = ProtocolName;
sProtocol.SUBJECTS = fullfile(bst_db_dir, ProtocolName, 'anat');
sProtocol.STUDIES  = fullfile(bst_db_dir, ProtocolName, 'data');
sProtocol.UseDefaultAnat    = 0;
sProtocol.UseDefaultChannel = 0;

% Removing existing protocol with the same name
isUserConfirm = 0;
isRemoveFiles = 1;
db_delete_protocol(ProtocolName, isUserConfirm, isRemoveFiles);
% Force to delete pre-existing folders
if file_exist(fullfile(bst_db_dir, ProtocolName))
    rmdir(fullfile(bst_db_dir, ProtocolName), 's');
end

% Create a protocol called 'TutorialCTF' in Brainstorm database
iProtocol = db_edit_protocol('create', sProtocol);
% Set new protocol as current protocol
gui_brainstorm('SetCurrentProtocol', iProtocol);
% Set Colin27 anatomy as the default anatomy (<=> Set anatomy for subject #0)
sColin = bst_get('AnatomyDefaults', 'Colin27');
db_set_template(0, sColin, 0);


%% ===== IMPORT ANATOMY FILES =====
% This section was generated using the pipeline editor interface
SubjectName = 'Subject01';
% Process: Import MRI
bst_process(...
    'CallProcess', 'process_import_mri', [], [], ...
    'subjectname', SubjectName, ...
    'mrifile',     {MriFile}, ...
    'nas',         [115.3, 207.2, 138.8], ...
    'lpa',         [45.9, 128.4, 71.3], ...
    'rpa',         [186.6, 123.8, 83.4], ...
    'ac',          [115.3, 130.3, 132.2], ...
    'pc',          [115.3, 102.2, 133.1], ...
    'ih',          [113.4, 109.7, 184.7]);
% Process: Import surfaces
bst_process(...
    'CallProcess', 'process_import_surfaces', [], [], ...
    'subjectname', SubjectName, ...
    'headfile',    {SurfFileHead, 'MESH'}, ...
    'cortexfile1', {SurfFileLhemi, 'MESH'}, ...
    'cortexfile2', {SurfFileRhemi, 'MESH'}, ...
    'nverthead',   7000, ...
    'nvertcortex', 15000);


%% ===== DISPLAY =====
% Get subject definition
sSubject = bst_get('Subject', SubjectName);
% Get MRI file and surface files
Mri    = sSubject.Anatomy(sSubject.iAnatomy).FileName;
Cortex = sSubject.Surface(sSubject.iCortex).FileName;
Head   = sSubject.Surface(sSubject.iScalp).FileName;

% Display MRI with the MRI Viewer
hFigMri1 = view_mri(Mri);
% Display MRI in parallel slices
hFigMri2 = view_mri_slices(Mri, 'x', 20); 
% Display MRI in 3D slices
hFigMri3 = view_mri_3d(Mri, [], 'NewFigure');
% Close figures
close([hFigMri1 hFigMri2 hFigMri3]);

% Display scalp and cortex
hFigSurf = view_surface(Head);
hFigSurf = view_surface(Cortex, [], [], hFigSurf);


% Stop brainstorm
% brainstorm stop

disp('Done.');




