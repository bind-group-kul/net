function varargout = process_bandpass( varargin )
% PROCESS_BANDPASS: Frequency filters: Lowpass/Highpass/Bandpass
%
% USAGE:      sProcess = process_bandpass('GetDescription')
%               sInput = process_bandpass('Run', sProcess, sInput, method)
%               sInput = process_bandpass('Run', sProcess, sInput)
%                    x = process_bandpass('Compute', x, Time, HighPass, LowPass, method)
%                    x = process_bandpass('Compute', x, Time, HighPass, LowPass)
%                    x = process_bandpass('Compute', x, sfreq, ...)

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
    sProcess.Comment     = 'Band-pass filter';
    sProcess.FileTag     = '| bandpass';
    sProcess.Category    = 'Filter';
    sProcess.SubGroup    = 'Pre-process';
    sProcess.Index       = 64;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'results', 'raw', 'matrix'};
    sProcess.OutputTypes = {'data', 'results', 'raw', 'matrix'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    sProcess.processDim  = 1;   % Process channel by channel
    
    % Definition of the options
    % === Low bound
    sProcess.options.highpass.Comment = 'Lower cutoff frequency (0=disable):';
    sProcess.options.highpass.Type    = 'value';
    sProcess.options.highpass.Value   = {2,'Hz ',2};
    % === High bound
    sProcess.options.lowpass.Comment = 'Upper cutoff frequency (0=disable):';
    sProcess.options.lowpass.Type    = 'value';
    sProcess.options.lowpass.Value   = {40,'Hz ',2};
    % === Mirror
    sProcess.options.mirror.Comment = 'Mirror signal before filtering (to avoid edge effects)';
    sProcess.options.mirror.Type    = 'checkbox';
    sProcess.options.mirror.Value   = 1;
    % === Sensor types
    sProcess.options.sensortypes.Comment = 'Sensor types or names (empty=all): ';
    sProcess.options.sensortypes.Type    = 'text';
    sProcess.options.sensortypes.Value   = 'MEG, EEG';
    sProcess.options.sensortypes.InputTypes = {'data', 'raw'};
end

%% ===== GET OPTIONS =====
function [HighPass, LowPass, isMirror] = GetOptions(sProcess)
    HighPass = sProcess.options.highpass.Value{1};
    LowPass  = sProcess.options.lowpass.Value{1};
    if (HighPass == 0) 
        HighPass = [];
    end
    if (LowPass == 0) 
        LowPass = [];
    end
    isMirror = sProcess.options.mirror.Value;
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    % Get options
    [HighPass, LowPass] = GetOptions(sProcess);
    % Format comment
    if ~isempty(HighPass) && ~isempty(LowPass)
        Comment = ['Band-pass:' num2str(HighPass) 'Hz-' num2str(LowPass) 'Hz'];
    elseif ~isempty(HighPass)
        Comment = ['High-pass:' num2str(HighPass) 'Hz'];
    elseif ~isempty(LowPass)
        Comment = ['Low-pass:' num2str(LowPass) 'Hz'];
    else
        Comment = '';
    end
end


%% ===== RUN =====
function sInput = Run(sProcess, sInput) %#ok<DEFNU>
    % Get options
    [HighPass, LowPass, isMirror] = GetOptions(sProcess);
    % ===== FILTER DATA =====
    sInput.A = Compute(sInput.A, sInput.TimeVector, HighPass, LowPass, [], isMirror);
    % ===== FILE COMMENT =====
    if ~isempty(HighPass) && ~isempty(LowPass)
        filterComment = ['| band(' num2str(HighPass) '-' num2str(LowPass) 'Hz)'];
    elseif ~isempty(HighPass)
        filterComment = ['| high(' num2str(HighPass) 'Hz)'];
    elseif ~isempty(LowPass)
        filterComment = ['| low(', num2str(LowPass) 'Hz)'];
    else
        filterComment = '';
    end
    sInput.FileTag = filterComment;
    % Comment for History
    sInput.HistoryComment = strrep(filterComment, '| ', '');    
end


%% ===== EXTERNAL CALL =====
% USAGE: x = process_bandpass('Compute', x, Time, HighPass, LowPass, Method, isMirror)
%        x = process_bandpass('Compute', x, Time, HighPass, LowPass)
%        x = process_bandpass('Compute', x, sfreq, ...)
function x = Compute(x, sfreq, HighPass, LowPass, method, isMirror)
    % Default method
    if (nargin < 6) || isempty(isMirror)
        isMirror = 1;
    end
    if (nargin < 5) || isempty(method)
        %if bst_get('UseSigProcToolbox')
            method = 'bst-fft-fir';
        %else
        %    method = 'bst-fft';
        %end
    end
    % Get sampling frequency from time vector
    if (length(sfreq) > 1)
        sfreq = 1 ./ (sfreq(2)-sfreq(1));
    end
    % Filtering using the selected method
    switch (method)
        case 'bst-fft-fir'
            x = bst_bandpass(x, sfreq, HighPass, LowPass, 1, isMirror);
        case 'bst-fft'
            x = bst_bandpass(x, sfreq, HighPass, LowPass, 0, isMirror);
        case 'bst-sos'
            % Prepare options structure
            coef.LowPass = LowPass;
            coef.HighPass = HighPass;
            % Filter signal
            x = bst_bandpass_sos(x, sfreq, coef);
    end
end



