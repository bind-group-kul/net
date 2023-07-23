function time_samples = getTime_samples(lenaTree)
% function time_samples = getTime_samples(lenaTree)
%
%   Get the time sample number
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   time_samples ( double ) : time sample number
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

% Find the time_samples id :
time_rangeId = descriptionElements(find(strcmp(names,'time_range')));

% Check the  child was found :
if isempty( time_rangeId )
    warning( 'Can t find any time_range parameter in the file' )
    time_samples = '';
    return
end

% Get the time_range elements :
time_rangeElements = children( lenaTree ,  time_rangeId);

% Get the time_range children names :
names = get( lenaTree , time_rangeElements , 'name' );

% Find the time id :
time_samplesId = time_rangeElements(find(strcmp(names,'time_samples')));

% Check the  child was found :
if isempty( time_samplesId )
    warning( 'Can t find any time_samples parameter in the file' )
    time_samples = '';
    return
end

% Get the time_samples content:
time_samplesContents = get( lenaTree , time_samplesId , 'contents' );

% Get the time_samples contents :
time_samplesValue = get( lenaTree , time_samplesContents , 'value' );

% Convert to double :
time_samples = str2double( time_samplesValue );

return