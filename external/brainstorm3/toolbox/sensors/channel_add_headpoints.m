function HeadPoints = channel_add_headpoints(ChannelFile, HeadPointsFile, FileFormat)
% CHANNEL_ADD_HEADPOINTS: Add head points to a ChannelFile (from any text file)
% 
% USAGE:  channel_add_headpoints( ChannelFile, HeadPointsFile=[ask], FileFormat ) : Includes the points from a defined file
%         channel_add_headpoints( ChannelFile, 'IncludeEeg' )   : Use the EEG sensors as extra head points
%         channel_add_headpoints( ChannelFile, 'IncludeFid' )   : Use the fiducials as extra head points (nasion, ears, etc.)
%         channel_add_headpoints( ChannelFile )                 : Ask user to select HeadPointsFile

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

%% ===== READ HEAD POINTS FILE =====
isIncludeEeg = 0;
isIncludeFid = 0;
HeadPoints = [];
if (nargin == 2) && strcmpi(HeadPointsFile, 'IncludeEeg')
    FileMat = import_channel([], ChannelFile, 'BST');
    HeadPointsFile = ChannelFile;
    isIncludeEeg = 1;
elseif (nargin == 2) && strcmpi(HeadPointsFile, 'IncludeFid')
    FileMat = import_channel([], ChannelFile, 'BST');
    HeadPointsFile = ChannelFile;
    isIncludeFid = 1;
elseif (nargin < 3) || isempty(HeadPointsFile) || isempty(FileFormat)
    [FileMat, HeadPointsFile, FileFormat] = import_channel();
else
    FileMat = import_channel([], HeadPointsFile, FileFormat);
end
if isempty(FileMat)
    return
end

%% ===== GET HEAD POINTS =====
% Add the EEG sensors from the same file to the list of HeadPoints
if isIncludeEeg
    iEEG = good_channel(FileMat.Channel, [], 'EEG');
    HeadPoints.Loc   = [FileMat.Channel(iEEG).Loc];
    HeadPoints.Label = {FileMat.Channel(iEEG).Name};
    HeadPoints.Type  = repmat({'EXTRA'}, [1,length(HeadPoints.Label)]);
% Add the fiducials from the same file to the list of HeadPoints
elseif isIncludeFid
    if ~isfield(FileMat, 'SCS') || ~isfield(FileMat.SCS, 'NAS') || isempty(FileMat.SCS.NAS) || isempty(FileMat.SCS.LPA) || isempty(FileMat.SCS.RPA)
        warning('No fiducials defined in this file.');
    else
        HeadPoints.Loc   = [FileMat.SCS.NAS, FileMat.SCS.LPA, FileMat.SCS.RPA];
        HeadPoints.Label = {'NAS', 'LPA', 'RPA'};
        HeadPoints.Type  = {'EXTRA', 'EXTRA', 'EXTRA'};
    end
% Use all the Headpoints and sensors available in the new file
else
    % If head points already defined in structure: use them
    if isfield(FileMat, 'HeadPoints') && ~isempty(FileMat.HeadPoints) && ~isempty(FileMat.HeadPoints.Loc)
        HeadPoints = FileMat.HeadPoints;
    else
        HeadPoints.Loc   = [];
        HeadPoints.Label = {};
        HeadPoints.Type  = {};
    end
    % Add EEG sensors
    iEeg = good_channel(FileMat.Channel, [], 'EEG');
    if ~isempty(iEeg)
        HeadPoints.Loc   = cat(2, HeadPoints.Loc,   FileMat.Channel(iEeg).Loc);
        HeadPoints.Label = cat(2, HeadPoints.Label, {FileMat.Channel(iEeg).Name});
        HeadPoints.Type  = cat(2, HeadPoints.Type,  repmat({'EXTRA'}, [1,length(iEeg)]));
    end
    % If no head points defined
    if isempty(HeadPoints) || isempty(HeadPoints.Loc)
        % Display warning: no head points
        java_dialog('warning', 'No head points found in file.', 'Add head points');
    end
end


%% ===== ADD TO CHANNEL FILE =====
% Load channel file
if ~isIncludeEeg
    ChannelMat = in_bst_channel(ChannelFile);
else
    ChannelMat = FileMat;
end
% Add new head points
strDupli = '';
nDupliPoints = 0;
if isfield(ChannelMat, 'HeadPoints') && ~isempty(ChannelMat.HeadPoints) 
    % For each new head point
    for i = 1:length(HeadPoints.Label)
        % Check if head point is not already existing
        if isempty(ChannelMat.HeadPoints.Loc) 
            ChannelMat.HeadPoints.Loc   = HeadPoints.Loc(:,i);
            ChannelMat.HeadPoints.Label = HeadPoints.Label(i);
            ChannelMat.HeadPoints.Type  = HeadPoints.Type(i);
        elseif ~any((abs(ChannelMat.HeadPoints.Loc(1,:) - HeadPoints.Loc(1,i)) < 1e-6) & ...
                    (abs(ChannelMat.HeadPoints.Loc(2,:) - HeadPoints.Loc(2,i)) < 1e-6) & ...
                    (abs(ChannelMat.HeadPoints.Loc(3,:) - HeadPoints.Loc(3,i)) < 1e-6))
            ChannelMat.HeadPoints.Loc   = [ChannelMat.HeadPoints.Loc,   HeadPoints.Loc(:,i)];
            ChannelMat.HeadPoints.Label = [ChannelMat.HeadPoints.Label, HeadPoints.Label{i}];
            ChannelMat.HeadPoints.Type  = [ChannelMat.HeadPoints.Type,  HeadPoints.Type{i}];
        else
            nDupliPoints = nDupliPoints + 1;
        end
    end
    if (nDupliPoints > 0)
        strDupli = sprintf('%d duplicated points (ignored).\n\n', nDupliPoints);
    end
else
    ChannelMat.HeadPoints = HeadPoints;
end

% History: Added head points
nNewPoints = length(HeadPoints.Label) - nDupliPoints;
ChannelMat = bst_history('add', ChannelMat, 'headpoints', sprintf('Added %d head points from file "%s"', nNewPoints, HeadPointsFile));
% Save modified file
bst_save(ChannelFile, ChannelMat, 'v7');
% Update raw links
panel_channel_editor('UpdateRawLinks', ChannelFile, ChannelMat);

% Message: head points added
if bst_get('isGUI')
    java_dialog('warning', sprintf('%d new head points added.\n%sTotal: %d points.', ...
        nNewPoints, strDupli, length(ChannelMat.HeadPoints.Label)), ...
        'Add head points');
end


