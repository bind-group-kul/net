function [ emg_events ] = net_extract_emg_events( eeg_filename, file_type, experiment_info, emg_channels )
%NET_ERS_ERD extract triggers from emg signals according to template
%   Detailed explanation goes here
 
    is_plot_on = true;
    %% 1. load file
    [file_path, ~] = fileparts(eeg_filename);
    S = [];
    S.output_filename = [file_path, filesep, 'temp.mat'];
    S.raweeg_filename = eeg_filename;
    
    switch lower(file_type)
        case 'egi'
            D = net_egi2spm(S);
        case 'ant'
            D = net_ant2spm(S);
        case 'bp'
            D = net_bp2spm(S);
        case 'spm'
            D = net_spm2spm(S);
        case 'eeglab'
            D = net_eeglab2spm(S);
    end
    
    %% 2. get EMG channels
    sample_num = size(D,2);
    fs = D.fsample;
    %time_axis = 0:1/sample_num:(sample_num-1)/fs;
    emg_channel_num = emg_channels(2)-emg_channels(1)+1;
    condition_num = length(experiment_info);
    
    emgs = D(emg_channels(1):emg_channels(2), :, 1);
    
    %% 3. denoise
    % 3.1 de-harmonic (notch on 50, 100, 150, 200, 250, 300, 350 Hz)
    for iter_channel = 1:1:emg_channel_num
        emgs(iter_channel, :) = net_notch_for_emg(emgs(iter_channel, :), fs);
        emgs(iter_channel, :) = net_notch_for_emg(emgs(iter_channel, :), fs);
    end
    % 3.2 de-drift, select sub-band
    band =[55, 399];
    for iter_channel = 1:1:emg_channel_num
        emgs(iter_channel, :) = net_filterdata(emgs(iter_channel,:) , fs, band(1), band(2));
    end
    
    %% 4. get filtered power course
    
    power = emgs.*emgs;
    stop_freq_1 = 2; %Hz
    stop_freq_2 = 12;
    [b1, a1]=cheby2(1, 10, stop_freq_1*2/fs, 'low');
    [b2, a2]=cheby2(1, 10, stop_freq_2*2/fs, 'low');
    for iter_channel = 1:1:emg_channel_num
        power_filted_1(iter_channel,:) = filtfilt(b1, a1, power(iter_channel,:));
        power_filted_2(iter_channel,:) = filtfilt(b2, a2, power(iter_channel,:));
    end
    
    %% 5. get emg events for each condition epoch by epoch
    events = D.events();
    events_index = 1;
    for iter_condition = 1:1:condition_num
        % 5.1 pick out emgs for this condition, get parameters of this
        % condition
        channels = experiment_info(iter_condition).emg_channels-emg_channels(1)+1;
        channels_num =length(channels);
        tmp_power_filted_1 = power_filted_1(channels, :);
        tmp_power_filted_2 = power_filted_2(channels,:);
        active_duration = experiment_info(iter_condition).active_duration;
        baseline_begining = experiment_info(iter_condition).baseline_begining;
        baseline_ending = experiment_info(iter_condition).baseline_ending;
        power2_threshold = experiment_info(iter_condition).threshold;
        
        % 5.2 get emg events for each epoch
        for iter_events = 1:1:length(events)
            if(strcmp(events(iter_events).value, experiment_info(iter_condition).epoch_start_marker))
                start_time = events(iter_events).time + experiment_info(iter_condition).block_duration(1);
                end_time = events(iter_events).time + experiment_info(iter_condition).block_duration(2);
                start_point = round(start_time * fs);
                end_point = round(end_time * fs);
               
                times = [];
                for iter_channel =1:1:channels_num
                    [tmp_time, is_event_found] = net_detect_emg_event(tmp_power_filted_1(iter_channel, start_point:end_point), tmp_power_filted_2(iter_channel, start_point:end_point),fs, baseline_begining, baseline_ending, active_duration, power2_threshold);
                    if(is_event_found)
                        times = [times; tmp_time];
                    end
                end
                if(~isempty(times))
                    time = mean(times,1) + start_time; %use mean of the two channels for now
                    emg_events(events_index).type = 'EMG_response';
                    emg_events(events_index).value = ['EMG_', experiment_info(iter_condition).internal_triggers{1}];
                    if(strcmp(experiment_info(iter_condition).events_type, 'ON'))
                        emg_events(events_index).time = time(1);
                    elseif (strcmp(experiment_info(iter_condition).events_type, 'OFF'))
                        emg_events(events_index).time = time(2);
                    end
                    events_index = events_index+1;
                end
            end
        end
    end
    %% delete temp files on hard disk
    delete ([file_path, filesep, 'temp.dat'], [file_path, filesep, 'temp.mat']);
    
    %% 6. plot for eye check
    if(is_plot_on)
        fprintf('start ploting... \n')
        power_filted_2 = power_filted_2./max(power_filted_2,[],2);
        power_filted_1 = power_filted_1./max(power_filted_1, [], 2);
        emgs = emgs./max(emgs, [], 2);
        time_axis = 0:1/fs:(sample_num-1)/fs;
        for iter_condition = 1:1:length(experiment_info)
            channels = experiment_info(iter_condition).emg_channels-emg_channels(1)+1;
            tmp_power_filted_2=power_filted_2(channels,:);
            tmp_power_filted_1 = power_filted_1(channels, :);
            tmp_emgs = emgs(channels,:);
            channels_num = size(tmp_power_filted_1, 1);
            tmp_events_time = [];
            for iter_events=1:1:length(emg_events)
                if(strcmp(emg_events(iter_events).value, ['EMG_', experiment_info(iter_condition).internal_triggers{1}]))
                    tmp_events_time = [tmp_events_time emg_events(iter_events).time];
                end
            end

            figure;
            for iter_channel = 1:1:channels_num
                subplot(channels_num,1,iter_channel)
                plot(time_axis, tmp_emgs(iter_channel,:),time_axis, tmp_power_filted_2(iter_channel,:),time_axis,tmp_power_filted_1(iter_channel,:));
                xlabel('time: second');
                ylabel('EMG signal/ filtered power of EMG');
                hold on;
                scatter(tmp_events_time, zeros(1,length(tmp_events_time)),[],'g','filled');
                hold off;
            end
            suptitle(['Detection of ', strrep(experiment_info(iter_condition).condition_name, '_', ' ')]);
        end
    end
end

