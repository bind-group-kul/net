function [sFile, errMsg] = in_fopen(DataFile, FileFormat, ImportOptions)
% IN_FOPEN:  Open a file for reading in Brainstorm.
%
% USAGE:  [sFile, errMsg] = in_fopen(DataFile, FileFormat, ImportOptions)
%         [sFile, errMsg] = in_fopen(DataFile, FileFormat)
%
% INPUT:
%     - DataFile      : Full path to file to open
%     - FileFormat    : Description of the file format (look in import_data.m for list of supported formats)
%     - ImportOptions : Structure that describes how to import the recordings.
%       => Fields used: ChannelAlign, ChannelReplace, DisplayMessages, EventsMode, EventsTrackMode
%
% OUTPUT:
%     - sFile : Brainstorm structure to pass to the in_fread() function.

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
% Authors: Francois Tadel, 2009-2012

if (nargin < 3) || isempty(ImportOptions)
    ImportOptions = db_template('ImportOptions');
end
errMsg = [];

switch (FileFormat)
    case 'FIF'
        sFile = in_fopen_fif(DataFile, ImportOptions);
    case {'CTF', 'CTF-CONTINUOUS'}
        sFile = in_fopen_ctf(DataFile);
    case '4D'
        sFile = in_fopen_4d(DataFile, ImportOptions);
    case 'KIT'
        [sFile, errMsg] = in_fopen_kit(DataFile);
    case 'LENA'
        sFile = in_fopen_lena(DataFile);
    case 'EEG-ANT-CNT'
        sFile = in_fopen_ant(DataFile);
    case 'EEG-BRAINAMP'
        sFile = in_fopen_brainamp(DataFile);
    case 'EEG-DELTAMED'
        sFile = in_fopen_deltamed(DataFile);
    case {'EEG-EDF', 'EEG-BDF'}
        sFile = in_fopen_edf(DataFile);
    case 'EEG-EEGLAB'
        sFile = in_fopen_eeglab(DataFile, ImportOptions);
    case 'EEG-EGI-RAW'
        sFile = in_fopen_egi(DataFile, [], [], ImportOptions);
    case 'EEG-MANSCAN'
        sFile = in_fopen_manscan(DataFile);
    case 'EEG-NEUROSCAN-CNT'
        sFile = in_fopen_cnt(DataFile, ImportOptions);
    case 'EEG-NEUROSCAN-EEG'
        sFile = in_fopen_eeg(DataFile);
    case 'EEG-NEUROSCAN-AVG'
        sFile = in_fopen_avg(DataFile);
    case 'EEG-NEUROSCOPE'
        sFile = in_fopen_neuroscope(DataFile);
    case 'NIRS-MFIP'
        sFile = in_fopen_mfip(DataFile);
    case 'BST-DATA'
        % Load file
        DataMat = in_bst_data(DataFile);
        % Load channel file
        ChannelFile = bst_get('ChannelFileForStudy', DataFile);
        if ~isempty(ChannelFile)
            ChannelMat = in_bst_channel(ChannelFile);
        else
            ChannelMat = [];
        end
        % Generate a sFile structure that describes this database file
        sFile = db_template('sfile');
        sFile.filename = file_fullpath(DataFile);
        sFile.format   = 'BST-DATA';
        sFile.device   = 'Brainstorm';
        sFile.comment  = DataMat.Comment;
        sFile.prop.times   = [DataMat.Time(1), DataMat.Time(end)];
        sFile.prop.sfreq   = 1 ./ (DataMat.Time(2) - DataMat.Time(1));
        sFile.prop.samples = round(sFile.prop.times .* sFile.prop.sfreq);
        sFile.prop.currCtfComp = 3;
        sFile.prop.destCtfComp = 3;
        if isfield(DataMat, 'Events') && ~isempty(DataMat.Events)
            sFile.events = DataMat.Events;
        end
        sFile.header.F    = DataMat.F;
        sFile.channelmat  = ChannelMat;
        sFile.channelflag = DataMat.ChannelFlag;
        
    otherwise
        error('Unknown file format');
end

if isempty(sFile)
    bst_error(['Cannot open data file: ', 10, DataFile], 'Import MEG/EEG recordings', 0);
end

% ===== EVENTS =====
if isfield(sFile, 'events') && ~isempty(sFile.events)
    % === SORT BY NAME ===
    % Remove the common components
    [tmp__, evtLabels] = str_common_path({sFile.events.label});
    % Try to convert all the names to numbers
    evtNumber = cellfun(@str2num, evtLabels, 'UniformOutput', 0);
    % If all the events names are numbers: sort numerically
    if ~any(cellfun(@isempty, evtNumber))
        [tmp__, iSort] = sort([evtNumber{:}]);
        sFile.events = sFile.events(iSort);
    % Else: sort alphabetically by names
    else
        % [tmp__, iSort] = sort(evtLabels);
        % sFile.events = sFile.events(iSort);
    end
   
    % === ADD COLOR ===
    if isempty(sFile.events(1).color)
        ColorTable = panel_record('GetEventColorTable');
        for i = 1:length(sFile.events)
            iColor = mod(i-1, length(ColorTable)) + 1;
            sFile.events(i).color = ColorTable(iColor,:);
        end
    end
end





