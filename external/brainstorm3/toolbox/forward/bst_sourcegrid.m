function GridLoc = bst_sourcegrid(Options, CortexFile, sCortex, sEnvelope)
% BST_SOURCEGRID: 3D adaptative gridding of the volume inside a cortex envelope.
%
% USAGE:  GridLoc = bst_sourcegrid(Options, CortexFile)
%         GridLoc = bst_sourcegrid(Options, CortexFile, sCortex, sEnvelope)
% 
% INPUTS: 
%    - Options    : Options structure
%    - CortexFile : Full path to a cortex tesselation file
%    - sCortex    : Cortex surface structure (Vertices/Faces)
%    - sEnvelope  : Convex envelope to use as the outermost layer of the grid
%
% OUTPUTS:
%    - GridLoc    : [Nx3] double matrix representing the volume grid.

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
% Authors: Francois Tadel, 2010-2011

%% ===== PARSE INPUTS =====
if (nargin == 2) && ischar(sCortex)
    % Create an envelope of the cortex surface
    [sEnvelope, sCortex] = tess_envelope(CortexFile, 'convhull', Options.nVerticesInit, .001, []);
    if isempty(sEnvelope)
        return;
    end
end
if (nargin < 1) || isempty(Options)
    Options.nLayers       = 17;
    Options.Reduction     = 3;
    Options.nVerticesInit = 4000;
end

% ===== PARAMETERS =====
% Build scales for each layer
scaleLayers = linspace(1, 0, Options.nLayers+1);
scaleLayers = scaleLayers(1:end-1);
% Build factor of reducepatch for each layer
reduceLayers = linspace(1, 0, Options.nLayers+1);
reduceLayers = reduceLayers(1:end-1) .^ Options.Reduction;

% ===== SAMPLE VOLUME =====
% Sample volume
GridLoc = SampleVolume(sEnvelope.Vertices, sEnvelope.Faces, scaleLayers, reduceLayers);

% ===== REMOVE NON-BRAIN POINTS =====
% iOutside = find(~inpolyhd(GridLoc, sCortex.Vertices, sCortex.Faces));
% Get brainmask
[brainmask, sMri] = bst_memory('GetSurfaceMask', CortexFile);
% Transform coordinates: SCS->MRI
GridLocMri = cs_scs2mri(sMri, GridLoc'*1000);
% Transform coordinates: MRI(MM)->MRI(Voxels)
GridLocMri = round(GridLocMri ./ repmat(sMri.Voxsize', 1, length(GridLocMri)));
% Convert in indices
ind = sub2ind(size(brainmask), GridLocMri(1,:), GridLocMri(2,:), GridLocMri(3,:));
% What is outside ?
iOutside = (brainmask(ind) == 0);

% Show removed points
% if ~isempty(iOutside)
%     % Show surface + removed points
%     view_surface_matrix(sCortex.Vertices, sCortex.Faces, .4, [.6 .6 .6]);
%     line(GridLoc(iOutside,1), GridLoc(iOutside,2), GridLoc(iOutside,3), 'LineStyle', 'none', ...
%                 'MarkerFaceColor', [1 0 0], 'MarkerEdgeColor', [1 1 1], 'MarkerSize', 6, 'Marker', 'o');
%     % Show surface + grid points
%     view_surface_matrix(sCortex.Vertices, sCortex.Faces, .3, [.6 .6 .6]);
%     line(GridLoc(~iOutside,1), GridLoc(~iOutside,2), GridLoc(~iOutside,3), 'LineStyle', 'none', ...
%                 'MarkerFaceColor', [0 1 0], 'MarkerSize', 2, 'Marker', 'o');
% end
% Remove those points
GridLoc(iOutside,:) = [];

end


%% ===== SAMPLE VOLUME =====
function GridLoc = SampleVolume(Vertices, Faces, scaleLayers, reduceLayers)
    % Check matrices orientation
    if (size(Vertices, 2) ~= 3) || (size(Faces, 2) ~= 3)
        error('Faces and Vertices must have 3 columns (X,Y,Z).');
    end
    GridLoc = [];
    hFig = [];

    % Get center of the best fitting sphere
    center = bst_bfs(Vertices)';
    % Center vertices on it
    Vertices = bst_bsxfun(@minus, Vertices, center);

    % Loop on each layer
    for i = 1:length(scaleLayers)
        LayerVertices = Vertices;
        LayerFaces = Faces;
        % Scale layer
        LayerVertices = scaleLayers(i) * LayerVertices;
        % Downsample layer
        if (reduceLayers(i) > 0) && (reduceLayers(i) < 1)
            [LayerFaces, LayerVertices] = reducepatch(LayerFaces, LayerVertices, reduceLayers(i));
            % Nothing left: return
            if isempty(LayerFaces)
                break;
            end
        end
        % Add layer to the list of grid points
        GridLoc = [GridLoc; LayerVertices];
        % Plot layer
%         if DEBUG
%             [hFig, iDS, iFig, hPatch] = view_surface_matrix(LayerVertices, LayerFaces, 1, [1 0 0], hFig);
%             %set(hPatch, 'EdgeColor', [1 0 0]);
%             set(hPatch, 'EdgeColor', 'none', 'MarkerFaceColor', [0,1,0], 'MarkerEdgeColor', [0,1,0], 'Marker', 'o', 'MarkerSize', 7);
%         end
    end
    % Go back to intial coordinates system
    GridLoc = bst_bsxfun(@plus, GridLoc, center);
    % Remove duplicate points
    GridLoc = unique(GridLoc, 'rows');
end



