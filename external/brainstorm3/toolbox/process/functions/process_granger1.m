function varargout = process_granger1( varargin )
% PROCESS_GRANGER1: Compute the Granger causality between one signal and all the others, in one file.

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
    sProcess.Comment     = 'Bivariate Granger causality 1xN';
    sProcess.FileTag     = '';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Connectivity';
    sProcess.Index       = 655;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data',     'results',  'matrix'};
    sProcess.OutputTypes = {'timefreq', 'timefreq', 'timefreq'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;

    % === TIME WINDOW
    sProcess.options.timewindow.Comment = 'Time window:';
    sProcess.options.timewindow.Type    = 'timewindow';
    sProcess.options.timewindow.Value   = [];
    % === REFERENCE CHANNELS
    sProcess.options.channelname.Comment    = 'Reference channel: ';
    sProcess.options.channelname.Type       = 'channelname';
    sProcess.options.channelname.Value      = 'name';
    sProcess.options.channelname.InputTypes = {'data'};
    % === SOURCE INDICE
    sProcess.options.sourceind.Comment    = 'Source indices: ';
    sProcess.options.sourceind.Type       = 'text';
    sProcess.options.sourceind.Value      = '';
    sProcess.options.sourceind.InputTypes = {'results'};
    % === ROW NAME
    sProcess.options.rowname.Comment    = 'Row names or indices: ';
    sProcess.options.rowname.Type       = 'text';
    sProcess.options.rowname.Value      = '';
    sProcess.options.rowname.InputTypes = {'timefreq', 'matrix'};
    % === SENSOR SELECTION
    sProcess.options.sensortypes.Comment    = 'Sensor types or names (empty=all): ';
    sProcess.options.sensortypes.Type       = 'text';
    sProcess.options.sensortypes.Value      = 'MEG, EEG';
    sProcess.options.sensortypes.InputTypes = {'data'};
    % === DIRECTION
    sProcess.options.sep1.Type         = 'separator';
    sProcess.options.dirlabel.Comment  = 'Direction of the causality:';
    sProcess.options.dirlabel.Type     = 'label';
    sProcess.options.direction.Comment = {'From the selected node (out)', 'To the selected node (in)', 'Both (generates two files)'};
    sProcess.options.direction.Type    = 'radio';
    sProcess.options.direction.Value   = 3;
    % === GRANGER ORDER
    sProcess.options.grangerorder.Comment = 'Maximum Granger model order (default=10):';
    sProcess.options.grangerorder.Type    = 'value';
    sProcess.options.grangerorder.Value   = {10, '', 0};
%     % === REMOVE EVOKED REPONSE
%     sProcess.options.removeevoked.Comment = 'Remove evoked response from each trial';
%     sProcess.options.removeevoked.Type    = 'checkbox';
%     sProcess.options.removeevoked.Value   = 0;
    % === OUTPUT MODE
    sProcess.options.label1.Comment = '<HTML><BR>Output configuration:';
    sProcess.options.label1.Type    = 'label';
    sProcess.options.outputmode.Comment = {'Save individual results (one file per input file)', 'Save average connectivity matrix (one file)', 'Concatenate input files before processing (one file)'};
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
    if strcmpi(sInputA(1).FileType, 'data')
        if isfield(sProcess.options, 'channelname') && isfield(sProcess.options.channelname, 'Value')
            OPTIONS.TargetA = sProcess.options.channelname.Value;
        end
        if isfield(sProcess.options, 'sensortypes') && isfield(sProcess.options.sensortypes, 'Value')
            OPTIONS.TargetB = sProcess.options.sensortypes.Value;
        end
    elseif strcmpi(sInputA(1).FileType, 'results') && isfield(sProcess.options, 'sourceind') && isfield(sProcess.options.sourceind, 'Value')
        OPTIONS.TargetA = sProcess.options.sourceind.Value;
    elseif any(strcmpi(sInputA(1).FileType, {'timefreq','matrix'})) && isfield(sProcess.options, 'rowname') && isfield(sProcess.options.rowname, 'Value')
        OPTIONS.TargetA = sProcess.options.rowname.Value;
    end
    if isfield(sProcess.options, 'timewindow') && isfield(sProcess.options.timewindow, 'Value') && iscell(sProcess.options.timewindow.Value) && ~isempty(sProcess.options.timewindow.Value)
        OPTIONS.TimeWindow = sProcess.options.timewindow.Value{1};
    end
%     OPTIONS.RemoveEvoked = (length(sInputA) >= 2) && sProcess.options.removeevoked.Value;
    OPTIONS.Freqs  = 0;
    OPTIONS.Method = 'granger';
    OPTIONS.ProcessName = func2str(sProcess.Function);
    % Granger options
    OPTIONS.GrangerOrder = sProcess.options.grangerorder.Value{1};
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
    % Computation depends on the direction
    OutputFiles = {};
    if ismember(sProcess.options.direction.Value, [1 3])
        OPTIONS.GrangerDir = 'out';
        OutputFiles = cat(2, OutputFiles, bst_connectivity({sInputA.FileName}, {sInputA.FileName}, OPTIONS));
    end
    if ismember(sProcess.options.direction.Value, [2 3])
        OPTIONS.GrangerDir = 'in';
        OutputFiles = cat(2, OutputFiles, bst_connectivity({sInputA.FileName}, {sInputA.FileName}, OPTIONS));
    end
end




