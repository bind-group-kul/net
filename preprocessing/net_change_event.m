% change event value

event = events(D);
num_event = size(event,2);

eventvalue = [];
eventtype = [];
for i = 1:num_event
    eventvalue{i} = event(i).value;
    eventtype{i} = event(i).type;
end


left_trigger = find( strcmp(eventvalue, 'DI50'));
for i=1:length(left_trigger)
    event(left_trigger(i)+1).value = 'left';
end
right_trigger = find( strcmp(eventvalue, 'D100'));
for i=1:length(left_trigger)
    event(right_trigger(i)+1).value = 'right';
end


D = events(D, [], event);
D.save
