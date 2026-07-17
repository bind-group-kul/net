function net_statistical_analysis(pathx,options_stats,nsubjs)

if not(isnan(options_stats.subjects)) % JS, 08.2023 - included several options
    if strcmpi(options_stats.subjects,'all')        % all subjs
        options_stats.subjects = 1:nsubjs;
        fprintf('\nAll datasets included in the statistical analyses.')
    elseif strcmpi(options_stats.subjects,'none')   % no subjs
        fprintf('\nNo statistical analyses to run.')
        return
    else                                            % some subjs
        if ~isempty(strfind(options_stats.subjects,'[')) && ~isempty(strfind(options_stats.subjects,']'))   % [first_sbj last_sbj]
            tmp = strsplit(options_stats.subjects,'[');
            subj = [];
            for i = 1:numel(tmp)
                if contains(tmp(i),']')
                    clear tmp2
                    tmp2 = strsplit(tmp{i},']');
                    for j = 1:numel(tmp2)
                        if length(tmp2{j})>=1 && ~strcmp(tmp2{j},' ')
                            clear tmp3
                            tmp3 = strsplit(tmp2{j}, ' ');
                            if length(tmp3)==2
                                subj = [subj, str2num(tmp3{1}):str2num(tmp3{2})];
                            elseif length(tmp3) == 1
                                subj = [subj, str2num(tmp3{1})];
                            end
                        end
                    end
                end
            end
            options_stats.subjects = subj;
            
            if subj(end)> nsubjs
                error('Number of datasets included in the statistic analysis higher than the available datasets.')
            end
        end
    
    end   
    if nsubjs>=2 && numel(options_stats.subjects) >=2
        fprintf('\n*** STATISTICAL ANALYSIS: START... ***\n')
        net_group_analysis(pathx,options_stats);
    else
        fprintf('At least 2 SUBJECTS NEEDED to perform statistical analyses!')
    end
else
    fprintf('No statistical analyses to run.')
end
end