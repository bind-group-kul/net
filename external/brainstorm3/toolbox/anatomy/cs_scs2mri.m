function [mriCoord] = cs_scs2mri(MRI,scsCoord)
% CS_SCS2MRI: Transform SCS point coordinates (in mm) to MRI coordinate system (in mm) 
%
% USAGE:  [mriCoord] = cs_scs2mri(MRI,scsCoord);
%
% INPUT: 
%     - MRI      : A proper Brainstorm MRI structure (i.e. from any subjectimage file, 
%                  with fiducial points and SCS system properly defined)
%     - scsCoord : a 3xN matric of corresponding point coordinates in the SCS system (in mm)
%     - mriCoord : a 3xN matrix of point coordinates in the MRI system (in mm)

% NOTES:
%  Definition of original transform is the following:
%  Xscs = MRI.SCS.R Xmri + MRI.SCS.T ; 
%  (Xmri in mm)
%
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

% Check matrices orientation
if (size(scsCoord, 1) ~= 3)
    error('scsCoord must have 3 rows (X,Y,Z).');
end

if ~isfield(MRI,'SCS') || ~isfield(MRI.SCS,'R') || ~isfield(MRI.SCS,'T') || isempty(MRI.SCS.R) || isempty(MRI.SCS.T)
    mriCoord = [];
    return
end
if isfield(MRI, 'R') && isfield(MRI, 'T')
    MRI.SCS=MRI;
end

mriCoord = MRI.SCS.R \ (scsCoord - repmat(MRI.SCS.T,1,size(scsCoord,2)));
 

