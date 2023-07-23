function varargout = process_extract_time( varargin )
% PROCESS_EXTRACT_TIME: Extract blocks of data from a set of files.

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
    sProcess.Comment     = 'Extract time';
    sProcess.FileTag     = '| time';
    sProcess.Category    = 'Filter';
    sProcess.SubGroup    = 'Extract';
    sProcess.Index       = 350;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'results', 'timefreq', 'matrix'};
    sProcess.OutputTypes = {'data', 'results', 'timefreq', 'matrix'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    sProcess.processDim  = 1;    % Process channel by channel
    
    % Definition of the options
    % === TIME WINDOW
    sProcess.options.timewindow.Comment = 'Time window:';
    sProcess.options.timewindow.Type    = 'timewindow';
    sProcess.options.timewindow.Value   = [];
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    Comment = [sProcess.Comment, ': [', GetTimeString(sProcess), ']'];
end

%% ===== GET TIME STRING =====
function strTime = GetTimeString(sProcess, sInput)
    % Get time window
    if isfield(sProcess.options, 'timewindow') && isfield(sProcess.options.timewindow, 'Value') && iscell(sProcess.options.timewindow.Value) && ~isempty(sProcess.options.timewindow.Value)
        time = sProcess.options.timewindow.Value{1};
    elseif (nargin >= 2) && isfield(sInput, 'TimeVector') && ~isempty(sInput.TimeVector)
        time = sInput.TimeVector([1 end]);
    else
        time = [];
    end
    % Print time window
    if ~isempty(time)
        if any(abs(time) > 2)
            strTime = sprintf('%1.3fs,%1.3fs', time(1), time(2));
        else
            strTime = sprintf('%dms,%dms', round(time(1)*1000), round(time(2)*1000));
        end
    else
        strTime = 'all';
    end
end


%% ===== RUN =====
function sInput = Run(sProcess, sInput) %#ok<DEFNU>
    % Build file tag
    sInput.FileTag = [sProcess.FileTag ' (' GetTimeString(sProcess, sInput) ')'];
    % Get time window
    if isfield(sProcess.options, 'timewindow') && isfield(sProcess.options.timewindow, 'Value') && iscell(sProcess.options.timewindow.Value) && ~isempty(sProcess.options.timewindow.Value)
        iTime = panel_time('GetTimeIndices', sInput.TimeVector, sProcess.options.timewindow.Value{1});
    else
        iTime = 1:length(sInput.TimeVector);
    end
    if isempty(iTime)
        bst_report('Error', sProcess, [], 'Invalid time definition.');
        sInput = [];
        return;
    end
    % Keep only those indices
    sInput.A          = sInput.A(:, iTime, :);
    sInput.TimeVector = sInput.TimeVector(iTime);
end




