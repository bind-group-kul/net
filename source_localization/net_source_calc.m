function source = net_source_calc(data,cfg)

A=cfg.grid.leadfield(cfg.grid.inside);
nchan=size(A{1},1);
G=zeros(nchan,length(A));
for i=1:length(A)
    G(:,3*(i-1)+1:3*i)=A{i};
end


%% fieldtrip
switch cfg.method
    case {'mne','lcmv','sam','rv','music','eloreta','dics'}
        
        list_eeg=[1:size(data.trial{1},1)];
        
        cfg.channel = list_eeg;
        
        cfg.elec.pnt = cfg.sens.elecpos;
        % cfg.elec.label = cfg.sens.label; % Gaia
        cfg.elec.label = upper(cfg.sens.label); % Gaia
        
        cfg.keeptrials='yes';
        cfg.feedback ='text';
        
        % Gaia
        %{
        if strcmpi(data.label,cfg.elec.label) % added by JS: same label order but different upper/lower cases
            cfg.elec.label = data.label;
        end
        %}
        
        source  = ft_sourceanalysis(cfg, data);
        
        %ndip=length(cfg.grid.leadfield);
        ntp=length(data.time{1});
   
            
            nsamples=min(1000,ntp);
            
            voxel_ind=find(source.inside==1);
            
            ImageGridAmp=zeros(3*length(voxel_ind),nsamples);
           
            
            for k=1:length(voxel_ind)
                
                tmp=source.avg.mom{voxel_ind(k)};
                ImageGridAmp(3*(k-1)+1:3*k,1:nsamples)=tmp(:,1:nsamples);
                
            end
            
            source.imagingkernel=ImageGridAmp*pinv(data.trial{1}(:,1:nsamples));
            
            if strcmp(cfg.method,'mne') && cfg.mne.deflect==1
                w=source.imagingkernel;
                for ii=1:size(w,1)
                    w(ii,:)=w(ii,:)./(w(ii,:)*G(:,ii));
                end
                source.imagingkernel=w;
            end
        
           
        
        source=rmfield(source,'avg');
            
        source=rmfield(source,'trialinfo');
            
        source=rmfield(source,'cfg');
        
        source.software='fieldtrip';
        
        source.method=cfg.method;
        
        source.cfg=cfg;
        
        
        
        
        %% brainstorm
    case {'wmne','dspm','sloreta','lcmvbf','gls_p','glsr','glsr_p','mnej','mnej_p'}%(strcmp(cfg.method,'wmne') || strcmp(cfg.method,'dspm') || strcmp(cfg.method,'sloreta'))
        
        %%% head model
        
        sigs=data.trial{1};
               
        
        HeadModel.Gain=G;
        HeadModel.GridLoc = cfg.grid.pos(cfg.grid.inside',:);
        HeadModel.GridOrient = [];
        HeadModel.SurfaceFile = '';
        HeadModel.MEGMethod = '';
        HeadModel.EEGMethod = 'eeg_volume';
        HeadModel.ECOGMethod = '';
        HeadModel.SEEGMethod = '';
        HeadModel.HeadModelType = 'volume';
        HeadModel.Comment = 'BEM_EEG';
        % % %         Harea=(cfg.grid.xgrid(2)-cfg.grid.xgrid(1))*(cfg.grid.ygrid(2)-cfg.grid.ygrid(1))*(cfg.grid.zgrid(2)-cfg.grid.zgrid(1));
        % % %         HeadModel.area=repmat(Harea,size(A,2),1);
        %%% localization
        OPTIONS=[];
        OPTIONS.SourceOrient={'free'};
        OPTIONS.flagSourceOrient = [0 0 2 0];
        OPTIONS.ChannelFlag=ones(nchan,1);
        OPTIONS.ChannelFile='';
        OPTIONS.Channel=[1:nchan]';
        OPTIONS.HeadModelFile='';
        OPTIONS.DataTime=data.time{1};
        % % % OPTIONS.NoiseCovRaw=;%%??
        % % % OPTIONS.NoiseCov=OPTIONS.NoiseCovRaw ./ nAvg; %??? %% eye(length(OPTIONS.GoodChannel));
        OPTIONS.NoiseCov=cfg.noisecov;
        OPTIONS.GoodChannel=[1:nchan]';
        OPTIONS.DataFile='';
        OPTIONS.Data=sigs;
        OPTIONS.InverseMethod=cfg.method;%% 'dspm', 'sloreta'
        OPTIONS.ResultFile='';
        OPTIONS.ComputeKernel=cfg.computekernel;
        OPTIONS.Comment='';
        OPTIONS.DisplayMessages=1;
        OPTIONS.DataTypes=repmat({'EEG'},nchan,1);
        OPTIONS.ChannelTypes=repmat({'EEG'},nchan,1);
        %         OPTIONS.depth=cfg.depth;
        
        
        
        
        switch(OPTIONS.InverseMethod)
            case 'lcmvbf'
                OPTIONS.OutputFormat=cfg.lcmvbf.OutputFormat;
                OPTIONS.BaselineSegment=cfg.lcmvbf.BaselineSegment;
                OPTIONS.isConstrained=0;
                OPTIONS.Tikhonov=cfg.lcmvbf.Tikhonov;
                OPTIONS.DataBaseline=cfg.lcmvbf.DataBaseline;
                switch OPTIONS.OutputFormat
                    case 0,  strMethod = '_LCMV_KERNEL'; % Filter Output
                    case 1,  strMethod = '_LCMV';        % Neural Index
                    case 2,  strMethod = '_LCMV_KERNEL'; % Normalized Filter Output
                    case 3,  strMethod = '_LCMV';        % Source Power
                end
            case 'wmne',    strMethod = '_wMNE';
                OPTIONS.weightlimit=cfg.wmne.weightlimit;
                OPTIONS.SNR=cfg.wmne.snr;
                
                
            case 'gls',     strMethod = '_GLS';
            case 'gls_p',   strMethod = '_GLSP';
            case 'glsr',    strMethod = '_GLSR';
            case 'glsr_p',  strMethod = '_GLSRP';
            case 'mnej',    strMethod = '_MNEJ';
            case 'mnej_p',  strMethod = '_MNEJP';
            case 'dspm',    strMethod = '_dSPM';
            case 'sloreta', strMethod = '_sLORETA';
                OPTIONS.depth = cfg.sloreta.depth;
                OPTIONS.SNR = cfg.sloreta.snr;
            case 'mem',     strMethod = '_MEM';
        end
        
        switch( OPTIONS.InverseMethod )
            case 'lcmvbf'
                if ~isempty(OPTIONS.BaselineSegment)
                    % Get baseline
                    BaselineInd = bst_closest([OPTIONS.BaselineSegment(1) OPTIONS.BaselineSegment(2)], DataMat.Time'); %get the indices for start and stop points
                    OPTIONS.BaselineSegment = [DataMat.Time(BaselineInd(1)), DataMat.Time(BaselineInd(end))]; % Time segment (min max only, in sec)
                    iTimeNoise = BaselineInd(1):BaselineInd(end); % Full Baseline segment
                    if length(iTimeNoise)<3
                        error('Baseline region does not have enough time slices. Select a different noise region');
                    end
                    % Get data on the baseline
                    OPTIONS.DataBaseline = DataMat.F(OPTIONS.GoodChannel, iTimeNoise);
                end
                clear DataMat;
                
                % Apply constrains
                if OPTIONS.isConstrained
                    HeadModel.Gain = bst_gain_orient(HeadModel.Gain, HeadModel.GridOrient);
                end
                % Beamformer estimation
                [Results, OPTIONS] = bst_lcmvbf(HeadModel.Gain, OPTIONS);
                
            case {'wmne', 'dspm', 'sloreta'}
                
                % NoiseCov: keep only the good channels
                if isfield(OPTIONS, 'NoiseCov')
                    OPTIONS.NoiseCov = OPTIONS.NoiseCov(OPTIONS.GoodChannel, OPTIONS.GoodChannel);
                else
                    OPTIONS.NoiseCov = eye(length(OPTIONS.GoodChannel));
                end
                OPTIONS.eegreg = 0;
                [Results, OPTIONS, HeadModel] = bst_wmne(HeadModel, OPTIONS);
                
            case {'gls', 'gls_p', 'glsr', 'glsr_p', 'mnej', 'mnej_p'}
                % NoiseCov: keep only the good channels
                if isfield(OPTIONS, 'NoiseCov')
                    OPTIONS.NoiseCov = OPTIONS.NoiseCov(OPTIONS.GoodChannel, OPTIONS.GoodChannel);
                else
                    OPTIONS.NoiseCov = eye(length(OPTIONS.GoodChannel));
                end
                % Get channels types
                OPTIONS.ChannelTypes = {OPTIONS.Channel(OPTIONS.GoodChannel).Type};
                % Mosher's function
                [Results, OPTIONS] = bst_wmne_mosher(HeadModel, OPTIONS);
                
            case 'mem'
                % NoiseCov: keep only the good channels
                if isfield(OPTIONS, 'NoiseCov')
                    OPTIONS.NoiseCov = OPTIONS.NoiseCov(OPTIONS.GoodChannel, OPTIONS.GoodChannel);
                else
                    OPTIONS.NoiseCov = eye(length(OPTIONS.GoodChannel));
                end
                % Get channels types
                OPTIONS.ChannelTypes = {OPTIONS.Channel(OPTIONS.GoodChannel).Type};
                % Call the mem solver
                [Results, OPTIONS] = be_main(HeadModel, OPTIONS);
                
            otherwise
                error('Unknown method');
        end
        
         
        source.dim     = cfg.grid.dim;
        source.time    = data.time{1};
        source.pos     = cfg.grid.pos;
        source.inside  = cfg.grid.inside;
        source.outside = cfg.grid.outside;
        
         
            
            source.imagingkernel=Results.ImagingKernel;
            
            if strcmp(cfg.method,'wmne') && cfg.wmne.deflect==1
                w=source.imagingkernel;
                for ii=1:size(w,1)
                    w(ii,:)=w(ii,:)./(w(ii,:)*G(:,ii));
                end
                source.imagingkernel=w;
            end
            
        
        source.software='brainstorm';
        
        source.method=cfg.method;
        
        source.cfg=OPTIONS;
        
    otherwise
        error('Unknown method');
        
end

