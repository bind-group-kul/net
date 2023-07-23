function db_delete_studies( iStudies )
% DB_DELETE_STUDIES: Delete some studies from the brainstorm database.
%
% USAGE:  db_delete_studies( iStudies )
%
% INPUT:
%    - iStudies : indices of the studies to delete

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
% Authors: Francois Tadel, 2009

ProtocolInfo    = bst_get('ProtocolInfo');
ProtocolStudies = bst_get('ProtocolStudies');
% For each study
for iStudy = iStudies
    % Delete study directory (and all its subdirectories)
    dirStudy = bst_fullfile(ProtocolInfo.STUDIES, bst_fileparts(ProtocolStudies.Study(iStudy).FileName));
    if file_exist(dirStudy)
        rmdir(dirStudy, 's');
        isDeleted = 1;
    else
        isDeleted = 0;
    end
    % Try to remove all the parents dirs until STUDIES dir, if they are empty
    parentDir = bst_fileparts(bst_fileparts(ProtocolStudies.Study(iStudy).FileName), 1);
    while isDeleted && ~isempty(parentDir)
        % Try to delete it
        try
            rmdir(bst_fullfile(ProtocolInfo.STUDIES, parentDir));
            isDeleted = 1;
        catch
            isDeleted = 0;
        end
        % Get parent directory
        parentDir = bst_fileparts(parentDir, 1);
    end
end
% Remove associated studies from database
ProtocolStudies.Study(iStudies) = [];
bst_set('ProtocolStudies', ProtocolStudies);
% Save database
db_save();





