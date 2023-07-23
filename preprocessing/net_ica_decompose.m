function [comp] = net_ica_decompose(D, ica_parameters)
% Description: 1) run ICA
%                    2) classify ICs into noise(comp.bad_ics) and EEG signals(comp.good_ics)
% 
% Example:
%   options.ica_parameters.approach='defl';
%   options.ica_parameters.nonlinearity='tanh';
%   % options.ica_parameters.numPCs = 180;   % the number of components
%   options.ica_parameters.epsilon=0.001;
%   options.ica_parameters.iterations=1000;
%   options.ica_parameters.sampleSize=0.2;     % default = 0.4
%   options.ica_parameters.artifact.corr.n_std = 3;       % default = 3
%   options.ica_parameters.artifact.power.thres = 3;       % default = 3
%   options.ica_parameters.artifact.outlier.thres = 4;       % default = 4
%   % options.ica_parameters.artifact.fitting.thres = 0.7;       % default = 0.7
%   options.ica_parameters.artifact.kurtosis.thres = 10;       % default = 9
%   options.ica_parameters.artifact.check = 'yes';       % default = 'no'
%   options.ica_parameters.reconstruction = 'remove';       % the alternative is 'recombine'
%   [Dn,comp] = net_ica(D, ica_parameters);
%
% last version: 05.03.2015
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Dn = D;

list_eeg    = selectchannels(Dn,'EEG');
Fs          = fsample(Dn);
mean_std    = mean(std(Dn(list_eeg,:,:)'));
list_noneeg = [selectchannels(Dn,'ECG') selectchannels(Dn,'EMG') selectchannels(Dn,'EOG') net_artchannels(Dn)];
sigs        = Dn(list_noneeg,:,:);
std_val     = std(sigs',1);
Dn(list_noneeg,:,:) = mean_std*sigs./(std_val'*ones(1,size(sigs,2)));


ch_sel      = selectchannels(Dn,'EEG');

data = spm2fieldtrip(Dn);

cfg=[];
cfg.resamplefs  = ica_parameters.fsample; %frequency at which the data will be resampled (default = 256 Hz)
cfg.detrend     = 'no';
cfg.demean      = 'no' ;
cfg.feedback    = 'no';
cfg.trials      = 'all';

data_res=ft_resampledata(cfg,data);


ntp         = size(data_res.trial{1},2);

avepower    = mean(data_res.trial{1}.^2,1);
[~,normal]=net_tukey(log(avepower),1.5);

samplesize = ica_parameters.sampleSize;
    
ntp_sel = fix(ntp*samplesize);

samples_ica     = net_getrandsamples(normal, ntp_sel,'homogeneous');

sigs_ica = data_res.trial{1}(ch_sel,samples_ica);


[iq, mixing, unmixing, S, sR]=icasso(sigs_ica,ica_parameters.niter_icasso,'approach',ica_parameters.approach,'g',ica_parameters.nonlinearity,'maxNumIterations',ica_parameters.iterations,'vis','off');
 
comp=[];
comp.topo       = mixing;
comp.unmixing   = unmixing;
comp.trial{1}   = unmixing*data_res.trial{1}(ch_sel,samples_ica);
comp.trial_full{1} = comp.unmixing*data.trial{1}(ch_sel,:);
comp.time{1}    = samples_ica/ica_parameters.fsample;
comp.fs_ica = ica_parameters.fsample;
comp.samples_ica    = samples_ica;
comp.topolabel  = data.elec.label;
comp.chanlocs  = Dn.chanlocs;


[good_ics,bad_ics,stats] = net_classify_ic(comp,data_res.trial{1}(list_noneeg,samples_ica),ica_parameters.artifact);


comp.good_ics = good_ics;
comp.bad_ics = bad_ics;
comp.stats = stats;

if strcmp(ica_parameters.artifact.check,'on')||strcmp(ica_parameters.artifact.check,'yes')
    
    comp = net_classify_ic_check(comp);
    
end

  
   

%     str = fname(Dn);
%     ica_filename = [path(Dn) filesep str(1:end-4) '_ica.mat'];
%     save(ica_filename,'comp');
    
end





