function MRI = in_mri_kit(MriFile)
% IN_MRI_KIT: Read a structural Yokogawa/KIT MRI.
%
% USAGE:  MRI = in_mri_kit(MriFile);
%
% This function is based on the Yokogawa MEG reader toolbox version 1.4.
% For copyright and license information and software documentation, 
% please refer to the contents of the folder brainstorm3/external/yokogawa

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
% Authors: Francois Tadel, 2013

% Output variable
MRI = struct('Cube',    [], ...
             'Voxsize', [1 1 1], ...
             'Comment', 'MRI');


% %% ===== RETURN DATA =====
% % Prepare volume
% MRI.Cube = reshape(MRI.Cube, [ndim1 ndim2 ndim3 nframes]);
% % Keep only first time frame
% if (nframes > 1)
%     MRI.Cube = MRI.Cube(:,:,:,1);
% end
% 
% % Transform volume to get something similar to CTF orientation
% 
% % Permute MRI dimensions
% MRI.Cube = permute(MRI.Cube, [2 3 1]);
% % Update voxel size
% MRI.Voxsize = MRI.Voxsize([2 3 1]);
% 
% % Rotation / Axis Y
% MRI.Cube = permute(MRI.Cube, [3 2 1]);
% MRI.Cube = flipdim(MRI.Cube, 3);
% % Update voxel size
% MRI.Voxsize = MRI.Voxsize([3 2 1]);
% 
% % Flip / X
% MRI.Cube = flipdim(MRI.Cube, 1);

% % Permutation of dimensions Y/Z
% MRI.Cube = permute(MRI.Cube, [1 3 2]);
% % Flip / Z
% MRI.Cube = flipdim(MRI.Cube, 3);
% % Update voxel size
% MRI.Voxsize = MRI.Voxsize([1 3 2]);
% 
% % Permutation of dimensions Y/Z
% MRI.Cube = permute(MRI.Cube, [1 3 2]);
% % Flip / Z
% MRI.Cube = flipdim(MRI.Cube, 3);
% % Update voxel size
% MRI.Voxsize = MRI.Voxsize([1 3 2]);






