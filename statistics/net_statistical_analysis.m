function net_statistical_analysis(pathx,options_stats,nsubjs)

if not(isnan(options_stats.subjects)) % JS, 08.2023 - included several options
    if strfind(options_stats.subjects,' ')
        error('Please remove all the spaces from the field statistical_analysis/stats.subj. Use commas to list datasets or the notation "first_dataset:last_dataset".')
    end
    if strcmpi(options_stats.subjects,'all')        % all subjs
        options_stats.subjects = 1:nsubjs;
    elseif strcmpi(options_stats.subjects,'none')   % no subjs
        fprintf('\nNo statistical analyses to run.')
        return
    else                                            % some subjs
        if ~isempty(strfind(options_stats.subjects,':'))    % first_sbj:last_sbj
            tmp = strsplit(options_stats.subjects,':');
            options_stats.subjects = str2num(tmp{1}):str2num(tmp{2});
            if str2num(tmp{2})>nsubjs
                error('Number of datasets included in the statistic analysis higher than the available datasets.')
            end
        elseif ~isempty(strfind(options_stats.subjects,',')) % sbj1,sbj2,...
            tmp = strsplit(options_stats.subjects,','); dt = [];
            for i = 1:length(tmp), dt = [dt, str2num(tmp{i})]; end
            options_stats.subjects = sort(dt);
            if options_stats.subjects(end)>nsubjs
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