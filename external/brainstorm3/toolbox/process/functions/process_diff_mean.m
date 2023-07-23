function varargout = process_diff_mean( varargin )
% PROCESS_DIFF_MEAN: Difference of means of sets A and B.

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
    sProcess.Comment     = 'Difference of means';
    sProcess.FileTag     = '';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Test';
    sProcess.Index       = 601;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'results', 'timefreq', 'matrix'};
    sProcess.OutputTypes = {'data', 'results', 'timefreq', 'matrix'};
    sProcess.nInputs     = 2;
    sProcess.nMinFiles   = 1;
    
    % === SEPARATOR
    sProcess.options.labeldesc.Type = 'label';
    sProcess.options.labeldesc.Comment = '<HTML>Description: average(A) - average(B)<BR><BR>';
    sProcess.options.labelavg.Type = 'label';
    sProcess.options.labelavg.Comment = 'Function to estimate the average across the source files:';
    sProcess.options.labelavg.InputTypes = {'results'};
    % === ABSOLUTE VALUES (FOR SOURCES)
    sProcess.options.avg_func.Comment = {'<HTML>Arithmetic average: <FONT color="#777777">mean(x)</FONT>', ...
                                         '<HTML>Absolute value of average: <FONT color="#777777">abs(mean(x))</FONT>', ...
                                         '<HTML>Average of absolute values:  <FONT color="#777777">mean(abs(x))</FONT>', ...
                                         '<HTML>Root mean square (RMS):  <FONT color="#777777">sqrt(sum(x.^2))</FONT>'};
    sProcess.options.avg_func.Type    = 'radio';
    sProcess.options.avg_func.Value   = 2;
    sProcess.options.avg_func.InputTypes = {'results'};
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess)
    Comment = 'Difference of means';
    % If sources: averaging option
    if isfield(sProcess.options, 'avg_func')
        switch(sProcess.options.avg_func.Value)
            case 1,  % Nothing to add
            case 2,  Comment = [Comment ' [abs(avg)]'];
            case 3,  Comment = [Comment ' [avg(abs)]'];
            case 4,  Comment = [Comment ' [RMS]'];
        end
    end
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputsA, sInputsB) %#ok<DEFNU>
    OutputFiles = {};
    % Make sure that file type is indentical for both sets
    if ~isempty(sInputsA) && ~isempty(sInputsB) && ~strcmpi(sInputsA(1).FileType, sInputsB(1).FileType)
        bst_report('Error', sProcess, sInputsA, 'Cannot process inputs from different types.');
        return;
    end
    % === GET OPTIONS ===
    isResults = strcmpi(sInputsA(1).FileType, 'results');
    if isResults && isfield(sProcess.options, 'avg_func')
        switch (sProcess.options.avg_func.Value)
            case 1,  avg_func = 'mean'; isAbsDiff = 0; strComment = '';
            case 2,  avg_func = 'mean'; isAbsDiff = 1; strComment = ' [abs(avg)]';
            case 3,  avg_func = 'abs';  isAbsDiff = 1; strComment = ' [avg(abs)]';
            case 4,  avg_func = 'rms';  isAbsDiff = 1; strComment = ' [RMS]';
        end
    else
        strComment = '';
        avg_func = 'mean';
        isAbsDiff = 0;
    end
    
    % === COMPUTE DIFFERENCE OF AVG ===
    % Compute average of the two sets of files
    [StatA, MessagesA, iAvgFileA] = bst_avg_files('mean', {sInputsA.FileName}, [], avg_func);
    [StatB, MessagesB, iAvgFileB] = bst_avg_files('mean', {sInputsB.FileName}, [], avg_func);
    % Add messages to report
    if ~isempty(MessagesA)
        bst_report('Error', sProcess, sInputsA, MessagesA);
        return
    end
    if ~isempty(MessagesB)
        bst_report('Error', sProcess, sInputsB, MessagesB);
        return
    end
    % Absolute values before difference
    if isAbsDiff
        StatA.mean = abs(StatA.mean);
        StatB.mean = abs(StatB.mean);
    end
    % Check timefreq measures
    if ~isempty(StatA.Measure) && ~strcmpi(StatA.Measure, StatB.Measure)
        bst_report('Error', sProcess, [sInputsA(:)',sInputsB(:)'], 'The two sets of files have different measures applied to the time-frequency coefficients.');
        return
    end
    % Compute difference of averages
    StatA.mean = StatA.mean - StatB.mean;
    
    % === CREATE OUTPUT STRUCTURE ===
    bst_progress('start', 'Difference of means', 'Saving result...');
    % Get output study
    [sStudy, iStudy] = bst_process('GetOutputStudy', sProcess, [sInputsA, sInputsB]);
    % Comment: forced in the options
    if isfield(sProcess.options, 'Comment') && isfield(sProcess.options.Comment, 'Value') && ~isempty(sProcess.options.Comment.Value)
        Comment = sProcess.options.Comment.Value;
    % Comment: process default
    else
        Comment = [sInputsA(1).Condition, '-', sInputsB(1).Condition, strComment];
    end
    % Get data matrix
    [sMat, matName] = in_bst(sInputsA(1).FileName);
    % Copy fields from StatA structure
    sMat.(matName)   = StatA.mean;
    sMat.ChannelFlag = StatA.ChannelFlag;
    sMat.Time        = StatA.Time;
    sMat.nAvg        = 1;   % What value to put here??
    sMat.Comment     = Comment;
    % Colormap for recordings: keep the original
    % Colormap for sources, timefreq... : difference (stat2)
    if ~strcmpi(sInputsA(1).FileType, 'data')
        sMat.ColormapType = 'stat2';
    end
    % History: Average
    if isfield(sMat, 'History')
        prevHistory = sMat.History;
        sMat = bst_history('reset', sMat);
        sMat = bst_history('add', sMat, 'diff_mean', FormatComment(sProcess));
        sMat = bst_history('add', sMat, 'diff_mean', 'History of the first file:');
        sMat = bst_history('add', sMat, prevHistory, ' - ');
    else
        sMat = bst_history('add', sMat, 'diff_mean', Comment);
    end
    % History: List files A
    sMat = bst_history('add', sMat, 'diff_mean', 'List of files in group A:');
    for i = 1:length(iAvgFileA)
        sMat = bst_history('add', sMat, 'diff_mean', [' - ' sInputsA(iAvgFileA(i)).FileName]);
    end
    % History: List files B
    sMat = bst_history('add', sMat, 'diff_mean', 'List of files in group B:');
    for i = 1:length(iAvgFileB)
        sMat = bst_history('add', sMat, 'diff_mean', [' - ' sInputsB(iAvgFileB(i)).FileName]);
    end
    % Averaging results from the different data file: reset the "DataFile" field
    if isfield(sMat, 'DataFile')
        sMat.DataFile = [];
    end
    % Do not keep the events
    if isfield(sMat, 'Events') && ~isempty(sMat.Events)
        sMat.Events = [];
    end
    % Fix surface link for warped brains
    if isfield(sMat, 'SurfaceFile') && ~isempty(sMat.SurfaceFile) && ~isempty(strfind(sMat.SurfaceFile, '_warped'))
        sMat = process_average('FixWarpedSurfaceFile', sMat, sInputsA(1), sStudy);
    end
    
    % === SAVE FILE ===
    % Output filename
    fileTag = bst_process('GetFileTag', sInputsA(1).FileName);
    OutputFiles{1} = bst_process('GetNewFilename', bst_fileparts(sStudy.FileName), [fileTag, '_diff_mean']);
    % Save on disk
    bst_save(OutputFiles{1}, sMat, 'v6');
    % Register in database
    db_add_data(iStudy, OutputFiles{1}, sMat);
end





