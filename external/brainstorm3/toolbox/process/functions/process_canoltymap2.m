function varargout = process_canoltymap2( varargin )
% This function generates Canolty like maps (Science 2006, figure 1) for the input signal. 

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
% Authors: Esther Florin, Sylvain Baillet, 2011-2013
%          Francois Tadel, 2013-2014

macro_methodcall;
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Canolty maps (FileB=MaxPAC)';
    sProcess.FileTag     = '| canolty';
    sProcess.Category    = 'File2';
    sProcess.SubGroup    = 'Frequency';
    sProcess.Index       = 661;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'raw',      'data',     'results',  'matrix'};
    sProcess.OutputTypes = {'timefreq', 'timefreq', 'timefreq', 'timefreq'};
    sProcess.nInputs     = 2;
    sProcess.nMinFiles   = 1;

    % === TIME WINDOW
    sProcess.options.timewindow.Comment = 'Time window: ';
    sProcess.options.timewindow.Type    = 'timewindow';
    sProcess.options.timewindow.Value   = [];
    % === EPOCH TIME
    sProcess.options.epochtime.Comment = 'Epoch time: ';
    sProcess.options.epochtime.Type    = 'range';
    sProcess.options.epochtime.Value   = {[-1, 1], 'ms', []};
    % === SENSOR SELECTION
    sProcess.options.target_data.Comment    = 'Sensor types or names (empty=all): ';
    sProcess.options.target_data.Type       = 'text';
    sProcess.options.target_data.Value      = 'MEG, EEG';
    sProcess.options.target_data.InputTypes = {'data', 'raw'};
    % === SOURCE INDICES
    sProcess.options.target_res.Comment    = 'Source indices (empty=all): ';
    sProcess.options.target_res.Type       = 'text';
    sProcess.options.target_res.Value      = '';
    sProcess.options.target_res.InputTypes = {'results'};
    % === ROW NAMES
    sProcess.options.target_tf.Comment    = 'Row names or indices (empty=all): ';
    sProcess.options.target_tf.Type       = 'text';
    sProcess.options.target_tf.Value      = '';
    sProcess.options.target_tf.InputTypes = {'timefreq', 'matrix'};
    % === MAX_BLOCK_SIZE
    sProcess.options.max_block_size.Comment = 'Number of signals to process at once: ';
    sProcess.options.max_block_size.Type    = 'value';
    sProcess.options.max_block_size.Value   = {100, ' ', 0};
    % === SAVE AVERAGED LOW-FREQ SIGNALS
    sProcess.options.save_erp.Comment = 'Save averaged low frequency signals';
    sProcess.options.save_erp.Type    = 'checkbox';
    sProcess.options.save_erp.Value   = 1;
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFile = Run(sProcess, sInputA, sInputB) %#ok<DEFNU>
    % Load the optimal low-frequency values from the MaxPAC file in InputB
    DataMat = load(file_fullpath(sInputB.FileName), 'sPAC');
    if ~isfield(DataMat, 'sPAC') || isempty(DataMat.sPAC) || ~isfield(DataMat.sPAC, 'NestingFreq') || isempty(DataMat.sPAC.NestingFreq)
        bst_report('Error', sProcess, sInputB, 'Invalid MaxPAC file in FilesB.');
        OutputFile = {};
        return;
    end
    % Set option from the file
    sProcess.options.lowfreq.Value{1} = DataMat.sPAC.NestingFreq;
    % Run the megPAC process
    OutputFile = process_canoltymap('Run', sProcess, sInputA);
end

    


