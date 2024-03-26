function net_erp_analysis(source_filename,options_erp)

if( strcmp(options_erp.mapping_enable,'on') || strcmp(options_erp.roi_enable,'on') || strcmp(options_erp.sensor_enable,'on')) %
    
    fprintf('\t** ERP analyses started... **\n')
    %% 1. load source, common code calculation
    f = waitbar(0,'ERP analysis...');
    tmp = strsplit(source_filename,filesep); subject_info = tmp{end-2};
    f.Name = ['Dataset ' subject_info(8:end) ' - ERP ANALYSIS']; clear tmp

    n_range=3;
    NET_folder = net('path');
    ddx=fileparts(fileparts(source_filename));
    [~, dataset_info] = fileparts(ddx);
    deformation_to_mni=[ddx filesep 'mr_data' filesep 'iy_anatomy_prepro.nii'];
    deformation_to_subj=[ddx filesep 'mr_data' filesep 'y_anatomy_prepro.nii'];
    fprintf(['\nNET ERP: ', dataset_info, '\n']);
    
    waitbar(.05,f,'...read triggers (1/4)');
    if(strcmp(options_erp.mapping_enable,'on') || strcmp(options_erp.roi_enable,'on')) %% load things only for source level
        signal_file = [ddx, filesep, 'eeg_signal', filesep, 'processed_eeg.mat'];
        signal_d = spm_eeg_load(signal_file);
        load(source_filename,'source');
        [dd,ff,ext]=fileparts(source_filename);
        xyz = source.pos(source.inside==1,:)';
        Fs=1/(source.time(2)-source.time(1));
        filtered_data=net_filterdata(source.sensor_data,Fs,options_erp.highpass,options_erp.lowpass);
        events_all = source.events;
        elec_labels = source.label;
        elecpos=source.elecpos;
    else % load for sensor level
        signal_file = [ddx, filesep, 'eeg_signal', filesep, 'processed_eeg.mat'];
        signal_d = spm_eeg_load(signal_file);
        Fs = signal_d.fsample;
        EEG_chan_list = selectchannels(signal_d, 'EEG');
        filtered_data = signal_d(EEG_chan_list, :);
        filtered_data = net_filterdata(filtered_data, Fs, options_erp.highpass, options_erp.lowpass); 
        events_all = signal_d.triggers;
        elec_locs_file = [ddx, filesep, 'mr_data', filesep, 'electrode_positions.sfp'];
        elecpos=readlocs(elec_locs_file);
        elec_labels = signal_d.chanlabels(EEG_chan_list);
    end
    
    channel_num = size(filtered_data,1);
    voltage_units = signal_d.units(1:channel_num);
    
    Fs_ref=1000;
    if not(Fs==Fs_ref)
        filtered_data = (resample(double(filtered_data)',Fs_ref,Fs))';
    end
    time_unit = 'ms';
    %% 2. parse events, common code for mapping and roi
    %2.1 load riggers template
    triggers_template_file = [NET_folder filesep 'template' filesep 'triggers' filesep options_erp.triggers '.mat'];
    load(triggers_template_file, 'triggers');
    conditions_num = length(triggers);
    events_num = length(events_all);
    
    %2.2 initialize events cell
    events = cell(1, conditions_num);
    
    %2.3 classify events, and save to events cell
    for iter_events = 1:1:events_num
        for iter_conditions = 1:1:conditions_num
            sub_conditions_num = length(triggers(iter_conditions).trig_labels);
            for iter_sub_conditions = 1:1:sub_conditions_num
                if(strcmp(events_all(iter_events).value, triggers(iter_conditions).trig_labels{iter_sub_conditions}))
                    events{iter_conditions} = [events{iter_conditions}, events_all(iter_events)];
                    continue;
                end
            end
        end
    end
    
    %2.4 check if all the conditions in the triggers template can be found
    empty_condition_index=[];
    for iter_conditions = 1:1:conditions_num
        if (isempty(events{iter_conditions}))
            empty_condition_index = [empty_condition_index iter_conditions];
            disp(['NET ERP: condition ', triggers(iter_conditions).condition_name, ' cannot be found across all the events, please check your triggers template or your experiment!']);
        end
    end    
    for iter_conditions = 1:1:conditions_num
        if isempty(events{iter_conditions})
            emp(iter_conditions) = 1;
        end
    end
    if exist('emp','var')
        if sum(emp) == conditions_num
        disp('No condition can be found in any event. ERP analysis not performed.')
        return
        end
    end

    %delete empty conditions, and update conditions infomation
    events(empty_condition_index) = [];
    triggers(empty_condition_index) = [];
    conditions_num = length(events);
    
    %% 3. ERP in sensor space
    if strcmp(options_erp.sensor_enable,'on')
    waitbar(.25,f,'...ERP - sensor space (2/4)');

        disp(['NET ERP: ', dataset_info, ': processing ERP in sensor space...']);
        dd2=[ddx filesep 'eeg_signal' filesep 'erp_results'];
        if ~isdir(dd2)
            mkdir(dd2);  % Create the output folder if it doesn't exist..
        end
        
        bar_len  = 0;
        for iter_conditions = 1:1:conditions_num
            tic;
            options_erp.pretrig = triggers(iter_conditions).pretrig;
            options_erp.posttrig = triggers(iter_conditions).posttrig;
            options_erp.baseline = triggers(iter_conditions).baseline;

            
            epoched_data = net_epoch(filtered_data,Fs_ref,events{iter_conditions},options_erp); 
            erp_data = net_robustaverage(epoched_data,n_range);
            
            pretrig   = round(Fs_ref*options_erp.pretrig/1000);
            posttrig  = round(Fs_ref*options_erp.posttrig/1000);
            
            cc=corr(erp_data(:,-pretrig+1:posttrig-pretrig)',erp_data(:,-pretrig+1:posttrig-pretrig)'); %why?
            vect=sign(max(cc,[],2)+min(cc,[],2));
            erp_tc=erp_data.*vect; %should I?
                    
            erp_sensor(iter_conditions).condition_name = triggers(iter_conditions).condition_name;
            erp_sensor(iter_conditions).time_axis = [pretrig+1:posttrig]; % time unit = ms
            erp_sensor(iter_conditions).erp_tc = erp_tc;
            erp_sensor(iter_conditions).label = elec_labels;
            erp_sensor(iter_conditions).trials = epoched_data;
            t = toc;
            bar_len = net_progress_bar_t(['NET ERP: ', subject_info, ': calculate sensors ERP', ], iter_conditions, conditions_num, t, bar_len);

        end       
        save([dd2 filesep 'erp_timecourses_sensor.mat'],'erp_sensor','elecpos', 'triggers','events', 'voltage_units', 'time_unit', 'events_all');
    end
    
    
    %% ERP in source space
    if strcmp(options_erp.mapping_enable,'on')
    waitbar(.5,f,'...ERP - source maps (3/4)');
        
        disp(['NET ERP: ', dataset_info, ': processing ERP in source space...']);
        dd2=[dd filesep 'erp_results']; 
        if ~isdir(dd2)
            mkdir(dd2);  % Create the output folder if it doesn't exist..
        end
        % get map of each type of triggers
        for iter_conditions = 1:1:conditions_num
            %prepare parameters
            options_erp.pretrig = triggers(iter_conditions).pretrig;
            options_erp.posttrig = triggers(iter_conditions).posttrig;
            options_erp.baseline = triggers(iter_conditions).baseline;
            
            
            epoched_data = net_epoch(filtered_data,Fs_ref,events{iter_conditions},options_erp);
            erp_data = net_robustaverage(epoched_data,n_range);
            %figure; plot([options_erp.pretrig+1:options_erp.posttrig],erp_data'); xlabel('time (ms)'); ylabel('a.u.');
            
            vox_indices=find(source.inside==1);
            nvoxels=length(vox_indices);
            xdim    = source.dim(1);
            ydim    = source.dim(2);
            zdim    = source.dim(3);
            
            %mat=net_pos2transform(source.pos, source.dim);
            %res=abs(det(mat(1:3,1:3)))^(1/3);
            
            pretrig   = round(Fs_ref*options_erp.pretrig/1000); % time in ms
            posttrig  = round(Fs_ref*options_erp.posttrig/1000);
            
            erp_source_tcs=source.pca_projection*source.imagingkernel*erp_data;
            time_axis = [pretrig+1:posttrig]; % time in ms
            
            cc=corr(erp_source_tcs',erp_data');
            vect=sign(max(cc,[],2)+min(cc,[],2));
            erp_source_tcs=erp_source_tcs.*(vect*ones(1,size(erp_source_tcs,2)));
            
            % ==================================================
            % 3. save the ERP maps for each time lag
            
            Vt.dim      = source.dim;
            Vt.pinfo    = [0.000001 ; 0 ; 0];
            Vt.dt       = [16 0];
            Vt.mat      = net_pos2transform(source.pos, source.dim);
            Vt.n        = [1 1];
            
            Ts = (1/Fs)*1000;
            lag_list = 0:Ts:posttrig;
            time_num = length(lag_list)-1; % JS 09.2023, last lag goes beyond the trial
            
            for iter_t = 1:time_num
                lag = lag_list(iter_t);
                time_locs = find(time_axis == lag):(find(time_axis == lag)+Ts-1);
                
                Vt.fname = [dd2 filesep 'erp_' triggers(iter_conditions).condition_name '_' num2str(lag), 'ms_map.nii'];
                if exist(Vt.fname,'file')
                    delete(Vt.fname);
                end
                erp_source_mat = erp_source_tcs(:,time_locs);
                if(size(erp_source_mat,2) >1)
                    erp_source_mat = mean(erp_source_mat,2);
                end
    
                erp_image   = zeros(xdim*ydim*zdim,1);
                erp_image(vox_indices) = erp_source_mat;
                erp_image   = reshape(erp_image, xdim, ydim, zdim);
                spm_write_vol(Vt, erp_image);
                % progress bar
                net_progress_bar(['        Writing ERP maps for each time lag (condition=', num2str(iter_conditions), '/', num2str(conditions_num), ')'], iter_t, time_num);
            end
        end
        
        net_warp([dd2 filesep 'erp*map.nii'],deformation_to_mni);
        delete([dd2, filesep, '*.nii']);
    end
    
    %% ERP in ROIs
    if strcmp(options_erp.roi_enable,'on')
    waitbar(.75,f,'...ERP - regions of interest (4/4)');

        disp(['NET ERP: ', dataset_info, ': processing ERP in ROIs']);
        dd2=[dd filesep 'erp_results']; 
        if ~isdir(dd2)
            mkdir(dd2);  % Create the output folder if it doesn't exist..
        end
        seed_file=[NET_folder filesep 'template' filesep 'seeds' filesep options_erp.seed_file '.mat'];
        load(seed_file,'seed_info');
        
        radius=6;
        
        nrois=length(seed_info);
        bar_len  = 0;
        for i=1:nrois
            tic;
            seed_info(i).coord_subj=net_project_coord(deformation_to_subj,seed_info(i).coord_mni);
            dist = pdist2(xyz',seed_info(i).coord_subj);
            voxel_list=find(dist<radius);
            if isempty(voxel_list)
                [~,voxel_list]=min(dist);
                disp(['please check seed ' num2str(i)]);
            end
            seed_info(i).seedindx=voxel_list;
            t = toc;
            bar_len = net_progress_bar_t(['NET ERP: ', subject_info, ': find individual ROI coordinates', ], i, nrois, t, bar_len);
        end
        
        
        % get map of each type of triggers
        for iter_conditions = 1:1:conditions_num
            %prepare parameters
            options_erp.pretrig = triggers(iter_conditions).pretrig;
            options_erp.posttrig = triggers(iter_conditions).posttrig;
            options_erp.baseline = triggers(iter_conditions).baseline;
            
            epoched_data = net_epoch(filtered_data,Fs_ref,events{iter_conditions},options_erp);
            
            erp_data = net_robustaverage(epoched_data,n_range);
            
            %figure; plot([options_erp.pretrig+1:options_erp.posttrig],erp_data'); xlabel('time (ms)'); ylabel('a.u.');
            %mat=net_pos2transform(source.pos, source.dim);
            %res=abs(det(mat(1:3,1:3)))^(1/3);
            
            pretrig   = round(Fs_ref*options_erp.pretrig/1000);
            posttrig  = round(Fs_ref*options_erp.posttrig/1000);
            
            bar_len = 0;
            for i=1:nrois
                tic;
                mat=source.pca_projection(seed_info(i).seedindx,:)*source.imagingkernel*erp_data;
                [~,score]=pca(mat');
                cc=corr(score(-pretrig+1:posttrig-pretrig,1),erp_data(:,-pretrig+1:posttrig-pretrig)');
                erp_tc=score(:,1)'*sign(max(cc)+min(cc));
                
                erp_roi(iter_conditions).condition_name = triggers(iter_conditions).condition_name;
                erp_roi(iter_conditions).time_axis = [pretrig+1:posttrig];
                erp_roi(iter_conditions).erp_tc(i,:) = erp_tc;
                erp_roi(iter_conditions).label{i} = seed_info(i).label;
                t = toc;
                bar_len = net_progress_bar_t(['Condition ' num2str(iter_conditions) ': ', subject_info, ': calculate ROI ERP', ], i, nrois, t, bar_len);
            end
            
        end
        
        save([dd2 filesep 'erp_timecourses_roi.mat'],'erp_roi','triggers', 'seed_info', 'events', 'voltage_units', 'time_unit');
    end
    close(f)
    fprintf('\t** ERP analyses done! **\n')
else
    fprintf('No ERP analyses to run.\n')
end
