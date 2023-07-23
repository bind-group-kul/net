function output = H_methods_PS ( data, config )
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
% Niso G, Bruna R, Pereda E, Gutiérrez R, Bajo R., Maestú F, & del-Pozo F. 
% HERMES: towards an integrated toolbox to characterize functional and 
% effective brain connectivity. Neuroinformatics 2013, 11(4), 405-434. 
% DOI: 10.1007/s12021-013-9186-1. 
%
% =========================================================================
%
% Authors:  Ricardo Gutierrez, 2009
%           Guiomar Niso, 2011
%           Guiomar Niso, Ricardo Bruna, 2012
%


% % Checks the completitude of the configuration structure.
if ~isfield ( config, 'measures' ),   config.measures   = {};        end
if ~isfield ( config, 'bandcenter' ), config.bandcenter = [ 6 20 ];  end
if ~isfield ( config, 'bandwidth' ),  config.bandwidth  = 4;         end
if ~isfield ( config, 'window' ),     config.window     = struct (); end
if ~isfield ( config, 'towindow' ),  config.towindow = false;       end   % added by JS, 28.02.17
if ~isfield ( config, 'flag_orth' ),  config.flag_orth  = 0;       end  % added by DM         


if ~isfield ( config.window, 'length' ),    config.window.length    = size ( data, 1 ); end
if ~isfield ( config.window, 'overlap' ),   config.window.overlap   = 0;                end
if ~isfield ( config.window, 'alignment' ), config.window.alignment = 'epoch';          end
if ~isfield ( config.window, 'fs' ),        config.window.fs        = 256;              end
if ~isfield ( config.window, 'baseline' ),  config.window.baseline  = 0;                end

% Fetchs option data
PLV_on  = H_check ( config.measures, 'PLV'  );
PLI_on  = H_check ( config.measures, 'PLI'  );
wPLI_on = H_check ( config.measures, 'wPLI' );
DPI_on  = H_check ( config.measures, 'DPI' );
RHO_on  = H_check ( config.measures, 'RHO' );

% Gets the size of the analysis data.                                     % modified by JS, 28.02.17
if config.towindow
    sizes = H_window ( data, config.window, 'size' );
    sizes = zeros(sizes);
else
    sizes = data;
end
[ samples, channels, windows, trials ] = size ( sizes );
bands = numel ( config.bandcenter );

% Reserves the needed memory
if PLV_on,  output.PLV.rawdata  = ones ( channels, channels, bands, windows );         end
if PLI_on,  output.PLI.rawdata  = ones ( channels, channels, bands, windows );         end
if wPLI_on, output.wPLI.rawdata = ones ( channels, channels, bands, windows, trials ); end
if DPI_on,  output.DPI.rawdata  = ones ( channels, channels, bands, windows );         end
if RHO_on,  output.RHO.rawdata  = ones ( channels, channels, bands, windows );         end

% Throttled user cancelation check vars
tinv = 0.2; % in seconds
tic;

% Goes throough all bands
for band = 1: length ( config.bandcenter )
    
    % Performs a narrow band filtering
    passband = ( config.bandcenter ( band ) + [ -config.bandwidth config.bandwidth ] / 2 ) / ( config.window.fs / 2 );
    fir = fir1 ( floor ( size ( data, 1 ) / 3 ) - 1, passband );
    
%     filtered = H_filtfilt ( fir, 1, data );
    hilbertedata = H_filtfilt ( fir, 1, data, true );
    filtered = real ( hilbertedata );
    
    
    % Calculates the wPLI, if required (all sensors at once)
    if wPLI_on
        
        % Windows the filtered data.
        windowedata = H_window ( filtered, config.window );
        
        % Calculates the index for each window
        for window = 1: windows
            Pxy = H_spectrum ( windowedata ( :, :, window, : ), 'cross', 0 );
            iPxy = imag ( Pxy );
            output.wPLI.rawdata ( :, :, band, window, : ) = abs ( mean ( iPxy ) ) ./ mean ( abs ( iPxy ) );
        end
    end
    
    if PLV_on || PLI_on || DPI_on || RHO_on
   
        % Calculates Hilbert transform
%         hilbertedata = reshape ( hilbert ( filtered ( :, : ) ), [], channels, trials );

        % Concatenates the trials for each window
        windowedata = H_window ( hilbertedata, config.window );
        windowedata = reshape ( permute ( windowedata, [ 1 4 2 3 ] ), [], channels, windows );

        % Gets the phase angles of the signals
        angles = angle ( windowedata );
    
        % Calculates the indexes for each pair of sensors
        for ch1 = 1: channels - 1
            for ch2 = ch1 + 1: channels
                
                % Gets the difference of phases
                d_angle = angles ( :, ch1, :, : ) - angles ( :, ch2, :, : );
                
                % Calculates the indexes for each window
                for window = 1: windows
                    
                    if RHO_on
                        % Number of bins according to Otnes & Enochson
                        nbins = round ( exp ( 0.626 + 0.4 * log ( samples ) ) );
                        
                        % Sets the diference of angles between 0 and 2pi.
                        d_angleRHO = d_angle ( :, :, window ) + ( d_angle ( :, :, window ) < 0 ) * ( 2 * pi );
                        
                        % Calculates Rho as 1-SE of the histogram
                        histogram = hist ( d_angleRHO, nbins );
                        histogram = histogram / samples / trials + 1e-30 * ( histogram == 0 );
                        
                        output.RHO.rawdata ( ch1, ch2, band, window ) = 1 - ( - sum ( histogram .* log ( histogram ) ) / log ( nbins ) );
                        output.RHO.rawdata ( ch2, ch1, band, window ) = output.RHO.rawdata ( ch1, ch2, band, window );
                    end
                    
                    if PLV_on
                        output.PLV.rawdata ( ch1, ch2, band, window ) = abs ( mean ( exp ( 1i * d_angle ( :, :, window ) ) ) );
                        output.PLV.rawdata ( ch2, ch1, band, window ) = output.PLV.rawdata ( ch1, ch2, band, window );
                    end
                    
                    if PLI_on
                        output.PLI.rawdata ( ch1, ch2, band, window ) = abs ( mean ( sign ( ( abs ( d_angle ( :, :, window ) ) - pi ) .* d_angle ( :, :, window ) ) ) );
                        output.PLI.rawdata ( ch2, ch1, band, window ) = output.PLI.rawdata ( ch1, ch2, band, window );
                    end
                    
                    if DPI_on
                        output.DPI.rawdata ( ch1, ch2, band, window ) = H_DPI ( angles ( :, ch1, :, : ), angles ( :, ch2, :, : ), config.method );
                        output.DPI.rawdata ( ch2, ch1, band, window ) = H_DPI ( angles ( :, ch2, :, : ), angles ( :, ch1, :, : ), config.method );
                    end
                end
            
                % Checks for user cancelation (Throttled)
                if toc > tinv,
                    if ( H_stop ), return, end
                    tic
                end
            end
        end
    end
end

% Averages across trials -> keep trial information                        % modified by JS, 28.02.17
if PLV_on,  output.PLV.data  = output.PLV.rawdata;  end
if PLI_on,  output.PLI.data  = output.PLI.rawdata;  end
if wPLI_on, output.wPLI.data = output.wPLI.rawdata; end
if RHO_on,  output.RHO.data  = output.RHO.rawdata;  end
if DPI_on,  output.DPI.data  = output.DPI.rawdata;  end

% Removes the trial information
if PLV_on,  output.PLV  = rmfield ( output.PLV,  'rawdata' ); end
if PLI_on,  output.PLI  = rmfield ( output.PLI,  'rawdata' ); end
if wPLI_on, output.wPLI = rmfield ( output.wPLI, 'rawdata' ); end
if RHO_on,  output.RHO  = rmfield ( output.RHO,  'rawdata' ); end
if DPI_on,  output.DPI  = rmfield ( output.DPI,  'rawdata' ); end
