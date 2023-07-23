function mesh_complement_filename = getMesh_complement_filename(lenaTree)
% function mesh_complement_filename = getMesh_complement_filename(lenaTree)
%
%   Get the complement mesh relative to sensor range with predefined color
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   mesh_complement_filename ( string ) : complement mesh file name
%

% Get the children ids :
child = children( lenaTree , root(lenaTree) );

% Get the children names :
names = get( lenaTree , child , 'name' );

% Find the mesh_complement_filename id :
mesh_complement_filenameId = child(find(strcmp(names,'mesh_complement_filename')));

% Check the  child was found :
if isempty( mesh_complement_filenameId )
    error( 'Can t find any mesh_complement_filename parameter in the file' )
    return
end
% Get its content id :
contentId = get( lenaTree , mesh_complement_filenameId , 'contents' );

% Get the mesh_complement_filename value :
mesh_complement_filename = get( lenaTree , contentId , 'value' );


return