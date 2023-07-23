function net_ica_cleaning(processedeeg_filename, ica_options)


if strcmp(ica_options.enable, 'on')
    
    D=spm_eeg_load(processedeeg_filename);
    
    ev=events(D);
    
    if not(isempty(ev))
    
    ica_options.events=ev;
    
    end
    
    dd=fileparts(fileparts(processedeeg_filename));
    
    elec_file=[dd filesep 'mr_data' filesep 'electrode_positions.sfp'];
    chanlocs=readlocs(elec_file);
    list_eeg    = selectchannels(D,'EEG');
    
    str=ica_options.elec_labels;
    art_labels=[];
    remain = str;
    while not(isempty(deblank(remain)))
        [token,remain] = strtok(remain,' ');
        art_labels = [art_labels, {token}];
    end
    
    Fs          = fsample(D);
    mean_std    = mean(std(D(list_eeg,:,:)'));
    list_noneeg = [net_artchannels(D,art_labels)];
    std_val     = std(D(list_noneeg,:,:)',1);
    D(list_noneeg,:,:) = mean_std*D(list_noneeg,:,:)./(std_val'*ones(1,size(D,2)));
    
   % data = spm2fieldtrip(D); %%%% Added by JS to have access to "data.elec.label"
    
    Fs_new=ica_options.fsample;
    
    eeg_res=resample(D(list_eeg,:,:)',Fs_new,Fs)';
    
    %elec_res=resample(D(list_noneeg,:,:)',Fs_new,Fs)';
    
    
    ntp         = size(eeg_res,2);
    
    medianpower    = median(eeg_res.^2,1);
    
    outlier=net_tukey(log(medianpower),5);
    
    vect=ones(1,ntp);
    for i=1:length(outlier)
        xx=[outlier(i)-Fs_new:outlier(i)+Fs_new];
        xx(xx<1)=[];
        xx(xx>ntp)=[];
        vect(xx)=0;
    end
    
    if not(isempty(ev))
    
    start_t=round(Fs_new*ev(1).time);

    end_t=round(Fs_new*ev(end).time);
    
    vect([1:start_t])=0;
    
    vect([end_t:end])=0;
    
    end
    
    
    normal=find(vect==1);
    
    samplesize = ica_options.sampleSize;
    
    ntp_sel = fix(ntp*samplesize);
    
    randn('seed',0);
    
    samples_ica     = net_getrandsamples(normal, ntp_sel,'random');
    
    [coeff, score, latent]=pca(eeg_res);
    latent=100*latent/sum(latent);
    n_pcs=sum(latent>0.01*mean(latent));
    
    [IC, mixing, unmixing]=fastica(eeg_res(:,samples_ica),'approach',ica_options.approach,'g',ica_options.nonlinearity,'maxNumIterations',ica_options.iterations,'lastEig',n_pcs);
    
    
    comp=[];
    comp.topo       = mixing;
    comp.unmixing   = unmixing;
    comp.trial{1}   = unmixing*eeg_res; 
    comp.trial_full{1} = unmixing*D(list_eeg,:,:);
    comp.time{1}    = [1:length(samples_ica)]/ica_options.fsample;
    comp.time_full{1}    = [1:size(comp.trial_full{1},2)]/Fs;
    comp.fs_ica = ica_options.fsample;
    comp.fs = fsample(D);
    comp.samples_ica    = samples_ica;
    comp.chanlocs  = chanlocs(list_eeg);
    
    
    
    [good_ics,bad_ics,stats] = net_classify_ic(comp,D(list_noneeg,:,:),ica_options);
    
    
    comp.good_ics = good_ics;
    comp.bad_ics = bad_ics;
    comp.stats = stats;
    
    if strcmpi(ica_options.artifact_check,'on')||strcmpi(ica_options.artifact_check,'yes')
        
        comp = net_classify_ic_check(comp);
        
    end
    
    
    % recover components time-locked to the experimental events
    
%     
%     for k=length(ev):-1:1
%         if strcmpi(ev(k).type,'mr_pulse')
%             ev(k)=[];
%         end
%     end
%     
%     if numel(ev)>=10 %%%%%%%%%%%%%%%%%%%%%%%%%%% changed by JS because in our case numel(ev)=3 but this is not an event related study
%         
%         tt=zeros(1,length(ev));
%         for k=1:length(ev)
%             tt(k)=round(comp.fs*ev(k).time);
%         end
%         
%         dur=round(0.9*median(diff(tt)));
%         pre=-round(0.1*dur);
%         post=dur+pre;
%         
%         while tt(end)+post>size(comp.trial_full{1},2)
%             tt(end)=[];
%         end
%         
%         label_ic=zeros(1,size(comp.trial_full{1},1));
%         label_ic(good_ics)=1;
%         
%         xx=zeros(1,length(bad_ics));
%         for i=1:length(bad_ics)
%             IC=comp.trial_full{1}(bad_ics(i),:);
%             mat=zeros(dur+1,length(tt));
%             for k=1:length(tt)
%                 vec=[tt(k)+pre:tt(k)+post];
%                 mat(:,k)=IC(vec)'; 
%             end
%             %figure; plot(mean(mat,2));
%             
%             xx(i)=mean(corr(mat,mean(mat,2)));
%             
%         end
%         
%         out=net_tukey(xx,2);
%         
%         label_ic(bad_ics(out))=1;
%         label_ic(bad_ics(xx<0.1))=0;  % do not recover components if inter-trial correlation is below 0.1
%         
%         good_ics_new=find(label_ic);
%         bad_ics_new=find(not(label_ic));
%         
%         comp.good_ics = good_ics_new;
%         comp.bad_ics = bad_ics_new;
%         
%     end
%     

    D.ica_results=comp;

    
    if strcmp(ica_options.reconstruction,'recombine')
        
       clean_data = mixing(:,comp.good_ics)*comp.trial_full{1}(comp.good_ics,:);    
 
    elseif strcmp(ica_options.reconstruction,'remove')
         
        clean_data = D(list_eeg,:,:)-mixing(:,comp.bad_ics)*comp.trial_full{1}(comp.bad_ics,:);
        
    else
        
        disp(['invalid ICA recontruction option ' ica_options.reconstruction]);
        
        return;
        
    end
    

    
   D(list_eeg,:,:)=clean_data;
    
   D.save;
    
    
end
