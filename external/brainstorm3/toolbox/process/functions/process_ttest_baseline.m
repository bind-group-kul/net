function varargout = process_ttest_baseline( varargin )
% PROCESS_TTEST_BASELINE: Student''s t-test of a post-stimulus signal vs. a baseline.

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
% Authors: Francois Tadel, 2010-2014

macro_methodcall;
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Student''s t-test against baseline';
    sProcess.FileTag     = '';
    sProcess.Category    = 'Stat1';
    sProcess.SubGroup    = 'Test';
    sProcess.Index       = 700;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'results', 'timefreq'};
    sProcess.OutputTypes = {'pdata', 'presults', 'ptimefreq'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    % Default values for some options
    sProcess.isSourceAbsolute = 1;
    
    % Definition of the options
    % === Baseline time window
    sProcess.options.prestim.Comment = 'Pre-simulus time window:   ';
    sProcess.options.prestim.Type    = 'baseline';
    sProcess.options.prestim.Value   = [];
    % === Baseline time window
    sProcess.options.poststim.Comment = 'Post-simulus time window: ';
    sProcess.options.poststim.Type    = 'poststim';
    sProcess.options.poststim.Value   = [];
    % === Absolue values: legend
    sProcess.options.test_label.Comment   = ['<HTML><BR>Test: t = X(post-stim) / std(X(pre-stim))<BR><BR>' ...
                                              'Function to estimate X, the average across the source files:<BR>'];
    sProcess.options.test_label.Type       = 'label';
    sProcess.options.test_label.InputTypes = {'results'};
    % === Absolue values: type
    sProcess.options.avg_func.Comment = {'<HTML>Arithmetic average: <FONT color="#777777">mean(x)</FONT>', ...
                                         '<HTML>Absolute value of average: <FONT color="#777777">abs(mean(x))</FONT>', ...
                                         '<HTML>Average of absolute values:  <FONT color="#777777">mean(abs(x))</FONT>'};
    sProcess.options.avg_func.Type    = 'radio';
    sProcess.options.avg_func.Value   = 2;
    sProcess.options.avg_func.InputTypes = {'results'};
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    % Get time windows
    prestim  = sProcess.options.prestim.Value{1};
    poststim = sProcess.options.poststim.Value{1};
    units = sProcess.options.prestim.Value{2};
    % Averaging function
    if isfield(sProcess.options, 'avg_func')
        switch(sProcess.options.avg_func.Value)
            case 1,  strAvgType = '';
            case 2,  strAvgType = ' [abs(avg)]';
            case 3,  strAvgType = ' [avg(abs)]';
            case 4,  strAvgType = ' [RMS]';
        end
    else
        strAvgType = '';
    end
    % Comment
    if strcmpi(units, 'ms')
        prestim  = round(1000 * prestim);
        poststim = round(1000 * poststim);
        f = '%dms';
    else
        f = '%1.3fs';
    end
    Comment = sprintf(['t-test%s: [' f ',' f '] vs. [' f ',' f ']'], strAvgType, poststim(1), poststim(2), prestim(1), prestim(2));
end


%% ===== RUN =====
function sOutput = Run(sProcess, sInputs) %#ok<DEFNU>   
    % === AVERAGE FILES ===
    % Get average type
    isResults = strcmpi(sInputs(1).FileType, 'results');
    if isResults && isfield(sProcess.options, 'avg_func')
        switch (sProcess.options.avg_func.Value)
            case 1,  avg_func = 'mean'; isAbsTest = 0;
            case 2,  avg_func = 'mean'; isAbsTest = 1;
            case 3,  avg_func = 'abs';  isAbsTest = 1;
            case 4,  avg_func = 'rms';  isAbsTest = 1;
        end
    else
        avg_func = 'mean';
        isAbsTest = 0;
    end
    % Compute mean across all the files
    [Stat, Messages] = bst_avg_files('mean', {sInputs.FileName}, [], avg_func);
    if ~isempty(Messages)
        bst_report('Error', sProcess, sInputs, Messages);
    end
    % Absolute values of the average
    if isAbsTest
        Stat.mean = abs(Stat.mean);
    end
    % Get time
    Time = Stat.Time;
    % Initialize output structure
    sOutput = db_template('statmat');
    % Bad channels: For recordings, keep only the channels that are good in BOTH A and B sets
    switch lower(sInputs(1).FileType)
        case 'data'
            ChannelFlag = Stat.ChannelFlag;
            iGood = find(ChannelFlag == 1);
            sOutput.ColormapType = 'stat2';
        case 'results'
            iGood = 1:size(Stat.mean, 1);
            ChannelFlag = [];
            sOutput.ColormapType = 'stat1';
            % Read some info from the first file
            ResultsMat = in_bst_results(sInputs(1).FileName, 0, 'Atlas', 'SurfaceFile');
            sOutput.Atlas       = ResultsMat.Atlas;
            sOutput.SurfaceFile = ResultsMat.SurfaceFile;
        case 'timefreq'
            iGood = 1:size(Stat.mean, 1);
            ChannelFlag = [];
            sOutput.ColormapType = 'stat1';
            % Read some info from the first file
            TimefreqMat = in_bst_timefreq(sInputs(1).FileName, 0, 'Atlas', 'DataType', 'SurfaceFile', 'TimeBands', 'Freqs', 'RefRowNames', 'RowNames', 'Measure', 'Method', 'Options');
            sOutput.Atlas       = TimefreqMat.Atlas;
            sOutput.DataType    = TimefreqMat.DataType;
            sOutput.SurfaceFile = TimefreqMat.SurfaceFile;
            sOutput.TimeBands   = TimefreqMat.TimeBands;
            sOutput.Freqs       = TimefreqMat.Freqs;
            sOutput.RefRowNames = TimefreqMat.RefRowNames;
            sOutput.RowNames    = TimefreqMat.RowNames;
            sOutput.Measure     = 'other';
            sOutput.Method      = 'ttest';
            sOutput.Options     = TimefreqMat.Options;
            % Check if the time vector matches the data size, if not it's a file with time bands => error
            if isfield(TimefreqMat, 'TimeBands') && ~isempty(TimefreqMat.TimeBands) 
                bst_report('Error', sProcess, sInputs, ['Cannot process files with time bands.' 10 'Please use files with a full time definition.']);
                sOutput = [];
                return;
            end
    end
    
    % === GET INFORMATION ===
    % Display progress bar
    bst_progress('start', 'Processes', 'Computing t-test...');
    % Get pre-stim indices
    iPreStim = bst_closest(sProcess.options.prestim.Value{1}, Time);
    if (iPreStim(1) == iPreStim(2)) && any(iPreStim(1) == Time)
        bst_report('Error', sProcess, sInputs, 'Invalid pre-stim time window definition.');
        sOutput = [];
        return;
    end
    iPreStim = iPreStim(1):iPreStim(2);
    % Get post-stim indices
    iPostStim = bst_closest(sProcess.options.poststim.Value{1}, Time);
    if (iPostStim(1) == iPostStim(2)) && any(iPostStim(1) == Time)
        bst_report('Error', sProcess, sInputs, 'Invalid pre-stim time window definition.');
        sOutput = [];
        return;
    end
    iPostStim = iPostStim(1):iPostStim(2);

    % Get data to test
    sizeOutput = size(Stat.mean);
    X = Stat.mean(iGood,:,:);
    clear Stat;

    % === COMPUTE TEST ===
    % Formula: t = x_post / std(x_pre)
    % Compute variance over baseline (pre-stim interval)
    stdPre = std(X(:,iPreStim,:), 0, 2);
    % Replace null values
    iNull = find(stdPre == 0);
    stdPre(iNull) = 1;
    % Compute t-statistics (formula from wikipedia)
    t_tmp = bst_bsxfun(@rdivide, X(:,iPostStim,:), stdPre);
    % Degrees of freedom for this test
    df = length(iPreStim) - 1;
    % Remove values with null variances
    if ~isempty(iNull)
        t_tmp(iNull,:,:) = 0;
    end
    
    % === CREATE RESULT STRUCTURE ===
    sOutput.tmap = zeros(sizeOutput);
    sOutput.tmap(iGood,iPostStim,:) = t_tmp;
    %sOutput.pmap = betainc( df ./ (df + sOutput.tmap .^ 2), df/2, 0.5);
    sOutput.Time        = Time;
    sOutput.df          = df;
    sOutput.ChannelFlag = ChannelFlag;
end




