function ChannelMat = channel_detect_type( ChannelMat, isAlign, isRemoveFid )
% CHANNEL_DETECT_TYPE: Detect some auxiliary EEG channels in a channel structure.
%
% USAGE:  ChannelMat = channel_detect_type( ChannelMat, isAlign )
%         ChannelMat = channel_detect_type( ChannelMat )            % isAlign = 0

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
% Authors: Francois Tadel, 2009-2013

% Parse inputs
if (nargin < 2) || isempty(isAlign)
    isAlign = 0;
end
if (nargin < 3) || isempty(isRemoveFid)
    isRemoveFid = 1;
end

%% ===== DETECT SENSOR TYPES =====
% Detect EEG channels
iEEG = good_channel(ChannelMat.Channel, [], 'EEG');
% If there are less than a certain number of "EEG" channels, let's consider it's not EEG
if (length(iEEG) < 5)
    [ChannelMat.Channel(iEEG).Type] = deal('Misc');
end
% Add orientation fields
if ~isfield(ChannelMat, 'SCS') || isempty(ChannelMat.SCS)
    ChannelMat.SCS = db_template('SCS');
end
% If some fiducials are defined in the imported channel file
iDelChan = [];
for i = 1:length(iEEG)
    iChan = iEEG(i);
    % Check name
    chName = lower(ChannelMat.Channel(iChan).Name);
    switch(chName)
        case {'nas', 'nasion', 'nz', 'fidnas', 'fidnz'}  % NASION
            if ~isempty(ChannelMat.Channel(iChan).Loc)
                iDelChan = [iDelChan, iChan];
                % ChannelMat.SCS.NAS = ChannelMat.Channel(iChan).Loc(:,1)' .* 1000;
                ChannelMat.SCS.NAS = ChannelMat.Channel(iChan).Loc(:,1)';  % CHANGED 09-May-2013 (suspected bug, not tested)
            end
            ChannelMat.Channel(iChan).Type = 'Misc';
        case {'lpa', 'pal', 'og', 'left', 'fidt9'} % LEFT EAR
            if ~isempty(ChannelMat.Channel(iChan).Loc)
                iDelChan = [iDelChan, iChan];
                % ChannelMat.SCS.LPA = ChannelMat.Channel(iChan).Loc(:,1)' .* 1000;
                ChannelMat.SCS.LPA = ChannelMat.Channel(iChan).Loc(:,1)';   % CHANGED 09-May-2013 (suspected bug, not tested)
            end
            ChannelMat.Channel(iChan).Type = 'Misc';
        case {'rpa', 'par', 'od', 'right', 'fidt10'} % RIGHT EAR
            if ~isempty(ChannelMat.Channel(iChan).Loc)
                iDelChan = [iDelChan, iChan];
                % ChannelMat.SCS.RPA = ChannelMat.Channel(iChan).Loc(:,1)' .* 1000;
                ChannelMat.SCS.RPA = ChannelMat.Channel(iChan).Loc(:,1)';   % CHANGED 09-May-2013 (suspected bug, not tested)
            end
            ChannelMat.Channel(iChan).Type = 'Misc';
        case 'fid' % Other fiducials
            iDelChan = [iDelChan, iChan];
        case {'ref','eegref','eref','vref','ref.'}
            ChannelMat.Channel(iChan).Type = 'EEG REF';
        % OTHER NON-EEG CHANNELS
        otherwise
            if ~isempty(strfind(chName, 'eog')) || ~isempty(strfind(chName, 'veo')) || ~isempty(strfind(chName, 'heo'))
                ChannelMat.Channel(iChan).Type = 'EOG';
            elseif ~isempty(strfind(chName, 'ecg')) || ~isempty(strfind(chName, 'ekg'))
                ChannelMat.Channel(iChan).Type = 'ECG';
            elseif ~isempty(strfind(chName, 'emg'))
                ChannelMat.Channel(iChan).Type = 'EMG';
            elseif ~isempty(strfind(chName, 'seeg'))
                ChannelMat.Channel(iChan).Type = 'SEEG';
            elseif ~isempty(strfind(chName, 'ecog'))
                ChannelMat.Channel(iChan).Type = 'ECOG';
            elseif ~isempty(strfind(chName, 'pulse'))
                ChannelMat.Channel(iChan).Type = 'Misc';
            elseif ~isempty(strfind(chName, 'mast'))
                ChannelMat.Channel(iChan).Type = 'MAST';
            end
    end
    % Check type
    if strcmpi(ChannelMat.Channel(iChan).Type, 'fiducial')
        iDelChan = [iDelChan, iChan];
    end
end
% Delete fiducials from channel file
if isRemoveFid
    ChannelMat.Channel(iDelChan) = [];
end


%% ===== DETECT FIDUCIALS IN HEAD POINTS =====
if (~isfield(ChannelMat, 'SCS') || ~isfield(ChannelMat.SCS, 'NAS') || isempty(ChannelMat.SCS.NAS)) && ...
   (isfield(ChannelMat, 'HeadPoints') && isfield(ChannelMat.HeadPoints, 'Label') && ~isempty(ChannelMat.HeadPoints.Label))
    % Get the three fiducials in the head points
    iNas = find(strcmpi(ChannelMat.HeadPoints.Label, 'Nasion') | strcmpi(ChannelMat.HeadPoints.Label, 'NAS'));
    iLpa = find(strcmpi(ChannelMat.HeadPoints.Label, 'Left')   | strcmpi(ChannelMat.HeadPoints.Label, 'LPA'));
    iRpa = find(strcmpi(ChannelMat.HeadPoints.Label, 'Right')  | strcmpi(ChannelMat.HeadPoints.Label, 'RPA'));
    % If they are all defined: use them
    if ~isempty(iNas) && ~isempty(iLpa) && ~isempty(iRpa)
        ChannelMat.SCS.NAS = mean(ChannelMat.HeadPoints.Loc(:,iNas)', 1);
        ChannelMat.SCS.LPA = mean(ChannelMat.HeadPoints.Loc(:,iLpa)', 1);
        ChannelMat.SCS.RPA = mean(ChannelMat.HeadPoints.Loc(:,iRpa)', 1);
    end
end


%% ===== ALIGN IN SCS COORDINATES =====
% Re-align in the Brainstorm/CTF coordinate system, if it is not already
if isAlign && all(isfield(ChannelMat.SCS, {'NAS','LPA','RPA'})) && (length(ChannelMat.SCS.NAS) == 3) && (length(ChannelMat.SCS.LPA) == 3) && (length(ChannelMat.SCS.RPA) == 3)
    % Force vector orientations
    ChannelMat.SCS.NAS = ChannelMat.SCS.NAS(:)';
    ChannelMat.SCS.LPA = ChannelMat.SCS.LPA(:)';
    ChannelMat.SCS.RPA = ChannelMat.SCS.RPA(:)';
    % Compute transformation
    transfSCS = cs_mri2scs(ChannelMat);
    ChannelMat.SCS.R      = transfSCS.R;
    ChannelMat.SCS.T      = transfSCS.T;
    ChannelMat.SCS.Origin = transfSCS.Origin;
    % Convert the fiducials positions
    ChannelMat.SCS.NAS = cs_mri2scs(ChannelMat, ChannelMat.SCS.NAS')';
    ChannelMat.SCS.LPA = cs_mri2scs(ChannelMat, ChannelMat.SCS.LPA')';
    ChannelMat.SCS.RPA = cs_mri2scs(ChannelMat, ChannelMat.SCS.RPA')';
    % Process each sensor
    for i = 1:length(ChannelMat.Channel)
        % Converts the electrodes locations to SCS (subject coordinates system)
        if ~isempty(ChannelMat.Channel(i).Loc)
            %ChannelMat.Channel(i).Loc = cs_mri2scs(ChannelMat, ChannelMat.Channel(i).Loc .* 1000) ./ 1000;
            ChannelMat.Channel(i).Loc = cs_mri2scs(ChannelMat, ChannelMat.Channel(i).Loc);   % CHANGED 09-May-2013 (suspected bug, not tested)
        end
    end
    % Process the head points    % ADDED 27-May-2013
    if ~isempty(ChannelMat.HeadPoints) && ~isempty(ChannelMat.HeadPoints.Type) && ~isempty(ChannelMat.HeadPoints.Loc)
        ChannelMat.HeadPoints.Loc = cs_mri2scs(ChannelMat, ChannelMat.HeadPoints.Loc);
    end
    % Add to the list of transformation
    ChannelMat.TransfMeg{end+1} = [ChannelMat.SCS.R, ChannelMat.SCS.T; 0 0 0 1];
    ChannelMat.TransfMegLabels{end+1} = 'Native=>Brainstorm/CTF';
    ChannelMat.TransfEeg{end+1} = [ChannelMat.SCS.R, ChannelMat.SCS.T; 0 0 0 1];
    ChannelMat.TransfEegLabels{end+1} = 'Native=>Brainstorm/CTF';
end


%% ===== CHECK SENSOR NAMES =====
% Check for empty channels
iEmpty = find(cellfun(@isempty, {ChannelMat.Channel.Name}));
for i = 1:length(iEmpty)
    ChannelMat.Channel(iEmpty(i)).Name = sprintf('%04d', iEmpty(i));
end
% Check for duplicate channels
for i = 1:length(ChannelMat.Channel)
    iOther = setdiff(1:length(ChannelMat.Channel), i);
    ChannelMat.Channel(i).Name = file_unique(ChannelMat.Channel(i).Name, {ChannelMat.Channel(iOther).Name});
end




    