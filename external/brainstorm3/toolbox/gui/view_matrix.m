function hFig = view_matrix( MatFile, DisplayMode )
% VIEW_MATRIX: Display a matrix file in a new figure.

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
% Authors: Francois Tadel, 2010

% Read matrix file
sMat = in_bst(MatFile);
% Select display mode
if (nargin < 2) || isempty(DisplayMode)
    DisplayMode = 'timeseries';
end
if strcmpi(DisplayMode, 'timeseries') && isempty(sMat.Time)
    DisplayMode = 'table';
end

% Switch display mode
switch lower(DisplayMode)
    case 'timeseries'
        if iscell(sMat.Value)
            AxesLabels = sMat.Description;
            LinesLabels = [];
        else
            AxesLabels = sMat.Comment;
            LinesLabels = sMat.Description;
        end
        [hFig, iDS, iFig] = view_timeseries_matrix(MatFile, sMat.Value, [], AxesLabels, LinesLabels);
    case 'image'
        hFig = figure();
        imagesc(sMat.Value);
        colorbar();
    case 'table'
        ViewTable(sMat.Value, sMat.Description, MatFile);
    otherwise
        error('Unknown display mode.');
end
end


%% ===== VIEW TABLE =====
function ViewTable(Data, rowTitle, wndTitle)
    import java.awt.*;
    import javax.swing.*;
    import javax.swing.table.*;
    import org.brainstorm.icon.*;
    % Create figure
    jFrame = java_create('javax.swing.JFrame', 'Ljava.lang.String;', wndTitle);
    % Set icon
    jFrame.setIconImage(IconLoader.ICON_APP.getImage());
    
    % Create table
    model = DefaultTableModel(size(Data,1), size(Data,2)+1);
    for i = 1:size(Data,1)
        row = cell(1, size(Data,2)+1);
        row{1} = rowTitle{i};
        for j = 1:size(Data,2)
            row{j+1} = Data(i,j);
        end
        model.insertRow(i-1, row);
    end
    
    jTable = JTable(model);
    
    % Create scroll panel
    jScroll = JScrollPane(jTable);
    jScroll.setBorder([]);
    jFrame.getContentPane.add(jScroll, BorderLayout.CENTER);
    
    jFrame.pack();
    jFrame.show();
end   



