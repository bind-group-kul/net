function D = net_change_eventtime(D, timedelay)
% function D = net_change_eventtime(D, timedelay)
% description: change event time to tradeof time delay

event = events(D);

num_event = size(event,2);

if timedelay<1
    timedelay = timedelay*1000;
end

for i = 1:num_event
    event(i).time = event(i).time+timedelay;
end


D = events(D, [], event);
