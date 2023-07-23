function varargout = process_average_freq( varargin )
% PROCESS_AVERAGE_FREQ: For each file in input, compute the average of the different frequency bands.

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
    sProcess.Comment     = 'Average frequency bands';
    sProcess.FileTag     = '| avgfreq';
    sProcess.Category    = 'File';
    sProcess.SubGroup    = 'Average';
    sProcess.Index       = 303;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'timefreq'};
    sProcess.OutputTypes = {'timefreq'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFile = Run(sProcess, sInput) %#ok<DEFNU>
    OutputFile = [];
    % Load TF file
    TimefreqMat = in_bst_timefreq(sInput.FileName, 0);
    % Check for measure
    if strcmpi(TimefreqMat.Measure, 'none')
        bst_report('Error', sProcess, sInput, 'Cannot average complex values. Please apply a measure to the values before calling this function.');
        return;
    end
    % Average time-freq values
    TimefreqMat.TF = mean(TimefreqMat.TF, 3);
    % Remove the frequency information
    if iscell(TimefreqMat.Freqs)
        TimefreqMat.Freqs = {'Avg freq', TimefreqMat.Freqs{1,2}, TimefreqMat.Freqs{end,3}};
    else
        TimefreqMat.Freqs = TimefreqMat.Freqs(end);
    end
    % Add file tag
    TimefreqMat.Comment = [TimefreqMat.Comment, ' ', sProcess.FileTag];
    % Add history entry
    TimefreqMat = bst_history('add', TimefreqMat, 'avgfreq', 'Averaged all the frequency bands.');

    % Output filename: add file tag
    FileTag = strtrim(strrep(sProcess.FileTag, '|', ''));
    OutputFile = strrep(file_fullpath(sInput.FileName), '.mat', ['_' FileTag '.mat']);
    OutputFile = file_unique(OutputFile);
    % Save file
    bst_save(OutputFile, TimefreqMat, 'v6');
    % Add file to database structure
    db_add_data(sInput.iStudy, OutputFile, TimefreqMat);
end




