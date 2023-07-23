% TUTORIAL_08_SOURCES:  Script that follows Brainstorm online tutorial #8: "Source estimation"
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
% Author: Francois Tadel, 2009-2013


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
InputFiles = {sStudyRight.Data(1).FileName, sStudyLeft.Data(1).FileName};


%% ===== MINIMUM NORM =====
% Process: Compute sources
sFiles = bst_process(...
    'CallProcess', 'process_inverse', ...
    InputFiles, [], ...
    'method',   1, ...
    'wmne',     struct(...
         'NoiseCov',      [], ...
         'InverseMethod', 'wmne', ...
         'SNR',           3, ...
         'diagnoise',     0, ...
         'SourceOrient',  {{'fixed'}}, ...
         'loose',         0.2, ...
         'depth',         1, ...
         'weightexp',     0.5, ...
         'weightlimit',   10, ...
         'regnoise',      1, ...
         'magreg',        0.1, ...
         'gradreg',       0.1, ...
         'eegreg',        0.1, ...
         'fMRI',          [], ...
         'fMRIthresh',    [], ...
         'fMRIoff',       0.1, ...
         'pca',           1), ...
    'sensortypes', 'MEG', ...
    'output',      2);
% Get output file names
ResultsFile = {sFiles.FileName};


%% ===== DISPLAY =====
% Display the sources for the first results computed (MN, non-shared kernel)
% View on the cortex surface
hFig1 = script_view_sources(ResultsFile{1}, 'cortex');
% Set current time to 46ms
panel_time('SetCurrentTime', 0.046);
% Set surface threshold to 65% of the maximal value
iSurf = 1;
thresh = .75;   % .80; % UNCONSTRAINED
panel_surface('SetDataThreshold', hFig1, iSurf, thresh);
% Set surface smoothing
panel_surface('SetSurfaceSmooth', hFig1, iSurf, .4);
% Show sulci
panel_surface('SetShowSulci', hFig1, iSurf, 1);

% View sources on MRI (3D orthogonal slices)
hFig2 = script_view_sources(ResultsFile{1}, 'mri3d');
panel_surface('SetDataThreshold', hFig2, iSurf, thresh);
% Set the position of the cuts in the 3D figure
% cutsPosMm  = [63.8 89.1 175.3];   % UNCONSTRAINED
cutsPosMm  = [66.6 99.4 167.8];
cutsPosVox = round(cutsPosMm ./ .9375); % .9375 is the voxel size in all directions in this MRI
panel_surface('PlotMri', hFig2, cutsPosVox);

% View sources with MRI Viewer
hFig3 = script_view_sources(ResultsFile{1}, 'mriviewer');
panel_surface('SetDataThreshold', hFig3, iSurf, thresh);
% Set the position of the cuts in the MRI Viewer (values in millimeters)
figure_mri('SetLocation', 'mm', hFig3, [], cutsPosMm);

disp('Done.');




