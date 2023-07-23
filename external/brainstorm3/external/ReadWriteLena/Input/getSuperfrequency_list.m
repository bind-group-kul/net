function superfrequency_list = getSuperfrequency_list(lenaTree)
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
frequency_rangeId = descriptionElements(find(strcmp(names,'frequency_range')));

% Check the  child was found :
if isempty( frequency_rangeId )
    warning( 'Can t find any frequency_range parameter in the file' )
    superfrequency_name = '';
    return
end

% Get the sensor_range elements :
frequency_rangeElements = children( lenaTree , frequency_rangeId );

% Get the sensor_range children names :
names = get( lenaTree , frequency_rangeElements , 'name' );

% Find the sensor_samples id :
frequency_samplesId = frequency_rangeElements(find(strcmp(names,'frequency_samples')));

% Check the  child was found :
if isempty( frequency_samplesId )
    warning( 'Can t find any frequency_samples parameter in the file' )
    superfrequency_name = '';
    return
end

% Get the frequency_samples elements :
frequency_samplesElements = children( lenaTree , frequency_samplesId );
% Give a default value to superfrequency_list
superfrequency_list = {};

for i_sens = 1:length(frequency_samplesElements)
    % Get the superfrequency children names :
    superfrequencyElements = children( lenaTree , frequency_samplesElements(i_sens) );
    names = get( lenaTree , superfrequencyElements , 'name' );


    % Find the frequency id :
    frequencyId = superfrequencyElements(find(strcmp(names,'frequency')));

    % Check the  child was found, and is unique :
    if isempty( frequencyId )
        warning( 'Can t find any frequency parameter in the file' )
        superfrequency_name = '';
        return
%     elseif length(frequencyId)>1
%         warning('The superfrequency seems to contain more than one frequency')
%         superfrequency_name = '';
%         return
    end

    % Get the frequency contents:
    frequencyContents = children( lenaTree , frequencyId );


    % Find the chardata element :
    for i = 1:length(frequencyContents)
        if strcmp(get(lenaTree,frequencyContents(i),'type'),'chardata')
            superfrequency_list{i_sens,i} = str2num(get(lenaTree,frequencyContents(i),'value'));
        end
    end
end

return