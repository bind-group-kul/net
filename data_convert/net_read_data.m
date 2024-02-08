function xls_data=net_read_data(pathx,subjects) % add subj_idx GT 03.22

xls_data = xls2struct(pathx,1); % modified (pathx,'data') GT 03.22

if ~exist('subjects','var')       % GT 06.22 to work with net_main_script
    subjects = 1:size(xls_data,1);  
end

%% check whether all the raw files are there for all the subjects

for subject_i = subjects % modified subject_i = 1:nsubjs    % GT 03.22

    if not(isnan(xls_data(subject_i).eeg_filename)) % added GT 05.22
        if not(exist( xls_data(subject_i).eeg_filename ,'file'))

        disp(['subject' num2str(subject_i) ' : no EEG file!'])
        end

    end

    if not(isnan(xls_data(subject_i).markerpos_filename)) % added GT 05.22
    if not(exist( xls_data(subject_i).markerpos_filename,'file'))
        
        disp(['subject' num2str(subject_i) ' : no electrode file.'])
    end
        
    end

    if not(isnan(xls_data(subject_i).anat_filename)) % added GT 05.22
    if not(exist( xls_data(subject_i).anat_filename,'file'))

        disp(['subject' num2str(subject_i) ' : no MR anatomy file.'])
    end
    else % MRI not specified, JS 02.2024
        sps = strsplit(xls_data(subject_i).markerpos_filename,'_');
        if ~strcmpi(sps{end},'corr.sfp') % no template electrode position
            disp(['subject' num2str(subject_i) ' : individual electrode file but no individual MR anatomy file.'])
        else % template electrode position and MRI
            xls_data(subject_i).anat_filename = [net('path') filesep 'template' filesep 'tissues_MNI' filesep 'mni_template.nii'];
            writetable(struct2table(xls_data),pathx,'WriteVariableNames',true,'Sheet',1);
        end
    end
    
    %check field of external events file, added by MZ, 11.Dec.2017
    if isfield(xls_data(subject_i),'experiment_filename')
        if isnan(xls_data(subject_i).experiment_filename)
            disp(['subject' num2str(subject_i) ' : no external events file, skip loading external events.'])
            xls_data(subject_i).experiment_filename = '';
        elseif not(exist( xls_data(subject_i).experiment_filename, 'file' ))
            disp(['subject' num2str(subject_i) ' : external events file not found! Not used for processing.'])
            xls_data(subject_i).experiment_filename = '';
        end
    end

end




