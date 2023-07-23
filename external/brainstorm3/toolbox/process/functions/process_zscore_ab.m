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
% Authors: Francois Tadel, 2012-2013

macro_methodcall;
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Z-score static (A=baseline)';
    sProcess.FileTag     = '| zscore';
    sProcess.Category    = 'Filter2';
    sProcess.SubGroup    = 'Standardize';
    sProcess.Index       = 650;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'results', 'timefreq', 'matrix'};
    sProcess.OutputTypes = {'data', 'results', 'timefreq', 'matrix'};
    sProcess.nInputs     = 2;
    sProcess.nMinFiles   = 1;
    % Default values for some options
    sProcess.isSourceAbsolute = 0;
    sProcess.processDim       = 1;    % Process channel by channel
    sProcess.isPaired         = 1;
    
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
    % Get frequency band
    time = sProcess.options.baseline.Value{1};
    % Add frequency band
    if any(abs(time) > 2)
        Comment = sprintf('Z-score normalization: [%1.3fs,%1.3fs]', time(1), time(2));
    else
        Comment = sprintf('Z-score normalization: [%dms,%dms]', round(time(1)*1000), round(time(2)*1000));
    end
end


%% ===== RUN =====
function sInputB = Run(sProcess, sInputA, sInputB) %#ok<DEFNU>
    % Get inputs
    iBaseline = bst_closest(sProcess.options.baseline.Value{1}, sInputA.TimeVector);
    if (iBaseline(1) == iBaseline(2)) && any(iBaseline(1) == sInputA.TimeVector)
        error('Invalid baseline definition.');
    end
    iBaseline = iBaseline(1):iBaseline(2);
    % Compute zscore
    sInputB.A = Compute(sInputA.A(:,iBaseline,:), sInputB.A);
    % Change DataType
    if ~strcmpi(sInputB.FileType, 'timefreq')
        sInputB.DataType = 'zscore';
    end
    % Default colormap
    if strcmpi(sInputB.FileType, 'results')
        sInputB.ColormapType = 'stat1';
    else
        sInputB.ColormapType = 'stat2';
    end
    % Add new tag to comment
    if isfield(sProcess.options, 'source_abs') && sProcess.options.source_abs.Value
        sInputB.Comment = [sInputB.Comment, ' | abs'];
    end
    sInputB.Comment = [sInputB.Comment, ' ', sProcess.FileTag];
end


%% ===== COMPUTE =====
function B_data = Compute(A_baseline, B_data)
    % Calculate mean and standard deviation
    [meanBaseline, stdBaseline] = process_zscore('ComputeStat', A_baseline);
    % Compute zscore
    B_data = bst_bsxfun(@minus, B_data, meanBaseline);
    B_data = bst_bsxfun(@rdivide, B_data, stdBaseline);
end


