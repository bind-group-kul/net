function [ short_time_energy_array ] = net_short_time_energy( signal_array, fs)
%NET_SHORT_TIME_ENERGY_ARRAY Summary of this function goes here
%   Detailed explanation goes here
    
    window_size_in_second = 0.1; % 100ms window
    window_sample_num = window_size_in_second * fs;
    step_num = 1; %no change on time resolution
    
    [channel_num, signal_length] = size(signal_array);
    
    pre_and_post = zeros(channel_num, window_sample_num-1);
    
    signal_array = [pre_and_post, signal_array, pre_and_post];

    short_time_energy_array = zeros(channel_num, floor(signal_length/step_num));
    
    for iter_sample = 1:step_num:ceil(signal_length/step_num)
        tmp_array = signal_array(:, iter_sample: iter_sample+window_sample_num-1);
        short_time_energy_array(: , ceil(iter_sample/step_num)) = sum(tmp_array.^2, 2);
    end

end

