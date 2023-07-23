function [connectivity, pValues, delays] = bst_correlation(X, Y, inputs)
% BST_CORRELATION   Calculate the covariance OR correlation between two multivariate signals, assuming any drift has been removed.
%
% Inputs:
%   X                 - First set of signals, one signal per row
%                       [X: A x N matrix]
%   Y                 - Second set of signals, one signal per row
%                       [Y: B x N matrix]
%                       (default: Y = X)
%   inputs            - Struct of parameters:
%   |-normalize       - If true, output correlation
%   |                   If false (default), output covariance
%   |                   [F: boolean]
%   |-nTrials         - Number of trials in data
%   |                   [T: nonnegative integer]
%   |                   (default: 1)
%   |-maxDelay        - Maximum delay desired in cross-covariance
%   |                   [D: nonnegative integer]
%   |                   (default: 0)
%   |-nDelay          - # of delays to skip in each iteration
%   |                   [T: positive integer]
%   |                   (default: 0)
%   |-flagStatistic   - Type of parametric model to apply to absolute value of correlation 
%   |                   0: Use t-statistic and then look up p-value for standard normal (default)
%   |                                                         |correlation|
%   |                           statistic = sqrt(N-2) * ------------------------
%   |                                                   sqrt(1 - correlation.^2)
%   |                   1: Use Fisher's Z transform and then look up p-value for standard normal
%   |                                                   1    1 + |correlation|
%   |                           statistic = sqrt(N-3) * - ln -----------------
%   |                                                   2    1 - |correlation|
%
% Outputs:
%   connectivity      - Matrix of covariance (correlation) values. (i,j) is the covariance (correlation) of X_i & Y_j.
%                       [C: A x B x ND matrix]
%   pValues           - Matrix of p-values for correlation. (i,j) is the p-value of the magnitude of correlation between X_i & Y_j.
%                       [P: A x B x ND matrix in (0.5, 1)]
%   delays            - Delays corresponding to each time-lagged cross-correlation in the previous output. Given D and T, the delays are
%                       [-D -D+T -D+2T ... -2T -T 0 T 2T ... D-2T D-T D]
%                       [V: ND x 1 vector]
%
% Call:
%   connectivity = bst_correlation(X, Y); % default
%   connectivity = bst_correlation(X, Y, inputs); % customized
% Parameter examples:
%   inputs.normalize      = false; % Covariance instead of correlation
%   inputs.maxDelay       = 30; % Get covariances for lags -30, -29, ..., -29, 30
%   inputs.nDelay         = 30; % Get covariances for lags -30, -27, ..., -27, 30
%   inputs.flagStatistic  = 0; % Use t-statistic because it better models the Monte Carlo distribution of correlation.

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
% Authors: Sergul Aydore & Syed Ashrafulla, 2012


%% Setup

% Number of timepoints
nTimes = size(X,2);

% Default: 1 trial
if ~isfield(inputs, 'nTrials')
  inputs.nTrials = 1;
end

% Default: no delayed cross-correlation
if ~isfield(inputs, 'maxDelay')
  inputs.maxDelay = 0;
end

% Default: capture every desired delay
if ~isfield(inputs, 'nDelay')
  inputs.nDelay = 1;
end

if ~isfield(inputs, 'flagStatistic')
  inputs.flagStatistic = 0;
end
duplicate = (all(size(Y) == size(X)) && max(abs(Y(:) - X(:))) < eps); % If Y = X, we want autocovariance;

%% Correlation or covariance?
if isfield(inputs, 'normalize') && inputs.normalize
  X = bst_bsxfun(@minus, X, mean(X, 2)); % Zero mean
  stdX = sqrt(sum(X.*conj(X), 2) / (nTimes - 1));
  X = bst_bsxfun(@rdivide, X(stdX > 0, :), stdX(stdX > 0)); % Unit standard deviation
  
  if ~duplicate
    Y = bst_bsxfun(@minus, Y, mean(Y, 2)); % Zero mean
    stdY = sqrt(sum(Y.*conj(Y), 2) / (nTimes - 1));
    Y = bst_bsxfun(@rdivide, Y(stdY > 0, :), stdY(stdY > 0)); % Same for the other side unless it is X (to reduce computation time)
  else
    Y = X;
  end
else
  inputs.normalize = false;
end

%% Connectivity measure

nSteps = floor(inputs.maxDelay/inputs.nDelay);
delays = (-nSteps:nSteps)*inputs.nDelay;

connectivity = zeros(size(X,1), size(Y,1), 2*nSteps+1);

% == Delay = 0: E{X[n] Y^T[n]} ==
connectivity(:, :, nSteps+1) = X*Y' / (size(X,2) - 1);

for idxStep = 1:nSteps
  
  % == Delay < 0: E{X[n-k] Y[k]} = E{X[n] Y[n+k]} ==
  delay = -delays(idxStep);
  if inputs.nTrials > 1
    % The trials are stacked across horizontally. So, to get timepoints delay+1, ..., N for each trial, we use bst_trial_idx
    % In addition, we only want to use timepoints with no NaNs. So, we remove all trial-specific indices that have NaNs.
    xDelay = X(:, bst_trial_idx((delay+1):nTimes, nTimes, inputs.nTrials)); 
    yDelay = Y(:, bst_trial_idx(1:(end-delay), nTimes, inputs.nTrials));    
  else
    % There is only 1 trial, so we just remove timepoints with no NaNs. For many calls, the function overhead is steep without this specific T = 1 case.
    xDelay = X(:, (delay+1):nTimes);
    yDelay = Y(:, 1:(end-delay));
  end
  
  % Covariance
  connectivity(:, :, idxStep) = xDelay * yDelay'/ (nTimes-delay - 1);

  % == Delay > 0: E{X[n-k] Y[n]} ==
  delay = delays(nSteps+1 + idxStep);
  if inputs.nTrials > 1
    % The trials are stacked across horizontally. So, to get timepoints delay+1, ..., N for each trial, we use bst_trial_idx
    % In addition, we only want to use timepoints with no NaNs. So, we remove all trial-specific indices that have NaNs.
    xDelay = X(:, bst_trial_idx(1:(end-delay), nTimes, inputs.nTrials));
    yDelay = Y(:, bst_trial_idx((delay+1):end, nTimes, inputs.nTrials));
  else
    % There is only 1 trial, so we just remove timepoints with no NaNs. For many calls, the function overhead is steep without this specific T = 1 case.
    xDelay = X(:, 1:(end-delay));
    yDelay = Y(:, (delay+1):end);
  end

  % Covariance
  connectivity(:, :, nSteps+1 + idxStep) = xDelay * yDelay'/ (nTimes-delay - 1);

end

%% Statistics
if (nargout >= 2)
    pValues = zeros(size(connectivity));
    if inputs.normalize && inputs.flagStatistic % If true, use Fisher's Z transform and Gaussian with zero mean, variance N-3
      pValues(connectivity < 1-eps) = 1 - normcdf((1/2 * ln((1 + abs(connectivity(connectivity < 1-eps))) ./ (1 - abs(connectivity(connectivity < 1-eps))))), 0, sqrt(nTimes - 3));
    elseif inputs.normalize % If false, use t-test and standard Gaussian
      pValues(connectivity < 1-eps) = normcdf(abs(connectivity(connectivity < 1-eps)) ./ sqrt(1 - connectivity(connectivity < 1-eps).^2) * sqrt(nTimes - 2), 0, 1);
    else
      pValues = NaN;
    end
end

end %% <== FUNCTION END
