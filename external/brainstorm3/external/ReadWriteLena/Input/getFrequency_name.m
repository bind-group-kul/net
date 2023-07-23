function frequency_value = getFrequency_name(lenaTree,frequencyIndex)
% function supersensor_name = getFrequency_name(lenaTree,frequencyIndex)
%
%   Get a frequency value. The frequencyIndex is the position of the
%   frequency in the header. 
%
% Input :
%   lenaTree ( lenaTree object )
%   superfrequencyIndex ( double ) : index of the superfrequency
%
% Output :
%   frequency_value( double ) : name of the superfrequency
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

% Find the frequency_range id :
frequency_rangeId = descriptionElements(find(strcmp(names,'frequency_range')));

% Check the  child was found :
if isempty( frequency_rangeId )
    warning( 'Can t find any frequency_range parameter in the file' )
    frequency_value = '';
    return
end

% Get the frequency_range elements :
frequency_rangeElements = children( lenaTree , frequency_rangeId );

% Get the frequency_range children names :
names = get( lenaTree , frequency_rangeElements , 'name' );

% Find the frequency_list id :
frequency_listId = frequency_rangeElements(find(strcmp(names,'frequency_list')));

% Check the  child was found :
if isempty( frequency_listId )
    warning( 'Can t find any frequency_list parameter in the file' )
    frequency_value = '';
    return
end

% Get the frequency elements :
frequency_Elements = children( lenaTree , frequency_listId );

% Check that provided frequencyIndex does exceed the number of
% frequency_elements :
if frequencyIndex > length(frequency_Elements)
    warning('Provided frequency index exceed the number of  frequencies.')
    frequency_value = '';
    return
end

% Get the frequency children names :
frequency = children( lenaTree , frequency_Elements(frequencyIndex) );
str_value = get( lenaTree , frequency , 'value' );

frequency_value = str2double( str_value  );

return
