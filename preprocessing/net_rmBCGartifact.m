%% Purpose -- Perform removal of BCG artifact induced by the scanning pulse in the EEG data using FASTR..


function net_rmBCGartifact(processedeeg_filename,options_bcg_artifacts)

if strcmp(options_bcg_artifacts.enable, 'on')
    
    D=spm_eeg_load(processedeeg_filename);
    
    ecg_channel = options_bcg_artifacts.ecg_channel;
    
    list_eeg=indchantype(D,'EEG');
    
    Fs=fsample(D);
    
    minpeakdistance=round(0.6*Fs);
    
    eeg_data=D(list_eeg,:,:);
    eeg_data=detrend(eeg_data')';
    
    
    nchan=size(eeg_data,1); %no of the channels
    ntp = size(eeg_data,2); %no of the samples
    
    %% ECG peak detection
    
    
    if not(isempty(ecg_channel))
        
        ecg =D(ecg_channel,:);
        ecg = net_fir_hanning(ecg,Fs,5,20);
        ecg(1:fix(minpeakdistance/2))=0;
        ecg(ntp-fix(minpeakdistance/2):ntp)=0;
        pow=net_fir_hanning(ecg.*ecg,Fs,0.1,2);
        [~,locs_ecg] = findpeaks(pow,'minpeakdistance',minpeakdistance);
        
    else
        
        eeg_data_filt=eeg_data;
        for i=1:nchan
            eeg_data_filt(i,:) = net_fir_hanning(eeg_data(i,:),Fs,5,20);
            eeg_data_filt(i,1:fix(minpeakdistance/2))=0;
            eeg_data_filt(i,ntp-fix(minpeakdistance/2):ntp)=0;
        end
        
        [~,score_eeg]=pca(eeg_data_filt');
        
        ecg2=score_eeg(:,1)';
        
        pow=net_fir_hanning(ecg2.*ecg2,Fs,0.1,2);
        [~,locs_ecg] = findpeaks(pow,'minpeakdistance',minpeakdistance);
        
        locs_ecg=locs_ecg-round(0.2*Fs);
        
    end
    
    
    RR_intervals=diff(locs_ecg);
    
    % correct for missing beats
    
    tt=1.5*median(RR_intervals);
    xx=find(RR_intervals>tt);
    for kk=1:length(xx)
        val=RR_intervals(xx(kk));
        n_pt=round(val/median(RR_intervals));
        c=round(val/n_pt);
        for dd=1:n_pt-1
            locs_ecg=[locs_ecg locs_ecg(xx(kk))+dd*c];
        end
    end
    locs_ecg=sort(locs_ecg);
    
    
    RR_intervals=diff(locs_ecg);
    nbeats=length(locs_ecg-1);
    PArange=fix(min(RR_intervals)/4);
    
    
    % BCG peak detection
    eeg_data_filt=eeg_data;
    for i=1:nchan
        eeg_data_filt(i,:) = net_fir_hanning(eeg_data(i,:),Fs,2,20);
        eeg_data_filt(i,1:fix(minpeakdistance/2))=0;
        eeg_data_filt(i,ntp-fix(minpeakdistance/2):ntp)=0;
    end
    
    [coeff_eeg,score_eeg]=pca(eeg_data_filt');
    %[coeff_eeg,score_eeg]=princomp(eeg_data_filt');
    
    
    bcg=score_eeg(:,1)';
    
    locs_bcg=qrscorrect(locs_ecg,bcg',Fs);
    
    locs_bcg=unique(locs_bcg);
    
    RR_intervals_bcg=diff(locs_bcg);
    
    BCGrange=max(RR_intervals_bcg);
    
    locs_bcg=locs_bcg-round(0.2*Fs);
    
    while locs_bcg(1)<1
        locs_bcg(1)=[];
    end
    
    while locs_bcg(end)+BCGrange>length(bcg)
        locs_bcg(end)=[];
    end
    
    
    nbeats_bcg=length(locs_bcg);
    
    
    %% channel-by-channel BCG event detection and aOBS artifact correction
    
    fitted_art=zeros(size(D,1),ntp+max(RR_intervals));
    
    npcs=zeros(1,size(D,1));
    % bcg_pcs_tot = zeros(50,nchan);
    
    for i = 1:size(D,1)
        
        if not(i==ecg_channel)
            
            sig=detrend(D(i,:,:)')';
            
            % removal of BCG artifact
            
            
            bcg_tot=zeros(nbeats_bcg,BCGrange);
            
            for kk=1:nbeats_bcg
                
                bcg_tmp = sig(locs_bcg(kk)+1:locs_bcg(kk)+BCGrange);
                
                bcg_tot(kk,:) = bcg_tmp;
                
            end
            
            bcg_tot=detrend(bcg_tot')';
            
            bcg_median=median(bcg_tot,1);
            
            trial_corr=corr(bcg_median',bcg_tot');
            
            [outlier_trial,normal_trial] = net_tukey(trial_corr,0,'low');
            
            sig_bcg=mean(bcg_tot(normal_trial,:),1)';
            
            bcg_res=bcg_tot-ones(nbeats_bcg,1)*sig_bcg';
            
            [coeff,score] = pca(bcg_res(normal_trial,1:round(median(RR_intervals)))');
            %[coeff,score] = princomp(bcg_res(normal_trial,1:round(median(RR_intervals)))');
            
            variance=100*std(score,[],1)./sum(std(score,[],1));
            
            score=bcg_tot(normal_trial,:)'*coeff;
            
            mfactor = (10*length(normal_trial))/nchan;
            
            %     bcg_pcs=find(variance >mfactor*100/nchan);
            bcg_pcs= variance >mfactor*100/length(normal_trial);
            
            
            basis_tmp=[sig_bcg score(:,bcg_pcs)];
            
            basis=net_qr_comp(basis_tmp);
            
            disp(['channel no. ' num2str(i) ' - number of removed PCs ' num2str(size(basis,2))]);
            
            npcs(i)=size(basis,2);
            
            beta=(basis'*basis)^-1*basis'*bcg_tot';
            
            bcg_art=beta'*basis';
            
            for kk=1:nbeats_bcg-1
                
                tmp=bcg_art(kk,1:locs_bcg(kk+1)-locs_bcg(kk));
                
                tmp_slope=tmp(1)+(tmp(end)-tmp(1))*[0:length(tmp)-1]/(length(tmp)-1);
                
                fitted_art(i,locs_bcg(kk)+1:locs_bcg(kk+1))=tmp-tmp_slope;
                
            end
            
            tmp=mean(bcg_art,1);
            
            tmp_slope=tmp(1)+(tmp(end)-tmp(1))*[0:length(tmp)-1]/(length(tmp)-1);
            
            fitted_art(i,locs_bcg(kk+1)+1:locs_bcg(kk+1)+length(tmp))=tmp-tmp_slope;
            
            
        end
        
    end
    
 

    newART.data=fitted_art(:,1:ntp);
    clear fitted_art;
    
        
%     nsamples=6600;
%     lp=7;
%     hp=[];
%     
%     ART = pop_fileio([path(D) filesep fname(D)]);
%     ART.data=fitted_art(:,1:ntp);
%     clear fitted_art;
%     newART=net_unripple_filter(ART,hp,lp,nsamples);
%    
    
    D(:,:,:) = D(:,:,:)-newART.data;
    
    D.save;
    
    
    [~,pcs,~]=pca(detrend(newART.data(list_eeg,:)'));
    
    
    %Collect the Gradient template..
    BCGtemplate = pcs(:,1:3)';
    
    for i=1:3
        BCGtemplate(i,:)=100*BCGtemplate(i,:)/std(BCGtemplate(i,:));
    end
    
    
    disp('Add the BCG templates as channels...');
    S=[];
    S.D=D;
    S.newchandata=BCGtemplate;
    S.newchanlabels = [{'BCGart1'},{'BCGart2'},{'BCGart3'}];
    S.newchantype = [{'BCG'},{'BCG'},{'BCG'}];
    
    %Concatenate the channels with the existing channels
    D = net_concat_chans( S );
    
    
end