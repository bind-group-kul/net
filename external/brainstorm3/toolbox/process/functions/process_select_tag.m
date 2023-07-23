function varargout = process_select_tag( varargin )
% PROCESS_SELECT_TAG: Keep only the files within the current selection that have the specified tag in their filename.
%
% USAGE:  sProcess = process_select_tag('GetDescription')
%                    process_select_tag('Run', sProcess, sInputs)

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
    sProcess.Comment     = 'Select files with tag';
    sProcess.FileTag     = '';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'File';
    sProcess.Index       = 1010;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'results', 'timefreq', 'matrix', 'pdata', 'presults', 'ptimefreq'};
    sProcess.OutputTypes = {'data', 'results', 'timefreq', 'matrix', 'pdata', 'presults', 'ptimefreq'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    sProcess.isSeparator = 1;
    % Definition of the options
    % === TARGET
    sProcess.options.tag.Comment = 'Search: ';
    sProcess.options.tag.Type    = 'text';
    sProcess.options.tag.Value   = '';
    % === FILENAME / COMMENT
    sProcess.options.label1.Comment = 'Where to look for:';
    sProcess.options.label1.Type    = 'label';
    sProcess.options.search.Comment = {'Search the file names', 'Search the file comments'};
    sProcess.options.search.Type    = 'radio';
    sProcess.options.search.Value   = 2;
    % === SELECT / IGNORE
    sProcess.options.label2.Comment = 'What to do with those files:';
    sProcess.options.label2.Type    = 'label';
    sProcess.options.select.Comment = {'Select only the files with the tag', 'Ignore the files with the tag'};
    sProcess.options.select.Type    = 'radio';
    sProcess.options.select.Value   = 1;
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    tag = strtrim(sProcess.options.tag.Value);
    if isempty(tag)
        tag = 'Not defined';
    end
    % Ignore/select
    if (sProcess.options.select.Value == 1)
        Comment = 'Select';
    else
        Comment = 'Ignore';
    end
    % Filename/comment
    if (sProcess.options.search.Value == 1)
        Comment = [Comment ' file names with tag: ' tag];
    else
        Comment = [Comment ' file comments with tag: ' tag];
    end
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>
    % Get new tag
    tag = sProcess.options.tag.Value;
    if isempty(tag)
        bst_report('Error', sProcess, [], 'Tag is not defined.');
        OutputFiles = {};
        return
    end
    % Search filenames/comments
    if (sProcess.options.search.Value == 1)
        isTag = ~cellfun(@(c)isempty(strfind(upper(c),upper(tag))), {sInputs.FileName});
    else
        isTag = ~cellfun(@(c)isempty(strfind(upper(c),upper(tag))), {sInputs.Comment});
    end
    % Ignore or select
    if (sProcess.options.select.Value == 1)
        iFiles = find(isTag);
    else
        iFiles = find(~isTag);
    end
    % Warning: nothing found
    if isempty(iFiles)
        bst_report('Error', sProcess, [], ['No files found for tag: ' tag]);
        OutputFiles = {};
        return
    end
    % Report information
    strReport = sprintf('Files selected for tag "%s": %d/%d', tag, length(iFiles), length(sInputs));
    bst_report('Info', sProcess, [], strReport);
    %disp(['BST> ' strReport]);
    % Return only the filenames that have the specific tag
    OutputFiles = {sInputs(iFiles).FileName};
end



