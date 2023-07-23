function varargout = process_timeoffset( varargin )
% PROCESS_TIMEOFFSET: Add/subtract a time offset to the Time vector.

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
% Authors: Francois Tadel, 2010-2013

macro_methodcall;
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Add time offset';
    sProcess.FileTag     = '| timeoffset';
    sProcess.Category    = 'Filter';
    sProcess.SubGroup    = 'Pre-process';
    sProcess.Index       = 76;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'results', 'matrix'};
    sProcess.OutputTypes = {'data', 'results', 'matrix'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    
    % Definition of the options
    % === Time offset
    sProcess.options.offset.Comment = 'Time offset:';
    sProcess.options.offset.Type    = 'value';
    sProcess.options.offset.Value   = {0, 'ms', []};
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    Comment = sprintf('%s: %1.2fms', sProcess.Comment, sProcess.options.offset.Value{1} * 1000);
end


%% ===== RUN =====
function sInput = Run(sProcess, sInput) %#ok<DEFNU>
    % Get inputs
    TimeOffset = sProcess.options.offset.Value{1};
    
    % === FILE COMMENT ===
    sInput.Comment = '| timeoffset';
    % History
    sInput.HistoryComment = sprintf('Add time offset: %1.2f ms', TimeOffset * 1000);

    % ===== APPLY OFFSET =====
    sInput.TimeVector = sInput.TimeVector + TimeOffset;
end




