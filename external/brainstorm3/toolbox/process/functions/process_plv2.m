function varargout = process_plv2( varargin )
% PROCESS_PLV2: Compute the coherence between one signal in one file, and all the signals in another file.

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
    sProcess.Comment     = 'Phase locking value 1xN';
    sProcess.FileTag     = '';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Connectivity';
    sProcess.Index       = 654;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'results', 'matrix'};
    sProcess.OutputTypes = {'timefreq', 'timefreq', 'timefreq'};
    sProcess.nInputs     = 2;
    sProcess.nMinFiles   = 1;
    sProcess.isPaired    = 1;

    % === REFERENCE CHANNELS
    sProcess.options.channelname.Comment    = 'Source channel (A): ';
    sProcess.options.channelname.Type       = 'channelname';
    sProcess.options.channelname.Value      = 'name';
    sProcess.options.channelname.InputTypes = {'data'};
    % === SOURCE ROW NAME OR INDICE
    sProcess.options.src.Comment     = 'Source row names or indices (A): ';
    sProcess.options.src.Type        = 'text';
    sProcess.options.src.Value       = '';
    sProcess.options.src.InputTypes  = {'results', 'matrix'};
    % === DESTINATION ROW NAME OR INDICE
    sProcess.options.dest.Comment    = 'Destination row names or indices (B): ';
    sProcess.options.dest.Type       = 'text';
    sProcess.options.dest.Value      = 'MEG, EEG';
    % === TIME WINDOW
    sProcess.options.timewindow.Comment = 'Time window:';
    sProcess.options.timewindow.Type    = 'timewindow';
    sProcess.options.timewindow.Value   = [];
    % === FREQ BANDS
    sProcess.options.freqbands.Comment = 'Frequency bands for the Hilbert transform:';
    sProcess.options.freqbands.Type    = 'groupbands';
    sProcess.options.freqbands.Value   = bst_get('DefaultFreqBands');
    % === Mirror
    sProcess.options.mirror.Comment = 'Mirror signal before filtering (to avoid edge effects)';
    sProcess.options.mirror.Type    = 'checkbox';
    sProcess.options.mirror.Value   = 1;
    % === KEEP TIME
    sProcess.options.keeptime.Comment = '<HTML>Keep time information, and estimate the PLV across trials<BR>(requires the average of many trials)';
    sProcess.options.keeptime.Type    = 'checkbox';
    sProcess.options.keeptime.Value   = 0;
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
function OutputFiles = Run(sProcess, sInputA, sInputB) %#ok<DEFNU>
    % Default options structure
    OPTIONS = bst_connectivity();
    % Source
    if strcmpi(sInputA(1).FileType, 'data') && isfield(sProcess.options, 'channelname') && isfield(sProcess.options.channelname, 'Value')
        OPTIONS.TargetA = sProcess.options.channelname.Value;
    elseif isfield(sProcess.options, 'src') && isfield(sProcess.options.src, 'Value')
        OPTIONS.TargetA = sProcess.options.src.Value;
    end
    % Destination
    if isfield(sProcess.options, 'dest') && isfield(sProcess.options.dest, 'Value')
        OPTIONS.TargetB = sProcess.options.dest.Value;
    end
    if isfield(sProcess.options, 'timewindow') && isfield(sProcess.options.timewindow, 'Value') && iscell(sProcess.options.timewindow.Value) && ~isempty(sProcess.options.timewindow.Value)
        OPTIONS.TimeWindow = sProcess.options.timewindow.Value{1};
    end
    OPTIONS.ProcessName = func2str(sProcess.Function);
    % Keep time or not: different methods
    if sProcess.options.keeptime.Value
        OPTIONS.Method = 'plvt';
    else
        OPTIONS.Method = 'plv';
    end
    % Hilbert and frequency bands options
    OPTIONS.Freqs = sProcess.options.freqbands.Value;
    OPTIONS.isMirror = sProcess.options.mirror.Value;
    
    % Output mode
    switch (sProcess.options.outputmode.Value)
        case 1, OPTIONS.OutputMode = 'input';
        case 2, OPTIONS.OutputMode = 'avg';
        case 3, OPTIONS.OutputMode = 'concat';
    end
    % Output study, in case of average
    if strcmpi(OPTIONS.OutputMode, 'avg')
        [tmp, OPTIONS.iOutputStudy] = bst_process('GetOutputStudy', sProcess, sInputB);
    end
    % Compute metric
    OutputFiles = bst_connectivity({sInputA.FileName}, {sInputB.FileName}, OPTIONS);
end




