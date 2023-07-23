function varargout = process_permtest( varargin )
% PROCESS_PERMTEST: Permutation tests.

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
% Authors: Francois Tadel, 2010

macro_methodcall;
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Permutation t-test';
    sProcess.FileTag     = '';
    sProcess.Category    = 'Stat2';
    sProcess.SubGroup    = 'Test';
    sProcess.Index       = 0; % 610;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'results', 'timefreq', 'matrix'};
    sProcess.OutputTypes = {'pdata', 'presults', 'ptimefreq', 'matrix'};
    sProcess.nInputs     = 2;
    sProcess.nMinFiles   = 2;
    
    % Default values for some options
    sProcess.isSourceAbsolute = 0;
    
    % Definition of the options
    % === NB PERMUTATIONS
    sProcess.options.npermut.Comment = 'Number of permutations:';
    sProcess.options.npermut.Type    = 'value';
    sProcess.options.npermut.Value   = {1000, '', 0};
    % === T-TEST TYPE
    sProcess.options.testtype.Comment = {'t-test (equal var)', 't-test (unequal var)', 't-test (paired)'};
    sProcess.options.testtype.Type    = 'radio';
    sProcess.options.testtype.Value   = 1;
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    % Test type
    iType = sProcess.options.testtype.Value;
    Comment = ['Perm ' sProcess.options.testtype.Comment{iType}];
end


%% ===== RUN =====
function sOutput = Run(sProcess, sInputsA, sInputsB) %#ok<DEFNU>
    % ===== GET OPTIONS =====
    % Progress bar
    bst_progress('start', 'Permutations', 'Initialization...');
    % Use absolute values of the data
    isAbsoluteValues = strcmpi(sInputsA(1).FileType, 'results') && sProcess.isSourceAbsolute;
    % Channel data or other (sources, matrix, timefreq...)
    isChannelData = strcmpi(sInputsA(1).FileType, 'data');
    % Get test properties
    switch (sProcess.options.testtype.Value)
        case 1 % Unpaired, equal variance
            isPaired = 0;
            isEqualVar = 1;
        case 2 % Unpaired, unequal variance
            isPaired = 0;
            isEqualVar = 0;
        case 3 % Paired
            isPaired = 1;
    end
    % Number of permutations
    nPermut = sProcess.options.npermut.Value;
    % Dimensions
    n1 = length(sInputsA);
    n2 = length(sInputsB);
    n = n1 + n2;
    % If paired test: number of samples must be equal
    if isPaired && (n1 ~= n2)
        error('For a paired t-test, number of samples must be equal in the two datasets.');
    end
    
    % ===== SPLIT IN TIME BLOCKS =====
    % Get time and data size from first file
    [sMatrix, matName] = in_bst(sInputsA(1).FileName);
    [nRow, nTime, nFreq] = size(sMatrix.(matName));
    Time = sMatrix.Time;
    clear sMatrix;
    % Initialize returned variables
    sOutput = db_template('statmat');
    sOutput.pmap     = zeros([nRow, nTime, nFreq]);
    sOutput.tmap     = zeros([nRow, nTime, nFreq]);
    sOutput.Time     = Time;
    % Maximum size of the data that can be handled by the permutation function 
    maxNbElem = 20e6;
    % Number of time blocks
    sizeBlock = round(maxNbElem / nRow / nFreq / n);
    nBlocks = ceil(nTime / sizeBlock);
    % Progress bar
    bst_progress('start', 'Permutations', 'Time block', 1, 100 * nBlocks);
    
    % Loop on each block
    for iBlock = 1:nBlocks
        % Progress bar: Read data
        bst_progress('text', sprintf('Time block #%d/%d: Reading data...', iBlock, nBlocks));
        % Get time samples for this block (start ind = 0)
        iTime = ((iBlock - 1) * sizeBlock + 1) : min(iBlock * sizeBlock, nTime);
        % Get data from all these files for this time block
        [X, ChannelFlag] = ReadTimeBlock([sInputsA, sInputsB], iTime, iBlock);
        % Progress bar: Permutations
        bst_progress('text', sprintf('Time block #%d/%d: Permutations...', iBlock, nBlocks));
        % Perform permuation test
        [pmap, tmap] = PermTest(X, isPaired, isEqualVar, n1, n2, nPermut, iBlock);
        % Reshape the maps into the initial size, and add them to the output variable
        sOutput.pmap(:,iTime,:) = reshape(pmap, nRow, length(iTime), nFreq);
        sOutput.tmap(:,iTime,:) = reshape(tmap, nRow, length(iTime), nFreq);
    end
    % Save channel flag
    sOutput.ChannelFlag = ChannelFlag;
end


%% ===== READ TIME BLOCK =====
function [X, ChannelFlag] = ReadTimeBlock(sInputs, iTime, iBlock)
    ChannelFlag = [];
    % Loop on files
    for i = 1:length(sInputs)
        bst_progress('set', round((iBlock-1)*100 + i/length(sInputs)*50));
        % Read time block
        %[sMatrix, matName] = in_bst(sInputs(i).FileName, iTime);
        %%% INPUTS OF THE FUNCTION CHANGED, FROM iTIME TO TIMEBOUNDS
        % If it is the first file: initialize output variable
        if (i == 1)
            nValues = prod(size(sMatrix.(matName)));
            X = zeros(length(sInputs), nValues);
            if isfield(sMatrix, 'ChannelFlag')
                ChannelFlag = sMatrix.ChannelFlag;
            end
        end
        % Reshape all the values for this file in a vector
        X(i,:) = reshape(sMatrix.(matName), 1, []);
        % Add bad channels to the bad channels list
        if ~isempty(ChannelFlag)
            ChannelFlag(sMatrix.ChannelFlag == -1) = -1;
        end
    end
end



%% ===== PERMUTATION TEST =====
function [pmap, tmap] = PermTest(X, isPaired, isEqualVar, n1, n2, nPermut, iBlock)
    i1 = 1:n1;
    i2 = n1+1:n1+n2;
    
    % Loop of permutations
    for iPermut = 1:nPermut
        bst_progress('set', round((iBlock-1)*100 + 50 + iPermut/nPermut*50));
    end
    
    % === UNPAIRED T-TEST ===
    if ~isPaired
        % Compute averages and variances
        a1 = mean(X(i1,:));
        a2 = mean(X(i2,:));
        v1 = var(X(i1,:));
        v2 = var(X(i2,:));
        % Remove null variances
        iNull = find((v1 == 0) | (v2 == 0));
        v1(iNull) = eps;
        v2(iNull) = eps;
        % Compute t-test: Formulas come from Wikipedia page: Student's t-test
        if isEqualVar
            df = n1 + n2 - 2 ;
            pvar = ((n1 - 1) * v1 + (n2 - 1) * v2) / df ;
            tmap = (a1 - a2) ./ sqrt( pvar * (1/n1 + 1/n2)) ;
        else
            df = (v1 / n1 + v2 / n2).^2 ./ ...
                 ( (v1 / n1).^2 / (n1 - 1) + (v2 / n2).^2 / (n2 - 1) ) ;
            tmap = (a1 - a2) ./ sqrt( v1 / n1 + v2 / n2 ) ;
        end
        clear a1 a2 v1 v2 pvar
    % === PAIRED T-TEST ===
    else
        % Compute average and variance
        Xdiff = X(i1,:) - X(i2,:);
        mean_diff = mean(Xdiff);
        std_diff = sqrt(var(Xdiff));
        % Remove null variances
        iNull = find(std_diff == 0);
        std_diff(iNull) = eps;
        % Compute t-test
        tmap = mean_diff ./ std_diff .* sqrt(n1);
        df = n1 - 1;
        clear mean_diff std_diff
    end
    
    % Compute p-values
    pmap = betainc( df ./ (df + tmap .^ 2), df/2, 0.5);
    
    % Remove values with null variances
    if ~isempty(iNull)
        pmap(iNull) = 1;
        tmap(iNull) = 0;
    end   
end


