function channel_remove_headpoints(ChannelFile)
% CHANNEL_REMOVE_HEADPOINTS: Remove head points from a ChannelFile
% 
% USAGE:  channel_remove_headpoints( ChannelFile )

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
% Authors: Francois Tadel, 2009-2010

% Load channel file
ChannelMat = in_bst_channel(ChannelFile);
% Remove head points
if ~isfield(ChannelMat, 'HeadPoints') || isempty(ChannelMat.HeadPoints) || isempty(ChannelMat.HeadPoints.Label)
    % Display warning: no head points
    java_dialog('warning', 'No head points in the file.', 'Remove head points');
else
    nPoints = length(ChannelMat.HeadPoints.Label);
    ChannelMat.HeadPoints = [];
    % History: Reamove all head points
    ChannelMat = bst_history('add', ChannelMat, 'headpoints', sprintf('Removed %d head points', nPoints));
    % Save file back
    bst_save(ChannelFile, ChannelMat, 'v7');
    % Message: head points remove
    java_dialog('msgbox', sprintf('%d head points removed successfully.', nPoints), 'Remove head points');
end



