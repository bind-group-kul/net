function sFile = in_fopen_ant(DataFile)
% IN_FOPEN_ANT: Open an ANT EEProbe .cnt file (continuous recordings).
%
% USAGE:  sFile = in_fopen_ant(DataFile)

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
        

%% ===== READ HEADER =====
% Read a small block of data, to get all the extra information
hdr = read_eep_cnt(DataFile, 1, 2);

% Initialize returned file structure
sFile = db_template('sfile');
% Add information read from header
sFile.byteorder  = 'l';
sFile.filename   = DataFile;
sFile.format     = 'EEG-ANT-CNT';
sFile.prop.sfreq = double(hdr.rate);
sFile.channelmat = [];
sFile.device     = 'ANT';
sFile.header     = hdr;
% Comment: short filename
[fPath, fBase, fExt] = bst_fileparts(DataFile);
sFile.comment = fBase;
% Time and samples indices
sFile.prop.samples = [0, hdr.nsample - 1];
sFile.prop.times   = sFile.prop.samples ./ sFile.prop.sfreq;
sFile.prop.nAvg    = 1;
% Get bad channels
sFile.channelflag = ones(hdr.nchan, 1);


%% ===== EVENT FILE =====   
% If a .trg file exists with the same name: load it
[fPath, fBase, fExt] = bst_fileparts(DataFile);
TrgFile = bst_fullfile(fPath, [fBase '.trg']);
% If file exists
if file_exist(TrgFile)
    [sFile, newEvents] = import_events(sFile, TrgFile, 'ANT');
end


%% ===== CREATE DEFAULT CHANNEL FILE =====
% Read default channel locs
%DefAntFile = bst_fullfile(bst_get('BrainstormHomeDir'), 'external', 'eeglab', 'anteepimport1.09', 'ANT_WG_standard_346.ced');
DefAntFile = bst_fullfile(bst_get('BrainstormHomeDir'), 'external', 'eeglab', 'anteepimport1.09', 'channel_ANT_WG_standard_346.mat');
if file_exist(DefAntFile)
    %DefAntMat = in_channel_ascii(DefAntFile, {'indice','Name','%f','%f','X','Y','Z','%f','%f','%f'}, 1, .0875);
    DefAntMat = load(DefAntFile);
else
    DefAntMat = [];
end
% Create channel structure
Channel = repmat(db_template('channeldesc'), [1 hdr.nchan]);
for i = 1:hdr.nchan
    Channel(i).Name    = hdr.label{i};
    Channel(i).Type    = 'EEG';
    Channel(i).Orient  = [];
    Channel(i).Weight  = 1;
    Channel(i).Comment = [];
    if ~isempty(DefAntMat)
        iDefChan = channel_find(DefAntMat.Channel, Channel(i).Name);
        if ~isempty(iDefChan)
            % Channel(i).Loc = DefAntMat.Channel(iDefChan).Loc ./ 100;
            Channel(i).Loc = DefAntMat.Channel(iDefChan).Loc;
        else
            Channel(i).Loc = [0; 0; 0];
        end
    else
        Channel(i).Loc = [0; 0; 0];
    end
end
ChannelMat.Comment = 'ANT standard position';
ChannelMat.Channel = Channel;
sFile.channelmat = ChannelMat;
     



