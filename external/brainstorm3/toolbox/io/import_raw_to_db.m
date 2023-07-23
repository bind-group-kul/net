function NewFiles = import_raw_to_db( DataFile )
% IMPORT_RAW_TO_DB: Import in the database some blocks of recordings from a continuous file already linked to the database.
%
% USAGE:  NewFiles = import_raw_to_db( DataFile )

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
% Authors: Francois Tadel, 2011-2012


% ===== GET FILE INFO =====
% Get study description
[sStudy, iStudy, iData] = bst_get('DataFile', DataFile);
if isempty(sStudy)
    error('File is not registered in the database.');
end
% Is it a "link to raw file" or not
isRaw = strcmpi(sStudy.Data(iData).DataType, 'raw');
% Get subject index
[sSubject, iSubject] = bst_get('Subject', sStudy.BrainStormSubject);
% Progress bar
bst_progress('start', 'Import raw file', 'Processing file header...');
% Read file descriptor
DataMat = in_bst_data(DataFile);

% ===== UPDATE CHANNEL INFO =====
% Some modifications may have been done after the channel information was first read from the file.
% Typically, a re-alignment of the sensors with the head, or the re-classification of a sensor.
% Those modifications have to be taken into account in the sFile structure of the RAW file.
% Get channel file
ChannelFile = bst_get('ChannelFileForStudy', sStudy.FileName);
% If a channel file is defined
if ~isempty(ChannelFile) && isRaw
    % Read channel file
    ChannelMat = in_bst_channel(ChannelFile);
    % Check channel structure if it exists
    if isempty(ChannelMat) || ~isfield(ChannelMat, 'Channel') || isempty(ChannelMat.Channel)
        error('Invalid channel file saved in the database.');
    end
    % If channel file not saved in the link to raw: add it
    if isempty(DataMat.F.channelmat) || ~isfield(DataMat.F.channelmat, 'Channel') || isempty(DataMat.F.channelmat.Channel)
        DataMat.F.channelmat = ChannelMat;
        isUpdateLink = 1;
    % Else: check for differences between the two files
    else
        % Just check that no channels were removed or added
        if ~isempty(DataMat.F.channelmat) && (length(ChannelMat.Channel) ~= length(DataMat.F.channelmat.Channel))
            error('The number of sensors was changed in the ChannelFile. File cannot be imported anymore.');
        end
        % If the projector were changed: overwrite the channel file with the last definition
        chan1 = DataMat.F.channelmat;
        chan2 = ChannelMat;
        if isfield(chan1,'Projector') && isfield(chan2,'Projector') && ~isequal(chan1.Projector, chan2.Projector) && (~isempty(chan1.Projector) || ~isempty(chan2.Projector))
            ChannelMat.Projector = DataMat.F.channelmat.Projector;
            bst_save(file_fullpath(ChannelFile), ChannelMat, 'v7');
            disp('BST> Warning: The active SSP projectors had changed in the channel file. Updating the channel file...');
        end
        % If other changes were made to the channel structure: overwrite the sFile structure
        if isfield(chan1, 'History')
            chan1 = rmfield(chan1, 'History');
        end
        if isfield(chan2, 'History')
            chan2 = rmfield(chan2, 'History');
        end
        if isfield(chan1, 'Comment')
            chan1 = rmfield(chan1, 'Comment');
        end
        if isfield(chan2, 'Comment')
            chan2 = rmfield(chan2, 'Comment');
        end
        if isfield(chan1, 'Projector')
            chan1 = rmfield(chan1, 'Projector');
        end
        if isfield(chan2, 'Projector')
            chan2 = rmfield(chan2, 'Projector');
        end
        % Differences between the two files
        isUpdateLink = ~isequal(chan1, chan2);
    end
    % Update link
    if isUpdateLink
        % Update sFile structure
        DataMat.F.channelmat = ChannelMat;
        % Save raw file descriptor on the hard drive
        bst_save(file_fullpath(DataFile), DataMat, 'v6');
        disp('BST> Warning: The sensors definition had changed in the channel file. Updating the link to raw file...');
    end
end

% ===== IMPORT FILE =====
% Import "link to raw file" in database
if isRaw
    % Get updated sFile structure
    sFile = DataMat.F;
% Import file that is already in the database
else
    % Generate a sFile structure that describes this database file
    sFile = in_fopen(DataFile, 'BST-DATA');
%     % Remove the channelmat field, so that importing does not overwrite the existing channel file
%     sFile.channelmat = [];
end
% Import file
NewFiles = import_data(sFile, sFile.format, [], iSubject);


