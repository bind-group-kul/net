function net_resampling(processedeeg_filename,resampling_options)
% 

if strcmpi(resampling_options.enable, 'on')

[dd,ff,ext]=fileparts(processedeeg_filename);

D=spm_eeg_load(processedeeg_filename);

fs=fsample(D);

if not(resampling_options.new_fs==fs)
    
    S =[];
    
    S.D = D;
    S.fsample_new = resampling_options.new_fs;
    S.prefix ='d';
    
    D = spm_eeg_downsample(S);
    
    S         = [];  % changed by DM 26.11.13
    S.D       = D;
    S.outfile = processedeeg_filename; % revised by QL, 16.01.2016, for SPM 12;  S.newname = raw_filename; for SPM 8
    S.newname = processedeeg_filename;
    D         = spm_eeg_copy(S); % The function that creates a copy of the mat and dat file and creates a MEEG SPM object-
    
    delete([dd filesep 'd' ff '.mat']);
    delete([dd filesep 'd' ff '.dat']);
    
end

end