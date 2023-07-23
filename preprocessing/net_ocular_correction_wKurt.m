function [ ] = net_ocular_correction_wKurt( processedeeg_filename, options)
%NET_REMOVE_EOG Summary of this function goes here
%   Detailed explanation goes here
    
    options.wKurt_overlap = 0.5;
    
    %% 2. process
    if strcmp(options.enable, 'on')
        %% 2.1 load data
        D=spm_eeg_load(processedeeg_filename);
        list_eeg = selectchannels(D,'EEG');
        Fs = fsample(D);
        data = D(list_eeg,:,:);
        data=detrend(data')';
        ntp = size(data,2);     
              
        %% 2.3 resample for BSS
        normal=[1:ntp];
        samplesize = options.sampleSize;
        ntp_sel = ceil(length(normal)*samplesize);
        randn('seed',0);
        samples = net_getrandsamples(normal, ntp_sel,'random');
        
        %% 2.4 whitening for BSS
        [dewhitening, score, latent]=pca(data(:,samples)','Centered','off');
        whitening=inv(dewhitening);
        PC=whitening*data;
        latent=100*latent/sum(latent);
        n_pcs=sum(latent>0.1*mean(latent));
        retained_variance=sum(latent(1:n_pcs));
        
        %% 2.5 BSS
        switch options.bss_method
            case 'pca'
                IC=PC(1:n_pcs,:);
                unmixing=eye(n_pcs);
                mixing=eye(n_pcs);

            case 'cca'
                [IC,unmixing] = ccabss(PC(1:n_pcs,samples));
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
        
        
        %% 2.5 Ocular artifact removal: non-referential with windowed kurtosis
        bad_ics_wKurt = [];
        if(strcmp(options.kurtosis_enable, 'on'))
            filtered_ICs = net_filterdata(IC, Fs, [], 7);
            wKurts = net_windowed_kurtosis(filtered_ICs, Fs, options.kurtosis_window, options.wKurt_overlap, 'max');
            bad_ics_wKurt = find(wKurts >= options.kurtosis_thres);            
        end
        
        %% 2.6 Ocular artifact removal: referential approach with correlation
        bad_ics_corr = [];
        if(strcmp(options.reference_enable, 'on'))
            ref_channel = selectchannels(D,'EOG');
            if(~isempty(ref_channel))
                
                ref_sigs = D(ref_channel,:,:);
                ref_sigs = net_filterdata(ref_sigs, D.fsample, 1, 12);
                ref_sigs = detrend(ref_sigs')';
                
                corr_vals = abs(corr(IC',ref_sigs'));
                corr_max = max(corr_vals,[],2)';
                
                bad_ics_corr = find(corr_max >= options.reference_thres);
            else
                disp('Could not find EOG channel as reference for ocular artifact removal. Please check the conversion page of xls file!');
            end
        end
        
        %% 2.7 define bad ICs, and remove artifacts
        bad_ics = unique([bad_ics_wKurt, bad_ics_corr]);
        data_new = D(list_eeg,:,:)-dewhitening(:,1:n_pcs)*mixing(:,bad_ics)*IC(bad_ics,:);
        
        %% 2.8 save some test results for debug, can be turned off
        test = 'on';
        if(strcmp(test, 'on'))
            [preprocess_path, ~] = fileparts(processedeeg_filename);
            IC_file = [preprocess_path, filesep, 'IC_S1_ocular.mat'];
            mixing_matrix = dewhitening(:,1:n_pcs)*mixing;
            unmixing_matrix = unmixing*whitening(1:n_pcs, :);
            save(IC_file, 'mixing_matrix', 'unmixing_matrix', 'IC', 'dewhitening', 'whitening', 'mixing', 'n_pcs', 'latent', 'PC', 'unmixing', 'bad_ics','Fs', 'bad_ics_wKurt', 'bad_ics_corr');
        end
        
        %% 2.9 show PSD comparison figures
        Fs = fsample(D);
        nfft = 1024;
        df = [1 20];
        
        show_figs = 'off';
        if(strcmp(show_figs, 'on'))
            figure;
            subplot(1,2,1)
            [Fxx,Pxx]=net_psd(D(list_eeg,:,:),nfft,Fs,@hanning,50,df,'on');
            xlim([0 7])
            ylim([0 100])
            subplot(1,2,2)
            [Fxx,Pxx]=net_psd(data_new,nfft,Fs,@hanning,50,df,'on');
            xlim([0 7])
            ylim([0 100])
        end
        
        %% 2.10 save data back to D struck
        D(list_eeg,:,:)=data_new;
        D.save;   
    end
end

