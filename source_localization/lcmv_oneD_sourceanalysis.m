function source = lcmv_oneD_sourceanalysis(data,cfg)



%% fieldtrip
switch cfg.method
    case {'mne','lcmv','sam','rv','music'}
        
        cfg.channel = [1:size(data.trial{1},1)];
        
        cfg.elec.pnt = cfg.sens.elecpos;
        cfg.elec.label = cfg.sens.label;
        
        cfg.keeptrials='yes';
        cfg.feedback ='text';
        
        
        source  = ft_sourceanalysis(cfg, data);
        imk=source.avg.filter(source.inside);
        source.imagingkernel=cell2mat(imk);
        
        source.software='fieldtrip';
        
        source.method=cfg.method;
        
        source.cfg=cfg;
        
end

