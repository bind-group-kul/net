function varargout = process_zscore_ab( varargin )
% PROCESS_ZSCORE: Compute Z-Score for a matrix A (normalization respect to a baseline).
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
% Authors: Francois Tadel, 2012

macro_methodcall;
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Remove DC offset (A=baseline)';
    sProcess.FileTag     = '| bl';
    sProcess.Category    = 'Filter2';
    sProcess.SubGroup    = 'Standardize';
    sProcess.Index       = 649;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'results', 'timefreq'};
    sProcess.OutputTypes = {'data', 'results', 'timefreq'};
    sProcess.nInputs     = 2;
    sProcess.nMinFiles   = 1;
    % Default values for some options
    sProcess.isSourceAbsolute = -1;
    sProcess.processDim       = 1;    % Process channel by channel

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
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    % Get baseline
    time = sProcess.options.baseline.Value{1};
    % Comment: seconds or miliseconds
    if any(abs(time) > 2)
        Comment = sprintf('Remove baseline: [%1.3fs,%1.3fs]', time(1), time(2));
    else
        Comment = sprintf('Remove baseline: [%dms,%dms]', round(time(1)*1000), round(time(2)*1000));
    end
end


%% ===== RUN =====
function sInputB = Run(sProcess, sInputA, sInputB) %#ok<DEFNU>
    % Get baseline
    BaselineBounds = sProcess.options.baseline.Value{1};
    % Get inputs
    iBaseline = panel_time('GetTimeIndices', sInputA.TimeVector, BaselineBounds);
    if isempty(iBaseline)
        bst_report('Error', sProcess, [], 'Invalid baseline definition.');
        sInputB = [];
        return;
    end
    % Compute baseline mean (File A)
    meanBaseline = mean(sInputA.A(:, iBaseline, :), 2);
    % Baseline that was used for real
    BaselineRead = sInputA.TimeVector(iBaseline([1 end]));

    % Remove baseline (File B)
    sInputB.A = bst_bsxfun(@minus, sInputB.A, meanBaseline);
    % History
    sInputB.HistoryComment = sprintf('Remove baseline offset: [%1.2f, %1.2f] ms', BaselineRead * 1000);
    % Add comment
    sInputB.Comment = [sInputB.Comment, ' ', sProcess.FileTag];
end


%% ===== COMPUTE =====
function B_data = Compute(A_baseline, B_data)
    % Compute baseline statistics
    stdBaseline  = std(A_baseline, 0, 2);
    meanBaseline = mean(A_baseline, 2);
    % Remove null variance values
    stdBaseline(stdBaseline == 0) = 1e-12;
    % Compute zscore
    B_data = bst_bsxfun(@minus, B_data, meanBaseline);
    B_data = bst_bsxfun(@rdivide, B_data, stdBaseline);
end


