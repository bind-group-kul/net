function net_plot_ERD(D, pretrig,  posttrig)
% plot ERD by eeglab toolbox
% notice: D is the spm format



fname=fnamedat(D);
Fsample = fsample(D);
EEG = pop_fileio([path(D) filesep fname(1:end-4) '.mat']);  % eeglab funtion to read SPM file
EEG.data = double( EEG.data );
sens = sensors(D,'EEG');
EEG=pop_chanedit(EEG, sens);

EEG.setname = [fname(1:end-4)];
% EEG = eeg_checkset( EEG );

channel_see = 10;

% the frequency figure 
figure; pop_spectopo(EEG, channel_see, [pretrig  posttrig], 'EEG' , 'percent', 15, 'freq', [6 10 13], 'freqrange',[1 80],'electrodes','off');

% the time figure of averaged epoches
figure; pop_timtopo(EEG, [pretrig  posttrig], [NaN], 'ERP data and scalp maps');

% 
pop_topoplot(EEG,channel_see, [pretrig:Fsample:posttrig] ,EEG.setname,0,'electrodes','off');

figure; pop_erpimage(EEG,1, [channel_see],[[]],sens(channel_see).label,10,1,{ 'left'},[],'value' ,'yerplabel','\muV','erp','on','cbar','on','topo', { [channel_see] EEG.chanlocs EEG.chaninfo } );
