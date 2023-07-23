function varargout = process_corr1n( varargin )
% PROCESS_CORR1N: Compute the correlation between all the pairs of signals, in one file.

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
% Authors: Francois Tadel, 2012

macro_methodcall;
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Correlation NxN';
    sProcess.FileTag     = '';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Connectivity';
    sProcess.Index       = 652;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data',     'results',  'matrix'};
    sProcess.OutputTypes = {'timefreq', 'timefreq', 'timefreq'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    sProcess.isSeparator = 1;
    
    % === TIME WINDOW
    sProcess.options.timewindow.Comment = 'Time window:';
    sProcess.options.timewindow.Type    = 'timewindow';
    sProcess.options.timewindow.Value   = [];
    % === SENSOR SELECTION
    sProcess.options.sensortypes.Comment    = 'Sensor types or names (empty=all): ';
    sProcess.options.sensortypes.Type       = 'text';
    sProcess.options.sensortypes.Value      = 'MEG, EEG';
    sProcess.options.sensortypes.InputTypes = {'data'};
    % === SCALAR PRODUCT
    sProcess.options.scalarprod.Comment    = '<HTML>Compute scalar product instead of correlation<BR>(do not remove average of the signal)';
    sProcess.options.scalarprod.Type       = 'checkbox';
    sProcess.options.scalarprod.Value      = 0;
    % === OUTPUT MODE
    sProcess.options.label1.Comment = '<HTML><BR>Output configuration:';
    sProcess.options.label1.Type    = 'label';
    sProcess.options.outputmode.Comment = {'Save individual results (one file per input file)', 'Save average connectivity matrix (one file)'};
    sProcess.options.outputmode.Type    = 'radio';
    sProcess.options.outputmode.Value   = 1;
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputA) %#ok<DEFNU>
    % Default options structure
    OPTIONS = bst_connectivity();
    % Get options
    if strcmpi(sInputA(1).FileType, 'data') && isfield(sProcess.options, 'sensortypes') && isfield(sProcess.options.sensortypes, 'Value')
        OPTIONS.TargetA = sProcess.options.sensortypes.Value;
    end
    if isfield(sProcess.options, 'timewindow') && isfield(sProcess.options.timewindow, 'Value') && iscell(sProcess.options.timewindow.Value) && ~isempty(sProcess.options.timewindow.Value)
        OPTIONS.TimeWindow = sProcess.options.timewindow.Value{1};
    end
    OPTIONS.RemoveMean = ~sProcess.options.scalarprod.Value;
    OPTIONS.Freqs  = 0;
    OPTIONS.Method = 'corr';
    OPTIONS.ProcessName = func2str(sProcess.Function);
    % Output mode
    switch (sProcess.options.outputmode.Value)
        case 1, OPTIONS.OutputMode = 'input';
        case 2, OPTIONS.OutputMode = 'avg';
        case 3, OPTIONS.OutputMode = 'concat';
    end
    % Output study, in case of average
    if strcmpi(OPTIONS.OutputMode, 'avg')
        [tmp, OPTIONS.iOutputStudy] = bst_process('GetOutputStudy', sProcess, sInputA);
    end
    % Compute metric
    OutputFiles = bst_connectivity({sInputA.FileName}, [], OPTIONS);
end




