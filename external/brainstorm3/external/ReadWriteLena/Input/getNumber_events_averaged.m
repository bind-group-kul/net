function number_events_averaged = getNumber_events_averaged(lenaTree)
% function number_events_averaged = getNumber_events_averaged(lenaTree)
%
%   Get the number of events averaged ( this means the file is resulting from an average )
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   number_events_averaged ( double ) : data offset
%

% Get the children ids :
child = children( lenaTree , root(lenaTree) );

% Get the children names :
names = get( lenaTree , child , 'name' );

% Find the number_events_averaged id :
number_events_averagedId = child(find(strcmp(names,'number_events_averaged')));

% Check the  child was found :
if isempty( number_events_averagedId )
    warning( 'Can t find any number_events_averaged parameter in the file' )
    number_events_averaged = '';
    return
end

% Get its content id :
contentId = get( lenaTree , number_events_averagedId , 'contents' );

% Get the number_events_averaged value :
number_events_averaged_value = get( lenaTree , contentId , 'value' );

% Convert string to integer :
number_events_averaged = str2double( number_events_averaged_value );

return