function [DataMat, Markers] = in_data_besa(DataFile)
% IN_DATA_BRAINAMP: Read BrainVision BrainAmp EEG files.
%
% USAGE:  OutputData = in_data_besa( DataFile )
%
% INPUT:
%     - DataFile : Full path to a recordings file.
% OUTPUT: 
%     - DataMat : Brainstorm data (recordings) structure

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

% Get format
[fPath, fBase, fExt] = bst_fileparts(DataFile);
% Initialize returned structure
DataMat = db_template('DataMat');
DataMat.Comment  = fBase;
DataMat.Device   = 'BESA';
DataMat.DataType = 'recordings';
DataMat.nAvg     = 1;

% Open file
fid = fopen(DataFile, 'r');
if (fid == -1)
    error('Cannot open file.');
end

% Switch according to file format
switch lower(fExt)
    case '.avr'
        % Read header (first line)
        hdr = fgetl(fid);
        % Split to get all the parameters
        hdr = str_split(hdr, ' =');
        nTime     = str2num(hdr{2});
        timeStart = str2num(hdr{4}) / 1000;  % Convert to seconds
        timeStep  = str2num(hdr{6}) / 1000;  % Convert to seconds
        % Read the recordings
        DataMat.F = fscanf(fid, '%f', [nTime, Inf])';
        
    case {'.mul', '.mux'}
        % Skip three lines
        hdr = fgetl(fid);
        hdr = fgetl(fid);
        hdr = fgetl(fid);
        % Read the recordings, line by line
        allLines = {};
        while 1
            newLine = fgetl(fid);
            if ~ischar(newLine)
                break;
            end
            allLines{end+1} = str2num(newLine);
        end
        % Concatenate everything
        DataMat.F = cat(1, allLines{:})';
        
        % Ask for time window
        res = java_dialog('input', {'Start time (in miliseconds):', 'Sampling frequency'}, ...
                                    'Time definition (in Hz)', [], {'0','1000'});
        if isempty(res) || (length(str2num(res{1})) ~= 1) || (length(str2num(res{2})) ~= 1)
            DataMat = [];
        else
            timeStart = str2num(res{1}) / 1000;
            timeStep  = 1 / str2num(res{2});
        end
    otherwise
        error(['Unsupported file extension: ' fExt]);
end
% Close file
fclose(fid);

% Rebuild time vector
DataMat.Time = timeStart + (0:size(DataMat.F,2)-1) .* timeStep;
% No bad channels defined in those files: all good
DataMat.ChannelFlag = ones(size(DataMat.F,1), 1);







