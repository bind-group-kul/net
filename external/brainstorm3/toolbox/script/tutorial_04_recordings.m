% TUTORIAL_04_RECORDINGS:  Script that follows Brainstorm online tutorial #4: "Importing recordings"
%
% USAGE: 
%     1) Run first the previous tutorial (#03)
%     2) Edit the 'tutorial_dir' path
%     3) Run this script

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


%% ===== FILES LOCATIONS =====
% Build the file names of the all files to import
DsFileRight = fullfile(tutorial_dir, 'Data', 'somMDYO-18av.ds');
DsFileLeft  = fullfile(tutorial_dir, 'Data', 'somMGYO-18av.ds');
% Check if the folder contains the required files
if ~file_exist(DsFileRight) || ~file_exist(DsFileLeft)
    error(['Please edit this script and change ''tutorial_dir'' to the path where' 10 ...
           'you unzipped the file bst_sample_ctf.zip (downloaded from the website).']);
end

%% ===== START BRAINSTORM =====
% Add brainstorm.m path to the path
addpath(fileparts(fileparts(fileparts(mfilename('fullpath')))));
% If brainstorm is not running yet: Start brainstorm without the GUI
if ~brainstorm('status')
    brainstorm nogui
end


%% ===== IMPORT THE RECORDINGS: RIGHT =====
SubjectName = 'Subject01';
ConditionName = 'Right';
% Process: Import MEG/EEG: Epochs
sFilesRight = bst_process(...
    'CallProcess',  'process_import_data_epoch', [], [], ...
    'datafile',     {DsFileRight, 'CTF'}, ...
    'subjectname',  SubjectName, ...
    'condition',    ConditionName, ...
    'iepochs',      [], ...   % Import all the epochs
    'createcond',   0, ...
    'channelalign', 1, ...
    'usectfcomp',   1, ...
    'usessp',       1, ...
    'baseline',     [-0.050, -0.008], ...  % Remove baseline: [-50ms,-1ms]
    'freq',         []);


%% ===== IMPORT THE RECORDINGS: LEFT =====
SubjectName = 'Subject01';
ConditionName = 'Left';
% Process: Import MEG/EEG: Epochs
sFilesLeft = bst_process(...
    'CallProcess',  'process_import_data_epoch', [], [], ...
    'datafile',     {DsFileLeft, 'CTF'}, ...
    'subjectname',  SubjectName, ...
    'condition',    ConditionName, ...
    'iepochs',      [], ...   % Import all the epochs
    'createcond',   0, ...
    'channelalign', 1, ...
    'usectfcomp',   1, ...
    'usessp',       1, ...
    'baseline',     [-0.050, -0.008], ...  % Remove baseline: [-50ms,-1ms]
    'freq',         []);

% Stop brainstorm
%brainstorm stop






