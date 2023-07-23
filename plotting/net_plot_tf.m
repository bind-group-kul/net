function [P,R,mbase,timesout,freqs,Pboot,Rboot] = net_plot_tf(Der, chan_number, freq_band, baseline)
% Inputing parameters:
%    Der: epoched and then bad trial removed SPM data
%    chan_number: the channel number to select the channel you want to plot.
%
% Example:
%       Der = spm_eeg_load('/Users/quanyingliu/Documents/EEG_motor_once_qy/reqy_motor_once_copy_avgRef_clean_ERD_DIN2.mat');
%       net_plot_tf(Der, 72, [1 30], [-2000 -1000])
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% last version: 16.01.2014

if nargin==1
    chan_number = 1;
    freq_band = [1 40];
    baseline = 0;
elseif nargin==2
    freq_band = [1 40];
    baseline = 0;
elseif nargin==3
    baseline = 0;   % take all the pre-stimulus samples as baseline
elseif nargin>4
    error('The inputing parameters are wrong'); 
    help net_plot_tf;
end


list = selectchannels(Der,'EEG');

sens = sensors(Der,'EEG');
chan_label = sens.label{chan_number};
if strcmp(sens.type,'egi128')
    sfp_file = '128.sfp';
elseif strcmp(sens.type,'egi256')
    sfp_file = '256.sfp';
end

time_Der = time(Der);
F_Der = fsample(Der);

filename = fname(Der);

    EEG = pop_fileio( [path(Der) filesep filename], 'channels', list);
    EEG.setname = filename(1:end-4);

    EEG = pop_chanedit(EEG, 'load', {sfp_file 'filetype' 'sfp'} );


figure; pop_newtimef( EEG, 1, chan_number, [time_Der(1)*F_Der  time_Der(end-1)*F_Der], [3 0.5] , 'topovec', chan_number, 'elocs', EEG.chanlocs, 'chaninfo', EEG.chaninfo, 'caption', chan_label, 'baseline', baseline, 'alpha',0.01, 'freqs', freq_band, 'plotphase', 'off', 'padratio', 1);
% figure; pop_newtimef( EEG, 1, chan_number, [time_Der(1)*F_Der  time_Der(end-1)*F_Der] , 'topovec', chan_number, 'elocs', EEG.chanlocs, 'chaninfo', EEG.chaninfo, 'caption', chan_label, 'baseline', baseline);

