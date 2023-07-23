function history = getHistory(lenaTree)
% function history = getHistory(lenaTree)
%
%   Get the history elements ( may be composed of many history elements )
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   history ( cell ) : each cell match with one history event
%

% Get the children ids :

history=[];
child = children( lenaTree , root(lenaTree) );

% Get the children names :
names = get( lenaTree , child , 'name' );

% Find the history id :
historyId = child(find(strcmp(names,'history')));

% Check the  child was found :
if isempty( historyId )
    warning( 'Can t find any history parameter in the file' )
    return
end

% Get the history elements :
historyElements = children( lenaTree , historyId );

% Get the history elements :
historyContents = get( lenaTree , historyElements , 'contents' );

% Get the history contents :
if iscell(historyContents)
history = get( lenaTree , [ historyContents{:} ] , 'value' );
else  history = get( lenaTree , [ historyContents ] , 'value' );
end
return