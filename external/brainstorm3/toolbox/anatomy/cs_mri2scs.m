function [outputVar1, outputVar2] = cs_mri2scs(MRI, mriCoord)
% CS_MRI2SCS: Compute the transform to move from the MRI coordinate system (in mm) to the SCS
%
% USAGE:            [transfSCS] = cs_mri2scs(MRI);
%         [scsCoord, transfSCS] = cs_mri2scs(MRI, mriCoord);
%
% INPUT:
%     - MRI:       A proper Brainstorm MRI structure (i.e. from any subjectimage file, 
%                  with fiducial points and SCS system properly defined)
%     - mriCoord:  A 3xN matrix of point coordinates in the MRI system (in mm)
%     - transfSCS: A structure specifying the transform that is applied to the MRI mm coordinates
%                  Definition of the transform is the following:
%                  Xscs = transfSCS.R Xmri + transfSCS.T ; (Xmri in mm)
%                  transfSCS.Origin is the location of the SCS origin in MRI coordinates
%     - scsCoord:  A 3xN matrix of corresponding point coordinates in the SCS system (in mm)
%
% NOTES:
%   - CTF/NEUROMAG coord systems : NAS, LPA, RPA

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
% Authors: Sylvain Baillet, Alexei Ossadtchi, 2004
%          Francois Tadel, 2008-2010

% ===== Parse inputs =====
outputVar1 = [];
outputVar2 = [];
% Subject coordinate system is not defined yet for this MRI
if ~isfield(MRI,'SCS')
    return
end
% Check points array dimensions
if (nargin == 2)
    if (size(mriCoord, 1) ~= 3)
        error('mriCoord must have 3 rows (X,Y,Z).');
    end
else
    mriCoord = [];
end


% ===== COMPUTE TRANSFORMATION =====
% If it is needed to compute the transformation
if (nargin == 1) || ~isfield(MRI.SCS, 'R') || isempty(MRI.SCS.R) || ~isfield(MRI.SCS, 'T') || isempty(MRI.SCS.T)
    % Move to SCS:
    % Xscs = R Xmri + T ; Xmri in mm

    % Fiducial coordinates in mm
    % NAS
    if isequal(size(MRI.SCS.NAS), [1 3])
        NAS = MRI.SCS.NAS';
    elseif isequal(size(MRI.SCS.NAS), [3 1])
        NAS = MRI.SCS.NAS;
    else
        return
    end
    % LPA
    if isequal(size(MRI.SCS.LPA), [1 3])
        LPA = MRI.SCS.LPA';
    elseif isequal(size(MRI.SCS.LPA), [3 1])
        LPA = MRI.SCS.LPA;
    else
        return
    end
    % RPA
    if isequal(size(MRI.SCS.RPA), [1 3])
        RPA = MRI.SCS.RPA';
    elseif isequal(size(MRI.SCS.RPA), [3 1])
        RPA = MRI.SCS.RPA;
    else
        return
    end

    % GET CTF TRANSFORM
    transfSCS = cs_fid2scs(NAS, LPA, RPA);
    if isempty(transfSCS)
        return
    end

    % Return origin, in the same format than input
    if isequal(size(MRI.SCS.NAS), [1 3])
        transfSCS.Origin = transfSCS.Origin';
    end
    
% Else: transformation is already known
else 
    transfSCS.R = MRI.SCS.R;
    transfSCS.T = MRI.SCS.T;
end
    
   
% ===== RETURNED VALUES ======
% Compute transformation
if (nargin == 1)
    outputVar1 = transfSCS;
% Transform some points
elseif (nargin == 2)
    % Compact form of RX+T
    outputVar1 = [transfSCS.R, transfSCS.T] * [mriCoord;ones(1,size(mriCoord,2))];
    outputVar2 = transfSCS;
end
    
    