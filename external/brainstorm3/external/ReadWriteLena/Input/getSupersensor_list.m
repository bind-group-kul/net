function supersensor_list = getSupersensor_list(lenaTree)
%function supersensor_list = getSupersensor_list()
% function supersensor_name = getSupersensor_list(lenaTree)
%
%   Get the list of all supersensor names. 
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   supersensor_list( cell ) : list of the supersensors
%

% Get the children ids :

%lenafile='/home/Data/CORR_UNAWARE_avg.lena';
%if strcmp(class(lenafile),'xmltree')
 % lenaTree = lenatree(lenafile);
%end

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
% Give a default value to supersensor_list
supersensor_list = {};

for i_sens = 1:length(sensor_samplesElements)
    % Get the supersensor children names :
    supersensorElements = children( lenaTree , sensor_samplesElements(i_sens) );
    names = get( lenaTree , supersensorElements , 'name' );


    % Find the sensor id :
    sensorId = supersensorElements(find(strcmp(names,'sensor')));

    % Check the  child was found, and is unique :
    if isempty( sensorId )
        warning( 'Can t find any sensor parameter in the file' )
        supersensor_name = '';
        return
%     elseif length(sensorId)>1
%         warning('The supersensor seems to contain more than one sensor')
%         supersensor_name = '';
%         return
    end

    % Get the sensor contents:
    sensorContents = children( lenaTree , sensorId );


    % Find the chardata element :
    for i = 1:length(sensorContents)
        if strcmp(get(lenaTree,sensorContents(i),'type'),'chardata')
            supersensor_list{i_sens,i} = get(lenaTree,sensorContents(i),'value');
        end
    end
end

return