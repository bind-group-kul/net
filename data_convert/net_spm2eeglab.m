function EEG = net_spm2eeglab( spm_file, electrode_filename )
% function: EEG = net_spm2eeglab( spm_file, electrode_filename )
% description: convert spm file or data to eeglab
% last version: 18.10.2015

% spm_file = '/Users/quanyingliu/Documents/NET/template/EGI dataset/repre_dspm8_Josh motor task 20131016 1601.mat';
% electrode_filename = '/Users/quanyingliu/Documents/NET/template/EGI dataset/josh 16.10.sfp';

if nargin==1
    electrode_filename = '256.sfp';
elseif nargin>3
    error('too much parameters!');
    help net_spm2eeglab;
end    

if strcmp(spm_file(end-3:end), '.mat')  % if the inputing parameter is a filename
    EEG = pop_fileio(spm_file);
    EEG.setname = 'epoch-eeg';
    EEG = pop_chanedit(EEG, 'lookup', electrode_filename);
    EEG.data = double( EEG.data );
end

% change the wrong EEG.event and epoch
if ~isempty(EEG.epoch)
    % 
end    

end

