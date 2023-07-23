function date = getDate(lenaTree)
% function date = getDate(lenaTree)
%
%   Get the date
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   date ( double ) : date
%

% Get the children ids :
child = children( lenaTree , root(lenaTree) );

% Get the children names :
names = get( lenaTree , child , 'name' );

% Find the date id :
dateId = child(find(strcmp(names,'date')));

% Check the  child was found :
if isempty( dateId )
    warning( 'Can t find any date parameter in the file' )
    date = '';
    return
end

% Get its content id :
contentId = get( lenaTree , dateId , 'contents' );

% Get the date value :
date = get( lenaTree , contentId , 'value' );

return