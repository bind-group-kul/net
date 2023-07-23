%% Purpose -- Perform removal of gradient artifact induced by the scanning pulse in the EEG data using FASTR..
% 1. If enabled chunk the data between the MR triggers
% 2. Compute the timing of the events(MR triggers)
% 3. Select only the events relevant for gradient artifact and the EEG
% channel data; if needed reconstruct the event markers
% 4. Supply them to the artefact subtraction algorithm
% 5. Get the cleaned data and also the template
% 6. Store the template as channels in the data

function net_rmMRIartifact(processedeeg_filename,options_fmri_artifacts)


if strcmp(options_fmri_artifacts.enable, 'on')

D=spm_eeg_load(processedeeg_filename);

list_eeg=indchantype(D,'EEG');

EEG = pop_fileio([path(D) filesep fname(D)]);
EEG.data = double( EEG.data );
event_code=options_fmri_artifacts.event_code;


Slices=options_fmri_artifacts.slices;
lpf=options_fmri_artifacts.lpf;
L=options_fmri_artifacts.L;
window=options_fmri_artifacts.window;
strig=options_fmri_artifacts.strig;
dummy_scans=options_fmri_artifacts.dummy_scans;

anc_chk=0;
tc_chk=0;

trig_info = size(EEG.event,2);%Collect the complete list of events
evmarkers=[];
for k = 1:trig_info
    mrtriggers = strcmpi(event_code,EEG.event(k).value);
    if(mrtriggers == 1)
        evmarkers = [evmarkers; EEG.event(k).latency]; %Collect the timing of the specific MR event
    end
    
end



if not(isempty(evmarkers))
    
    
    vol_time=round(mean(diff(evmarkers))); %Compute the repetition rate of the event

    
    if(dummy_scans>0)

         evmarkers_tot=[-vol_time*[dummy_scans:-1:1]'+evmarkers(1) ; evmarkers];

    end
    
    %Use the algorithm for artifact subtraction..
    
    Volumes=length(evmarkers_tot);
    
    %save a copy of the original data
     rawEEG = EEG.data;
    
     %Remove the gradient artifacts
     EEG=fmrib_fastr(EEG,lpf,L,window,evmarkers_tot,strig,anc_chk,tc_chk,Volumes,Slices);
     
     %Estimate the Gradient template..
     
     art=rawEEG(list_eeg,:)-EEG.data(list_eeg,:);
          
     [~,pcs,~]=pca(detrend(art'));

     
     %Collect the Gradient template..
     Gradienttemplate = pcs(:,1:3)';
     
     for i=1:3
        Gradienttemplate(i,:)=100*Gradienttemplate(i,:)/std(Gradienttemplate(i,:));
     end

     D(:,:,1) = EEG.data;
     
     D.save;
     
     disp('Add the Gradient templates as channels...');
     S=[];
     S.D=D;
     S.newchandata=Gradienttemplate;
     S.newchanlabels = [{'GradArt1'},{'GradArt2'},{'GradArt3'}];
     S.newchantype = [{'MRI'},{'MRI'},{'MRI'}];
     
     %Concatenate the channels with the existing channels
     D = net_concat_chans( S );
     
     
     % Chunking the dataset to remove the non-scanning periods
     
     triggers=D.triggers;
     
     t1=(-vol_time*(dummy_scans-1)+evmarkers(1))/fsample(D);
     t2=(evmarkers(end)+vol_time)/fsample(D);
     
     if t1>0
     
     cont=0;
     
     for i=1:length(triggers)
        tt=triggers(i).time;
        if tt>t1
           cont=cont+1;
           triggers_new(cont)=triggers(i);
           triggers_new(cont).time=tt-t1;
        end
         
     end
     
     clear job
     
     dir=path(D);
     name=fname(D);
     
     job.data = {[dir filesep name]};
     job.chunk(1).chunk_beg.t_rel = net_secs2hms(t1);
     job.chunk(1).chunk_end.t_rel = net_secs2hms(t2);
     job.options.overwr = 1;
     job.options.fn_prefix = 'chk';
     job.options.numchunk = 1;
     
     crc_run_chunking(job);
     
     S=[];
     S.D       = [dir filesep 'chk1_' fname(D)];
     S.outfile = [dir filesep fname(D)];
     spm_eeg_copy(S);
     delete([dir filesep 'chk1_' name]);
     delete([dir filesep 'chk1_' name(1:end-4) '.dat']);
     
     D=spm_eeg_load([dir filesep name]);
     D.triggers=triggers_new;
     D.save;
   
     end

end


end
