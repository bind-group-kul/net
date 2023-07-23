function export_events( DataFile, OutputFile )
% EXPORT_EVENTS: Export events from a file or from the raw file viewer.
%
% USAGE:  export_events(DataFile, OutputFile )  : Get the events from DataFile, save them to OutputFile
%         export_events(DataFile)               : Get the events from DataFile, ask where to save them
%         export_events([], ...)                : Get the events from the raw file viewer
%         export_events(sFile, ...)             : Save the specified events structure
%         export_events()                       : Get the events from the raw file viewer, ask where to save them
%
% INPUT: 
%     - DataFile   : Brainstorm file that contains the events to save
%     - OutputFile : Output events file

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
% Authors: Francois Tadel, 2010-2013

%% ===== PARSE INPUTS =====
global GlobalData;
if (nargin < 2)
    OutputFile = [];
end
% CALL: export_events([], ...)
if (nargin < 1) || isempty(DataFile)
    % Get raw file viewer dataset
    [iDS, isRaw] = panel_record('GetCurrentDataset');
    if isempty(iDS)
        error('No events are currently loaded.');
    end
    % Get sFile structure
    sFile = GlobalData.DataSet(iDS).Measures.sFile;
% CALL: export_events(DataFile, ...)
elseif ischar(DataFile)
    % Load data file
    DataMat = in_bst_data(DataFile);
    if ~isstruct(DataMat.F)
        sFile = DataMat.F;
    else
        sFile = db_template('sFile');
        sFile.events   = DataMat.Events;
        sFile.format   = 'BST';
        sFile.filename = DataFile;
        sFile.prop.times   = DataMat.Time([1 end]);
        sFile.prop.sfreq   = 1 ./ (DataMat.Time(2) - DataMat.Time(1));
        sFile.prop.samples = round(sFile.prop.times * sFile.prop.sfreq);
    end
    clear DataMat;
% CALL: export_events(sFile, ...)
elseif isstruct(DataFile)
    sFile = DataFile;
end

% Check number of events
if isempty(sFile.events)
    error('No event available in this file.');
end
    

%% ===== SELECT OUTPUT FILE =====
if isempty(OutputFile)
    % === Build a default filename ===
    % Get raw path
    if isfield(sFile, 'filename') && ~isempty(sFile.filename)
        [fPath, fBase, fExt] = bst_fileparts(sFile.filename);
    else
        fPath = '';
        fBase = 'export';
    end
    % Get default directories and formats
    DefaultFormats = bst_get('DefaultFormats');
    if isempty(DefaultFormats.EventsOut)
        DefaultFormats.EventsOut = 'CTF';
    end
    % Get default extension
    switch (DefaultFormats.EventsOut)
        case 'BST'
            OutputFile = bst_fullfile(fPath, ['events_' fBase '.mat']);
        case 'CTF'
            OutputFile = bst_fullfile(fPath, 'MarkerFile-bst.mrk');
        case 'FIF'
            OutputFile = bst_fullfile(fPath, [fBase, '.eve']);
        case {'ARRAY-TIMES', 'ARRAY-SAMPLES'}
            OutputFile = bst_fullfile(fPath, [file_standardize(sFile.events(1).label), '.txt']);
        case 'CTFVIDEO'
            OutputFile = bst_fullfile(fPath, 'video_events.txt');
        otherwise
            OutputFile = bst_fullfile(fPath, [fBase, '.eve']);
    end

    % === Ask filename ===
    [OutputFile, FileFormat] = java_getfile( 'save', ...
        'Export events...', ...  % Window title
        OutputFile, ...          % Default filename
        'single', 'files', ...   % Selection mode
        {{'_events'},       'Brainstorm (events*.mat)',  'BST'; ...
         {'.mrk'},          'CTF MarkerFile (*.mrk)',    'CTF'; ...
         {'.eve','.fif'},   'Neuromag/MNE (*.eve)',      'FIF'; ...
         {'.txt'},          'Array of times (*.txt)',    'ARRAY-TIMES'; ... 
         {'.txt'},          'Array of samples (*.txt)',  'ARRAY-SAMPLES'; ...
         {'.txt'},          'CTF Video Times (*.txt)',  'CTFVIDEO'}, ...
         DefaultFormats.EventsOut);
    % If no file was selected: exit
    if isempty(OutputFile)
        return
    end
    % Save default export format
    DefaultFormats.EventsOut = FileFormat;
    bst_set('DefaultFormats',  DefaultFormats);
else
    % Detect output file format
    [fPath, fBase, fExt] = bst_fileparts(OutputFile);
    switch(fExt)
        case '.mat',   FileFormat = 'BST';
        case '.mrk',   FileFormat = 'CTF';
        case '.eve',   FileFormat = 'FIF';
        case '.txt',   FileFormat = 'ARRAY-TIMES';
    end
end


%% ===== SAVE EVENTS FILE =====
% Show progress bar
bst_progress('start', 'Export events', 'Saving file...');
% Switch between file formats
switch FileFormat
    case 'BST'
        s.events = sFile.events;
        bst_save(OutputFile, s, 'v7');
    case 'CTF'
        out_events_ctf(sFile, OutputFile);
    case 'FIF'
        if strcmpi(OutputFile(end-4:end), '.fif')
            OutputFile(end-4:end) = '.eve';
        end
        out_events_eve(sFile, OutputFile);
    case 'ARRAY-TIMES'
        if (length(sFile.events) > 1)
            error('Cannot export more than one event at a time with this format.');
        end
        eve = sFile.events.times;
        save(OutputFile, 'eve', '-ascii');
    case 'ARRAY-SAMPLES'
        if (length(sFile.events) > 1)
            error('Cannot export more than one event at a time with this format.');
        end
        eve = sFile.events.samples;
        save(OutputFile, 'eve', '-ascii');
    case 'CTFVIDEO'
        out_events_video(sFile,OutputFile);
    otherwise
        error(['Unsupported file format : "' FileFormat '"']);
end
% Hide progress bar
bst_progress('stop');






