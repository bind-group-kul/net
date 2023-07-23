function [a, el] = test_sin_remove(a_init, sfreq, FreqList)
% TEST_SIN_REMOVE: Test all the methods available in Brainstorm for sinusoid removal.
% 
% USAGE:  test_sin_remove(a_init, sfreq, FreqList)
%         test_sin_remove()
%         [a, el] = test_sin_remove();
%
% INPUT: 
%     - a_init : Signal to filter
%                Default: [cos(t)+cos(t*50)*.1; sin(t)+rand(1,length(t))*.1], with t=-pi:.0001:pi
%     - FreqList  : Frequencies to remove
%
% OUTPUT:
%     - a  : Cell-array oo the filtered signals for each method
%     - el : Computation time for each method

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
% Authors: Francois Tadel, 2011

% Define input signal
if (nargin < 1)
    % Define time vector
    sfreq  = 1000;
    Time = (1:5000) ./ sfreq;
    % Define signal
    t = Time*2*pi;
    a_init = 2 + cos(4*t) + cos(30*t+pi/4)*.4 + randn(1,length(t))*.05;
    FreqList = 30.0;
    
%     a_init = [a_init(end:-1:1), a_init, a_init(end:-1:1)];
%     Time = (1:15000) ./ sfreq;
%     t = Time*2*pi;
else
    Time = (1:size(a_init,2)) / sfreq;
end
% List of available methods
list_methods = {'mosher', 'moshermosher_extrap'};
% Intialize arrays
a  = cell(1,length(list_methods));
el = a;
isFigCreated = 0;
% Loop on all the methods
for i = 1:length(list_methods);
    try
        % Method selection
        method = list_methods{i};
        % Resample
        tic;
        a{i} = process_sin_remove('Compute', a_init, Time, FreqList, method); 
        el{i} = toc;
        % Plot initial signal
        if ~isFigCreated
            isFigCreated = 1;
            % Create figure: signal
            hFigSignal = figure('Name', 'Filter: signal', 'NumberTitle', 'off', 'Toolbar', 'figure', 'Units', 'normalized', 'Position', [0 0 1 1]);
            zoom on
            % Plot signal
            hAxesSignal(1) = PlotSignal(hFigSignal, 1, 'Initial signal', Time, a_init);
            % Create figure: signal
            hFigSpect(1) = figure('Name', 'Filter: |fft|', 'NumberTitle', 'off', 'Toolbar', 'figure', 'Units', 'normalized', 'Position', [0 0 1 1]);
            zoom on
            % Plot spectrum
            hAxesSpect(1) = PlotSpectrum(hFigSpect, 1, sprintf('Initial signal'), sfreq, a_init);
        end
        % Plot resampled signal
        axesTitle = sprintf('%s (%3.4fs)', method, el{i});
        hAxesSignal(i+1) = PlotSignal(hFigSignal, i+1, axesTitle, Time, a{i});
        % Plot resampled spectrum
        hAxesSpect(i+1) = PlotSpectrum(hFigSpect, i+1, axesTitle, sfreq, a{i});
    catch
        disp(['Method "' method '" crashed.']);
    end
end
% Link all axes
linkaxes(hAxesSignal(hAxesSignal > 0));
linkaxes(hAxesSpect(hAxesSpect > 0));

% Plot a figure with everything overlayed
try
    figure;
    plot([a_init', cat(1, a{:})']);
    legend_str = {'initial'};
    for i = 1:length(a)
        legend_str{end+1} = sprintf('%s: %1.4fs', list_methods{i}, el{i});
    end
    legend(legend_str);
    zoom on
catch
end
    


function hAxes = PlotSignal(hFig, iPlot, axesTitle, Time, x)
    hAxes = subplot(2, 2, iPlot, 'Parent', hFig);
    plot(hAxes, Time, x);
    title(hAxes, axesTitle);

function hAxes1 = PlotSpectrum(hFig, iPlot, axesTitle, sfreq, x)
    % Compute FFT
    ntime = size(x,2);
    nfft = 2^nextpow2(ntime);
    Y = fft(x',nfft)' / ntime;
    f = sfreq * linspace(0, 1, nfft);
    % Plot |FFT|
    hAxes1 = subplot(2, 2, iPlot, 'Parent', hFig(1));
    plot(hAxes1, f, 2 * log(max(abs(Y'),1e-5))); 
    title(hAxes1, axesTitle);
    
    
    