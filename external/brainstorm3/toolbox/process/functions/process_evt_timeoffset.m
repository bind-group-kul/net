function varargout = process_evt_timeoffset( varargin )
% PROCESS_EVT_TIMEOFFSET: Add a time offset to all the events of a given category
%
% USAGE:  OutputFiles = process_evt_timeoffset('Run', sProcess, sInput)

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
    sProcess.Comment     = 'Events: Add time offset';
    sProcess.FileTag     = '| evttime';
    sProcess.Category    = 'File';
    sProcess.SubGroup    = 'Import recordings';
    sProcess.Index       = 17;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'raw'};
    sProcess.OutputTypes = {'data', 'raw'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    sProcess.isSeparator = 1;
    % Event name
    sProcess.options.eventname.Comment = 'Event names: ';
    sProcess.options.eventname.Type    = 'text';
    sProcess.options.eventname.Value   = '';
    % Time offset
    sProcess.options.offset.Comment = 'Time offset:';
    sProcess.options.offset.Type    = 'value';
    sProcess.options.offset.Value   = {0, 'ms', []};
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFile = Run(sProcess, sInput) %#ok<DEFNU>
    % Return all the input files
    OutputFile = {sInput.FileName};
    
    % ===== GET OPTIONS =====
    % Time offset
    OffsetTime = sProcess.options.offset.Value{1};
    % Event names
    EvtNames = strtrim(str_split(sProcess.options.eventname.Value, ',;'));
    if isempty(EvtNames)
        bst_report('Error', sProcess, [], 'No events selected.');
        return;
    end
    
    % ===== LOAD FILE =====
    % Get file descriptor
    isRaw = strcmpi(sInput.FileType, 'raw');
    % Load the raw file descriptor
    if isRaw
        DataMat = in_bst_data(sInput.FileName, 'F');
        sEvents = DataMat.F.events;
        sFreq = DataMat.F.prop.sfreq;
    else
        DataMat = in_bst_data(sInput.FileName, 'Events', 'Time');
        sEvents = DataMat.Events;
        sFreq = 1 ./ (DataMat.Time(2) - DataMat.Time(1));
    end
    % If no markers are present in this file
    if isempty(sEvents)
        bst_report('Error', sProcess, sInput, 'This file does not contain any event.');
        return;
    end
    % Find event names
    iEvtList = [];
    for i = 1:length(EvtNames)
        iEvt = find(strcmpi(EvtNames{i}, {sEvents.label}));
        if ~isempty(iEvt)
            iEvtList(end+1) = iEvt;
        else
            bst_report('Warning', sProcess, sInput, 'This file does not contain any event.');
        end
    end
    % No events to process
    if isempty(sEvents)
        bst_report('Error', sProcess, sInput, 'No events to process.');
        return;
    end
    % Snap time offset to the closest sample
    OffsetSample = round(OffsetTime * sFreq);
    if (OffsetSample == 0)
        bst_report('Error', sProcess, sInput, 'The selected time offset must be longer than one time sample.');
        return;
    end
    
    % ===== PROCESS EVENTS =====
    for i = 1:length(iEvtList)
        sEvents(iEvtList(i)).samples = sEvents(iEvtList(i)).samples + OffsetSample;
        sEvents(iEvtList(i)).times   = sEvents(iEvtList(i)).times + OffsetSample / sFreq;
    end
        
    % ===== SAVE RESULT =====
    % Report results
    if isRaw
        DataMat.F.events = sEvents;
    else
        DataMat.Events = sEvents;
    end
    % Only save changes if something was change
    bst_save(file_fullpath(sInput.FileName), DataMat, 'v6', 1);
end




