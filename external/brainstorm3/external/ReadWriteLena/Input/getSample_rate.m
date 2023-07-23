function sample_rate = getSample_rate(lenaTree)
% function sample_rate = getSample_rate(lenaTree)
%
%   Get the time sample rate
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   sample_rate ( double ) : time sample rate
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

% Find the time id :
time_rangeId = descriptionElements(find(strcmp(names,'time_range')));

% Check the  child was found :
if isempty( time_rangeId )
    warning( 'Can t find any time_range parameter in the file' )
    sample_rate = '';
    return
end

% Get the time_range elements :
time_rangeElements = children( lenaTree ,  time_rangeId);

% Get the time_range children names :
names = get( lenaTree , time_rangeElements , 'name' );

% Find the sample_rate id :
sample_rateId = time_rangeElements(find(strcmp(names,'sample_rate')));

% Check the  child was found :
if isempty( sample_rateId )
    warning( 'Can t find any sample_rate parameter in the file' )
    sample_rate = '';
    return
end

% Get the sample_rate content:
sample_rateContents = get( lenaTree , sample_rateId , 'contents' );

% Get the sample_rate contents :
sample_rateValue = get( lenaTree , sample_rateContents , 'value' );

% Convert to double :
sample_rate = str2double( sample_rateValue );

return