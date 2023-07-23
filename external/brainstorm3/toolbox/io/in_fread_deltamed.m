function F = in_fread_deltamed(sFile, sfid, SamplesBounds)
% IN_FREAD_DELTAMED:  Read a block of recordings from a Deltamed Coherence-Neurofile exported binary file
%
% USAGE:  F = in_fread_deltamed(sFile, sfid, SamplesBounds=[])

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
% Authors: Francois Tadel, 2013

% Parse inputs
if (nargin < 3) || isempty(SamplesBounds)
    SamplesBounds = sFile.prop.samples;
end

nChan = sFile.header.NbOfChannels;
bytesize = 2;
% Get start and length of block to read
offsetData = SamplesBounds(1) * nChan * bytesize;
nSamplesToRead = SamplesBounds(2) - SamplesBounds(1) + 1;
% Position file at the beginning of the data block
fseek(sfid, offsetData, 'bof');
% Read all values at once
F = fread(sfid, [nChan, nSamplesToRead], 'int16');
% Convert from microVolts to Volts
F = bst_bsxfun(@times, double(F), sFile.header.chgain');


