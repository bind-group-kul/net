%% function [D, bad_events, bad_channels] = net_epoch(D, pretrig, posttrig, eventinfo, bc)
%% description: epoching data
%%
%% last version: 28.10.2013
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function epoched_data = net_epoch(data,Fs,events,options)
        
% e.g. eventvalue = {'a' 'b'};


pretrig   = round(Fs*options.pretrig/1000);
posttrig  = round(Fs*options.posttrig/1000);

if not(isempty(options.baseline))
baseline  = round(Fs*options.baseline/1000);
vect=[baseline(1)-pretrig+1:baseline(2)-pretrig];
end



event_time = round(Fs.*cat(1, events.time));

%delete those cannot be used
event_time(event_time+pretrig<1)=[];  %delete first several events that do not have enough time for pretrig
event_time(event_time+posttrig>size(data,2))=[]; %delete last several events that do not have enough time for posttrig


nchan=size(data,1);
ntp=posttrig-pretrig;

ntrig=length(event_time);

epoched_data=zeros(ntrig,nchan,ntp);

for i=1:ntrig
    mat=data(:,event_time(i)+pretrig+1:event_time(i)+posttrig);
    if not(isempty(options.baseline))
        mat=mat-mean(mat(:,vect),2)*ones(1,ntp);
    end
    epoched_data(i,:,:)=mat;
end

