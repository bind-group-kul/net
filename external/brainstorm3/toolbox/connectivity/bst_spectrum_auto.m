function [spectra, freq] = bst_spectrum_auto(X, inputs)
% BST_SPECTRUM  Main method for calculating the autospectrum of each of a set of signals.
%
% Inputs:
%   X           - MX signals, each of length N
%                 [X: MX x N matrix]
%   inputs      - Structure of parameters:
%   |-freq      - Frequencies of interest
%   |             [F: NF x 1 vector]
%   |-Fs        - Sampling rate (we assume uniform sampling rate)
%   |             [FS: scalar, FS > freq(end)*2]
%   |-method    - Method for calculating power spectral densities:
%   |               cov/mcov/yulear/burg - parametric, autoregression
%   |                  periodogram/welch - nonparametric (<== default)
%   |
%   |------------ Also pass parameters specific to the method if desired
%
% Outputs:
%   spectra       - (i, j, :) is the magnitude spectrum between signals i & j
%                   [C: MX x MY x NF matrix]
% Notes:
% The periodogram estimates are done in-house using only MatLab's FFT implementation.

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

% Frequency and sampling rate
freq = inputs.freq;
Fs = inputs.Fs;

% Default: nonparametric approach
if ~isfield(inputs, 'method');
  method = 'periodogram';
else
  method = inputs.method;
end

%% Calculate!
switch method
  
  %% Smoothing (Welch's overlapping segments) direct spectral estimator
  case {'periodogram', 'welch'} 
   
    % Default: segment length trades off resolution for variance
    if ~isfield(inputs, 'segmentLength')
      segmentLength = 64;
    else
      segmentLength = inputs.segmentLength;
    end
    
    % Default: overlap pct trades of speed for resolution
    if ~isfield(inputs, 'overlap')
      overlap = 0.5;
    else
      overlap = inputs.overlap;
    end
    
    % Default: Parzen window shows most stability
    if ~isfield(inputs, 'windowName')
      windowName = 'parzenwin';
    else
      windowName = inputs.windowName;
    end
    
    % Default: Small amount of taper
    if ~isfield(inputs, 'taperPct')
      taperPct = 0;
    else
      taperPct = inputs.taperPct;
    end
    
    % Default: 95% confidence interval
    if ~isfield(inputs, 'ci')
      ci = 0.95;
    else
      ci = inputs.ci;
    end
    
    % Default: no maximum frequency resolution
    if ~isfield(inputs, 'maxfreqres')
      maxfreqres = [];
    else
      maxfreqres = inputs.maxfreqres;
    end
    
    [spectra, freq] = bst_spectrum_periodogram(X, freq, Fs, segmentLength, overlap, windowName, taperPct, ci, maxfreqres);
    
  %% Parametric estimation via multivariate AR -- NOT DONE
  case {'cov', 'mcov', 'yulear', 'burg'}
    
%     % Default: Order 10 used in BrainStorm
%     if ~isfield(inputs, 'order')
%       order = 10;
%     else
%       order = inputs.order;
%     end
%     
%     % Default: Single-trial
%     if ~isfield(inputs, 'nTrials')
%       nTrials = 1;
%     else
%       nTrials = inputs.nTrials;
%     end
%     
%     [transfers, noiseVariance] = bst_mvar(X, order, nTrials, true);
%     noiseVariance = squeeze(noiseVariance(:, :, end));
%     spectra = bst_spectrum_mvar(transfers, freq, Fs, noiseVariance);
    
%     lag = repmat(struct('a', []), 1, 6);
%     for m = 1:order
%       lag(m).a = -transfers(:, (m-1)*size(transfers,1) + size(transfers,1));
%     end
%     results = spm_mar_spectra(struct('p', order, 'noise_cov', noiseVariance, 'lag', lag, 'd', size(data,1)), freq, Fs, 0);
%     spectra = abs(results.P)/Fs;
    
  %% Multitaper method using a Slepian basis -- NOT STARTED
  case 'mtm'
    
%     estimator = eval(['spectrum.' method '(varargin{:})']);
%     
%     if length(varargin) == 2
%       [spectra, lower, upper] = bst_spectrum_toolbox(estimator, data, Fs, freq, varargin{2});
%     else
%       [spectra, lower, upper] = bst_spectrum_toolbox(estimator, data, Fs, freq);
%     end
    
  %% Nonparametric estimation of signal basis -- NOT STARTED
  case 'music'
    
%     estimator = eval(['spectrum.' method]);
%     
%     if length(varargin) == 2
%       [spectra, lower, upper] = bst_spectrum_toolbox(estimator, data, Fs, freq, varargin{2});
%     else
%       [spectra, lower, upper] = bst_spectrum_toolbox(estimator, data, Fs, freq);
%     end
    
end

end %% <== FUNCTION END

%% =============================================== estimation via periodogram with Welch's overlapping segments ===============================================
function [spectra, freq, lower, upper] = bst_spectrum_periodogram(X, freq, Fs, segmentLength, overlap, windowName, taperPct, ci, maxfreqres)
% BST_PERIODOGRAM   Calculate two-sided autoperiodogram
%
% Inputs:
%   X               - MX signals - one in each column - each of length N
%                     [X: MX x N matrix]
%   inputs          - Structure of parameters:
%   freq            - Frequencies of interest
%                     [F: NF x 1 vector]
%   Fs              - Sampling rate (we assume uniform sampling rate)
%                     [FS: scalar, FS > freq(end)*2]
%   segmentLength   - Length of each window
%                     For basic periodogram, set segmentLength = N
%   overlap         - percentage overlap within a segment
%   windowName      - Name of window used to smooth spectrum in frequency domain
%   taperPct        - % of rolloff to begin/end each window
%   ci              - Confidence interval at each frequency
%   maxfreqres      - Maximum frequency resolution in Hz, to limit NFFT (default=empty, ie no limit)
%
% Outputs:
%   spectra         - (i, j, :) is the magnitude spectrum between signals i & j
%                     [C: M x M x NF matrix]
%   lower           - lower bound of confidence interval at each frequency
%                     [L: M x M x NF matrix]
%   upper           - upper bound of confidence interval at each frequency
%                     [U: M x M x NF matrix]

%% ===== SETUP =====
nX = size(X, 1);
nTimes = size(X, 2);

% Segment indices - discard final timepoints
overlapLength = floor(overlap*segmentLength);
nSegments = floor((nTimes-overlapLength)/(segmentLength-overlapLength));
partialLength = segmentLength - overlapLength;
segmentStart = partialLength * (0:(nSegments-1)) + 1;
segmentEnd = segmentStart + (segmentLength-1);
if segmentEnd(end) > nTimes
  segmentStart(end) = [];
  segmentEnd(end) = [];
end
segmentIndices = [segmentStart; segmentEnd];

% Frequencies of interest are not defined
if isempty(freq)
    % Maximum default resolution: 1 Hz
    if ~isempty(maxfreqres) && (nTimes > round(Fs / maxfreqres))
        nFFT = 2^nextpow2( round(Fs / maxfreqres) );
    % Use the default for FFT 
    else
        nFFT = 2^nextpow2( nTimes );
    end
% FFT is done over program-defined frequencies for speed
else
    freq = sort(freq(:));
    nFFT = 2^nextpow2(max(length(freq)-1, (Fs/2)/min(diff(freq))))*2;
end
freqInitial = Fs/2*linspace(0, 1, nFFT/2 + 1)'; % NOTE the transpose
freqInitial(end) = [];

% Frequency smoother (represented as time-domain multiplication)
% smoother = window(windowName, segmentLength);
% taperer = tukeywin(segmentLength, taperPct);
smoother = window(windowName, segmentLength) .* tukeywin(segmentLength, taperPct);
smoother = smoother / sqrt(sum(smoother.^2));

%% ===== EVERY SEGMENT (SAVE FOR THE LAST PARTIAL SEGMENT) =====
spectra = zeros(nX, length(freqInitial));
% Add spectrum of each segment onto the aggregation
for idxSegment = 1:nSegments % To save time/space I collapsed everything to deal with only autospectra
    specific = abs(fft(bst_bsxfun(@times, X(:, segmentIndices(1,idxSegment):segmentIndices(2,idxSegment)), smoother'), nFFT, 2)).^2;
    spectra = spectra + specific(:, 1:(nFFT/2));
end

%% ===== INTERPOLATION TO DESIRED FREQS =====
% Normalize for segments and sampling rate
spectra = spectra / (nSegments * Fs);

% Interpolation if desired
if ~isempty(freq) % Interpolate to desired frequencies
    spectra = abs(interp1(freqInitial, spectra.', freq).');
else % No re-interpolation of the results
    freq = freqInitial;
    spectra = abs(spectra);
end

%% ===== CONFIDENCE INTERVAL =====
% Confidence interval from Kay, p. 76, eqn 4.16:
if nargout > 2
    alpha = 1 - ci;
    lower = spectra*(2*nSegments ./ chi2inv(1-alpha/2,2*nSegments))/(nSegments*sum(smoother)^2);
    upper = spectra*(2*nSegments ./ chi2inv(alpha/2,2*nSegments))/(nSegments*sum(smoother)^2);
end

end %% <== FUNCTION END

%% ======================================================== estimation for multivariate autoregression ========================================================
function [spectra, forward, freq] = bst_spectrum_mvar(transfers, freq, Fs, noiseCovariance)
% BST_MVAR_SPECTRUM   Given transfer matrix, calculate power spectral density of each resulting AR signal.
%                     In addition, if desired, output the frequency-domain transfer function.
%
% Inputs:
%   transfers         - Transfer matrices in AR process.
%                       [A: Flat (N x NP) or Expanded (N x N X P)]
%                       [N = # of sources, P = order]
%   freq              - Frequencies at which parametric spectrum is desired.
%   Fs                - Sampling frequency of data
%   noiseCovariance   - Variance of residuals
%                       [C: N x N matrix]
%
% Outputs:
%   spectra           - Magnitude cross-spectrum between each pair of variables.
%   forward           - Forward transform in frequency from source to sink.
%   freq              - Frequencies used (for reference if not specified)
%
% Call:
%   [spectra, ~, freq] = bst_mvar_spectrum(transfers) <-- basic
%   spectra = bst_mvar_spectrum(transfers, freq) <-- desired (normalized) freqs
%   [spectra, ~, freq] = bst_mvar_spectrum(transfers, [], Fs) <-- known sampling
%   spectra = bst_mvar_spectrum(transfers, freq, Fs) <-- desired frequencies
%
%   [spectra, forward, freq] = bst_mvar_spectrum(transfers) <-- also forward
%   [spectra, forward] = bst_mvar_spectrum(transfers, freq, Fs) <- at known pts

%% Setup

transfersFlat = reshape(transfers, nSources, []);
nFFT = 2^nextpow2(Fs/min(diff(freq)));
initial = linspace(0, Fs/2, nFFT);
inverse = zeros(nSources, nSources, nFFT);

%% For each causality pair, calculate inverse transfer
% Inverse transfer means the transfer function from the sources to the innovations. We calculate this at each frequency.
% The inverse transfer from source a to innovation b is
%                1 - \sum_{n=1}^N a_{ab} [n] e^{-j2pi * f * n}
coefficients = [eye(nSources) -transfersFlat];
for start = 1:nSources
  for stop = 1:nSources
    inverseFull = fft(coefficients(stop, start + (0:order)*nSources), nFFT*2);
    inverse(stop, start, :) = inverseFull(1:nFFT);
  end
end

%% Move to forward transfer and spectrum
% The forward transfer is the inverse of the inverse transfer at each frequency f. Denoted H(f), the power spectral density is then HH' at each frequency.

if nSources > 1 % Have to use for loop
  
  spectra = zeros(nSources, nSources, nFFT);
  forward = zeros(nSources, nSources, nFFT);
  for idxFreq = 1:nFFT
    A = inverse(:, :, idxFreq); % Inverse transfer

    % Forward transfer
    H = inv(A);
		if any(isnan(H(:)) | isinf(H(:)))
			H = 0;
		end

    H = H ./ sqrt(Fs); % Normalization for sampling rate

    % Store power of forward transfer at each signal as well as power spectrum
    spectra(:, :, idxFreq) = H * noiseCovariance * H';
    forward(:, :, idxFreq) = abs(H).^2;
  end
  
elseif nSources == 2 % Speed increase when bivariate PSD
  
  % Forward transfer: Use formula for 2x2 inverse
  H = zeros(2, 2, nFFT);
  H(1,1,:) = inverse(2,2,:); H(1,2,:) = -inverse(1,2,:); 
  H(2,1,:) = -inverse(2,1,:); H(2,2,:) = inverse(1,1,:);
  detInverse = inverse(1,1,:).*inverse(2,2,:) - inverse(1,2,:).*inverse(2,1,:);
  H = H ./ repmat(detInverse, [2 2 1]);
  H = H ./ sqrt(Fs); % Normalization for sampling rate
  
  % Store power of forward transfer at each signal as well as power spectrum
  spectra = zeros(nSources, nSources, nFFT);
  % for idxFreq = 1:nFFT
  %   spectra(:, :, idxFreq) = H(:,:,idxFreq) * noiseCovariance * H(:,:,idxFreq)';
  % end
  spectra(1,1,:) = ...
    noiseCovariance(1,1) * H(1,1,:) .* conj(H(1,1,:)) ...
    + noiseCovariance(1,2) * H(1,2,:) .* conj(H(1,1,:)) ...
    + noiseCovariance(1,2) * H(1,1,:) .* conj(H(1,2,:)) ...
    + noiseCovariance(2,2) * H(1,2,:) .* conj(H(1,2,:));
  spectra(1,2,:) = ...
    noiseCovariance(1,1) * H(2,1,:) .* conj(H(1,1,:)) ...
    + noiseCovariance(1,2) * H(2,2,:) .* conj(H(1,1,:)) ...
    + noiseCovariance(1,2) * H(2,1,:) .* conj(H(1,2,:)) ...
    + noiseCovariance(2,2) * H(1,2,:) .* conj(H(1,2,:));
  spectra(2,1,:) = conj(spectra(1,2,:));
  spectra(2,2,:) = ...
    noiseCovariance(1,1) * H(2,1,:) .* conj(H(2,1,:)) ...
    + noiseCovariance(1,2) * H(2,2,:) .* conj(H(2,1,:)) ...
    + noiseCovariance(1,2) * H(2,1,:) .* conj(H(2,2,:)) ...
    + noiseCovariance(2,2) * H(1,2,:) .* conj(H(2,2,:));
  forward = abs(H).^2;
  
else % Speed increase when it is univariate PSD
  
  H = zeros(1, 1, nFFT);
  H(abs(inverse) > 1e-60) = 1 ./ inverse(abs(inverse) > 1e-60);
  H = H ./ sqrt(Fs);
  spectra = abs(H).^2 * squeeze(noiseCovariance);
  forward = abs(H).^2;
  
end

%% Interpolate magnitudes to desired frequencies
forward = reshape(interp1(initial, reshape(forward, [], nFFT).', freq).', [nSources nSources length(freq)]);
spectra = reshape(interp1(initial, reshape(spectra, [], nFFT).', freq).', [nSources nSources length(freq)]);

%% Spectrum is absolute value of responses
spectra = abs(spectra);
forward = abs(forward);

end