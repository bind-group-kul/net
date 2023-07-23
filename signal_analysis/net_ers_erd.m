
%% last version: 28.10.2013
%% last version: 07.11.2017 updated by Mingqi Zhao
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [tf_map,times_in_ms] = net_ers_erd(data,time_axis,events,options)

n_range=3;

Fs=1/(time_axis(2)-time_axis(1));

%positions based on newFs
pretrig   = round(Fs*options.pretrig/1000); 
posttrig  = round(Fs*options.posttrig/1000);
baseline  = round(Fs*options.baseline/1000);
vect=[baseline(1)-pretrig+1:baseline(2)-pretrig];

event_time = cat(1, events.time);

%delete those cannot be used
event_time(event_time+1.1*pretrig/Fs<1)=[];  %delete first several events that do not have enough time for pretrig
event_time(event_time+1.1*posttrig/Fs>size(data,2))=[]; %delete last several events that do not have enough time for posttrig

nf=size(data,1);  %frequency channel number
ntp=posttrig-pretrig+1; % time in sample points

ntrig=length(event_time); %number of triggers

epoched_data=zeros(ntrig,nf,ntp);

for i=1:ntrig
    [x,pos]=min(abs(time_axis-event_time(i)));
    interval=[pos+pretrig:pos+posttrig];
    if interval(1)>=1 && interval(end)<=length(time_axis) 
    mat=data(:,interval); %cut out the epch
%      bas=mean(mat(:,vect),2);
%      matx=100*(mat-bas*ones(1,ntp))./(bas*ones(1,ntp)); % definition of ERS/ERD, refer to https://doi.org/10.1016/S1388-2457(99)00141-8
    epoched_data(i,:,:)=mat; % conversion to percentage
    end
end

mean_pow = net_robustaverage(epoched_data,n_range);
%mean_pow=squeeze(mean(epoched_data,1));

bas=mean(mean_pow(:,vect),2);

tf_map=100*(mean_pow-bas*ones(1,ntp))./(bas*ones(1,ntp)); % definition of ERS/ERD, refer to https://doi.org/10.1016/S1388-2457(99)00141-8

times_in_ms=1000/Fs*[pretrig:posttrig]; %time_in_ms = 1000ms*[Ts*sample_point], Ts = 1/Fs

