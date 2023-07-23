function  lenaTree= setData_offset(lenaTree,data_offset)
% function data_offset = getData_offset(lenaTree)
%
%   Get the data offset
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   data_offset ( double ) : data offset
%

% Get the children ids :
child = children( lenaTree , root(lenaTree) );

% Get the children names :
names = get( lenaTree , child , 'name' );

% Find the data_offset id :
data_offsetId = child(find(strcmp(names,'data_offset')));

% Check the  child was found :
if isempty( data_offsetId )
    %warning( 'Can t find any data_offset parameter in the file' )
     [lenaTree, data_offsetId] = add( lenaTree, root(lenaTree), 'element', 'data_offset' );
    lenaTree = add(lenaTree,data_offsetId,'chardata',data_offset);
    
else error( 'data_offset parameter already exist in the file' )

    return
end

% % Get its content id :
% contentId = get( lenaTree , data_offsetId , 'contents' );
% 
% % Get the data_offset value :
% data_offset_value = get( lenaTree , contentId , 'value' );
% 
% % Convert string to integer :
% data_offset = str2num( data_offset_value );

return