function varargout = process_hilbert( varargin )
% PROCESS_HILBERT: Computes the Hilbert transform of all the trials, and average them.

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
    sProcess.Comment     = 'Hilbert transform';
    sProcess.FileTag     = 'hilbert';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Frequency';
    sProcess.Index       = 503;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'results', 'matrix'};
    sProcess.OutputTypes = {'timefreq', 'timefreq', 'timefreq'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    % Options: CLUSTERS
    sProcess.options.clusters.Comment = '';
    sProcess.options.clusters.Type    = 'cluster_confirm';
    sProcess.options.clusters.Value   = {};
    % Options: Sensor types
    sProcess.options.sensortypes.Comment = 'Sensor types or names (empty=all): ';
    sProcess.options.sensortypes.Type    = 'text';
    sProcess.options.sensortypes.Value   = 'MEG, EEG';
    sProcess.options.sensortypes.InputTypes = {'data'};
    % Options: Mirror
    sProcess.options.mirror.Comment = 'Mirror signal before filtering (to avoid edge effects)';
    sProcess.options.mirror.Type    = 'checkbox';
    sProcess.options.mirror.Value   = 1;
    % Separator
    %sProcess.options.sep.Type     = 'separator';
    sProcess.options.sep.Comment = '  ';
    sProcess.options.sep.Type    = 'label';
    % Options: Time-freq
    sProcess.options.edit.Comment = {'panel_timefreq_options', 'Hilbert transform options: '};
    sProcess.options.edit.Type    = 'editpref';
    sProcess.options.edit.Value   = [];
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>
    % Check Signal Processing Toolbox
    if ~bst_get('UseSigProcToolbox')
        bst_report('Error', sProcess, [], ['This process requires the Matlab Signal Processing Toolbox.' 10 ...
               'If you have it, make sure that it is enabled in Brainstorm preferences.']);
        OutputFiles = {};
        return;
    end
    % Call TIME-FREQ process
    OutputFiles = process_timefreq('Run', sProcess, sInputs);
end




