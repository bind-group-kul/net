function [  ] = net_muscle_correction_gamma_ratio( processedeeg_filename, options )
%NET_MUSCLE_CORRECTION_2 Summary of this function goes here
%   Detailed explanation goes here
    
    %% 1.configurations
    options.gamma_band = [30, 80];
    options.whole_band = [1, 80];
    
    %% 2. process
    if strcmp(options.enable, 'on') 
        %% 2.1 load file
        D=spm_eeg_load(processedeeg_filename);
        list_eeg = selectchannels(D,'EEG');
        Fs = fsample(D);
        data=D(list_eeg,:,:);
        data=detrend(data')';
        ntp = size(data,2);
        
        %% 2.2 resample for BSS
        normal=[1:ntp];
        samplesize = options.sampleSize;
        ntp_sel = ceil(length(normal)*samplesize);
        randn('seed',0);
        samples = net_getrandsamples(normal, ntp_sel,'random');
        
        %% 2.3 whitening for BSS
        [dewhitening, score, latent]=pca(data(:,samples)','Centered','off');
        whitening=inv(dewhitening);
        PC=whitening*data;
        latent=100*latent/sum(latent);
        n_pcs=sum(latent>0.1*mean(latent));
        retained_variance=sum(latent(1:n_pcs));
        
        %% 2.4 BSS
        switch options.bss_method
            case 'pca'
                IC=PC(1:n_pcs,:);
                unmixing=eye(n_pcs);
                mixing=eye(n_pcs);

            case 'cca'
                [IC,unmixing] = ccabss(PC(1:n_pcs,:));
                unmixing=real(unmixing');
                IC=unmixing*score(:,1:n_pcs)';
                mixing=pinv(unmixing);

            case 'fastica_defl'
                [IC, mixing, unmixing]=fastica(PC(1:n_pcs,samples),'approach','defl','g','tanh','maxNumIterations',500);
                IC=unmixing*PC(1:n_pcs,:);

            case 'fastica_symm'
                [IC, mixing, unmixing]=fastica(PC(1:n_pcs,samples),'approach','symm','g','tanh','stabilization','on','maxNumIterations',1000);
                IC=unmixing*PC(1:n_pcs,:);

            case 'runica'
                [unmixing,~]=runica(PC(1:n_pcs,samples),'extended',1);
                IC=unmixing*PC(1:n_pcs,:);
                mixing=pinv(unmixing);

            case 'jade'
                [unmixing]=jader(PC(1:n_pcs,samples));
                IC=unmixing*PC(1:n_pcs,:);
                mixing=pinv(unmixing);

             case 'iva'
                 Nshifts=4;
                 lag=ceil(8*Fs/1000);
                 Xmat=net_shifted_dataset(PC(1:n_pcs,:),'lag',lag,'Nshifts',Nshifts);
                 [Wmat]=net_iva_second_order(Xmat,...
                     'verbose',true,...
                     'opt_approach','quasi',...
                     'maxIter',5000,...
                     'WDiffStop',1e-9);
                 
                 unmixing=Wmat(:,:,1);
                 IC=unmixing*PC(1:n_pcs,:);
                 mixing=pinv(unmixing);

        end
        
        %% 2.5.1 Myogenic artifact removal: non-referential approach
        bad_ics_gamma_ratio = [];
        if(strcmp(options.gammaRatio_enable, 'on'))    
            ratios = net_get_power_ratio(IC, Fs,  options.gamma_band, options.whole_band);
            bad_ics_gamma_ratio = find(ratios >= options.gammaRatio_thres);
        end
        
        %% 2.5.2 Myogenic artifact removal: referential approach
        bad_ics_ref = [];
        if(strcmp(options.reference_enable, 'on'))
            list_emg = net_selectchannels(D,'EMG');
            if(~isempty(list_emg))
                mean_std = mean(std(data'));
                ref_sigs=D(list_emg,:,:);
                std_val = std(ref_sigs',1);
                ref_sigs = mean_std*ref_sigs./(std_val'*ones(1,size(D,2)));
                D(list_emg,:,:) = ref_sigs;

                emg_corr=abs(corr(IC',ref_sigs'));
                emg_corr_max=max(emg_corr,[],2)';
                
                bad_ics_ref = find(emg_corr_max >= options.reference_thres);
                
            end
        end
        
        %% 2.6 define bad ICs, and remove artifacts
        bad_ics = unique([bad_ics_gamma_ratio, bad_ics_ref]);
        data_new = D(list_eeg,:,:)-dewhitening(:,1:n_pcs)*mixing(:,bad_ics)*IC(bad_ics,:);
        
        %% 2.7 save some test results for debug, can be turned off
        test = 'on';
        if(strcmp(test, 'on'))
            [preprocess_path, ~] = fileparts(processedeeg_filename);
            IC_file = [preprocess_path, filesep, 'IC_S3_muscle.mat'];
            mixing_matrix = dewhitening(:,1:n_pcs)*mixing;
            unmixing_matrix = unmixing*whitening(1:n_pcs, :);
            save(IC_file, 'mixing_matrix', 'unmixing_matrix', 'IC', 'dewhitening', 'whitening', 'mixing', 'n_pcs', 'latent', 'PC', 'unmixing', 'bad_ics','Fs', 'bad_ics_gamma_ratio', 'bad_ics_ref');
       
        end
        
        %% 2.8 show PSD comparison figures
        show_figs = 'off';
        if(strcmp(show_figs, 'on'))
            Fs = fsample(D);
            nfft = 1024;
            df = [1 100];
        
            figure;
            subplot(1,2,1)
            [Fxx,Pxx]=net_psd(D(list_eeg,:,:),nfft,Fs,@hanning,50,df,'on');
            xlim([0 80])
            ylim([0 100])
            subplot(1,2,2)
            [Fxx,Pxx]=net_psd(data_new,nfft,Fs,@hanning,50,df,'on');
            xlim([0 80])
            ylim([0 100])
        end
        
        %% 2.9 save data back to D struck
        D(list_eeg,:,:)=data_new;
        D.save; 
    end
end