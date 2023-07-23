function net_eegprepro_initialize(input_filename,output_filename)



S         = [];  % changed by DM 26.11.13
S.D       = input_filename; 
S.outfile = output_filename; % revised by QL, 16.01.2016, for SPM 12;  S.newname = raw_filename; for SPM 8
S.newname = output_filename;
D         = spm_eeg_copy(S); % The function that creates a copy of the mat and dat file and creates a MEEG SPM object-