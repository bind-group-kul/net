function [ trigger_time, is_event_found ] = net_detect_emg_event( data_filted_1, data_filted_2, fs, baseline_begining, baseline_ending, active_duration, power2_threshold )
%NET_DETECT_EMG_EVENT Summary of this function goes here
%   Detailed explanation goes here   

    if(size(data_filted_1,1) ~= 1)
        error('net_detect_emg_event: input epoch should be a 1 by N vector!');
    end
    is_event_found = false;
    sample_num = length(data_filted_1);
    
    %% 1. get thresholds
    baseline_1_points = round(fs*baseline_begining);
    baseline_2_points = round(fs*baseline_ending);
    starting_low_threshold = 3.8*max(data_filted_1(baseline_1_points(1):baseline_1_points(2)),[],2);
    ending_low_threshold = 3.8*max(data_filted_1(baseline_2_points(1):baseline_2_points(2)),[],2);
    high_threshold = max([starting_low_threshold,ending_low_threshold]); %%can choose 3 - 10, test to choose for different subject
    
    %% 2. binarise according to high_threshold
    binarized_epoch = zeros(1, sample_num);
    binarized_epoch(data_filted_1 > high_threshold) = 1;
    
    %% 3. smooth according to active block duration, fill the small gaps
    % 3.1 get rise edges and fall edges of binarized_epoch
    diff_epoch = [binarized_epoch, 0] - [0, binarized_epoch]; 
    rise_index = find(diff_epoch == 1);
    fall_index = find(diff_epoch == -1); 
    % 3.2 pre-check according rise and fall edges
    rise_num = length(rise_index);
    fall_num = length(fall_index);
    if(rise_num ~= fall_num || rise_num == 0)
        trigger_time =[];
        return;  % epoch is not good, no event can be detected
    end
    % 3.3 one or more gaps exist, fill small gaps according to active_duration
    if(rise_num > 1) 
        window_length = round(0.4*active_duration*fs);
        gap_index = [fall_index(1:end-1); rise_index(2:end)];
        gap_length = gap_index(2,:) - gap_index(1,:);
        fill_index = find(gap_length <= window_length); % find the gaps that shorter than 40% of active_duration
        for iter_gap = fill_index %fill
            gap_start = gap_index(1, iter_gap);
            gap_end = gap_index(2, iter_gap);
            binarized_epoch(gap_start:gap_end) = 1;
        end    
    end
    
    %% 4. smooth according to active block duration, remove small pulse
    % 4.1 get rise edges and fall edges
    diff_epoch = [binarized_epoch, 0] - [0, binarized_epoch]; 
    rise_index = find(diff_epoch == 1);
    fall_index = find(diff_epoch == -1);
    pulse_index = [rise_index; fall_index];
    pulse_length = pulse_index(2,:) -pulse_index(1,:);
    window_length = round(0.6*active_duration*fs);
    remove_index = find(pulse_length <= window_length);
    if( ~isempty(remove_index)) %remove
        for iter_pulse = remove_index
            pulse_start = pulse_index(1, iter_pulse);
            pulse_end = pulse_index(2, iter_pulse);
            binarized_epoch(pulse_start:pulse_end) = 0;
        end
    end
    
    %% 5. find precise starting point and ending point
    diff_epoch = [binarized_epoch, 0] - [0, binarized_epoch]; 
    rise_index = find(diff_epoch == 1);
    fall_index = find(diff_epoch == -1);
    rise_num = length(rise_index);
    fall_num = length(fall_index);
    if (rise_num ==1 && fall_num ==1) % as settings of the experiment, each epoch should only contain 1 rise and 1 fall
        is_event_found = true;
    else                              % too many edge, this epoch cannot be used
        trigger_time =[];
        return;
    end
    if(is_event_found)
        % 5.1 find power peaks
        [~, locs] = findpeaks(data_filted_1(rise_index:fall_index));
        locs = (locs - 1) + (rise_index - 1);
        loc_first_peak = locs(1);
        loc_last_peak = locs(end);
        % 5.2 start point is 70% power point of first power peak;
        for iter_sample = locs(1):-1:2
            if(data_filted_2(iter_sample) <= data_filted_2(loc_first_peak)*power2_threshold)
                on_index = iter_sample;
                break;
            end
        end
        % 5.3 end point is half power point of last power peak
        for iter_sample = locs(end):1:sample_num
            if(data_filted_2(iter_sample) <= data_filted_2(loc_last_peak)*power2_threshold)
                off_index = iter_sample;
                break;
            end
        end
    end
    
    %% 6. return value
    % 6.1 get rise edges and fall edges
    if(is_event_found)
        trigger_time(1,1) = on_index/fs;
        trigger_time(1,2) = off_index/fs;
    end
    
end

