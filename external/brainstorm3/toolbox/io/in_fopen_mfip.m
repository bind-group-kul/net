function [sFile] = in_fopen_mfip(DataFile)
% IN_FOPEN_MFIP: Open a nirs .mat file (continuous recordings).
% USAGE:  sFile = in_fopen_mfip_nirs(DataFile)

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
% Authors: Alexis Machado, 2012


%% ===== Create a  HEADER =====
hdr = read_hdr_info(DataFile); % subfunction

%% ===== FILL STRUCTURE =====
% Initialize returned file structure                    
sFile=db_template('sfile');                     
                      
% Add information read from header
sFile.filename   = DataFile;
sFile.fid        = [];  
sFile.format     = 'NIRS-MFIP';
sFile.device     = 'NIRS system';
sFile.byteorder  = 'l';

% Properties of the recordings
sFile.prop.times   = [hdr.acquisition.startTime hdr.acquisition.endTime];
sFile.prop.sfreq   = double(hdr.acquisition.fs);
sFile.prop.samples = sFile.prop.times .* sFile.prop.sfreq;
sFile.prop.nAvg    = 1;


% Get fiducials
ChannelMat = db_template('channelmat');
ChannelMat.Comment = 'NIRS sensors';
ChannelMat.SCS.NAS = hdr.fiducials.NAS' ./ 1000;
ChannelMat.SCS.LPA = hdr.fiducials.LPA' ./ 1000;
ChannelMat.SCS.RPA = hdr.fiducials.RPA' ./ 1000;
% Compute transformation matrix for the sensors
transfSCS = cs_mri2scs(ChannelMat);
ChannelMat.SCS.R      = transfSCS.R;
ChannelMat.SCS.T      = transfSCS.T;
ChannelMat.SCS.Origin = transfSCS.Origin;
% Convert the fiducials positions
ChannelMat.SCS.NAS = cs_mri2scs(ChannelMat, ChannelMat.SCS.NAS);
ChannelMat.SCS.LPA = cs_mri2scs(ChannelMat, ChannelMat.SCS.LPA);
ChannelMat.SCS.RPA = cs_mri2scs(ChannelMat, ChannelMat.SCS.RPA);

% Channel informations
sFile.channelflag = ones(hdr.acquisition.nChannels,1); % GOOD=1; BAD=-1;
for iChan = 1:hdr.acquisition.nChannels
    Channel(iChan).Name    = hdr.channels(iChan).name;
    Channel(iChan).Type    = 'EEG'; % Keep 'EEG' even for now, after see hdr.channels.type
    Channel(iChan).Loc     = cs_mri2scs(ChannelMat,hdr.channels(iChan).chanPos' ./ 1000);
    Channel(iChan).Orient  = [];
    Channel(iChan).Weight  = 1;
    Channel(iChan).Comment = [];    
end
ChannelMat.Channel = Channel;
sFile.channelmat = ChannelMat;

sFile.header=hdr;
end


function hdr=read_hdr_info(DataFile)
%__________________________________________________________________________
% INPUTS
% hdr: Structure with fields
%         .acquisition
% 
%             .fs: sampling frequency | dimension scalar
% 
%             .startTime: real startTime (according to the sampling frequency)
%            
%             .endTime:   real endTime   (according to the sampling frequency)
%             
%             .nSamples: number of samples
%             
%             .nChannels: number of channels
% 
%         .channels
% 
%             .name: string
%             
%             .type: string e.g 'I830' 'I690' 'concHbO' 'concHbR' ...
% 
%             .SDnumbers: correpondance table between the columns of data and the Src and Det number
%                         Each raw represent the respective column in data. The first column is the Src number , the second is the Det number
%                         | dimension: nChan by 2.
% 
%             .srcPos: Source position in cartesian referential 
%                      (origin and orientaion are arbitrary) | dimension: 1 by 3.
% 
%             .detPos: Detector position in cartesian referential 
%                     (origin and orientation are arbitrary) | dimension: 1 by 3.
% 
%             .chanPos: middle of the channel position in cartesian referential 
%                     (origin and orientation are arbitrary) | dimension: 1 by 3.

%__________________________________________________________________________
% OUTPUTS
% hdr: Same structure

load(DataFile,'hdr','-mat');

end










