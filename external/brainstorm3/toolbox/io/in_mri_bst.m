function MriMat = in_mri_bst( MriFile )
% IN_MRI_BST: Load a Brainstorm MRI file, and compute missing fields.
%
% USAGE:  MriMat = in_mri_bst(MriFile);
%
% INPUT: 
%     - MriFile : full path to a MRI file
% OUTPUT:
%     - MriMat:  Brainstorm MRI structure
%
% SEE ALSO: in_mri

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

% ===== LOAD FILE =====
MriFile = file_fullpath(MriFile);
if ~file_exist(MriFile)
    error(['MRI file not found:' 10 file_short(MriFile) 10 'You should reload this protocol (right-click > reload).']);
end
% Load file
try
    MriMat = load(MriFile);
catch
    error(['Cannot load MRI file: "' MriFile '".' 10 10 lasterr]);
end
% Check fields (cells)
UpdateFile = 0;

% Histogram not computed yet
if ~isfield(MriMat, 'Histogram') || isempty(MriMat.Histogram) || ~isfield(MriMat.Histogram, 'intensityMax')
    % Compute histogram
    Histogram = mri_histogram(MriMat.Cube);
    % Save histogram
    s.Histogram = Histogram;
    bst_save(MriFile, s, 'v7', 1);
    % Return histogram
    MriMat.Histogram = Histogram;
    UpdateFile = 1;
end
% Other missing fields
if ~isfield(MriMat, 'Comment') 
    [fPath,fBase,fExt] = bst_fileparts(MriFile);
    MriMat.Comment = fBase;
    UpdateFile = 1;
end
if ~isfield(MriMat, 'SCS') || ~isfield(MriMat.SCS, 'NAS') 
    MriMat.SCS = db_template('SCS');
    UpdateFile = 1;
end
if ~isfield(MriMat, 'NCS') || ~isfield(MriMat.NCS, 'AC') 
    MriMat.NCS = db_template('NCS');
    UpdateFile = 1;
end
    
% If need to update file
if UpdateFile
    bst_save(MriFile, MriMat, 'v7');
end
                
                
                
                
                
                