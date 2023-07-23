function supersensor_scale = getSupersensor_scale(lenaTree,supersensorIndex)
% function supersensor_scale = getSupersensor_scale(lenaTree,supersensorIndex)
%
%   Get a supersensor scale
%
% Input :
%   lenaTree ( lenaTree object )
%   supersensorIndex ( double ) : index of the supersensor, or
%   list of index
%
% Output :
%   supersensor_scale ( double ) : scale of the supersensor
%

% Get the children ids :
supersensor_scale=[];
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
    supersensor_scale = '';
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
    supersensor_scale = '';
    return
end

% Get the sensor_samples elements :
sensor_samplesElements = children( lenaTree , sensor_samplesId );

% Check that provided supersensorIndex does exceed the number of
% sensor_samples elements :
bad_indexes = find(supersensorIndex > length(sensor_samplesElements));
if ~isempty(bad_indexes)
    warning('Provided supersensorIndex(es) exceed the number of supersensors.')
    good_indexes = find(supersensorIndex <= length(sensor_samplesElements));
    if isempty(good_indexes)
        supersensor_scale = '';
    else
        supersensorIndex = good_indexes;
    end

    return
end

% Get the supersensor attributes :
supersensorAttributes = get( lenaTree , sensor_samplesElements(supersensorIndex) , 'attributes');

if length(supersensorIndex)==1
    supersensor_scale=1;
    for i = 1:length(supersensorAttributes)
        if strcmp(supersensorAttributes{i}.key,'scale');
            supersensor_scale=str2double(supersensorAttributes{i}.val);
        end
    end
else
    supersensor_scale=ones(1,length(supersensorIndex));
    for j = 1:length(supersensorIndex)
        for i = 1:length(supersensorAttributes{j})
            if strcmp(supersensorAttributes{j}{i}.key,'scale');
                supersensor_scale(j)=str2double(supersensorAttributes{j}{i}.val);
            end
        end

    end
end
    
    
return