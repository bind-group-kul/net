function [  ] = convert2edf_main(varargin)
%CONVERT2EDF_MAIN Convert a experimental root folder, or a SPM MEEG object to
%EDF file. The converted EDF files will be saved at the same location with
%the same name to original SPM mat files
%   

    if(nargin == 0)
        % manual select
        [filename, pathname, filterindex] = uigetfile({'*.mat','MAT-file (*.spm)'}, 'Pick a file', 'MultiSelect', 'on');
        if(iscell(filename))
            file_num = length(filename);
            for iter_f = 1:file_num
                file_list{iter_f} = [pathname, filename{iter_f}];
            end
        else
            if(ischar(filename))
                file_list = {[pathname, filename]};
            end
        end
        
    elseif(nargin == 1)
        file_list = varargin{1};
        if(ischar(filelist))
            file_list{1} = file_list;
        end    
    end
    
    file_num = length(file_list);
    for iter_convert = 1:file_num
        spm_file = file_list{1};
        if(ischar(spm_file))
            if(strcmp(spm_file(end-3:end), '.mat'))
                net_spm2edf(spm_file);
                disp(['1 SPM file converted: ', spm_file]);
            end
        end    
    end
end

