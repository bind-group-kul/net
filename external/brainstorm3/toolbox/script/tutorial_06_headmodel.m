% TUTORIAL_06_HEADMODEL:  Script that follows Brainstorm online tutorial #6: "Computing a head model"
%
% USAGE: 
%     1) Run the previous tutorials
%     2) Run this script

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
% Author: Francois Tadel, 2009-2012


%% ===== START BRAINSTORM =====
% Add brainstorm.m path to the path
addpath(fileparts(fileparts(fileparts(mfilename('fullpath')))));
% If brainstorm is not running yet: Start brainstorm without the GUI
if ~brainstorm('status')
    brainstorm nogui
end


%% ===== GET INPUT FILES =====
% Get the Left and Right conditions
[sStudyRight, iStudyRight] = bst_get('StudyWithCondition', 'Subject01/Right');
[sStudyLeft,  iStudyLeft]  = bst_get('StudyWithCondition', 'Subject01/Left');
% Get all the data files from conditions Left and Right
InputFiles = {sStudyRight.Data.FileName, sStudyLeft.Data.FileName};


%% ===== HEADMODEL: OVERLAPPING SPHERES =====
% Process: Compute head model
bst_process(...
    'CallProcess', 'process_headmodel', ...
    InputFiles, [], ...
    'sourcespace', 1, ...
    'meg', {3, {'<none>', 'Single sphere', 'Overlapping spheres', 'OpenMEEG BEM'}}, ...
    'eeg', {1, {'<none>', '3-shell sphere', 'OpenMEEG BEM'}});


%% ===== HEADMODEL: OPENMEEG BEM =====
% Process: Generate BEM surfaces
bst_process(...
    'CallProcess', 'process_generate_bem', [], [], ...
    'subjectname', 'Subject01', ...
    'nscalp',      1082, ...
    'nouter',      642, ...
    'ninner',      642, ...
    'thickness',   {4, 'mm', 1});
% % Process: Compute head model
% bst_process(...
%     'CallProcess', 'process_headmodel', ...
%     {sStudyRight.Data.FileName}, [], ...
%     'sourcespace',       1, ...
%     'meg',               {4, {'<none>', 'Single sphere', 'Overlapping spheres', 'OpenMEEG BEM'}}, ...
%     'eeg',               {1, {'<none>', '3-shell sphere', 'OpenMEEG BEM'}}, ...
%     'openmeeg',          struct(...
%          'BemSelect',    [0, 0, 1], ...
%          'BemCond',      [1, 0.0125, 1], ...
%          'BemNames',     {{'Scalp', 'Skull', 'Brain'}}, ...
%          'BemFiles',     {{}}, ...
%          'isAdjoint',    0, ...
%          'isAdaptative', 1, ...
%          'isSplit',      0, ...
%          'SplitLength',  4000));
     
% The last model created is used by default for the following computations
disp('Done.');



