function [pmask, corr_p] = bst_stat_thresh(pmap, StatThreshOptions)
% BST_STAT_THRESH: Threshold a maps of p-values, correcting for multiple comparisons.
%
% USAGE:  [pmask, corr_p] = bst_stat_thresh(pmap, StatThreshOptions)
%
% INPUTS:
%    - pmap  : Map of p-values of any size
%    - StatThreshOptions: Structure with the thresholding options
%        |- pThreshold : statistical threshold (example: 0.05)
%        |- Correction : {'none','fdr','bonferroni'}
%        |- Control    : array of dimensions controlled for multiple comparisons [1=signals,2=time,3=frequencies]
%
% OUTPUTS:
%    - pmask  : Logical mask (0 and 1) of the same size as the pmap. 
%               1 means over the threshold (significant); 0 means below the threshold (not significant)
%    - corr_p : Corrected p-threshold
%
% NOTES:
%    - The correction that is applied and the uncorrected p-threshold are read from 
%      Brainstorm preferences, in variable 'StatThreshOptions', usually defined through the GUI
%    - Those options can be set from a script using: bst_set('StatThreshOptions', your_structure)

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

% Check if no dimensions are selected for control
if isempty(StatThreshOptions.Control)
    StatThreshOptions.Correction = 'none';
end
% Number of tests
nTests = 1;
sizeMap = size(pmap);
if (length(sizeMap) < 3)
    sizeMap(3) = 1;
end
if ismember(1, StatThreshOptions.Control)
    nTests = nTests * sizeMap(1);
end
if ismember(2, StatThreshOptions.Control)
    nTests = nTests * sizeMap(2);
end
if ismember(3, StatThreshOptions.Control)
    nTests = nTests * sizeMap(3);
end

% Type of correction:
switch (StatThreshOptions.Correction)
    case 'none'
        % Using uncorrected threshold
        corr_p = StatThreshOptions.pThreshold;
        % Thresholded pvalues mask
        pmask = (pmap < corr_p);
        % Display console message
        disp(sprintf('BST> Uncorrected p-threshold: %g', StatThreshOptions.pThreshold));
        
    case 'bonferroni'
        % Bonferroni correction: p/N
        corr_p = StatThreshOptions.pThreshold ./ nTests;
        % Thresholded pvalues mask
        pmask = (pmap < corr_p);
        % Display console message
        disp(sprintf('BST> Average corrected p-threshold: %g  (Bonferroni, Ntests=%d)', mean(corr_p), nTests));
        
    case 'fdr'
        % Permute dimensions to have the controlled dimensions first
        dim = [StatThreshOptions.Control, setdiff([1 2 3], StatThreshOptions.Control)];
        pmap = permute(pmap, dim);
        % Reshape to the number of tests: [controlled dimensions x non-controlled dimensions]
        pmap = reshape(pmap, nTests, []);
        
        % Sort values along controlled dimensions 
        fdr_pmap = sort(pmap, 1);
        % FDR line
        fdr_line = (1:nTests)' ./ nTests .* StatThreshOptions.pThreshold;
        % Find points where FDR line is above the sorted pvalues (fdr_pmap < fdr_line)
        fdr_pmap = bst_bsxfun(@minus, fdr_pmap, fdr_line) < 0;
        % Find the highest crossing point
        [tmp, icross] = max(flipdim(fdr_pmap,1), [], 1);
        icross = nTests - icross + 1;
        % Get corresponding p-values
        corr_p = fdr_line(icross)';
        % Nothing: Using Bonferroni correction
        corr_p(icross == nTests) = StatThreshOptions.pThreshold ./ nTests;
        
        % Threshold p-values
        pmask = bst_bsxfun(@lt, pmap, corr_p);
        % Restore initial dimensions
        pmask = reshape(pmask, sizeMap(dim));
        % Restore dimensions order
        if isequal(dim, [2 3 1])
            pmask = permute(pmask, [3 1 2]);
        elseif isequal(dim, [3 1 2])
            pmask = permute(pmask, [2 3 1]);
        else
            pmask = permute(pmask, dim);
        end
        % Display console message
        disp(sprintf('BST> Average corrected p-threshold: %g  (FDR, Ntests=%d)', mean(corr_p), nTests));
        
%         % Control over: time&space or space only
%         switch (StatThreshOptions.Control)
%             case 'time_space'
%                 % Use all the pvalues
%                 corr_p2 = FdrThreshold(pmap, StatThreshOptions.pThreshold);
%                 % Thresholded pvalues mask
%                 pmask = (pmap < corr_p2);
%             case 'space'
%                 % Initialize mask
%                 pmask = false(size(pmap));
%                 nTime = size(pmap,2);
%                 corr_p2 = zeros(1,nTime);
%                 % Loop for each time
%                 for iTime = 1:nTime
%                     % Use only the pvalues for this time point
%                     corr_p2(iTime) = FdrThreshold(pmap(:,iTime), StatThreshOptions.pThreshold);
%                     pmask(:,iTime) = (pmap(:,iTime) < corr_p2(iTime));
%                 end
%         end
end
end


% %% ===== FDR THRESOLD =====
% function corr_p = FdrThreshold(pmap, pThreshold)
%     % Sort pvalues
%     pmap_sorted = sort(pmap(:));
%     % Number of tests
%     N = length(pmap_sorted); 
%     % FDR line
%     fdr_line = (1:N)' ./ N .* pThreshold; 
%     % Highest crossing point between sorted pvalues and FDR line
%     crossing = find( pmap_sorted>fdr_line == 0, 1, 'last');
%     % If the two lines cross
%     if ~isempty(crossing)
%         corr_p = fdr_line(crossing);
%     % Else: no significant voxels
%     else
%         corr_p = 0;
%     end
% end



