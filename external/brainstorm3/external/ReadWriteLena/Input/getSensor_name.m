function sensor_name = getSensor_name(lenaTree,sensorIndex)
% function supersensor_name = getSupersensor_name(lenaTree,supersensorIndex)
%
%   Get a sensor name. The supersensorIndex is the position of the
%   supersensor in the header. The supersensor must contain only one
%   sensor, else an error is raised.
%
% Input :
%   lenaTree ( lenaTree object )
%   supersensorIndex ( double ) : index of the supersensor
%
% Output :
%   supersensor_name( string ) : name of the supersensor,
%

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
   sensor_name = '';
    return
end

% Get the sensor_range elements :
sensor_rangeElements = children( lenaTree , sensor_rangeId );

% Get the sensor_range children names :
names = get( lenaTree , sensor_rangeElements , 'name' );

% Find the sensor_samples id :
sensor_listId = sensor_rangeElements(find(strcmp(names,'sensor_list')));

% Check the  child was found :
if isempty( sensor_listId )
    warning( 'Can t find any sensor_samples parameter in the file' )
    sensor_name = '';
    return
end

% Get the sensor_samples elements :
sensor_listElements = children( lenaTree , sensor_listId );

% Check that provided supersensorIndex does exceed the number of
% sensor_samples elements :
if sensorIndex > length(sensor_listElements)
    warning('Provided supersensorIndex exceed the number of supersensors.')
    sensor_name = '';
    return
end


sensorContents=get(lenaTree,children(lenaTree,sensor_listElements(sensorIndex)));

% Get the supersensor children names :
sensorElements = children( lenaTree , sensor_listElements(sensorIndex) );
%names = get( lenaTree , sensorElements , 'name' );


% Find the sensor id :
%sensorId = sensorElements(find(strcmp(names,'sensor')));
%sensorId = Elements(find(strcmp(names,'sensor')));

% Check the  child was found, and is unique :
if isempty( sensorContents )
    warning( 'Can t find any sensor parameter in the file' )
    sensor_name = '';
    return
% elseif length(sensorId)>1
%     warning('The supersensor seems to contain more than one sensor')
%     sensor_name = '';
%     return
 end

% Get the sensor contents:
%sensorContents = children( lenaTree , sensorId );

% Give a default value to supersensor_name
sensor_name = '';

% Find the chardata element :


%sensor_uid=-1;
i=1;
if iscell(sensorContents)
    while (i<length(sensorContents)+1)
        if strcmp(sensorContents{i}.type,'chardata')
                    sensor_name=sensorContents{i}.value;
            return
        
        end
        i=i+1;
    end
else  if strcmp(sensorContents.type,'chardata')
                    sensor_name=sensorContents.value;
            return
    end
end

% for i = 1:length(sensorContents)
%     if strcmp(get(lenaTree,sensorContents{1,i},'type'),'chardata')
%         sensor_name = get(lenaTree,sensorContents(i),'value');
%     end
% end


return