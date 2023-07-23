
% load it...
EEG = pop_loadset('filename','example_set.set','filepath','/data1/Dropbox/Dropbox/Prog/GitWork/CWRegr/eeglab13_1_1b/plugins/CWRegrTool/example_dataset/');

% do an actual CW regression...
EEG = pop_cwregression(EEG, 500, 4.000000, 0.050000, 4, 'hann', [33 34 35 36 37 38 39 40], [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31], 'taperedhann', 0);

% look at the logs of that... i am interested in beta parameter estimates!!
logs = EEG.cwregression.cfg.cwregression.logging;

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





