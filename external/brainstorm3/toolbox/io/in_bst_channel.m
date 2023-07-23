function sMat = in_bst_channel(MatFile, varargin)
% IN_BST_CHANNEL: Read a "channel" file in Brainstorm format.
% 
% USAGE:  sMat = in_bst_channel(MatFile, FieldsList) : Read the specified fields        
%         sMat = in_bst_channel(MatFile)             : Read all the fields
% 
% INPUT:
%    - MatFile    : Absolute or relative path to the file to read
%    - FieldsList : List of fields to read from the file
% OUTPUT:
%    - sMat : Brainstorm matrix file structure

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
% Authors: Francois Tadel, 2012

%% ===== PARSE INPUTS =====
% Full file name
MatFile = file_fullpath(MatFile);
if ~file_exist(MatFile)
    error(['Channel file was not found: ' 10 file_short(MatFile) 10 'Please reload this protocol (right-click > reload).']);
end
% Specific fields
if (nargin < 2)
    % Read all fields
    sMat = load(MatFile);
    % Default structure
    defMat = db_template('channelmat');
    % Add file fields
    sMat = struct_copy_fields(defMat, sMat, 1);
    % Get all the fields
    FieldsToRead = fieldnames(sMat);
else
    % Get fields to read
    FieldsToRead = varargin;
    % Read each field only once
    FieldsToRead = unique(FieldsToRead);
    % Read specified files only
    warning off MATLAB:load:variableNotFound
    sMat = load(MatFile, FieldsToRead{:});
    warning on MATLAB:load:variableNotFound
end


%% ===== HEAD POINTS =====
if ismember('HeadPoints', FieldsToRead) && (~isfield(sMat, 'HeadPoints') || isempty(sMat.HeadPoints))
    sMat.HeadPoints = struct('Loc',   [], ...
                             'Label', [], ...
                             'Type',  []);
end

%% ===== PROJECTORS =====
if ismember('Projector', FieldsToRead)
    % Field exists
    if isfield(sMat, 'Projector') && ~isempty(sMat.Projector)
        % Old format (I-UUt) => Convert to new format
        if ~isstruct(sMat.Projector)
            sMat.Projector = process_ssp('ConvertOldFormat', sMat.Projector);
        end
    % Field does not exist
    else
        sMat.Projector = repmat(db_template('projector'), 0);
    end
end

%% ===== FILL OTHER MISSING FIELDS =====
% Default structure
for i = 1:length(FieldsToRead)
    if ~isfield(sMat, FieldsToRead{i})
        sMat.(FieldsToRead{i}) = [];
    end
end







