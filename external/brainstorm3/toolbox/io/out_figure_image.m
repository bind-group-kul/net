function varargout = out_figure_image( hFig, imgFile, imgLegend)
% OUT_FIGURE_IMAGE: Save window contents as a bitmap image.
%
% USAGE: img = out_figure_image(hFig)           : Extract figure image and return it
%              out_figure_image(hFig, imgFile)  : Extract figure image and save it to imgFile
%              out_figure_image(hFig, 'Viewer') : Extract figure image and open it with the image viewer
%              out_figure_image(hFig)           : Extract figure image and save it to a user selected file
%              out_figure_image(hFig, ..., imgLegend)
%              out_figure_image(hFig, ..., 'time')

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
% Authors: Francois Tadel, 2008-2010

global GlobalData;
drawnow;

% No legend: plot the time 
if (nargin < 3)
    imgLegend = 'time';
elseif isempty(imgLegend)
    imgLegend = '';
end

% If image filename is not specified
if (nargin <= 1) && (nargout == 0)
    % === Build a default filename ===
    % Get default directories and format
    LastUsedDirs = bst_get('LastUsedDirs');
    DefaultFormats = bst_get('DefaultFormats');
    if isempty(DefaultFormats.ImageOut)
        DefaultFormats.ImageOut = 'tif';
    end
    % Get the default filename (from the window title)
    wndTitle = get(hFig, 'Name');
    if isempty(wndTitle)
        imgDefautFile = 'img_default';
    else
        imgDefautFile = [file_standardize(wndTitle)];
        imgDefautFile = strrep(imgDefautFile, '__', '_');
    end
    % Add extension
    imgDefautFile = [imgDefautFile, '.', lower(DefaultFormats.ImageOut)];
    
    % === Ask user filename ===
    % Ask confirmation for the figure filename
    imgDefaultFile = bst_fullfile(LastUsedDirs.ExportImage, imgDefautFile);
    [imgFile, FileFormat] = java_getfile('save', 'Save image as...', imgDefaultFile, 'single', 'files', ...
        {{'.tif'}, 'TIFF image, compressed (*.tif)',      'TIF'; ...
         {'.jpg'}, 'JPEG image (*.jpg)',                  'JPG'; ...
         {'.bmp'}, 'Bitmap file (*.bmp)',                 'BMP'; ...
         {'.png'}, 'Portable Network Graphics (*.png)',   'PNG'; ...
         {'.hdf'}, 'Hierarchical Data Format (*.hdf)',    'HDF'; ...
         {'.pbm'}, 'Portable bitmap (*.pbm)',             'PBM'; ...
         {'.pgm'}, 'Portable Graymap (*.pgm)',            'PGM'; ...
         {'.ppm'}, 'Portable Pixmap (*.ppm)',             'PPM'}, DefaultFormats.ImageOut);
    if isempty(imgFile)
        return
    end
    % Save new default export path
    LastUsedDirs.ExportImage = bst_fileparts(imgFile);
    bst_set('LastUsedDirs', LastUsedDirs);
    % Save default export format
    DefaultFormats.ImageOut = FileFormat;
    bst_set('DefaultFormats',  DefaultFormats);
end

% Get figure Type
[hFig_,iFig,iDS] = bst_figures('GetFigure', hFig);
FigureId = GlobalData.DataSet(iDS).Figure(iFig).Id;
% If figure is a registered data figure
if ~isempty(iDS) && ~isempty(imgLegend)
    % If 3DAxes => Add a time legend
    if strcmpi(imgLegend, 'time') 
        isAddTime = strcmpi(FigureId.Type, '3DViz') || strcmpi(FigureId.Type, 'Topography');
        if isAddTime && ~isempty(GlobalData.UserTimeWindow.CurrentTime)
            if (GlobalData.UserTimeWindow.CurrentTime > 2)
                imgLegend = sprintf('%4.3fs ', GlobalData.UserTimeWindow.CurrentTime);
            else
                imgLegend = sprintf('%dms ', round(GlobalData.UserTimeWindow.CurrentTime * 1000));
            end
        else
            imgLegend = '';
        end
    end
    % Create legend
    if ~isempty(imgLegend)
        hLabel = uicontrol('Style',               'text', ...
                           'String',              imgLegend, ...
                           'Units',               'Pixels', ...
                           'Position',            [6, 0, 16 * length(imgLegend), 30], ...
                           'HorizontalAlignment', 'left', ...
                           'FontUnits',           'points', ...
                           'FontWeight',          'bold', ...
                           'FontSize',            15, ...
                           'ForegroundColor',     [.3 1 .3], ...
                           'BackgroundColor',     [0 0 0], ...
                           'Parent', hFig);
    end
else
    imgLegend = '';
end
% For time series figures: hide buttons
if ismember(FigureId.Type, {'DataTimeSeries', 'ResultsTimeSeries'})
    % Find existing buttons
    hButtons = findobj(hFig, 'Type', 'hgjavacomponent');
    isVisible = get(hButtons, 'Visible');
    % Hide them
    set(hButtons, 'Visible', 'off');
else
    hButtons = [];
end
% Focus on figure (captures the contents the topmost figure)
pause(.01);
drawnow;
figure(hFig);
drawnow;
% Get figure bitmap
%frameGfx = getframe(hFig);
frameGfx = getscreen(hFig);

% Save image file or return it in argument
if (nargout == 0) && ~isempty(imgFile)
    if strcmpi(imgFile, 'Viewer')
        view_image(frameGfx.cdata);
    else
        out_image(imgFile, frameGfx.cdata);
    end
else
    varargout{1} = frameGfx.cdata;
end

% Delete created label
if ~isempty(imgLegend)
    delete(hLabel);
end
% Show the buttons again
if ~isempty(hButtons)
    for i = 1:length(hButtons)
        set(hButtons(i), 'Visible', isVisible{i});
    end
end







