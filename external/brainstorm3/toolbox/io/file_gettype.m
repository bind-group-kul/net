function fileType = file_gettype( fileName )
% FILE_GETTYPE: Idenfity a file type based on its fileName.
%
% USAGE:  fileType = file_gettype( fileName )
%         fileType = file_gettype( sMat )
%
% INPUT:
%     - fileName : Full path to file to identify
%     - sMat     : Structure that should be contained in a file
% OUTPUT:
%     - fileType : Brainstorm type (eg. 'subject', 'data', 'anatomy', ...) 

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
% Authors: Francois Tadel, 2008-2012


%% ===== INPUT: FILE =====
if ischar(fileName)
    % Detect links
    if (length(fileName) > 5) && strcmpi(fileName(1:5),'link|')
        fileType = 'link';
        return;
    end
    % Initialize possible types and formats to empty lists
    fileType = 'unknown';

    % Get the different file parts : path, name, extension
    [filePath, fileName, fileExt] = bst_fileparts(fileName);
    fileName = lower(fileName);
    fileExt  = lower(fileExt);
    % If file has no extension : don't know what to do
    if (isempty(fileExt))
        return;
    end
    % Replace some standard separators with "_"
    fileName = strrep(fileName, '.', '_');
    fileName = strrep(fileName, '-', '_');
    % Add a '_' at the beginning of the fileName, so that the first word of
    % the fileName can be considered a tag (ex: 'brainstormsubject.mat')
    fileName = ['_' fileName];

    % If it is a Matlab .mat file : look for valid tags in fileName
    if (length(fileExt) >= 4) && (isequal(fileExt(1:4), '.mat'))
        if ~isempty(findstr(fileName, '_data'))
            fileType = 'data';
        elseif ~isempty(findstr(fileName, '_results'))
            fileType = 'results';
        elseif ~isempty(findstr(fileName, '_linkresults'))
            fileType = 'linkresults';
        elseif ~isempty(findstr(fileName, '_brainstormstudy'))
            fileType = 'brainstormstudy';
        elseif ~isempty(findstr(fileName, '_channel'))
            fileType = 'channel';
        elseif ~isempty(findstr(fileName, '_headmodel'))
            fileType = 'headmodel';
        elseif ~isempty(findstr(fileName, '_noisecov'))
            fileType = 'noisecov';
        elseif ~isempty(findstr(fileName, '_timefreq'))
            fileType = 'timefreq';
        elseif ~isempty(findstr(fileName, '_pdata'))
            fileType = 'pdata';
        elseif ~isempty(findstr(fileName, '_presults'))
            fileType = 'presults';
        elseif ~isempty(findstr(fileName, '_ptimefreq'))
            fileType = 'ptimefreq';
        elseif ~isempty(findstr(fileName, '_brainstormsubject'))
            fileType = 'brainstormsubject';
        elseif ~isempty(findstr(fileName, '_subjectimage'))
            fileType = 'subjectimage';
        elseif ~isempty(findstr(fileName, '_tess'))
            if ~isempty(findstr(fileName, '_cortex'))   % || ~isempty(findstr(fileName, '_brain'))
                fileType = 'cortex';
            elseif ~isempty(findstr(fileName, '_scalp')) || ~isempty(findstr(fileName, '_skin')) || ~isempty(findstr(fileName, '_head'))
                fileType = 'scalp';
            elseif ~isempty(findstr(fileName, '_outerskull')) || ~isempty(findstr(fileName, '_outer_skull'))
                fileType = 'outerskull';
            elseif ~isempty(findstr(fileName, '_innerskull')) || ~isempty(findstr(fileName, '_inner_skull'))
                fileType = 'innerskull';
            elseif ~isempty(findstr(fileName, '_skull'))
                fileType = 'outerskull';
            else
                fileType = 'tess';
            end
        elseif ~isempty(findstr(fileName, '_res4'))
            fileType = 'res4';
        elseif ~isempty(findstr(fileName, '_dipoles'))
            fileType = 'dipoles';
        elseif ~isempty(findstr(fileName, '_matrix'))
            fileType = 'matrix';
        elseif ~isempty(findstr(fileName, '_proj'))
            fileType = 'proj';
        elseif ~isempty(findstr(fileName, '_scout'))
            fileType = 'scout';
        end
    % If file is an image:
    elseif (ismember(fileExt, {'.bmp','.emf','.eps','.jpg','.jpeg','.jpe','.pbm','.pcx','.pgm','.png','.ppm','.tif','.tiff'}))
        fileType = 'image';
    end
    
%% ===== INPUT: STRUCTURE =====
elseif isstruct(fileName)
    sMat = fileName;  
    if isfield(sMat, 'F')
        fileType = 'data';
    elseif isfield(sMat, 'ImageGridAmp')
        fileType = 'results';
    elseif isfield(sMat, 'BrainStormSubject')
        fileType = 'brainstormstudy';
    elseif isfield(sMat, 'Channel')
        fileType = 'channel';
    elseif all(isfield(sMat, {'HeadModelType','MEGMethod'}))
        fileType = 'headmodel';
    elseif isfield(sMat, 'NoiseCov')
        fileType = 'noisecov';
    elseif isfield(sMat, 'TF')
        fileType = 'timefreq';
    elseif all(isfield(sMat, {'tmap','Type'})) && strcmpi(sMat.Type, 'data')
        fileType = 'pdata';
    elseif all(isfield(sMat, {'tmap','Type'})) && strcmpi(sMat.Type, 'results')
        fileType = 'presults';
    elseif all(isfield(sMat, {'tmap','Type'})) && strcmpi(sMat.Type, 'timefreq')
        fileType = 'ptimefreq';
    elseif isfield(sMat, 'Cortex')
        fileType = 'brainstormsubject';
    elseif isfield(sMat, 'Cube')
        fileType = 'subjectimage';
    elseif isfield(sMat, 'Scout')
        fileType = 'scout';
    elseif isfield(sMat, 'Vertices')
        fileType = 'tess';
    elseif isfield(sMat, 'Dipole')
        fileType = 'dipoles';
    elseif isfield(sMat, 'Value')
        fileType = 'matrix';
    else
        fileType = 'unknown';
    end
else
    fileType = 'unknown';
end

end



