function isDeleted = file_delete( fileList, isForced )
% FILE_DELETE: Delete a file, or a list of file, with user confirmation.
%
% USAGE:  isDeleted = file_delete( fileList, isForced );
% 
% INPUT: 
%     - fileList : cell array of files or directories to delete
%     - isForced : if 0, ask user confirmation before deleting files (default)
%                  if 1, do not ask user confirmation
% OUTPUT:
%     - isDeleted :  0 if user aborted deletion
%                   -1 if an error occured
%                    1 if success

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
% Authors: Francois Tadel, 2008-2012

% Parse inputs
if (nargin == 1)
    isForced = 0;
end
isDeleted = 0;
% If input is not a cell list : convert it into a cell list
if ischar(fileList)
    fileList = {fileList};
end

% Build string to ask for the deletion
strFiles = [];
strInvalidFiles = [];
nbInvalidFiles = 0;
nbValidFiles = 0;
for i=1:length(fileList)
    if file_exist(fileList{i})
        strFiles = [strFiles '' fileList{i} 10];
        nbValidFiles = nbValidFiles + 1;
    else
        strInvalidFiles = [strInvalidFiles fileList{i} 10];
        fileList{i} = '';
        nbInvalidFiles = nbInvalidFiles + 1;
    end
end

% If invalid filenames were found : display warning message
if ~isempty(strInvalidFiles)
    if ~isForced
        if (nbInvalidFiles <= 10)
            bst_error(['Following files and directories were not found : ' 10 strInvalidFiles], 'Delete files', 0);
        else
            bst_error(sprintf('Warning: %d files and directories were not found.\n\n', nbInvalidFiles), 'Delete files', 0);
        end
    end
    isDeleted = -1;
    return;
end
if isempty(strFiles)
    return
end

% Ask the user a confirmation (if deletion is not forced)
if ~isForced 
    if (nbValidFiles <= 10)
        questStr = ['<HTML>The following files and directories are going to be permanently deleted :<BR><BR>' strrep(strFiles, char(10), '<BR>')];
    else
        questStr = sprintf('<HTML>Warning: %d files are going to be permanently deleted.<BR><BR>', nbValidFiles);
    end
    % Raw warning
    if ~all(cellfun(@(c)isempty(strfind(c, '_0raw')), fileList))
        questStr = [questStr '<BR><FONT color="#CC0000">Warning: Removing links to raw files does not acually remove the raw files.<BR>' ...
                    'To remove the recordings from the hard drive, use the popup menu File > Delete raw file,<BR>' ...
                    'or do it from your operating system file manager.</FONT>'];
    end
    isConfirmed = java_dialog('confirm', questStr, 'Delete files');
else
    isConfirmed = 1;
end
% If deletion was confirmed
if isConfirmed
    % Delete each file
    for i=1:length(fileList)
        if ~isempty(fileList{i})
            iDSUnload = [];
            % Unload corresponding file
            fileType = file_gettype(fileList{i});
            switch (fileType)
                case {'cortex','scalp','innerskull','outerskull','tess'}
                    bst_memory('UnloadSurface', file_short(fileList{i}), 1);
                case 'subjectimage'
                    bst_memory('UnloadMri', file_short(fileList{i}));
                case 'channel'
                    iDSUnload = bst_memory('GetDataSetChannel', file_short(fileList{i}));
                case {'pdata', 'data'}
                    iDSUnload = bst_memory('GetDataSetData', file_short(fileList{i}));
                case {'presults', 'results', 'link'}
                    iDSUnload = bst_memory('GetDataSetResult', file_short(fileList{i}));
                case {'timefreq', 'ptimefreq'}
                    iDSUnload = bst_memory('GetDataSetTimefreq', file_short(fileList{i}));
            end
            % Unload target datasets
            if ~isempty(iDSUnload)
                bst_memory('UnloadDataSets', iDSUnload);
            end
            % Remove directory
            if isdir(fileList{i})
                try
                    rmdir(fileList{i}, 's');
                catch
                    disp(['Error: Could not delete folder "' fileList{i} '"']);
                end
            % Remove single file
            else
                warning('off', 'MATLAB:DELETE:Permission');
                delete(fileList{i});
            end
        end
    end
    isDeleted = 1;
end
    
