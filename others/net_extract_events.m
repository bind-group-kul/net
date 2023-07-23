function [ time_matrix, event_struct ] = net_extract_events( events, event_tag )
%EXTRACT_EVENTS Summary of this function goes here
%   Detailed explanation goes here
    
    events_num = length(events);
    time_matrix = [];
    event_struct = [];
    for iter_event = 1:events_num
        if(strcmp(events(iter_event).value, event_tag))
            time_matrix = [time_matrix; events(iter_event).time];
            event_struct = [ event_struct; events(iter_event)];
        end
    end
end

