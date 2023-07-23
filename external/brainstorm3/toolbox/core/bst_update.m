function isUpdated = bst_update(AskConfirm)
% BST_UPDATE:  Download and install the latest version of Brainstorm.
%
% USAGE:  isUpdated = bst_update(AskConfirm)
%         isUpdated = bst_update()
%
% INPUT:
%    - AskConfirm: {0,1}, If 1, ask user confirmation before proceeding to update

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
% Authors: Francois Tadel, 2009-2013

% Parse inputs
if (nargin == 0) || isempty(AskConfirm)
    AskConfirm = 0;
end
isUpdated = 0;

% === ASKING CONFIRMATION ===
if AskConfirm
    res = java_dialog('confirm', ['Download latest Brainstorm update ?' 10 10 ...
                                  'To turn off automatic updates, edit software preferences.' 10 10], 'Update');
    if ~res
        return
    end
end

% === DOWNLOAD NEW VERSION ===
% Get update zip file
urlUpdate  = 'http://neuroimage.usc.edu/brainstorm3_register/getupdate.php?c=UbsM09';
installDir = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
zipFile    = fullfile(installDir, 'brainstorm_update.zip');

% Check permissions
if ~file_attrib(installDir, 'w') || ~file_attrib(fullfile(installDir, 'brainstorm3'), 'w')
    disp('BST> Update: Brainstorm folder is read-only...');
    if AskConfirm
        java_dialog('msgbox', ['Installation folder is read-only.' 10 10 ...
                               'Software was not updated.' 10 10], 'Update');
    end
    return
end

% Download file
downloadManager = java_create('org.brainstorm.file.BstDownload', 'Ljava.lang.String;Ljava.lang.String;Ljava.lang.String;)', urlUpdate, zipFile, 'Brainstorm update');
downloadManager.download();
% Wait for the termination of the thread
while (downloadManager.getResult() == -1)
    pause(0.5);
end
% If file was not downloaded correctly
if (downloadManager.getResult() ~= 1)
    disp('BST> Update: Unable to download updates.');
    if AskConfirm
        java_dialog('msgbox', ['Could not download new packages.' 10 10 ...
                               'Software was not updated.' 10 10], 'Update');
    end
    return
end

% === STOP BRAINSTORM ===
if isappdata(0, 'BrainstormRunning')
    bst_exit();
end

% === DELETE THE PREVIOUS INSTALLATION ===
downloadManager.setText('Removing previous installation...');
disp('BST> Update: Removing previous installation...');
% Go to zip folder (to make sure we are not in a folder we are deleting)
cd(installDir);
% Try the folders separately
try
    rmdir(fullfile(installDir, 'brainstorm3', 'toolbox'), 's');
end
try
    rmdir(fullfile(installDir, 'brainstorm3', 'external'), 's');
end
try
    rmdir(fullfile(installDir, 'brainstorm3', 'bin'), 's');
end
try
    rmdir(fullfile(installDir, 'brainstorm3', 'defaults', 'anatomy', 'Colin27'), 's');
end
try
    rmdir(fullfile(installDir, 'brainstorm3', 'defaults', 'eeg', 'Colin27'), 's');
end
try
    rmdir(fullfile(installDir, 'brainstorm3', 'defaults', 'anatomy', 'MNI_Colin27'), 's');
end
try
    rmdir(fullfile(installDir, 'brainstorm3', 'defaults', 'eeg', 'MNI_Colin27'), 's');
end
try
    rmdir(fullfile(installDir, 'brainstorm3', 'defaults', 'eeg', 'NotAligned'), 's');
end

% === UNZIP FILE ===
downloadManager.setText('Unzipping...');
disp('BST> Update: Unzipping...');
% Unzip update file
unzip(zipFile);
% Delete temporary update file
delete(zipFile);
% Add some folders to the path again
addpath(fullfile(installDir, 'brainstorm3', 'toolbox', 'misc'));
addpath(fullfile(installDir, 'brainstorm3', 'toolbox', 'core'));
addpath(fullfile(installDir, 'brainstorm3', 'toolbox', 'io'));

% Clear everything in memory
warning('off', 'MATLAB:objectStillExists');
clear global
clear functions
clear java
clear classes
warning('on', 'MATLAB:objectStillExists');
% Get last warning
[warnTxt,warnId] = lastwarn();
% If not all objects were deleted: need matlab restart
% if strcmpi(warnId, 'MATLAB:objectStillExists')
%     disp('BST> Update: You need to restart Matlab before starting Brainstorm.');
%     isRestart = 1;
% else
%     isRestart = 0;
% end
isRestart = 1;

disp('BST> Update: Done.');
isUpdated = 1;

% === RESTART MATLAB/BRAINSTORM ===
if isRestart
    h = msgbox(['Brainstorm updated successfully.' 10 10 ...
                'Matlab will now be closed.' 10 ...
                'Restart Matlab and run brainstorm.m to finish installation.' 10 10], 'Update');
    waitfor(h);
    exit;
else
    % Start brainstorm again
    cd brainstorm3
    brainstorm
end
end


