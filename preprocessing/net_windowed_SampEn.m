function [ min_wSampEns, mean_wSampEns ] = net_windowed_SampEn(ICs, Fs, window_in_s, overlap, Fs_new)
%SAMPLE_ENTROPY_WINDOWED Summary of this function goes here
%   Detailed explanation goes here
    
    %% init 
    m = 2;
    r = 0.4;
    
    [ic_num, ~] = size(ICs);
    min_wSampEns = nan(1, ic_num);
    mean_wSampEns = nan(1, ic_num);

    %% calcualte
    bar_len = 0;
    for iter_ic = 1:ic_num
        tic;
        %% down sampling if needed
        tmp_ic = ICs(iter_ic, :);
        if(Fs ~= Fs_new)
            tmp_ic = resample(double(tmp_ic), Fs_new, Fs);
            Fs_final = Fs_new;
        else
            Fs_final = Fs;
        end
        
        window_len = window_in_s*Fs_final;
        step_size = round(window_len*(1-overlap));
        samp_num_new = length(tmp_ic);
        %window_num = floor(samp_num_new/(window_len-step_size))-1;
        %index = 1;
        tmp_wSampEn = [];
        if(window_len >= samp_num_new)
            tmp_wSampEn = sampen(tmp_ic, m, r, 'chebychev');
        else
            w_start = 1;
            w_stop = window_len;
            while w_stop <= samp_num_new
                
                % calculate
                tmp_ic_w = tmp_ic(w_start:w_stop);
                tmp_wSampEn = [tmp_wSampEn, sampen(tmp_ic_w, m, r, 'chebychev')];
                
                % update sliding window
                w_start = w_start + step_size;
                w_stop = w_stop + step_size;
                
%                 % info
%                 net_progress_bar('Calculating for IC', index, window_num);
%                 index = index + 1;
            end
        end
        %% save data
        min_wSampEns(iter_ic) = min(tmp_wSampEn);
        mean_wSampEns(iter_ic) = mean(tmp_wSampEn);
        t=toc;
        bar_len = net_progress_bar_t(['Calculating sample entropy for ', ic_num,' ICs'], iter_ic, ic_num, t, bar_len);
    end
end

