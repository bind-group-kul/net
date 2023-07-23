%% Purpose -- Perform removal of gradient artifact induced by the scanning pulse in the EEG data..
% 1. Compute the timing of the events(MR triggers)
% 2. Select only the events relevant for gradient artifact and the EEG
% channel data
% 3. Supply them to the artefact subtraction algorithm

function Dtemp = net_rmgradientartifact(Dtemp,options)

event_code=options.event_code;
interpol=options.interpol;
pretrig=options.pretrig;
weighting=options.weighting;
low_correlation=options.low_correlation;
max_shift=options.max_shift;
num_epochs=options.num_epochs;

trig_info = events(Dtemp);%Collect the complete list of events
evmarkers=[];
for k = 1:length(trig_info)
    mrtriggers = strcmpi(event_code,trig_info(1,k).type);
    if(mrtriggers == 1)
        evmarkers = [evmarkers; trig_info(k).time*1000 + 1]; %Collect the timing of the specific MR event
    end
    
end

if not(isempty(evmarkers))
    
    sel=selectchannels(Dtemp,'EEG');
    data=Dtemp(sel,:,:); %Use only the EEG data
    delta = evmarkers(2)-evmarkers(1); %Compute the repitition rate of the event
    
    %The below code is for removal of artifact from the 1st scanning pulse,
    %which is not present as a trigger event in the EEG data, hence we
    %computationally reconstruct it..
    for k = 1:7
    appendslice = evmarkers(1)-delta;
    evmarkers = [appendslice;evmarkers];
    end
    
    aftercorr=zeros(size(data));
    %Use the algorithm for artifact subtraction..
    
    for i=1:size(data,1)
        fprintf('\n...Channel %d is being corrected for artefact...\n', i)
        
        [aftercorr(i,:),~,~,~]=net_itas(data(i,:),evmarkers,interpol,[pretrig delta],fsample(Dtemp),weighting,length(evmarkers)-1,low_correlation,max_shift,num_epochs);
    end
    
    Dtemp(sel,:,:)=aftercorr;
    
    Dtemp.save;
    
end