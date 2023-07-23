function F= in_fread_mfip(sFile,SamplesBounds)
% IN_FREAD_MFIP:  Read a block of recordings from nirs data .mat file
%
% USAGE:  F = in_fread_mfip(sFile, SamplesBounds) : Read all channels
%         F = in_fread_mfip(sFile)                : Read all channels, all the times

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

% Check inputs
if (nargin < 2)
    SamplesBounds = [];
else
    % Remove first sample from the list
    SamplesBounds = SamplesBounds - sFile.prop.samples(1) + 1;
    % Check validity of time window
    if (SamplesBounds(1) <= 0) || (SamplesBounds(1) > SamplesBounds(2)) || (SamplesBounds(2) > sFile.header.acquisition.nSamples)
        error('Invalid samples range.');
    end
end
    
% Load file
mat = load(sFile.filename,'data','-mat');

% Select only a given time window
if ~isempty(SamplesBounds)
    F = mat.data(SamplesBounds(1):SamplesBounds(2), :)'; % data | dimension nSamples by nChannels
else
    F = mat.data';
end

