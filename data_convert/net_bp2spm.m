%% Purpose
% 1. Main function that converts Brain products files to SPM format.
% 2. Create sensor information compatible to field trip structure.
% 3. Add EOG, EMG signals.
% 4. Do the notch filtering at 50 Hz and detrending.

%%
function D = net_bp2spm(X)

% Main function for converting different M/EEG formats to SPM8 format.
% FORMAT D = spm_eeg_convert(S)
% S                - can be string (file name) or struct (see below)
%
% If S is a struct it can have the optional following fields:
% X.raweeg_filename        - file name
% X.output_filename     -


%Check if both raw data and position files are specified

if ~isfield(X, 'raweeg_filename'),    error('EEG filename must be specified!');
else
    raweeg_filename = X.raweeg_filename;
end

ff = dir(raweeg_filename);
%Check if both .eeg and .vhdr files are available in the same folder
% added by JS 03.2022
if strcmpi(X.raweeg_filename(end-3:end),'.eeg')
    headfile = [ff.folder filesep ff.name(1:end-4) '.vhdr'];
    if ~exist(headfile,'file')
        error([ ff.name(1:end-4) '.vhdr file not available. The .eeg and the .vhdr files must be saved in the same folder.' ])
    end
elseif strcmpi(X.raweeg_filename(end-4:end),'.vhdr')
    datafile = [ff.folder filesep ff.name(1:end-5) '.eeg'];
    if ~exist(datafile,'file')
        error([ ff.name(1:end-5) '.eeg file not available. The .eeg and the .vhdr files must be saved in the same folder.' ])
    end
end
% Use .mat file instead of .dat, if available (otherwise spm_eeg_convert throws an error)   Gaia 21.09.22
if strcmpi(X.raweeg_filename(end-3:end),'.dat')
    raweeg_filename_mat = [raweeg_filename(1:end-4) '.mat'];
    if exist(raweeg_filename_mat,'file')
        raweeg_filename = raweeg_filename_mat;
    end
end

output_file=X.output_filename;

% correct event file is needed

A=dir([raweeg_filename filesep 'Events*.xml']);
if size(A,1)>0   % added by QL, 07.10.2014 to check whether there is events*.xml file.
    ev_file=A.name;
    
    if not(isempty(strfind(ev_file,'255')))
        movefile([raweeg_filename filesep ev_file],[raweeg_filename filesep 'Events_DIN_1.xml']);
    end
end


%Supply details in a struct format for the SPM function to start the file
%conversion

S = [];
S.dataset = raweeg_filename; %file name
S.channels = 'all'; %Which channels to convert?
S.checkboundary = 1; %To check if there are breaks in the file
S.usetrials = 1; %we don't use a trail definition file
S.datatype = 'float32-le'; %input data is of 32 bit float format
S.eventpadding = 0; %This is for trial borders, we don't use them
S.saveorigheader = 0; % Don't keep the original header
S.inputformat = []; % we don't use it
S.outfile = output_file; %Save the converted file with a prefix spm_
S.continuous = true; %The data is not epoched it is continuous
%Send this information to SPM function to start conversion
disp('Data Conversion: Reading data...');

%Check if the original file (.eeg or .vhdr) has been renamed
% added by JS 03.2022
% try
D = spm_eeg_convert(S);
% catch ME
%     filenameparts = strsplit(ME.message,' '); spaces = {' '};
%     msg = ['The original EEG file has been renamed and cannot be located.', ...
%                 ' The current filename is ', ff.name,' whereas the original one was ', filenameparts{end}, '.', ...
%                 ' Please rename the file.'];
%     error(msg)
% end


D.save;

%%
% Revision history:
%{
2014-04-13
    v0.1 Updated the file based on initial versions from Dante and
    Quanying(Revision author : Sri).
   

%}

