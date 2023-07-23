function [ varargout ] = bst_memory( varargin )
% BST_MEMORY: Manages all loaded data (GlobalData variable).
% For a description of the global variable GlobalData, see "brainstorm/doc/GlobalData.txt"
%
% USAGE:          iDS = bst_memory('LoadDataFile',         DataFile, isReloadForced)
%                       bst_memory('LoadRecordingsMatrix', iDS)
%      [iDS, iResult] = bst_memory('LoadResultsFile',      ResultsFile)
%                       bst_memory('LoadResultsMatrix',    iDS, iResult)
%      [iDS, iResult] = bst_memory('LoadResultsFileFull',  ResultsFile)
%      [iDS, iDipole] = bst_memory('LoadDipolesFile',      DipolesFile)
%       [iDS, iTimef] = bst_memory('LoadTimefreqFile',     TimefreqFile)
%                       bst_memory('LoadMri',              iDS, MriFile);
%      [sSurf, iSurf] = bst_memory('LoadSurface',          iSubject, SurfaceType)
%      [sSurf, iSurf] = bst_memory('LoadSurface',          MriFile,  SurfaceType)
%      [sSurf, iSurf] = bst_memory('LoadSurface',          SurfaceFile)
%
%          DataValues = bst_memory('GetRecordingsValues',  iDS, iChannel, iTime)
%       ResultsValues = bst_memory('GetResultsValues',     iDS, iRes, iVertices, TimeValues)
%       DipolesValues = bst_memory('GetDipolesValues',     iDS, iDipoles, TimeValues)
%      TimefreqValues = bst_memory('GetTimefreqValues',    iDS, iTimefreq, TimeValues)
%              minmax = bst_memory('GetResultsMaximum',    iDS, iTimefreq)
%              minmax = bst_memory('GetTimefreqMaximum',   iDS, iTimefreq, Function)
%                 iDS = bst_memory('GetDataSetData',       DataFile, isStatic)
%                 iDS = bst_memory('GetDataSetData',       DataFile)
%                 iDS = bst_memory('GetDataSetStudyNoData',StudyFile)
%                 iDS = bst_memory('GetDataSetStudy',      StudyFile)
%                 iDS = bst_memory('GetDataSetChannel',    ChannelFile)
%                 iDS = bst_memory('GetDataSetSubject',    SubjectFile, createSubject)
%                 iDS = bst_memory('GetDataSetEmpty')
%      [iDS, iResult] = bst_memory('GetDataSetResult',     ResultsFile)
%      [iDS, iResult] = bst_memory('GetDataSetDipoles',    DipolesFile)
%      [iDS, iTimefr] = bst_memory('GetDataSetTimefreq',   TimefreqFile)
%             iResult = bst_memory('GetResultInDataSet',   iDS, ResultsFile)
%             iResult = bst_memory('GetDipolesInDataSet',  iDS, DipolesFile)
%           iTimefreq = bst_memory('GetTimefreqInDataSet', iDS, TimefreqFile)
%                 iDS = bst_memory('GetRawDataSet');
%
% [TimeVector, iTime] = bst_memory('GetTimeVector', ...) 
%                isOk = bst_memory('CheckTimeWindows')
%                isOk = bst_memory('CheckFrequencies')
%                       bst_memory('ReloadAllDataSets')
%                       bst_memory('ReloadStatDataSets')
%                       bst_memory('UnloadAll', OPTIONS)
%                       bst_memory('UnloadDataSets', iDS)
%                       bst_memory('UnloadDataSetResult, ResultsFile)
%                       bst_memory('UnloadDataSetResult, iDS, iResult)

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

macro_methodcall;
end


%% =========================================================================================
%  ===== ANATOMY ===========================================================================
%  =========================================================================================
%% ===== LOAD MRI =====
% USAGE:  [sMri,iMri] = bst_memory('LoadMri', MriFile)
%         [sMri,iMri] = bst_memory('LoadMri', iSubject)
function [sMri,iMri] = LoadMri(MriFile)
    global GlobalData;
    % ===== PARSE INPUTS =====
    % If argument is a subject indice
    if isnumeric(MriFile)
        % Get subject
        iSubject = MriFile;
        sSubject = bst_get('Subject', iSubject);
        % If subject does not have a MRI
        if isempty(sSubject.Anatomy) || isempty(sSubject.iAnatomy)
            error('No MRI avaialable for subject "%s".', sSubject.Name);
        end
        % Get MRI file
        MriFile = sSubject.Anatomy(sSubject.iAnatomy).FileName;
    end

    % ===== CHECK IF LOADED =====  
    % Check if surface is already loaded
    iMri = find(file_compare({GlobalData.Mri.FileName}, MriFile));
    % If MRI is not loaded yet: load it
    if isempty(iMri)
        % Unload the unused Anatomies (surfaces + MRIs)
        UnloadAll('KeepSurface');
        % Create default structure
        sMri = db_template('LoadedMri');
        % Load MRI matrix
        MriMat = in_mri_bst(MriFile);
        % Build MRI structure
        for field = fieldnames(sMri)'
            if isfield(MriMat, field{1})
                sMri.(field{1}) = MriMat.(field{1});
            end
        end
        % Set filename
        sMri.FileName = file_win2unix(MriFile);
        % Add MRI to loaded MRIs in this protocol
        iMri = length(GlobalData.Mri) + 1;
        % Save MRI in memory
        GlobalData.Mri(iMri) = sMri;
    % Else: Return the existing instance
    else
        sMri = GlobalData.Mri(iMri);
    end
end


%% ===== GET MRI =====
function [sMri, iMri] = GetMri(MriFile) %#ok<DEFNU>
    global GlobalData;
    % Check if surface is already loaded
    iMri = find(file_compare({GlobalData.Mri.FileName}, MriFile));
    if ~isempty(iMri)
        sMri = GlobalData.Mri(iMri);
    else
        sMri = [];
    end
end


%% ===== LOAD SURFACE =====
% Load a surface in memory, or get a loaded surface
% Usage:  [sSurf, iSurf] = LoadSurface(iSubject, SurfaceType)
%         [sSurf, iSurf] = LoadSurface(MriFile,  SurfaceType)
%         [sSurf, iSurf] = LoadSurface(SurfaceFile)
function [sSurf, iSurf] = LoadSurface(varargin)
    global GlobalData;
    % ===== PARSE INPUTS =====
    if (nargin == 1)
        SurfaceFile = varargin{1};
    elseif (nargin == 2)
        % Get inputs
        iSubject = varargin{1};
        SurfaceType = varargin{2};
        % Get surface
        sDbSurf = bst_get('SurfaceFileByType', iSubject, SurfaceType);
        SurfaceFile = sDbSurf.FileName;
    end
    % Get subject and surface type
    [sSubject, iSubject, iSurfDb] = bst_get('SurfaceFile', SurfaceFile);
    if isempty(iSubject)
        SurfaceType = 'Other';
    else
        SurfaceType = sSubject.Surface(iSurfDb).SurfaceType;
    end
            
    % ===== LOAD FILE =====
    % Check if surface is already loaded
    if ~isempty(GlobalData.Surface)
        iSurf = find(file_compare({GlobalData.Surface.FileName}, SurfaceFile));
    else
        iSurf = [];
    end
    % If file not loaded: load it
    if isempty(iSurf)
        % Check if progressbar is visible
        isProgressBar = bst_progress('isVisible');
        % Unload the unused Anatomies (surfaces + MRIs)
        UnloadAll('KeepMri', 'KeepRegSurface');
        % Re-open progress bar
        if isProgressBar
            bst_progress('show');
            bst_progress('text', 'Loading surface file...');
        end
        % Create default structure
        sSurf = db_template('LoadedSurface');
        % Load surface matrix
        surfMat = in_tess_bst(SurfaceFile);
        % Get interesting fields
        sSurf.Comment         = surfMat.Comment;
        sSurf.Faces           = double(surfMat.Faces);
        sSurf.Vertices        = double(surfMat.Vertices);
        sSurf.VertConn        = surfMat.VertConn;
        sSurf.VertNormals     = surfMat.VertNormals;
        [tmp, sSurf.VertArea] = tess_area(surfMat);
        sSurf.SulciMap        = double(surfMat.SulciMap);

        % Get interpolation matrix MRI<->Surface if it exists
        if isfield(surfMat, 'tess2mri_interp')
            sSurf.tess2mri_interp = surfMat.tess2mri_interp;
        end
        % Get the mrimask for this surface, if it exists
        if isfield(surfMat, 'mrimask')
            sSurf.mrimask = surfMat.mrimask;
        end
        % Fix atlas structure
        sSurf.Atlas = panel_scout('FixAtlasStruct', surfMat.Atlas);
        % Default atlas
        if isempty(surfMat.iAtlas) || (surfMat.iAtlas < 1) || (surfMat.iAtlas > length(sSurf.Atlas))
            sSurf.iAtlas = 1;
        else
            sSurf.iAtlas = surfMat.iAtlas;
        end
        % Save surface file and type
        sSurf.FileName = file_win2unix(SurfaceFile);
        sSurf.Name     = SurfaceType;
        % Add surface to loaded surfaces list in this protocol (if not already loaded)
        iSurf = length(GlobalData.Surface) + 1;
        % Save surface in memory
        GlobalData.Surface(iSurf) = sSurf;
        
    % Else, return the existing instance
    else
        sSurf = GlobalData.Surface(iSurf);
    end
end


%% ===== GET INTERPOLATION SURF-MRI =====
% USAGE:  [tess2mri_interp, sMri] = GetTess2MriInterp(iSurf, MriFile) 
%         [tess2mri_interp, sMri] = GetTess2MriInterp(iSurf)          : Use the database to get MriFile
function [tess2mri_interp, sMri] = GetTess2MriInterp(iSurf, MriFile)
    global GlobalData;
    if (nargin < 2) || isempty(MriFile)
        MriFile = [];
    end
    % Get existing interpolation
    tess2mri_interp = GlobalData.Surface(iSurf).tess2mri_interp;
    % Get anatomy
    if (nargout >= 2) || isempty(tess2mri_interp)
        % Get surface file name
        SurfaceFile = GlobalData.Surface(iSurf).FileName;
        % Load subject MRI
        if ~isempty(MriFile)
            sMri = LoadMri(MriFile);
        else
            [sSubject, iSubject] = bst_get('SurfaceFile', SurfaceFile);
            sMri = LoadMri(iSubject);
        end
    end
    % If interpolation matrix was not lready computed: return it
    if isempty(tess2mri_interp)
        % Compute or load interpolation matrix
        tess2mri_interp = tess_interp_mri(SurfaceFile, sMri);
        % Store result for future use
        GlobalData.Surface(iSurf).tess2mri_interp = tess2mri_interp;
    end
end


%% ===== GET INTERPOLATION GRID-MRI =====
function grid2mri_interp = GetGrid2MriInterp(iDS, iResult) %#ok<DEFNU>
    global GlobalData;
    % If matrix was already computed: return it
    if ~isempty(GlobalData.DataSet(iDS).Results(iResult).grid2mri_interp)
        grid2mri_interp = GlobalData.DataSet(iDS).Results(iResult).grid2mri_interp;
    % Else: compute it
    else
        % Get subject
        [sSubject, iSubject] = bst_get('Subject', GlobalData.DataSet(iDS).SubjectFile);
        % Load MRI
        sMri = LoadMri(iSubject);
        % Compute interpolation
        grid2mri_interp = grid_interp_mri(GlobalData.DataSet(iDS).Results(iResult).GridLoc, sMri);
        % Store result for future use
        GlobalData.DataSet(iDS).Results(iResult).grid2mri_interp = grid2mri_interp;
    end
end


%% ===== GET SURFACE MASK =====
% USAGE:  GetSurfaceMask(SurfaceFile, MriFile)
%         GetSurfaceMask(SurfaceFile)          : MriFile is retrieved from the database
function [mrimask, sMri, sSurf] = GetSurfaceMask(SurfaceFile, MriFile) %#ok<DEFNU>
    global GlobalData;
    if (nargin < 2) || isempty(MriFile)
        MriFile = [];
    end
    % Load surface
    [sSurf, iSurf] = LoadSurface(SurfaceFile);
    % Get the tess -> MRI interpolation
    [tess2mri_interp, sMri] = GetTess2MriInterp(iSurf, MriFile);
    % Get an existing mrimask
    if ~isempty(sSurf.mrimask)
        mrimask = sSurf.mrimask;
    % MRI mask do not exist yet
    else
        % Compute mrimask
        mrimask = tess_mrimask(size(sMri.Cube), tess2mri_interp);
        % Add it to loaded structure
        GlobalData.Surface(iSurf).mrimask = mrimask;
        % Save new mrimask into file
        SurfaceFile = file_fullpath(SurfaceFile);
        s.mrimask = mrimask;
        if file_exist(SurfaceFile)
            bst_save(SurfaceFile, s, 'v7', 1);
        end
    end
end


%% ===== GET SURFACE =====
function [sSurf, iSurf] = GetSurface(SurfaceFile)
    global GlobalData;
    % Remove full path
    SurfaceFile = file_short(SurfaceFile);
    % Check if surface is already loaded
    iSurf = find(file_compare({GlobalData.Surface.FileName}, SurfaceFile));
    if ~isempty(iSurf)
        sSurf = GlobalData.Surface(iSurf);
    else
        sSurf = [];
    end
end


%% =========================================================================================
%  ===== FUNCTIONAL DATA ===================================================================
%  =========================================================================================
%% ===== GET FILE INFORMATION =====
% Get all the information related with a DataFile.
function [sStudy, iData, ChannelFile, FileType, sItem] = GetFileInfo(DataFile)
    % Get file in database
    [sStudy, iStudy, iData, FileType, sItem] = bst_get('AnyFile', DataFile);
    % If this data file does not belong to any study
    if isempty(sStudy)
        error('File is not registered in database.');
    end
    % If Channel is not defined yet : get it from Study description
    Channel = bst_get('ChannelForStudy', iStudy);
    if ~isempty(Channel)
        ChannelFile = Channel.FileName;
    else
        ChannelFile = '';
    end
end


%% ===== LOAD CHANNEL FILE =====
function LoadChannelFile(iDS, ChannelFile)
    global GlobalData;
    % If a channel file is defined
    if ~isempty(ChannelFile)
        % Load channel
        ChannelMat = in_bst_channel(ChannelFile);
        % Check coherence between Channel and Measures.F dimensions
        nChannels = length(ChannelMat.Channel);
        nDataChan = length(GlobalData.DataSet(iDS).Measures.ChannelFlag);
        if (nDataChan > 0) && (nDataChan ~= nChannels)
            error('Number of channels in ChannelFile (%d) and DataFile (%d) do not match. Aborting...', nChannels, nDataChan);
        end
        % Save in DataSet structure
        GlobalData.DataSet(iDS).ChannelFile = file_win2unix(ChannelFile);
        GlobalData.DataSet(iDS).Channel     = ChannelMat.Channel; 
        % If extra channel info available (such as head points in FIF format)
        if isfield(ChannelMat, 'HeadPoints')
            GlobalData.DataSet(iDS).HeadPoints = ChannelMat.HeadPoints;
        end
        
    % No channel file: create a fake structure
    elseif ~isempty(GlobalData.DataSet(iDS).Measures.ChannelFlag)
        nChan = length(GlobalData.DataSet(iDS).Measures.ChannelFlag);
        GlobalData.DataSet(iDS).Channel = repmat(db_template('ChannelDesc'), [1 nChan]);
        for i = 1:nChan
            GlobalData.DataSet(iDS).Channel(i).Name = sprintf('E%d', i);
            GlobalData.DataSet(iDS).Channel(i).Loc  = [0;0;0];
            GlobalData.DataSet(iDS).Channel(i).Type = 'EEG';
        end
    end
end


%% ===== LOAD DATA FILE (& CREATE DATASET) =====
% Load all recordings information but the recordings matrix itself (F).
% USAGE:  [iDS, ChannelFile] = LoadDataFile(DataFile, isReloadForced, isTimeCheck)
%         [iDS, ChannelFile] = LoadDataFile(DataFile, isReloadForced)
%         [iDS, ChannelFile] = LoadDataFile(DataFile)
function [iDS, ChannelFile] = LoadDataFile(DataFile, isReloadForced, isTimeCheck)
    global GlobalData;
    % ===== PARSE INPUTS =====
    if (nargin < 3)
        isTimeCheck = 1;
    end
    if (nargin < 2)
        isReloadForced = 0;
    end
    % Get data file information from database
    [sStudy, iData, ChannelFile, FileType] = GetFileInfo(DataFile);
    % Get data type
    switch lower(FileType)
        case 'data'
            DataType = sStudy.Data(iData).DataType;
        case 'pdata'
            DataType = 'stat';
            % Show "stat" tab
            gui_brainstorm('ShowToolTab', 'Stat');
    end

    % ===== LOAD DATA =====
    % Create Measures structure
    Measures = db_template('Measures');
    % Load file description
    if strcmpi(DataType, 'raw')
        % Is loaded dataset
        iDS = GetDataSetData(DataFile, 0);
        % Load file
        if isempty(iDS)
            bst_progress('start', 'Loading raw file', 'Reading file header...');
            MeasuresMat = in_bst_data(DataFile, 'F', 'ChannelFlag', 'ColormapType');
            sFile = MeasuresMat.F;
        else
            MeasuresMat = GlobalData.DataSet(iDS).Measures;
            sFile = MeasuresMat.sFile;
        end
        % Rebuild Time vector
        if ~isempty(sFile.epochs)
            NumberOfSamples = sFile.epochs(1).samples(2) - sFile.epochs(1).samples(1) + 1;
            Time = linspace(sFile.epochs(1).times(1), sFile.epochs(1).times(2), NumberOfSamples);
        else
            NumberOfSamples = sFile.prop.samples(2) - sFile.prop.samples(1) + 1;
            Time = linspace(sFile.prop.times(1), sFile.prop.times(2), NumberOfSamples);
        end
        % Check if file exists
        isRetry = 1;
        while isRetry
            if ~file_exist(sFile.filename)
                % File does not exist: ask the user what to do
                res = java_dialog('question', [...
                    'The following file has been moved, deleted, is used by another program,', 10, ...
                    'or is on a drive that is currently not connected to your computer.' 10 ...
                    'If the file is accessible at another location, click on "Pick file".' 10 10 ...
                    sFile.filename 10 10], ...
                    'Load continuous file', [], {'Pick file...', 'Retry', 'Cancel'}, 'Cancel');
                % Cancel
                if isempty(res) || strcmpi(res, 'Cancel')
                    iDS = [];
                    bst_progress('stop');
                    return;
                end
                % Retry
                if strcmpi(res, 'Retry')
                    continue;
                % Pick file
                else
                    sFile = panel_record('FixFileLink', DataFile, sFile);
                    if isempty(sFile)
                        iDS = [];
                        bst_progress('stop');
                        return;
                    end
                end
            else
                isRetry = 0;
            end
        end
    else
        MeasuresMat = in_bst_data(DataFile, 'Time', 'ChannelFlag', 'ColormapType', 'Events');
        Time = MeasuresMat.Time;
        % Create fake "sFile" structure
        sFile = db_template('sFile');
        % Store events
        if ~isempty(MeasuresMat.Events)
            sFile.events = MeasuresMat.Events;
        else
            sFile.events = repmat(db_template('event'), 0);
        end
        sFile.format       = 'BST';
        sFile.filename     = DataFile;
        sFile.prop.times   = Time([1 end]);
        sFile.prop.sfreq   = 1 ./ (Time(2) - Time(1));
        sFile.prop.samples = round(sFile.prop.times * sFile.prop.sfreq);
    end
    Measures.DataType     = DataType;
    Measures.ChannelFlag  = MeasuresMat.ChannelFlag;
    Measures.sFile        = sFile;
    Measures.ColormapType = MeasuresMat.ColormapType;
    clear MeasuresMat;
    
    % ===== TIME =====
    if (length(Time) > 1)
        % Default time selection: all the samples
        iTime = [1, length(Time)];
        % For raw recordings: limit to the user option
        if strcmpi(DataType, 'raw')
            RawViewerOptions = bst_get('RawViewerOptions', sFile);
            % If current time window can be re-used
            if ~isempty(GlobalData.UserTimeWindow.Time) && (GlobalData.UserTimeWindow.Time(1) >= Time(1)) && (GlobalData.UserTimeWindow.Time(2) <= Time(end))
                iTime = bst_closest(GlobalData.UserTimeWindow.Time, Time);
            elseif (length(Time) > RawViewerOptions.MaxSamples)
                iTime = [1, RawViewerOptions.MaxSamples];
            end
        end
        Measures.Time            = double(Time([iTime(1), iTime(2)])); 
        Measures.SamplingRate    = double(Time(2) - Time(1));
        Measures.NumberOfSamples = iTime(2) - iTime(1) + 1;
    else
        Measures.Time            = [0 0.001]; 
        Measures.SamplingRate    = 0.002;
        Measures.NumberOfSamples = 2;
    end
    
    % ===== EXISTING DATASET ? =====
    % Check if a DataSet already exists for this DataFile
    isStatic = (Measures.NumberOfSamples <= 2);
    iDS = GetDataSetData(DataFile, isStatic);
    if (length(iDS) > 1)
        iDS = iDS(1);
    end
    % If dataset already exist AND IS DEFINED FOR THE RIGHT SUBJECT, just return its index
    if ~isempty(iDS) && ~isReloadForced
        if ~isempty(sStudy.BrainStormSubject) && ~file_compare(sStudy.BrainStormSubject, GlobalData.DataSet(iDS).SubjectFile)
            iDS = [];
        else
            GlobalData.DataSet(iDS).Measures.DataType    = Measures.DataType;
            GlobalData.DataSet(iDS).Measures.ChannelFlag = Measures.ChannelFlag;
            GlobalData.DataSet(iDS).Measures.sFile       = Measures.sFile;
            return
        end
    end
    
    % ===== CHECK FOR OTHER RAW FILES =====
    if strcmpi(DataType, 'raw') && ~isempty(GlobalData.FullTimeWindow) && ~isempty(GlobalData.FullTimeWindow.CurrentEpoch) && ~isReloadForced
        bst_error(['Cannot open two raw viewers at the same time.' 10 'Please close the other windows and retry.'], 'Load data file', 0);
        iDS = [];
        return
    end
    
    % ===== STORE IN GLOBALDATA =====
    % Look for a DataSet that have been partly initialized for this study 
    % IE. StudyFile was defined but not DataFile (ie. a Channel or Result DataSet)
    if isempty(iDS) && ~isempty(sStudy.FileName) 
        iDS = GetDataSetStudyNoData(sStudy.FileName);
        if (length(iDS) > 1)
            iDS = iDS(1);
        end
    end
    % If no DataSet is available for this data file
    if isempty(iDS)
        % Create new dataset
        iDS = length(GlobalData.DataSet) + 1;
        GlobalData.DataSet(iDS) = db_template('DataSet');
    end
    % Store DataSet in GlobalData
    GlobalData.DataSet(iDS).SubjectFile = file_short(sStudy.BrainStormSubject);
    GlobalData.DataSet(iDS).StudyFile   = file_short(sStudy.FileName);
    GlobalData.DataSet(iDS).DataFile    = file_short(DataFile);
    GlobalData.DataSet(iDS).Measures    = Measures;
    
    % ===== LOAD CHANNEL FILE =====
    LoadChannelFile(iDS, ChannelFile);
    
    % ===== Check time window consistency with previously loaded data =====
    if isTimeCheck
        % Update time window
        isTimeCoherent = CheckTimeWindows();
        % If loaded data is not coherent with previous data
        if ~isTimeCoherent
            bst_error(['Time definition for this file is not compatible with the other files' 10 ...
                       'already loaded in Brainstorm.' 10 10 ...
                       'Close existing windows before opening this file, or use the Navigator.'], 'Load recordings', 0);
            % Remove it
            UnloadDataSets(iDS);
            %GlobalData.DataSet(iDS) = [];
            iDS = [];
            return;
        end
    end
    
    % ===== UPDATE TOOL TABS =====
    if ~isempty(iDS) && strcmpi(GlobalData.DataSet(iDS).Measures.DataType, 'raw')
        % Initialize tab with new RAW information
        panel_record('InitializePanel');
    end
    panel_cluster('UpdatePanel');
    panel_time('UpdatePanel');
end


%% ===== GET RAW DATASET =====
function iDS = GetRawDataSet() %#ok<DEFNU>
    global GlobalData;
    iDS = [];
    % No raw data loaded
    if isempty(GlobalData.FullTimeWindow) || isempty(GlobalData.FullTimeWindow.CurrentEpoch)
        return
    end
    % Look for the raw data loaded in all the datasets
    for i = 1:length(GlobalData.DataSet)
        if isequal(GlobalData.DataSet(i).Measures.DataType, 'raw')
            iDS = i;
            return;
        end
    end
end

    
%% ===== LOAD F MATRIX FOR A GIVEN DATA FILE =====
% Load the F matrix for a dataset that has already been pre-loaded (with LoadDataFile)
function LoadRecordingsMatrix(iDS)
    global GlobalData;
    % Check dataset index integrity
    if (iDS <= 0) || (iDS > length(GlobalData.DataSet))
        error('Invalid DataSet index : %d', iDS);
    end   
    % Relative filename : add the SUBJECTS path
    DataFile = file_fullpath(GlobalData.DataSet(iDS).DataFile);
    
    % Load F Matrix
    if strcmpi(GlobalData.DataSet(iDS).Measures.DataType, 'stat')
        % Load stat file
        StatMat = in_bst_data(DataFile, 'pmap', 'tmap', 'df');
        % Apply threshold
        GlobalData.DataSet(iDS).Measures.F = process_extract_pthresh('Compute', StatMat);
    else
        % If RAW file: load a block from the file
        if strcmpi(GlobalData.DataSet(iDS).Measures.DataType, 'raw')
            DataMat.F = LoadRecordingsRaw(iDS);
            % If not data could be loaded from the file: return
            if isempty(DataMat.F)
                return
            end   
        % Else: Load data file
        else
            DataMat = in_bst_data(DataFile, 'F');
        end

        % ===== APPLY FILTERING =====
        DataMat.F = FilterLoadedData(DataMat.F, iDS);

        % If data was loaded : store it in GlobalData
        if ~isempty(DataMat.F)
             GlobalData.DataSet(iDS).Measures.F = double(DataMat.F);
        end
    end
    % If there is only one time sample : copy it to get 2 time samples
    if (size(GlobalData.DataSet(iDS).Measures.F, 2) == 1)
        GlobalData.DataSet(iDS).Measures.F = repmat(GlobalData.DataSet(iDS).Measures.F, [1,2]);
    end
end


%% ===== LOAD RAW DATA ====
% Load a block of 
function F = LoadRecordingsRaw(iDS)
    global GlobalData;
    % Get values data to read
    iEpoch    = GlobalData.FullTimeWindow.CurrentEpoch;
    TimeRange = GlobalData.DataSet(iDS).Measures.Time;
    % Get raw viewer options
    RawViewerOptions = bst_get('RawViewerOptions');
    % Read data block
    F = panel_record('ReadRawBlock', GlobalData.DataSet(iDS).Measures.sFile, iEpoch, TimeRange, 1, RawViewerOptions.UseCtfComp, RawViewerOptions.RemoveBaseline);
end


%% ===== FILTER LOADED DATA =====
function F = FilterLoadedData(F, iDS)
    global GlobalData;
    isLowPass    = GlobalData.VisualizationFilters.LowPassEnabled;
    isHighPass   = GlobalData.VisualizationFilters.HighPassEnabled;
    isSinRemoval = GlobalData.VisualizationFilters.SinRemovalEnabled;
    isMirror     = GlobalData.VisualizationFilters.MirrorEnabled;
    % Get time vector
    nTime = size(F,2);
    if (isHighPass || isLowPass || isSinRemoval) && (nTime > 2)
        TimeVector = GetTimeVector(iDS);
    end
    % Band-pass filter is active: apply it (only if real recordings => ignore time averages)
    if (isHighPass || isLowPass) && (nTime > 2)
        % LOW-PASS
        if ~isLowPass || isequal(GlobalData.VisualizationFilters.LowPassValue, 0)
            LowPass = [];
        else
            LowPass = GlobalData.VisualizationFilters.LowPassValue;
        end
        % HI-PASS
        if ~isHighPass || isequal(GlobalData.VisualizationFilters.HighPassValue, 0)
            HighPass = [];
        else
            HighPass = GlobalData.VisualizationFilters.HighPassValue;
        end
        % Check if bounds are correct
        if ~isempty(HighPass) && ~isempty(LowPass) && (HighPass == LowPass)
            errordlg('Please check the filter settings before loading data', 'Display error');
        end        
        % Filter data
        F = process_bandpass('Compute', F, TimeVector, HighPass, LowPass, [], isMirror);
    end
    % Sin removal filter is active
    if isSinRemoval && ~isempty(GlobalData.VisualizationFilters.SinRemovalValue) && (nTime > 2)
        % Filter data
        F = process_sin_remove('Compute', F, TimeVector, GlobalData.VisualizationFilters.SinRemovalValue, [], isMirror);
    end
end

%% ===== RELOAD ALL DATA FILES ======
% Reload all the data files.
% (needed for instance after changing the visualization filters parameters).
function ReloadAllDataSets() %#ok<DEFNU>
    global GlobalData;
    % Process all the loaded datasets
    for iDS = 1:length(GlobalData.DataSet)
        % If F matrix is loaded: reload it
        if ~isempty(GlobalData.DataSet(iDS).Measures.F)
            LoadRecordingsMatrix(iDS);
        end
        % For the FULL sources: reload source time series
        for iRes = 1:length(GlobalData.DataSet(iDS).Results)
            if ~isempty(GlobalData.DataSet(iDS).Results(iRes).ImageGridAmp)
                LoadResultsMatrix(iDS, iRes);
            end
        end
    end
end


%% ===== RELOAD STAT DATA FILES ======
% Reload all the stat files.
% (needed for instance after changing the statistical thresholding options).
function ReloadStatDataSets() %#ok<DEFNU>
    global GlobalData;
    % Process all the loaded datasets
    for iDS = 1:length(GlobalData.DataSet)
        % If F matrix is loaded: reload it
        if ~isempty(GlobalData.DataSet(iDS).Measures.F) && strcmpi(GlobalData.DataSet(iDS).Measures.DataType, 'stat')
            LoadRecordingsMatrix(iDS);
        end
%         % Go through the results files
%         for iRes = 1:length(GlobalData.DataSet(iDS).Results)
%             % Reload the full results
%             if ~isempty(GlobalData.DataSet(iDS).Results(iRes).ImageGridAmp)
%                 bst_memory('LoadResultsMatrix', iDS, iRes);
%             end
%         end
        % Go through the timefreq files
        for iTf = 1:length(GlobalData.DataSet(iDS).Timefreq)
             fileType = file_gettype(GlobalData.DataSet(iDS).Timefreq(iTf).FileName);
             if strcmpi(fileType, 'ptimefreq')
                 LoadTimefreqFile(GlobalData.DataSet(iDS).Timefreq(iTf).FileName, 0, 0, 1);
             end
        end
    end
end


%% ===== LOAD RESULT FILE (& CREATE DATASET) =====
% Load result file (some informative fields, not all the calculated matrices)
% Usage :  [iDS, iResult] = LoadResultsFile(ResultsFile)
%          [iDS, iResult] = LoadResultsFile(ResultsFile) 
function [iDS, iResult] = LoadResultsFile(ResultsFile, isTimeCheck)
    global GlobalData;
    if (nargin < 2)
        isTimeCheck = 1;
    end
    % Initialize returned values
    iResult  = [];
    
    % ===== GET FILE INFORMATION =====
    % Get file information
    [sStudy, iFile, ChannelFile, FileType] = GetFileInfo(ResultsFile);
    % Get associated data file
    switch(FileType)
        case {'results', 'link'}
            DataFile = sStudy.Result(iFile).DataFile;
            isLink = sStudy.Result(iFile).isLink;
            DataType = 'results';
        case 'presults'
            DataFile = sStudy.Stat(iFile).DataFile;
            isLink = 0;
            DataType = 'stat';
    end
    % Make relative filenames
    if ~isLink
        ResultsFile = file_short(ResultsFile);
    end
    % Resolve link
    ResultsFullFile = file_resolve_link( ResultsFile );    
    % Get variables list
    File_whos = whos('-file', ResultsFullFile);
    
    % ===== Is Result file is already loaded ? ====
    % If Result file is dependent from a Data file
    if ~isempty(DataFile)
        % Load (or simply get) DataSet associated with DataFile
        isForceReload = isLink;
        iDS = LoadDataFile(DataFile, isForceReload);
        % If error loading the data file
        if isempty(iDS)
            return;
        end
        % Check if result file is already loaded in this DataSet
        iResult = GetResultInDataSet(iDS, ResultsFile);
    else
        % Check if result file is already loaded in this DataSet
        [iDS, iResult] = GetDataSetResult(ResultsFile);
    end
    % If dataset for target ResultsFile already exists, just return its index
    if ~isempty(iDS) && ~isempty(iResult)
        return
    end
    
    % ===== If Result file need and independent DataSet structure =====
    if isempty(iDS)
        % Create a new DataSet only for results
        iDS = length(GlobalData.DataSet) + 1;
        GlobalData.DataSet(iDS)             = db_template('DataSet');
        GlobalData.DataSet(iDS).DataFile    = '';
    end
    GlobalData.DataSet(iDS).SubjectFile = file_short(sStudy.BrainStormSubject);
    GlobalData.DataSet(iDS).StudyFile   = file_short(sStudy.FileName);
    
    % === NORMAL RESULTS FILE ===
    if any(strcmpi('ImageGridAmp', {File_whos.name}))
        % Load results .Mat
        ResultsMat = in_bst_results(ResultsFullFile, 0, 'Comment', 'Time', 'ChannelFlag', 'HeadModelType', 'ColormapType', 'GoodChannel', 'Atlas');
        % If Time does not exist, try to rebuild it
        if isempty(ResultsMat.Time)
            % If DataSet.Measures is empty (if no data was loaded)
            if isempty(GlobalData.DataSet(iDS).Measures.Time)
                % It is impossible to reconstruct the time vector => impossible to load ResultsFile
                error(['Missing time information (Time or recordings file) for file "' ResultsFile '".']);
            else
                % If Time vector is defined in results (indices in initial Data time vector)
                if ~isempty(ResultsMat.Time)
                    Time = ResultsMat.Time;
                % Else: Rebuild Measures time vector
                else
                    Time = linspace(GlobalData.DataSet(iDS).Measures.Time(1), ...
                                    GlobalData.DataSet(iDS).Measures.Time(end), ...
                                    GlobalData.DataSet(iDS).Measures.NumberOfSamples);
                end
            end
        % Else: use Time vector from file
        else
            Time = ResultsMat.Time;
        end
    % === STAT ON RESULTS ===
    elseif all(ismember({'Comment', 'Time', 'tmap', 'ChannelFlag'}, {File_whos.name}))
        % Show stat tab
        gui_brainstorm('ShowToolTab', 'Stat');
        % Load results .Mat
        ResultsMat = in_bst_results(ResultsFullFile, 0, 'Comment', 'Time', 'ChannelFlag', 'HeadModelType', 'ColormapType', 'GoodChannel', 'Atlas');
        Time = ResultsMat.Time;
    else
        error('File does not follow Brainstorm file format.');
    end
    
    % ===== Create new Results entry =====
    % Create Results structure
    Results = db_template('LoadedResults');
    % Copy information
    Results.FileName        = file_win2unix(ResultsFile);
    Results.DataType        = DataType;
    Results.HeadModelType   = ResultsMat.HeadModelType;
    Results.Comment         = ResultsMat.Comment;
    Results.Time            = Time([1, end]);
    Results.NumberOfSamples = length(Time);
    Results.SamplingRate    = Time(2)-Time(1);
    Results.ColormapType    = ResultsMat.ColormapType;
    Results.Atlas           = ResultsMat.Atlas;
    % If channel flag not specified in results (pure kernel file)
    if isempty(ResultsMat.ChannelFlag) && ~isempty(GlobalData.DataSet(iDS).Measures.ChannelFlag) 
        Results.ChannelFlag = GlobalData.DataSet(iDS).Measures.ChannelFlag;
    else
        Results.ChannelFlag = ResultsMat.ChannelFlag;
    end
    % If GoodChannel not specified, consider that is is all the channels
    if isempty(ResultsMat.GoodChannel)
        Results.GoodChannel = 1:length(Results.ChannelFlag);
    else
        Results.GoodChannel = ResultsMat.GoodChannel;
    end
    
    % Store new Results structure in GlobalData
    iResult = length(GlobalData.DataSet(iDS).Results) + 1;
    GlobalData.DataSet(iDS).Results(iResult) = Results;
    
    % ===== LOAD CHANNEL FILE =====
    if ~isempty(ChannelFile)
        LoadChannelFile(iDS, ChannelFile);
    end
    
    % ===== Check time window consistency with previously loaded result =====
    % Save measures information if no DataFile is available
    % Create Measures structure
    if isempty(GlobalData.DataSet(iDS).Measures) || isempty(GlobalData.DataSet(iDS).Measures.Time)
        GlobalData.DataSet(iDS).Measures.Time            = double(Results.Time); 
        GlobalData.DataSet(iDS).Measures.SamplingRate    = double(Results.SamplingRate);
        GlobalData.DataSet(iDS).Measures.NumberOfSamples = Results.NumberOfSamples;
        if isempty(GlobalData.DataSet(iDS).Measures.ChannelFlag) || (length(GlobalData.DataSet(iDS).Measures.ChannelFlag) ~= length(Results.ChannelFlag))
            GlobalData.DataSet(iDS).Measures.ChannelFlag = Results.ChannelFlag;
        end
    end
    % Update time window
    if isTimeCheck
        isTimeCoherent = CheckTimeWindows();
        % If loaded results are not coherent with previous data
        if ~isTimeCoherent
            % Remove it
            GlobalData.DataSet(iDS).Results(iResult) = [];
            iDS = [];
            iResult  = [];
            bst_error(['Time definition for this file is not compatible with the other files' 10 ...
                       'already loaded in Brainstorm.' 10 10 ...
                       'Close existing windows before opening this file, or use the Navigator.'], 'Load results', 0);
            return
        end
    end
    % Update TimeWindow panel, if it exists
    panel_time('UpdatePanel');
end



%% ===== LOAD RESULTS MATRIX =====
% Load the calculated matrices for a Results entry in a given dataset
% Results entry must have already been pre-loaded (with LoadResultsFile)
function LoadResultsMatrix(iDS, iResult)
    global GlobalData;
    % Check dataset and result indices integrity
    if (iDS <= 0) || (iDS > length(GlobalData.DataSet))
        error('Invalid DataSet index : %d', iDS);
    end
    if (iResult <= 0) || (iResult > length(GlobalData.DataSet(iDS).Results))
        error('Invalid Results index : %d', iResult);
    end
    
    % === NORMAL RESULTS ===
    if ~strcmpi(GlobalData.DataSet(iDS).Results(iResult).DataType, 'stat')
        % Load results matrix
        ResultsFile = GlobalData.DataSet(iDS).Results(iResult).FileName;
        ResultsMat  = in_bst_results(ResultsFile, 0, 'ImageGridAmp', 'ImagingKernel', 'nComponents', 'GridLoc', 'OpticalFlow', 'ZScore');   
        % FULL RESULTS MATRIX
        if isfield(ResultsMat, 'ImageGridAmp') && ~isempty(ResultsMat.ImageGridAmp)
            % Apply online filters 
            ResultsMat.ImageGridAmp = FilterLoadedData(ResultsMat.ImageGridAmp, iDS);
            % Store results in memory
            GlobalData.DataSet(iDS).Results(iResult).ImageGridAmp  = ResultsMat.ImageGridAmp; % FT 11-Jan-10: Remove "single"
            GlobalData.DataSet(iDS).Results(iResult).ImagingKernel = [];
            GlobalData.DataSet(iDS).Results(iResult).OpticalFlow   = ResultsMat.OpticalFlow;
        % KERNEL ONLY
        elseif isfield(ResultsMat, 'ImagingKernel') && ~isempty(ResultsMat.ImagingKernel)
            GlobalData.DataSet(iDS).Results(iResult).ImageGridAmp  = [];
            GlobalData.DataSet(iDS).Results(iResult).ImagingKernel = ResultsMat.ImagingKernel; % FT 11-Jan-10: Remove "single"
            GlobalData.DataSet(iDS).Results(iResult).ZScore        = ResultsMat.ZScore;
            % Make sure that recordings matrix is loaded
            if isempty(GlobalData.DataSet(iDS).Measures.F)
                LoadRecordingsMatrix(iDS);
            end
        % ERROR
        else
            error(['Invalid results file : ' GlobalData.DataSet(iDS).Results(iResult).FileName]);
        end
        GlobalData.DataSet(iDS).Results(iResult).nComponents = ResultsMat.nComponents;
        GlobalData.DataSet(iDS).Results(iResult).GridLoc     = ResultsMat.GridLoc;

    % === STAT/RESULTS FILE ===
    else
        % Load stat matrix
        StatFile = GlobalData.DataSet(iDS).Results(iResult).FileName;
        StatMat = in_bst_results(StatFile, 0, 'pmap', 'tmap', 'df', 'nComponents', 'GridLoc');
        % Do not allow stat with more than one component
        if (StatMat.nComponents > 1)
            error('The display of statistical maps for unconstrained source models is not supported yet.');
        end
        % Store results in GlobalData
        GlobalData.DataSet(iDS).Results(iResult).ImageGridAmp  = process_extract_pthresh('Compute', StatMat);
        GlobalData.DataSet(iDS).Results(iResult).ImagingKernel = [];
        GlobalData.DataSet(iDS).Results(iResult).nComponents   = StatMat.nComponents;
        GlobalData.DataSet(iDS).Results(iResult).GridLoc       = StatMat.GridLoc;
    end
end


%% ===== LOAD RESULTS : FULL LOAD & CHECK =====
function [iDS, iResult] = LoadResultsFileFull(ResultsFile)
    global GlobalData;
    % Load Results file
    [iDS, iResult] = LoadResultsFile(ResultsFile);
    % Check if dataset was not created
    if isempty(iDS) || isempty(iResult)
        bst_progress('stop');
        iDS = [];
        iResult = [];
        return;
    end
    % Check if results ImageGridAmp matrix is already loaded
    if isempty(GlobalData.DataSet(iDS).Results(iResult).ImageGridAmp) ...
            && isempty(GlobalData.DataSet(iDS).Results(iResult).ImagingKernel)
        % Load associated matrix
        LoadResultsMatrix(iDS, iResult);
    end
    % Check again if restults matrix was loaded
    if isempty(GlobalData.DataSet(iDS).Results(iResult).ImageGridAmp) ...
            && isempty(GlobalData.DataSet(iDS).Results(iResult).ImagingKernel)
        bst_progress('stop');
        error('Results matrix is not loaded or empty');
    end
end


%% ===== LOAD DIPOLES FILE =====
function [iDS, iDipoles] = LoadDipolesFile(DipolesFile, isTimeCheck) %#ok<DEFNU>
    global GlobalData;
    if (nargin < 2)
        isTimeCheck = 1;
    end
    % Show dipoles tab
    gui_brainstorm('ShowToolTab', 'Dipoles');

    % ===== GET ALL INFORMATION =====
    % Check whether file paths are absolute or relative
    if file_exist(DipolesFile)
        % Absolute filename (set from outside the GUI)
        DipolesFullFile = DipolesFile;
        DipolesFile = file_short(DipolesFile);
    else
        % Relative filename : add the STUDIES path
        DipolesFullFile = file_fullpath(DipolesFile);
    end
    % Get file information
    [sStudy, iDip, ChannelFile] = GetFileInfo(DipolesFile);

    % ===== ARE DIPOLES ALREADY LOADED ? ====
    % If Dipoles file is dependent from a Data file
%     DataFile = sStudy.Dipoles(iDip).DataFile;
%     if ~isempty(DataFile)
%         % Load (or simply get) DataSet associated with DataFile
%         isForceReload = 0;
%         iDS = LoadDataFile(DataFile, isForceReload);
%         % If DataSet exists or was successfully created
%         if ~isempty(iDS)
%             % Check if file is already loaded in this DataSet
%             iDipoles = GetDipolesInDataSet(iDS, DipolesFile);
%         end
%     else
        % Check if file is already loaded in this DataSet
        [iDS, iDipoles] = GetDataSetDipoles(DipolesFile);
%     end
    % If dataset for target file already exists, just return its index
    if ~isempty(iDS) && ~isempty(iDipoles)
        return
    end
    
    % ===== GET/CREATE A NEW DATASET =====
    % Get dataset with same study
    if isempty(iDS)
        iDS = GetDataSetStudy(sStudy.FileName);
    end
    % StudyFile not found in DataSets, try SubjectFile
    if isempty(iDS)
        iDS = GetDataSetSubject(sStudy.BrainStormSubject, 0);
        % Do not accept DataSet if an other DataFile is already attributed to the DataSet
        iDS = iDS(cellfun(@(c)isempty(c), {GlobalData.DataSet(iDS).DataFile}));
    end
    % Create dataset
    if isempty(iDS)
        % Create a new DataSet only for results
        iDS = length(GlobalData.DataSet) + 1;
        GlobalData.DataSet(iDS)             = db_template('DataSet');
        GlobalData.DataSet(iDS).SubjectFile = file_short(sStudy.BrainStormSubject);
    end
    if isempty(iDipoles)
        GlobalData.DataSet(iDS).StudyFile   = file_short(sStudy.FileName);
        GlobalData.DataSet(iDS).ChannelFile = file_short(ChannelFile);
        GlobalData.DataSet(iDS).DataFile    = '';
    end
    % Make sure that there is only one dataset selected
    iDS = iDS(1);
    
    % ===== LOAD DIPOLES FILE =====
    % Load results .Mat
    DipolesMat = load(DipolesFullFile);
    Time = DipolesMat.Time;
    if length(Time) == 1 %only one dipole, add artifical temporal dimension
        Time = [Time Time+0.001];
    end
    
    % Backward compatible with dipole files that do not have subsets...
    if ~isfield(DipolesMat, 'Subset')
        DipolesMat.Subset = [];
    end
    
    % Backward compatible with dipole files that do not have all fields...
    if ~isfield(DipolesMat.Dipole, 'Khi2')
        DipolesMat.Dipole(end).Khi2 = [];
    end
    if ~isfield(DipolesMat.Dipole, 'DOF')
        DipolesMat.Dipole(end).DOF = [];
    end
    if ~isfield(DipolesMat.Dipole, 'ConfVol')
        DipolesMat.Dipole(end).ConfVol = [];
    end
    if ~isfield(DipolesMat.Dipole, 'Perform')
        DipolesMat.Dipole(end).Perform = [];
    end
    
    % ===== CREATE NEW DIPOLES ENTRY =====
    % Create structure
    Dipoles = db_template('LoadedDipoles');
    % Copy information
    Dipoles.FileName        = DipolesFile;
    Dipoles.Comment         = DipolesMat.Comment;
    Dipoles.Dipole          = DipolesMat.Dipole;
    Dipoles.DipoleNames     = DipolesMat.DipoleNames;
    Dipoles.Time            = Time([1, end]);
    Dipoles.NumberOfSamples = length(Time);
    Dipoles.SamplingRate    = Time(2)-Time(1);
    Dipoles.Subset          = DipolesMat.Subset;
    % Store new Results structure in GlobalData
    iDipoles = length(GlobalData.DataSet(iDS).Dipoles) + 1;
    GlobalData.DataSet(iDS).Dipoles(iDipoles) = Dipoles;  
    
    % ===== Check time window consistency with previously loaded files =====
    % Save measures information if no DataFile is available
    % Create Measures structure
    if isempty(GlobalData.DataSet(iDS).Measures) || isempty(GlobalData.DataSet(iDS).Measures.Time)
        GlobalData.DataSet(iDS).Measures.Time            = double(Dipoles.Time); 
        GlobalData.DataSet(iDS).Measures.SamplingRate    = double(Dipoles.SamplingRate);
        GlobalData.DataSet(iDS).Measures.NumberOfSamples = Dipoles.NumberOfSamples;
    end
    if isTimeCheck
        % Update time window
        isTimeCoherent = CheckTimeWindows();
        % If loaded results are not coherent with previous data
        if ~isTimeCoherent
            % Remove it
            GlobalData.DataSet(iDS).Dipoles(iDipoles) = [];
            iDS = [];
            iDipoles  = [];
            bst_error(['Time definition for this file is not compatible with the other files' 10 ...
                       'already loaded in Brainstorm.' 10 10 ...
                       'Close existing windows before opening this file, or use the Navigator.'], 'Load dipoles', 0);
            return
        end
    end
    % Update TimeWindow panel
    panel_time('UpdatePanel');
end
    

%% ===== LOAD TIME-FREQ FILE =====
function [iDS, iTimefreq, iResults] = LoadTimefreqFile(TimefreqFile, isTimeCheck, isLoadResults, isForceReload, PacOption)
    global GlobalData;
    if (nargin < 5) || isempty(PacOption)
        PacOption = '';   % {'MaxPAC'='', 'DynamicPAC', 'DynamicNesting'}
    end
    if (nargin < 4) || isempty(isForceReload)
        isForceReload = 0;
    end
    if (nargin < 3) || isempty(isLoadResults)
        isLoadResults = 0;
    end
    if (nargin < 2) || isempty(isTimeCheck)
        isTimeCheck = 1;
    end

    % ===== GET ALL INFORMATION =====
    % Get file information
    [sStudy, iTf, ChannelFile, FileType, sItem] = GetFileInfo(TimefreqFile);
    TimefreqMat = in_bst_timefreq(TimefreqFile, 0, 'DataType');
    % Get DataFile
    TimefreqFile = sItem.FileName;
    ParentFile = sItem.DataFile;
    
    % ===== IS FILE ALREADY LOADED ? ====
    iDS      = [];
    iResults = [];
    DataFile = '';
    if ~isempty(ParentFile)
        switch (TimefreqMat.DataType)
            case 'data'
                DataFile = ParentFile;
                % Load (or simply get) DataSet associated with DataFile
                % isForceReload = 0;
                % iDS = LoadDataFile(DataFile, isForceReload);
            case 'results'
                % Get data file associated with the results file
                [sStudy,iStudy,iRes] = bst_get('ResultsFile', ParentFile);
                DataFile = sStudy.Result(iRes).DataFile;
                % Load (or simply get) DataSet associated with ResultsFile
                if isLoadResults || ~isempty(strfind(TimefreqFile, '_KERNEL_'))
                    [iDS, iResults] = LoadResultsFileFull(ParentFile);
                end
            case {'cluster', 'scout', 'matrix'}
                % Load (or simply get) DataSet associated with MatrixFile
                % iDS = LoadMatrixFile(ParentFile);
        end
    end
    % Force DataFile to be a string, and not a double empty matrix
    if isempty(DataFile)
        DataFile = '';
    end
    % Load timefreq file
    if ~isempty(iDS)
        iTimefreq = GetTimefreqInDataSet(iDS, TimefreqFile);
    else
        [iDS, iTimefreq] = GetDataSetTimefreq(TimefreqFile);
    end
    % If dataset for target file already exists, just return its index
    if ~isForceReload && ~isempty(iDS) && ~isempty(iTimefreq)
        return
    end
    
    % ===== LOAD TIME-FREQ FILE =====
    isStat = strcmpi(FileType, 'ptimefreq');
    if ~isStat
        % Load .Mat
        TimefreqMat = in_bst_timefreq(TimefreqFile, 0, 'TF', 'Time', 'Freqs', 'DataFile', 'DataType', 'Comment', 'TimeBands', 'RowNames', 'RefRowNames', 'Measure', 'Method', 'Options', 'ColormapType', 'Atlas', 'SurfaceFile', 'sPAC', 'GridLoc');
        % Load inverse kernel that goes with it if applicable
        if ~isempty(ParentFile) && strcmpi(TimefreqMat.DataType, 'results') && (size(TimefreqMat.TF,1) < length(TimefreqMat.RowNames))
            [iDS, iResults] = LoadResultsFileFull(ParentFile);
        end
    else
        % Load stat matrix
        TimefreqMat = in_bst_timefreq(TimefreqFile, 0, 'pmap', 'tmap', 'df', 'Time', 'Freqs', 'DataFile', 'DataType', 'Comment', 'TF', 'TimeBands', 'RowNames', 'RefRowNames', 'Measure', 'Method', 'Options', 'ColormapType', 'Atlas', 'SurfaceFile', 'sPAC', 'GridLoc');
        % Report thresholded maps
        TimefreqMat.TF = process_extract_pthresh('Compute', TimefreqMat);
        % Open the "Stat" tab
        gui_brainstorm('ShowToolTab', 'Stat');
    end
    % Replace some fields for DynamicPAC 
    if isequal(PacOption, 'DynamicPAC')
        TimefreqMat.TF = TimefreqMat.sPAC.DynamicPAC;
        TimefreqMat.Freqs = TimefreqMat.sPAC.HighFreqs;
    elseif isequal(PacOption, 'DynamicNesting')
        TimefreqMat.TF = TimefreqMat.sPAC.DynamicNesting;
        TimefreqMat.Freqs = TimefreqMat.sPAC.HighFreqs;
    end
    % If Freqs matrix is not well oriented
    if ~iscell(TimefreqMat.Freqs) && (size(TimefreqMat.Freqs, 1) > 1)
        TimefreqMat.Freqs = TimefreqMat.Freqs';
    end
    % Show frequency slider
    isStaticFreq = (size(TimefreqMat.TF,3) <= 1);
    if ~isStaticFreq
        gui_brainstorm('ShowToolTab', 'FreqPanel');
    end
    
    % ===== CHECK FREQ COMPATIBILITY =====
    isFreqOk = 1;
    % Do not check if new files has no Frequency definition (Freqs = 1 value, or empty)
    if (length(TimefreqMat.Freqs) >= 2)
        if isempty(GlobalData.UserFrequencies.Freqs)
            GlobalData.UserFrequencies.Freqs = TimefreqMat.Freqs;
            % Update time-frenquecy panel
            panel_freq('UpdatePanel');
        elseif ~isempty(TimefreqMat.Freqs) && ~isequal(GlobalData.UserFrequencies.Freqs, TimefreqMat.Freqs)
            if iscell(GlobalData.UserFrequencies.Freqs) && iscell(TimefreqMat.Freqs) && isequal(GlobalData.UserFrequencies.Freqs(:,1), TimefreqMat.Freqs(:,1))
                isFreqOk = 1;
            elseif ~iscell(GlobalData.UserFrequencies.Freqs) && ~iscell(TimefreqMat.Freqs) && (length(GlobalData.UserFrequencies.Freqs) == length(TimefreqMat.Freqs)) && ...
                    all(abs(GlobalData.UserFrequencies.Freqs - TimefreqMat.Freqs) < 1e-5)
                isFreqOk = 1;
            else
                isFreqOk = 0;
            end
        else
            GlobalData.UserFrequencies.Freqs = TimefreqMat.Freqs;
        end
        % Error message if it doesn't match
        if ~isFreqOk
            bst_error(['Frequency definition for this file is not compatible with the other files' 10 ...
                       'already loaded in Brainstorm.' 10 10 ...
                       'Close existing windows before opening this file, or use the Navigator.'], 'Load time-frequency', 0);
            iDS = [];
            iTimefreq = [];
            iResults = [];
            return
        end
        % Current frequency
        if isempty(GlobalData.UserFrequencies.iCurrentFreq)
            GlobalData.UserFrequencies.iCurrentFreq = 1;
            panel_freq('UpdatePanel');
        end
    end
    
    % ===== GET/CREATE A NEW DATASET =====
    % Create dataset
    if isempty(iDS)
        % Create a new DataSet only for results
        iDS = length(GlobalData.DataSet) + 1;
        GlobalData.DataSet(iDS)             = db_template('DataSet');
        GlobalData.DataSet(iDS).SubjectFile = file_win2unix(sStudy.BrainStormSubject);
        GlobalData.DataSet(iDS).StudyFile   = file_win2unix(sStudy.FileName);
        GlobalData.DataSet(iDS).ChannelFile = file_win2unix(ChannelFile);
        GlobalData.DataSet(iDS).DataFile    = DataFile;
    end
    % Make sure that there is only one dataset selected
    iDS = iDS(1);
    
    % ===== CREATE A FAKE RESULT FOR GRID LOC =====
    % This is specifically for the case of timefreq files calculated on volume source grids, without a ParentFile
    % => In this case, the location of the source points is saved in GridLoc
    if ~isempty(TimefreqMat.GridLoc) && isempty(ParentFile)
        % Fake results file
        ParentFile = strrep(TimefreqFile, '.mat', '$.mat');
        TimefreqMat.DataFile = ParentFile;
        % Create new fake structure
        iResults = length(GlobalData.DataSet(iDS).Results) + 1;
        GlobalData.DataSet(iDS).Results(iResults) = db_template('LoadedResults');
        GlobalData.DataSet(iDS).Results(iResults).FileName        = ParentFile;
        GlobalData.DataSet(iDS).Results(iResults).DataType        = 'results';
        GlobalData.DataSet(iDS).Results(iResults).Comment         = [TimefreqMat.Comment '$'];
        GlobalData.DataSet(iDS).Results(iResults).Time            = [TimefreqMat.Time(1), TimefreqMat.Time(end)];
        GlobalData.DataSet(iDS).Results(iResults).SamplingRate    = (TimefreqMat.Time(2) - TimefreqMat.Time(1));
        GlobalData.DataSet(iDS).Results(iResults).NumberOfSamples = length(TimefreqMat.Time);
        GlobalData.DataSet(iDS).Results(iResults).HeadModelType   = 'volume';
        GlobalData.DataSet(iDS).Results(iResults).GridLoc         = TimefreqMat.GridLoc;
        GlobalData.DataSet(iDS).Results(iResults).nComponents     = 3;
    end
    
    % ===== CREATE NEW TIMEFREQ ENTRY =====
    % Create structure
    Timefreq = db_template('LoadedTimefreq');
    % Copy information
    Timefreq.FileName        = TimefreqFile;
    Timefreq.DataFile        = TimefreqMat.DataFile;
    Timefreq.DataType        = TimefreqMat.DataType;
    Timefreq.Comment         = TimefreqMat.Comment;
    Timefreq.TF              = TimefreqMat.TF;
    Timefreq.Freqs           = TimefreqMat.Freqs;
    Timefreq.Time            = TimefreqMat.Time([1, end]);
    Timefreq.TimeBands       = TimefreqMat.TimeBands;
    Timefreq.RowNames        = TimefreqMat.RowNames;
    Timefreq.RefRowNames     = TimefreqMat.RefRowNames;
    Timefreq.Measure         = TimefreqMat.Measure;
    Timefreq.Method          = TimefreqMat.Method;
    Timefreq.NumberOfSamples = length(TimefreqMat.Time);
    Timefreq.SamplingRate    = TimefreqMat.Time(2) - TimefreqMat.Time(1);
    Timefreq.Options         = TimefreqMat.Options;
    Timefreq.ColormapType    = TimefreqMat.ColormapType;
    Timefreq.SurfaceFile     = TimefreqMat.SurfaceFile;
    Timefreq.Atlas           = TimefreqMat.Atlas;
    Timefreq.sPAC            = TimefreqMat.sPAC;
    
    % ===== EXPAND SYMMETRIC MATRICES =====
    if isfield(Timefreq.Options, 'isSymmetric') && Timefreq.Options.isSymmetric
        Timefreq.TF = process_compress_sym('Expand', Timefreq.TF, length(TimefreqMat.RowNames));
    end
    % Store new Results structure in GlobalData
    if isempty(iTimefreq)
        iTimefreq = length(GlobalData.DataSet(iDS).Timefreq) + 1;
    end
    GlobalData.DataSet(iDS).Timefreq(iTimefreq) = Timefreq;  
    
    % ===== LOAD CHANNEL FILE =====
    if ~isempty(ChannelFile)
        LoadChannelFile(iDS, ChannelFile);
    end

    % ===== DETECT MODALITY =====
    if strcmpi(Timefreq.DataType, 'data')
        uniqueRows = unique(Timefreq.RowNames);
        % Find channels
        iChannels = [];
        for iRow = 1:length(uniqueRows)
            iChan = find(strcmpi({GlobalData.DataSet(iDS).Channel.Name}, uniqueRows{iRow}));
            if ~isempty(iChan)
                iChannels(end+1) = iChan;
            end
        end
        % Detect modality
        Modality = unique({GlobalData.DataSet(iDS).Channel(iChannels).Type});
        % Convert the Neuromag MEG GRAD/MEG MAG, as just "MEG"
        if isequal(Modality, {'MEG GRAD', 'MEG MAG'})
            Modality = {'MEG'};
        end
        % If only one modality: consider it as the "type" of the file
        if (length(Modality) == 1)
            GlobalData.DataSet(iDS).Timefreq(iTimefreq).Modality = Modality{1};
            % If the good/bad channels for the dataset are not defined yet
            if isempty(GlobalData.DataSet(iDS).Measures.ChannelFlag)
                % Set all the channels as good by default
                GlobalData.DataSet(iDS).Measures.ChannelFlag = ones(length(GlobalData.DataSet(iDS).Channel), 1);
                % Set all the channel in the file as good, and the other channels from the same modality as bad
                iChanMod = good_channel(GlobalData.DataSet(iDS).Channel, [], Modality{1});
                iBadChan = setdiff(iChanMod, iChannels);
                if ~isempty(iBadChan)
                    GlobalData.DataSet(iDS).Measures.ChannelFlag(iBadChan) = -1;
                end
            end
        end
    end
    
    % ===== Check time window consistency with previously loaded files =====
    % Save measures information if no DataFile is available
    % Create Measures structure
    if isempty(GlobalData.DataSet(iDS).Measures) || isempty(GlobalData.DataSet(iDS).Measures.Time)
        GlobalData.DataSet(iDS).Measures.Time            = double(Timefreq.Time); 
        GlobalData.DataSet(iDS).Measures.SamplingRate    = double(Timefreq.SamplingRate);
        GlobalData.DataSet(iDS).Measures.NumberOfSamples = Timefreq.NumberOfSamples;
    end
    % Update time window
    if isTimeCheck
        isTimeCoherent = CheckTimeWindows();
        % If loaded results are not coherent with previous data
        if ~isTimeCoherent
            % Remove it
            GlobalData.DataSet(iDS).Timefreq(iTimefreq) = [];
            iDS = [];
            iTimefreq  = [];
            bst_error(['Time definition for this file is not compatible with the other files' 10 ...
                       'already loaded in Brainstorm.' 10 10 ...
                       'Close existing windows before opening this file, or use the Navigator.'], 'Load time-frequency', 0);
            return
        end
    end
    % Update TimeWindow panel
    panel_time('UpdatePanel');
end


%% ===== LOAD TIMEFREQ ROW =====
function iTfNew = LoadTimefreqRow(iDS, iTfRef, RefRowName) %#ok<DEFNU>
    global GlobalData;
    % Get all entries with the same filename
    FileName = GlobalData.DataSet(iDS).Timefreq(iTfRef).FileName;
    iTfAll = find(strcmpi({GlobalData.DataSet(iDS).Timefreq.FileName}, FileName));
    % Loop on them, try to find one with the same unique row name
    iTfNew = [];
    iTfFull = [];
    for i = 1:length(iTfAll)
        uniqueRefRow = unique(GlobalData.DataSet(iDS).Timefreq(iTfAll(i)).RefRowNames);
        if (length(uniqueRefRow) == 1) && strcmpi(uniqueRefRow{1}, RefRowName)
            iTfNew = iTfAll(i);
        elseif (length(uniqueRefRow) > 1)
            iTfFull = iTfAll(i);
        end
    end
    % If full timefreq entry not found: return (cannot create a secondary entry)
    if isempty(iTfFull)
        return;
    end
    % If secondary entry not found: create a new entry
    if isempty(iTfNew)
        % Copy base entry
        iTfNew = length(GlobalData.DataSet(iDS).Timefreq) + 1;
        GlobalData.DataSet(iDS).Timefreq(iTfNew) = GlobalData.DataSet(iDS).Timefreq(iTfFull);
        % Find the target RefRowName
        iSel = find(strcmpi(GlobalData.DataSet(iDS).Timefreq(iTfNew).RefRowNames, RefRowName));
        if isempty(iSel)
            error(['Row "' RefRowName '" not found in target file.']);
        end
        % Add RefRowName to the filename
        GlobalData.DataSet(iDS).Timefreq(iTfNew).FileName    = [GlobalData.DataSet(iDS).Timefreq(iTfNew).FileName '|' RefRowName];
        % Keep only the connections coming from row RefRowName
        GlobalData.DataSet(iDS).Timefreq(iTfNew).RefRowNames = {RefRowName};
        
        error('todo');
%         % Get values
%         [TF, iTimeBands] = bst_memory('GetTimefreqValues', iDS, iTimefreq, [], TfInfo.iFreqs, iTime, TfInfo.Function);
%         % Rebuild connectivity for this row
%         R = GetConnectMatrix(iDS, iTfRef, RefRowName, TF);
%         % Set it as the full loaded data matrix
%         GlobalData.DataSet(iDS).Timefreq(iTfNew).TF = R;
    end
end


%% ===== GET CONNECTIVITY MATRIX =====
function R = GetConnectMatrix(iDS, iTfRef, TF, selRefRow) %#ok<DEFNU>
    global GlobalData;
    % Parse inputs
    if (nargin < 4)
        selRefRow = [];
    end
    % Names of the rows and columns of the connectivity matrix
    RefRowNames = GlobalData.DataSet(iDS).Timefreq(iTfRef).RefRowNames;
    RowNames    = GlobalData.DataSet(iDS).Timefreq(iTfRef).RowNames;
    nTime       = size(TF, 2);
    nFreq       = size(TF, 3);
    % Error: no time allowed
    if (nTime > 1) 
        error('No multiple time or frequencies allowed in this function.');
    end
    % Reshape connectivity matrix: [Nrow x Ncol]
    R = reshape(TF, [length(RefRowNames), length(RowNames), nFreq]);
    % Keep only the selected row
    if ~isempty(selRefRow)
        % Find target row
        iSel = find(strcmpi(selRefRow, RefRowNames));
        if isempty(iSel)
            return
        end
        % Select only the required row
        R = R(iSel, :, :);
        % Reshape in [nRow, nTime, nFreq]
        R = reshape(R, [], 1, nFreq);
    end
end


%% ===== LOAD MATRIX FILE =====
function iDS = LoadMatrixFile(MatFile) %#ok<DEFNU>
    global GlobalData;
    % ===== GET/CREATE A NEW DATASET =====
    % Get study
    sStudy = bst_get('AnyFile', MatFile);
    if isempty(sStudy)
        iDS = [];
        return;
    end
    % Get time definition
    Mat = in_bst_matrix(MatFile, 'Time', 'Events', 'Comment');
    % Look for file in all the datasets
    [iDS, iMatrix] = GetDataSetMatrix(MatFile);
    % Get dataset with same study
    if isempty(iDS) && isempty(Mat.Events)
        iDS = GetDataSetStudy(sStudy.FileName);
    end
    % Create dataset
    if isempty(iDS)
        % Create a new DataSet only for results
        iDS = length(GlobalData.DataSet) + 1;
        GlobalData.DataSet(iDS)             = db_template('DataSet');
        GlobalData.DataSet(iDS).SubjectFile = file_short(sStudy.BrainStormSubject);
        GlobalData.DataSet(iDS).StudyFile   = file_short(sStudy.FileName);
    end
    % Make sure that there is only one dataset selected
    iDS = iDS(1);
 
    % ===== CHECK TIME =====
    % If there time in this file
    if (length(Mat.Time) >= 2)
        isTimeOkDs = 1;
        % Save measures information if no DataFile is available
        if isempty(GlobalData.DataSet(iDS).Measures) || isempty(GlobalData.DataSet(iDS).Measures.Time)
            GlobalData.DataSet(iDS).Measures.Time            = double(Mat.Time([1, end])); 
            GlobalData.DataSet(iDS).Measures.SamplingRate    = double(Mat.Time(2) - Mat.Time(1));
            GlobalData.DataSet(iDS).Measures.NumberOfSamples = length(Mat.Time);
        elseif (abs(Mat.Time(1)   - GlobalData.DataSet(iDS).Measures.Time(1)) > 1e-5) || ...
               (abs(Mat.Time(end) - GlobalData.DataSet(iDS).Measures.Time(2)) > 1e-5) || ...
               ~isequal(length(Mat.Time), GlobalData.DataSet(iDS).Measures.NumberOfSamples)
            isTimeOkDs = 0;
        end
        % Update time window
        isTimeCoherent = CheckTimeWindows();
        % If loaded file are not coherent with previous data
        if ~isTimeCoherent || ~isTimeOkDs
            iDS = [];
            bst_error(['Time definition for this file is not compatible with the other files' 10 ...
                       'already loaded in Brainstorm.' 10 10 ...
                       'Close existing windows before opening this file, or use the Navigator.'], 'Load matrix', 0);
            return
        end
        % Update TimeWindow panel
        panel_time('UpdatePanel');
    end
    
    % ===== REFERENCE FILE =====
    if isempty(iMatrix)
        % Reference matrix file in the dataset
        iMatrix = length(GlobalData.DataSet(iDS).Matrix) + 1;
        GlobalData.DataSet(iDS).Matrix(iMatrix).FileName = MatFile;
        GlobalData.DataSet(iDS).Matrix(iMatrix).Comment  = Mat.Comment;
        % Store events
        if ~isempty(Mat.Events)
            sFile.events = Mat.Events;
        else
            sFile.events = repmat(db_template('event'), 0);
        end
        GlobalData.DataSet(iDS).Measures.sFile = sFile;
    end
end


%% ===== GET RECORDINGS VALUES =====
% USAGE:  DataValues = GetRecordingsValues(iDS, iChannel, iTime, isGradMagScale)
%         DataValues = GetRecordingsValues(iDS, iChannel, 'UserTimeWindow')
%         DataValues = GetRecordingsValues(iDS, iChannel, 'CurrentTimeIndex')
%         DataValues = GetRecordingsValues(iDS, iChannel)                        : Get recordings for UserTimeWindow
%         DataValues = GetRecordingsValues(iDS)                                  : Get all the channels
function DataValues = GetRecordingsValues(iDS, iChannel, iTime, isGradMagScale) %#ok<DEFNU>
    global GlobalData;
    
    % ===== PARSE INPUTS =====
    % Default iChannel: all
    if (nargin < 2) || isempty(iChannel)
        iChannel = 1:length(GlobalData.DataSet(iDS).Channel);
    end
    % Default time values: current user time window
    if (nargin < 3) || isempty(iTime)
        % Static dataset: use the whole time window
        if (GlobalData.DataSet(iDS).Measures.NumberOfSamples <= 2)
            iTime = [1 2];
        % Else: use the current user time window
        else
            iTime = 'UserTimeWindow';
        end
    end
    % Get generic time selections
    if ischar(iTime)
        % iTime possible values: 'UserTimeWindow', 'CurrentTimeIndex'
        [TimeVector, iTime] = GetTimeVector(iDS, [], iTime);
    end
    % Is it needed to apply Gradiometer/Magnetometers scaling factor for Neuromag recordings ?
    if (nargin < 4) || isempty(isGradMagScale)
        isGradMagScale = 1;
    end
    
    % ===== LOAD DATA MATRIX =====
    if isempty(GlobalData.DataSet(iDS).Measures.F)
        LoadRecordingsMatrix(iDS);
    end
    
    % ===== GET RECORDINGS =====
    % If values are loaded in memory
    if ~isempty(GlobalData.DataSet(iDS).Measures.F)
        % Get recording values
        DataValues = GlobalData.DataSet(iDS).Measures.F(iChannel, iTime);
        DataType = GlobalData.DataSet(iDS).Measures.DataType;
        % Gradio/magnetometers scale
        if isGradMagScale && ~isempty(DataType) && ismember(DataType, {'recordings', 'raw'})
            % Scale gradiometers / magnetometers:
            %    - Neuromag: Apply axial factor to MEG GRAD sensors, to convert in fT/cm
            %    - CTF: Apply factor to MEG REF gradiometers
            DataValues = bst_scale_gradmag( DataValues, GlobalData.DataSet(iDS).Channel(iChannel));
        end
    else
        DataValues = [];
    end
end
        

%% ===== GET RESULTS VALUES ======
% USAGE:  [ResultsValues, nComponents, nVert] = GetResultsValues(iDS, iResult, iVertices, ...,             , ApplyOrient)
%         [ResultsValues, nComponents, nVert] = GetResultsValues(iDS, iResult, iVertices, iTime)
%         [ResultsValues, nComponents, nVert] = GetResultsValues(iDS, iResult, iVertices, 'UserTimeWindow')
%         [ResultsValues, nComponents, nVert] = GetResultsValues(iDS, iResult, iVertices, 'CurrentTimeIndex')
%         [ResultsValues, nComponents, nVert] = GetResultsValues(iDS, iResult, iVertices)
%         [ResultsValues, nComponents, nVert] = GetResultsValues(iDS, iResult)
function [ResultsValues, nComponents, nVert] = GetResultsValues(iDS, iResult, iVertices, iTime, ApplyOrient)
    global GlobalData;
    % ===== PARSE INPUTS =====
    % Default iVertices: all
    if (nargin < 3) || isempty(iVertices)
        iVertices = [];
    % Adapt list of vertices to the number of components per vertex
    else
        switch (GlobalData.DataSet(iDS).Results(iResult).nComponents)
            case 1,  iVertices = sort(iVertices);
            case 2,  iVertices = sort([2*iVertices-1, 2*iVertices]);
            case 3,  iVertices = sort([3*iVertices-2, 3*iVertices-1, 3*iVertices]);
        end
    end
    % Get results time window
    if (nargin < 4) || isempty(iTime)
        iTime = 'UserTimeWindow';
    end
    % Apply orientation (useful only for unconstrained results)
    if (nargin < 5) || isempty(ApplyOrient)
        ApplyOrient = 1;
    end
    % Get time window
    [TimeVector, iTime] = GetTimeVector(iDS, iResult, iTime);
    % Get number of components
    nComponents = GlobalData.DataSet(iDS).Results(iResult).nComponents;
    
    % ===== GET RESULTS VALUES =====
    % === FULL RESULTS ===
    if ~isempty(GlobalData.DataSet(iDS).Results(iResult).ImageGridAmp)
        % Get ImageGridAmp interesting sub-part
        if isempty(iVertices)
            ResultsValues = double(GlobalData.DataSet(iDS).Results(iResult).ImageGridAmp(:, iTime));
        else
            ResultsValues = double(GlobalData.DataSet(iDS).Results(iResult).ImageGridAmp(iVertices, iTime));
        end
        % Number of sources
        nVert = size(GlobalData.DataSet(iDS).Results(iResult).ImageGridAmp, 1) ./ nComponents;
    % === KERNEL ONLY ===
    elseif ~isempty(GlobalData.DataSet(iDS).Results(iResult).ImagingKernel)
        % == LOAD DATA ==
        % If 'F' matrix is not loaded for this file
        if isempty(GlobalData.DataSet(iDS).Measures.F)
            % Load recording matrix
            LoadRecordingsMatrix(iDS);
        end

        % == MULTIPLICATION ==
        % Get selected channels
        GoodChannel = GlobalData.DataSet(iDS).Results(iResult).GoodChannel;
        % Get Data values
        Data = GlobalData.DataSet(iDS).Measures.F(GoodChannel, iTime);
        % Select only the needed vertices
        if isempty(iVertices)
            ImagingKernel = GlobalData.DataSet(iDS).Results(iResult).ImagingKernel;
        else
            ImagingKernel = GlobalData.DataSet(iDS).Results(iResult).ImagingKernel(iVertices,:);
        end
        % Get surface values and multiply them with Kernel
        ResultsValues = ImagingKernel * Data;
        % Number of sources
        nVert = size(GlobalData.DataSet(iDS).Results(iResult).ImagingKernel, 1) ./ nComponents;

        % == APPLY DYNAMIC ZSCORE ==
        if ~isempty(GlobalData.DataSet(iDS).Results(iResult).ZScore)
            ZScore = GlobalData.DataSet(iDS).Results(iResult).ZScore;
            % Keep only the selected vertices
            if ~isempty(iVertices) && ~isempty(ZScore.mean)
                ZScore.mean = ZScore.mean(iVertices,:);
                ZScore.std  = ZScore.std(iVertices,:);
            end
            % Calculate mean/std
            if isempty(ZScore.mean)
                [ResultsValues, ZScore] = process_zscore_dynamic('Compute', ResultsValues, ZScore, ...
                    TimeVector, ImagingKernel, GlobalData.DataSet(iDS).Measures.F(GoodChannel,:));
                % Check if something went wrong
                if isempty(ResultsValues)
                    bst_error('Baseline definition is not valid for this file.', 'Dynamic Z-score', 0);
                    ResultsValues = [];
                    return;
                end
                % If all the sources: report the changes in the ZScore structure
                if isempty(iVertices)
                    GlobalData.DataSet(iDS).Results(iResult).ZScore = ZScore;
                end
            % Apply existing mean/std
            else
                ResultsValues = process_zscore_dynamic('Compute', ResultsValues, ZScore);
            end
        end
    end

    % ===== UNCONSTRAINED SOURCES =====
    % If unconstrained sources (2 or 3 values per source) => Compute norm
    if ApplyOrient
        % STAT: Get the maximum along the different components
        if strcmpi(GlobalData.DataSet(iDS).Results(iResult).DataType, 'stat')
            switch (nComponents)
                case 2,  ResultsValues = max(cat(3, ResultsValues(1:2:end,:), ResultsValues(2:2:end,:)), [], 3);
                case 3,  ResultsValues = max(cat(3, ResultsValues(1:3:end,:), ResultsValues(2:3:end,:), ResultsValues(3:3:end,:)), [], 3);
            end
        % Else: Take the norm
        else
            switch (nComponents)
                case 2,  ResultsValues = sqrt(ResultsValues(1:2:end,:).^2 + ResultsValues(2:2:end,:).^2);
                case 3,  ResultsValues = sqrt(ResultsValues(1:3:end,:).^2 + ResultsValues(2:3:end,:).^2 + ResultsValues(3:3:end,:).^2);
            end
        end
    end
end


%% ===== GET DIPOLES VALUES ======
% USAGE:  DipolesValues = GetDipolesValues(iDS, iDipoles, iTime)
%         DipolesValues = GetDipolesValues(iDS, iDipoles, 'UserTimeWindow')
%         DipolesValues = GetDipolesValues(iDS, iDipoles, 'CurrentTimeIndex')
%         DipolesValues = GetDipolesValues(iDS, iDipoles)
function DipolesValues = GetDipolesValues(iDS, iDipoles, iTime) %#ok<DEFNU>
    global GlobalData;
    % ===== PARSE INPUTS =====
    % Get results time window
    if (nargin < 3)
        iTime = 'UserTimeWindow';
    end
    % Get time window
    [TimeVector, iTime] = GetTimeVector(iDS, iDipoles, iTime, 'Dipoles');

    % ===== GET DIPOLES VALUES =====
    iDip = find(sum(abs(bst_bsxfun(@minus, repmat([GlobalData.DataSet(iDS).Dipoles(iDipoles).Dipole.Time]', 1, length(iTime)), TimeVector(iTime))) < 1e-5, 2));  
    DipolesValues = GlobalData.DataSet(iDS).Dipoles(iDipoles).Dipole(iDip);
end


%% ===== GET TIME-FREQ VALUES =====
% USAGE:  [Values, iTimeBands, iRow] = GetTimefreqValues(iDS, iTimefreq, RowNames, iFreqs, iTime,              Function)
%         [Values, iTimeBands, iRow] = GetTimefreqValues(iDS, iTimefreq, RowNames, iFreqs, 'UserTimeWindow')
%         [Values, iTimeBands, iRow] = GetTimefreqValues(iDS, iTimefreq, RowNames, iFreqs, 'CurrentTimeIndex')
%         [Values, iTimeBands, iRow] = GetTimefreqValues(iDS, iTimefreq, RowNames, iFreqs)
%         [Values, iTimeBands, iRow] = GetTimefreqValues(iDS, iTimefreq, RowNames)
%         [Values, iTimeBands, iRow] = GetTimefreqValues(iDS, iTimefreq)
function [Values, iTimeBands, iRow] = GetTimefreqValues(iDS, iTimefreq, RowNames, iFreqs, iTime, Function)
    global GlobalData;
    % ===== PARSE INPUTS =====
    % Default function: Unchanged
    if (nargin < 6) || isempty(Function)
        Function = [];
    end
    % Default time window
    if (nargin < 5) || isempty(iTime)
        iTime = 'UserTimeWindow';
    end
    % Get full time-freq matrix
    nRow  = size(GlobalData.DataSet(iDS).Timefreq(iTimefreq).TF, 1);
    nFreq = size(GlobalData.DataSet(iDS).Timefreq(iTimefreq).TF, 3);
    % Default frequencies: all
    if (nargin < 4) || isempty(iFreqs)
        iFreqs = 1:nFreq;
    end
    if (nargin < 3)
        RowNames = [];
    end
    iTimeBands = [];
    
    % ===== GET TIME =====
    % Get time window
    [TimeVector, iTime] = GetTimeVector(iDS, iTimefreq, iTime, 'Timefreq');
    % Time bands are defined
    TimeBands = GlobalData.DataSet(iDS).Timefreq(iTimefreq).TimeBands;
    if ~isempty(TimeBands)
        BandBounds = process_tf_bands('GetBounds', TimeBands);
        % Get all the bands to be displayed
        for i = 1:size(TimeBands, 1)
            band = TimeVector(bst_closest(BandBounds(i,:), TimeVector));
            if any((TimeVector(iTime) >= band(1)) & (TimeVector(iTime) <= band(2)))
                iTimeBands(end+1) = i;
            end
        end
        iTime = iTimeBands;
    end
    % Only one time available in the file: return only one index
    if (size(GlobalData.DataSet(iDS).Timefreq(iTimefreq).TF, 2) == 1) && (length(iTime) > 1) 
        iTime = iTime(1);
    end
    
    % ===== GET ROW NAMES =====
    % Default rows: all
    if isempty(RowNames)
        iRow = 1:nRow;
    else
        iRow = [];
        if ischar(RowNames)
            RowNames = {RowNames};
        end
        % Find selected rows
        for i = 1:length(RowNames)
            if iscell(RowNames)
                iRow(end+1) = find(strcmpi(GlobalData.DataSet(iDS).Timefreq(iTimefreq).RowNames, RowNames{i}), 1);
            else
                iRow(end+1) = find(GlobalData.DataSet(iDS).Timefreq(iTimefreq).RowNames == RowNames(i), 1);
            end
        end
    end
    % Kernel sources: read all recordings values
    isKernelSources = strcmpi(GlobalData.DataSet(iDS).Timefreq(iTimefreq).DataType, 'results') && strcmpi(GlobalData.DataSet(iDS).Timefreq(iTimefreq).Measure, 'none') && (size(GlobalData.DataSet(iDS).Timefreq(iTimefreq).TF,1) ~= length(GlobalData.DataSet(iDS).Timefreq(iTimefreq).RowNames));
    if isKernelSources && ~isempty(RowNames)
        iRowInput = iRow;
        iRow = 1:nRow;
    else
        iRowInput = [];
    end
    
    % ===== GET VALUES =====
    % Extract values
    if isequal(Function, 'maxpac')
        Values = GlobalData.DataSet(iDS).Timefreq(iTimefreq).TF(iRow, iTime, iFreqs);
        isApplyFunction = 0;
    elseif isequal(Function, 'pacflow')
        Values = GlobalData.DataSet(iDS).Timefreq(iTimefreq).sPAC.NestingFreq(iRow, iTime, iFreqs);
        isApplyFunction = 0;
    elseif isequal(Function, 'pacfhigh')
        Values = GlobalData.DataSet(iDS).Timefreq(iTimefreq).sPAC.NestedFreq(iRow, iTime, iFreqs);
        isApplyFunction = 0;
    elseif isequal(Function, 'pacphase')
        Values = GlobalData.DataSet(iDS).Timefreq(iTimefreq).sPAC.PhasePAC(iRow, iTime, iFreqs);
        isApplyFunction = 0;
    else
        Values = GlobalData.DataSet(iDS).Timefreq(iTimefreq).TF(iRow, iTime, iFreqs);
        isApplyFunction = ~isempty(Function);
    end
    
    % === INVERSION KERNEL ===
    % Timefreq on results: need to multiply with inversion kernel
    if isKernelSources
        % Get loaded recordings
        iRes = GetResultInDataSet(iDS, GlobalData.DataSet(iDS).Timefreq(iTimefreq).DataFile);
        if ~isempty(iRes)
            nComponents = GlobalData.DataSet(iDS).Results(iRes).nComponents;
            % Get sources to extract
            if isempty(iRowInput)
                Kernel = GlobalData.DataSet(iDS).Results(iRes).ImagingKernel;
            else
                iVertices = iRowInput;
                % Number of components per vertex
                switch (nComponents)
                    case 1,  iVertices = sort(iVertices);
                    case 2,  iVertices = sort([2*iVertices-1, 2*iVertices]);
                    case 3,  iVertices = sort([3*iVertices-2, 3*iVertices-1, 3*iVertices]);
                end
                Kernel = GlobalData.DataSet(iDS).Results(iRes).ImagingKernel(iVertices, :);
            end
            % Multiply values by kernel
            MultValues = zeros(size(Kernel,1), size(Values,2), size(Values,3));
            for i = 1:size(Values,3)
                MultValues(:,:,i) = Kernel * Values(:,:,i);
            end
            Values = MultValues;

            % == APPLY DYNAMIC ZSCORE ==
            if ~isempty(GlobalData.DataSet(iDS).Results(iRes).ZScore)
                error('Not supported yet.');
    %             % Calculate mean/std
    %             if isempty(GlobalData.DataSet(iDS).Results(iResult).ZScore.mean)
    %                 [ResultsValues, GlobalData.DataSet(iDS).Results(iResult).ZScore] = process_zscore_dynamic('Compute', ResultsValues, ...
    %                     GlobalData.DataSet(iDS).Results(iResult).ZScore, ...
    %                     TimeVector, ImagingKernel, GlobalData.DataSet(iDS).Measures.F(GoodChannel,:));
    %             % Apply existing mean/std
    %             else
    %                 ResultsValues = process_zscore_dynamic('Compute', ResultsValues, GlobalData.DataSet(iDS).Results(iResult).ZScore);
    %             end
            end
        end
    end
    
    % ===== APPLY FUNCTION =====
    % If a measure is asked, different from what is saved in the file
    if isApplyFunction
        % Convert
        [Values, isError] = process_tf_measure('Compute', Values, GlobalData.DataSet(iDS).Timefreq(iTimefreq).Measure, Function);
        % If conversion is impossible
        if isError
            error(['Invalid measure conversion: ' GlobalData.DataSet(iDS).Timefreq(iTimefreq).Measure, ' => ' Function]);
        end
    end
end


%% ===== GET PAC VALUES =====
% Calculate an average on the fly if there are several rows
% USAGE:  [ValPAC, sPAC] = GetPacValues(iDS, iTimefreq, RowNames)
function [ValPAC, sPAC] = GetPacValues(iDS, iTimefreq, RowNames) %#ok<DEFNU>
    global GlobalData;
    % ===== GET ROW NAMES =====
    iRows = [];
    if ischar(RowNames)
        RowNames = {RowNames};
    end
    % Find selected rows
    if iscell(RowNames)
        for i = 1:length(RowNames)
            if iscell(RowNames)
                iRows(end+1) = find(strcmpi(GlobalData.DataSet(iDS).Timefreq(iTimefreq).RowNames, RowNames{i}));
            else
                iRows(end+1) = find(GlobalData.DataSet(iDS).Timefreq(iTimefreq).RowNames == RowNames(i));
            end
        end
    else
        iRows = RowNames;
    end
    % ===== GET VALUES =====
    % Taking only the first time point for now
    iTime = 1;
    iFreq = 1;
    % Extract values
    ValPAC           = GlobalData.DataSet(iDS).Timefreq(iTimefreq).TF(iRows, iTime, iFreq);
    sPAC.NestingFreq = GlobalData.DataSet(iDS).Timefreq(iTimefreq).sPAC.NestingFreq(iRows, iTime, iFreq);
    sPAC.NestedFreq  = GlobalData.DataSet(iDS).Timefreq(iTimefreq).sPAC.NestedFreq(iRows, iTime, iFreq);
    sPAC.PhasePAC    = GlobalData.DataSet(iDS).Timefreq(iTimefreq).sPAC.PhasePAC(iRows, iTime, iFreq);
    sPAC.LowFreqs    = GlobalData.DataSet(iDS).Timefreq(iTimefreq).sPAC.LowFreqs;
    sPAC.HighFreqs   = GlobalData.DataSet(iDS).Timefreq(iTimefreq).sPAC.HighFreqs;
    if isfield(GlobalData.DataSet(iDS).Timefreq(iTimefreq).sPAC, 'DirectPAC') && ~isempty(GlobalData.DataSet(iDS).Timefreq(iTimefreq).sPAC.DirectPAC)
        sPAC.DirectPAC = GlobalData.DataSet(iDS).Timefreq(iTimefreq).sPAC.DirectPAC(iRows, iTime, :, :);
    end
    % Average if there are more than one row
    if (length(iRows) > 1)
        ValPAC = mean(ValPAC, 1);
        sPAC.NestingFreq = mean(sPAC.NestingFreq, 1);
        sPAC.NestedFreq  = mean(sPAC.NestedFreq, 1);
        sPAC.PhasePAC    = mean(sPAC.PhasePAC, 1);
        if isfield(sPAC, 'DirectPAC') && ~isempty(sPAC.DirectPAC)
            sPAC.DirectPAC = mean(sPAC.DirectPAC, 1);
        end
    end
end


%% ===== GET MAXIMUM VALUES FOR RESULTS (SMART GFP VERSION) =====
% USAGE:  bst_memory('GetResultsMaximum', iDS, iResult)
function DataMinMax = GetResultsMaximum(iDS, iResult) %#ok<DEFNU>
    global GlobalData;
    % Kernel results
    if ~isempty(GlobalData.DataSet(iDS).Results(iResult).ImagingKernel)
        % Get the sensors concerned but those results
        iChan = GlobalData.DataSet(iDS).Results(iResult).GoodChannel;
        % Compute the GFP of the recordings
        GFP = sum((GlobalData.DataSet(iDS).Measures.F(iChan,:)).^2, 1);
        % Get the time indice of the max GFP value
        [maxGFP, iMax] = max(GFP);
        % Get the results values at this particular time point
        sources = GetResultsValues(iDS, iResult, [], iMax);
    % Full results
    else
        % Get the maximum on the full results matrix
        sources = GlobalData.DataSet(iDS).Results(iResult).ImageGridAmp;
    end
    % Store minimum and maximum of displayed data
    DataMinMax = [min(sources(:)), max(sources(:))];
end


%% ===== GET MAXIMUM VALUES FOR TIMEFREQ =====
% USAGE:  bst_memory('GetTimefreqMaximum', iDS, iTimefreq, Function)
function DataMinMax = GetTimefreqMaximum(iDS, iTimefreq, Function) %#ok<DEFNU>
    tic
    global GlobalData;
    % Get row names and numbers
    RowNames = GlobalData.DataSet(iDS).Timefreq(iTimefreq).RowNames;
    nRowsTF = size(GlobalData.DataSet(iDS).Timefreq(iTimefreq).TF,1);
    % If reading sources based on kernel: get the maximum of the sensors, and multiply by kernel
    isKernelSources = strcmpi(GlobalData.DataSet(iDS).Timefreq(iTimefreq).DataType, 'results') && (nRowsTF < length(RowNames));
    if isKernelSources
        % Get time of the maximum of the GFP(recordings TF)
        [maxTF, iMaxTF] = max(sum(sum(abs(GlobalData.DataSet(iDS).Timefreq(iTimefreq).TF) .^ 2, 1), 3));
        % Get the sources TF values for this time point
        values = GetTimefreqValues(iDS, iTimefreq, [], [], iMaxTF, Function);
    % If the number of values exceeds a certain threshold, compute only max for the first row
    elseif (numel(GlobalData.DataSet(iDS).Timefreq(iTimefreq).TF) > 5e6)
        if iscell(RowNames)
            values = GetTimefreqValues(iDS, iTimefreq, RowNames{1}, [], [], Function);
        else
            values = GetTimefreqValues(iDS, iTimefreq, [], [], 'CurrentTimeIndex', Function);
        end
    % Get all timefreq values
    else
        values = GetTimefreqValues(iDS, iTimefreq, [], [], [], Function);
    end
    % Store minimum and maximum of displayed data
    DataMinMax = [min(values(:)), max(values(:))];
    % Display warning message if analysis time was more than 3s
    t = toc;
    if (t > 3)
        disp(sprintf('bst_memory> WARNING: GetTimefreqMaximum() took %1.5f s', t));
    end
end


%% ===== GET DATASET (DATA) =====
function iDataSets = GetDataSetData(DataFile, isStatic)
    global GlobalData;
    % Parse inputs
    if (nargin < 2)
        isStatic = [];
    end
    % If target is empty : return and empty matrix
    if isempty(DataFile)
        iDataSets = [];
        return
    end
    iDataSets = find(file_compare({GlobalData.DataSet.DataFile}, DataFile));
    % Keep only the datasets with required properties
    if ~isempty(iDataSets) && ~isempty(isStatic)
        isStaticOk = [];
        for i = 1:length(iDataSets)
            isStaticDS = (GlobalData.DataSet(iDataSets(i)).Measures.NumberOfSamples <= 2);
            if isempty(isStaticDS) || (isStatic == isStaticDS)
                isStaticOk(end+1) = i;
            end
        end
        iDataSets = iDataSets(isStaticOk);
    end
end


%% ===== GET DATASET (STUDY, WITH NO DATAFILE) =====
function iDS = GetDataSetStudyNoData(StudyFile)
    global GlobalData;
    % Initialize returned value
    iDS = [];
    % If target is empty : return and empty matrix
    if isempty(StudyFile)
        return
    end
    % Look for dataset in all the registered datasets
    iDS = find(file_compare({GlobalData.DataSet.StudyFile}, StudyFile) & ...
               cellfun(@(c)isempty(c), {GlobalData.DataSet.DataFile}));
end

%% ===== GET DATASET (STUDY) =====
function iDS = GetDataSetStudy(StudyFile)
    global GlobalData;
    % Initialize returned value
    iDS = [];
    % If target is empty : return and empty matrix
    if isempty(StudyFile)
        return
    end
    % Look for dataset in all the registered datasets
    iDS = find(file_compare({GlobalData.DataSet.StudyFile}, StudyFile));
end

%% ===== GET DATASET (CHANNEL) =====
function iDS = GetDataSetChannel(ChannelFile) %#ok<DEFNU>
    global GlobalData;
    % Initialize returned value
    iDS = [];
    % If target is empty : return and empty matrix
    if isempty(ChannelFile)
        return
    end
    iDS = find(file_compare({GlobalData.DataSet.ChannelFile}, ChannelFile));
end



%% ===== GET/CREATE SUBJECT-ONLY DATASET =====
% DataSet type used to display subject data (not attached to a study) 
function iDS = GetDataSetSubject(SubjectFile, createSubject)
    global GlobalData;
    % Parse inputs
    % Initialize returned values
    iDS = [];
    % If target is empty : return and empty matrix
    if isempty(SubjectFile)
        return
    end
    if (nargin < 2) 
        createSubject = 1;
    end
 
    % Look for subject in all the registered datasets
    % (subject-only, ie. without StudyFile defined)
    iDS = find(file_compare({GlobalData.DataSet.SubjectFile}, SubjectFile));
    % If no dataset found for this subject : look if subject uses default subject
    if isempty(iDS)
        % Find subject in database (return default subject if needed)
        sSubject = bst_get('Subject', SubjectFile);
        if ~isempty(sSubject)
            % Look for the default subject file in the loaded DataSets
            iDS = find(file_compare({GlobalData.DataSet.SubjectFile}, sSubject.FileName));
        end
    end
    
    % If DataSet not found, but subject required is the default anatomy: 
    % look for loaded subjects that use the default anatomy
    if isempty(iDS) && strcmpi(bst_fileparts(sSubject.FileName), bst_get('DirDefaultSubject'))
        % Get all protocol subjects
        ProtocolSubjects = bst_get('ProtocolSubjects');
        % If subjects are defined for the protocol
        if ~isempty(ProtocolSubjects.Subject)
            % Get subjects that use default anatomy
            DefAnatSubj = ProtocolSubjects.Subject([ProtocolSubjects.Subject.UseDefaultAnat] == 1);
            % Look for loaded subject that use the default anatomy
            for i = 1:length(DefAnatSubj)
                % Look for the subject file in the loaded DataSets
                iDS = find(file_compare({GlobalData.DataSet.SubjectFile}, DefAnatSubj(i).FileName));
                % If matching dataset is found
                if ~isempty(iDS)
                    break;
                end
            end
        end
    end
    
    % If no DataSet is found : create an empty one
    if isempty(iDS) && createSubject
        % Store DataSet in GlobalData
        iDS = length(GlobalData.DataSet) + 1;
        GlobalData.DataSet(iDS)             = db_template('DataSet');
        GlobalData.DataSet(iDS).SubjectFile = SubjectFile;
    end
end


%% ===== GET/CREATE EMPTY DATASET =====
% DataSet type used to display data/sources/surfaces without using Brainstorm GUI and database
function iDS = GetDataSetEmpty() %#ok<DEFNU>
    global GlobalData;
    % Initialize returned values
    iDS = [];
    % Look for empty dataset in all the registered datasets
    i = 1;
    while isempty(iDS) && (i <= length(GlobalData.DataSet))
        if isempty(GlobalData.DataSet(i).StudyFile) && ...
           isempty(GlobalData.DataSet(i).DataFile) && ...
           isempty(GlobalData.DataSet(i).SubjectFile) && ...
           isempty(GlobalData.DataSet(i).ChannelFile)
            iDS = i;
        else
            i = i + 1;
        end
    end

    % If no DataSet is found : create an empty one
    if isempty(iDS)
        % Store DataSet in GlobalData
        iDS = length(GlobalData.DataSet) + 1;
        GlobalData.DataSet(iDS) = db_template('DataSet');
    end
end



%% ===== GET RESULT IN ALL DATASETS =====
function [iDS, iResult] = GetDataSetResult(ResultsFile)
    global GlobalData;
    % Initialize returned values
    iDS = [];
    iResult  = [];
    % Search for ResultsFile in all DataSets
    for i = 1:length(GlobalData.DataSet)
        % Look for dataset in all the registered datasets
        iRes = find(file_compare({GlobalData.DataSet(i).Results.FileName}, ResultsFile));
        if ~isempty(iRes)
            iDS = i;
            iResult  = iRes;
            return
        end
    end
end

%% ===== GET RESULT IN ONE DATASET =====
function iResult = GetResultInDataSet(iDS, ResultsFile)
    global GlobalData;
    % If target is empty : return and empty matrix
    if isempty(ResultsFile)
        iResult = [];
        return
    end
    % Look for dataset in all the registered datasets
    iResult = find(file_compare({GlobalData.DataSet(iDS).Results.FileName}, ResultsFile));
end


%% ===== GET DIPOLES IN ALL DATASETS =====
function [iDS, iDipoles] = GetDataSetDipoles(DipolesFile)
    global GlobalData;
    % Initialize returned values
    iDS = [];
    iDipoles  = [];
    % Search for DipolesFile in all DataSets
    for i = 1:length(GlobalData.DataSet)
        % Look for dataset in all the registered datasets
        iDip = find(file_compare({GlobalData.DataSet(i).Dipoles.FileName}, DipolesFile));
        if ~isempty(iDip)
            iDS = i;
            iDipoles  = iDip;
            return
        end
    end
end

%% ===== GET MATRIX IN ALL DATASETS =====
function [iDS, iMatrix] = GetDataSetMatrix(MatrixFile)
    global GlobalData;
    % Initialize returned values
    iDS = [];
    iMatrix  = [];
    % Search for MatrixFile in all DataSets
    for i = 1:length(GlobalData.DataSet)
        % Look for dataset in all the registered datasets
        iMat = find(file_compare({GlobalData.DataSet(i).Matrix.FileName}, MatrixFile));
        if ~isempty(iMat)
            iDS = i;
            iMatrix  = iMat;
            return
        end
    end
end

%% ===== GET DIPOLES IN ONE DATASET =====
function iDipoles = GetDipolesInDataSet(iDS, DipolesFile) %#ok<DEFNU>
    global GlobalData;
    % If target is empty : return and empty matrix
    if isempty(DipolesFile)
        iDipoles = [];
        return
    end
    % Look for dataset in all the registered datasets
    iDipoles = find(file_compare({GlobalData.DataSet(iDS).Dipoles.FileName}, DipolesFile));
end


%% ===== GET TIME-FREQ IN ALL DATASETS =====
function [iDS, iTimefreq] = GetDataSetTimefreq(TimefreqFile)
    global GlobalData;
    % Initialize returned values
    iDS  = [];
    iTimefreq = [];
    % Search for TimefreqFile in all DataSets
    for i = 1:length(GlobalData.DataSet)
        % Look for dataset in all the registered datasets
        iTf = find(file_compare({GlobalData.DataSet(i).Timefreq.FileName}, TimefreqFile));
        if ~isempty(iTf)
            iDS  = i;
            iTimefreq = iTf;
            return
        end
    end
end


%% ===== GET TIME-FREQ IN ONE DATASET =====
function iTimefreq = GetTimefreqInDataSet(iDS, TimefreqFile)
    global GlobalData;
    % If target is empty : return and empty matrix
    if isempty(TimefreqFile)
        iTimefreq = [];
        return
    end
    % Look for dataset in all the registered datasets
    iTimefreq = find(file_compare({GlobalData.DataSet(iDS).Timefreq.FileName}, TimefreqFile));
end


%% ===== CHECK TIME WINDOWS =====
% Only allows exactly similar time windows
function isOk = CheckTimeWindows()
    global GlobalData;
    % Initialize
    isOk = 1;
    listTime = [];
    listRate = [];

    % Process all the loaded data (=> existing DataSets)
    for iDS = 1:length(GlobalData.DataSet)
        % Measures
        if (GlobalData.DataSet(iDS).Measures.NumberOfSamples > 2)
            listTime = [listTime; GlobalData.DataSet(iDS).Measures.Time];
            listRate = [listRate, GlobalData.DataSet(iDS).Measures.SamplingRate];
        end        
        % Results
        for iRes = 1:length(GlobalData.DataSet(iDS).Results)
            if (GlobalData.DataSet(iDS).Results(iRes).NumberOfSamples > 2)
                listTime = [listTime; GlobalData.DataSet(iDS).Results(iRes).Time];
                listRate = [listRate, GlobalData.DataSet(iDS).Results(iRes).SamplingRate];
            end
        end
        % Timefreq
        for iTf = 1:length(GlobalData.DataSet(iDS).Timefreq)
            if (GlobalData.DataSet(iDS).Timefreq(iTf).NumberOfSamples > 2)
                listTime = [listTime; GlobalData.DataSet(iDS).Timefreq(iTf).Time];
                listRate = [listRate, GlobalData.DataSet(iDS).Timefreq(iTf).SamplingRate];
            end
        end
        % Dipoles
        for iDip = 1:length(GlobalData.DataSet(iDS).Dipoles)
            if (GlobalData.DataSet(iDS).Dipoles(iDip).NumberOfSamples > 2)
                listTime = [listTime; GlobalData.DataSet(iDS).Dipoles(iDip).Time];
                listRate = [listRate, GlobalData.DataSet(iDS).Dipoles(iDip).SamplingRate];
            end
        end
    end

    % If no time window defined: return
    if isempty(listRate)
        % User time window
        GlobalData.UserTimeWindow.Time            = [];
        GlobalData.UserTimeWindow.SamplingRate    = [];
        GlobalData.UserTimeWindow.NumberOfSamples = 0;
        GlobalData.UserTimeWindow.CurrentTime     = [];
        % Full time window
        GlobalData.FullTimeWindow.Epochs       = [];
        GlobalData.FullTimeWindow.CurrentEpoch = [];
        return;
    end
    
    % === CHECK TIME WINDOWS ===
    Time = listTime(1,:);
    SamplingRate = listRate(1);
    % Check if there is a time window which is not compatible with the first one
    if any(abs(listTime(:,1)-Time(1)) > 1e-5) || any(abs(listTime(:,2)-Time(2)) > 1e-5) || any(abs(listRate-SamplingRate) > 1e-5)
        isOk = 0;
        return;
    end
    
    % === VALIDATE ===
    % Configure user time window
    GlobalData.UserTimeWindow.Time            = Time;
    GlobalData.UserTimeWindow.SamplingRate    = SamplingRate;
    GlobalData.UserTimeWindow.NumberOfSamples = round((GlobalData.UserTimeWindow.Time(2)-GlobalData.UserTimeWindow.Time(1)) / GlobalData.UserTimeWindow.SamplingRate) + 1;
    % Try to reuse the same current time
    if isempty(GlobalData.UserTimeWindow.CurrentTime)
        GlobalData.UserTimeWindow.CurrentTime = GlobalData.UserTimeWindow.Time(1);
    end
    panel_time('SetCurrentTime', GlobalData.UserTimeWindow.CurrentTime);

    % Update panel "Filters"
    panel_filter('TimeWindowChangedCallback');
end


%% ===== CHECK FREQUENCIES =====
function CheckFrequencies()
    global GlobalData;
    isReset = 1;
    % Look for a dataset that still has some time-frequency information loaded
    for iDS = 1:length(GlobalData.DataSet)
        if ~isempty(GlobalData.DataSet(iDS).Timefreq) 
            isReset = 0;
            break;
        end
    end
    % Reset frequency panel
    if isReset 
        GlobalData.UserFrequencies.iCurrentFreq = [];
        GlobalData.UserFrequencies.Freqs = [];
        panel_freq('UpdatePanel');
    end
end


%% ===== GET TIME VECTOR =====
% Usage:  [TimeVector, iTime] = GetTimeVector(iDS, iResult, iTime, DataType)
%         [TimeVector, iTime] = GetTimeVector(iDS, iResult, iTime)
%         [TimeVector, iTime] = GetTimeVector(iDS, iResult, 'UserTimeWindow')
%         [TimeVector, iTime] = GetTimeVector(iDS, iResult, 'CurrentTimeIndex')
%         [TimeVector, iTime] = GetTimeVector(iDS, iResult)  : Return current time
%         [TimeVector, iTime] = GetTimeVector(iDS)           : Return current time, for the recordings
function [TimeVector, iTime] = GetTimeVector(iDS, iResult, iTime, DataType)
    global GlobalData;
    % === GET TIME BOUNDS ===
    isDipole   = (nargin >= 4) && ~isempty(DataType) && strcmpi(DataType, 'Dipoles');
    isTimefreq = (nargin >= 4) && ~isempty(DataType) && strcmpi(DataType, 'Timefreq');
    isResult   = ~isDipole && ~isTimefreq && (nargin >= 2) && ~isempty(iResult);
    % If a dipole
    if isDipole
        Time = GlobalData.DataSet(iDS).Dipoles(iResult).Time;
        NumberOfSamples = GlobalData.DataSet(iDS).Dipoles(iResult).NumberOfSamples;
    % If a time-frequency map
    elseif isTimefreq
        Time = GlobalData.DataSet(iDS).Timefreq(iResult).Time;
        NumberOfSamples = GlobalData.DataSet(iDS).Timefreq(iResult).NumberOfSamples;
    % Not a result, OR a kernel result
    elseif ~isResult || ~isempty(GlobalData.DataSet(iDS).Results(iResult).ImagingKernel)
        Time = GlobalData.DataSet(iDS).Measures.Time;
        NumberOfSamples = GlobalData.DataSet(iDS).Measures.NumberOfSamples;
    else
        Time = GlobalData.DataSet(iDS).Results(iResult).Time;
        NumberOfSamples = GlobalData.DataSet(iDS).Results(iResult).NumberOfSamples;
    end
    % If iTime was not defined
    if (nargin < 3)
        iTime = [];
    end
    
    % === BUILD TIME VECTOR ===
    is_static = (~isResult  && (GlobalData.DataSet(iDS).Measures.NumberOfSamples <= 2)) || ...
                (isResult   && (GlobalData.DataSet(iDS).Results(iResult).NumberOfSamples <= 2)) || ...
                (isDipole   && (GlobalData.DataSet(iDS).Dipoles(iResult).NumberOfSamples <= 2)) || ...
                (isTimefreq && (GlobalData.DataSet(iDS).Timefreq(iResult).NumberOfSamples <= 2));
    % Static dataset: use the whole time window
    if is_static
        TimeVector = Time;
        if ~isempty(iTime) && (ischar(iTime) && strcmpi(iTime, 'UserTimeWindow'))
            iTime = [1,2];
        else
            iTime = 1;
        end
    % Else: use the current user time window
    else
        % Rebuild initial time vector
        TimeVector = linspace(Time(1), Time(2), NumberOfSamples);
        % Find CurrentTime index in the time vector
        if isempty(iTime) || (ischar(iTime) && strcmpi(iTime, 'CurrentTimeIndex'))
            if ~isempty(GlobalData.UserTimeWindow.CurrentTime)
                iTime = bst_closest(GlobalData.UserTimeWindow.CurrentTime, TimeVector);    
            else
                iTime = 1;
            end
        elseif (ischar(iTime) && strcmpi(iTime, 'UserTimeWindow'))
            if isempty(GlobalData.UserTimeWindow.Time)
                iTime = 1:length(TimeVector);
            elseif ~isempty(GlobalData.UserTimeWindow.CurrentTime)
                % Get the time range for the current user window
                iTimeRange = bst_closest(GlobalData.UserTimeWindow.Time, TimeVector);   
                % Get the number of samples between two recordings
                iTimeStep = bst_closest(GlobalData.UserTimeWindow.Time(1) + GlobalData.UserTimeWindow.SamplingRate, TimeVector) - iTimeRange(1);
                % Build list of indices for user time range
                iTime = iTimeRange(1):iTimeStep:iTimeRange(2);
            else
                iTime = [1 2];
            end
        end
    end
    iTime = double(iTime);
    TimeVector = double(TimeVector);
end

 

%% =========================================================================================
%  ===== UNLOAD DATASETS ===================================================================
%  =========================================================================================
%% ===== UNLOAD ALL DATASETS =====
% Unload Brainstorm datasets and perform all needed updates (recalculate time window, update panels, etc...)
%
% USAGE: UnloadAll(OPTIONS)
% Possible OPTIONS (list of strings):
%     - 'Forced'         : All the figures are closed and all the datasets unloaded
%                          else, only the unused (no figures associated) are unloaded
%     - 'KeepMri'        : Do not unload the MRIs
%     - 'KeepSurface'    : Do not unload the surfaces
%     - 'KeepRegSurface' : Unload only the anonymous surfaces (created with view_surface_matrix)
%     - 'KeepChanEditor' : Do not close the channel editor
function UnloadAll(varargin)
    global GlobalData;
    % Display progress bar
    isNewProgress = ~bst_progress('isVisible');
    if isNewProgress
        bst_progress('start', 'Unload all', 'Closing figures...');
    end
    % Parse inputs
    isForced       = any(strcmpi(varargin, 'Forced'));
    KeepMri        = any(strcmpi(varargin, 'KeepMri'));
    KeepSurface    = any(strcmpi(varargin, 'KeepSurface')); 
    KeepRegSurface = any(strcmpi(varargin, 'KeepRegSurface'));
    KeepChanEditor = any(strcmpi(varargin, 'KeepChanEditor'));
    
    % ===== UNLOAD FUNCTIONAL DATA =====
    % Process all datasets
    iDSToUnload = [];
    for iDS = length(GlobalData.DataSet):-1:1
        % If there are some figures left and if unload is not forced => Ignore DataSet 
        if ~isempty(GlobalData.DataSet(iDS).Figure) && ~isForced
            continue
        % Else : Unload dataset
        else
            iDSToUnload = [iDSToUnload, iDS]; %#ok<AGROW>
        end
    end  
    drawnow;
    % Unload all marked datasets
    UnloadDataSets(iDSToUnload);
    
    % ===== UNLOAD ANATOMIES =====
    unloadedSurfaces = {};
    % Forced unload MRI
    if isForced && ~KeepMri
        GlobalData.Mri = repmat(db_template('LoadedMri'), 0);
    end
    % Forced unload surfaces
    if isForced && ~KeepSurface
        unloadedSurfaces = {GlobalData.Surface.FileName};
        UnloadSurface();
    end
    % Unload UNUSED surfaces and MRIs
    if ~isForced && (~KeepMri || ~KeepSurface || KeepRegSurface)
        % Get all the figures
        hFigures = findobj(0,'-depth', 1, 'type','figure');
        % For each figure, get the list of anatomy objects displayed
        listFiles = {};
        for i = 1:length(hFigures)
            TessInfo = getappdata(hFigures(i), 'Surface');
            if ~isempty(TessInfo)
                listFiles = cat(2, listFiles, {TessInfo.SurfaceFile});
            end
        end
        listFiles = unique(listFiles);
        listFiles = setdiff(listFiles, {''});
        % Unload all the MRI that are not inside this list (no longer displayed => no longer loaded)
        if ~KeepMri
            iUnusedMri = find(~cellfun(@(c)any(file_compare(c,listFiles)), {GlobalData.Mri.FileName}));
            if ~isempty(iUnusedMri)
                GlobalData.Mri(iUnusedMri) = [];
            end
        end
        % Unload surfaces
        if ~KeepSurface
            % Get unused surfaces
            iUnusedSurfaces = find(~cellfun(@(c)any(file_compare(c,listFiles)), {GlobalData.Surface.FileName}));
            % Remove registered surfaces from unused surfaces if required
            if KeepRegSurface 
                iRegSurf = find(cellfun(@(c)isempty(strfind(c, 'view_surface_matrix')), {GlobalData.Surface.FileName}));
                iUnusedSurfaces = setdiff(iUnusedSurfaces, iRegSurf);
            end
            % Unload unused surfaces
            if ~isempty(iUnusedSurfaces)
                unloadedSurfaces = {GlobalData.Surface(iUnusedSurfaces).FileName};
                UnloadSurface(unloadedSurfaces);
            end
        end
    end
    
    % Remove unused scouts
    if (~KeepSurface && ~isempty(unloadedSurfaces)) || (isForced && isempty(iDSToUnload))
        drawnow
        % If the current surface was unloaded
        if any(file_compare(GlobalData.CurrentScoutsSurface, unloadedSurfaces))
            % If there are other surfaces still loaded: use the first one
            if ~isempty(GlobalData.Surface)
                warning('todo');
                CurrentSurface = '';
            else
                CurrentSurface = '';
            end
            % Get next surface
            panel_scout('SetCurrentSurface', CurrentSurface);
        end
        % Unload clusters
        panel_cluster('RemoveAllClusters');
    end
    % Empty the clipboard
    bst_set('Clipboard', []);
    % Empty row selection
    if isForced
        GlobalData.DataViewer.SelectedRows = {};
    end
    % Unselect clusters
    panel_cluster('SetSelectedClusters', [], 0);
    panel_cluster('UpdatePanel');
    % Update Event panel
    panel_record('UpdatePanel');
    
    % ===== FORCED =====
    if isForced
        GlobalData.DataViewer.DefaultFactor = [];
        % Unload interpolations
        GlobalData.Interpolations = [];
        % Close channel editor
        if ~KeepChanEditor
            gui_hide( 'ChannelEditor' );
        end
        % Close report editor
        bst_report('Close');
    end
    % Close all unecessary tabs when forced, or when no data left
    if isForced || isempty(GlobalData.DataSet)
        gui_hide('Dipoles');
        gui_hide('FreqPanel');
        gui_hide('Display');
        gui_hide('Stat');
    end
    if isNewProgress
        bst_progress('stop');
    end
end


%% ===== UNLOAD DATASET =====
function UnloadDataSets(iDataSets)
    global GlobalData;
    % Close all figures of each dataset
    for i = 1:length(iDataSets)
        iDS = iDataSets(i);
        % Invalid indice
        if (iDS > length(GlobalData.DataSet))
            continue;
        end
        isRaw = strcmpi(GlobalData.DataSet(iDS).Measures.DataType, 'raw');
        % Raw files: save events and close files
        if ~isempty(GlobalData.DataSet(iDS).Measures) && ~isempty(GlobalData.DataSet(iDS).Measures.sFile) %  && ~isempty(GlobalData.DataSet(iDS).Measures.DataType)
            % If file was modified: ask the user to save it or not
            if GlobalData.DataSet(iDS).Measures.isModified
                if bst_get('ReadOnly')
                    java_dialog('warning', ['Read-only protocol:' 10 'Cannot save the modifications.'], 'Read-only');
                else
                    % Get open file name
                    if isRaw
                        [fPath, fBase, fExt] = bst_fileparts(GlobalData.DataSet(iDS).Measures.sFile.filename);
                        strFile = [' for file "' fBase, fExt '"'];
                    elseif ~isempty(GlobalData.DataSet(iDS).DataFile)
                        strFile = [' for file "' GlobalData.DataSet(iDS).DataFile '"'];
                    else
                        strFile = '';
                    end
                    % Ask user whether to save modifications
                    res = java_dialog('question', ...
                        ['Events were modified', strFile, '.' 10 10 'Save modifications ?'], ...
                        'Save file', [], {'Yes', 'No', 'Cancel'});
                    % User canceled operation
                    if isempty(res) || strcmpi(res, 'Cancel')
                        return
                    end
                    % Save modifications
                    if strcmpi(res, 'Yes')
                        % Save modifications in Brainstorm database
                        panel_record('SaveModifications', iDS);
                    end
                end
            end
            % Force closing of SSP editor panel
            gui_hide('EditSsp');
        end
        % Close all the figures
        for iFig = length(GlobalData.DataSet(iDS).Figure):-1:1
            bst_figures('DeleteFigure', GlobalData.DataSet(iDS).Figure(iFig).hFigure, 'NoUnload', 'NoLayout');
            drawnow
        end
    end
    % Check that dataset still exists
    if any(iDataSets > length(GlobalData.DataSet))
        return;
    end
    % Unload DataSets 
    GlobalData.DataSet(iDataSets) = [];
    % Recompute max time window
    CheckTimeWindows();
    panel_time('UpdatePanel');
    % Update frequency definition
    CheckFrequencies();
    % Reinitialize TimeSliderMutex
    global TimeSliderMutex;
    TimeSliderMutex = [];
    % Call layout manager
    gui_layout('Update');
end


%% ===== UNLOAD RESULTS IN DATASETS =====
% Usage: UnloadDataSetResult(ResultsFile)
%        UnloadDataSetResult(iDS, iResult)
function UnloadDataSetResult(varargin) %#ok<DEFNU>
    global GlobalData;
    % === PARSE INPUTS ===
    % CALL: UnloadDataSetResult(ResultsFile)
    if (nargin == 1) && ischar(varargin{1})
        ResultsFile = varargin{1}; 
        [iDS, iResult] = GetDataSetResult(ResultsFile);
    % CALL: UnloadDataSetResult(iDS, iResult)
    elseif (nargin == 2) && isnumeric(varargin{1}) && isnumeric(varargin{2}) 
       iDS = varargin{1};
       iResult = varargin{2};
    else
        error('Invalid call to UnloadDataSetResult()');
    end
    % === UNLOAD RESULTS ===
    if ~isempty(iDS) && ~isempty(iResult)
        GlobalData.DataSet(iDS).Results(iResult) = [];
        % If DataSet was here only to handle this results : delete it
        if isempty(GlobalData.DataSet(iDS).Results) && ...
                isempty(GlobalData.DataSet(iDS).DataFile)
            % Close figures
            for iFig = 1:length(GlobalData.DataSet(iDS).Figure)
                close(GlobalData.DataSet(iDS).Figure(iFig).hFigure);
            end
        end
    end
end


%% ===== UNLOAD SURFACE =====
% USAGE:  bst_memory('UnloadSurface', SurfaceFile, isCloseFig=0) : Unloads one surface
%         bst_memory('UnloadSurface')                            : Unloads all the surfaces
function UnloadSurface(SurfaceFiles, isCloseFig)
    global GlobalData;
    % If request to close the surface
    if (nargin < 2) || isempty(isCloseFig)
        isCloseFig = 0;
    end
    % If surface is not specified: take all the surfaces
    if (nargin < 1) || isempty(SurfaceFiles)
        SurfaceFiles = {GlobalData.Surface.FileName};
    elseif ischar(SurfaceFiles)
        ProtocolInfo = bst_get('ProtocolInfo');
        SurfaceFiles = {strrep(SurfaceFiles, ProtocolInfo.SUBJECTS, '')};
    elseif iscell(SurfaceFiles)
        % Ok, nothing to do
    end
    % Get current scout surface
    CurrentSurface = GlobalData.CurrentScoutsSurface;
    
    % Save modifications to scouts
    iCloseSurf = [];
    for i = 1:length(SurfaceFiles)
        % If this is the current surface: empty it
        if ~isempty(CurrentSurface) && file_compare(SurfaceFiles{i}, CurrentSurface)
            panel_scout('SetCurrentSurface', '');
        end
        % Save modifications to the surfaces
        panel_scout('SaveModifications');
        % Check if surface is already loaded
        [sSurf, iSurf] = GetSurface(SurfaceFiles{i});
        % If surface is not loaded: skip
        if isempty(iSurf)
            continue;
        end
        % Add to list of surfaces to unload
        iCloseSurf = [iCloseSurf, iSurf];
    end
    % If it is: unload it
    if ~isempty(iCloseSurf)
        GlobalData.Surface(iCloseSurf) = [];
    end
    
    % Close associated figures
    if isCloseFig
        hClose = [];
        % Find surfaces that contain the figure
        for iDS = 1:length(GlobalData.DataSet)
            for iFig = 1:length(GlobalData.DataSet(iDS).Figure)
                % Get surfaces in this figure
                hFig = GlobalData.DataSet(iDS).Figure(iFig).hFigure;
                TessInfo = getappdata(hFig, 'Surface');
                if isempty(TessInfo) || ~isfield(TessInfo, 'SurfaceFile')
                    continue;
                end
                % Loop on the surfaces to unload
                for i = 1:length(TessInfo)
                    if any(file_compare(TessInfo(i).SurfaceFile, SurfaceFiles)) || ...
                       (~isempty(TessInfo(i).DataSource) && ~isempty(TessInfo(i).DataSource.FileName) && any(file_compare(TessInfo(i).DataSource.FileName, SurfaceFiles)))
                        hClose = [hClose, hFig];
                        break;
                    end
                end
            end
        end
        % Close all the figures
        if ~isempty(hClose)
            close(hClose);
        end
    end
end

%% ===== UNLOAD MRI =====
function UnloadMri(MriFile) %#ok<DEFNU>
    global GlobalData;
    % Get SUBJECTS directory
    ProtocolInfo = bst_get('ProtocolInfo');
    % Force relative path
    MriFile = strrep(MriFile, ProtocolInfo.SUBJECTS, '');
    % Check if MRI is already loaded
    iMri = find(file_compare({GlobalData.Mri.FileName}, MriFile));
    % If it is: unload it
    if ~isempty(iMri)
        GlobalData.Mri(iMri) = [];
    end
    % Get subject
    sSubject = bst_get('MriFile', MriFile);
    % Unload subject
    UnloadSubject(sSubject.FileName);
end


%% ===== UNLOAD SUBJECT =====
function UnloadSubject(SubjectFile)
    global GlobalData;
    iDsToUnload = [];
    % Process all the datasets
    for iDS = 1:length(GlobalData.DataSet)
        % Get subject filename (with default anat if it is the case)
        sSubjectDs = bst_get('Subject', GlobalData.DataSet(iDS).SubjectFile);
        % If this dataset uses the subject to unload
        if file_compare(sSubjectDs.FileName, SubjectFile)
            iDsToUnload = [iDsToUnload, iDS];
        end
    end
    % Force unload all the datasets for this subject
    if ~isempty(iDsToUnload)
        UnloadDataSets(iDsToUnload);
    end
end



