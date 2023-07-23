function varargout = process_average( varargin )
% PROCESS_AVERAGE: Average files, by subject, by condition, or all at once.
%
% USAGE:    OutputFiles = process_average('Run', sProcess, sInputs)
%        [sMat,isFixed] = process_average('FixWarpedSurfaceFile', sMat, sInput, sStudyDest)


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
% Authors: Francois Tadel, 2010-2013

macro_methodcall;
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Average files';
    sProcess.FileTag     = '';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Average';
    sProcess.Index       = 301;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'results', 'timefreq', 'matrix'};
    sProcess.OutputTypes = {'data', 'results', 'timefreq', 'matrix'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 2;
    sProcess.isSeparator = 1;
    % Definition of the options
    % === AVERAGE TYPE
    sProcess.options.avgtype.Comment = {'Everything', 'By subject', 'By condition (subject average)', 'By condition (grand average)', 'By trial group (subject average)', 'By trial group (grand average)'};
    sProcess.options.avgtype.Type    = 'radio';
    sProcess.options.avgtype.Value   = 1;
    % === SEPARATOR
    sProcess.options.separator.Type = 'separator';
    % sProcess.options.separator.InputTypes = {'results'};
    sProcess.options.labelfunc.Type = 'label';
    sProcess.options.labelfunc.Comment = 'Function:';
    % sProcess.options.labelfunc.InputTypes = {'results'};
    % === ABSOLUTE VALUES (FOR SOURCES)
    sProcess.options.avg_func.Comment = {'<HTML>Arithmetic average: <FONT color="#777777">mean(x)</FONT>', ...
                                         '<HTML>Average absolute values:  <FONT color="#777777">mean(abs(x))</FONT>', ...
                                         '<HTML>Root mean square (RMS):  <FONT color="#777777">sqrt(sum(x.^2))</FONT>', ...
                                         '<HTML>Standard deviation: <FONT color="#777777">sqrt(var(x))</FONT>', ...
                                         '<HTML>Standard error: <FONT color="#777777">sqrt(var(x))/N</FONT>'};
    sProcess.options.avg_func.Type    = 'radio';
    sProcess.options.avg_func.Value   = 1;
    % sProcess.options.avg_func.InputTypes = {'results'};
    % === KEEP EVENTS
    sProcess.options.keepevents.Comment = 'Keep all the events from the individual epochs';
    sProcess.options.keepevents.Type    = 'checkbox';
    sProcess.options.keepevents.Value   = 0;
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    % Function
    if isfield(sProcess.options, 'avg_func')
        switch(sProcess.options.avg_func.Value)
            case 1,  Comment = 'Average: ';
            case 2,  Comment = 'Average/abs: ';
            case 3,  Comment = 'RMS: ';
            case 4,  Comment = 'Standard deviation: ';
            case 5,  Comment = 'Standard error: ';
        end
    else
        Comment = 'Average: ';
    end
    % Average type
    iAvgType = sProcess.options.avgtype.Value;
    Comment = [Comment, sProcess.options.avgtype.Comment{iAvgType}];
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>
    % Initialize returned list
    OutputFiles = {};
    % Get current progressbar position
    if bst_progress('isVisible')
        curProgress = bst_progress('get');
    else
        curProgress = [];
    end
    % Keep events
    KeepEvents = sProcess.options.keepevents.Value;
    % Group files in different ways: by subject, by condition, or all together
    switch(sProcess.options.avgtype.Value)
        % === EVERYTHING ===
        case 1  
            OutputFiles = AverageFiles(sProcess, sInputs, KeepEvents);
            
        % === BY SUBJECT ===
        case 2
            % Process each subject independently
            uniqueSubj = unique({sInputs.SubjectFile});
            for i = 1:length(uniqueSubj)
                % Set progress bar at the same level for each loop
                if ~isempty(curProgress)
                    bst_progress('set', curProgress);
                end
                % Get all the files for condition #i
                iInputSubj = find(strcmpi(uniqueSubj{i}, {sInputs.SubjectFile}));
                % Process the average of condition #i
                tmpOutFiles = AverageFiles(sProcess, sInputs(iInputSubj), KeepEvents);
                % Save the results
                OutputFiles = cat(2, OutputFiles, tmpOutFiles);
            end
            
        % === BY CONDITION ===
        case {3,4}
            % Subject average
            if (sProcess.options.avgtype.Value == 3)
                inputCondPath = {};
                for iInput = 1:length(sInputs)
                    inputCondPath{iInput} = [sInputs(iInput).SubjectName, '/', sInputs(iInput).Condition];
                end
            % Grand average
            else
                inputCondPath = {sInputs.Condition};
            end
            % Process each condition independently
            uniqueCond = unique(inputCondPath);
            for i = 1:length(uniqueCond)
                % Set progress bar at the same level for each loop
                if ~isempty(curProgress)
                    bst_progress('set', curProgress);
                end
                % Get all the files for condition #i
                iInputCond = find(strcmpi(uniqueCond{i}, inputCondPath));
                % Set the comment of the output file
                sProcess.options.Comment.Value = sInputs(iInputCond(1)).Condition;
                % Process the average of condition #i
                tmpOutFiles = AverageFiles(sProcess, sInputs(iInputCond), KeepEvents);
                % Save the results
                OutputFiles = cat(2, OutputFiles, tmpOutFiles);
            end
        
        % === BY TRIAL GROUPS ===
        % Process each subject+condition+trial group independently
        case {5,6}
            % Get the condition path (SubjectName/Condition/CommentBase) or (Condition/CommentBase) for each input file
            CondPath = cell(1, length(sInputs));
            trialComment = cell(1, length(sInputs));
            for iInput = 1:length(sInputs)
                % Default comment
                trialComment{iInput} = sInputs(iInput).Comment;
                % If results/timefreq and attached to a data file
                if any(strcmpi(sInputs(iInput).FileType, {'results','timefreq'})) && ~isempty(sInputs(iInput).DataFile)
                    switch (file_gettype(sInputs(iInput).DataFile))
                        case 'data'
                            [sStudyAssoc, iStudyAssoc, iFileAssoc] = bst_get('DataFile', sInputs(iInput).DataFile);
                            if ~isempty(sStudyAssoc)
                                trialComment{iInput} = sStudyAssoc.Data(iFileAssoc).Comment;
                            else
                                bst_report('Warning', sProcess, sInputs(iInput), ['File skipped, the parent node has been deleted:' 10 sInputs(iInput).DataFile]);
                            end
                            
                        case {'results', 'link'}
                            [sStudyAssoc, iStudyAssoc, iFileAssoc] = bst_get('ResultsFile', sInputs(iInput).DataFile);
                            if ~isempty(sStudyAssoc)
                                [sStudyAssoc2, iStudyAssoc2, iFileAssoc2] = bst_get('DataFile', sStudyAssoc.Result(iFileAssoc).DataFile);
                                if ~isempty(sStudyAssoc2)
                                    trialComment{iInput} = sStudyAssoc2.Data(iFileAssoc2).Comment;
                                else
                                    bst_report('Warning', sProcess, sInputs(iInput), ['File skipped, the parent node has been deleted:' 10 sStudyAssoc.Result(iFileAssoc).DataFiles]);
                                end
                            else
                                bst_report('Warning', sProcess, sInputs(iInput), ['File skipped, the parent node has been deleted:' 10 sInputs(iInput).DataFile]);
                            end
                    end
                end
                % Subject average
                if (sProcess.options.avgtype.Value == 5)
                    CondPath{iInput} = [sInputs(iInput).SubjectName, '/', str_remove_parenth(trialComment{iInput})];
                % Grand average
                else
                    CondPath{iInput} = str_remove_parenth(trialComment{iInput});
                end
            end            
            uniquePath = setdiff(unique(CondPath), {''});
            % Process each condition path
            for i = 1:length(uniquePath)
                % Set progress bar at the same level for each loop
                if ~isempty(curProgress)
                    bst_progress('set', curProgress);
                end
                % Get all the files for condition #i
                iInputCond = find(strcmpi(uniquePath{i}, CondPath));
                % Do not process if there is only one input
                if (length(iInputCond) == 1)
                    bst_report('Warning', sProcess, sInputs(iInputCond(1)).FileName, 'File is alone in its trial/comment group. Not processed.');
                    continue;
                end
                % Set the comment of the output file
                sProcess.options.Comment.Value = str_remove_parenth(trialComment{iInputCond(1)});
                % Process the average of condition #i
                tmpOutFiles = AverageFiles(sProcess, sInputs(iInputCond), KeepEvents);
                % Save the results
                OutputFiles = cat(2, OutputFiles, tmpOutFiles);
            end
    end
end


%% ===== AVERAGE FILES =====
function OutputFiles = AverageFiles(sProcess, sInputs, KeepEvents)   
    % === PROCESS AVERAGE ===
    % Get function
    isResults = strcmpi(sInputs(1).FileType, 'results');
    % if isResults && isfield(sProcess.options, 'avg_func')
    if isfield(sProcess.options, 'avg_func')
        switch (sProcess.options.avg_func.Value)
            case 1,  avg_func = 'mean';   StatType = 'mean';   strComment = 'Avg';
            case 2,  avg_func = 'abs';    StatType = 'mean';   strComment = 'Avg(abs)';
            case 3,  avg_func = 'rms';    StatType = 'mean';   strComment = 'RMS';
            case 4,  avg_func = 'mean';   StatType = 'var';    strComment = 'Std';
            case 5,  avg_func = 'mean';   StatType = 'var';    strComment = 'StdError';   
        end
    else
        strComment = 'Avg';
        avg_func = 'mean';
        StatType = 'mean';
    end
    % Compute average
    [Stat, Messages, iAvgFile, Events] = bst_avg_files(StatType, {sInputs.FileName}, [], avg_func, 1);
    % Apply corrections on the variance value
    if strcmpi(StatType, 'var')
        % Std
        if strcmpi(strComment, 'Std')
            Stat.(StatType) = sqrt(Stat.(StatType));
        % StdError
        elseif strcmpi(strComment, 'StdError')
            Stat.(StatType) = sqrt(Stat.(StatType) / length(sInputs));
        end
    end
    % Add messages to report
    if ~isempty(Messages)
        bst_report('Error', sProcess, sInputs, Messages);
    end
    
    % === CREATE OUTPUT STRUCTURE ===
    % Get output study
    [sStudy, iStudy, Comment, uniqueDataFile] = bst_process('GetOutputStudy', sProcess, sInputs);
    % Replace the number of files
    Comment = strrep(Comment, [num2str(length(sInputs)) ' '], [num2str(length(iAvgFile)) ' ']);
    % Comment: forced in the options
    if isfield(sProcess.options, 'Comment') && isfield(sProcess.options.Comment, 'Value') && ~isempty(sProcess.options.Comment.Value)
        Comment = [strComment ': ' sProcess.options.Comment.Value, ' (' num2str(length(sInputs)) ' files)'];
    % Comment: Process default
    else
        Comment = [strComment ': ' Comment];
    end
    % Get data matrix
    [sMat, matName] = in_bst(sInputs(iAvgFile(1)).FileName);
    % Copy fields from Stat structure
    sMat.(matName) = Stat.(StatType);
    sMat.ChannelFlag = Stat.ChannelFlag;
    sMat.Time        = Stat.Time;
    sMat.nAvg        = Stat.nAvg;
    sMat.Comment     = Comment;
    % History: Average
    if isfield(sMat, 'History')
        prevHistory = sMat.History;
        sMat = bst_history('reset', sMat);
        sMat = bst_history('add', sMat, 'average', 'History of the first file:');
        sMat = bst_history('add', sMat, prevHistory, ' - ');
    else
        sMat = bst_history('add', sMat, 'average', Comment);
    end
    % History: List files
    sMat = bst_history('add', sMat, 'average', 'List of averaged files:');
    for i = 1:length(iAvgFile)
        sMat = bst_history('add', sMat, 'average', [' - ' sInputs(iAvgFile(i)).FileName]);
    end
    % Averaging results from the different data file: reset the "DataFile" field
    if isfield(sMat, 'DataFile') && ~isempty(sMat.DataFile) && (length(uniqueDataFile) ~= 1)
        sMat.DataFile = [];
    end
    % Copy all the events found in the input files
    if KeepEvents && ~isempty(Events)
        sMat.Events = Events;
    else
        sMat.Events = [];
    end
    
    % === AVERAGE WARPED BRAINS ===
    if isResults
        sMat = FixWarpedSurfaceFile(sMat, sInputs(1), sStudy);
    end
    
    % === SAVE FILE ===
    % Output filename
    if strcmpi(sInputs(1).FileType, 'data')
        allFiles = {};
        for i = 1:length(sInputs)
            [tmp, allFiles{end+1}, tmp] = bst_fileparts(sInputs(i).FileName);
        end
        fileTag = str_common_path(allFiles, '_');
    else
        fileTag = bst_process('GetFileTag', sInputs(1).FileName);
    end
    OutputFiles{1} = bst_process('GetNewFilename', bst_fileparts(sStudy.FileName), [fileTag, '_average']);
    % Save on disk
    bst_save(OutputFiles{1}, sMat, 'v6');
    % Register in database
    db_add_data(iStudy, OutputFiles{1}, sMat);
end


%% ===== FIX SURFACE FOR WARPED BRAINS =====
% Average source files coming from different subjects that are all different deformations of the default brain: 
% should re-use the initial cortex surface instead of the first cortex surface available
function [sMat, isFixed] = FixWarpedSurfaceFile(sMat, sInput, sStudyDest)
    isFixed = 0;
    % Not a warped surface: skip
    if ~isfield(sMat, 'SurfaceFile') || isempty(sMat.SurfaceFile) || isempty(strfind(sMat.SurfaceFile, '_warped'))
        return;
    end
    % Must be from non-default to default anatomy
    isDestDefaultSubj = strcmp(bst_fileparts(sStudyDest.BrainStormSubject), bst_get('DirDefaultSubject'));
    isSrcDefaultSubj  = strcmp(bst_fileparts(sInput.SubjectFile), bst_get('DirDefaultSubject'));
    if isSrcDefaultSubj || ~isDestDefaultSubj
        return;
    end
    % Rebuild possible target surface
    [tmp, fBase, fExt] = bst_fileparts(sMat.SurfaceFile);
    SurfaceFileDest = [bst_fileparts(sStudyDest.BrainStormSubject), '/', strrep([fBase, fExt], '_warped', '')];
    % Find destination file in database
    [sSubjectDest, iSubjectDes, iSurfDest] = bst_get('SurfaceFile', SurfaceFileDest);
    if isempty(iSurfDest)
        return;
    end
    % If this surface exists: use it if it has the same number of vertices as the source surface
    % Get the vertices number from source and destination surface files
    VarInfoSrc  = whos('-file', file_fullpath(sMat.SurfaceFile), 'Vertices');
    VarInfoDest = whos('-file', file_fullpath(SurfaceFileDest), 'Vertices');
    % Number of vertices match: change the surface
    if (VarInfoSrc.size(1) == VarInfoDest.size(1))
        sMat.SurfaceFile = SurfaceFileDest;
        isFixed = 1;
    end
end





