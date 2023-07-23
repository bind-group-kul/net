function dimensions_names = getDimensions_names(lenaTree)
% function dimensions_names = getDimensions_names(lenaTree)
%
%   Get the dimensions names
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   dimensions_names ( string ) : dimensions names
%

% Get the children ids :
child = children( lenaTree , root(lenaTree) );

% Get the children names :
names = get( lenaTree , child , 'name' );

% Find the description id :
descriptionId = child(find(strcmp(names,'description')));

% Check the  child was found :
if isempty( descriptionId )
    %error( 'Can t find any description parameter in the file' )
    %return
    dimensions_names=[];
    return;
end

% Get the description elements :
descriptionElements = children( lenaTree , descriptionId );


% Get the description children names :
dimensions_names = get( lenaTree , descriptionElements , 'name' );

return