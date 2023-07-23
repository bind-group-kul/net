function mesh_filename = getMesh_filename(lenaTree)
% function mesh_filename = getMesh_filename(lenaTree)
%
%   Get the mesh file name associated to sensor range to project and represent data
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   mesh_filename ( string ) : mesh file name
%

% Get the children ids :
child = children( lenaTree , root(lenaTree) );

% Get the children names :
names = get( lenaTree , child , 'name' );

% Find the mesh_filename id :
mesh_filenameId = child(find(strcmp(names,'mesh_filename')));

% Check the  child was found :
if isempty( mesh_filenameId )
    error( 'Can t find any mesh_filename parameter in the file' )
    return
end
% Get its content id :
contentId = get( lenaTree , mesh_filenameId , 'contents' );

% Get the mesh_filename value :
mesh_filename = get( lenaTree , contentId , 'value' );


return