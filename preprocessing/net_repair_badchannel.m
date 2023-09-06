%% Purpose
% 1. Detect the bad channels based on the correlation coefficient and median gradient of the signal.
%%
function net_repair_badchannel(processedeeg_filename, options)
% detect bad channels by correlation coefficient and/or median gradient of the signal
% the default range = [0.2 0.8], the default 'corrcoef' and 'gradient' is
% 'on'
%
% e.g. D = net_detect_badchannel_multvar(D, [0.25 0.75], options);
% with options.corrcoef='on'; options.gradient='off';
% last version: 03.06.2014

if strcmp(options.enable, 'on')

[ddx,ffx,ext]=fileparts(fileparts(processedeeg_filename));
    
    
D=spm_eeg_load(processedeeg_filename);


if nargin==1

    n_range=4;
else
    %range=options.range;
    n_range=options.n_range;
    
end

list_chan = selectchannels(D,'EEG'); %Collect the EEG channels

%initial filtering
EEG = pop_fileio([path(D) filesep fname(D)]);
EEG = net_unripple_filter(EEG, 1, 80, 6600);  % 6600, revised by QL, 29.07.2015

data = double(EEG.data(list_chan,:,1));

data=1000*data/max(data(:)); %Normalize the data

CR = corrcoef(data');
%CR = corrcoef(abs(data'));
%CR = corrcoef(abs(hilbert(data')));

vt = max(abs(CR-eye(size(CR))));

list_bch = net_tukey(vt,n_range,'low');

hp=round(min(EEG.srate/2.5,200));
lp=round(min(EEG.srate/2.1,250));
nsamples=6600;

EEG = pop_fileio([path(D) filesep fname(D)]);
EEG = net_unripple_filter(EEG,hp,lp,nsamples);


%list_eeg = selectchannels(D,'EEG');
data = double(EEG.data(list_chan,:,1));
%data = data-ones(length(list_chan),1)*mean(data,1);
%noisecov_matrix = diag(diag(cov(bsxfun(@minus, data', mean(data',1)))));

%xt=diag(noisecov_matrix)';

xt=std(data,[],2)';


list_bch2 = [net_tukey(xt,n_range,'high') find(xt==0)]; 

disp('Bad channel detection completed!');



bad_list = badchannels(D);
manual_bad_channels = str2num(options.badchannels); % add by MZ 20 June,  2018
badchanind=unique([list_bch list_bch2 bad_list manual_bad_channels]);% add by MZ 20 June,  2018


%D = badchannels(D, [], 0);
D = badchannels(D, badchanind, 1);


D.save;


filename = fname(D);
badchannel_filename = [path(D) filesep filename(1:end-4) '_badchannel.mat'];  % file name for bad channel..
save(badchannel_filename,'badchanind');


if isempty(D.badchannels)
    disp('No bad channels!');
    
else
    
    disp('Bad channels were detected: loading results')
    fprintf('-->Channels %d \n',D.badchannels);
    
    
    list_bch_tot = D.badchannels;
    % mark: change it in the future for more flexibility.
    sens = sensors(D,'EEG');
    for i=1:length(sens.label)
        sens.label{i}=upper(sens.label{i});
    end
    
    data = spm2fieldtrip(D); %Convert data to field trip format for repair
    
    
    for i=1:length(data.label)
        data.label{i}=upper(data.label{i});
    end
    
    for i = 1:ntrials(D)   % Data conversion for multi-epoch data
        data.trial{i} = double( data.trial{i} );
    end
    
    cfg=[];
    cfg.elec.elecpos=sens.elecpos;
    cfg.elec.chanpos=sens.elecpos;
    cfg.elec.label=sens.label;
    lay = ft_prepare_layout(cfg, data); %prepare the layout acc. to elec. positions.
    
    % call ft_prepare_neighbours(cfg,data)
    cfg = [];
    cfg.method = 'triangulation';
    cfg.layout =  lay;
    cfg.channel  = sens.label;
    cfg.feedback = 'no';
    neighbours = ft_prepare_neighbours(cfg, data); %find out the neighbours acc. to elec. positions.
    
    % call ft_channelrepair(cfg, data);
    cfg = [];
    cfg.method = 'nearest';
    cfg.badchannel  = data.label(list_bch_tot); %mark the bad channels.
    cfg.missingchannel = [];
    cfg.elec.pnt = sens.elecpos;
    cfg.elec.label = sens.label;
    cfg.neighbours = neighbours;
    cfg.trials = 'all';
    [interp] = ft_channelrepair(cfg, data); %repair the bad channels
    
    for i=1:ntrials(D)  % for multi-epoch data
        data_all = interp.trial{i};
        D(:,:,i) = data_all;
    end
    
    
   % D = badchannels(D, [], 0);
    
    D = badchannels(D, badchanind, 0);    % added by QY, 28.10.2013, to reset the badchannels.
        
    D.save;
    
    
end




EEG = pop_fileio([path(D) filesep fname(D)]);

EEG=net_unripple_filter(EEG,hp,lp,nsamples);

sigs = double(EEG.data(list_chan,:,1))';
noisecov_matrix = diag(diag(cov(bsxfun(@minus, sigs, mean(sigs)))));


D.noisecov_matrix = noisecov_matrix;

D.save;



end

