function varargout = process_ttest_paired( varargin )
% PROCESS_TTEST_PAIRED: Paired Student''s t-test: Compare means between conditions (across trials or across sujects).

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
    sProcess.Comment     = 'Student''s t-test (Paired)';
    sProcess.FileTag     = '';
    sProcess.Category    = 'Stat2';
    sProcess.SubGroup    = 'Test';
    sProcess.Index       = 604;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'results', 'timefreq'};
    sProcess.OutputTypes = {'pdata', 'presults', 'ptimefreq'};
    sProcess.nInputs     = 2;
    sProcess.nMinFiles   = 2;
    sProcess.isPaired    = 1;
    
    % Definition of the options
    % === Absolue values: legend:
    sProcess.options.abs_label.Comment    = ['<HTML>Warning: This test may not be adapted for processing sources.<BR><BR>' ...
                                             'Test:  t = avg(D) ./ std(D) .* sqrt(n)'];
    sProcess.options.abs_label.Type       = 'label';
    sProcess.options.abs_label.InputTypes = {'results'};
    % === Absolue values: type
    sProcess.options.abs_type.Comment = {'D = abs(A)-abs(B)   - Default', ...
                                         'D = A-B'};
    sProcess.options.abs_type.Type    = 'radio';
    sProcess.options.abs_type.Value   = 1;
    sProcess.options.abs_type.InputTypes = {'results'};
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    % Absolute type
    if ~isfield(sProcess.options, 'abs_type') || isempty(sProcess.options.abs_type.Value) || (sProcess.options.abs_type.Value == 2)
        strAbsType = '';
    elseif (sProcess.options.abs_type.Value == 1)
        strAbsType = ', abs';
    end 
    % Comment
    Comment = ['t-test [paired' strAbsType ']'];
end


%% ===== RUN =====
function sOutput = Run(sProcess, sInputsA, sInputsB) %#ok<DEFNU>
    % ===== PARSE INPUTS =====
    % Absolute values for sources
    isResults = strcmpi(sInputsA(1).FileType, 'results');
    if isResults && isfield(sProcess.options, 'abs_type') 
        switch(sProcess.options.abs_type.Value)
            case 1,  avg_func = 'abs';
            case 2,  avg_func = 'mean';
        end
    else
        avg_func = 'mean';
    end
    % Make sure that file type is indentical for both sets
    if ~isempty(sInputsA) && ~isempty(sInputsB) && ~strcmpi(sInputsA(1).FileType, sInputsB(1).FileType)
        bst_report('Error', sProcess, sInputsA, 'Cannot process inputs from different types.');
        sOutput = [];
        return;
    end
    % Dimensions
    n1 = length(sInputsA);
    n2 = length(sInputsB);
    % Paired test: Number of samples must be equal
    if (n1 ~= n2)
        bst_report('Error', sProcess, [sInputsA(:)',sInputsB(:)'], 'For a paired t-test, the number of files must be the same in the two groups.');
        sOutput = [];
        return;
    end
    % Read atlas in the first file
    ResultsMat = in_bst_results(sInputsA(1).FileName, 0, 'Atlas');
    
    % === PAIRED T-TEST ===
    % Compute the mean and variance of (samples A - samples B) 
    [Stat, Messages] = bst_avg_files('var_diff', {sInputsA.FileName}, {sInputsB.FileName}, avg_func);
    % Add messages to report
    if ~isempty(Messages)
        bst_report('Error', sProcess, [sInputsA(:)',sInputsB(:)'], Messages);
        sOutput = [];
        return;
    end
    % Display progress bar
    bst_progress('start', 'Processes', 'Computing t-test...');

    % Initialize output structure
    sOutput = db_template('statmat');
    % Bad channels and other properties
    switch lower(sInputsA(1).FileType)
        case 'data'
            ChannelFlag = Stat.ChannelFlag;
            isGood = (ChannelFlag == 1);
        case 'results'
            ChannelFlag = [];
            isGood = true(size(Stat.mean, 1), 1);
            % Read some info from the first file
            ResultsMat = in_bst_results(sInputsA(1).FileName, 0, 'Atlas', 'SurfaceFile');
            sOutput.Atlas       = ResultsMat.Atlas;
            sOutput.SurfaceFile = ResultsMat.SurfaceFile;
        case 'timefreq'
            ChannelFlag = [];
            isGood = true(size(Stat.mean, 1), 1);
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
    sizeOutput = size(Stat.mean);
    % Get results
    mean_diff = Stat.mean(isGood,:,:);
    std_diff = sqrt(Stat.var(isGood,:,:));
    % Remove null variances
    iNull = find(std_diff == 0);
    std_diff(iNull) = eps;

    % Compute t-test
    t_tmp = mean_diff ./ std_diff .* sqrt(n1);
    df = n1 - 1;
    clear mean_diff std_diff
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
    sOutput.df           = df;
    sOutput.ChannelFlag  = ChannelFlag;
    sOutput.Time         = Stat.Time;
    sOutput.ColormapType = 'stat2';
end


