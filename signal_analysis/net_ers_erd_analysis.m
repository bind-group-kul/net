%% last version: 22.05.2018

function net_ers_erd_analysis(source_filename, options_ers_erd)

if(strcmp(options_ers_erd.mapping_enable, 'on') || strcmp(options_ers_erd.roi_enable, 'on') || strcmp(options_ers_erd.sensor_enable, 'on')) 
    
    fprintf('\t** ERS/ERD analyses started... **\n')
    smooth = 'on';
    %% 1. load source, common code for mapping and roi
    NET_folder = net('path');
    ddx=fileparts(fileparts(source_filename));
    [~, dataset_info] = fileparts(ddx);
    fprintf(['\nNET ERD/ERS: ' dataset_info, '\n']);
    deformation_to_mni=[ddx filesep 'mr_data' filesep 'iy_anatomy_prepro.nii'];
    deformation_to_subj=[ddx filesep 'mr_data' filesep 'y_anatomy_prepro.nii'];
    %tpmref_filename=[NET_folder filesep 'template' filesep 'tissues_MNI' filesep 'eTPM6.nii'];
    
    if(strcmp(options_ers_erd.mapping_enable, 'on') || strcmp(options_ers_erd.roi_enable, 'on'))
        load(source_filename, 'source');
        [dd,ff,ext]=fileparts(source_filename);
        Fs=1/(source.time(2)-source.time(1));
        xyz = source.pos(source.inside==1,:)';
        channel_data=1000*source.sensor_data;
        events_all = source.events;
        elecpos=source.elecpos;
        elec_labels = source.label;
    else
        signal_file = [ddx, filesep, 'eeg_signal', filesep, 'processed_eeg.mat'];
        signal_d = spm_eeg_load(signal_file);
        Fs = signal_d.fsample;
        EEG_chan_list = selectchannels(signal_d, 'EEG');
        channel_data = 1000*signal_d(EEG_chan_list, :);
        events_all = signal_d.triggers;
        elec_locs_file = [ddx, filesep, 'mr_data', filesep, 'electrode_positions.sfp'];
        elecpos=readlocs(elec_locs_file);
        elec_labels = signal_d.chanlabels(EEG_chan_list);
    end
    Ntime=size(channel_data,2);    
    
    %%
    hp=options_ers_erd.highpass;
    lp=options_ers_erd.lowpass;
    
        large_window = 1; %2; % window length in sec
        step_window  = 0.1; %0.1; % step length in sec, smaller will make calculation take longer time
        frequencies  = hp:lp; % in Hz, resolution 1 Hz
        
        % window2 = hann( round(Fs*large_window) ); % in points/samples
        window2 = round(Fs*large_window); % in points/samples
        overlap = round( Fs*(large_window-step_window)); % in points/samples (integer)
     
    time_unit = 'ms';
    %% 2. parse events, common code for mapping and roi
    %2.1 load triggers template
    triggers_template_file = [NET_folder filesep 'template' filesep 'triggers' filesep options_ers_erd.triggers '.mat'];
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
    
    %2.4 check if all the conditions in the triggers template can be found,
    empty_condition_index=[];
    for iter_conditions = 1:1:conditions_num
        if (isempty(events{iter_conditions}))
            empty_condition_index = [empty_condition_index iter_conditions];
            fprintf([dataset_info,': NET ERS/ERD: condition ''', triggers(iter_conditions).condition_name, ''' cannot be found across all the events, please check your triggers template or your experiment!\n']);
        end
    end
    %delete empty conditions, and update conditions infomation
    events(empty_condition_index) = [];
    triggers(empty_condition_index) = [];
    conditions_num = length(events);
  
  %% 3. erd/ers sensor topogram
    if(strcmp(options_ers_erd.sensor_enable,'on'))
         
        dd2=[ddx filesep 'eeg_signal' filesep 'ers_erd_results'];
        if ~isdir(dd2)
            mkdir(dd2);
        end
         bar_len = 0;
         nchan=size(channel_data,1);
         for i=1:nchan
             tic;
             [~, F, T, Ptot] = spectrogram(channel_data(i,:), window2, overlap, frequencies, Fs);
             if(strcmp(smooth, 'on'))
                Ptot = medfilt2(Ptot,[5 5]);  % smooth the spectrogram
             end

             % get map of each type of triggers
             for iter_conditions = 1:1:conditions_num
                 %prepare parameters
                 options_ers_erd.pretrig = triggers(iter_conditions).pretrig;
                 options_ers_erd.posttrig = triggers(iter_conditions).posttrig;
                 options_ers_erd.baseline = triggers(iter_conditions).baseline;
                 %options_ers_erd.time_range = triggers(iter_conditions).time_range;
                 
                 [tf_map, times] = net_ers_erd(Ptot,T,events{iter_conditions},options_ers_erd);
                
                %save result to structure
                ers_erd_sensor(iter_conditions).condition_name = triggers(iter_conditions).condition_name;
                ers_erd_sensor(iter_conditions).time_axis = times;
                ers_erd_sensor(iter_conditions).frequency_axis = frequencies;
                ers_erd_sensor(iter_conditions).tf_map(i,:,:) = tf_map;
                ers_erd_sensor(iter_conditions).label{i} = elec_labels{i};
             end
             t = toc;
             bar_len = net_progress_bar_t(['NET ERS/ERD sensor: ', dataset_info], i, nchan, t, bar_len);
         end
         save([dd2 filesep 'ers_erd_sensor.mat'],'ers_erd_sensor','elecpos','triggers','events', 'time_unit'); %MZ, 9.Feb.2018 save triggers instead of options_ers_erd
    end   
    
    %% 4. ers_erd.mapping. This part can be very time consuming!
    if(strcmp(options_ers_erd.mapping_enable,'on'))
        dd2=[dd filesep 'ers_erd_results'];
        if ~isdir(dd2)
            mkdir(dd2);
        end
        
        %3.1 start calculate
        vox_indices=find(source.inside==1);
        nvoxels=length(vox_indices);
        
        xdim    = source.dim(1);
        ydim    = source.dim(2);
        zdim    = source.dim(3);
        
        %mat=net_pos2transform(source.pos, source.dim);
        %res=abs(det(mat(1:3,1:3)))^(1/3);
   
        max_band_num = 0;
        for iter_conditions = 1:conditions_num
            temp_band_num = length(triggers(iter_conditions).frequency);
            if (temp_band_num > max_band_num)
                max_band_num = temp_band_num;
            end
        end
        ers_erd_maps =  zeros(nvoxels, max_band_num,conditions_num);
        %--------------
        bar_len = 0;
        for k=1:nvoxels
            tic;
            brain_signal = source.pca_projection(k,(3*k-2):(3*k))*source.imagingkernel((3*k-2):(3*k),:)*channel_data; %% add by JS, 06.07.2017
            
            [~, F, T, Ptot] = spectrogram(brain_signal, window2, overlap, frequencies, Fs);
            if(strcmp(smooth, 'on'))
                Ptot = medfilt2(Ptot,[5 5]);  % smooth the spectrogram
            end
            %                 sigx=source.imagingkernel(1+3*(k-1),:)*channel_data;
            %                 sigy=source.imagingkernel(2+3*(k-1),:)*channel_data;
            %                 sigz=source.imagingkernel(3*k,:)*channel_data;
            %
            %                 [~, F, T, Px] = spectrogram(sigx, window2, overlap, frequencies, Fs);
            %                 [~, F, T, Py] = spectrogram(sigy, window2, overlap, frequencies, Fs);
            %                 [~, F, T, Pz] = spectrogram(sigz, window2, overlap, frequencies, Fs);
            %
            %                 % Sum the three PSDs for each 'seed' voxel
            %                 Ptot = Px+Py+Pz;
            
            % get map of each type of triggers
            for iter_conditions = 1:1:conditions_num
                %prepare parameters
                options_ers_erd.pretrig = triggers(iter_conditions).pretrig;
                options_ers_erd.posttrig = triggers(iter_conditions).posttrig;
                options_ers_erd.baseline = triggers(iter_conditions).baseline;
                %options_ers_erd.time_range = triggers(iter_conditions).time_range;
               
                [tf_map, times] = net_ers_erd(Ptot,T,events{iter_conditions},options_ers_erd);
                
                band_num = length(triggers(iter_conditions).frequency);%% added by M.Z. 22. May. 2018
                
                for iter_band = 1:band_num
                    
                    time_range = triggers(iter_conditions).time_range{iter_band}; %% added by M.Z. 22. May. 2018
                    freq_range = triggers(iter_conditions).frequency{iter_band}; %% added by M.Z. 22. May. 2018

                    vect_t= times>=time_range(1) & times<=time_range(2);%% changed by M.Z. 22. May. 2018
                    vect_f=(frequencies>=freq_range(1) & frequencies<=freq_range(2));%% added by M.Z. 22. May. 2018
                    if(isnan(mean(mean(tf_map(vect_f,vect_t)))))
                        disp('ok');
                    end
                    ers_erd_maps(k,iter_band,iter_conditions) = mean(mean(tf_map(vect_f,vect_t)));%% changed by M.Z. 22. May. 2018
                end 
            end
            t=toc;
            bar_len = net_progress_bar_t(['NET ERS/ERD source: ', dataset_info], k, nvoxels, t, bar_len);
        end
        
        %3.2 start saving to MNI space
        for iter_conditions = 1:1:conditions_num
            band_num = length(triggers(iter_conditions).frequency); %% added by M.Z. 22. May. 2018
            for iter_band=1:band_num
                
                freq_range=triggers(iter_conditions).frequency{iter_band};
                
                Vt.dim      = source.dim;
                Vt.pinfo    = [0.00001 ; 0 ; 0];
                Vt.dt       = [16 0];
                Vt.fname    = [dd2 filesep 'ers_erd_' triggers(iter_conditions).condition_name '_' num2str(freq_range(1)) '-' num2str(freq_range(2)) 'Hz_maps.nii'];
                Vt.mat      = net_pos2transform(source.pos, source.dim);
                Vt.n         = [1 1];
                image   = zeros(xdim*ydim*zdim,1);
                image(vox_indices) = ers_erd_maps(:, iter_band, iter_conditions);
                image   = reshape(image, xdim, ydim, zdim);
                spm_write_vol(Vt, image);               
            end      
        end

        net_warp([dd2 filesep 'ers_erd*maps.nii'],deformation_to_mni);
        delete([dd2, filesep, '*.nii']);
    end
    
    %% 5. ers_erd.roi
    if strcmp(options_ers_erd.roi_enable,'on')
        dd2=[dd filesep 'ers_erd_results'];
        if ~isdir(dd2)
            mkdir(dd2);
        end
        
        %4.1 calculate tf-maps of each roi
        seed_file=[NET_folder filesep 'template' filesep 'seeds' filesep options_ers_erd.seed_file '.mat'];
        load(seed_file,'seed_info');
        
        radius=6;
        
        nrois=length(seed_info);
        for i=1:nrois
            seed_info(i).coord_subj=net_project_coord(deformation_to_subj,seed_info(i).coord_mni);
            dist = pdist2(xyz',seed_info(i).coord_subj);
            voxel_list=find(dist<radius);
            if isempty(voxel_list)
                [~,voxel_list]=min(dist);
                disp(['NET ERS/ERD: ', dataset_info ,': please check seed ' num2str(i)]);
            end
            seed_info(i).seedindx=voxel_list;
        end
        bar_len = 0;
        for i=1:nrois
            tic;
            seedindx=seed_info(i).seedindx;
            
            nv=length(seedindx);
            mat_sig=zeros(nv,Ntime);
            for j=1:nv
                q=seedindx(j);
                mat_sig(j,:) = source.pca_projection(q,(3*q-2):(3*q))*source.imagingkernel((3*q-2):(3*q),:)*channel_data; %% add by JS, 06.07.2017
            end
            coeff=pca(mat_sig');
            coeffx=inv(coeff');
            brain_signal=coeffx(:,1)'*mat_sig;
            
            [~, F, T, Ptot] = spectrogram(brain_signal, window2, overlap, frequencies, Fs);
            
            if(strcmp(smooth, 'on'))
                Ptot = medfilt2(Ptot,[5 5]);  % smooth the spectrogram
            end
            %                 sigx=source.imagingkernel(1+3*(k-1),:)*channel_data;
            %                 sigy=source.imagingkernel(2+3*(k-1),:)*channel_data;
            %                 sigz=source.imagingkernel(3*k,:)*channel_data;
            %
            %                 [~, F, T, Px] = spectrogram(sigx, window2, overlap, frequencies, Fs);
            %                 [~, F, T, Py] = spectrogram(sigy, window2, overlap, frequencies, Fs);
            %                 [~, F, T, Pz] = spectrogram(sigz, window2, overlap, frequencies, Fs);
            %
            %                 % Sum the three PSDs for each 'seed' voxel
            %                 Ptot = Px+Py+Pz;
            %
            
            for iter_conditions = 1:1:conditions_num
                
                %prepare parameters
                options_ers_erd.pretrig = triggers(iter_conditions).pretrig;
                options_ers_erd.posttrig = triggers(iter_conditions).posttrig;
                options_ers_erd.baseline = triggers(iter_conditions).baseline;
                %options_ers_erd.time_range = triggers(iter_conditions).time_range;
                %get tf-map
                [tf_map, times] = net_ers_erd(Ptot,T,events{iter_conditions},options_ers_erd);
                
                %save result to structure
                ers_erd_roi(iter_conditions).condition_name = triggers(iter_conditions).condition_name;
                ers_erd_roi(iter_conditions).time_axis = times;
                ers_erd_roi(iter_conditions).frequency_axis = frequencies;
                ers_erd_roi(iter_conditions).tf_map(i,:,:) = tf_map;
                ers_erd_roi(iter_conditions).label{i} = seed_info(i).label;
                
            end
            t=toc;
            bar_len = net_progress_bar_t(['NET ERS/ERD ROI: ', dataset_info], i, nrois, t, bar_len);
        end
        
        triggers=triggers(1);
        save([dd2 filesep 'ers_erd_roi.mat'],'ers_erd_roi','triggers', 'seed_info','events', 'time_unit'); %save triggers rather than options_ers_erd
    end
    fprintf('\t** ERS/ERD analyses done! **\n')
else
    fprintf('No ERS/ERD analyses to run.\n')
end