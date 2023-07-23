function baseline_start = getBaseline_start(lenaTree)
% function baseline_start = getBaseline_start(lenaTree)
%
%   Get the baseline start time
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   baseline_start ( double ) : baseline start time
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
    error( 'Can t find any time_range parameter in the file' )
    return
end

% Get the time_range elements :
time_rangeElements = children( lenaTree ,  time_rangeId);

% Get the time_range children names :
names = get( lenaTree , time_rangeElements , 'name' );

% Find the time id :
baseline_startId = time_rangeElements(find(strcmp(names,'baseline_start')));

% Check the  child was found :
if isempty( baseline_startId )
    error( 'Can t find any baseline_start parameter in the file' )
    return
end

% Get the baseline_start content:
baseline_startContents = get( lenaTree , baseline_startId , 'contents' );

% Get the baseline_start contents :
baseline_startValue = get( lenaTree , baseline_startContents , 'value' );

% Convert to double :
baseline_start = str2double( baseline_startValue );

return