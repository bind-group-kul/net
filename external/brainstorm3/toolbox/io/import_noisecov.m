function Output = import_noisecov(iStudies, NoiseCovMat, AutoReplace)
% IMPORT_NOISECOV: Imports a noise covariance file.
% 
% USAGE:  
%         BstNoisecovFile = import_noisecov(iStudies, NoiseCovFile) : Read file and save it in brainstorm database
%         BstNoisecovFile = import_noisecov(iStudies, NoiseCovMat)  : Save a NoiseCov file structure in brainstorm database
%         BstNoisecovFile = import_noisecov(iStudies)               : Ask file to the user, read it, and save it in brainstorm database
%             NoiseCovMat = import_noisecov([],       NoiseCovFile) : Just read the file
%             NoiseCovMat = import_noisecov()                       : Ask file to the user, and read it
%                     ... = import_noisecov(..., ..., AutoReplace)  : If 1, do not ask for confirmation before replacing existing files
%
% INPUT:
%    - iStudies     : Indices of the studies where to import the NoiseCovFile
%    - NoiseCovFile : Full filename of the noise covariance matrix to import (format is autodetected)
%                     => if not specified : file to import is asked to the user
%    - AutoReplace  : {0,1}, If 1, do not ask for confirmation before replacing existing files

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
% Authors: Francois Tadel, 2009-2010


%% ===== PARSE INPUTS =====
% Argument: AutoReplace
if (nargin < 3) || isempty(AutoReplace)
    AutoReplace = 0;
end
% Argument: NoiseCovMat
if (nargin < 2) || isempty(NoiseCovMat)
    NoiseCovMat = [];
    NoiseCovFile = '';
elseif ischar(NoiseCovMat)
    NoiseCovFile = NoiseCovMat;
    NoiseCovMat = [];
elseif isstruct(NoiseCovMat)
    NoiseCovFile = '';
end
% Argument: iStudies
if (nargin < 1)
    iStudies = [];
end
% Initialize output structure
Output = [];

% Detect file format
FileFormat = '';
if ~isempty(NoiseCovFile)
    % Get the file extenstion
    [fPath, fBase, fExt] = bst_fileparts(NoiseCovFile);
    if ~isempty(fExt)
        fExt = lower(fExt(2:end));
        % Detect file format by extension
        switch lower(fExt)
            case 'fif', FileFormat = 'FIF';
            case 'mat', FileFormat = 'BST';
            otherwise,  FileFormat = 'ASCII';
        end
        % Display assumed file format
        disp(['Default file format for this extension: ' FileFormat]);
        disp('If you want to specify the extension, please run this function without arguments.');
    end
end


%% ===== SELECT NOISECOV FILE =====
% If MRI file to load was not defined : open a dialog box to select it
if isempty(NoiseCovFile) && isempty(NoiseCovMat)
    % Get default import directory and formats
    LastUsedDirs = bst_get('LastUsedDirs');
    DefaultFormats = bst_get('DefaultFormats');
    % Get NoiseCov file
    [NoiseCovFile, FileFormat] = java_getfile('open', ...
            'Import noise covariance...', ...         % Window title
            LastUsedDirs.ImportChannel, ...   % Last used directory
            'single', 'files', ...   % Selection mode
            {{'.fif'},      'Neuromag FIFF (*.fif)',      'FIF'; ...
             {'_noisecov'}, 'Brainstorm (noisecov*.mat)', 'BST'; ...
             {'*'},         'ASCII (*.*)',                'ASCII' ...
            }, DefaultFormats.NoiseCovIn);
    % If no file was selected: exit
    if isempty(NoiseCovFile)
        return
    end
    % Save default import directory
    LastUsedDirs.ImportChannel = bst_fileparts(NoiseCovFile);
    bst_set('LastUsedDirs', LastUsedDirs);
    % Save default import format
    DefaultFormats.NoiseCovIn = FileFormat;
    bst_set('DefaultFormats',  DefaultFormats);
end


%% ===== LOAD NOISECOV FILE =====
sensorsNames = [];
isProgressBar = bst_progress('isVisible');
if isempty(NoiseCovMat)
    % Progress bar
    if ~isProgressBar
        bst_progress('start', 'Import noise covariance file', ['Loading file "' NoiseCovFile '"...']);
    end
    % Get the file extenstion
    [fPath, fBase, fExt] = bst_fileparts(NoiseCovFile);
    if ~isempty(fExt)
        fExt = lower(fExt(2:end));
    end
    % Load file
    switch FileFormat
        case 'FIF'
            [NoiseCovMat.NoiseCov, sensorsNames] = in_noisecov_fif(NoiseCovFile);
            NoiseCovMat.Comment = 'Noise covariance (FIF)';
            % Check that something was read
            if isempty(NoiseCovMat.NoiseCov)
                error('Noise covariance matrix was not found in this FIF file.');
            end
        case 'BST'
            NoiseCovMat.NoiseCov = load(NoiseCovFile);       
            NoiseCovMat.Comment = 'Noise covariance';
        case 'ASCII'  % (*.*)
            NoiseCovMat.NoiseCov = load(NoiseCovFile, '-ascii');
            NoiseCovMat.Comment = 'Noise covariance (ASCII)';
    end
    % No data imported
    if isempty(NoiseCovMat) || isempty(NoiseCovMat.NoiseCov)
        bst_progress('stop');
        return
    end
    % History: File name
    NoiseCovMat = bst_history('add', NoiseCovMat, 'import', ['Import from: ' NoiseCovFile ' (Format: ' FileFormat ')']);
            
    % Get imported base name
    [tmp__, importedBaseName, importedExt] = bst_fileparts(NoiseCovFile);
    importedBaseName = strrep(importedBaseName, 'noisecov_', '');
    importedBaseName = strrep(importedBaseName, '_noisecov', '');
    importedBaseName = strrep(importedBaseName, 'noisecov', '');
    % Limit number of chars
    if (length(importedBaseName) > 15)
        importedBaseName = importedBaseName(1:15);
    end
else
    importedBaseName = 'full';
end


%% ===== APPLY NEW NOISECOV FILE =====
if ~isempty(iStudies)
    % Get Protocol information
    ProtocolInfo = bst_get('ProtocolInfo');
    BstNoisecovFile = [];
    % Add noisecov file to all the target studies
    for i = 1:length(iStudies)
        % Get study
        iStudy = iStudies(i);
        sStudy = bst_get('Study', iStudy);
        studySubDir = bst_fileparts(sStudy.FileName);
        % Load ChannelFile
        if ~isempty(sStudy.Channel)
            ChannelMat = in_bst_channel(sStudy.Channel.FileName, 'Channel');
        end
        
        % If there is a Channel file defined, and we know the names of the noisecov rows
        if ~isempty(sStudy.Channel) && ~isempty(sensorsNames)
            % For each row of the noisecov matrix
            iRowChan = [];
            iRowCov  = [];
            for iRow = 1:length(sensorsNames)
                % Look for sensor name in channels list
                ind = find(strcmpi(sensorsNames{iRow}, {ChannelMat.Channel.Name}));
                % If channel was found, reference it in both arrays
                if ~isempty(ind)
                    iRowCov(end+1)  = iRow;
                    iRowChan(end+1) = ind;
                end
            end
            % Check that this noisecov file corresponds to the Channel file
            if isempty(iRowCov)
                error('This noise covariance file does not correspond to the channel file.');
            end
            % Fill a NoiseCov matrix corresponding to channel file
            fullNoiseCov = zeros(length(ChannelMat.Channel));
            fullNoiseCov(iRowChan,iRowChan) = NoiseCovMat.NoiseCov(iRowCov,iRowCov);
            % Replace noise covariance read from file
            NoiseCovMat.NoiseCov = fullNoiseCov;
        else
            % Check the number of sensors
            if ~isempty(sStudy.Channel) && (size(NoiseCovMat.NoiseCov,1) ~= length(ChannelMat.Channel))
                error('This noise covariance file does not correspond to the channel file.');
            end
        end
        
        % ===== DELETE PREVIOUS NOISECOV FILES =====
        % Delete all the other noisecov files in the study directory
        noisecovFiles = dir(bst_fullfile(ProtocolInfo.STUDIES, studySubDir, '*noisecov*.mat'));
        if ~isempty(noisecovFiles)
            % If no auto-confirmation
            if ~AutoReplace
                % Ask user confirmation
                res = java_dialog('confirm', ['Warning: a noise covariance file is already defined for this study,' 10 ...
                                       '"' bst_fullfile(studySubDir, noisecovFiles(1).name) '".' 10 10 ...
                                       'Delete previous file ?' 10], 'Replace noise covariance file');
                % If user did not accept : go to next study
                if ~res
                    continue;
                end
            end
            % Delete previous noisecov file
            noisecovFilesFull = cellfun(@(f)bst_fullfile(ProtocolInfo.STUDIES, studySubDir, f), {noisecovFiles.name}, 'UniformOutput', 0);
            file_delete(noisecovFilesFull, 1);
        end

        % ===== SAVE NOISECOV FILE =====
        % Produce a default noisecov filename
        BstNoisecovFile = bst_fullfile(ProtocolInfo.STUDIES, studySubDir, ['noisecov_' importedBaseName '.mat']);
        % Save new NoiseCovFile in Brainstorm format
        bst_save(BstNoisecovFile, NoiseCovMat, 'v7');

        % ===== STORE NEW NOISECOV IN DATABASE ======
        % New noisecov structure
        newNoiseCov = db_template('NoiseCov');
        newNoiseCov(1).FileName = file_short(BstNoisecovFile);
        newNoiseCov.Comment    = NoiseCovMat.Comment;

        % Add noisecov to study
        sStudy.NoiseCov = newNoiseCov;
        % Update database
        bst_set('Study', iStudy, sStudy);  
    end

    % Update tree
    panel_protocols('UpdateNode', 'Study', iStudies);
    % Save database
    db_save();
    % Returned value
    Output = BstNoisecovFile;
else
    Output = NoiseCovMat;
end

% Progress bar
if ~isProgressBar
    bst_progress('stop');
end


