function net_despiking(processedeeg_filename, options)


if strcmp(options.enable, 'on')
    
    window=options.window;
    
    D=spm_eeg_load(processedeeg_filename);
     
    list_eeg    = selectchannels(D,'EEG');
   
    Fs          = fsample(D);

    data=D(list_eeg,:,:);
    
    data=detrend(data')';
      
    ntp         = size(data,2);
    
    data_new=data;
    
    for i=1:length(list_eeg)
       
        
       sig=data(i,:); 
       
%         frequencies=[1:80];
%       winsize  = round(2*Fs);
%         overlap  = round(Fs);   
%     
%     [St, F, T, Pt] = spectrogram(sig, winsize, overlap, frequencies, Fs);
%   
%     figure; imagesc(T,F,Pt);  colorbar; 
   
       amp=sqrt(sig.^2);
       
       [upper,~] = net_envelope(amp,round(window*Fs),'peak');
       
       amp_env=max([abs(upper); amp],[],1);
       
%       figure; plot(amp); hold on; plot(amp_env,'r');
       
       [out,~]=net_tukey(amp_env,5);
       
       vect=zeros(1,ntp);
       
       vect(out)=1;
       
       vect2=smooth(vect,round(Fs),'moving');
       
%       amp_env_clean=amp_env;
%       
%       amp_env_clean(vect2==0)=0;
%       
%       figure; plot(amp_env); hold on; plot(amp_env_clean,'r');
       
       sig2=sig;
       
       sig2(vect2>0)=median(amp_env(vect2==0))*sig(vect2>0)./amp_env(vect2>0);
       
%       figure; plot(sig); hold on; plot(sig2,'r');
%       
%       figure; plot(sig2);
%       
%        frequencies=[1:80];
%        winsize  = round(2*Fs);
%        overlap  = round(Fs);
%        
%        [St, F, T, Pt] = spectrogram(sig2, winsize, overlap, frequencies, Fs);
%        
%        figure; imagesc(T,F,Pt);  colorbar;

        data_new(i,:)=sig2;
        
        disp(['despiking channel ' num2str(i) ' - ' num2str(0.1*round(100*sum(vect2>0)/ntp)) '% data corrected']);
        
    end
    
    
    D(list_eeg,:,:) = data_new;
    
    D.save;
    
    
end
