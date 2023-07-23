function pre_trigger = getPre_trigger(lenaTree)
% function pre_trigger = getPre_trigger(lenaTree)
%
%   Get the pre trigger time
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   pre_trigger ( double ) : pre trigger time
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
pre_triggerId = time_rangeElements(find(strcmp(names,'pre_trigger')));

% Check the  child was found :
if isempty( pre_triggerId )
    error( 'Can t find any pre_trigger parameter in the file' )
    return
end

% Get the pre_trigger content:
pre_triggerContents = get( lenaTree , pre_triggerId , 'contents' );

% Get the pre_trigger contents :
pre_triggerValue = get( lenaTree , pre_triggerContents , 'value' );

% Convert to double :
pre_trigger = str2double( pre_triggerValue );

return