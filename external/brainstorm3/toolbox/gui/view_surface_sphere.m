function [hFig, iDS, iFig] = view_surface_sphere(SurfaceFile)
% VIEW_SURFACE_SPHERE: Display the registration sphere for a surface.
%
% USAGE:  [hFig, iDS, iFig] = view_surface(SurfaceFile)
%         [hFig, iDS, iFig] = view_surface(ResultsFile)

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
% Authors: Francois Tadel, 2013

% Initialize returned variables
global GlobalData;
hFig = [];
iDS  = [];
iFig = [];

% ===== LOAD DATA =====
% Display progress bar
isProgress = ~bst_progress('isVisible');
if isProgress
    bst_progress('start', 'View surface', 'Loading surface file...');
end
% Get file type
fileType = file_gettype(SurfaceFile);
% If it is a results file
if ismember(fileType, {'results','link'})
    ResultsFile = SurfaceFile;
    ResultsMat = in_bst_results(ResultsFile, 0, 'SurfaceFile');
    SurfaceFile = ResultsMat.SurfaceFile;
else
    ResultsFile = [];
end

% ===== LOAD SPHERE =====
% Load sphere vertices
TessMat = in_tess_bst(SurfaceFile);
if ~isfield(TessMat, 'Reg') || ~isfield(TessMat.Reg, 'Sphere')  || ~isfield(TessMat.Reg.Sphere, 'Vertices') || isempty(TessMat.Reg.Sphere.Vertices)
    bst_error('There is no registered sphere available for this surface.', 'View registered sphere', 0);
    return;
end
sphVertices = double(TessMat.Reg.Sphere.Vertices);

% Get subject MRI file
sSubject = bst_get('SurfaceFile', SurfaceFile);
sMri = in_mri_bst(sSubject.Anatomy(1).FileName);
% FreeSurfer RAS coord => MRI => millimeters
mriSize = size(sMri.Cube) / 2;
sphVertices = bst_bsxfun(@plus, sphVertices, mriSize / 1000);
sphVertices = bst_bsxfun(@times, sphVertices, sMri.Voxsize);
% Convert to SCS
sphVertices = cs_mri2scs(sMri, sphVertices' .* 1000)' ./ 1000;

% Detect the two hemispheres
[ir, il, isConnected] = tess_hemisplit(TessMat);
% If there is a Structures atlas with left and right hemispheres: split in two spheres
if ~isempty(ir) && ~isempty(il) && ~isConnected
    sphVertices(il,2) = sphVertices(il,2) + 0.12;
    sphVertices(ir,2) = sphVertices(ir,2) - 0.12;
end

% ===== DISPLAY SPHERE =====
% Display sphere
if isempty(ResultsFile)
    TessMat.Vertices = sphVertices;
    [hFig, iDS, iFig] = view_surface_matrix(TessMat);
    iSurf = 1;
% Display sphere + results
else
    % Open cortex with results
    [hFig, iDS, iFig] = view_surface_data(SurfaceFile, ResultsFile, [], 'NewFigure');
    % Get display structure
    TessInfo = getappdata(hFig, 'Surface');
    % Replace the vertices in the patch
    set(TessInfo.hPatch, 'Vertices', sphVertices);
    % Replace the vertice in the loaded structure
    [sSurf, iSurf] = bst_memory('GetSurface', SurfaceFile);
    % Copy the existing loaded surface
    iSurfNew = length(GlobalData.Surface) + 1;
    GlobalData.Surface(iSurfNew) = GlobalData.Surface(iSurf);
    % Replace the vertice in the loaded structure
    GlobalData.Surface(iSurfNew).Vertices = sphVertices;
    % Change the filename so that it does not overlap with the display of the regular brain
    GlobalData.Surface(iSurfNew).FileName = [GlobalData.Surface(iSurf).FileName, '|spheres'];
    % Edit the filename in the TessInfo structure
    TessInfo.SurfaceFile = GlobalData.Surface(iSurfNew).FileName;
    setappdata(hFig, 'Surface', TessInfo);
    % Remove the subject information from the dataset so it doesn't get selected by any other viewing function
    GlobalData.DataSet(iDS).SubjectFile = [];
    GlobalData.DataSet(iDS).StudyFile   = [];
    GlobalData.DataSet(iDS).DataFile    = [];
    GlobalData.DataSet(iDS).ChannelFile = [];
end

% ===== CONFIGURE FIGURE =====
% Set transparency
panel_surface('SetSurfaceTransparency', hFig, iSurf, 0);
% Force sulci display
panel_surface('SetSurfaceSmooth', hFig, iSurf, 0);
panel_surface('SetShowSulci', hFig, iSurf, 1);
% Set figure as current figure
bst_figures('SetCurrentFigure', hFig, '3D');

% Camera basic orientation
figure_3d('SetStandardView', hFig, 'top');
% Make sure to update the Headlight
camlight(findobj(hFig, 'Tag', 'FrontLight'), 'headlight');

% Show figure
set(hFig, 'Visible', 'on');
if isProgress
    bst_progress('stop');
end



