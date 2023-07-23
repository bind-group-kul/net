function out_tess(BstFile, OutputFile, FileFormat, sMri)
% OUT_TESS: Exports a Brainstorm surface in another file format.
%
% USAGE:  out_tess(TessFile, OutputFile, FileFormat, sMri);
%
% INPUT: 
%     - BstFile    : Tesselation file from the Brainstorm database
%     - OutputFile : Full path to output filename
%     - FileFormat : String that describes the surface file format : {TRI, DFS, DSGL, MESH, BST ...}
%     - sMri       : Loaded MRI structure

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
% Authors: Francois Tadel, 2011-2013

% ===== PARSE INPUTS =====
if (nargin < 4)
    sMri = [];
end

% ===== LOAD SURFACE =====
% Load Brainstorm file
TessMat = in_tess_bst(BstFile);
% Convert back to MRI coordinates
if ~isempty(sMri)
    TessMat.Vertices = cs_scs2mri(sMri, TessMat.Vertices' .* 1000)';
    % Divide by the voxel size
    TessMat.Vertices = bst_bsxfun(@rdivide, TessMat.Vertices, sMri.Voxsize);
else
    disp('BST> Warning: MRI is missing, cannot convert surface to Brainstorm coordinate system.');
end


% ===== SAVE SURFACE =====
[fPath, fBase, fExt] = bst_fileparts(OutputFile);
% Show progress bar
bst_progress('start', 'Export surface', ['Export surface to file "' [fBase, fExt] '"...']);
% Switch between file formats
switch upper(FileFormat)
    case 'MESH'
        % Convert into BrainVISA MRI coordinates
        if ~isempty(sMri)
            mriSize = size(sMri.Cube) .* (sMri.Voxsize(:))';
            TessMat.Vertices = bst_bsxfun(@minus, mriSize, TessMat.Vertices);
        end
        % Export file
        out_tess_mesh(TessMat, OutputFile);
    case 'DFS'
        out_tess_dfs(TessMat, OutputFile);
    case 'FS'
        % Convert to FreeSurfer representation: Swap faces
        TessMat.Faces = TessMat.Faces(:,[2 1 3]);
        % FreeSurfer millimeters => MRI => RAS coord
        if ~isempty(sMri)
            mriSize = size(sMri.Cube) / 2;
            TessMat.Vertices = bst_bsxfun(@rdivide, TessMat.Vertices, sMri.Voxsize);
            TessMat.Vertices = bst_bsxfun(@minus, TessMat.Vertices, mriSize);
        end
        % Export file
        out_tess_fs(TessMat, OutputFile);
    case 'GII'
        % Convert to BrainVISA MRI coordinates
        if ~isempty(sMri)
            mriSize = size(sMri.Cube) .* (sMri.Voxsize(:))';
            TessMat.Vertices = bst_bsxfun(@minus, mriSize, TessMat.Vertices);
        end
        % Export file
        out_tess_gii(TessMat, OutputFile);
    case 'TRI'
        out_tess_tri(BstFile, OutputFile);
    case 'OFF'
        out_tess_off(TessMat, OutputFile);
    otherwise
        error(['Unsupported file extension : "' OutputExt '"']);
end
% Hide progress bar
bst_progress('stop');



