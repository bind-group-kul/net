%% Purpose -- Perform removal of gradient artifact induced by the scanning pulse in the EEG data using FASTR..
% 1. Compute the timing of the events(MR triggers)
% 2. Select only the events relevant for gradient artifact and the EEG
% channel data
% 3. Supply them to the artefact subtraction algorithm

function D = net_rmfastrgradientartifact(D,options)

EEG = pop_fileio([path(D) filesep fname(D)]);
EEG.data = double( EEG.data );
EEG.data=EEG.data(1:128,:);
EEG.chanlocs=EEG.chanlocs(1:128);
%EEG = net_spm2eeglab(spm_filename, electrode_filename );
% 



event_code=options.fmri_gradient.event_code;
lpf=options.fmri_gradient.lpf;
L=options.fmri_gradient.L;
window=options.fmri_gradient.window;
strig=options.fmri_gradient.strig;


anc_chk=0;
tc_chk=0;
Slices=1;

trig_info = size(EEG.event,2);%Collect the complete list of events
evmarkers=[];
for k = 1:trig_info
    mrtriggers = strcmpi(event_code,EEG.event(k).value);
    if(mrtriggers == 1)
        evmarkers = [evmarkers; EEG.event(k).latency + 1]; %Collect the timing of the specific MR event
    end
    
end

Volumes=length(evmarkers);

if not(isempty(evmarkers))
    
 
    delta = evmarkers(2)-evmarkers(1); %Compute the repitition rate of the event
    
    %The below code is for removal of artifact from the 1st scanning pulse,
    %which is not present as a trigger event in the EEG data, hence we
    %computationally reconstruct it..
%     for k = 1:7
%     appendslice = evmarkers(1)-delta;
%     evmarkers = [appendslice;evmarkers];
%     end
    
    %Use the algorithm for artifact subtraction..
    
     EEG=fmrib_fastr(EEG,lpf,L,window,evmarkers,strig,anc_chk,tc_chk,Volumes,Slices);
   
     data = EEG.data;
     D(:,:,1) = data;
     
    D.save;
    
end