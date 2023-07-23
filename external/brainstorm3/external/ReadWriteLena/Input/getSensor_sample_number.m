function sensor_sample_number = getSensor_sample_number(lenaTree)
% function sensor_sample_number = getSensor_sample_number(lenaTree)
%
%   Get the sensor sample number
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   sensor_sample_number ( double ) : sensor sample number
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
    sensor_sample_number = '';
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
    sensor_sample_number = '';
    return
end

% Get the sensor_range elements :
sensor_rangeElements = children( lenaTree ,  sensor_rangeId);

% Get the sensor_range children names :
names = get( lenaTree , sensor_rangeElements , 'name' );

% Find the sensor_samples id :
sensor_samplesId = sensor_rangeElements(find(strcmp(names,'sensor_samples')));

% Check the  child was found :
if isempty( sensor_samplesId )
    warning( 'Can t find any sensor_samples parameter in the file' )
    sensor_sample_number = '';
    return
end

% Get the sensor_samples content:
sensor_samplesContents = get( lenaTree , sensor_samplesId , 'contents' );

% Get the sensor_samples contents size :
sensor_sample_number = length( sensor_samplesContents );

return