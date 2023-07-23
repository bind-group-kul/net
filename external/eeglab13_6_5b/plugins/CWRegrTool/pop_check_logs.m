function [ EEGOUT, command ] = pop_check_logs( EEG, varargin)

command='';
EEGOUT = EEG;



logs = EEG.cwregression.cfg.cwregression.logging;



check_logs_ui(EEG, logs);

% so make here a nice diagnostical GUI that allows you to make figures
% for checking weights, variance explained, etc etc... that you can track
% for each window.



% so for 1 channel, and for 1 regressor... make an imagesc of the beta
% parameter estimates!


collect = [];
channel = 25;
for i_reg=1:numel([33 34 35 36 37 38 39 40]);
    for i=1:numel(logs)
        collect(:,i,i_reg) = [logs{i}.bparams{channel,i_reg}]';
        
    end
end



% now... make a figure -- of beta parameters (which is something like a TRF
% for the CW loops)
figure;
for i_reg=1:8
    
    % figure;
    ah = subplot(3,3,i_reg);
    ih = imagesc(collect(:,:,i_reg));
    title(['cw ' num2str(i_reg)]);
    % xlabel('window');
    % ylabel('delay bin');
    set(ah,'clim',[-0.2 0.2]);
    
    
end

ah = subplot(3,3,9);
set(ah,'visible','off');
set(ah,'clim',[-0.2 0.2]);
colorbar;



% now make a figure of... the correlations between CW loops and channels..

collect = [];
channel = 25;
for i_reg=1:numel([33 34 35 36 37 38 39 40]);
    for i=1:numel(logs)
        collect(:,i,i_reg) = [logs{i}.corrs{channel,i_reg}]';
        
    end
end


figure;
for i_reg=1:8
    
    % figure;
    ah = subplot(3,3,i_reg);
    ih = imagesc(collect(:,:,i_reg));
    title(['cw ' num2str(i_reg)]);
    % xlabel('window');
    % ylabel('delay bin');
    set(ah,'clim',[-0.9 0.9]);
    
    
end
ah = subplot(3,3,9);
set(ah,'visible','off');
set(ah,'clim',[-0.9 0.9]);
colorbar;




xlabel('window');
ylabel('beta fit parameter');








