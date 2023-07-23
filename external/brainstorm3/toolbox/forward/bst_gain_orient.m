function Gain = bst_gain_orient(Gain, GridOrient)
% BST_GAIN_ORIENT: Constrain source orientation on a leadfield matrix
%
% USAGE:  Gain = bst_gain_orient(Gain, GridOrient)
%
% INPUT: 
%     - Gain       : [nChannels,3*nSources] leadfield matrix
%     - GridOrient : [nSources,3] orientation for each source of the Gain matrix
% OUTPUT:
%     - Gain : [nChannels,nSources] leadfield matrix with fixed orientations

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

% Create a sparse block diagonal matrix for orientations
GridOrient = blk_diag(GridOrient', 1);
% Apply the orientation to the Gain matrix
Gain = Gain * GridOrient;

