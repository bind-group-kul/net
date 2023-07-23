function data_size = getData_size(lenaTree)
% function data_size = getData_size(lenaTree)
%
%   Get the size of binary data ( 1, 4, 8 )
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   data_size ( double ) : data size
%

% Get the children ids :
child = children( lenaTree , root(lenaTree) );

% Get the children names :
names = get( lenaTree , child , 'name' );

% Find the data_size id :
data_sizeId = child(find(strcmp(names,'data_size')));

% Check the  child was found :
if isempty( data_sizeId )
    error( 'Can t find any data_size parameter in the file' )
    return
end

% Get its content id :
contentId = get( lenaTree , data_sizeId , 'contents' );

% Get the data_size value :
data_size_value = get( lenaTree , contentId , 'value' );

% Convert string to integer :
data_size = str2num( data_size_value );

return