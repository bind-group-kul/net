function [DeviceTag, DeviceName] = channel_detect_device(ChannelMat)
% CHANNEL_DETECT_DEVICE: Based on a channel structure, determine what MEG system recorded it
% 
% USAGE:  [DeviceTag, DeviceName] = channel_detect_device(ChannelMat)

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

% Count number of MEG references
nMegRef = nnz(strcmpi({ChannelMat.Channel.Type}, 'MEG REF'));
% Detect MEG machine type
DeviceTag = '';
DeviceName = '';
% VECTORVIEW 306: Gradiometers + Magnetometers
if all(ismember({'MEG GRAD', 'MEG MAG'}, {ChannelMat.Channel.Type}))
    DeviceTag = '_vectorview306';
    DeviceName = 'Neuromag';
% KIT/4D/CTF: MEG references
elseif (nMegRef > 3)
    % CTF
    if strfind(lower(ChannelMat.Comment), 'ctf')
        DeviceTag = '_ctf';
        DeviceName = 'CTF';
    % 4D
    elseif strfind(lower(ChannelMat.Comment), '4d')
        DeviceTag = '_4d';
        DeviceName = '4D';
    % KIT
    elseif strfind(lower(ChannelMat.Comment), 'kit')
        DeviceTag = '_kit';
        DeviceName = 'KIT';
    % If comment is not useful: detect based on number of references
    % CTF: 29 references
    elseif (nMegRef > 25)
        DeviceTag = '_ctf';
        DeviceName = 'CTF';
    % 4D: 23 references
    elseif (nMegRef > 18)
        DeviceTag = '_4d';
        DeviceName = '4D';
    % KIT: 12 references
    elseif  (nMegRef > 8)
        DeviceTag = '_kit';
        DeviceName = 'KIT';
    end
    % Check if accuracy is 1 (MEG = 8 points for CTF; 4 pts for 4D)
    iMeg = good_channel(ChannelMat.Channel, [], 'MEG');
    if ~isempty(iMeg)
        nPts = size(ChannelMat.Channel(iMeg(1)).Loc, 2);
        if (strcmpi(DeviceName,'CTF') && (nPts == 8)) || (strcmpi(DeviceName,'4D') && (nPts >= 4)) 
            DeviceTag = [DeviceTag '_acc1'];
        end
    else
        DeviceTag = [DeviceTag '_acc1'];
    end
% BabySQUID
elseif strfind(lower(ChannelMat.Comment), 'babysquid')
    DeviceTag = '_babysquid';
    DeviceName = 'BabySQUID';
% KIT
elseif strfind(lower(ChannelMat.Comment), 'kit')
    DeviceTag = '_kit';
    DeviceName = 'KIT';
end
    
    
    