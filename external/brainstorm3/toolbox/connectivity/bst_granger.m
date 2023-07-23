function [connectivity, spectral, idxOrderTotal] = bst_granger(sinks, sources, inputs)
% BST_GRANGER       Granger causality between any two signals.
%
% Inputs:
%   sinks           - First set of signals, one signal per row
%                     [X: A x N or A x N x T matrix]
%   sources         - Second set of signals, one signal per row
%                     [Y: B x N or B x N x T matrix]
%                     (default: Y = X)
%   inputs          - Structure of parameters:
%   |-order         - Maximum lag in estimating causality (k)
%   |-nTrials       - # of trials in concantenated signal
%   |-standardize   - If true, remove mean from each signal.
%   |                 If false, assume signal has already been detrended
%   |-flagFPE       - If true, optimize order for autoregression
%   |                 If false, force same order in all autoregression
%   |-freq          - If given, frequencies at which spectral Granger causality
%   |                 is to be calculated.
%   |-Fs            - Sampling frequency of data (default: 1)
%
% Outputs:
%   GC              - A x B matrix of Granger causalities from source to sink, removing the effects of other signals.
%                     For each signal pair (a,b) we calculate GC_(b -> a) as below and store it in GC(a,b).
%
%                                       Var(x_a[t] | x_a[t-1, ..., t-k])         
%                             ----------------------------------------------------
%                             Var(x_a[t] | x_a[t-1, ..., t-k], y_b[t-1, ..., t-k])
%
%
%                     By default, GC(a,a) = 0 if Y is empty.
%
% See also BST_GRANGER_SEMIPARTIAL, BST_GRANGER_PARTIAL, BST_MVAR
%
% Call:
%   GC = bst_granger(sinks, sources, inputs)
%   inputs.order = 10; % Remove up to lag-10 effects on the mean
%   inputs.nTrials = 10; % Handle 10 trials, to get more accurate estimators of covariance and conditional variance
%   inputs.standardize = true; % Only do this if you haven't standardized the data already.
%   inputs.flagFPE = true; % Only do this if you haven't standardized the data already.

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

% Dimensions of the signals
nSinks = size(sinks, 1);
if ndims(sinks) == 3
  inputs.nTrials = size(sinks,3);
  sinks = reshape(sinks, nSinks, []);
end
nSamples = size(sinks, 2);
nTimes = nSamples / inputs.nTrials;

% Default: auto-causality
if (ndims(sources) == ndims(sinks) && all(size(sources) == size(sinks)) && max(abs(sources(:) - sinks(:))) < eps)
  
  nSources = nSinks; duplicate = true;
  
else
  
  nSources = size(sources, 1);
  duplicate = false;
  sources = reshape(sources, nSources, []);

end

% Remove linear effects unless told not to do so (because done already)
if inputs.standardize
  detrender = [1:nTimes; ones(1, nTimes)];
  sinks = sinks - (sinks/detrender) * detrender;
  sinks = diag(sqrt(sum(sinks.^2, 2))) \ sinks;
  
  % Do for Y as well unless Y is supposed to be X
  if ~duplicate
    detrender = [1:nTimes; ones(1, nTimes)];
    sources = sources - (sources/detrender) * detrender;
    sources = diag(sqrt(sum(sources.^2, 2))) \ sources;
  else
    sources = sinks;
  end
  
  inputs.standardize = false;
end

% Preallocate
if inputs.flagFPE
  restCovTotal = zeros(inputs.order+1, nSinks); restOrderTotal = zeros(nSinks, 1);
  unCovTotal = zeros(2, 2, inputs.order+1, nSinks, nSources); unOrderTotal = zeros(nSinks, nSources);
else
  restCovTotal = zeros(1, nSinks); restOrderTotal = zeros(nSinks, 1);
  unCovTotal = zeros(2, 2, 1, nSinks, nSources); unOrderTotal = zeros(nSinks, nSources);
end

%% Iterate over each possible sink
for idxSink = 1:nSinks

  % Restricted (without the source) model for given sink
  [restTransfer, restCov, restOrderTotal(idxSink), restTransferFull, restCovTotal(:, idxSink)] = bst_mvar(sinks(idxSink, :), inputs.order, inputs.nTrials, inputs.flagFPE);

  % Unrestricted (with the source) model for given source
  % When Y = X, for sources indexed lower than sink, we will later use the unrestricted variance computed previously for causality in the reverse direction.
  for idxSource = 1:nSources
    if ~(duplicate && idxSink == idxSource) && max(abs(sinks(idxSink, :) - sources(idxSource, :))) > eps % Unrestricted variance is required and not computed yet
      [unTransfer, unCov, unOrderTotal(idxSink, idxSource), unTransferFull, unCovTotal(:, :, :, idxSink, idxSource)] = ...
        bst_mvar([sinks(idxSink, :); sources(idxSource, :)], inputs.order, inputs.nTrials, inputs.flagFPE);
    end

  end

end

%% Connectivity calculation
connectivity = zeros(nSinks, nSources);

if inputs.flagFPE % Optimize order: choose the minimum inputs.inputs.order fit between restricted & unrestricted models for each causality estimation

  % Minimum order for each directed pair
  idxOrderTotal = bst_bsxfun(@min, restOrderTotal, unOrderTotal);

  % Iterate over pairs
  for idxSink = 1:nSinks
    for idxSource = 1:nSources

      if (duplicate && idxSink == idxSource) || max(abs(sinks(idxSink, :) - sources(idxSource, :))) < eps % Self-causality is default zero
        connectivity(idxSink, idxSource) = 0;
      elseif duplicate && idxSink > idxSource % Log-ratio of restricted variance to unrestricted variance, found on opposite directon on other diagonal spot
        idxOrder = idxOrderTotal(idxSink, idxSource);
        connectivity(idxSink, idxSource) = log(restCovTotal(idxOrder, idxSink) / unCovTotal(2, 2, idxOrder, idxSource, idxSink));
      else % Log-ratio of restricted variance to unrestricted variance
        idxOrder = idxOrderTotal(idxSink, idxSource);
        connectivity(idxSink, idxSource) = log(restCovTotal(idxOrder, idxSink) / unCovTotal(1, 1, idxOrder, idxSink, idxSource));
      end

    end
  end

else % Order is fixed, so just calculate Granger causality
  idxOrderTotal = inputs.order;

  for idxSink = 1:nSinks
    for idxSource = 1:nSources

      if (duplicate && idxSink == idxSource) || max(abs(sinks(idxSink, :) - sources(idxSource, :))) < eps % Self-causality is default zero
        connectivity(idxSink, idxSource) = 0;
      elseif duplicate && idxSink > idxSource % Log-ratio of restricted variance to unrestricted variance, found on opposite directon on other diagonal spot
        connectivity(idxSink, idxSource) = log(restCovTotal(1, idxSink) / unCovTotal(2, 2, 1, idxSource, idxSink));
      else % Log-ratio of restricted variance to unrestricted variance
        connectivity(idxSink, idxSource) = log(restCovTotal(1, idxSink) / unCovTotal(1, 1, 1, idxSink, idxSource));
      end

    end
  end  

end

%% Frequency-domain Granger causality: CURRENTLY NOT WORKING
if 0 % ~isempty(inputs.freq)

  % Partial variance of unrestricted residuals
  residualVar = repmat((1./diag(inv(unCov)))', [nSignals 1]);
  residualVar = repmat(residualVar, [1 1 length(freq)]);
  % We use the matrix inversion lemma: the inverse of the covariance has the inverse of the partial variances along the diagonals (as both are Schur
  % complements, see [1]). Thus, inverting the diagonal of the inverse covariance nets us the partial variances.
  % We then want to use that for every sink at each source, which is why we must transpose and then replicate it along the ROWS. In addition, we use this
  % constant at all frequencies which is why we replicate in the 1st dimension.
  
  % Spectra and power of forward system
  [spectra, forward] = bst_mvar_spectrum(unTransfer, struct('freq', inputs.freq, 'Fs', inputs.Fs, 'noiseCovariance', unCov));
  forward = abs(forward);
  sinkSpectra = zeros(size(spectra));
  for idxSignal = 1:nSignals
    sinkSpectra(idxSignal, :, :) = repmat(spectra(idxSignal, idxSignal, :), [1 nSignals 1]);
  end
  % We take the diagonal of the spectrum at each frequency (hence the power spectrum).
  % Then, we repeat it at every COLUMN because we are looking at the sink power spectrum (each ROW is a sink).
  
  % Geweke-Granger spectral causality
  restSpectra = sinkSpectra - forward .* residualVar;
  spectral = zeros(nSignals, nSignals, length(inputs.freq));
  idx = sinkSpectra > 0 & restSpectra > 0;
  spectral(idx) = log(sinkSpectra(idx) ./ restSpectra(idx)) / (Fs/2);
  
  % On the diagonal, return the partial power spectrum
  for idxFreq = 1:length(inputs.freq)
    current = spectra(:, :, idxFreq);
    
    if cond(current) < 1e20 % We have residual spectrum here
      
      % partial = 1./diag(inv(current));
      for m = 1:nSignals
        spectral(m, m, idxFreq) = 0; % partial(m);
      end
      
    else % There is a linear dependency so the partial spectrum must be ZERO
      
      for m = 1:nSignals
        spectral(m, m, idxFreq) = 0;
      end
      
    end
    
  end
  
else
  
  spectral = NaN;
  
end