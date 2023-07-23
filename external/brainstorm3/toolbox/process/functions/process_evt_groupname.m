function varargout = process_evt_groupname( varargin )
% PROCESS_EVT_GROUPNAME: Combine different categories events into one (by name)
%
% USAGE:  OutputFiles = process_evt_groupname('Run', sProcess, sInputs)

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
    sProcess.Comment     = 'Events: Group by name';
    sProcess.FileTag     = '| evt';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Import recordings';
    sProcess.Index       = 16;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'raw'};
    sProcess.OutputTypes = {'data', 'raw'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    % Event name
    sProcess.options.combine.Comment = ['<HTML>Example: We have three events (A,B,C) and want to create new combinations:<BR>' ...
                                        '&nbsp;&nbsp;&nbsp;&nbsp;<B>E</B>: Event A and B occurring at the same time<BR>' ...
                                        '&nbsp;&nbsp;&nbsp;&nbsp;<B>F</B>: Event A and C occurring at the same time<BR>' ...
                                        'For that, use the following classification:<BR>' ...
                                        '&nbsp;&nbsp;&nbsp;&nbsp;<B>E</B> = A,B<BR>' ...
                                        '&nbsp;&nbsp;&nbsp;&nbsp;<B>F</B> = A,C<BR>' ...
                                        'You may add as many combinations as needed, one per line.<BR>' ...
                                        'You can delete or keep the original events (A,B,C) with the checkbox below.<BR><BR>'];
    sProcess.options.combine.Type    = 'textarea';
    sProcess.options.combine.Value   = '';
    % Delete original events
    sProcess.options.delete.Comment = 'Delete the original events';
    sProcess.options.delete.Type    = 'checkbox';
    sProcess.options.delete.Value   = 0;
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>
    % Return all the input files
    OutputFiles = {};
    
    % ===== GET OPTIONS =====
    % Get the options
    isDelete = sProcess.options.delete.Value;
    % Combination string
    combineStr = strtrim(sProcess.options.combine.Value);
    % Split in lines
    combine_lines = str_split(combineStr, [10 13]);
    % Split each line
    combineCell = {};
    for i = 1:length(combine_lines)
        % No information on this line: skip
        combine_lines{i} = strtrim(combine_lines{i});
        if isempty(combine_lines{i})
            continue;
        end
        % Split with "="
        lineCell = str_split(combine_lines{i}, '=');
        if (length(lineCell) ~= 2)
            continue;
        end
        % Split with ";,"
        eventsCell = str_split(lineCell{2}, ';,');
        % Add combination entry
        iComb = size(combineCell,1) + 1;
        combineCell{iComb,1} = strtrim(lineCell{1});
        combineCell{iComb,2} = cellfun(@strtrim, eventsCell, 'UniformOutput', 0);
    end
    % If no combination available
    if isempty(combineCell)
        bst_report('Error', sProcess, [], 'Invalid combinations format.');
        return;
    end
    
    % ===== PROCESS ALL FILES =====
    % For each file
    for iFile = 1:length(sInputs)
        % ===== GET FILE DESCRIPTOR =====
        % Load the raw file descriptor
        isRaw = strcmpi(sInputs(iFile).FileType, 'raw');
        if isRaw
            DataMat = in_bst_data(sInputs(iFile).FileName, 'F');
            sFile = DataMat.F;
        else
            sFile = in_fopen(sInputs(iFile).FileName, 'BST-DATA');
        end
        % If no markers are present in this file
        if isempty(sFile.events)
            bst_report('Error', sProcess, sInputs(iFile), 'This file does not contain any event. Skipping File...');
            continue;
        end
        % Call the grouping function
        [sFile.events, isModified] = Compute(sInputs(iFile), sFile.events, combineCell, isDelete);

        % ===== SAVE RESULT =====
        % Only save changes if something was change
        if isModified
            % Report changes in .mat structure
            if isRaw
                DataMat.F = sFile;
            else
                DataMat.Events = sFile.events;
            end
            % Save file definition
            bst_save(file_fullpath(sInputs(iFile).FileName), DataMat, 'v6', 1);
        end
        % Return all the input files
        OutputFiles{end+1} = sInputs(iFile).FileName;
    end
end


%% ===== GROUP EVENTS =====
function [events, isModified] = Compute(sInput, events, combineCell, isDelete)
    % No modification
    isModified = 0;
    % Loop on the different combinations
    for iComb = 1:size(combineCell,1)
        AllEvt = zeros(2,0);
        iEvtList = [];
        % Get events for this combination
        for iCombEvt = 1:length(combineCell{iComb,2})
            % Find event in the list
            evtLabel = combineCell{iComb,2}{iCombEvt};
            iEvt = find(strcmpi({events.label}, evtLabel));
            % If events are extended events: skip
            if isempty(iEvt)
                bst_report('Warning', 'process_evt_groupname', sInput, ['Event "' evtLabel '" does not exist. Skipping group...']);
                continue;
            end
            % If events are extended events: skip
            if (size(events(iEvt).times,1) > 1)
                bst_report('Error', 'process_evt_groupname', sInput, 'Cannot process extended events. Skipping group...');
                continue;
            end
            % Add to the list of all the processes
            iEvtList(end+1) = iEvt;
            AllEvt = [AllEvt, [events(iEvt).samples; repmat(iEvt, size(events(iEvt).samples))]];
        end
        % Skip combination if one of the events is not found or not a simple event
        if (length(iEvtList) ~= length(combineCell{iComb,2}))
            continue;
        end
        % Process each unique time value
        uniqueSamples = unique(AllEvt(1,:));
        for iSmp = 1:length(uniqueSamples)
            % Look for all the events happening at this time
            iEvts = AllEvt(2, (AllEvt(1,:) == uniqueSamples(iSmp)));
            % If only one occurrance: skip to the next time
            if (length(iEvts) ~= length(iEvtList))
                continue;
            end
            % Remove occurrence from each event type (and build new event name)
            for i = 1:length(iEvts)
                % Find the occurrence indice
                iOcc = find(events(iEvts(i)).samples == uniqueSamples(iSmp));
                % Get the values 
                if (i == 1)
                    newTime   = events(iEvts(i)).times(iOcc);
                    newSample = events(iEvts(i)).samples(iOcc);
                    newEpoch  = events(iEvts(i)).epochs(iOcc);
                end
                % Remove this occurrence
                if isDelete
                    events(iEvts(i)).times(iOcc)   = [];
                    events(iEvts(i)).samples(iOcc) = [];
                    events(iEvts(i)).epochs(iOcc)  = [];
                end
            end
            % New event name
            newLabel = combineCell{iComb,1};
            % Find this event in the list
            iNewEvt = find(strcmpi(newLabel, {events.label}));
            % Create event category if does not exist yet
            if isempty(iNewEvt)
                % Initialize new event
                iNewEvt = length(events) + 1;
                sEvent = db_template('event');
                sEvent.label = newLabel;
                % Color
                ColorTable = panel_record('GetEventColorTable');
                iColor = mod(iNewEvt - 1, length(ColorTable)) + 1;
                sEvent.color = ColorTable(iColor,:);
                % Add new event to list
                events(iNewEvt) = sEvent;
            end
            % Add occurrences
            events(iNewEvt).times   = [events(iNewEvt).times,   newTime];
            events(iNewEvt).samples = [events(iNewEvt).samples, newSample];
            events(iNewEvt).epochs  = [events(iNewEvt).epochs,  newEpoch];
            % Sort
            [events(iNewEvt).times, indSort] = unique(events(iNewEvt).times);
            events(iNewEvt).samples = events(iNewEvt).samples(indSort);
            events(iNewEvt).epochs  = events(iNewEvt).epochs(indSort);
            isModified = 1;
        end
    end
end






