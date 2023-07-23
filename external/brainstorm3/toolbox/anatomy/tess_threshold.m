function [Faces, iFacesRemove] = tess_threshold(Vertices, Faces, threshArea, threshAngle)
% TESS_THRESHOLD: Remove the asymetric triangles (that have a ratio perimeter/area too high)

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

% Parse inputs
if (nargin < 4)
    threshAngle = 150;
end
if (nargin < 3)
    threshArea = 3;
end
iFacesRemoveArea = [];
iFacesRemoveAngle = [];

% Threshold perimeter/area
if ~isempty(threshArea) && (threshArea > 0)
    % Compute perimeter again
    triPerimeter = tess_perimeter(Vertices, Faces);
    % Compute area
    triArea = zeros(length(Faces),1);
    for i = 1:length(Faces)
        A = Vertices(Faces(i,1),:);
        B = Vertices(Faces(i,2),:);
        C = Vertices(Faces(i,3),:);
        triArea(i) = norm(bst_cross(B-A, C-A, 2)) / 2;
    end
    % Ratio perimeter / area
    ratio = (triPerimeter ./ triArea);
    % Detect the Faces that have an area above the threshold
    iFacesRemoveArea = find(ratio - mean(ratio) > threshArea * std(ratio));
    if isempty(iFacesRemoveArea)
        return;
    end
    % Keep only the good faces
    Faces(iFacesRemoveArea,:) = [];
end

% Threshold angle
if ~isempty(threshAngle) && (threshAngle > 0)
    v1 = Vertices(Faces(:,1),:) - Vertices(Faces(:,2),:);
    v2 = Vertices(Faces(:,1),:) - Vertices(Faces(:,3),:);
    v3 = Vertices(Faces(:,2),:) - Vertices(Faces(:,3),:);
    
    maxAngle = zeros(size(Vertices,1),1);
    for i = 1:length(v1)
        maxAngle(i) = max([atan2(norm(cross(v1(i,:),v2(i,:))), dot(v1(i,:),v2(i,:))), ...
                        atan2(norm(cross(v1(i,:),v3(i,:))), dot(v1(i,:),v3(i,:))), ...
                        atan2(norm(cross(v2(i,:),v3(i,:))), dot(v2(i,:),v3(i,:)))]);
    end
    % Convert to degrees
    maxAngle = maxAngle / 2 / pi * 360;
    % Detect the Faces that have an area above the threshold
    iFacesRemoveAngle = find(maxAngle > threshAngle);
    if isempty(iFacesRemoveAngle)
        return;
    end
    % Keep only the good faces
    Faces(iFacesRemoveAngle,:) = [];
end

iFacesRemove = [iFacesRemoveArea(:); iFacesRemoveAngle(:)];

    



