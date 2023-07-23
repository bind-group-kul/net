function [foundFile, iDepth] = file_find( baseDir, filePattern, nbMaxRecursion, iDepth )
% FILE_FIND: Find a file recursively.
%
% USAGE:  [foundFile, iFoundDepth] = file_find( baseDir, filePattern, nbMaxRecursion )
% 
% INPUT:
%    - baseDir        : Full path to the directory to search
%    - filePattern    : Name of the target file (wild chars allowed)
%    - nbMaxRecursion : Maximum folder depth from the baseDir
%
% OUTPUT:
%    - foundFile      : Full path to file, or [] if no file were found

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
% Authors: Francois Tadel, 2008-2010

% Parse inputs
if (nargin < 2)
    error('foundFile = file_find( baseDir, filePattern, nbMaxRecursion );');
end
if (nargin < 3)
    nbMaxRecursion = Inf;
end
if (nargin < 4)
    iDepth = 1;
end
iFoundDepth = [];
% Default return value
foundFile = [];

% Base dir not valid
if isempty(baseDir) || ~isdir(baseDir) || (baseDir(1) == '.')
    return;
else
    % Try to find required file
    listDir = dir(bst_fullfile(baseDir, filePattern));
    if ~isempty(listDir)
        foundFile = bst_fullfile(baseDir, listDir(1).name);
        return
    end
    % If reached the recursion limit
    if (nbMaxRecursion <= 1)
        return
    end
    % Get subdirectories
    listDir = dir(bst_fullfile(baseDir, '*'));
    listDir([listDir.isdir] == 0) = [];
    % Process each subdirectory
    for i = 1:length(listDir)
        if (listDir(i).name(1) ~= '.')
            newDir = bst_fullfile(baseDir, listDir(i).name);
            [foundFile, iFoundDepth] = file_find(newDir, filePattern, nbMaxRecursion - 1, iDepth + 1);
            if ~isempty(foundFile)
                iDepth = iFoundDepth;
                return
            end
        end
    end
end
iDepth = [];



