function varargout = process_ttest( varargin )
% PROCESS_TTEST: Student''s t-test: Compare means between conditions (across trials or across sujects).

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
% Authors: Francois Tadel, Dimitrios Pantazis, 2008-2013
macro_methodcall;
end

%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Student''s t-test';
    sProcess.FileTag     = '';
    sProcess.Category    = 'Stat2';
    sProcess.SubGroup    = 'Test';
    sProcess.Index       = 603;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'results', 'timefreq'};
    sProcess.OutputTypes = {'pdata', 'presults', 'ptimefreq'};
    sProcess.nInputs     = 2;
    sProcess.nMinFiles   = 2;

    % Definition of the options
    % === T-TEST: type
    sProcess.options.testtype.Comment = {['<HTML><B>Equal variance</B>:<BR>t = (m1-m2) / (Sx * sqrt(1/n1 + 1/n2))<BR>' ...
                                          'Sx = sqrt(((n1-1)*v1 + (n2-1)*v2) ./ (n1+n2-2))'], ...
                                         ['<HTML><B>Unequal variance</B>:<BR>', ...
                                          't = (m1-m2) / sqrt(v1/n1 + v2/n2)']};
    sProcess.options.testtype.Type    = 'radio';
    sProcess.options.testtype.Value   = 1;
    % === T-TEST: legend
    sProcess.options.ttest_label.Comment    = ['<HTML><FONT color="#777777">n1,n2: Number of samples in each group<BR>' ...
                                               'm1,m2: Average across the files for each group<BR>' ...
                                               'v1,v2: Unbiased estimator of the variance across the files</FONT><BR>'];
    sProcess.options.ttest_label.Type       = 'label';
    sProcess.options.separator.Type = 'separator';
    sProcess.options.separator.InputTypes = {'results'};
    
    % === Absolue values: legend
    sProcess.options.abs_label.Comment    = '<HTML><BR>Function to estimate the average across the source files:';
    sProcess.options.abs_label.Type       = 'label';
    sProcess.options.abs_label.InputTypes = {'results'};
    % === Absolue values: type
    sProcess.options.avg_func.Comment = {'<HTML>Arithmetic average: <FONT color="#777777">mean(x)</FONT>', ...
                                         '<HTML>Absolute value of average: <FONT color="#777777">abs(mean(x))</FONT>', ...
                                         '<HTML>Average of absolute values:  <FONT color="#777777">mean(abs(x))</FONT>'}; %, ...
                                         %'<HTML>Root mean square (RMS):  <FONT color="#777777">sqrt(sum(x.^2))</FONT>'};
    sProcess.options.avg_func.Type    = 'radio';
    sProcess.options.avg_func.Value   = 2;
    sProcess.options.avg_func.InputTypes = {'results'};
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    % If sources: averaging option
    if isfield(sProcess.options, 'avg_func')
        switch(sProcess.options.avg_func.Value)
            case 1,  strAvgType = '';
            case 2,  strAvgType = ', abs(avg)';
            case 3,  strAvgType = ', avg(abs)';
            case 4,  strAvgType = ', RMS';
        end
    else
        strAvgType = '';
    end
    % Test type
    switch (sProcess.options.testtype.Value)
        case 1,  Comment = ['t-test [equal var' strAvgType ']'];
        case 2,  Comment = ['t-test [unequal var' strAvgType ']'];
    end
end


%% ===== RUN =====
function sOutput = Run(sProcess, sInputsA, sInputsB) %#ok<DEFNU>
    % ===== PARSE INPUTS =====
    % Make sure that file type is indentical for both sets
    if ~isempty(sInputsA) && ~isempty(sInputsB) && ~strcmpi(sInputsA(1).FileType, sInputsB(1).FileType)
        bst_report('Error', sProcess, sInputsA, 'Cannot process inputs from different types.');
        sOutput = [];
        return;
    end
    % Get variance hypothesis
    isEqualVar = (sProcess.options.testtype.Value == 1);
    % Get average type
    isResults = strcmpi(sInputsA(1).FileType, 'results');
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
    % Dimensions
    n1 = length(sInputsA);
    n2 = length(sInputsB);

    % === UNPAIRED T-TEST ===
    % Compute mean and var for both files sets
    [StatA, MessagesA] = bst_avg_files('var', {sInputsA.FileName}, [], avg_func);
    [StatB, MessagesB] = bst_avg_files('var', {sInputsB.FileName}, [], avg_func);
    Time = StatA.Time;
    % Add messages to report
    if ~isempty(MessagesA)
        bst_report('Error', sProcess, sInputsA, MessagesA);
        sOutput = [];
        return;
    end
    if ~isempty(MessagesB)
        bst_report('Error', sProcess, sInputsB, MessagesB);
        sOutput = [];
        return;
    end
    if ~isequal(size(StatA.mean), size(StatB.mean))
        bst_report('Error', sProcess, sInputsB, 'Files A and B do not have the same number of channels of time samples.');
        sOutput = [];
        return;
    end
    % Absolute values of the average
    if isAbsTest
        StatA.mean = abs(StatA.mean);
        StatB.mean = abs(StatB.mean);
    end
    % Display progress bar
    bst_progress('start', 'Processes', 'Computing t-test...');

    % Initialize output structure
    sOutput = db_template('statmat');
    % Bad channels: For recordings, keep only the channels that are good in BOTH A and B sets
    switch lower(sInputsA(1).FileType)
        case 'data'
            ChannelFlag = StatA.ChannelFlag;
            ChannelFlag(StatB.ChannelFlag == -1) = -1;
            isGood = (ChannelFlag == 1);
        case 'results'
            ChannelFlag = [];
            isGood = true(size(StatA.mean, 1), 1);
            % Read some info from the first file
            ResultsMat = in_bst_results(sInputsA(1).FileName, 0, 'Atlas', 'SurfaceFile');
            sOutput.Atlas       = ResultsMat.Atlas;
            sOutput.SurfaceFile = ResultsMat.SurfaceFile;
        case 'timefreq'
            ChannelFlag = [];
            isGood = true(size(StatA.mean, 1), 1);
            % Read some info from the first file
            TimefreqMat = in_bst_timefreq(sInputsA(1).FileName, 0, 'Atlas', 'DataType', 'SurfaceFile', 'TimeBands', 'Freqs', 'RefRowNames', 'RowNames', 'Measure', 'Method', 'Options');
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
    end
    sizeOutput = size(StatA.mean);
    
    % Get results
    a1 = StatA.mean(isGood,:,:);
    a2 = StatB.mean(isGood,:,:);
    v1 = StatA.var(isGood,:,:);
    v2 = StatB.var(isGood,:,:);
    % Clear variables
    clear StatA StatB
    % Remove null variances
    iNull = find((v1 == 0) | (v2 == 0));
    v1(iNull) = eps;
    v2(iNull) = eps;

    % Compute t-test: Formulas come from Wikipedia page: Student's t-test
    if isEqualVar
        df = n1 + n2 - 2 ;
        pvar = ((n1 - 1) * v1 + (n2 - 1) * v2) / df ;
        t_tmp = (a1 - a2) ./ sqrt( pvar * (1/n1 + 1/n2)) ;
    else
        df = (v1 / n1 + v2 / n2).^2 ./ ...
             ( (v1 / n1).^2 / (n1 - 1) + (v2 / n2).^2 / (n2 - 1) ) ;
        t_tmp = (a1 - a2) ./ sqrt( v1 / n1 + v2 / n2 ) ;
    end
    clear a1 a2 v1 v2

    % Remove values with null variances
    if ~isempty(iNull)
        t_tmp(iNull) = 0;
    end
    
    % === OUTPUT STRUCTURE ===
    % Initialize p and t matrices
    if (nnz(isGood) == length(ChannelFlag))
        sOutput.tmap = t_tmp;
    else
        sOutput.tmap = zeros(sizeOutput);
        sOutput.tmap(isGood,:,:) = t_tmp;
    end
    %sOutput.pmap = betainc( df ./ (df + sOutput.tmap .^ 2), df/2, 0.5);
    sOutput.df          = df;
    sOutput.ChannelFlag = ChannelFlag;
    sOutput.Time        = Time;
    sOutput.ColormapType = 'stat2';
end


