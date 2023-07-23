% MACROD_METHODCALL: Script to insert at the beginning of all the brainstorm class functions

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
% Authors: Francois Tadel, 2010-2012

% No parameters: nothing to do
if (nargin == 0)
% Else : execute appropriate local function
elseif ischar(varargin{1}) 
    % No error handling
    if isequal(varargin{1}, 'NoCatch') && (nargin >= 2)
        if (nargout)
            [varargout{1:nargout}] = feval(str2func(varargin{2}), varargin{3:end});
        else
            feval(str2func(varargin{2}), varargin{3:end});
        end
    % Safe call
    else
        if (nargout)
            [varargout{1:nargout}] = bst_call(str2func(varargin{1}), varargin{2:end});
        else
            bst_call(str2func(varargin{1}), varargin{2:end});
        end
    end
end


