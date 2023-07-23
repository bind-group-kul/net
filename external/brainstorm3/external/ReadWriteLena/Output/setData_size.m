function  lenaTree= setData_size(lenaTree,data_size)
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
    
[lenaTree, data_sizeId] = add( lenaTree, root(lenaTree), 'element', 'data_size' );
    lenaTree = add(lenaTree,data_sizeId,'chardata',data_size);
    
else error( 'data_offset parameter already exist in the file' )

    return
end

% % Get its content id :
% contentId = get( lenaTree , data_sizeId , 'contents' );
% 
% % Get the data_size value :
% data_size_value = get( lenaTree , contentId , 'value' );
% 
% % Convert string to integer :
% data_size = str2num( data_size_value );

return