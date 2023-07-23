function net_filtering(processedeeg_filename,filtering_options)
% 
if strcmp(filtering_options.enable, 'on')
    
    D=spm_eeg_load(processedeeg_filename);
    
    nsamples=6600;
    
    try
        hp=filtering_options.highpass;
        if ischar(hp) % added JS 06.2022
            hp = str2double(hp);
        end
    catch %#ok<CTCH>
        hp=[];
    end
    
    try
        lp=filtering_options.lowpass;
        if ischar(lp) % added JS 06.2022
            lp = str2double(lp);
        end
    catch %#ok<CTCH>
        lp=[];
    end
    
    
    EEG = pop_fileio([path(D) filesep fname(D)]);
    [newEEG]=net_unripple_filter(EEG,hp,lp,nsamples);
    D(:,:,1) = newEEG.data;
    
    
    D.save;
    
end