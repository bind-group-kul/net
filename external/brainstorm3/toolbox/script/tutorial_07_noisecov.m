% TUTORIAL_07_NOISECOV:  Script that follows Brainstorm online tutorial #7: "Computing a noise covariance matrix"
%
% USAGE: 
%     1) Run first the previous tutorials
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


%% ===== NOISE COVARIANCE MATRIX =====
% Process: Compute noise covariance
bst_process(...
    'CallProcess', 'process_noisecov', ...
    InputFiles, [], ...
    'baseline', [-0.0496, -0.0008], ...
    'dcoffset', 2, ...
    'method',   2);
% Display message
disp('Done.');


%% ===== DISPLAY =====
% Get study again (update version)
sStudyRight = bst_get('StudyWithCondition', 'Subject01/Right');
% Load noise covariance file
NoiseCovMat = load(file_fullpath(sStudyRight.NoiseCov.FileName));
% Display as image
hFig = view_image(NoiseCovMat.NoiseCov, 'jet');
% Close figure
close(hFig);




