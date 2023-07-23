

%% Start afresh by clearing all command windows and variables
% clc;clear;warning off

clear D*

%% Set the file from where the input is taken and where the output of the preprocessing is stored


spm_filename = '/Users/quanyingliu/Documents/EEG_sti/dante/spm_dante_left_prepro_clean_avgRef.mat';

options.filtering.highpass = 1.6;
options.filtering.lowpass = 70;  % 1.6-70
options.erp.trigger.value{1} = 'DIN4';  % 'DI50', 'DI75', D100
% options.erp.trigger.value{2} = 'DI22';  % 'DI50', 'DI75', D100
% options.erp.trigger.value{3} = 'DI23';  % 'DI50', 'DI75', D100
% options.erp.trigger.value{4} = 'DI24';  % 'DI50', 'DI75', D100
% options.erp.trigger.value{5} = 'DI25';  % 'DI50', 'DI75', D100
% options.erp.trigger.value{6} = 'DI26';  % 'DI50', 'DI75', D100
options.erp.trigger.type = 'DIN_1';  % 'DI50', 'DI75', D100
% options.erp.trigger.label = 'left';
options.erp.pretrig = -40;
options.erp.posttrig = 160;
options.erp.bc.value=1;
options.erp.bc.time=[-40 -20];  % reference time from -20ms to -10ms

options.artifact.prctile_sel= 3; % default settings? S.artifact_amplitude = 3
options.artifact.nstd = 3; % default settings? S.artifact_amplitude = 3
options.artifact.false_event = 0.5;     % if the false event is bigger than S.false_event*event_number , it is a bad channel. S.false_event = 0.2;  0.5
options.artifact.false_channel = 0.05;  % if the false channel in one event is bigger than S.false_channel*channel_number , it is a bad event; S.false_channel = 0.02; 



%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. load SPM data into fieldtrip format 
% 2. filtering(0.5-40Hz) and detrending
%%%%%%%%%%%%%%%%%%%%%%%%%%


D=spm_eeg_load(spm_filename);
% D = net_timedelay_correct(D, 36);
dname=fname(D);
S = [];
S.D = D;
% S.newname = [path(D) filesep dname(1:end-4) '_ERP_' options.erp.trigger.label '.mat'];
S.newname = [path(D) filesep dname(1:end-4) '_ERP.mat'];
D = spm_eeg_copy(S);




D = net_filtering(D, options.filtering);


%%%%%%%%%%%%%%%%%%%%%%
% 6. cut the data into different trials by different EVENTs
%    Then detect the bad event and bad channel for every trial
% 17.10.2013
%%%%%%%%%%%%%%%%%%%%%%
disp(['Now epoching EEG data.']);



% epoch
% ------------------------------------------------------
De = net_epoch(D, options.erp);     



% find bad trials and repair
% ------------------------------------------------------
Der = net_badtrial_analysis(De,options.artifact);  % revised by QY, 01.04.2014


% average all good trials
% ------------------------------------------------------
S=[];
% S.D=De;
S.D=Der;
S.robust = false;
S.plv = false;
S.review = 0;
Derm = spm_eeg_average(S);

% sens = sensors(Derm,'EEG');
% figure; 
% ft_plot_topo3d(sens.chanpos, Derm(1:256,96,1)', 'contourstyle', 'black'); 

elecs = readlocs('256.sfp');
% figure; subplot(1,3,1); topoplot(Derm(1:256,60,1)', elecs); title( 'N20' );
% subplot(1,3,2); topoplot(Derm(1:256,85,1)', elecs); title( 'P45' );
% subplot(1,3,3); topoplot(Derm(1:256,160,1)', elecs); title( 'N120' );
figure; 
for i=1:16
subplot(4,4,i); topoplot(Derm(1:256, 40+10*(i-1), 1)', elecs); title( [num2str(10*(i-1)) ' ms']);
end

figure;
plot([-40:1:160], Derm(1:256,:,1)); grid on;

delete(D);
delete(De);
clear D De
