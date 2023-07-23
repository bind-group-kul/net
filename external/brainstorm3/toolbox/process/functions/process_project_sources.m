function varargout = process_project_sources( varargin )
% PROCESS_PROJECT_SOURCES: Project source files on a different surface.

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
    sProcess.Comment     = 'Project on default anatomy';
    sProcess.FileTag     = '';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Sources';
    sProcess.Index       = 334;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'results', 'timefreq'};
    sProcess.OutputTypes = {'results', 'timefreq'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    % Default values for some options
    sProcess.options.source_abs.Comment = '<HTML>Use absolute values of source activations<BR><I>This directive works only for full results: [nSources x nTime]</I>';
    sProcess.options.source_abs.Type    = 'checkbox';
    sProcess.options.source_abs.Value   = 0;
    sProcess.options.source_abs.InputTypes = {'results'};
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>
    OutputFiles = {};
    % Get options
    if isfield(sProcess.options, 'source_abs') && ~isempty(sProcess.options.source_abs.Value)
        isAbsoluteValues = sProcess.options.source_abs.Value;
    else
        isAbsoluteValues = 0;
    end
    % List all the input files
    ResultsFile = {sInputs.FileName};
    % Get default anatomy
    sDefSubject = bst_get('Subject', 0);
    if isempty(sDefSubject.iCortex)
        bst_report('Error', sProcess, [], 'No cortex available for the default anatomy.');
        return;
    end
    % Get default cortex of default anatomy
    destSurfFile = sDefSubject.Surface(sDefSubject.iCortex).FileName;
    % Project sources
    OutputFiles = bst_project_sources( ResultsFile, destSurfFile, isAbsoluteValues, 0 );
end




