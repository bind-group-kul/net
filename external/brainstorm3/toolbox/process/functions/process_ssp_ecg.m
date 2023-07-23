function varargout = process_ssp_ecg( varargin )
% PROCESS_SSP_ECG: Reject cardiac artifact for a group of recordings file
%
% USAGE:  OutputFiles = process_ssp_ecg('Run', sProcess, sInputs)

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
% Authors: Francois Tadel, 2011-2012

macro_methodcall;
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Compute SSP: Heartbeats';
    sProcess.FileTag     = '| ssp_ecg';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Artifacts';
    sProcess.Index       = 111;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'raw'};
    sProcess.OutputTypes = {'data', 'raw'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
   
    % Event name
    sProcess.options.eventname.Comment = 'Event name: ';
    sProcess.options.eventname.Type    = 'text';
    sProcess.options.eventname.Value   = 'cardiac';
    sProcess.options.eventname.InputTypes = {'raw'};
    % Sensor types
    sProcess.options.sensortypes.Comment = 'Sensor types or names (empty=all): ';
    sProcess.options.sensortypes.Type    = 'text';
    sProcess.options.sensortypes.Value   = 'MEG, MEG MAG, MEG GRAD';
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    if isfield(sProcess.options, 'eventname') && ~isempty(sProcess.options.eventname.Value)
        Comment = ['SSP ECG: ' sProcess.options.eventname.Value];
    else
        Comment = sProcess.Comment;
    end
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>
    % Pre-defined values for ECG
    sProcess.options.eventtime.Value  = {[-.040, .040], 'ms'};
    sProcess.options.bandpass.Value   = {[13, 40], 'Hz'};
    sProcess.options.output.Value     = 1;
    % Call the generic version of the event detection
    OutputFiles = process_ssp('Run', sProcess, sInputs);
end



