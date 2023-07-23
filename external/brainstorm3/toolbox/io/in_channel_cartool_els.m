function ChannelMat = in_channel_cartool_els(ChannelFile)
% IN_CHANNEL_ELS: Reads a .els file : cartesian coordinates of a set of electrodes, divided in various clusters
% 
% USAGE:  ChannelMat = in_channel_els(ChannelFile)
%
% INPUT: 
%    - ChannelFile : name of file to open, WITH .ELS EXTENSION
% OUTPUT:
%    - ChannelMat  : Brainstorm channel structure
%
% FORMAT: (.ELS)
%     ASCII file :
%     Format : "ES01<RETURN>"
%              "<nb_electrodes> <RETURN>"
%              "<nb_clusters> <RETURN>"
%              Repeat for each cluster :
%                  "<Cluster_name> <RETURN>"
%                  "<Cluster_number_of_electrodes> <RETURN>"
%                  "<Cluster_type> <RETURN>"
%              End of repeat
%              Repeat for each electrode :
%                  "<X1> <Y1> <Z1> ?<electrode_label>? ?<optional_flag>?<RETURN>"
%              End.
%     Notes :
%     - Cluster_type : could be seen as the dimensionality of the cluster :
%           - 0 for separated electrodes (like auxiliaries), or "points"
%           - 1 for a strip of electrodes, or "line"
%           - 2 for a grid of electrodes, or "array"
%           - 3 for a 3D set of electrodes, usually on the scalp
%     - optional_flag : ignored in this program

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
% Authors: Francois Tadel, 2006


%% Internal callback functions
function buttonOk_Callback(hObject, eventdata, handles)
    electrodes = allElectrodes;
    labels = allLabels;
    % Keep only electrodes that are in one of the selected clusters
    index = 1;
    for i=1:Nclust
        if (get(hCheckbox(i), 'Value') == 0)
            n = cell2mat(clusters(i,2));
            electrodes(index:index+n-1,:) = [];
            labels(index:index+n-1) = [];
        else
            index = index + cell2mat(clusters(i,2));
        end
    end
    % Report results
    close(hFig);
    electrodes = allElectrodes;
    labels = allLabels;
end

%% Output variables initialization
electrodes = double([]);
labels = {};

%% Open file for reading only
[fid, message] = fopen(ChannelFile, 'r');
if fid == -1
    disp(sprintf('ioReadEls : %s', message));
    return;
end

%% Read file header
% Magic number
readData = textscan(fid, '%s', 1);
readData = readData{1};
if ~strcmp(readData, 'ES01')
    disp('ioReadEls : corrupted .els file'); return;
end
% Number of electrodes and number of clusters
Ne = textscan(fid, '%d', 1);
Ne = Ne{1};
Nclust = textscan(fid, '%d', 1);
Nclust = Nclust{1};
% Clusters
clusters = cell(Nclust, 3);
for i=1:Nclust
    fgetl(fid);
    clusters(i,1) = {fgetl(fid)};
    readData = textscan(fid, '%d', 1);
    clusters(i,2) = readData;
    readData = textscan(fid, '%d', 1);
    clusters(i,3) = readData;
end

%% Reading electrodes coordinates
%    - electrodes : the [Ne,3] matrix read from the ELS file (empty if error)
%                   'Ne' represents the number of electrodes defined in this file.
%                   WARNING : the division in clusters is not kept in the
%                   output, because it is not useful in the smac algorithms
%                   The program will just ask the user which clusters he
%                   wants to use.
%    - labels : [Ne,1] cell array containing the label associated to each electrode
readData = textscan(fid, '%n %n %n %s');
% Close the file
fclose(fid);
% Get the list of the electrodes labels
allLabels = readData(:,4);
allLabels = allLabels{1};
% Convert the cell array to a simple array
allElectrodes = cell2mat(readData(:,1:3));
% Verify the expected number of electrodes
% If too many electrodes were read, only keep the first 'Ne' electrodes
readNe = size(allElectrodes,1);
if (readNe < Ne)
    disp(['ioReadXyz : Warning reading file ' ChannelFile ' : incorrect number of electrodes in file']);
elseif (readNe > Ne)
    allElectrodes(Ne+1:readNe, :) = [];
    allLabels(Ne+1:readNe, :) = [];
end

%% Process clusters (delete or keep clusters)
% If there are more than one cluster, ask the user what are the clusters
% that the user wants to keep.
if (Nclust>1)
    % Figure definition
    figureHeight = 85 + 17*i;
    hFig = figure('Units','pixels', 'MenuBar','none','NumberTitle','off','Color',get(0,'defaultUicontrolBackgroundColor'),...
                  'PaperPosition',get(0,'defaultfigurePaperPosition'),'Resize','off','HandleVisibility','callback',...
                  'Name','Import ELS file', 'Tag','figureImportEls');
    autoPos = get(hFig, 'Position');
    set(hFig, 'Position',[autoPos(1:2) 271 figureHeight]);
    % Title : list of solutions
    uicontrol('Parent',hFig, 'Units','pixels','HorizontalAlignment','left',...
                  'Position',[22 (figureHeight-30) 139 17],...
                  'String','Select clusters to import :','Style','text','Tag','textTitleSelectIS');
    % List of checkboxes (one per cluster)
    hCheckbox = zeros(Nclust,1);
    for i=1:Nclust
        hCheckbox(i) = uicontrol('Parent',hFig,'Units','pixels','Style','checkbox','Value',1,'Tag',sprintf('checkbox%d', i),...
                  'Position',[33 (figureHeight-35-17*i) 228 17],'String', clusters(i,1));
    end
    % Button OK
    hButtonOk = uicontrol('Parent',hFig, 'Callback',@buttonOk_Callback,'Position',[103 15 65 24],...
                          'String','OK','Tag','buttonOk');
    % Wait for the user to close the window
    waitfor(hFig);
    drawnow;
else
    electrodes = allElectrodes;
    labels = allLabels;
end


%% ===== CONVERT IN BRAINSTORM FORMAT =====
ChannelMat = db_template('channelmat');
ChannelMat.Comment = 'Cartool ELS';
for iChan = 1:size(electrodes,1)
    ChannelMat.Channel(iChan).Loc     = electrodes(iChan,:)';
    ChannelMat.Channel(iChan).Orient  = [];
    ChannelMat.Channel(iChan).Comment = '';
    ChannelMat.Channel(iChan).Weight  = 1;
    ChannelMat.Channel(iChan).Type    = 'EEG';
    ChannelMat.Channel(iChan).Name    = labels{iChan};
end


end