function frequency_samples_number = getFrequency_samples_number(lenaTree)
% function frequency_sample_number = getfrequency_sample_number(lenaTree)
%
%   Get the frequency sample number
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   frequency_sample_number ( double ) : frequency sample number
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
    frequency_sample_number = '';
    return
end

% Get the description elements :
descriptionElements = children( lenaTree , descriptionId );


% Get the description children names :
names = get( lenaTree , descriptionElements , 'name' );

% Find the time_samples id :
frequency_rangeId = descriptionElements(find(strcmp(names,'frequency_range')));

% Check the  child was found :
if isempty( frequency_rangeId )
    warning( 'Can t find any frequency_range parameter in the file' )
    frequency_sample_number = '';
    return
end

% Get the frequency_range elements :
frequency_rangeElements = children( lenaTree ,  frequency_rangeId);

% Get the frequency_range children names :
names = get( lenaTree , frequency_rangeElements , 'name' );

% Find the frequency_samples id :
frequency_samplesId = frequency_rangeElements(find(strcmp(names,'frequency_samples')));

% Check the  child was found :
if isempty( frequency_samplesId )
    warning( 'Can t find any frequency_samples parameter in the file' )
    frequency_sample_number = '';
    return
end

% Get the frequency_samples content:
frequency_samplesContents = get( lenaTree , frequency_samplesId , 'contents' );

% Get the frequency_samples contents size :
frequency_samples_number = length( frequency_samplesContents );

return
