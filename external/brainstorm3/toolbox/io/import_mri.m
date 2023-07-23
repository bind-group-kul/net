function [BstMriFile, MRI] = import_mri(iSubject, MriFile, FileFormat, isInteractive)
% IMPORT_MRI: Import a MRI file in a Subject of Brainstorm database
% 
% USAGE: [BstMriFile, MRI] = import_mri(iSubject, MriFile, FileFormat='ALL', isInteractive=0)
%
% INPUT:
%    - iSubject  : Indice of the subject where to import the MRI
%                  If iSubject=0 : import MRI in default subject
%    - MriFile   : Full filename of the MRI to import (format is autodetected)
%                  => if not specified : file to import is asked to the user
%    - FileFormat : String, one on the file formats in in_mri
%    - isInteractive : if 1, importation will be interactive (MRI is displayed after loading)
% OUTPUT:
%    - BstMriFile : Full path to the new file if success, [] if error

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
% Authors: Francois Tadel, 2008-2013

% ===== Parse inputs =====
if (nargin < 3) || isempty(FileFormat)
    FileFormat = 'ALL';
end
if (nargin < 4) || isempty(isInteractive)
    isInteractive = 0;
end
% Initialize returned variables
BstMriFile = [];
MRI = [];
% Get Protocol information
ProtocolInfo     = bst_get('ProtocolInfo');
ProtocolSubjects = bst_get('ProtocolSubjects');
% Default subject
if (iSubject == 0)
	sSubject = ProtocolSubjects.DefaultSubject;
% Normal subject 
else
    sSubject = ProtocolSubjects.Subject(iSubject);
end


%% ===== SELECT MRI FILE =====
% If MRI file to load was not defined : open a dialog box to select it
if isempty(MriFile)    
    % Get last used directories
    LastUsedDirs = bst_get('LastUsedDirs');
    % Get last used format
    DefaultFormats = bst_get('DefaultFormats');
    if isempty(DefaultFormats.MriIn)
        DefaultFormats.MriIn = 'ALL';
    end
    % Get MRI file
    [MriFile, FileFormat] = java_getfile( 'open', ...
        'Import MRI...', ...              % Window title
        LastUsedDirs.ImportAnat, ...      % Default directory
        'single', 'files', ...            % Selection mode
        bst_get('FileFilters', 'mri'), ...
        DefaultFormats.MriIn);
    % If no file was selected: exit
    if isempty(MriFile)
        return
    end
    % Save default import directory
    LastUsedDirs.ImportAnat = bst_fileparts(MriFile);
    bst_set('LastUsedDirs', LastUsedDirs);
    % Save default import format
    DefaultFormats.MriIn = FileFormat;
    bst_set('DefaultFormats',  DefaultFormats);
end
    
    
%% ===== LOAD MRI FILE =====
bst_progress('start', 'Import MRI', ['Loading file "' MriFile '"...']);
% Load MRI
MRI = in_mri(MriFile, FileFormat);
if isempty(MRI)
    bst_progress('stop');
    return
end
% History: File name
MRI = bst_history('add', MRI, 'import', ['Import from: ' MriFile]);


%% ===== MANAGE MULTIPLE MRI =====
% Add new anatomy
iAnatomy = length(sSubject.Anatomy) + 1;
% If add an extra MRI: read the first one to check that they are compatible
if (iAnatomy > 1)
    % Load the reference MRI (the first one)
    refMriFile = sSubject.Anatomy(1).FileName;
    refMRI = in_mri_bst(refMriFile);
    % Copy the SCS and NCS fields
    MRI.SCS = refMRI.SCS;
    MRI.NCS = refMRI.NCS;
    % Check the dimensions
    if any(size(refMRI.Cube) ~= size(MRI.Cube)) || any(refMRI.Voxsize ~= refMRI.Voxsize)
        errMsg = ['Error: The size or orientation of the new MRI does not match the previous one.' 10 10 ...
                  'You can import multiple MRI volumes for a subject only if they all have exactly' 10 ...
                  'the same dimensions, voxel size, and orientation.'];
        if isInteractive
            bst_error(errMsg, 'Import MRI', 0);
            MRI = [];
            bst_progress('stop');
            return;
        else
            disp(errMsg);
            MRI = [];
            bst_progress('stop');
            return;
        end
    end
end

%% ===== SAVE MRI IN BRAINSTORM FORMAT =====
% % If there is already an MRI defined for this subject
% if ~isempty(sSubject.Anatomy)
%     % If interactive method is required
%     if isInteractive
%         % Ask user whether the previous MRI should be removed
%         isDel = java_dialog('confirm', ['Warning: There is already a MRI defined for this subject.' 10 10 ...
%                                         'Are you sure you want to delete the previous MRI ?' 10 10], 'Import MRI');
%         % If user canceled process
%         if ~isDel
%             bst_progress('stop');
%             return;
%         end
%     end
%     % Delete the previous MRI
%     MriFile = bst_fullfile(ProtocolInfo.SUBJECTS, sSubject.Anatomy(1).FileName);
%     file_delete(MriFile, 1);
% end

% Add a Comment field in MRI structure, if it does not exist yet
if ~isfield(MRI, 'Comment')
    MRI.Comment = 'MRI';
end
% Add an index number 
if (iAnatomy > 1)
    MRI.Comment = [MRI.Comment, sprintf(' #%d', iAnatomy)];
end
% Get subject subdirectory
subjectSubDir = bst_fileparts(sSubject.FileName);
% Get imported base name
[tmp__, importedBaseName] = bst_fileparts(MriFile);
importedBaseName = strrep(importedBaseName, 'subjectimage_', '');
importedBaseName = strrep(importedBaseName, '_subjectimage', '');
% Produce a default anatomy filename
BstMriFile = bst_fullfile(ProtocolInfo.SUBJECTS, subjectSubDir, ['subjectimage_' importedBaseName '.mat']);
% Make this filename unique
BstMriFile = file_unique(BstMriFile);
% Save new MRI in Brainstorm format
MRI = out_mri_bst(MRI, BstMriFile);
% Clear memory
MriComment = MRI.Comment;

%% ===== STORE NEW MRI IN DATABASE ======
% New anatomy structure
sSubject.Anatomy(iAnatomy) = db_template('Anatomy');
sSubject.Anatomy(iAnatomy).FileName = file_short(BstMriFile);
sSubject.Anatomy(iAnatomy).Comment  = MriComment;
% Default anatomy: do not change
if isempty(sSubject.iAnatomy)
    sSubject.iAnatomy = iAnatomy;
end

% == Update database ==
% Default subject
if (iSubject == 0)
	ProtocolSubjects.DefaultSubject = sSubject;
% Normal subject 
else
    ProtocolSubjects.Subject(iSubject) = sSubject;
end
bst_set('ProtocolSubjects', ProtocolSubjects);


%% ===== UPDATE GUI =====
% Refresh tree
panel_protocols('UpdateNode', 'Subject', iSubject);
panel_protocols('SelectNode', [], 'subject', iSubject, -1 );
% Save database
db_save();
% Unload MRI (if a MRI with the same name was previously loaded)
bst_memory('UnloadMri', BstMriFile);


%% ===== MRI VIEWER =====
if isInteractive
    % => MRI Visualization and selection of fiducials (in order to align surfaces/MRI)
    hFig = view_mri(BstMriFile, 'EditMri');
    drawnow;
    bst_progress('stop');
    % Display help message: ask user to select fiducial points
    if (iAnatomy == 1)
        jHelp = bst_help('MriSetup.html', 0);
    else
        jHelp = [];
    end
    % Wait for the MRI Viewer to be closed
    if ishandle(hFig)
        waitfor(hFig);
    end
    % Close help window
    if ~isempty(jHelp)
        jHelp.close();
    end
else
    bst_progress('stop');
end





    
