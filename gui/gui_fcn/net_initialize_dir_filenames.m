function net_initialize_dir_filenames(handles)

pathy = handles.outdir;
subjects = handles.subjects;
folderpaths = [];

for subject_i = subjects
    dd=[pathy filesep 'dataset' num2str(subject_i)];
    ddx=[dd filesep 'mr_data'];
    if ~isdir(ddx)
        mkdir(ddx);  % Create the output folder if it doesn't exist..
    end
    
    ddy=[dd filesep 'eeg_signal'];
    if ~isdir(ddy)
        mkdir(ddy);  % Create the output folder if it doesn't exist..
    end
    
    ddz=[dd filesep 'eeg_source'];
    if ~isdir(ddz)
        mkdir(ddz);  % Create the output folder if it doesn't exist..
    end
    
    folderpaths(subject_i).mr_data = ddx;
    folderpaths(subject_i).eeg_signal = ddy;
    folderpaths(subject_i).eeg_source = ddz;
end
    setappdata(handles.gui,'folderpaths',folderpaths)
end