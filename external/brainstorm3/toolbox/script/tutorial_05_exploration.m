% TUTORIAL_05_EXPLORATION:  Script that follows Brainstorm online tutorial #5: "Exploring recordings"
%
% USAGE: 
%     1) Run the previous tutorials (#03,#04)
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

%% ===== GET FILE NAMES =====
% Get condition Subject01/Right
[sStudy, iStudy] = bst_get('StudyWithCondition', 'Subject01/Right');
% Get first data file in this condition 
DataFile = sStudy.Data(1).FileName;

% Note that that the path you get is relative to the protocol STUDIES folder
%
% If you want the full path to the file, you have to append this STUDIES path, with the followind commands:
% > ProtocolInfo = bst_get('ProtocolInfo');
% > DataFileFull = fullfile(ProtocolInfo.STUDIES, DataFile);
%
% Or use the shortcut:
% > DataFileFull = file_fullpath(DataFile);


%% ===== DISPLAY RECORDINGS =====
% Display MEG time series
[hFigTs, iDS, iFig] = view_timeseries(DataFile, 'MEG');
% Display MEG topographies
hFigTp1 = view_topography(DataFile, 'MEG', '2DSensorCap');
hFigTp2 = view_topography(DataFile, 'MEG', '3DSensorCap');
hFigTp3 = view_topography(DataFile, 'MEG', '2DDisc');
hFigTp4 = view_topography(DataFile, 'MEG', '2DLayout');
% Set current time to 46ms
panel_time('SetCurrentTime', 0.046);


%% ===== CHANNELS =====
SelectedChannels = {'MLC31', 'MLC32'};
% Set sensors selection
bst_figures('SetSelectedRows', SelectedChannels);
% View selection in a separated window
view_timeseries(DataFile, [], SelectedChannels);
% Show sensors on 2DSensorCap topography
isMarkers = 1;
isLabels = 0;
figure_3d('ViewSensors', hFigTp1, isMarkers, isLabels);

% Get ChannelFile
ChannelFile = sStudy.Channel.FileName;
% Show sensors in a separate figure
isMarkers = 1;
isLabels = 1;
hFigChan = view_channels(ChannelFile, 'MEG', isMarkers, isLabels);


%% ===== COLORMAP =====
ColormapType = 'meg';
% Set 'Meg' colormap to 'jet'
bst_colormaps('SetColormapName', ColormapType, 'jet');
pause(0.2);
% Set 'Meg' colormap to 'rwb'
bst_colormaps('SetColormapName', ColormapType, 'cmap_rbw');
% Set colormap to display absolute values
bst_colormaps('SetColormapAbsolute', ColormapType, 1);
% Normalize colormap for each time frame
bst_colormaps('SetMaxMode', ColormapType, 'local');
% Hide colorbar
bst_colormaps('SetDisplayColorbar', ColormapType, 0);
pause(0.2);
% Restore colormap to default values
bst_colormaps('RestoreDefaults', ColormapType);

% Edit good/bad channel for current file
gui_edit_channelflag(DataFile);
% Display Channel editor
%gui_edit_channel( ChannelFile );

%% ===== SNAPSHOTS =====
% Save a figure as image
% out_figure_image(hFigTp2, imgFile);
% Display time contact sheet for a figure
% hContactFig = view_contactsheet( hFig, 'time', 'fig', imgFile, nbSamples );


%% ===== SOME OTHER COMMANDS =====
% Turn the auto-arrangement of the windows ON
% bst_set('Layout', 'WindowManager', 'TileWindows');

% Turn the auto-arrangement of the windows OFF
% bst_set('Layout', 'WindowManager', '');

% Close all figures, Unload memory
% bst_memory('UnloadAll', 'Forced');

% Stop brainstorm (this call would close all the figures...)
% brainstorm stop

% Display message
% java_dialog('msgbox', 'Done.', 'example_tutorial_ctf_4.m');



