function varargout = process_ersd( varargin )
% PROCESS_ERSD: Compute event related perturbation (synchrnonization / desynchrnonization)
%
% DESCRIPTION: 
%    This function calculates event related perturbation (ERS/ERD) as the percentage of a 
%    decrease or increase during a test interval (T), as compared to a reference interval (R). 
%    The following formula is used: ERSP = (R-T)/R x 100.

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
% Authors: Nikola Vukovic, University of Cambridge, 2013

macro_methodcall;
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Event related perturbation (ERS/ERD)';
    sProcess.FileTag     = '| ersd';
    sProcess.Category    = 'Filter';
    sProcess.SubGroup    = 'Standardize';
    sProcess.Index       = 412;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'results', 'timefreq', 'matrix'};
    sProcess.OutputTypes = {'data', 'results', 'timefreq', 'matrix'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    % Default values for some options
    sProcess.isSourceAbsolute = -1;
    sProcess.processDim       = 1;    % Process channel by channel

    % Definition of the options
    % === Baseline time window
    sProcess.options.baseline.Comment = 'Baseline:';
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
        Comment = sprintf('Event related perturbation: [%1.3fs,%1.3fs]', time(1), time(2));
    else
        Comment = sprintf('Event related perturbation: [%dms,%dms]', round(time(1)*1000), round(time(2)*1000));
    end
end


%% ===== RUN =====
function sInput = Run(sProcess, sInput) %#ok<DEFNU>
    % Get inputs
    iBaseline = panel_time('GetTimeIndices', sInput.TimeVector, sProcess.options.baseline.Value{1});
    if isempty(iBaseline)
        bst_report('Error', sProcess, [], 'Invalid baseline definition.');
        sInput = [];
        return;
    end
    % Compute ERSP
    sInput.A = Compute(sInput.A, iBaseline);
    % Change DataType
    if ~strcmpi(sInput.FileType, 'timefreq')
        sInput.DataType = 'zscore';
    end
    % Default colormap
    if strcmpi(sInput.FileType, 'results')
        sInput.ColormapType = 'stat1';
    else
        sInput.ColormapType = 'stat2';
    end
end


%% ===== COMPUTE =====
function A = Compute(A, iBaseline)
    % Compute baseline statistics
    meanBaseline = mean(A(:, iBaseline,:), 2);
    % Remove null variance values
    meanBaseline(meanBaseline == 0) = 1e-12;
    % Compute event related perturbation
    A = bst_bsxfun(@minus, A, meanBaseline);
    A = bst_bsxfun(@rdivide, A, meanBaseline) .* 100;
end


