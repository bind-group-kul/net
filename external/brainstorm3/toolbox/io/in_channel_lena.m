function ChannelMat = in_channel_lena( ChannelFile )
% IN_CHANNEL_LENA: Read a LENA file, and return a brainstorm Channel structure
%
% USAGE:  ChannelMat = in_channel_lena( ChannelFile );
%         ChannelMat = in_channel_lena( lena_tree );
%
% INPUT:
%     - ChannelFile: Full path to file to import
%     - lena_tree  : LENA XML tree

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

%% ===== INITIALIZATION =====
% Parse inputs
if isa(ChannelFile, 'xmltree')
    % LENA XML tree has already been read from file
    lena_tree = ChannelFile;
else
    % Read XML tree from LENA file
%     lena_tree = lenaTree( ChannelFile );
    fileName = CheckNew_OldFormat(ChannelFile);
    lena_tree = lenaTree( fileName );
end

% Initialize returned structure
ChannelMat = db_template('channelmat');
ChannelMat.Comment = 'LENA channels';
ChannelMat.Channel = repmat(struct('Name','', 'Type','', 'Comment',[], 'Loc',[], 'Orient', [], 'Weight',[]),0);
% Get progress bar
isProgressBar = bst_progress('isVisible');
    

%% ===== INTERPET CHANNELS INFO =====
% Get sensors dimension
dimNames = getDimensions_names(lena_tree);
if isempty(dimNames) || ~iscell(dimNames)
    error('Can read only time/sensor data.');
end
iDimSensors = find(strcmpi(dimNames, 'sensor_range'));
if isempty(iDimSensors)
    error('No sensors information in file.');
end
% Get number of sensors
nChannels = getSensor_sample_number(lena_tree);
if isempty(nChannels) || (nChannels < 1)
    error('No sensor description available in file.');
end

% Progress bar
bst_progress('start', 'Import LENA recordings', 'Intialization', 0, nChannels);
% Store all the numbers of coils
AllNbCoils = zeros(1, nChannels);
corr_val  = cell(0);
corr_sens = cell(0);

% Loop on each each sensor
for iChan = 1:nChannels
    bst_progress('inc', 1);
    bst_progress('text', sprintf('Reading sensor #%d/%d', iChan, nChannels));
    % Get channel name
    ch_name{iChan} = getSensor_name(lena_tree, iChan);
    % Remove everything that is after a '-'
    iTiret = strfind(ch_name{iChan}, '-');
    if ~isempty(iTiret) && (iTiret ~= 1)
        sChannel.Name = ch_name{iChan}(1:iTiret-1);
    else
        sChannel.Name = ch_name{iChan};
    end
    % Get channel type
    chType = upper(getSensor_category(lena_tree, ch_name{iChan} ));
    % Get channel geometry (location, orientation)
    sensor_coils = getSensor_coil_geometry(lena_tree, ch_name{iChan});
    
    % Process channel tpye
    switch (chType)
        case 'MAGNETOMETER'
            sChannel.Type = 'MEG REF';
            sChannel.Comment = 'Reference Magnetometer';
            % CHEAT: force the Loc and Orient fields to represent 2 coils (second one is empty)
            sensor_coils(2,1,1) = 0;
        case 'GRADIOMETER'
            sChannel.Type = 'MEG REF';
            sChannel.Comment = 'Reference Gradiometer';
        otherwise
            sChannel.Type = chType;
            sChannel.Comment = '';
    end
            
    % Process channel geometry
    % No definition
    if isempty(sensor_coils)
        sChannel.Loc    = [];
        sChannel.Orient = [];
        sChannel.Weight = [];
    else
        % Loop on different numbers of coils defined in the file
        nbCoils = size(sensor_coils, 1);
        for iCoil = 1:nbCoils
            % Location
            sChannel.Loc(:,iCoil) = squeeze(sensor_coils(iCoil,1,:)) / 100;
            % Orientation
            if (size(sensor_coils,2) > 1)
                sChannel.Orient(:,iCoil) = squeeze(sensor_coils(iCoil,2,:));
            else
                sChannel.Orient(:,iCoil) = [];
            end
        end
        % Check locations & orientations
        if all(sChannel.Orient(:) == 0) && nbCoils==1
            % Null orientation vector may be due to EEG datasets concverted
            % into CTF ds format...
             sChannel.Orient = [];
%              warning('Null orientation vector converted to [] for sensor: %s', sChannel.Name);             
        end            
        % Check orientations
        if (nbCoils == 2)
            % Reorient along the outward pointing normal
            ps1 = sum(sChannel.Loc(:,1) .* sChannel.Orient(:,1));
            ps2 = sum(sChannel.Loc(:,2) .* sChannel.Orient(:,2));
            sChannel.Orient(:,1) = sign(ps1) .* sChannel.Orient(:,1);
            sChannel.Orient(:,2) = sign(ps2) .* sChannel.Orient(:,2);
        end
        % Weight
        switch (nbCoils)
            case 0
                sChannel.Weight = [];
            case 1
                sChannel.Weight = 1;
            case 2
                sChannel.Weight = [1 -1];
            case 4
                sChannel.Weight(iCoil) = [1 1 -1 -1];
        end
        % Save number of coils
        AllNbCoils(iChan) = nbCoils;
    end
    
    % Correction coefficients
    if ismember(sChannel.Type, {'MEG', 'MEG MAG', 'MEG GRAD'})
        % Get correction coefficients (for 3rd order gradient correction / CTF ONLY)
        [val, sens] = lena_get_ctfcomp(lena_tree, ch_name{iChan});
        % If coeff are defined 
        if ~isempty(val)
            corr_val{end + 1} = val;
            corr_sens{end + 1} = sens;
        end
    end
    
    % Save channel description
    ChannelMat.Channel(iChan) = sChannel;
end

% Check if mix of gradiometers and magnetometers (cf. Neuromag machine)
iMeg = find(strcmpi({ChannelMat.Channel.Type}, 'MEG'));
if ~isempty(iMeg) && ~all(AllNbCoils(iMeg(1)) == AllNbCoils(iMeg))
    iMegGrad = intersect(iMeg, find(AllNbCoils == 2));
    iMegMag  = intersect(iMeg, find(AllNbCoils == 1));
    ChannelMat.Channel(iMegGrad).Type = deal('MEG GRAD');
    ChannelMat.Channel(iMegMag).Type  = deal('MEG MAG');
end

% Build the MegRefCoef matrix (CTF machines)
if ~isempty(corr_val)
    % MegRefCoef matrix: nb MEG sensors x nb references
    iMeg = good_channel(ChannelMat.Channel, [], 'MEG');
    iRef = good_channel(ChannelMat.Channel, [], 'MEG REF');
    ChannelMat.MegRefCoef = zeros(length(iMeg), length(iRef));
    % Process all sensors
    for iChan = 1:length(corr_val)
        % Process all references for each sensor
        for j = 1:length(corr_val{iChan})
            % Get reference sensor indice
            iDestRef = find(strcmpi(ch_name(iRef), corr_sens{iChan}{j}), 1);
            % Put the coeff value in the MegRefCoef matrix
            ChannelMat.MegRefCoef(iChan, iDestRef) = corr_val{iChan}(j);
        end
    end
    % Compute (I - MegRefCoef)
%     ChannelMat.MegRefCoef = eye(nChannels) - ChannelMat.MegRefCoef;
end

% Hide progress bar if necessary
if ~isProgressBar
    bst_progress('stop');
end






