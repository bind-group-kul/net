function varargout = process_zscore_dynamic_ab( varargin )
% PROCESS_ZSCORE_DYNAMIC_AB: Prepares a file for dynamic display of the zscore (load-time)
%
% DESCRIPTION:  For each channel:
%     1) Compute mean m and variance v for baseline
%     2) For each time sample, subtract m and divide by v
                        
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

macro_methodcall;
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Z-score dynamic (A=baseline)';
    sProcess.FileTag     = '| zscored';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Standardize';
    sProcess.Index       = 651;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'results', 'timefreq', 'matrix'};
    sProcess.OutputTypes = {'data', 'results', 'timefreq', 'matrix'};
    sProcess.nInputs     = 2;
    sProcess.nMinFiles   = 1;
    sProcess.isPaired    = 1;
    
    % Definition of the options
    % === Baseline time window
    sProcess.options.baseline.Comment = 'Baseline (Files A):';
    sProcess.options.baseline.Type    = 'baseline';
    sProcess.options.baseline.Value   = [];
    % === Sensor types
    sProcess.options.sensortypes.Comment = 'Sensor types or names (empty=all): ';
    sProcess.options.sensortypes.Type    = 'text';
    sProcess.options.sensortypes.Value   = 'MEG, EEG';
    sProcess.options.sensortypes.InputTypes = {'data'};
    % === Absolute values for sources
    sProcess.options.source_abs.Comment = 'Use absolute values of source activations';
    sProcess.options.source_abs.Type    = 'checkbox';
    sProcess.options.source_abs.Value   = 1;
    sProcess.options.source_abs.InputTypes = {'results'};
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess)
    % Get frequency band
    time = sProcess.options.baseline.Value{1};
    % Add frequency band
    if any(abs(time) > 2)
        Comment = sprintf('Z-score normalization (dynamic): [%1.3fs,%1.3fs]', time(1), time(2));
    else
        Comment = sprintf('Z-score normalization (dynamic): [%dms,%dms]', round(time(1)*1000), round(time(2)*1000));
    end
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputsBaseline, sInputs) %#ok<DEFNU>
    % Check if there are some kernel-based files
    if any(~cellfun(@(c)isempty(strfind(c,'link|')), {sInputs.FileName}))
        bst_report('Error', sProcess, sInputs, 'Cannot calculate dynamic Z-score for source files based on shared inversion kernels. Use the static zscore instead.');
        OutputFiles = {};
        return;
    end
    % Call the base process
    OutputFiles = process_zscore_dynamic('Run', sProcess, sInputsBaseline, sInputs);
end


