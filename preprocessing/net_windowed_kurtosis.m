function [w_kurtosis] = net_windowed_kurtosis(ICs, Fs, window_in_s, overlap, type)
    
    [ic_num, samp_num] = size(ICs);
    window_len = window_in_s*Fs;
    step_size = round(window_len*(1-overlap));
    
    w_kurtosis = nan(1, ic_num);
    for iter_ic = 1:ic_num
        
        %% calculate for each window
        tmp_ic = ICs(iter_ic, :);
        
        tmp_w_kurt = [];
        if(window_len >= samp_num)
            tmp_w_kurt = kurt(tmp_ic');
        else
            w_start = 1;
            w_stop = window_len;
            while w_stop <= samp_num
                tmp_ic_w = tmp_ic(w_start:w_stop);
                tmp_w_kurt = [tmp_w_kurt, kurt(tmp_ic_w')];
                
                % update sliding window
                w_start = w_start + step_size;
                w_stop = w_stop + step_size; 
            end   
        end
        
        %% save data
        if(strcmp(type, 'max'))
            w_kurtosis(iter_ic) = max(tmp_w_kurt);
        elseif(strcmp(type, 'mean'))
            w_kurtosis(iter_ic) = mean(tmp_w_kurt);
        else
            error('Wrong choice of type, it should be max or mean!');
        end
     
    end 
end