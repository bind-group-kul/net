function sensor_coil_number = getSensor_coil_number(lenaTree,sensor_name)
% function sensor_coil_number = getSensor_coil_number(lenaTree,sensor_name)
%
%   Get the sensor coils number
%
% Input :
%   lenaTree ( lenaTree object )
%   sensor_name ( string ) : name of the sensor
%
% Output :
%   sensor_coil_number ( double ) : sensor coils number
%

% Get the children ids :
child = children( lenaTree , root(lenaTree) );

% Get the children names :
names = get( lenaTree , child , 'name' );

% Find the description id :
descriptionId = child(find(strcmp(names,'description')));

% Check the  child was found :
if isempty( descriptionId )
    warning( 'Can t find any description parameter in the file' )
    sensor_coil_number = '';
    return
end

% Get the description elements :
descriptionElements = children( lenaTree , descriptionId );


% Get the description children names :
names = get( lenaTree , descriptionElements , 'name' );

% Find the sensor_range id :
sensor_rangeId = descriptionElements(find(strcmp(names,'sensor_range')));

% Check the  child was found :
if isempty( sensor_rangeId )
    warning( 'Can t find any sensor_range parameter in the file' )
    sensor_coil_number = '';
    return
end

% Get the sensor_range elements :
sensor_rangeElements = children( lenaTree , sensor_rangeId );

% Get the sensor_range children names :
names = get( lenaTree , sensor_rangeElements , 'name' );

% Find the sensor_list id :
sensor_listId = sensor_rangeElements(find(strcmp(names,'sensor_list')));

% Check the  child was found :
if isempty( sensor_listId )
    warning( 'Can t find any sensor_list parameter in the file' )
    sensor_coil_number = '';
    return
end

% Get the sensor_list elements :
sensor_samplesElements = children( lenaTree , sensor_listId );

% Find the sensor which name is sensor_name

elements=get(lenaTree,children(lenaTree,sensor_samplesElements));
sensor_uid=-1;
i=1;
while (sensor_uid<0)&(i<length(elements)+1)
    if strcmp(elements{i}.type,'chardata')
        if strcmp(elements{i}.value,sensor_name)
            sensor_uid=elements{i}.parent;
        end
    end
    i=i+1;
end

if sensor_uid<0
    error('Given sensor name doesn t seem to exist')
    return
end

% Get the coils id :
sensor_contents=get(lenaTree,children(lenaTree,sensor_uid));

sensor_coil_number=0;
if length(sensor_contents)>1
    for i=1:length(sensor_contents)
        if strcmp(sensor_contents{i}.type,'element')
            if strcmp(sensor_contents{i}.name,'coil')
                sensor_coil_number=sensor_coil_number+1;
            end
        end
    end
else
    if strcmp(sensor_contents.type,'element')
        if strcmp(sensor_contents.name,'coil')
            sensor_coil_number=sensor_coil_number+1;
        end
    end
end

return