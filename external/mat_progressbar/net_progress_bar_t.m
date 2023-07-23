function [ previous_text_len ] = net_progress_bar_t(varargin)
%CMD_PROGRESS_BAR Summary of this function goes here
%   Detailed explanation goes here
    

    %marker = '¡ö';
    marker = '#';
    %% dealwith input arguments
    if(nargin == 5)
        front_text = varargin{1};
        current_index = varargin{2};
        max_index = varargin{3};
        t  = varargin{4};
        previous_text_len  = varargin{5};
        write_text_file = 0;
        
    elseif(nargin == 6)
        front_text = varargin{1};
        current_index = varargin{2};
        max_index = varargin{3};
        t  = varargin{4};
        previous_text_len  = varargin{5};
        fid = varargin{6};
        write_text_file = 1;
    else
    end

    %% remaining time this
    remain_t = t*(max_index - current_index);
	remain_t_h = floor(remain_t/3600);
    remain_t_m = floor((remain_t - remain_t_h*3600)/60);
    remain_t_s = round(remain_t - remain_t_h*3600 - remain_t_m*60);
    remain_t_str = [' [Eta: ',num2str(remain_t_h), 'h ', num2str(remain_t_m), 'min ', num2str(remain_t_s), 's]'];
    

    %% this index info
    index_str = [' [Loop: ', num2str(current_index), '/', num2str(max_index), ']'];
    
    %% percentage
    percent_done = 100 * current_index / max_index;
    perc_str = num2str(percent_done,'%3.1f');

    %% prepare bar str
    total_bar_num = 20;
    prc_step = 100/total_bar_num;
    
    dot_num = round(percent_done./prc_step);
    bar_str = ['[', repmat(marker, 1, dot_num), repmat(' ', 1, total_bar_num-dot_num), ']'];
    total_str = [front_text, ': ', bar_str, perc_str, '%%',index_str, remain_t_str];
    if(current_index == 1)
        s = total_str ;
                
    elseif(current_index > 1 && current_index < max_index)
        backspace_matrix = repmat(sprintf('\b'), 1, previous_text_len);
        s =[backspace_matrix, total_str]; 
        
    elseif(current_index == max_index)
        backspace_matrix = repmat(sprintf('\b'), 1, previous_text_len);
     	s = [backspace_matrix(1:end), total_str, '\n'];
    end
    
    previous_text_len = length(sprintf(total_str));
    %% plot bar
    fprintf(s);
    if(write_text_file)
        fprintf(fid, s);
    end
    
end

