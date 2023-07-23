function D = net_timedelay_correct(D, timedelay)
% function D = net_change_eventtime(D, timedelay)
% description: change event time to tradeof time delay
% timedelay = 36 or 0.036;
% last version: 22.01.2015 by QL

event = D.triggers;

num_event = size(event,2);

if timedelay>1
   timedelay = timedelay/1000;  % change ms into s
end

event_new=event;

max_length=size(D,2)/fsample(D);

for i = 1:num_event
    if not(isempty(strfind(lower(event(i).type),'stimulus'))) || not(isempty(strfind(lower(event(i).type),'din')))
        tt=event(i).time-timedelay;
        if tt<0
            tt=0;
        end
        if tt>max_length
            tt=max_length;
        end 
        event_new(i).time = tt;  % event(i).time+timedelay
    end
end


D.triggers=event_new;

D.save;