function net_biological_correction(processedeeg_filename, bio_options)


if strcmp(bio_options.enable, 'on')
    
    D=spm_eeg_load(processedeeg_filename);
    
    
    list_eeg    = selectchannels(D,'EEG');
   
    Fs          = fsample(D);

    data=D(list_eeg,:,:);
    
    data=detrend(data')';
      
    ntp         = size(data,2);
    
    normal=[1:ntp];
    
    samplesize = bio_options.sampleSize;
    
    ntp_sel = ceil(length(normal)*samplesize);
    
    randn('seed',0);
    
    samples     = net_getrandsamples(normal, ntp_sel,'random');
    
    [dewhitening, score, latent]=pca(data(:,samples)','Centered','off');
    whitening=inv(dewhitening);
    PC=whitening*data;
    latent=100*latent/sum(latent);
    n_pcs=sum(latent>0.1*mean(latent));
    retained_variance=sum(latent(1:n_pcs));
    
    switch bio_options.bss_method
        
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
                 'WDiffStop',10e-9);
             
             unmixing=Wmat(:,:,1);
             IC=unmixing*PC(1:n_pcs,:);
             mixing=pinv(unmixing);
             
             
    end
            
    
    %%
    
    str=bio_options.elec_labels;
    art_labels=[];
    remain = str;
    while not(isempty(deblank(remain)))
        [token,remain] = strtok(remain,' ');
        art_labels = [art_labels, {token}];
    end
    
    
    mean_std    = mean(std(data'));
    list_noneeg = [net_artchannels(D,art_labels)];
    ref_sigs=D(list_noneeg,:,:);
    std_val     = std(ref_sigs',1);
    ref_sigs  = mean_std*ref_sigs./(std_val'*ones(1,size(D,2)));
    
   
    D(list_noneeg,:,:) = ref_sigs;
   
    M_pc=abs(corr(IC',ref_sigs'));
    %M_pc=[corr(IC.^2',ref_sigs.^2')]; 

    corr_max=max(M_pc,[],2);
 
%     ratio_int=zeros(size(IC,1),1);
%     for i=1:size(IC,1)
%         weights=dewhitening(:,1:size(mixing,2))*mixing(:,i);
%         weights=weights-mean(weights);
%         weights=sort(weights,'descend');
%         if weights(1)+weights(end)<0
%             weights=-weights(end:-1:1);
%         end
%         %ratio_int(i)=weights(1)/weights(2);
%         ratio_int(i)=weights(1)/weights(1+ceil(length(list_eeg)/128));
%         %figure; bar(weights);
%     end
    
    ntp = size(IC,2);
    
    vc=zeros(size(IC,1),1);
    for i=1:size(IC,1)
    xc=xcorr(IC(i,:),'coeff');
    xc=xc(ntp+1:ntp+2*round(Fs));
    %figure; plot(xc(6:25)); title(num2str(i));
    %disp([num2str(max(xc(6:25)))  '  ' num2str(i)]);
    vc(i,1)=max(xc([1+fix(0.6*Fs):ceil(1.2*Fs)]))/max([0.1 xc([1+fix(Fs/12):ceil(Fs/8)])]); %autocorrelazione in banda cardiaca / autocorrelazione in banda alpha 
    end
%     
    
    g = fittype({'1/x','1'});
    frq_interval=[2 48];
    nfft = 1024;
    df = [1 100];
    
    mp=zeros(size(IC,1),1);
    
    for k=1:size(IC,1)
        [freq,sp]=net_psd(IC(k,:),nfft,Fs,@hanning,50,df,'off');
        vec = find(freq > frq_interval(1) & freq < frq_interval(2));
        [x,f] = fit(freq(vec),sp(vec),g);
        %sp2=diff(sp);
%         a=x(freq(vec));
%         b=sp(vec)-a;
%         b=b-min(b)+0.01;
%         [~,pos]=max(b);
%         mp(k) = b(pos)/b(1);
        mp(k)=f.rsquare;
        %figure; plot(freq(vec),sp(vec),'r'); title(num2str(mp(k)));
    end
    
    
%         mp=zeros(size(IC,1),1);
%     
%     for k=1:size(IC,1)
%         [freq,sp]=net_psd(IC(k,:),nfft,Fs,@hanning,50,df,'off');
%         vec = find(freq > frq_interval(1) & freq < frq_interval(2));
%         x = fit(freq(vec),sp(vec),g);
%         a=x(freq(vec));
%         b=sp(vec)-a;
%         b=b-min(b)+0.01;
%         [~,pos]=max(b);
%         mp(k) = b(pos)/b(1);
%          figure; plot(freq(vec),b,'r'); hold on; plot(freq(vec),sp(vec)); title(num2str(mp(k)));
%     end
%     
%   bad_ics=find(mp>bio_options.mp_thres  | corr_max>bio_options.corr_thres | ratio_int>bio_options.int_thres);
    
   bad_ics=find(vc>bio_options.vc_thres | mp>bio_options.mp_thres  | corr_max>bio_options.corr_thres);
   
   %% test code from Mingqi
    [preprocess_path, ~] = fileparts(processedeeg_filename);
    IC_file = [preprocess_path, filesep, 'IC_biological.mat'];
    mixing_matrix = dewhitening(:,1:n_pcs)*mixing;
    save(IC_file, 'mixing_matrix', 'IC', 'bad_ics', 'Fs');
    %%
   
   %bad_ics=find(corr_max>bio_options.corr_thres | ratio_int>bio_options.int_thres);
   
    
    
%      Fs = fsample(D);
%         nfft = 1024;
%         df = [1 100];
%     
%         figure;
%         subplot(1,2,1)
%         [Fxx,Pxx]=net_psd(IC,nfft,Fs,@hanning,50,df,'off');
%         xlim([0 80])
%     
%     
%         for i=1:size(IC,1)
%             figure; plot(Fxx(:,i),log(Pxx(:,i))); xlim([0 80])
%         end
    
    data_new=D(list_eeg,:,:)-dewhitening(:,1:n_pcs)*mixing(:,bad_ics)*IC(bad_ics,:);
%     
%         Fs = fsample(D);
%         nfft = 1024;
%         df = [1 100];
%     
%         figure;
%         subplot(1,2,1)
%         [Fxx,Pxx]=net_psd(D(list_eeg,:,:),nfft,Fs,@hanning,50,df,'on');
%         xlim([0 80])
%         ylim([0 100])
%         subplot(1,2,2)
%         [Fxx,Pxx]=net_psd(data_new,nfft,Fs,@hanning,50,df,'on');
%         xlim([0 80])
%         ylim([0 100])
%     
%     
    D(list_eeg,:,:) = data_new;
    
    D.save;
    
    
end
