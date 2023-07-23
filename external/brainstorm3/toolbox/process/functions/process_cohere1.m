function varargout = process_cohere1( varargin )
% PROCESS_COHERE1: Compute the coherence between one signal and all the others, in one file.

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
% Authors: Francois Tadel, 2012-2013

macro_methodcall;
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Coherence 1xN';
    sProcess.FileTag     = '';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Connectivity';
    sProcess.Index       = 653;
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
    % === WINDOW LENGTH
    sProcess.options.winlength.Comment = 'Estimator window length: ';
    sProcess.options.winlength.Type    = 'value';
    sProcess.options.winlength.Value   = {64, 'time samples', 0};
    % === LIMIT FREQUENCY RESOLUTION
    sProcess.options.maxfreqres.Comment = 'Frequency resolution (lower bound; 0=no limit):';
    sProcess.options.maxfreqres.Type    = 'value';
    sProcess.options.maxfreqres.Value   = {1,'Hz',2};
    % === P-VALUE THRESHOLD
    sProcess.options.pthresh.Comment = 'p-value threshold: ';
    sProcess.options.pthresh.Type    = 'value';
    sProcess.options.pthresh.Value   = {0.05,' ',4};
    % === IS FREQ BANDS
    sProcess.options.isfreqbands.Comment = 'Group by frequency bands (name/freqs/function):';
    sProcess.options.isfreqbands.Type    = 'checkbox';
    sProcess.options.isfreqbands.Value   = 0;
    % === FREQ BANDS
    sProcess.options.freqbands.Comment = '';
    sProcess.options.freqbands.Type    = 'groupbands';
    sProcess.options.freqbands.Value   = bst_get('DefaultFreqBands');
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
    OPTIONS.Method      = 'cohere';
    OPTIONS.ProcessName = func2str(sProcess.Function);
    OPTIONS.CohWinLength  = sProcess.options.winlength.Value{1};
    OPTIONS.pThreshold    = sProcess.options.pthresh.Value{1};
    % Maximum frequency resolution
    OPTIONS.CohMaxFreqRes = sProcess.options.maxfreqres.Value{1};
    if isempty(OPTIONS.CohMaxFreqRes) || (OPTIONS.CohMaxFreqRes == 0)
        OPTIONS.CohMaxFreqRes = [];
    end
    % Frequency bands
    isFreqBands = sProcess.options.isfreqbands.Value;
    if isFreqBands
        OPTIONS.Freqs = sProcess.options.freqbands.Value;
    else
        OPTIONS.Freqs = [];
    end
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
    OutputFiles = bst_connectivity({sInputA.FileName}, {sInputA.FileName}, OPTIONS);
end




