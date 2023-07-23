function sFile = in_fopen_lena(DataFile)
% IN_FOPEN_LENA: Open a LENA file, and get all the data and channel information.
%
% USAGE:  sFile = in_fopen_lena(DataFile)

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

%% ===== READ HEADER =====
% Read file header
DataFile = CheckNew_OldFormat(DataFile);
lena_tree = lenaTree( DataFile );
% Get dimensions names
dimNames = getDimensions_names(lena_tree);
if isempty(dimNames) || ~iscell(dimNames) || ~all(ismember({'time_range', 'sensor_range'}, dimNames))
    error('Can read only time/sensor data.');
end
% Get indices of different dimensions
iDimEpoch = find(strcmpi(dimNames, 'datablock_range'));
iDimTime  = find(strcmpi(dimNames, 'time_range'));
% Number of epochs
if ~isempty(iDimEpoch)
    nEpochs = getDatablock_samples_number(lena_tree);
else
    nEpochs = 1;
end
% Get protocol name
try
    ProtocolName = getProtocol(lena_tree);
    if isnan(ProtocolName)
        ProtocolName = '';
    end
catch
    ProtocolName = '';
end
% Get time
nTimes  = getTime_samples(lena_tree);
sfreq   = getSample_rate(lena_tree);
pretrig = getPre_trigger(lena_tree);
% Get number of trials that where averaged
nAvg = get_nAvg(lena_tree);
% Get byte order
data_format = getData_format(lena_tree);
switch(data_format)
    case 'LittleEndian', byteorder = 'l';
    case 'BigEndian',    byteorder = 'b';
    otherwise,           byteorder = 'n';
end

%% ===== READ CHANNEL STRUCTURE =====
% Build Channel structure
ChannelMat = in_channel_lena( lena_tree );
ChannelFlag = ones(length(ChannelMat.Channel), 1);

%% ===== FILL STRUCTURE =====
% Initialize returned file structure
sFile = db_template('sfile');
% Add information read from header
sFile.filename   = DataFile;
sFile.format     = 'LENA';
sFile.prop.sfreq = double(sfreq);
sFile.channelmat = ChannelMat;
sFile.channelflag= ChannelFlag;
sFile.byteorder  = byteorder;
sFile.device     = 'LENA';
sFile.comment    = ProtocolName;
sFile.header.lena_tree = lena_tree;
sFile.header.dimNames  = dimNames;
sFile.header.iDimEpoch = iDimEpoch;
sFile.header.iDimTime  = iDimTime;
sFile.header.nTimes    = nTimes;
% Time and samples indices
sFile.prop.samples = ([0, nTimes - 1] - pretrig .* sfreq);
sFile.prop.times   = sFile.prop.samples ./ sfreq;
sFile.prop.nAvg    = nAvg;
% By default: sensors are considered as if the CTF compensators were already applied, and 3rd order
sFile.prop.currCtfComp = 3;
sFile.prop.destCtfComp = 3;


%% ===== EPOCHS FILE =====
if (nEpochs > 1)
    % Build epochs structure
    for i = 1:nEpochs
        sFile.epochs(i).label   = sprintf('Trial #%d', i);
        sFile.epochs(i).samples = sFile.prop.samples;
        sFile.epochs(i).times   = sFile.prop.times;
        sFile.epochs(i).nAvg    = 1;
        sFile.epochs(i).select  = 1;
        sFile.epochs(i).bad         = 0;
        sFile.epochs(i).channelflag = [];
    end
end


%% ===== READ EVENTS =====
% Get folder
[fPath, fBase] = bst_fileparts(DataFile);
% Look for an event file in LENA folder (.ptx for version 3, .event for version 2)
if file_exist(bst_fullfile(fPath, 'data.event'))
    marker_file = bst_fullfile(fPath, 'data.event');
elseif file_exist(bst_fullfile(fPath, [fBase, '.ptx']))
    marker_file = bst_fullfile(fPath, [fBase, '.ptx']);
else
    marker_file = [];
end
% Read markers file
if ~isempty(marker_file)
    bst_progress('text', 'Reading events file...');
    % Read file
    sFile.events = in_events_lena(sFile, marker_file);
end

end


%% ===== HELPER FUNCTIONS =====
function nAvg = get_nAvg(lenaTree)
    % Default return value
    nAvg = 1;
    % Get the children ids
    child = children( lenaTree , root(lenaTree) );
    % Get the children names
    childNames = get( lenaTree , child , 'name' );
    % Find tag number_events_averaged
    tagId = child(find(strcmp(childNames,'number_events_averaged')));
    if isempty(tagId)
        return
    end
    % Get the time_samples content:
    tagContents = get( lenaTree, tagId, 'contents' );
    % Get the time_samples contents :
    tagValue = get( lenaTree, tagContents, 'value' );
    % Convert to double
    nAvg = str2double( tagValue );
end



