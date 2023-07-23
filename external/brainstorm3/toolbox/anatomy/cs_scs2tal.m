function [pts,T,R] = cs_scs2tal(Fid, CortexVert, pts, isDeform)
% CS_SCS2TAL: Converts point locations from SCS (e.g. CTF) to a Normalized Coordinate System (Talairach).
%
% USAGE:  [pts,T,R] = cs_scs2tal(Fid,  CortexVert, pts, isDeform)
%         [pts,T,R] = cs_scs2tal(sMri, CortexVert, pts, isDeform)
%         [pts,T,R] = cs_scs2tal(Fid,  CortexVert, pts)           : isDeform = 1
% 
% INPUT:  
%    - Fid       : A 3x3 matrix containing the SCS coordinates of AC, PC and IH points (in meters)
%                  Each column of the matrix is the [x ;y ;z] triplet of coordinates of these reference points.
%                  First column is AC, second column is PC and third column is IH.
%    - sMri      : Instead of the Fiducials matrix, you can provide the MRI structure from which the fiducials are extracted
%                  Required fields: NCS.AC, NCS.PC, NCS.IH, SCS.NAS, SCS.LPA, SCS.RPA, SCS.R, SCS.T
%    - CortexVert: A 3xN matrix containing the SCS coordinates of the vertices of the tessellation 
%                  of the subject's cortical surface (in meters) - 
%                  **** ONLY USED IF isDeform=0 ****
%    - pts       : A 3xN matrix of points to transform from SCS to NCS (in meters)
%    - isDeform  : If 0, only do a rigid transformation (rotation/translation) to align the cortex in Talairach axes 
%                  If 1, deform the cortex into the Talairach coordinate system
%                        A bounding box is computed about this brain surface for subsequent computation 
%                        of the piecewise affine transforms corresponding to Talairach normalization.
% OUTPUT:
%    - pts  : A 3xN matrix of points in NCS (in meters).
%    - T    : Translation matrix
%    - R    : Rotation matrix  

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
% Authors: Sylvain Baillet, Karim N'Diaye, John C. Mosher, 2005
%          Francois Tadel, 2010

%% ===== PARSE INPUTS =====
% Fiducials: MRI Strcture
if isstruct(Fid)
    sMri = Fid;
    % Coordinates in MRI coords of Normalized fiducials (AC, PC, IH)
    mmFid = [sMri.NCS.AC', sMri.NCS.PC', sMri.NCS.IH'];
    % Conversion in SCS
    Fid = cs_mri2scs(sMri, mmFid);
    % Conversion in millimeters
    Fid = Fid ./ 1000;
elseif ~isequal(size(Fid), [3 3])
    error('Invalid fiducials definition');
end
% Fiducials: [3x3] matrix
AC = Fid(:,1)';
PC = Fid(:,2)';
IH = Fid(:,3)';
% Cortex vertices
if isDeform && ~isempty(CortexVert) && (size(CortexVert,1) ~= 3) 
    error('CortexVert must have 3 rows (X,Y,Z).');
end
% Points to convert
isTransposed = (size(pts,1) ~= 3);
if isTransposed
    pts = pts';
end
% Default: deform cortex to Talairach space
if (nargin < 4) || isempty(isDeform)
    isDeform = 1;
end


%% ===== GET THE RIGID TRANSFORMATION =====
% Definition: Origin is AC and x is antero-posterior axis
% => Translation: AC vector
T = AC';
% AC-PC vector
ACPC = (PC-AC) ./ norm(PC-AC);
% Rotation matrix
mat1 = [    1     1     1 ;
         AC(2) PC(2) IH(2);
         AC(3) PC(3) IH(3)];
mat2 = [ AC(1) PC(1) IH(1);
            1     1     1;
         AC(3) PC(3) IH(3)]; 
mat3 = [ AC(1) PC(1) IH(1);
         AC(2) PC(2) IH(2);
            1     1     1];
V1 = [det(mat1); det(mat2); det(mat3)];
V1 = V1 ./ norm(V1);
V2 = cross(V1,ACPC');
V2 = V2/norm(V2);
R  = [-ACPC' V1 V2]';

% Apply Talairach referential change (translation + rotation)
pts = (R * bst_bsxfun(@minus, pts, T));



%% ===== DEFORMATION => TALAIRACH =====
if isDeform
    % Dimensions of brain bouding box in Talairach space (in meters)
    antac  = 70e-3;
    acpc   = 23e-3;
    postpc = 79e-3;
    infac  = 42e-3;
    supac  = 74e-3;
    aclat  = 68e-3;

    % === BOUNDING BOX ===
    % Use Nx3 coordinates (due to orginal Karim's scripting)
    pts = pts'; 
    % Transform the cortex vertices in Talairach coordinated
    CortexVert = R * bst_bsxfun(@minus, CortexVert, T);
    CortexVert = CortexVert';
    % CP position in TAL 
    cptal = R * (PC - AC)';
    xcp = cptal(1);
    % Bounding box in Talairach coordinated
    xant  = max(CortexVert(:,1));
    xpost = abs(min(CortexVert(:,1) - cptal(1)));
    ymax  = max(abs(CortexVert(:,2)));
    zsup  = max(CortexVert(:,3));
    zinf  = abs(min(CortexVert(:,3)));
    
    % === LINEAR SCALINGS ===
    % 1) Separate brain bouding box in 3 antero-posterior subsections
    %    Compute scaling for each of these along same axis
    xavac = find(pts(:,1)>=0);
    xapac = find( (pts(:,1)< 0));
    xapcp = find(pts(:,1)< xcp);
    % Firsty, we homothetize the part in front of AC, so that it is 70mm long
    pts(xavac,1) = pts(xavac,1) .* antac ./ xant;
    % Secondly we contract everything which is between PC and AC, so that AC-PC matches Talairach's 23mm
    pts(xapac,1) = pts(xapac,1) .*acpc ./ abs(xcp);

    % Then we deform the part behind PC
    pts(xapcp,1) = (pts(xapcp,1) + acpc) .* postpc ./ (xpost .* acpc ./ abs(xcp)) - acpc;

    % 2) Linear scaling along left-right axis
    pts(:,2) = pts(:,2) .* aclat ./ ymax;

    % 3) Linear scaling along vertical axis
    nzsup = find(pts(:,3) > 0);
    pts(nzsup,3) = pts(nzsup,3) .* supac ./ zsup;

    nzinf = find(pts(:,3) <= 0);
    pts(nzinf,3) = pts(nzinf,3) .* infac ./ zinf;

    % 4) Invert systems of axis
    %    En TAL, l'axe X est orthosagittal & vers la droite
    %            l'axe Y orthofrontal (i.e. antero-posterieur) & vers l'avant
    %    En CTF, l'axe X est orthofrontal, vers l'avant
    %            l'axe Y orthosagittal mais vers la GAUCHE
    pts = [-pts(:,2) pts(:,1) pts(:,3)];

    % Restore 3xN matrix
    pts = pts';
end

% Return the transformed points in the way they were given in input
if isTransposed
    pts = pts';
end



