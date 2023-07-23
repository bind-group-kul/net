function net_plot_3d(D, time_ms)
% D is mean epoched SPM Data
% time is in ms
%
% Example:
%   D = spm_eeg_load('/Users/quanyingliu/Documents/EEG_demo/mrespm_koen_oddball_1_copy_masRef_clean_ERP_DI50DI75.mat');
%   net_plot_3d(D, 400);
%
% last version: 20.01.2014

if nargin ==1
    time_ms = 300;
elseif nargin>2
    error('Too many inputing parameters');
end

Ncondition = nconditions(D);

if Ncondition~=size(D,3)
    error('The inputing data must be mean epoched SPM Data.');
    help net_plot_3d
end

chanind = strmatch('EEG', D.chantype);


Time = time(D);
sample_n = find( Time>time_ms/1000-0.001 & Time<time_ms/1000+0.001 );

sample_n = sample_n(1);


for i=1:Ncondition
    
    data = D(chanind, sample_n, i);
    try
        vol = D.inv{1}.forward(1).vol;
        sens = D.inv{1}.datareg(1).sensors;
        figure('Name', ['3D plot of amplitude in ' num2str(time_ms) ' ms for trigger ' num2str(i)]);
        ft_plot_vol(vol, 'facecolor', 'cortex', 'edgecolor', 'none');alpha 0.5; camlight;
        hold on; ft_plot_sens(sens,'style', 'k.');
        ft_plot_topo3d(sens.chanpos, data, 'contourstyle', 'black'); caxis([-40 40]); 
    catch
        sens = sensors(D, 'EEG');
        figure('Name', ['3D plot of amplitude in ' num2str(time_ms) ' ms for trigger ' num2str(i)]);
        ft_plot_topo3d(sens.chanpos, data, 'contourstyle', 'black'); caxis([-40 40]); 
    end
    
end

