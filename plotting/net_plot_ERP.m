function net_plot_ERP(Der, Eventtype, plot_time)
% Inputing parameters:
%    Der: epoched and then bad trial removed SPM data
%    chan_number: the channel number to select the channel you want to plot.
%
% Example:
%       Der = spm_eeg_load('/Users/quanyingliu/Documents/EEG_demo/respm_koen_oddball_copy_avgRef_clean_ERP_DI50DI75');
%       net_plot_ERP(Der, 'DI75', 500);
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% last version: 17.01.2014

if nargin<2
    error('Please specify the eventtype'); help net_plot_ERP;
elseif nargin<3
    plot_time = 0;
elseif nargin>4
    error('So many inputing parameters!'); help net_plot_ERP;
end


list = selectchannels(Der,'EEG');

sens = sensors(Der,'EEG');
if strcmp(sens.type,'egi128')
    sfp_file = '128.sfp';
elseif strcmp(sens.type,'egi256')
    sfp_file = '256.sfp';
end


time_Der = time(Der);

filename = fname(Der);

EEG = pop_fileio( [path(Der) filesep filename], 'channels', list);
EEG.setname = filename(1:end-4);

EEG = pop_chanedit(EEG, 'load', {sfp_file 'filetype' 'sfp'} );
EEG = pop_saveset( EEG, 'filename', ['eeglab_' EEG.setname '.set'], 'filepath', [path(Der) filesep]);


event_num = size(EEG.epoch,2);
flag = 0;
for i = 1:event_num
    if strcmp( EEG.epoch(i).eventtype(1), Eventtype )  % select the event you want
        flag = flag+1;
        epoch_new( flag ) = EEG.epoch( i );
        data_new( :, :, flag ) = EEG.data( :, :, i );
    end
end
EEG.data = data_new;
EEG.epoch = epoch_new;
EEG.trials = flag;


figure; pop_timtopo(EEG, [time_Der(1)*1000  time_Der(end-1)*1000], [plot_time], ['ERP data and scalp maps of' filename]);

pop_topoplot(EEG,1, [0: 25: time_Der(end-1)*1000-1] ,['2D scalp maps of' filename], [5 6] ,0,'electrodes','off');
