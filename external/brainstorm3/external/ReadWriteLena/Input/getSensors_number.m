function sensors_number = getSensors_number(lenaTree)
% function sensors_number = getSensor_sample_number(lenaTree)
%
%   Get the sensors  number
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   sensor_number ( double ) : sensor sample number
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
    sensors_number = '';
    return
end

% Get the description elements :
descriptionElements = children( lenaTree , descriptionId );


% Get the description children names :
names = get( lenaTree , descriptionElements , 'name' );

% Find the time_samples id :
sensor_rangeId = descriptionElements(find(strcmp(names,'sensor_range')));

% Check the  child was found :
if isempty( sensor_rangeId )
    warning( 'Can t find any sensor_range parameter in the file' )
    sensors_number = '';
    return
end

% Get the sensor_range elements :
sensor_rangeElements = children( lenaTree ,  sensor_rangeId);

% Get the sensor_range children names :
names = get( lenaTree , sensor_rangeElements , 'name' );

% Find the sensor_samples id :
sensor_listId = sensor_rangeElements(find(strcmp(names,'sensor_list')));

% Check the  child was found :
if isempty( sensor_listId )
    warning( 'Can t find any sensor_samples parameter in the file' )
    sensors_number = '';
    return
end

% Get the sensor_samples content:
sensor_listContents = get( lenaTree , sensor_listId , 'contents' );

% Get the sensor_samples contents size :
sensors_number = length( sensor_listContents );

return