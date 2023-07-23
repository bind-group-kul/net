function sPAC = bst_pac(F, sRate, bandNesting, bandNested, isFullMaps, isUseParallel, isUseMex)
% BST_PAC: Calculate the directPAC metric for all the input time series.
%
% USAGE:  sPAC = bst_pac(F, sRate, bandNesting, bandNested, isFullMaps=0, isUseParallel=0, isUseMex=0)
% 
% INPUTS:
%    - F             : Signal time series [nSignals x nTime]
%    - sRate         : Signal sampling rate (in Hz)
%    - bandNesting   : Candidate frequency band of phase driving oscillations e.g., [0.5 48] Hz
%                      Note that cycle minimal frequency bandNesting(1) needs to be
%                      at least 10 times smaller than signal length (duration)    
%    - bandNested    : Candidate frequency band of nested oscillatiosn e.g., [48,300] Hz
%    - isFullMaps    : If 1, save the full directPAC maps
%    - isUseParallel : If 1, use parallel processing toolbox
%    - isUseMex      : If 1, use mex file instead of matlab loop
% 
% OUTPUTS:   sPAC structure [for each signal]
%    - ValPAC      : Value of maximum PAC 
%    - NestingFreq : Optimal nesting frequency (frequency for phase)
%    - NestedFreq  : Optimal nested frequency (frequency for amplitude)
%    - DirectPAC   : Full array of direct PAC measures for all frequyency pairs
%    - PhasePAC    : 
%
% DOCUMENTATION:
%    - For more information, please refer to the method described in the following article:
%         Özkurt TE, Schnitzler A, 
%         "A critical note on the definition of phase-amplitude cross-frequency coupling" 
%         J Neurosci Methods. 2011 Oct 15;201(2):438-43
%    - The current code is inspired from Ryan Canolty's code provided originally with the article:
%         Canolty RT, Edwards E, Dalal SS, Soltani M, Nagarajan SS, Kirsch HE, Berger MS, Barbaro NM, Knight RT,
%         "High gamma power is phase-locked to theta oscillations in human neocortex",
%         Science, 2006 Sep 15;313(5793):1626-8.

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
% Authors: Ryan Canolty, 2006
%          Esther Florin, Soheila Samiee, Sylvain Baillet, 2011-2013
%          Francois Tadel, 2013

% Parse inputs
if (nargin < 6) || isempty(isUseMex)
    isUseMex = 0;
end
if (nargin < 6) || isempty(isUseParallel)
    isUseParallel = 0;
end
if (nargin < 5) || isempty(isFullMaps)
    isFullMaps = 0;
end
if (nargin < 4) || isempty(bandNesting) || isempty(bandNested)
    bandNesting = [];
    bandNested  = [];
end
% Initialize returned variables
nSignals = size(F,1);
sPAC.ValPAC      = zeros(nSignals,1);
sPAC.NestingFreq = zeros(nSignals,1);
sPAC.NestedFreq  = zeros(nSignals,1);
sPAC.PhasePAC    = zeros(nSignals,1);
% Number of time points
nTime = size(F,2);

% ===== DEFINE LOW/HIGH FREQ BINNING =====
% Initial code from Esther (deprecated)
if isempty(bandNesting)
    % === LOW FREQ ===
    centerLow = [2:.5:12, 14:2:48];
    %centerLow = [0.5:.2:2, 2.5:.5:12, 14:2:48];
    % === HIGH FREQ ===
    % Definitions
    fmin = 1;
    fmax = 250;
    numfreqs = 70;
    fstep = 0.75;
    % Calculate center frequencies
    temp1 = (0:numfreqs-1) * fstep;
    temp2 = logspace(log10(fmin), log10(fmax), numfreqs);
    temp2 = (temp2-temp2(1)) * ((temp2(end)-temp1(end)) / temp2(end)) + temp2(1);
    centerHigh = temp1 + temp2;
    % Taking only frequencies from 80 to 150 Hz
    centerHigh = centerHigh(51:62);
    % Group both
    chirpCenterFreqs = [centerLow, centerHigh];
    lfreq = 1:length(centerLow);
    hfreq = length(centerLow) + (1:length(centerHigh));
% New Esther/Soheila code
else
    % Definitions
    fmin = min(bandNesting);
    fmax = sRate/3;
    numfreqs = round(sRate/9);
    fstep = 0.75;
    % Calculate center frequencies
    temp1 = (0:numfreqs-1) * fstep;
    temp2 = logspace(log10(fmin), log10(fmax), numfreqs);
    temp2 = (temp2-temp2(1)) * ((temp2(end)-temp1(end)) / temp2(end)) + temp2(1);
    chirpCenterFreqs = temp1 + temp2;
    % Remove unused frequencies
    chirpCenterFreqs(chirpCenterFreqs > max(bandNested)) = [];      %%% ESTHER
    chirpCenterFreqs((chirpCenterFreqs < min(bandNested)) & (chirpCenterFreqs >= max(bandNesting))) = [];      %%% ESTHER
    % Indices of center frequencies in the upper frequency range
    hfreq = find( chirpCenterFreqs >= min(bandNested) );
    % Number of cf bins to evaluate for PAC with lower-frequency oscillations
    % lfreq = find(chirpCenterFreqs < min(bandNested));
    lfreq = find(chirpCenterFreqs < max(bandNesting));   %%% ESTHER
end

% ===== PAC OPTIONS =====
% Will contain all scores of PAC between all pairs of low-f and high-f bins 
if isFullMaps
    sPAC.DirectPAC = zeros(nSignals, 1, length(lfreq), length(hfreq));
else
    sPAC.DirectPAC = [];
end
sPAC.LowFreqs  = chirpCenterFreqs(lfreq);
sPAC.HighFreqs = chirpCenterFreqs(hfreq);

% ===== CALCULATE CHIRPLETS =====
% Calculate chirplets
[chirpF, Freqs] = bst_chirplet(sRate, nTime, chirpCenterFreqs);

% ===== BAND PASS INPUT SIGNAL =====
% NOT IN ESTHER'S ORIGINAL CODE
if ~isempty(bandNesting)
    % Apply the band-pass filter to eliminate all the frequencies that we are not interested in
    bandLow  = min(bandNesting(1)*.5, sRate/2);
    bandHigh = min(bandNested(end)*1.5, sRate/2 - min(20, sRate/2 * 0.2) - 1);
    F = bst_bandpass(F, sRate, bandLow, bandHigh, 1, 1);
end

% ===== FFT OF SIGNALS =====
% Transform sensor time series into analytic signals
F_fft = fft(F, length(Freqs), 2);
% This step scales analytic signal such that: real(analytic_signal) = raw_signal
% but note that analytic signal energy is double that of raw signal energy
F_fft(:,Freqs<0) = 0;
F_fft(:,Freqs>0) = 2 * F_fft(:,Freqs>0);
clear F;

% Define minimal frequency support with non-zeros chirplet coefficients
[row,scol] = find(F_fft ~= 0);
scol = max(scol)+1;
[chirprow,chirpcol] = find(squeeze(chirpF(1,:,:)) ~= 0);
chirprow = max(chirprow)+1;
% Minimal number of frequency coefficients
nfcomponents = min(chirprow,scol); 
clear row scol chirprow chirpcol


% ===== CALULATE PAC =====
% Filter signal in frequency domain
F_fft = bst_bsxfun(@times, F_fft(:, 1:nfcomponents, ones(1,length(chirpCenterFreqs))), ...
                           chirpF(1,1:nfcomponents,:));
% Convert back to time domain
fs = ifft(F_fft, length(Freqs), 2);
clear F_fft;

% Magnitude and phase about each chirplet center frequency
AMP = abs( fs(:, 1:nTime, length(lfreq)+1:end ) );
PHASE = exp(1i * angle( fs(:, 1:nTime, 1:length(lfreq))));
clear fs;

% === USING MEX FILES ===
if isUseMex && bst_compile_mex('toolbox/connectivity/private/direct_pac_mex', 0)
    % Initialize local directPAC matrix for current signals
    directPAC = zeros(length(lfreq), length(hfreq), nSignals);
    % Compute direct PAC index for each high-freq and low-freq pair
    % Permute dimensions of PHASE & AMP, easier to loop through in C
    if isUseParallel
        parfor iSignal = 1:nSignals
            directPAC(:,:,iSignal) = direct_pac_mex(permute(PHASE(iSignal,:,:), [2,3,1]), permute(AMP(iSignal,:,:), [2,3,1]));
        end
    else
        directPAC = direct_pac_mex(permute(PHASE, [2,3,1]), permute(AMP, [2,3,1]));
    end
    directPAC = permute(directPAC, [3,1,2]);
% === USING MATLAB SCRIPTS ===
else
    % Initialize local directPAC matrix for current signals
    directPAC = zeros(nSignals, length(lfreq), length(hfreq));
    % Compute direct PAC index for each high-freq and low-freq pair
    if isUseParallel
        parfor ihf = 1:length(hfreq)
            directPAC(:,:,ihf) = reshape(sum( bst_bsxfun(@times, PHASE, AMP(:,:,ihf)), 2 ), [nSignals, length(lfreq)]);
        end
    else
        for ihf = 1:length(hfreq)
            directPAC(:,:,ihf) = reshape(sum( bst_bsxfun(@times, PHASE, AMP(:,:,ihf)), 2 ), [nSignals, length(lfreq)]);
        end
    end
end

% Finalize scaling of direct PAC metric
tmp2 = sqrt( ( sum(AMP.*AMP, 2) ) );
directPAC = abs(directPAC) ./ tmp2(:,ones(1,size(directPAC,2)),:);
directPAC = directPAC / sqrt(nTime);

% Find pair of maximum pac frequencies
[sPAC.ValPAC, indmax] = max(reshape(directPAC, nSignals, []), [], 2);
[imaxl, imaxh] = ind2sub([size(directPAC,2), size(directPAC,3)], indmax);
sPAC.NestingFreq = chirpCenterFreqs(lfreq(imaxl));
sPAC.NestedFreq = chirpCenterFreqs(hfreq(imaxh));
% Phase estimation
pacEst = AMP(1,:,imaxh).*PHASE(1,:,imaxl);
sPAC.PhasePAC = angle(mean(pacEst))/pi*180 + 90;

% Save directPAC values in returned structure
if isFullMaps
    sPAC.DirectPAC(:,1,:,:) = directPAC;
end





