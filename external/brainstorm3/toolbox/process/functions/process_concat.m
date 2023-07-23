function varargout = process_concat( varargin )
% PROCESS_CONCAT: Concatenate several data files using the time information from the first file.

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
% Authors: Francois Tadel, 2013

macro_methodcall;
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Concatenate recordings';
    sProcess.FileTag     = '';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Standardize';
    sProcess.Index       = 305;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data'};
    sProcess.OutputTypes = {'data'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 2;
    sProcess.isSeparator = 1;
    % Definition of the options
    % === NOTICE
    sProcess.options.label1.Type    = 'label';
    sProcess.options.label1.Comment = '<HTML>The first file in the list is used as the time reference,<BR>the time information from the following files is ignored.';
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>
    % Load the first file, as the reference
    NewMat = in_bst_data(sInputs(1).FileName, fieldnames(db_template('datamat'))');
    % Check all the input files
    for iInput = 2:length(sInputs)
        % Load the next file
        DataMat = in_bst_data(sInputs(iInput).FileName, fieldnames(db_template('datamat'))');
        % Check consistency with the number of sensors
        if (size(NewMat.F,1) ~= size(DataMat.F,1))
            bst_report('Error', sProcess, sInputs(iInput), ['This file has a different number of channels than the previous ones: "' sInputs(iInput).ChannelFile '".']);
            return;
        end
        % Concatenate the F matrices
        NewMat.F = [NewMat.F, DataMat.F];
        % Add the bad channels
        NewMat.ChannelFlag(DataMat.ChannelFlag == -1) = -1;
        % Concatenate the events
        if ~isempty(DataMat.Events) 
            if isempty(NewMat.Events)
                NewMat.Events = DataMat.Events;
            else
                % Trick import_events() to work for event concatenation
                sFile.events = NewMat.Events;
                sFile.prop.sfreq = 1 ./ (NewMat.Time(2) - NewMat.Time(1));
                sFile = import_events(sFile, DataMat.Events);
                NewMat.Events = sFile.events;
            end
        end
    end
    % Set the final time vector
    NewMat.Time = NewMat.Time(1) + (0:size(NewMat.F,2)-1) .* (NewMat.Time(2) - NewMat.Time(1));
    % Set comment
    if (NewMat.Time(end) > 2)
        timeComment = sprintf('(%1.2fs,%1.2fs)', NewMat.Time(1), NewMat.Time(end));
    else
        timeComment = sprintf('(%dms,%dms)', round(1000 * NewMat.Time(1)), round(1000 * NewMat.Time(end)));
    end
    NewMat.Comment = [str_remove_parenth(NewMat.Comment), ' concat' timeComment];
    % Get output filename
    OutputFiles{1} = bst_process('GetNewFilename', bst_fileparts(sInputs(1).FileName), 'data_concat');
    % Save file
    bst_save(OutputFiles{1}, NewMat, 'v6');
    % Register in database
    db_add_data(sInputs(1).iStudy, OutputFiles{1}, NewMat);
end


