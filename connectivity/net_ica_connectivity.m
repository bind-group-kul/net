function net_ica_connectivity(source_filename,options_ica)

if strcmp(options_ica.enable,'on')
    
    fprintf('\t** ICA connectivity analyses started... **\n')
    load(source_filename,'source');  % to save the matrix bigger than 2GB, added by QL, 04.12.2014
    ddx=fileparts(fileparts(source_filename));
    NET_folder = net('path');
    deformation_to_mni=[ddx filesep 'mr_data' filesep 'iy_anatomy_prepro.nii'];
    
    dd=fileparts(source_filename);
    dd2=[dd filesep 'ica_results'];
    if ~isdir(dd2)
        mkdir(dd2);  % Create the output folder if it doesn't exist..
    end
    
    if (strcmpi(options_ica.decomposition_type,'temporal')) || strcmpi(options_ica.decomposition_type,'both')%modified by JS 03.2020
    dd2x=[dd2 filesep 'tica'];
    if ~isdir(dd2x)
        mkdir(dd2x);  % Create the output folder if it doesn't exist..
    end
    end
    if (strcmpi(options_ica.decomposition_type,'spatial')) || strcmpi(options_ica.decomposition_type,'both')%modified by JS 03.2020
    dd2y=[dd2 filesep 'sica'];
    if ~isdir(dd2y)
        mkdir(dd2y);  % Create the output folder if it doesn't exist..
    end
    end
    
    %% generating power envelopes
    str=options_ica.frequency_bands;
    xx=strfind(str,'[');
    yy=strfind(str,']');
    nbands=min(length(xx),length(yy));
    band=cell(nbands,1);
    for i=1:nbands
        band{i}=str2num(str(xx(i)+1:yy(i)-1));
    end
    
    vox_indices=find(source.inside==1);
    nvoxels=length(vox_indices);
    xdim    = source.dim(1);
    ydim    = source.dim(2);
    zdim    = source.dim(3);
    
    mat=net_pos2transform(source.pos, source.dim);
    res=abs(det(mat(1:3,1:3)))^(1/3);
    
    Fs=1/(source.time(2)-source.time(1));
    winsize  = ceil(Fs*options_ica.window_duration);
    overlap  = round(Fs*options_ica.window_overlap);
    frequencies=round(options_ica.highpass:options_ica.lowpass);
    t        = source.time;
    channel_data=net_filterdata(source.sensor_data,Fs,options_ica.highpass,options_ica.lowpass);

    %% if task data..
    if length(options_ica.triggers) > 1 % .. data has to be epoched
        triggers_template_file = [NET_folder filesep 'template' filesep 'triggers' filesep options_ica.triggers '.mat'];
        load(triggers_template_file, 'triggers');
        conditions_num = length(triggers);
        
        Fs_ref=1000; % needed for following epoching
        if not(Fs==Fs_ref)
            channel_data = (resample(double(channel_data)',Fs_ref,Fs))';
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
% %             better not resampling back to the original Fs to keep as many samples as possible
% %             if not(Fs == Fs_ref) 
% %                 new_channel_data = resample(new_channel_data',Fs,Fs_ref)';
% %             end
 
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
% %             better not resampling back to the original Fs to keep as many samples as possible
% %             if not(Fs == Fs_ref) 
% %                 new_channel_data = resample(new_channel_data',Fs,Fs_ref)';
% %             end
            
            epoches(iter_conditions).condition_name = triggers(iter_conditions).condition_name;
            epoches(iter_conditions).data = new_channel_data;
            epoches(iter_conditions).trials = epoched_data;
        end
        end
        save([dd2 filesep 'epochs_timecourses_sensor.mat'],'epoches', 'triggers','events');
    
    else % resting state data
        epoches.condition_name = 'resting';
        epoches.data = channel_data;
    end
    %%
    
    for cond = 1:numel(epoches)
    
    data = epoches(cond).data;
    if ~isempty(options_ica.triggers), t = 0:size(data,2)-1; end % if task data, adapt t to the new signal
    
    [~, F, T] = spectrogram(t, winsize, overlap, frequencies, Fs);
    nchan=size(data,1);
%     
%     channel_power=zeros(nchan,length(T));
%     for k=1:nchan
%         disp([num2str(k) ' / ' num2str(nchan)]);
%         [S, F, T, P] = spectrogram(data(k,:), winsize, overlap, frequencies, Fs);
%         channel_power(k,:) = sum(P,1);
%     end
    
    FT_pow = zeros(nvoxels,length(F),length(T));
    for k=1:nvoxels
        disp([num2str(k) ' / ' num2str(nvoxels)]);
        brain_signal = source.pca_projection(k,(3*k-2):(3*k))*source.imagingkernel((3*k-2):(3*k),:)*data; %% add by JS, 06.07.2017
        [S, F, T, P] = spectrogram(brain_signal, winsize, overlap, frequencies, Fs);
        FT_pow(k,:,:) = P;
    end
    
    %% ICA calculation
    power_envelope=squeeze(sum(FT_pow,2));
    power_envelope  = power_envelope./(ones(size(power_envelope,1),1)*mean(power_envelope,1));
    power_envelope  = power_envelope./(mean(power_envelope,2)*ones(1,size(power_envelope,2)));
    
    Ntime=length(T);

    power_envelope2  = power_envelope;
    ntp         = size(power_envelope2,2);
    normal=[1:ntp];
    samplesize = 1;
    ntp_sel = ceil(length(normal)*samplesize);

    randn('seed',0);
    samples     = net_getrandsamples(normal, ntp_sel,'random');

    [dewhitening, score, latent]=pca(power_envelope2(:,samples)','Centered','off');
    latent=100*latent/sum(latent);
    n_pcs=sum(latent>0.1*mean(latent));
    retained_variance=sum(latent(1:n_pcs));

    PC = score(:,1:n_pcs);
  
    y_final = dewhitening(:,1:n_pcs)*PC';
    Ntime=length(T);
    if options_ica.smooth_fwhm>0
        sq=options_ica.smooth_fwhm/(res*sqrt(8*log(2)));
    end
    
    image_all = zeros(xdim,ydim,zdim,Ntime);
    disp('NET - smooth the source...');
    for i=1:Ntime
        sig_image = zeros(xdim*ydim*zdim,1);
        sig_image(vox_indices) = y_final(:, i );
        image = reshape(sig_image,xdim,ydim,zdim);
        if options_ica.smooth_fwhm>0
            image_all(:,:,:,i) = smooth3(image, 'gaussian', [3 3 3],sq);  % It is important to smooth source data before running ICA
        else
            image_all(:,:,:,i)= image;
        end
    end
    clear sig_image image
    
    %% calculate the number of ICs
    mask_tot=zeros(1,xdim*ydim*zdim);
    mask_tot(vox_indices)=1;
    [comp_est, mdl, aic, kic] = icatb_estimate_dimension(image_all, mask_tot);

    options_ica.niter_icasso = 10;

    
    if comp_est < 15
        comp_est = 15;
    end
    
    
    %% calculate ICA
    power_envelope_ica = reshape(image_all, xdim*ydim*zdim, Ntime );
    power_envelope_ica = power_envelope_ica(vox_indices,:);
    switch options_ica.decomposition_type
        
        case {'temporal'}
            flag_tica=1;
            flag_sica=0;
            
        case {'spatial'}
            flag_tica=0;
            flag_sica=1;
            
        case{'both'}
            flag_tica=1;
            flag_sica=1;
    end
    
    %% temporal ICA
    if flag_tica==1
        [~, map_weights, ~, tICs, ~] = icasso(power_envelope_ica ,options_ica.niter_icasso,'g','tanh','numOfIC',comp_est,'approach','defl','maxNumIterations', 500, 'vis','off');
        map_weights_tica = map_weights;
        tICs_tica = tICs;
        
        length_map_weights = size(map_weights_tica,2); % MM 11.12.17
        tICs_tica = pinv(map_weights_tica)*power_envelope_ica;
        
        % ------------------------------------------------
        % compute correlation or Linear regression between each IC
        %         ica_maps = zeros(size(tICs,1),nvoxels);
        ica_maps_tica = zeros(min(size(tICs_tica)),nvoxels);
        
        switch options_ica.mapping_type
            case {'Spearman', 'spearman'}
                for kk=1:nvoxels
                    ica_maps_tica(:,kk) = corr(tICs_tica',power_envelope2(kk,:)', 'type','Spearman'); % Spearman correlation
                end
                ica_maps_tica       = atanh(ica_maps_tica);
                
            case {'Pearson', 'pearson'}
                for kk=1:nvoxels
                    ica_maps_tica(:,kk) = corr(tICs_tica',power_envelope2(kk,:)', 'type','Pearson'); % Pearson correlation
                end
                ica_maps_tica       = atanh(ica_maps_tica);
                
           case {'Regression', 'regression'}
                ica_maps_tica=pinv(tICs_tica*pinv(power_envelope2))';
                ica_maps_tica=zscore(ica_maps_tica')';
        end
        
        kurt_data = kurt(tICs_tica');
        
        Y = prctile(kurt_data,25); 
        kurt_data_tmp = (kurt_data>Y);
        pos_tot = find(kurt_data_tmp == 1);

        ica_maps_tica = ica_maps_tica(pos_tot,:);
        
        % 3. Save the ica_map and transform into MNI space
        % 3.1 write ica_map Z-score into 'nifit' files
        Vt.dim      = source.dim;
        Vt.pinfo    = [0.000001 ; 0 ; 0];
        Vt.dt       = [16 0];
        Vt.mat      = net_pos2transform(source.pos, source.dim);
        
        Vt.fname    = [dd2x filesep 'tica_(' num2str(options_ica.highpass) '-' num2str(options_ica.lowpass) 'Hz)_' epoches(cond).condition_name '_maps.nii'];
        for i = 1:size(ica_maps_tica,1)
            Vt.n        = [i 1];
            image       = ica_maps_tica(i,:)';
            ica_image   = zeros(xdim*ydim*zdim,1);
            ica_image(vox_indices) = image;
            ica_image   = reshape(ica_image, xdim, ydim, zdim);
            spm_write_vol(Vt, ica_image);
        end
        
        for k=1:nbands
            power_envelope_band=squeeze(sum(FT_pow(:,F>=band{k}(1) & F<=band{k}(2),:),2));
            power_envelope_band  = power_envelope_band./(ones(size(power_envelope_band,1),1)*mean(power_envelope_band,1));
            power_envelope_band  = power_envelope_band./(mean(power_envelope_band,2)*ones(1,size(power_envelope_band,2)));
            
            vox_indices=find(source.inside==1);
            image_all = zeros(xdim,ydim,zdim,Ntime);
            disp('NET - smooth the source...');
            for i=1:Ntime
                sig_image = zeros(xdim*ydim*zdim,1);
                sig_image(vox_indices) = power_envelope_band(:, i );
                image = reshape(sig_image,xdim,ydim,zdim);
                
                image_all(:,:,:,i)= image;
            end
            
            vox_indices = find(image_all(:,:,:,1)~=0);  %%%% GAIA (image_all2)
            power_envelope_band = reshape(image_all, xdim*ydim*zdim, Ntime );
            power_envelope_band = power_envelope_band(vox_indices,:);

            tICs_tica_band_tmp = pinv(map_weights_tica)*power_envelope_band;
            ica_maps_tica_band = zeros(min(size(tICs_tica)),nvoxels);
            
            switch options_ica.mapping_type
                case {'Spearman', 'spearman'}
                    for kk=1:nvoxels
                        ica_maps_tica_band(:,kk) = corr(tICs_tica',power_envelope_band(kk,:)', 'type','Spearman'); % Spearman correlation
                    end
                    
                case {'Pearson', 'pearson'}
                    for kk=1:nvoxels
                        ica_maps_tica_band(:,kk) = corr(tICs_tica',power_envelope_band(kk,:)', 'type','Pearson'); % Pearson correlation
                    end
                  
                case {'Regression', 'regression'}
                ica_maps_tica_band=pinv(tICs_tica*pinv(power_envelope_band))';
                ica_maps_tica_band=zscore(ica_maps_tica_band')';
            end
            
            ica_maps_tica_band   = atanh(ica_maps_tica_band);
            ica_maps_tica_band = ica_maps_tica_band(pos_tot,:);
            tICs_tica_band_tmp = tICs_tica_band_tmp(pos_tot,:);
            
            % 3. Save the ica_map and transform into MNI space
            % 3.1 write ica_map Z-score into 'nifit' files
            Vt.dim      = source.dim;
            Vt.pinfo    = [0.000001 ; 0 ; 0];
            Vt.dt       = [16 0];
            Vt.mat      = net_pos2transform(source.pos, source.dim);
            
            Vt.fname    = [dd2x filesep 'tica_(' num2str(band{k}(1)) '-' num2str(band{k}(2)) 'Hz)_' epoches(cond).condition_name '_maps.nii'];
            for i = 1:size(ica_maps_tica_band,1)
                Vt.n        = [i 1];
                image       = ica_maps_tica_band(i,:)';
                ica_image   = zeros(xdim*ydim*zdim,1);
                ica_image(vox_indices) = image;
                ica_image   = reshape(ica_image, xdim, ydim, zdim);
                spm_write_vol(Vt, ica_image);
            end
        tICs_tica_band{k} = tICs_tica_band_tmp;
        end
        
        net_warp([dd2x filesep 'tica*maps.nii'],deformation_to_mni);
        rsn_dir=[dd2x filesep 'mni' filesep 'rsn'];
        if ~isdir(rsn_dir)
            mkdir(rsn_dir);  % Create the output folder if it doesn't exist..
        end
        
        fname    = [dd2x filesep 'mni' filesep 'tica_(' num2str(options_ica.highpass) '-' num2str(options_ica.lowpass) 'Hz)_' epoches(cond).condition_name '_maps_mni.nii'];
        [matching_tica,rsn_name_tica,corr_value_tica]=net_rsn_match(fname,[NET_folder filesep 'template' filesep 'RSNs_fMRI']);
        tICs_tica = tICs_tica(pos_tot,:);
        map_weights_tica = map_weights_tica(:,pos_tot);
        
        [row_cor_tica,col_cor_tica] = find(matching_tica == 1 | matching_tica == -1);
        rsn_tc_tica = tICs_tica(row_cor_tica,:);
        rsn_weights_tica = map_weights_tica(:,row_cor_tica);

        matching_tica_tmp = matching_tica(row_cor_tica,:);

        clear rsn_tc_tica_band
        for b = 1:nbands %modified by JS 03.2020
        rsn_tc_tica_band(:,:,b) = tICs_tica_band{b}(row_cor_tica,:);
        end
%         rsn_tc_tica_delta = tICs_tica_band{1}(row_cor_tica,:);
%         rsn_tc_tica_theta = tICs_tica_band{2}(row_cor_tica,:);
%         rsn_tc_tica_alpha = tICs_tica_band{3}(row_cor_tica,:);
%         rsn_tc_tica_beta = tICs_tica_band{4}(row_cor_tica,:);
%         rsn_tc_tica_gamma = tICs_tica_band{5}(row_cor_tica,:);
        
        save([rsn_dir filesep 'tica_timecourses_' epoches(cond).condition_name '_maps'], '-v7.3','rsn_name_tica','rsn_weights_tica','rsn_tc_tica','corr_value_tica','rsn_tc_tica_band','matching_tica_tmp');
        
        fname    = [dd2x filesep 'mni' filesep 'tica_(' num2str(options_ica.highpass) '-' num2str(options_ica.lowpass) 'Hz)_' epoches(cond).condition_name '_maps_mni.nii'];
        fname_rsn=cell(1,length(rsn_name_tica));
        for kk=1:length(rsn_name_tica)
            fname_rsn{kk}=[dd2x filesep 'mni' filesep 'rsn' filesep 'rsn_' rsn_name_tica{kk} '_tica_(' num2str(options_ica.highpass) '-' num2str(options_ica.lowpass) 'Hz)_' epoches(cond).condition_name '_mni.nii'];
        end
                
        V=spm_vol(fname);
        ica_data=spm_read_vols(V);
        for kk=1:length(fname_rsn) % skip maps without a match: modified by JS, 05.2023
            pos=find(matching_tica(:,kk) == 1 | matching_tica(:,kk) == -1);  % select IC % old code: not(matching_tica(:,kk)==0)
            if not(isempty(pos))
                map=sign(matching_tica(pos,kk))*ica_data(:,:,:,pos);
                V(1).fname=fname_rsn{kk};
                spm_write_vol(V(1),map);
            end
        end
        
        for i=1:nbands
            fname    = [dd2x filesep 'mni' filesep 'tica_(' num2str(band{i}(1)) '-' num2str(band{i}(2)) 'Hz)_' epoches(cond).condition_name '_maps_mni.nii'];
            fname_rsn=cell(1,length(rsn_name_tica));
            for kk=1:length(rsn_name_tica)
                fname_rsn{kk}=[dd2x filesep 'mni' filesep 'rsn' filesep 'rsn_' rsn_name_tica{kk} '_tica_(' num2str(band{i}(1)) '-' num2str(band{i}(2)) 'Hz)_' epoches(cond).condition_name '_mni.nii'];
            end
            
            V=spm_vol(fname);
            ica_data_band=spm_read_vols(V);
            for kk=1:length(fname_rsn)
                pos=find(matching_tica(:,kk) == 1 | matching_tica(:,kk) == -1);  % select IC % old code: not(matching_tica(:,kk)==0)
                if not(isempty(pos))
                    map=sign(matching_tica(pos,kk))*ica_data_band(:,:,:,pos);
                    V(1).fname=fname_rsn{kk};
                    spm_write_vol(V(1),map);
                end
            end
        end
    end
    
 %% spatial ICA   
    if flag_sica==1
        options_ica.niter_icasso = 10;
        [~,tICs_sica , ~, map_weights_sica, ~] = icasso(power_envelope_ica',options_ica.niter_icasso,'g','tanh','numOfIC',comp_est,'approach','defl','maxNumIterations', 500, 'vis','off');
        
        length_map_weights = size(map_weights_sica,1); % MM 11.12.17
        tICs_sica = map_weights_sica*power_envelope_ica;
        
        % ------------------------------------------------
        % compute correlation or Linear regression between each IC
        %         ica_maps = zeros(size(tICs,1),nvoxels);
        ica_maps_sica = zeros(min(size(tICs_sica)),nvoxels);
        
        switch options_ica.mapping_type
            case {'Spearman', 'spearman'}
                for kk=1:nvoxels
                    ica_maps_sica(:,kk) = corr(tICs_sica',power_envelope2(kk,:)', 'type','Spearman'); % Spearman correlation
                end
                ica_maps_sica=atanh(ica_maps_sica);
                
            case {'Pearson', 'pearson'}
                for kk=1:nvoxels
                    ica_maps_sica(:,kk) = corr(tICs_sica',power_envelope2(kk,:)', 'type','Pearson'); % Pearson correlation
                end
                ica_maps_sica       = atanh(ica_maps_sica);
                
            case {'Regression', 'regression'}
                ica_maps_sica=pinv(tICs_sica*pinv(power_envelope2))';
                ica_maps_sica=zscore(ica_maps_sica')';
        end
        kurt_data = kurt(tICs_sica');
        Y = prctile(kurt_data,25); 
        kurt_data_tmp = (kurt_data>Y);
        pos_tot = find(kurt_data_tmp == 1);
        
        ica_maps_sica = ica_maps_sica(pos_tot,:);
        
        % 3. Save the ica_map and transform into MNI space
        % 3.1 write ica_map Z-score into 'nifit' files
        Vt.dim      = source.dim;
        Vt.pinfo    = [0.000001 ; 0 ; 0];
        Vt.dt       = [16 0];
        Vt.mat      = net_pos2transform(source.pos, source.dim);
        
        Vt.fname    = [dd2y filesep 'sica_(' num2str(options_ica.highpass) '-' num2str(options_ica.lowpass) 'Hz)_' epoches(cond).condition_name '_maps.nii'];
        for i = 1:size(ica_maps_sica,1)
            Vt.n        = [i 1];
            image       = ica_maps_sica(i,:)';
            ica_image   = zeros(xdim*ydim*zdim,1);
            ica_image(vox_indices) = image;
            ica_image   = reshape(ica_image, xdim, ydim, zdim);
            spm_write_vol(Vt, ica_image);
        end
        
        for k=1:nbands
            power_envelope_band=squeeze(sum(FT_pow(:,F>=band{k}(1) & F<=band{k}(2),:),2));
            power_envelope_band  = power_envelope_band./(ones(size(power_envelope_band,1),1)*mean(power_envelope_band,1));
            power_envelope_band  = power_envelope_band./(mean(power_envelope_band,2)*ones(1,size(power_envelope_band,2)));
            vox_indices=find(source.inside==1);
     
            image_all = zeros(xdim,ydim,zdim,Ntime);
            disp('NET - smooth the source...');
            for i=1:Ntime
                sig_image = zeros(xdim*ydim*zdim,1);
                sig_image(vox_indices) = power_envelope_band(:, i );
                image = reshape(sig_image,xdim,ydim,zdim);
                
                image_all(:,:,:,i)= image;
            end
            vox_indices = find(image_all(:,:,:,1)~=0);  %%% GAIA (image_all2)
            power_envelope_band = reshape(image_all, xdim*ydim*zdim, Ntime );
            power_envelope_band = power_envelope_band(vox_indices,:);
            
            tICs_sica_band_tmp = map_weights_sica*power_envelope_band;
            ica_maps_sica_band = zeros(min(size(tICs_sica)),nvoxels);
            
            switch options_ica.mapping_type
                case {'Spearman', 'spearman'}
                    for kk=1:nvoxels
                        ica_maps_sica_band(:,kk) = corr(tICs_sica',power_envelope_band(kk,:)', 'type','Spearman'); % Spearman correlation
                    end
                    ica_maps_sica_band   = atanh(ica_maps_sica_band);
                    
                case {'Pearson', 'pearson'}
                    for kk=1:nvoxels
                        ica_maps_sica_band(:,kk) = corr(tICs_sica',power_envelope_band(kk,:)', 'type','Pearson'); % Pearson correlation
                    end
                    ica_maps_sica_band   = atanh(ica_maps_sica_band);
                    
                case {'Regression', 'regression'}
                ica_maps_sica_band=pinv(tICs_sica*pinv(power_envelope_band))';
                ica_maps_sica_band=zscore(ica_maps_sica_band')';                    
            end
            ica_maps_sica_band = ica_maps_sica_band(pos_tot,:);
            tICs_sica_band_tmp = tICs_sica_band_tmp(pos_tot,:);
            
            % 3. Save the ica_map and transform into MNI space
            % 3.1 write ica_map Z-score into 'nifit' files
            Vt.dim      = source.dim;
            Vt.pinfo    = [0.000001 ; 0 ; 0];
            Vt.dt       = [16 0];
            Vt.mat      = net_pos2transform(source.pos, source.dim);
            
            Vt.fname    = [dd2y filesep 'sica_(' num2str(band{k}(1)) '-' num2str(band{k}(2)) 'Hz)_' epoches(cond).condition_name '_maps.nii'];
            for i = 1:size(ica_maps_sica_band,1)
                Vt.n        = [i 1];
                image       = ica_maps_sica_band(i,:)';
                ica_image   = zeros(xdim*ydim*zdim,1);
                ica_image(vox_indices) = image;
                ica_image   = reshape(ica_image, xdim, ydim, zdim);
                spm_write_vol(Vt, ica_image);
            end
            
            tICs_sica_band{k} = tICs_sica_band_tmp;
        end
        net_warp([dd2y filesep 'sica*maps.nii'],deformation_to_mni);
        rsn_dir=[dd2y filesep 'mni' filesep 'rsn'];
        if ~isdir(rsn_dir)
            mkdir(rsn_dir);  % Create the output folder if it doesn't exist..
        end
        
        fname    = [dd2y filesep 'mni' filesep 'sica_(' num2str(options_ica.highpass) '-' num2str(options_ica.lowpass) 'Hz)_' epoches(cond).condition_name '_maps_mni.nii'];
        [matching_sica,rsn_name_sica,corr_value_sica]=net_rsn_match(fname,[NET_folder filesep 'template' filesep 'RSNs_fMRI']);
        
        tICs_sica = tICs_sica(pos_tot,:);
        map_weights_sica = map_weights_sica(pos_tot,:);
        [row_cor_sica,col_cor_sica] = find(matching_sica == 1 | matching_sica == -1);
        
        rsn_tc_sica = tICs_sica(row_cor_sica,:);
        rsn_weights_sica = map_weights_sica(:,row_cor_sica);

        matching_sica_tmp = matching_sica(row_cor_sica,:);
        
        clear rsn_tc_sica_band
        for b = 1:nbands %modified by JS 03.2020
        rsn_tc_sica_band(:,:,b) = tICs_sica_band{b}(row_cor_sica,:);
        end
        
        save([rsn_dir filesep 'sica_timecourses_' epoches(cond).condition_name '_maps'], '-v7.3','rsn_name_sica','rsn_weights_sica','rsn_tc_sica','corr_value_sica','rsn_tc_sica_band','matching_sica_tmp');
        
        fname    = [dd2y filesep 'mni' filesep 'sica_(' num2str(options_ica.highpass) '-' num2str(options_ica.lowpass) 'Hz)_' epoches(cond).condition_name '_maps_mni.nii'];
        fname_rsn=cell(1,length(rsn_name_sica));
        for kk=1:length(rsn_name_sica)
            fname_rsn{kk}=[dd2y filesep 'mni' filesep 'rsn' filesep 'rsn_' rsn_name_sica{kk} '_sica_(' num2str(options_ica.highpass) '-' num2str(options_ica.lowpass) 'Hz)_' epoches(cond).condition_name '_mni.nii'];
        end
        
        V=spm_vol(fname);
        ica_data=spm_read_vols(V);
        for kk=1:length(fname_rsn)
            pos=find(matching_sica(:,kk) == 1 | matching_sica(:,kk) == -1);  % select IC % old code: not(matching_tica(:,kk)==0)
            if not(isempty(pos))
                map=sign(matching_sica(pos,kk))*ica_data(:,:,:,pos);
                V(1).fname=fname_rsn{kk};
                spm_write_vol(V(1),map);
            end
        end
        
        for i=1:nbands
            fname    = [dd2y filesep 'mni' filesep 'sica_(' num2str(band{i}(1)) '-' num2str(band{i}(2)) 'Hz)_' epoches(cond).condition_name '_maps_mni.nii'];
            fname_rsn=cell(1,length(rsn_name_sica));
            for kk=1:length(rsn_name_sica)
                fname_rsn{kk}=[dd2y filesep 'mni' filesep 'rsn' filesep 'rsn_' rsn_name_sica{kk} '_sica_(' num2str(band{i}(1)) '-' num2str(band{i}(2)) 'Hz)_' epoches(cond).condition_name '_mni.nii'];
            end
            
            V=spm_vol(fname);
            ica_data_band=spm_read_vols(V);
            for kk=1:length(fname_rsn)
                pos=find(matching_sica(:,kk) == 1 | matching_sica(:,kk) == -1);  % select IC % old code: not(matching_tica(:,kk)==0)
                if not(isempty(pos))
                    map=sign(matching_sica(pos,kk))*ica_data_band(:,:,:,pos);
                    V(1).fname=fname_rsn{kk};
                    spm_write_vol(V(1),map);
                end
            end
        end
    end
    end
    fprintf('\t** ICA connectivity analyses done! **\n')
else
    fprintf('No ICA connectivity analyses to run.\n')
end