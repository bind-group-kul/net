function frequencies = getFrequencies(lenaTree)
% function frequencies = getfrequencies(lenaTree)
%
%   Get the frequencies
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   frequencies ( double ) : matrix of frequency samples
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
    frequencies = [];
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
    frequencies=[];
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
    frequencies=[];
    return
end


% find frequencies, assuming each super frequency contains only 1
% frequency ( ie we search all chardata elements )

frequencies_char = get(lenaTree,find(lenaTree, frequency_samplesId,'type','chardata'),'value');
if iscell(frequencies_char)
frequencies = zeros(1,length(frequencies_char));
for i=1:length(frequencies_char)
    frequencies(i)=str2num(frequencies_char{i});
end
else  frequencies=str2num(frequencies_char);
end

return
