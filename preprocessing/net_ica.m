function [Dn,comp] = net_ica(D, ica_parameters)
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

list_eeg    = meegchannels(Dn);
Fs          = fsample(Dn);
mean_std    = mean(std(Dn(list_eeg,:,:)'));
list_noneeg = [ecgchannels(Dn) emgchannels(Dn) eogchannels(Dn) net_artchannels(Dn)];
sigs        = Dn(list_noneeg,:,:);
std_val     = std(sigs',1);
Dn(list_noneeg,:,:) = mean_std*sigs./(std_val'*ones(1,size(sigs,2)));


ntp         = size(Dn,2);
ch_sel      = selectchannels(Dn,'EEG');
avepower    = mean(Dn(ch_sel,:,:).^2,1);
avepower_sel= avepower(avepower >= prctile(avepower,20) & avepower<=prctile(avepower,80));
samples_sel = find(avepower< mean(avepower_sel)+10*std(avepower_sel) & D.samples_process==1);
samples_sel_vect                = zeros(1,ntp);
samples_sel_vect(samples_sel)   = 1;
Dn.samples_select               = samples_sel_vect;


Dn.save;



if ntrials(Dn)~=1
    error('the trial number of D should be 1.');
    
else
    data = spm2fieldtrip(Dn);
    
    samplesize = ica_parameters.sampleSize;
    
    ntp_sel = fix(ntp*samplesize);
    
    samples_ica     = net_getrandsamples(samples_sel, ntp_sel,'homogeneous');
    data.trial{1}   = data.trial{1}(ch_sel,:);
    data.label      = data.label(ch_sel);
    
    DATA_ica = data.trial{1}(ch_sel,samples_ica);
    
    cfg         = [];
    cfg.method  = 'fastica';
    cfg.demean  = 'no';
    cfg.fastica.approach         = ica_parameters.approach;
    cfg.fastica.g                = ica_parameters.nonlinearity;
    cfg.fastica.epsilon          = ica_parameters.epsilon;
    cfg.fastica.maxNumIterations = ica_parameters.iterations;
    cfg.fastica.verbose          = 'on';
    if isfield(ica_parameters, 'numPCs')  % revised by QL, 07.02.2015, define the total number of PCs
        cfg.fastica.lastEig = ica_parameters.numPCs;   
    end
    optarg = ft_cfg2keyval(cfg.fastica);
    [mixing, unmixing] = fastica(DATA_ica, optarg{:});   % revised by QL, 25.09.2014
    
    
    comp.topo       = mixing;
    comp.unmixing   = unmixing;
    IC = unmixing*data.trial{1}(ch_sel,samples_sel);
    comp.trial{1}   = IC;
    comp.time{1}    =[1:length(samples_sel)]/Fs;
    comp.samples_sel= samples_sel;
    comp.samples_ica= samples_ica;
    comp.topolabel  = data.label;
    
    
    str = fname(Dn);
    comp.fname = [path(Dn) filesep str(1:end-4) '_ica.mat'];  % added by QL, 05.03.2015
    ica_filename = comp.fname;
    save(ica_filename,'comp');
    
    [good_ics,bad_ics,stats] = net_classify_ic(Dn, comp, ica_parameters.artifact);
    comp.good_ics = good_ics;
    comp.bad_ics = bad_ics;
    comp.stats = stats;
    
    if strcmp(ica_parameters.artifact.check,'on')||strcmp(ica_parameters.artifact.check,'yes') 
       
        comp = net_classify_ic_check(comp);
        
    end
    
    comp.time{1}  = data.time{1};
    comp.trial{1} = comp.unmixing*data.trial{1}(ch_sel,:);
    

    str = fname(Dn);
    ica_filename = [path(Dn) filesep str(1:end-4) '_ica.mat'];
    save(ica_filename,'comp');
    
end


end



