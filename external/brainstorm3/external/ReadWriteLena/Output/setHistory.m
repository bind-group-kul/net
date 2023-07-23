function lenaTree = setHistory(lenaTree, element)
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


if nargin < 2
    error('Insufficient number of arguments.');
    return;
elseif nargin > 2
    error('To much arguments supplied.');
    return;
end

child = children( lenaTree , root(lenaTree) );

% Get the children names :
names = get( lenaTree , child , 'name' );

% Find the history id :
historyId = child(find(strcmp(names,'history')));

% Check the  child was found :
if isempty( historyId )
[ lenaTree , history_uid ] = add(lenaTree,root(lenaTree),'element','history');
else
    error('Description already contains a history element, delete it before any new assignement');
    return;
end

if iscell(element)
for cp=1:length(element)
    
          [lenaTree, history_elementId] = add(lenaTree, history_uid, 'element', 'history_element' );
          
          c=element{cp};
          lenaTree = add( lenaTree, history_elementId, 'chardata',  c);
            
   
end

else 

     [lenaTree, history_elementId] = add(lenaTree, history_uid, 'element', 'history_element' );
          
          c=element;
          lenaTree = add( lenaTree, history_elementId, 'chardata',  c);

end

% Get the history elements :
% historyElements = children( lenaTree , historyId );
% 
% % Get the history elements :
% historyContents = get( lenaTree , historyElements , 'contents' );
% 
% % Get the history contents :
% history = get( lenaTree , [ historyContents{:} ] , 'value' );

return