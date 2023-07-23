function net_movement_correction(processedeeg_filename, mov_options)


if strcmp(mov_options.enable, 'on')
    
    D=spm_eeg_load(processedeeg_filename);
     
    % dd=fileparts(fileparts(processedeeg_filename));
    
    list_eeg    = selectchannels(D,'EEG');
   
    Fs          = fsample(D);
     
    nsamples=6600;
    
    lp=mov_options.low_pass;
    
    hp=[];
    
    EEG = pop_fileio([path(D) filesep fname(D)]);
    [newEEG]=net_unripple_filter(EEG,hp,lp,nsamples);
    
    
    data=newEEG.data(list_eeg,:,:);
    
    data=detrend(data')';
      
    ntp         = size(data,2);
    
    normal=[1:ntp];
    
    samplesize = mov_options.sampleSize;
    
    ntp_sel = ceil(length(normal)*samplesize);
    
    randn('seed',0);
    
    samples     = net_getrandsamples(normal, ntp_sel,'random');
    
    [dewhitening, score, latent]=pca(data(:,samples)','Centered','off');
    whitening=inv(dewhitening);
    PC=whitening*data;
    latent=100*latent/sum(latent);
    n_pcs=sum(latent>0.1*mean(latent));
    retained_variance=sum(latent(1:n_pcs));
    
    switch mov_options.bss_method
        
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
            
    kurtosis=kurt(IC');
    
    bad_ics=find(kurtosis>mov_options.thres_kurtosis);
   
    data_new = D(list_eeg,:,:)-dewhitening(:,1:n_pcs)*mixing(:,bad_ics)*IC(bad_ics,:);
    
    %% test code from Mingqi
    [preprocess_path, ~] = fileparts(processedeeg_filename);
    IC_file = [preprocess_path, filesep, 'IC_movement.mat'];
    mixing_matrix = dewhitening(:,1:n_pcs)*mixing;
    save(IC_file, 'mixing_matrix', 'IC', 'bad_ics', 'Fs');
    %%
%     Fs = fsample(D);
%     nfft = 1024;
%     df = [1 100];
%    
%     figure;
%     subplot(1,2,1)
%     [Fxx,Pxx]=performPSD1(D(list_eeg,:,:),nfft,Fs,@hanning,60,1,df);
%     xlim([0 80])
%     ylim([0 100])
%     subplot(1,2,2)
%     [Fxx,Pxx]=performPSD1(data_new,nfft,Fs,@hanning,60,1,df);
%     xlim([0 80])
%     ylim([0 100])    
    
    D(list_eeg,:,:)=data_new;
    
    
    D.save;
    
    
end
