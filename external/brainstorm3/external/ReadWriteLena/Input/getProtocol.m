function protocol = getProtocol(lenaTree)
% function protocol = getProtocol(lenaTree)
%
%   Get the protocol name
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   protocol ( string ) : protocol name
%

% Get the children ids :
child = children( lenaTree , root(lenaTree) );

% Get the children names :
names = get( lenaTree , child , 'name' );

% Find the protocol id :
protocolId = child(find(strcmp(names,'protocol')));

% Check the  child was found :
if isempty( protocolId )
    error( 'Can t find any protocol parameter in the file' )
    return
end
% Get its content id :
contentId = get( lenaTree , protocolId , 'contents' );

% Get the protocol value :
protocol = get( lenaTree , contentId , 'value' );


return