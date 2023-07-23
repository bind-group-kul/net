function [spectra, freq, pValues] = bst_cohn(X, Y, Fs, segmentLength, MaxFreqRes, isSymmetric, ImagingKernel, waitMax)
% BST_COHN: Optimized version of bst_coherence.

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
% Authors: Sergul Aydore, Syed Ashrafulla, Francois Tadel, 2013


%% ===== INITIALIZATIONS =====
% Default options
if (nargin < 8) || isempty(waitMax)
    waitMax = 100;
end
if (nargin < 7) || isempty(ImagingKernel)
    ImagingKernel = [];
end
if (nargin < 6) || isempty(isSymmetric)
    isSymmetric = 0;
end
if (nargin < 5) || isempty(MaxFreqRes)
    MaxFreqRes = 1;
end
if (nargin < 4) || isempty(segmentLength)
    segmentLength = 64;
end
overlap = 0.5;
% Signal properties
nX = size(X, 1); 
nY = size(Y, 1);
nTimes = size(X, 2);
% Get current progress bar position
waitStart = bst_progress('get');

% Segment indices - discard final timepoints
overlapLength = floor(overlap * segmentLength);
nSegments = floor((nTimes-overlapLength) / (segmentLength-overlapLength));
partialLength = segmentLength - overlapLength;
segmentStart = partialLength * (0:(nSegments-1)) + 1;
segmentEnd = segmentStart + (segmentLength-1);
if (segmentEnd(end) > nTimes)
    segmentStart(end) = [];
    segmentEnd(end) = [];
end
segmentIndices = [segmentStart; segmentEnd];

% Maximum default resolution: 1 Hz
if ~isempty(MaxFreqRes) && (nTimes > round(Fs / MaxFreqRes))
    nFFT = 2^nextpow2( round(Fs / MaxFreqRes) );
% Use the default for FFT 
else
    nFFT = 2^nextpow2( nTimes );
end
% Output frequencies
freq = Fs/2*linspace(0, 1, nFFT/2 + 1)';
freq(end) = [];

% Frequency smoother (represented as time-domain multiplication)
smoother = window('parzenwin', segmentLength) .* tukeywin(segmentLength, 0);
smoother = smoother / sqrt(sum(smoother.^2));


%% ===== VERSION 1: for loops, full matrix =====
if ~isSymmetric
    isCalcAuto = ~isequal(X,Y);
    % Initialize variables
    spectra = zeros(nX, nY, length(freq));
    if isCalcAuto
        autoX = zeros(nX, 1, length(freq));
        autoY = zeros(1, nY, length(freq));
    end
    % Cross-spectrum
    for iSeg = 1:nSegments
        bst_progress('set', round(waitStart + iSeg/nSegments * 0.7 * waitMax));
        % Get time indices for this segment
        iTime = segmentIndices(1,iSeg):segmentIndices(2,iSeg);
        % Frequency domain spectrum after smoothing and tapering
        fourierX = fft(bst_bsxfun(@times, X(:,iTime), smoother'), nFFT, 2);
        fourierY = fft(bst_bsxfun(@times, Y(:,iTime), smoother'), nFFT, 2);
        % Calculate for each frequency: fourierX * fourierY'
        for f = 1:length(freq)
            spectra(:,:,f) = spectra(:,:,f) + fourierX(:,f) * fourierY(:,f)';
        end
        % Calculate auto-spectra if needed
        if isCalcAuto
            autoX = autoX + reshape(abs(fourierX(:,1:(nFFT/2)) .^ 2), nX, 1, length(freq));
            autoY = autoY + reshape(abs(fourierY(:,1:(nFFT/2)) .^ 2), 1, nY, length(freq));
        end
    end
    bst_progress('set', round(waitStart + 0.75 * waitMax));
    % Normalize for segments and sampling rate
    spectra = spectra / (nSegments * Fs);
    if isCalcAuto
        autoX = autoX / (nSegments * Fs);
        autoY = autoY / (nSegments * Fs);
    end
    
    % Project in source space
    if ~isempty(ImagingKernel)
        % Initialize output matrix
        nX = size(ImagingKernel,1);
        nY = size(ImagingKernel,1);
        Rs = zeros(nX, nY, length(freq));
        % Loop on the frequencies to make the multiplication
        for iFreq = 1:length(freq)
            Rs(:,:,iFreq) = ImagingKernel * spectra(:,:,iFreq) * ImagingKernel';
        end
        spectra = Rs;
        clear Rs;
    end
    
    % [NxN]: Auto spectrum for X is contained within cross-spectral estimation
    bst_progress('set', round(waitStart + 0.9 * waitMax));
    if ~isCalcAuto
        iAuto = sub2ind(size(spectra), ...
            repmat((1:nX)', length(freq), 1), ... 
            repmat((1:nY)', length(freq), 1), ... 
            reshape(repmat(1:length(freq), nX, 1),[],1));
        autoX = reshape(spectra(iAuto), nX, 1, length(freq));
        autoY = reshape(spectra(iAuto), 1, nY, length(freq));
    end
    
    % Divide by the corresponding autospectra for each frequency
    spectra = spectra .* conj(spectra);
    spectra = bst_bsxfun(@rdivide, spectra, autoX);
    spectra = bst_bsxfun(@rdivide, spectra, autoY);
    % Save the auto-spectra as the diagonal
    if ~isCalcAuto
        spectra(iAuto) = autoX(:);
    end
    
    
%% ===== VERSION 2: Vectorized + Symetrical =====
else
    % Indices for the multiplication
    [iY,iX] = meshgrid(1:nX,1:nY);
    % Find the values above the diagonal
    indSym = find(iX <= iY);
    % Cross-spectrum
    spectra = zeros(length(indSym), length(freq));
    for iSeg = 1:nSegments
        bst_progress('set', round(waitStart + iSeg/nSegments * 0.7 * waitMax));
        % Get time indices for this segment
        iTime = segmentIndices(1,iSeg):segmentIndices(2,iSeg);
        % Frequency domain spectrum after smoothing and tapering
        fourierX = fft(bst_bsxfun(@times, X(:,iTime), smoother'), nFFT, 2);
        fourierY = conj(fft(bst_bsxfun(@times, Y(:,iTime), smoother'), nFFT, 2));
        % Calculate for each frequency: fourierX * fourierY'
        spectra = spectra + fourierX(iX(indSym),1:(nFFT/2)) .* fourierY(iY(indSym),1:(nFFT/2));
    end
    % Normalize for segments and sampling rate
    spectra = spectra / (nSegments * Fs);

    % Project in source space
    if ~isempty(ImagingKernel)
        bst_progress('text', sprintf('Projecting to source domain [%d>%d]...', nX, size(ImagingKernel,1)));
        % Expand matrix
        spectra = process_compress_sym('Expand', spectra, nX, 1);
        bst_progress('set', round(waitStart + 0.75 * waitMax));
        % Reshape [nX x nY]
        spectra = reshape(spectra, nX, nY, length(freq));
        % Initialize output matrix
        nX = size(ImagingKernel,1);
        nY = size(ImagingKernel,1);
        Rs = zeros(nX, nY, length(freq));
        % Loop on the frequencies to make the multiplication
        for iFreq = 1:length(freq)
            Rs(:,:,iFreq) = ImagingKernel * spectra(:,:,iFreq) * ImagingKernel';
        end
        bst_progress('set', round(waitStart + 0.85 * waitMax));
        % Reshape
        Rs = reshape(Rs, nX * nY, length(freq));
        % Compress matrix again
        spectra = process_compress_sym('Compress', Rs);
        % Remove the time dimension
        clear Rs;
        % Re-estimate indices
        [iY,iX] = meshgrid(1:nX,1:nY);
        indSym = find(iX <= iY);
    end
        
    bst_progress('text', sprintf('Normalizing: Coherence [%dx%d]...', nX, nX));
    bst_progress('set', round(waitStart + 0.90 * waitMax));
    % Find auto-spectrum in the list
    indDiag = (iX(indSym) == iY(indSym));
    autoX = spectra(indDiag,:);
    % Divide by the corresponding autospectra for each frequency
    spectra = spectra .* conj(spectra);
    spectra = spectra ./ (autoX(iX(indSym),:) .* autoX(iY(indSym),:));
    % Save the auto-spectra as the diagonal
    spectra(indDiag,:) = autoX;
    % Reshape to have the frequencies in third dimension
    spectra = reshape(spectra, length(indSym), 1, length(freq));
end

bst_progress('set', round(waitStart + 0.95 * waitMax));





