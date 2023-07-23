function [PChanLocs, X, Y, Z] = channel_spherize(sensloc, bfs_center, bfs_radius)
% CHANNEL_SPHERIZE: Parametrize sensors on a sphere on a sphere.
%
% USAGE:  [PChanLocs, X, Y, Z] = channel_spherize(sensloc, bfs_center, bfs_radius) % Specify the sphere
%         [PChanLocs, X, Y, Z] = channel_spherize(sensloc);                        % Let sphere be computed automatically
%
% INPUT:
%    - sensloc   : a Nx3 matrix containing the sensors locations
%    - bfs_center: (x,y,z) Center or the sphere
%    - bfs_radius: radius of the sphere
%
% OUTPUT:
%    - PChanlocs : Array of channel locations projected on best-fitting sphere
%    - X, Y, Z   : coordinates of the object on which the data is rendered

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
% Authors: Sylvain Baillet, 1999
%          Francois Tadel, 2008-2012

%% ===== CHECK INPUTS =====
if size(sensloc,2) ~= 3
    sensloc = sensloc';
end
% BFS
if (nargin < 3)
    % Compute best-fitting sphere to sensors
    [ bfs_center, bfs_radius ] = bst_bfs( sensloc );
end
% Check that BFS is a row vector
if (size(bfs_center, 1) == 3)
    bfs_center = bfs_center';
end



%% ===== SPHERIZE SENSORS =====
% Center sensors on the center of the BFS
PChanLocs = sensloc - ones(size(sensloc,1),1) * bfs_center;
% Convert into spherical coordinates
[teta,phi,rr] = cart2sph(PChanLocs(:,1), PChanLocs(:,2), PChanLocs(:,3));
% Project sensors on the sphere
[x_sph, y_sph, z_sph] = sph2cart(teta, phi, bfs_radius * ones(size(phi)));
PChanLocs = [x_sph, y_sph, z_sph];
% Get minimum phi value
phimin = min(phi);


%% ===== BUILD SPHERE SURFACE =====
% Load a pre-computed sphere with regular sampling
BstSphere = load('bst_sphere_1000V.mat');
X = BstSphere.Vertices(:,1);
Y = BstSphere.Vertices(:,2);
Z = BstSphere.Vertices(:,3);
% Transform in spherical coordinates
[Theta, Phi, R] = cart2sph(X, Y, Z);
% Find all the points < phimin
iTooLow = find(Phi < phimin);
% Find all the Faces that have only one point too low
iIncompleVert = unique(BstSphere.Faces(sum(ismember(BstSphere.Faces, iTooLow),2) == 3));
% For all the Vertices at the border: fix 
Phi(iIncompleVert) = phimin;
% Remove all the other vertices below phimin
iTooLow = setdiff(iTooLow, iIncompleVert);
Theta(iTooLow) = [];
Phi(iTooLow)   = [];
R(iTooLow)     = [];
% Transform back in cartesian coordinates
[X, Y, Z] = sph2cart(Theta, Phi, R);
% Scale to fit the best fitting sphere
X = X .* bfs_radius;
Y = Y .* bfs_radius;
Z = Z .* bfs_radius;

% ===== OLD VERSION =======================================================
% % Create regular sampling of the surface in spheric coordinates
% % N = 30;
% % phi  = (phimin:(pi/2 - phimin)/N:pi/2)' * ones(1,N+1);
% % teta = (0: 2*pi/N : 2*pi )' * ones(1,N+1);
% N_phi = 20;
% N_theta = 40;
% phi_val  = linspace(0,1,N_phi).^1.6 * (pi/2 - phimin) + phimin;
% teta_val = linspace(-pi-10*eps, pi, N_theta);
% phi_param  = ones(N_theta,1) * phi_val;
% teta_param = teta_val' * ones(1,N_phi);
% 
% % Transform in cartesian coordinates
% X = cos(teta_param) .* cos(phi_param) .* bfs_radius;
% Y = sin(teta_param) .* cos(phi_param) .* bfs_radius;
% Z = sin(phi_param) .* bfs_radius;
% =========================================================================


%% ===== TRANSLATION / CENTER ======
X = X + bfs_center(1); 
Y = Y + bfs_center(2); 
Z = Z + bfs_center(3);
PChanLocs = PChanLocs + ones(size(PChanLocs,1),1) * bfs_center;





