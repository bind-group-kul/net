function events = in_events_ctf(sFile, EventFile)
% IN_EVENTS_CTF: Read marker information from CTF MarkerFile.mrk located in DS_FOLDER 
%
% USAGE:  events = in_events_ctf(sFile, EventFile)
%
% OUTPUT:
%    - events(i): array of structures with following fields (one structure per event type) 
%        |- label   : Identifier of event #i
%        |- samples : Array of unique time indices for event #i in the corresponding raw file
%        |- times   : Array of unique time latencies (in seconds) for event #i in the corresponding raw file
%                     => Not defined for files read from -eve.fif files

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
% Authors: Sylvain Baillet, Francois Tadel, 2009-2012
    
% Store everything in a cell array of string
txtCell =  textread(EventFile,'%s','delimiter','\n'); 

% Read number of markers
id = find(strcmp(txtCell,'NUMBER OF MARKERS:'));
nMarkers  = str2num(txtCell{id+1});

% Read marker names
id = find(strcmp(txtCell,'NAME:'));
marker_names = txtCell(id+1);
% Read marker color
id = find(strcmp(txtCell,'COLOR:'));
marker_colors = txtCell(id+1);
% Read marker color
id = find(strcmp(txtCell,'CLASSID:'));
classid = txtCell(id+1);
% Read number of samples for each marker
id = find(strcmp(txtCell,'NUMBER OF SAMPLES:'));
nSamples = str2num(char(txtCell(id+1)));
% Get start of description block for each marker
mrkr_info = strmatch('TRIAL NUMBER',txtCell)+1;

% Initialize returned structure
events = repmat(db_template('event'), 0);
% Loop on each marker
for i = 1:nMarkers
    % Get trial indice and time of all occurrences
    iTrials = mrkr_info(i) + (0:nSamples(i)-1);
    if any(iTrials > length(txtCell))
        disp('IN_EVENTS> Error: Marker file is corrupted, not enough trial samples...');
        iTrials(iTrials > length(txtCell)) = [];
    end
    trial_time = str2num(char(txtCell(iTrials))); 
    % If at least one marker occurrence exists
    if ~isempty(trial_time)
        iEvt = length(events) + 1;
        events(iEvt).label = marker_names{i};
        events(iEvt).epochs  = trial_time(:,1)' + 1;
        events(iEvt).times   = trial_time(:,2)';
        events(iEvt).samples = round(events(iEvt).times .* sFile.prop.sfreq);
        events(iEvt).reactTimes  = [];
        events(iEvt).select      = 1;
        % Color
        if (length(marker_colors{i}) == 13) && (marker_colors{i}(1) == '#')
            events(iEvt).color = [hex2dec(marker_colors{i}(2:5)), hex2dec(marker_colors{i}(6:9)), hex2dec(marker_colors{i}(10:13))] ./ (256 * 256 - 1);
        end
    end
end

% Convert to CTF-CONTINUOUS if necessary
if ~isempty(events) && strcmpi(sFile.format, 'CTF-CONTINUOUS')
    sFile = process_ctf_convert('Compute', sFile, 'epoch');
    sFile.events = events;
    sFile = process_ctf_convert('Compute', sFile, 'continuous');
    events = sFile.events;
end



