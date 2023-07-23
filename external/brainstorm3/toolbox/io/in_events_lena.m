function events = in_events_lena(sFile, EventFile)
% IN_EVENTS_LENA: Read the events descriptions for a LENA file.
%
% USAGE:  events = in_events_lena(sFile, EventFile) 
%
% OUTPUT:
%    - events(i): array of structures with following fields (one structure per event type) 
%        |- label  : Identifier of event #i
%        |- epochs : Array of epochs indices where each event occurs (1 for all the events if there are no epochs)
%        |- times  : Array of unique time latencies (in seconds) for event #i in the corresponding raw file
%                    => Not defined for files read from -eve.fif files

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
% Authors: Francois Tadel, 2009

% Open file
fid = fopen(EventFile, 'r');
if (fid < 0)
    error('Cannot open marker file.');
end
% Initialize returned structure
events = repmat(db_template('event'), 0);
fileVer = 1;
% Read file line by line
while 1
    % Read a line
    tline = fgetl(fid);
    
    % If the an error occured: stop reading
    if ~ischar(tline)
        break
    end
    % If line starts with a '#', it is a comment
    if isempty(tline) || (tline(1) == '#')
        % Check if the format is indicated in it
        if ~isempty(strfind(tline, 'PTX_V2'))
            fileVer = 2;
        end
        continue;
    end

    % Read lines according to version
    switch (fileVer)
        case 1
            [time, label] = strread(tline, '%f %s');
            time = time ./ 1000;
            iEpoch = 0;
        case 2
            [iEpoch, time, label, duration, offset] = strread(tline, '%d %f %s %d %d');
    end
    % Get file time and sample indices
    sample = round(time .* sFile.prop.sfreq) + sFile.prop.samples(1);
    time   = sample ./ sFile.prop.sfreq;
        
    % If no label was read: ignore line
    if isempty(label)
        continue;
    % If label name starts with '__': combination of several events
    elseif (length(label{1}) > 2) && strcmpi(label{1}(1:2), '__')
        for i = 3:length(label{1})
            events = addEvent(events, label{1}(i), iEpoch, time, sample);
        end
    % Else: only one event
    else
        events = addEvent(events, label{1}, iEpoch, time, sample);
    end
end
% Close file
fclose(fid);

end


%% ===== ADD EVENT TO EVENTS LIST =====
function events = addEvent(events, label, iEpoch, time, sample)
    isStop = 0;
    % Start/stop events
    if ~isempty(strfind(label, '__START__'))
        label = strrep(label, '__START__', '');
    elseif ~isempty(strfind(label, '__END__'))
        label = strrep(label, '__END__', '');
        isStop = 1;
    end
    % Look for previous event of this name in the events list
    iEvt = find(strcmp({events.label}, label));
    % If event is not registered yet in the list: add it
    if isempty(iEvt)
        iEvt = length(events) + 1;
        events(iEvt).label  = label;
        events(iEvt).epochs = iEpoch;
        if isStop
            events(iEvt).times   = [0; time];
            events(iEvt).samples = [0; sample];
        else
            events(iEvt).times   = time;
            events(iEvt).samples = sample;
        end
        events(iEvt).reactTimes = [];
        events(iEvt).select  = 1;
    % Event already registered: add instance
    else
        events(iEvt).epochs(end + 1) = iEpoch;
        if isStop
            events(iEvt).times(2, end)   = time;
            events(iEvt).samples(2, end) = sample;
        else
            events(iEvt).times(1, end + 1)   = time;
            events(iEvt).samples(1, end + 1) = sample;
        end
    end
end



