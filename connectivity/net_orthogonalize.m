function [voxel_ortho] = net_orthogonalize(brain_signals, options, type)
%NET_ORTHOGONALIZE  Orthogonalize the time course of a brain source
%                   with respect to the seed activity
%
%Input:             BRAIN_SIGNALS - matrix containing one time course per voxel,
%                                   organized as [time_samples x n_voxel]
%                   OPTIONS       - fs, seed indices
%                   TYPE          - "time" or "frequency" output
%
%Output:            VOXEL_ORTHO   - time course of the voxel orthogonalized with
%                   respect to the seed

Fs          = options.Fs;
ntp         = size(brain_signals,1);
f_spctrgrm  = 1:80; % in Hz
nvoxels     = size(brain_signals,2);
nseeds      = length(options.seedindx);
type        = lower(type);
% Window features
win.length    = 2; % window length in seconds
win.samples   = round(win.length*Fs); % windows length in samples
win.step      = 1; % step length in sec
win.overlaptp = round(Fs*(win.length-win.step)); % overlap in samples
win.nwin      = fix((ntp-win.overlaptp)/(win.samples-win.overlaptp)); % number of segments after windowing

% allocate space for the output
if     ( strcmp(type,'time') )
	voxel_ortho = zeros(ntp,nvoxels,nseeds);
elseif ( strcmp(type,'freq') )
    voxel_ortho = zeros(length(f_spctrgrm), win.nwin, nvoxels,nseeds);
end
% compute the spectrogram (for net_compute_alpha)
F_T_all = net_spectrogram(brain_signals,f_spctrgrm,Fs,win);

for s = 1:nseeds
    seed  = brain_signals(:,options.seedindx(s));
    % Synchrosqueezed transform of the seed
    [X,f_sst] = net_wsst(seed,Fs,'bump','ExtendSignal',1,'FreqScale','linear');  % f_sst x ntp
    % average some rows to consider the same frequencies of the
    % spectrogram
    f_spctrgrm_up = f_spctrgrm + 0.5;
    f_spctrgrm_up(end) = f_spctrgrm(end) + 1;
    temp         = X;
    temp_f       = f_sst;
    x = zeros(length(f_spctrgrm), ntp);
    for f = 1:length(f_spctrgrm)
    	indx_up  = find(temp_f<f_spctrgrm_up(f));
        indx_up  = indx_up(end);
        Xf       = temp(1:indx_up,:);
        temp     = temp(indx_up+1:end,:);
        temp_f   = temp_f(:,indx_up+1:end);
        x(f,:)   = nanmean(Xf,1);
    end
    
    %% 1. Compute orthogonalization coefficients
    alpha = net_compute_alpha(options.seedindx(s),F_T_all); % f_spctrgrm x nwin x nvoxels
    alpha_avg = mean(alpha,2); % average over time considering the stationarity
    alpha_avg = squeeze(alpha_avg); % f_spctrgrm x nvoxels
    
    for v = 1:nvoxels
        voxel = brain_signals(:,v);
        
    %% 2. Synchrosqueezed transform the generic voxel
        [Y,f_sst] = net_wsst(voxel,Fs,'bump','ExtendSignal',1,'FreqScale','linear'); % f_sst x ntp
        % average some rows to consider the same frequencies of the
        % spectrogram
        temp        = Y;
        temp_f      = f_sst;
        y = zeros(length(f_spctrgrm), ntp);
        for f = 1:length(f_spctrgrm)
            indx_up = find(temp_f<f_spctrgrm_up(f));
            indx_up = indx_up(end);
            Xf      = temp(1:indx_up,:);
            temp    = temp(indx_up+1:end,:);
            temp_f  = temp_f(:,indx_up+1:end);
            y(f,:)  = nanmean(Xf,1);
        end

    %% 3. Orthogonalization of voxel (y) to the seed (x) direction (Hipp et all., 2012)
        Y_ortho = zeros(length(f_spctrgrm), ntp);
        
        for f = 1:length(f_spctrgrm)
            Y_ortho(f,:) = y(f,:) - alpha_avg(f,v).*x(f,:); % f_spctrgrm x ntp
        end
        
    %% 4. Return the orthogonalized signal in the required domain
        if ( strcmp(type,'time') )
            voxel_ortho(:,v,s) = net_iwsst(Y_ortho,'bump');
        
        elseif ( strcmp(type,'freq') )
            % Window the orthogonalized voxel activity according to Hipp et all. (2012)
            colind = 1 + (0:(win.nwin-1))*(win.samples-win.overlaptp);    % starting point of each segment
            rowind = (1:win.samples)';
            var = {win.samples,win.overlaptp,f_spctrgrm,Fs};
            [~,~,~,~,~,ww] = net_welchparse(voxel,'psd',var{:}); % it doesn' matter which time course is given as first input, the window will always be the same
            vox = zeros(win.samples,win.nwin,length(f_spctrgrm));

            for f = 1:length(f_spctrgrm)
                Yf = Y_ortho(f,:)';
                vox(:,:,f) = ww.*Yf(rowind(:,ones(1,win.nwin))+colind(ones(win.samples,1),:)-1);
            end
            vox = mean(vox,1);
            vox = squeeze(vox)'; % f_spctrgrm x nwin
            
            voxel_ortho(:,:,v,s) = vox; % f_spctrgrm x nwin x nvoxels
        else
            disp('Type must be "frequency" or "time"')
            return
        end
    end
end