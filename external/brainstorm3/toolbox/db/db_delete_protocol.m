function isRemoved = db_delete_protocol(iProtocol, isUserConfirm, isRemoveFiles)
% DB_DELETE_PROTOCOL: Remove protocol from database (do not delete any file).
%
% USAGE:  db_delete_protocol(iProtocol,    isUserConfirm, isRemoveFiles)  : Remove protocol #iProtocol from protocols list
%         db_delete_protocol(ProtocolName, isUserConfirm, isRemoveFiles)  : Remove protocol with specified name
%         db_delete_protocol()  : Delete current protocol
% INPUT:
%     - iProtocol     : Indice of the protocol to remove
%     - ProtocolName  : Name of the protocol to remove
%     - isUserConfirm : If 0, do not ask user confirmation (default=1)
%     - isRemoveFiles : If 1, delete all the files in this protocol from the hard drive
%                       If 0, keep the files on the hard drive
%                       If empty or not specified: ask user

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

global GlobalData;


%% ===== PARSE INPUTS =====
% Get Protocols list structures (Infos, Subjects, Studies)
sProtocolsListInfo     = GlobalData.DataBase.ProtocolInfo;
sProtocolsListSubjects = GlobalData.DataBase.ProtocolSubjects;
sProtocolsListStudies  = GlobalData.DataBase.ProtocolStudies;
nbProtocols = length(sProtocolsListInfo);
if (nbProtocols == 0)
    return;
end
% Get/Check protocol index
if (nargin < 1) || isempty(iProtocol)
    iProtocol = GlobalData.DataBase.iProtocol;
elseif ischar(iProtocol)
    ProtocolName = iProtocol;
    iProtocol = find(strcmpi(ProtocolName, {sProtocolsListInfo.Comment}));
    if isempty(iProtocol)
        return;
    end
elseif ((iProtocol <= 0) || (iProtocol > nbProtocols))
    error('Protocol #%d does not exist.', iProtocol);
end
% Options
if (nargin < 2) || isempty(isUserConfirm)
    isUserConfirm = 1;
end
if (nargin < 3) || isempty(isRemoveFiles)
    isRemoveFiles = 1;
end


%% ===== ASK USER CONFIRMATION =====
if isUserConfirm
    % Warning string
    if ~isRemoveFiles
        strWarn = '(Subjects and datasets directories will not be deleted)';
    else
        strWarn = ['<BR><FONT color="#CC0000"><U>WARNING</U>: All the files will be permanently deleted from your hard drive.</FONT>'];
    end
    % Display dialog box
    isConfirmed = java_dialog('confirm', ['<HTML>Remove protocol ''' sProtocolsListInfo(iProtocol).Comment ''' from Brainstorm database ? <BR>' ...
                                          strWarn '<BR><BR>'], sprintf('Remove protocol #%d', iProtocol));
    if ~isConfirmed
        isRemoved = 0;
        return
    end
end

%% ===== REMOVE FILES =====
if isRemoveFiles
    % Remove all the contents of STUDIES and SUBJECTS folders
    file_delete( {sProtocolsListInfo(iProtocol).STUDIES, sProtocolsListInfo(iProtocol).SUBJECTS}, 1);
    % If the parent folder (protocol folder) is empty: remove it
    try
        rmdir(bst_fileparts(sProtocolsListInfo(iProtocol).STUDIES));
    catch
        % If an error was thrown, it is just because the folder is not empty.
    end
end
    
%% ===== REMOVE PROTOCOL =====
sProtocolsListInfo(iProtocol)     = [];
sProtocolsListSubjects(iProtocol) = [];
sProtocolsListStudies(iProtocol)  = [];
% Update database
GlobalData.DataBase.ProtocolInfo      = sProtocolsListInfo;
GlobalData.DataBase.ProtocolSubjects  = sProtocolsListSubjects;
GlobalData.DataBase.ProtocolStudies   = sProtocolsListStudies;
GlobalData.DataBase.isProtocolLoaded(iProtocol)   = [];
GlobalData.DataBase.isProtocolModified(iProtocol) = [];
% Update protocols ComboBox
gui_brainstorm('UpdateProtocolsList');

% Get new protocol to select
if isempty(sProtocolsListInfo)
    iProtocol = 0;
elseif (iProtocol == 1)
    iProtocol = 1;
else
    iProtocol = iProtocol - 1;
end
% Select current protocol in combo list
gui_brainstorm('SetCurrentProtocol', iProtocol);

% Save database
% db_save();
isRemoved = 1;



