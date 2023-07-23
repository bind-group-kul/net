function data_type = getData_type(lenaTree)
% function data_type = getData_type(lenaTree)
%
%   Get the data type ( unsigned fixed, fixed or floating )
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   data_type ( string ) : data type
%

% Get the children ids :
child = children( lenaTree , root(lenaTree) );

% Get the children names :
names = get( lenaTree , child , 'name' );

% Find the data_type id :
data_typeId = child(find(strcmp(names,'data_type')));

% Check the  child was found :
if isempty( data_typeId )
    error( 'Can t find any data_type parameter in the file' )
    return
end
% Get its content id :
contentId = get( lenaTree , data_typeId , 'contents' );

% Get the data_type value :
data_type = get( lenaTree , contentId , 'value' );


return