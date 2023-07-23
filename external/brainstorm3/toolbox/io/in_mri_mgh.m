function MRI = in_mri_mgh(MriFile)
% IN_MRI_MGH: Read a structural MGH/MGZ MRI.
%
% USAGE:  MRI = in_mri_mgh(MriFile);
%
% INPUT:
%     - MriFile : full path to a MRI file, WITH EXTENSION
% OUTPUT:
%     - MRI : Standard brainstorm structure for MRI volumes
%
% NOTE: A .mgz file is just a gzipped .mgh file

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
% Authors: Francois Tadel, 2008-2013


%% ===== INITIALIZATION =====   
% Output variable
MRI = struct('Cube',    [], ...
             'Voxsize', [1 1 1], ...
             'Comment', 'MRI');

%% ===== UNZIP FILE =====
[MRIpath, MRIbase, MRIext] = bst_fileparts(MriFile);
% If file is gzipped
if strcmpi(MRIext, '.mgz')
    % Get temporary folder
    tmpDir = bst_get('BrainstormTmpDir');
    % Target file
    gunzippedFile = bst_fullfile(tmpDir, [MRIbase, '.mgh']);
    % Unzip file
    res = org.brainstorm.file.Unpack.gunzip(MriFile, gunzippedFile);
    if ~res
        error(['Could not gunzip file : "' MriFile '"']);
    end
    % Import dunzipped file
    MriFile = gunzippedFile;
end
         
         
%% ===== LOAD MGH HEADER =====
% Open file
fid = fopen(MriFile, 'rb', 'b') ;
if (fid < 0)
    error(['Could not open file : "' MriFile '".']);
end

% Read header
v       = fread(fid, 1, 'int');
ndim1   = fread(fid, 1, 'int');
ndim2   = fread(fid, 1, 'int');
ndim3   = fread(fid, 1, 'int');
nframes = fread(fid, 1, 'int');
type    = fread(fid, 1, 'int');
dof     = fread(fid, 1, 'int');

unused_space_size = 256 - 2 ;
ras_good_flag = fread(fid, 1, 'short') ;

if (ras_good_flag)
    MRI.Voxsize = fread(fid, 3, 'float32')' ;
    Mdc         = fread(fid, 9, 'float32') ;
    Mdc         = reshape(Mdc,[3 3]);
    Pxyz_c      = fread(fid, 3, 'float32') ;
    unused_space_size = unused_space_size - (3*4 + 4*3*4) ; % space for ras transform
end

% Position at the end of the header
fseek(fid, unused_space_size, 'cof') ;


%% ===== LOAD MRI VOLUME =====
nv = ndim1 * ndim2 * ndim3 * nframes;
% Determine number of bytes per voxel
switch type
    case 0,  precision = 'uchar';
    case 1,  precision = 'int';
    case 3,  precision = 'float32';
    case 4,  precision = 'short';
end
% Read volume
MRI.Cube = fread(fid, nv, precision);
% Check whole volume was read
if(numel(MRI.Cube) ~= nv)
    bst_error('Unrecognized data format.', 'Import MGH MRI', 0);
    MRI = [];
    return;
end
% Load MR params
if(~feof(fid))
    [mr_parms count] = fread(fid,4,'float32');
    if (count ~= 4)
        error('Error reading MR params.');
    end
end
% Close file
fclose(fid) ;


%% ===== RETURN DATA =====
% Prepare volume
MRI.Cube = reshape(MRI.Cube, [ndim1 ndim2 ndim3 nframes]);
% Keep only first time frame
if (nframes > 1)
    MRI.Cube = MRI.Cube(:,:,:,1);
end

% Transform volume to get something similar to CTF orientation

% Permute MRI dimensions
MRI.Cube = permute(MRI.Cube, [2 3 1]);
% Update voxel size
MRI.Voxsize = MRI.Voxsize([2 3 1]);

% Rotation / Axis Y
MRI.Cube = permute(MRI.Cube, [3 2 1]);
MRI.Cube = flipdim(MRI.Cube, 3);
% Update voxel size
MRI.Voxsize = MRI.Voxsize([3 2 1]);

% Flip / X
MRI.Cube = flipdim(MRI.Cube, 1);

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






