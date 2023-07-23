function supersensor_name = getSupersensor_name(lenaTree,supersensorIndex)
% function supersensor_name = getSupersensor_name(lenaTree,supersensorIndex)
%
%   Get a supersensor name. The supersensorIndex is the position of the
%   supersensor in the header. The supersensor must contain only one
%   sensor, else an error is raised.
%
% Input :
%   lenaTree ( lenaTree object )
%   supersensorIndex ( double ) : index of the supersensor
%
% Output :
%   supersensor_name( string ) : name of the supersensor
% doesn't handle the case of multiple sensors in a supersensor 

% Get the children ids :
child = children( lenaTree , root(lenaTree) );

% Get the children names :
names = get( lenaTree , child , 'name' );

% Find the description id :
descriptionId = child(find(strcmp(names,'description')));

% Check the  child was found :
if isempty( descriptionId )
    error( 'Can t find any description parameter in the file' )
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
    supersensor_name = '';
    return
end

% Get the sensor_range elements :
sensor_rangeElements = children( lenaTree , sensor_rangeId );

% Get the sensor_range children names :
names = get( lenaTree , sensor_rangeElements , 'name' );

% Find the sensor_samples id :
sensor_samplesId = sensor_rangeElements(find(strcmp(names,'sensor_samples')));

% Check the  child was found :
if isempty( sensor_samplesId )
    warning( 'Can t find any sensor_samples parameter in the file' )
    supersensor_name = '';
    return
end

% Get the sensor_samples elements :
sensor_samplesElements = children( lenaTree , sensor_samplesId );

% Check that provided supersensorIndex does exceed the number of
% sensor_samples elements :
if supersensorIndex > length(sensor_samplesElements)
    warning('Provided supersensorIndex exceed the number of supersensors.')
    supersensor_name = '';
    return
end

% Get the supersensor children names :
supersensorElements = children( lenaTree , sensor_samplesElements(supersensorIndex) );
names = get( lenaTree , supersensorElements , 'name' );


% Find the sensor id :
sensorId = supersensorElements(find(strcmp(names,'sensor')));

% Check the  child was found, and is unique :
if isempty( sensorId )
    warning( 'Can t find any sensor parameter in the file' )
    supersensor_name = '';
    return
elseif length(sensorId)>1
%    warning('The supersensor seems to contain more than one sensor')
 %   supersensor_name = '';
  %  return
end

% Get the sensor contents:
sensorContents = children( lenaTree , sensorId );

% Give a default value to supersensor_name
supersensor_name = '';

% Find the chardata element :
for i = 1:length(sensorContents)
    if strcmp(get(lenaTree,sensorContents(i),'type'),'chardata')
        supersensor_name{i} = get(lenaTree,sensorContents(i),'value');
    end
end


return