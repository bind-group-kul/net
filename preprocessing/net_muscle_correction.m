function net_muscle_correction(processedeeg_filename, muscle_options)


if strcmp(muscle_options.enable, 'on')
    
    D=spm_eeg_load(processedeeg_filename);
    
    list_eeg    = selectchannels(D,'EEG');
   
    Fs          = fsample(D);
     
    nsamples=6600;
   
    
    hp=muscle_options.high_pass;
    
    lp=[];
    
    EEG = pop_fileio([path(D) filesep fname(D)]);
    [newEEG]=net_unripple_filter(EEG,hp,lp,nsamples);
    
    
    data=newEEG.data(list_eeg,:,:);
    
    data=detrend(data')';
      
    ntp         = size(data,2);
    
    normal=[1:ntp];
    
    samplesize = muscle_options.sampleSize;
    
    ntp_sel = ceil(length(normal)*samplesize);
    
    randn('seed',0);
    
    samples     = net_getrandsamples(normal, ntp_sel,'random');
    
    [dewhitening, score, latent]=pca(data(:,samples)','Centered','off');
    whitening=inv(dewhitening);
    PC=whitening*data;
    latent=100*latent/sum(latent);
    n_pcs=sum(latent>0.1*mean(latent));
    retained_variance=sum(latent(1:n_pcs));
    
    switch muscle_options.bss_method
        
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
    
    
    IC_num = size(IC,1);
    ntp = size(IC,2);

    g = fittype({'1/x','1'});
    %frq_interval=[2 48];
    nfft = 1024;
    df = [1 100];
    
    alpha_band = [8 12];
    gamma_band = [31 79];
    
    
    ratio=zeros(1,IC_num);
    
    for k=1:IC_num
        [freq,sp]=net_psd(IC(k,:),nfft,Fs,@hanning,50,df,'off');
        %vec = find(sp>0.01*max(sp));
        %fmax=max(freq(vec))-1;
        %[~,pos]=min(abs(freq-fmax));
        %[~,posx]=max(sp(vec));
        %ratio(k) = freq(pos)/freq(posx);
        pow_alpha=mean(sp(freq>alpha_band(1) & freq<alpha_band(2)));
        pow_gamma=mean(sp(freq>gamma_band(1) & freq<gamma_band(2)));
        ratio(k) = pow_alpha / pow_gamma ;
        %figure; plot(freq(vec),sp(vec)); title(num2str(ratio(k)));
    end


    
    vc=zeros(1,IC_num);
    for i=1:size(IC,1)
        xc=xcorr(IC(i,:),'coeff');
        xc=xc(ntp+1:ntp+round(Fs));
        val=min(findpeaks(double(xc(round(Fs/100):round(Fs/13))),'MinPeakHeight',muscle_options.xcorr_thres));
        %       figure; plot(xc(1:25)); title(num2str(i));
        if not(isempty(val))
            vc(i) = val;
        end
    end
  
   
   bad_ics=find(ratio<=muscle_options.pow_thres | vc>muscle_options.xcorr_thres);
    %% test code from Mingqi
    [preprocess_path, ~] = fileparts(processedeeg_filename);
    IC_file = [preprocess_path, filesep, 'IC_muscle.mat'];
    mixing_matrix = dewhitening(:,1:n_pcs)*mixing;
    save(IC_file, 'mixing_matrix', 'IC', 'bad_ics', 'Fs');
    
    %%
  
    data_new = D(list_eeg,:,:)-dewhitening(:,1:n_pcs)*mixing(:,bad_ics)*IC(bad_ics,:);
        
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
    
    D(list_eeg,:,:)=data_new;
    
    D.save;
    
    
end
