function net_seed_connectivity(source_filename,options_seed)

if strcmp(options_seed.map_enable,'on') || strcmp(options_seed.matrix_enable,'on')
    
    fprintf('\t** Seed-based connectivity analyses started... **\n')
    NET_folder = net('path');
    
    % define paths
    % ------------
    ddx=fileparts(fileparts(source_filename));
    [dd,ff,ext] = fileparts(source_filename);
    dd2 = [dd filesep 'seed_connectivity'];
    if ~isdir(dd2)
        mkdir(dd2);  % Create the output folder if it doesn't exist..
    end
    
    dd3 = [dd2 filesep 'matrix_connectivity'];% added by JS, 06.2022
    if ~isdir(dd3)
        mkdir(dd3);  % Create the sub-folder if it doesn't exist..
    end
    
    % load data
    % ---------
    load(source_filename,'source');
    deformation_to_subj=[ddx filesep 'mr_data' filesep 'y_anatomy_prepro.nii'];
    deformation_to_mni=[ddx filesep 'mr_data' filesep 'iy_anatomy_prepro.nii'];
    
    % define parameters (channels, ntp, nvox)
    % ---------------------------------------
    nchan=size(source.sensor_data,1);
    
    Fs = 1/(source.time(2)-source.time(1));
    new_Fs = options_seed.fs;
    frequencies = [1:1:80];
    if not(new_Fs==Fs)
        channel_data = resample(source.sensor_data',new_Fs,Fs)';
        t=resample(source.time',new_Fs,Fs)';
        Ntime  = length(t);
    else
        channel_data = source.sensor_data;
        t=source.time;
        Ntime  = length(t);
    end
    
    vox_indices = find(source.inside==1);
    nvoxels = length(vox_indices);
    xdim    = source.dim(1);
    ydim    = source.dim(2);
    zdim    = source.dim(3);
    xyz = source.pos(vox_indices,:)';
    
    % load and project seeds in individual space
    % -----------------------------------------
    radius=6; % in mm
    seed_file=[NET_folder filesep 'template' filesep 'seeds' filesep options_seed.seed_file '.mat'];
    load(seed_file,'seed_info');
    nrois=length(seed_info);
    for i=1:nrois
        seed_info(i).coord_subj=net_project_coord(deformation_to_subj,seed_info(i).coord_mni);
        dist = pdist2(xyz',seed_info(i).coord_subj);
        voxel_list=find(dist<radius);
        if isempty(voxel_list)
            disp(['problem with seed ' num2str(i) '!']);
            [~,voxel_list]=min(dist);
        end
        seed_info(i).seedindx=voxel_list;
    end
    
    % added by JS, 06.2022
    tmp = seed_info;
    for i = 1:nrois
        tmp(i).seed = tmp(i).label;
        tmp(i).Xmni = tmp(i).coord_mni(1);
        tmp(i).Ymni = tmp(i).coord_mni(2);
        tmp(i).Zmni = tmp(i).coord_mni(3);
    end
    tmp = rmfield(tmp,{'label','coord_mni','frequency','coord_subj','seedindx'});
    T = struct2table(tmp);
    writetable(T,[dd3 filesep 'seeds.txt'],'Delimiter','space');
    clear tmp T frvect
    

    %% if task data..

    if length(options_seed.triggers) > 1 && ~strcmpi(options_seed.triggers,'nan')% .. data has to be epoched
        triggers_template_file = [NET_folder filesep 'template' filesep 'triggers' filesep options_seed.triggers '.mat'];
        load(triggers_template_file, 'triggers');
        conditions_num = length(triggers);
        
        Fs_ref=1000; % needed for following epoching
        if not(new_Fs==Fs_ref)
            channel_data = (resample(double(channel_data)',Fs_ref,new_Fs))';
        end
        events_all = source.events;
        events_num = length(events_all);
        events = cell(1, conditions_num);
        
        % classify events according to triggers
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
        
        % epoch the channel signals accordingly
        if triggers(iter_conditions).duration > 0 % opt 1: block design
        for iter_conditions = 1:1:conditions_num
            tmp = events{iter_conditions};
            starttime = tmp(1).time*Fs_ref;
            stoptime = starttime + triggers(iter_conditions).duration*Fs_ref;
            
            clear new_channel_data
            new_channel_data = channel_data(:,starttime:stoptime);
            if (new_Fs > Fs_ref) %resampling only to higher frequency
                new_channel_data = resample(new_channel_data',Fs,Fs_ref)';
            end
    
            epoches(iter_conditions).condition_name = triggers(iter_conditions).condition_name;
            epoches(iter_conditions).data = new_channel_data;
        end
                
        else % opt 2: randomized design
        for iter_conditions = 1:1:conditions_num
            options_trial.pretrig = 0; % epoch is from trigger onset to connectivity_time
            options_trial.posttrig = triggers(iter_conditions).connectivity_time;
            options_trial.baseline = [];

            clear epoched_data new_channel_data
            epoched_data = net_epoch(channel_data,Fs_ref,events{iter_conditions},options_trial);
            epoched_data = permute(epoched_data,[2,1,3]);
            new_channel_data = reshape(epoched_data,size(epoched_data,1),length(events{iter_conditions})*options_trial.posttrig); % concatenate all epochs
            if (new_Fs > Fs_ref) %resampling only to higher frequency
                new_channel_data = resample(new_channel_data',Fs,Fs_ref)';
            end
              
            epoches(iter_conditions).condition_name = triggers(iter_conditions).condition_name;
            epoches(iter_conditions).data = new_channel_data;
            epoches(iter_conditions).trials = epoched_data;
        end
        end
        save([dd2 filesep 'epochs_timecourses_sensor.mat'],'epoches', 'triggers','events');
    
    else % resting state data
        epoches.condition_name = 'resting';
        epoches.data = channel_data;
        Fs_ref = 0;
    end
    %%
    
    for cond = 1:numel(epoches)
    
    data = epoches(cond).data;
    if ~isempty(options_seed.triggers), t = 0:size(data,2)-1; Ntime  = length(t); 
    if (new_Fs < Fs_ref), new_Fs = Fs_ref; disp(['**Warning** new Fs is ' num2str(Fs_ref) 'Hz.']); end, end % if task data, adapt t to the new signal
    
    %% mapping
    %  -------
    winsize  = round(new_Fs*options_seed.window_duration);
    overlap  = round(new_Fs*options_seed.window_overlap);
    [~, F, T] = spectrogram(t, winsize, overlap, frequencies, new_Fs);
    FT_all = zeros(nvoxels,length(F),length(T));
    FT_roi = zeros(nrois,length(F),length(T));
    
    % reconstruct source activities
    % ----------------------------
    brain = zeros(nvoxels,Ntime);
    for k = 1:nvoxels
        brain(k,:) = source.pca_projection(k,(3*k-2):(3*k))*source.imagingkernel((3*k-2):(3*k),:)*data;
    end
    [coeff,score] = pca(brain','Centered',false);
    fpc = score(:,1)*coeff(:,1)'; % for regression
    brain = brain - fpc';
    clear fpc coeff score
    
    for k = 1:nvoxels % for normalization
        tmp = brain(k,:);
        brain(k,:) = tmp./std(tmp);
    end
    % for multiple runs of net_seed_connectivity, save source activity matrix:
    % % save([ ddx filesep 'eeg_source' filesep 'cleansource.mat'],'brain','-v7.3')
    % % load([ ddx filesep 'eeg_source' filesep 'cleansource.mat'],'brain')
    
    if strcmp(options_seed.map_enable,'on')
        switch options_seed.connectivity_measure
            case {'blpc_spec','blpc_ss'}
                if strcmp(options_seed.connectivity_measure,'blpc_spec')
                    % time-frequency decomposition
                    % ----------------------------
                    for k=1:nvoxels
                        disp([num2str(k) ' / ' num2str(nvoxels)]);
                        brain_signal = brain(k,:);
                        FT_all(k,:,:) = spectrogram(brain_signal, winsize, overlap, frequencies, new_Fs);
                    end
                    
                    for k = 1:nrois
                        seedindx = seed_info(k).seedindx;
                        
                        nv      = length(seedindx);
                        mat_sig = zeros(nv,Ntime);
                        for j = 1:nv
                            q = seedindx(j);
                            mat_sig(j,:) = brain(q,:);
                        end
                        coeff = pca(mat_sig');
                        coeffx = inv(coeff');
                        brain_signal   = coeffx(:,1)'*mat_sig; %first PC
                        FT_roi(k,:,:)  = spectrogram(brain_signal, winsize, overlap, frequencies, new_Fs);
                    end
                end
        end
        
        % othogonalization and connectivity
        % ------------
        for k = 1:nrois
            corr_map = zeros(nvoxels,length(frequencies));
            Si = squeeze(FT_roi(k,:,:))';
            for w = 1:nvoxels
                if ismember(w,seed_info(k).seedindx) % w belong to the voxel_list corresponding to the k-th seed, ie is in the ROI around the seed
                    corr_map(w,:) = nan;
                else
                    Sj = squeeze(FT_all(w,:,:))';
                    corr_map(w,:) = net_blp_corr(Si, Sj,options_seed.orthogonalize);
                end
            end
            corr_map( isnan(corr_map) ) = max(corr_map(:)) - nanstd(corr_map(:));
            
            nbands = length(seed_info(k).frequency);
            for zz=1:nbands
                band=seed_info(k).frequency{zz};
                vect_f=(frequencies>=band(1) & frequencies<=band(2));
                seed_map = mean(corr_map(:,vect_f),2)';
                
                Vt.dim      = source.dim;
                Vt.pinfo    = [0.000001 ; 0 ; 0];
                Vt.dt       = [16 0];
                Vt.fname    = [dd2 filesep 'seed_' seed_info(k).label '_(' num2str(band(1)) '-' num2str(band(2)) 'Hz)_' epoches(cond).condition_name '_maps.nii'];
                Vt.mat      = net_pos2transform(source.pos, source.dim);
                Vt.n        = [1 1];
                image       = seed_map;
                seed_image  = zeros(xdim*ydim*zdim,1);
                seed_image(vox_indices) = image;
                seed_image  = reshape(seed_image, xdim, ydim, zdim);
                spm_write_vol(Vt, seed_image);
            end
        end
        net_warp([dd2 filesep 'seed*maps.nii'],deformation_to_mni);
    end
    
    
    %% matrix
    %  ------
    if strcmp(options_seed.matrix_enable,'on')
        bands = {1:4, 4:8, 8:13, 13:30, 30:80};
        switch options_seed.connectivity_measure
            case {'blpc_spec','blpc_ss'}
                
                if strcmp(options_seed.connectivity_measure,'blpc_spec')
                    % time-frequency decomposition
                    % ----------------------------
                    for k = 1:nrois
                        seedindx = seed_info(k).seedindx;
                        
                        nv      = length(seedindx);
                        mat_sig = zeros(nv,Ntime);
                        for j = 1:nv
                            q = seedindx(j);
                            mat_sig(j,:) = brain(q,:);
                        end
                        coeff = pca(mat_sig');
                        coeffx = inv(coeff');
                        brain_signal   = coeffx(:,1)'*mat_sig; %first PC
                        FT_roi(k,:,:)  = spectrogram(brain_signal, winsize, overlap, frequencies, new_Fs);
                        
                    end
                end
        end
        
        % othogonalization and connectivity
        % ------------
        corr_matrix = zeros(nrois,nrois,length(frequencies));
        for k = 1:nrois
            Si = squeeze(FT_roi(k,:,:))';
            for w = k+1:nrois
                Sj = squeeze(FT_roi(w,:,:))';
                corr_matrix(k,w,:) = net_blp_corr(Si, Sj,options_seed.orthogonalize);
                corr_matrix(w,k,:) = corr_matrix(k,w,:);
            end
        end
        save([dd3 filesep epoches(cond).condition_name '_matrix_connectivity.mat'],'corr_matrix','F','T','options_seed','seed_info','-v7.3');
        
        % save connectivity matrices, JS 06.2022
        for b = 1:numel(bands)
            fr = bands{b};
            avgConn = nanmean(corr_matrix(:,:,fr),3);
            T = table(avgConn);
            
            writetable(T,[dd3 filesep epoches(cond).condition_name '_avg_connectivity_(' num2str(fr(1)) '-' num2str(fr(end)) ')Hz.xlsx'],'WriteVariableNames',0,'Sheet',1);
            clear avgconn fr T
        end
    end
    end
    fprintf('\t** Seed-based connectivity analyses done! **\n')
else
    fprintf('No seed-based connectivity analyses to run.\n')
end


% update 10.10.2019, by JS:
% implement regression of first PC and power normalization to go from
% average to infinity re-referencing
% update 20.06.2022, by JS:
% save seed file (.txt) and band-specific matrix connectivity (.xlsx) in a
% subfolder of the seed connectivity output folder where also the
% connectivity matrices (.mat) are saved