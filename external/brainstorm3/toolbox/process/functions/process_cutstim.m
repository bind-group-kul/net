function varargout = process_cutstim( varargin )
% PROCESS_CUTSTIM: Remove the values on a specific time window, and replace them with a linear interpolation.

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
% Authors: Francois Tadel, 2010-2011

macro_methodcall;
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Cut stimulation artifact';
    sProcess.FileTag     = '| cutstim';
    sProcess.Category    = 'Filter';
    sProcess.SubGroup    = 'Artifacts';
    sProcess.Index       = 114;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data'};
    sProcess.OutputTypes = {'data'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    % Default values for some options
    sProcess.processDim  = 1;    % Process channel by channel
    
    % Definition of the options
    % === Artifact time window
    sProcess.options.timewindow.Comment = 'Artifact time window:';
    sProcess.options.timewindow.Type    = 'baseline';
    sProcess.options.timewindow.Value   = [];
    % === Sensor types
    sProcess.options.sensortypes.Comment = 'Sensor types or names (empty=all): ';
    sProcess.options.sensortypes.Type    = 'text';
    sProcess.options.sensortypes.Value   = 'MEG, EEG';
    sProcess.options.sensortypes.InputTypes = {'data'};
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    % Get frequency band
    time = sProcess.options.timewindow.Value{1};
    % Add frequency band
    if any(abs(time) > 2)
        Comment = sprintf('%s: [%1.3fs,%1.3fs]', sProcess.Comment, time(1), time(2));
    else
        Comment = sprintf('%s: [%dms,%dms]', sProcess.Comment, round(time(1)*1000), round(time(2)*1000));
    end
end


%% ===== RUN =====
function sInput = Run(sProcess, sInput) %#ok<DEFNU>
    % Get inputs
    iTime = panel_time('GetTimeIndices', sInput.TimeVector, sProcess.options.timewindow.Value{1});
    if isempty(iTime)
        bst_report('Error', sProcess, [], 'Invalid time definition.');
        sInput = [];
        return;
    end
    [Nchan, Ntime] = size(sInput.A);
    
    % Get all the indices except but the removed time window
    iValid = setdiff(1:Ntime, iTime);
    % Reinterpolate values for the removed time window
    for i = 1:Nchan
        sInput.A(i,iTime) = interp1(iValid, sInput.A(i,iValid), iTime, 'linear');
    end

    % History comment
    sInput.HistoryComment = sprintf('Cut stimulation artifact: [%1.2f, %1.2f] ms', sInput.TimeVector(iTime([1 end])) * 1000);
end




