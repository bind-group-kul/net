function output = H_methods_CM ( data, config )

% =========================================================================
%
% This function is part of the HERMES toolbox:
% http://hermes.ctb.upm.es/
% 
% Copyright (c)2010-2015 Universidad Politecnica de Madrid, Spain
% HERMES is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% HERMES is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
% GNU General Public License for more details. You should have received 
% a copy of the GNU General Public License % along with HERMES. If not, 
% see <http://www.gnu.org/licenses/>.
% 
%
% ** Please cite: ---------------------------------------------------------
% Niso G, Bruña R, Pereda E, Gutiérrez R, Bajo R., Maestú F, & del-Pozo F. 
% HERMES: towards an integrated toolbox to characterize functional and 
% effective brain connectivity. Neuroinformatics 2013, 11(4), 405-434. 
% DOI: 10.1007/s12021-013-9186-1. 
%
% =========================================================================
% 
% Authors:  Guiomar Niso, 2011
%           Guiomar Niso, Ricardo Bruna, 2012
%


% Checks the completitude of the configuration structure.
if ~isfield ( config, 'measures' ),  config.measures   = {};        end
if ~isfield ( config, 'maxlags' ),   config.maxlags    = 0;         end
% if ~isfield ( config, 'nfft' ),      config.nfft       = 128;       end % modified by JS, 23.02.17
if ~isfield ( config, 'window' ),    config.window     = struct (); end
if ~isfield ( config, 'trials' ),    config.trials     = false;     end
if ~isfield ( config, 'towindow' ),  config.towindow = false;       end   % added by JS, 23.02.17
if ~isfield ( config, 'flag_orth' ),  config.flag_orth  = 0;       end  % added by DM         


if ~isfield ( config.window, 'length' ),    config.window.length    = size ( data, 1 ); end
if ~isfield ( config.window, 'overlap' ),   config.window.overlap   = 0;                end
if ~isfield ( config.window, 'alignment' ), config.window.alignment = 'epoch';          end
if ~isfield ( config.window, 'fs' ),        config.window.fs        = 256;              end
if ~isfield ( config.window, 'baseline' ),  config.window.baseline  = 0;                end

% Windows the data.
if config.towindow                                         % added by JS, 23.02.17
    data = H_window ( data, config.window );
end

% Gets the size of the analysis data.
[ samples, channels, windows, trials ] = size ( data );

% Fetchs option data
COR_on  = H_check ( config.measures, 'COR' );
xCOR_on = H_check ( config.measures, 'xCOR' );
COH_on  = H_check ( config.measures, 'COH' );
iCOH_on = H_check ( config.measures, 'iCOH' );
% PSI_on  = H_check ( config.measures, 'PSI' );         % modified by JS, 23.02.17

% Calculates the window size, the overlapping and the nfft value.
if COH_on || iCOH_on
    
    % If the data has enough trials, the data is not windowed.
    if config.trials
        wlen    = samples;
        overlap = 0;
        nfft    = max ( 256, pow2 ( nextpow2 ( wlen ) ) );
        trials  = 1;
        
    % Otherwise the data is segmented in nine overlapping windows.
    else
        wlen    = 2 * floor ( samples / 9 );
        overlap = floor ( wlen / 2 );
        nfft    = max ( 256, pow2 ( nextpow2 ( wlen ) ) );
        win     = hamming ( wlen );
    end
end

% % Comprobar esto!!                                    % modified by JS, 23.02.17
% freqs = size(config.freqRange,1); 
% if freqs==0; freqs=1; end


% Reserves the needed memory.
if COR_on,  output.COR.rawdata  = zeros ( channels, channels, windows, trials ); end
if xCOR_on, output.xCOR.rawdata = zeros ( channels, channels, 2 * config.maxlags + 1, windows, trials ); end
if COH_on,  output.COH.rawdata  = zeros ( channels, channels, ceil ( ( nfft + 1 ) / 2 ), windows, trials ); end
if iCOH_on, output.iCOH.rawdata = zeros ( channels, channels, ceil ( ( nfft + 1 ) / 2 ), windows, trials ); end
% if PSI_on,  output.PSI.rawdata  = zeros ( channels, channels, freqs, windows ); end       % modified by JS, 23.02.17

% Throttled user cancelation.
tinv = 0.2;
tic;

% Calculates the indexes for each window and trial.
for window = 1: windows
    for trial = 1: trials
        if COR_on,  output.COR.rawdata  ( :, :, window, trial )    = permute ( H_xcorr ( data ( :, :, window, trial ), 0,              'coeff' ),          [ 2 3 4 1 ] ); end
        if xCOR_on, output.xCOR.rawdata ( :, :, :, window, trial ) = permute ( H_xcorr ( data ( :, :, window, trial ), config.maxlags, 'coeff' ),          [ 2 3 1 4 ] ); end
    end
    
    % If the flag is active, each trial is considered a segment.
    if config.trials
        if COH_on                                       % modified by JS, 24.02.17
            output.COH.rawdata  ( :, :, :, window ) = permute ( H_spectra ( data ( :, :, window, : ), 'coherence'  ), [ 2 3 1 4 ] );
            L = 2*size(output.COH.rawdata,3);
            fft_f = config.window.fs*(0:(L/2))/L;
            output.fftFreq = fft_f(1:L/2)';
        end
        if iCOH_on
            output.iCOH.rawdata ( :, :, :, window ) = permute ( H_spectra ( data ( :, :, window, : ), 'icoherence' ), [ 2 3 1 4 ] );
            L = 2*size(output.iCOH.rawdata,3);
            fft_f = config.window.fs*(0:(L/2))/L;
            output.fftFreq = fft_f(1:L/2)';
        end
        

    % Otherwise the data is segmented to calculate the spectra.
    else
        for trial = 1: trials
            if COH_on
                output.COH.rawdata  ( :, :, :, window, trial ) = permute ( H_spectra ( data ( :, :, window, trial ), 'coherence',  win, overlap, nfft ), [ 2 3 1 4 ] );
                L = 2*size(output.COH.rawdata,3);
                fft_f = config.window.fs*(0:(L/2))/L;
                output.fftFreq = fft_f(1:L/2)';

            end
            if iCOH_on
                output.iCOH.rawdata ( :, :, :, window, trial ) = permute ( H_spectra ( data ( :, :, window, trial ), 'icoherence', win, overlap, nfft ), [ 2 3 1 4 ] );
                L = 2*size(output.iCOH.rawdata,3);
                fft_f = config.window.fs*(0:(L/2))/L;
                output.fftFreq = fft_f(1:L/2)';
            end
        end
    end
    
%     % No permute                                      % modified by JS, 23.02.17
%     if PSI_on, output.PSI.rawdata ( :, :, :, window) = permute ( H_psi ( data ( :, :, window, : ), config.freqRange ), [ 1 2 3 4 ] ); end
    
    % Checks for user cancelation.
    if toc > tinv
        if ( H_stop ), return, end
        tic
    end
    
end

% In the Imaginary part of Coherence, replaces NaN for 0.
if iCOH_on, output.iCOH.rawdata ( isnan ( output.iCOH.rawdata ) ) = 0; end

% % Averages across trials -> keep trial information    % modified by JS, 23.02.17
if COR_on,  output.COR.data  = output.COR.rawdata; end
if xCOR_on, output.xCOR.data = output.xCOR.rawdata; end
if COH_on,  output.COH.data  = output.COH.rawdata; end
if iCOH_on, output.iCOH.data = output.iCOH.rawdata; end
% if PSI_on,  output.PSI.data  = mean ( output.PSI.rawdata,  5 ); end      

% Transforms the coherence measures to single precision.
if COH_on,  output.COH.data  = single ( output.COH.data  ); end
if iCOH_on, output.iCOH.data = single ( output.iCOH.data ); end

% Removes the trial information.
if COR_on,  output.COR  = rmfield ( output.COR,  'rawdata' ); end
if xCOR_on, output.xCOR = rmfield ( output.xCOR, 'rawdata' ); end
if COH_on,  output.COH  = rmfield ( output.COH,  'rawdata' ); end
if iCOH_on, output.iCOH = rmfield ( output.iCOH, 'rawdata' ); end
% if PSI_on,  output.PSI  = rmfield ( output.PSI,  'rawdata' ); end        % modified by JS, 23.02.17
