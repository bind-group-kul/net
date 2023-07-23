function varargout = process_average_time( varargin )
% PROCESS_AVERAGE_TIME: For each file in input, compute the mean (or the variance) over the time window.

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
    sProcess.Comment     = 'Average time';
    sProcess.FileTag     = '| avg';
    sProcess.Category    = 'Filter';
    sProcess.SubGroup    = 'Average';
    sProcess.Index       = 303;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'results', 'timefreq'};
    sProcess.OutputTypes = {'data', 'results', 'timefreq'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    % Default values for some options
    sProcess.isSourceAbsolute = 1;
    
    % Definition of the options
    % === TIME WINDOW
    sProcess.options.timewindow.Comment = 'Time window:';
    sProcess.options.timewindow.Type    = 'timewindow';
    sProcess.options.timewindow.Value   = [];
    % === VARIANCE
    sProcess.options.isstd.Comment = 'Compute standard deviation instead of average';
    sProcess.options.isstd.Type    = 'checkbox';
    sProcess.options.isstd.Value   = 0;
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    % Get time window
    Comment = [sProcess.Comment, ': [', process_extract_time('GetTimeString', sProcess), ']'];
    % Absolute values 
    if isfield(sProcess.options, 'source_abs') && sProcess.options.source_abs.Value
        Comment = [Comment, ', abs'];
    end
    % Standard deviation
    if sProcess.options.isstd.Value
        Comment = [Comment, ', std'];
    end
end


%% ===== RUN =====
function sInput = Run(sProcess, sInput) %#ok<DEFNU>
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
    % Variance across time
    if sProcess.options.isstd.Value
        sInput.A = sqrt(var(sInput.A(:, iTime, :), 0, 2));
        sInput.FileTag = '| std';
    % Mean across time
    else
        sInput.A = mean(sInput.A(:, iTime, :), 2);
        sInput.FileTag = '| avg';
    end
    % Copy values to represent the time window
    sInput.A = [sInput.A, sInput.A];
    % Keep only first and last time values
    sInput.TimeVector = [sInput.TimeVector(iTime(1)), sInput.TimeVector(iTime(end))];
    % Build file tag
    sInput.FileTag = [sProcess.FileTag ' (' process_extract_time('GetTimeString',sProcess,sInput) ')'];
end




