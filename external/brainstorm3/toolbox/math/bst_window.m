function F = bst_window( L, Method )
% BST_WINDOW: Generate a window of length L, ot the given type: hann, hamming, blackman

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
if (nargin < 2)
    Method = 'hann';
end
% Calculate normalized time vector
t = (0:L-1)' ./ (L-1);
% Switch according to windowing method 
switch (lower(Method))
    case 'hann'
        F = 0.5 - 0.5 * cos(2*pi*t);
    case 'hamming'
        F = 0.54 - 0.46 * cos(2*pi*t);
    case 'blackman'
        F = 0.42 - 0.5 * cos(2*pi*t) + 0.08 * cos(4*pi*t);
    otherwise
        error(['Unsupported windowing method: "' Method '".']);
end


