function lenaTree=setData_format(lenaTree,data_format)
% function data_format = getData_format(lenaTree)
%
%   Get the data format ( LittleEndian or BigEndian )
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   data_format ( string ) : data format
%

% Get the children ids :
child = children( lenaTree , root(lenaTree) );

% Get the children names :
names = get( lenaTree , child , 'name' );

% Find the data_format id :
data_formatId = child(find(strcmp(names,'data_format')));

% Check the  child was found :
if isempty( data_formatId )
    [lenaTree, data_formatId] = add( lenaTree, root(lenaTree), 'element', 'data_format' );
    lenaTree = add(lenaTree,data_formatId,'chardata',data_format);
    
else
    return;
end
% Get its content id :
%contentId = get( lenaTree , data_formatId , 'contents' );

% Get the data_format value :
%data_format = get( lenaTree , contentId , 'value' );


return