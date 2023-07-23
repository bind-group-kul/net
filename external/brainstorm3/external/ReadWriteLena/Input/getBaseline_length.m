function baseline_length = getBaseline_length(lenaTree)
% function baseline_length = getBaseline_length(lenaTree)
%
%   Get the baseline length time
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   baseline_length ( double ) : baseline length time
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
baseline_lengthId = time_rangeElements(find(strcmp(names,'baseline_length')));

% Check the  child was found :
if isempty( baseline_lengthId )
    error( 'Can t find any baseline_length parameter in the file' )
    return
end

% Get the baseline_length content:
baseline_lengthContents = get( lenaTree , baseline_lengthId , 'contents' );

% Get the baseline_length contents :
baseline_lengthValue = get( lenaTree , baseline_lengthContents , 'value' );

% Convert to double :
baseline_length = str2double( baseline_lengthValue );

return