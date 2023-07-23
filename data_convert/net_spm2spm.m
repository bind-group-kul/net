%% Purpose
% 1. Main function that converts Brain products files to SPM format.
% 2. Create sensor information compatible to field trip structure.
% 3. Add EOG, EMG signals.
% 4. Do the notch filtering at 50 Hz and detrending.

%%
function D = net_spm2spm(X)

% Main function for converting different M/EEG formats to SPM8 format.
% FORMAT D = spm_eeg_convert(S)
% S                - can be string (file name) or struct (see below)
%
% If S is a struct it can have the optional following fields:
% X.raweeg_filename        - file name
% X.output_file     -


%Check if both raw data and position files are specified

if ~isfield(X, 'raweeg_filename'),    error('EEG filename must be specified!');
else
    raweeg_filename = X.raweeg_filename;
end

output_file=X.output_filename;



%Supply details in a struct format for the SPM function to start the file
%conversion

S.D = raweeg_filename;       
S.outfile = output_file; %Save the converted file with a prefix spm_

disp('Data Conversion: Reading data...');
D = spm_eeg_copy(S);


D.save;

%%
% Revision history:
%{
2014-04-13
    v0.1 Updated the file based on initial versions from Dante and
    Quanying(Revision author : Sri).
   

%}

