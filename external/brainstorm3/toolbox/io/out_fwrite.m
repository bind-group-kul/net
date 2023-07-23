function sFile = out_fwrite(sFile, iEpoch, SamplesBounds, iChannels, F)
% OUT_FWRITE: Write a block of data in a file.
%
% USAGE:  nBytes = out_fwrite(sFile, iEpoch, SamplesBounds, iChannels, F);
%
% INPUTS:
%     - sFile         : Structure for importing files in Brainstorm. Created by in_fopen()
%     - iEpoch        : Indice of the epoch to read (only one value allowed)
%     - SamplesBounds : [smpStart smpStop], First and last sample to read in epoch #iEpoch
%     - iChannels     : Array of indices of the channels to import
%     - F             : Block of data to write to the file [iChannels x SamplesBounds]

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


%% ===== PARSE INPUTS =====
if isempty(iEpoch)
    iEpoch = 1;
end


%% ===== OPEN FILE =====
% Except for CTF, because file is open in the out_fwrite_ctf function (to handle multiple .meg4 files)
if ~strcmpi(sFile.format, 'CTF-CONTINUOUS')
    % If file does not exist: Create it
    if ~file_exist(sFile.filename)
        sfid = fopen(sFile.filename, 'w', sFile.byteorder);
        if (sfid == -1)
            error('Could not create output file.');
        end
        fclose(sfid);
    end
    % Open file
    sfid = fopen(sFile.filename, 'r+', sFile.byteorder);
    if (sfid == -1)
        error('Could not open output file.');
    end
else
    sfid = [];
end


%% ===== WRITE RECORDINGS BLOCK =====
switch (sFile.format)
    case 'FIF'
        out_fwrite_fif(sFile, sfid, iEpoch, SamplesBounds, iChannels, F);
    case 'CTF-CONTINUOUS'
        isContinuous = strcmpi(sFile.format, 'CTF-CONTINUOUS');
        if isempty(iChannels)
            ChannelRange = [];
        else
            ChannelRange = [iChannels(1), iChannels(end)];
        end
        out_fwrite_ctf(sFile, iEpoch, SamplesBounds, ChannelRange, isContinuous, F);
    otherwise
        error('Unsupported file format.');
end

%% ===== CLOSE FILE =====
if ~isempty(sfid) && ~isempty(fopen(sfid))
    fclose(sfid);
end




