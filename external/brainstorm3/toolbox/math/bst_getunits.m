function [valScaled, valFactor, valUnits] = bst_getunits( val, DataType )
% BST_GETUNITS: Get in which units is expressed a value.
%
% USAGE:  [valScaled, valFactor, valUnits] = bst_getunits(val, DataType);
%
% INPUT:
%    - val       : Value to analyze
%    - DataType  : Type of data in the value "val". Possible strings: 
%                  'EEG', 'MEG', 'MEG MAG', 'MEG GRAD', 'ECOG', 'SEEG', '$MEG', '$EEG', '$ECOG', '$SEEG', 'results', 'sources', 'source', 'stat', ...
% OUTPUT:
%    - valScaled : value in the detected units (val * valFactor)
%    - valFactor : factor to convert val -> valScaled
%    - valUnits  : string that represents the units ('\muV', 'fT', 'pA.m', etc.)

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
% Authors: Francois Tadel, 2008-2010

% Consider input data in absolute value
val = abs(val);
% If no modality (ex: surface mask, mri values...)
if isempty(DataType)
    DataType = 'none';
end
% Units depends on the data modality
switch lower(DataType)
    case {'meg', '$meg', 'meg grad', 'meg mag', '$meg grad', '$meg mag'}
        % MEG data in fT
        if (val < 1e-8)
            valFactor = 1e15;
            valUnits  = 'fT';
        % MEG data without units (zscore, stat...)
        else
            valFactor = 1;
            valUnits  = 'No units';
        end
        
    case {'eeg', '$eeg', 'ecog', '$ecog', 'seeg', '$seeg'}
        % EEG data in Volts, displayed in microVolts
        if (val < 0.01)
            valFactor = 1e6;
            valUnits = '\muV';
        % EEG data in Volts, displayed in microVolts
        elseif (val < 0.1)
            valFactor = 1;
            valUnits = 'V';
        % EEG data without units (zscore, stat...)
        else
            valFactor = 1;
            valUnits = 'No units';
        end
        
    case {'results', 'sources', 'source'}
        % Results in Amper.meter (display in picoAmper.meter)
        if (val < 1e-4)
            valFactor = 1e12;
            valUnits  = 'pA.m';
        % Results without units (zscore, stat...)
        else
            valFactor = 1;
            valUnits  = 'No units';
        end
        
    case 'sloreta'
        if (val < 1e-4)
            exponent = round(log(val)/log(10)) - 1;
            valFactor = 10 ^ -exponent;
            valUnits  = sprintf('10^{%d}', exponent);
        else
            valFactor = 1;
            valUnits  = 'No units';
        end
        
    case 'stat'
        valFactor = 1;
        valUnits  = 'No units';
        
    case 'connect'
        valFactor = 1;
        valUnits  = 'score';
        
    case 'timefreq'
        %exponent = round(log(val)/log(10) / 3) * 3;
        exponent = round(log(val)/log(10)) - 1;
        valFactor = 10 ^ -exponent;
        valUnits  = sprintf('x10^{%d}', exponent);

    otherwise
        %exponent = round(log(val)/log(10) / 3) * 3;
        exponent = round(log(val)/log(10)) - 1;
        valFactor = 10 ^ -exponent;
        valUnits  = sprintf('10^{%d}', exponent);
end

% Scale input value
valScaled = val .* valFactor;



