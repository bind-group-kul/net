function original_ptx_filename = getOriginal_ptx_filename(lenaTree)
% function original_ptx_filename = getOriginal_ptx_filename(lenaTree)
%
%   Get the original ptx filename
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   original_ptx_filename ( string ) : original ptx filename
%

% Get the children ids :
child = children( lenaTree , root(lenaTree) );

% Get the children names :
names = get( lenaTree , child , 'name' );

% Find the original_ptx_filename id :
original_ptx_filenameId = child(find(strcmp(names,'original_ptx_filename')));

% Check the  child was found :
if isempty( original_ptx_filenameId )
    error( 'Can t find any original_ptx_filename parameter in the file' )
    return
end
% Get its content id :
contentId = get( lenaTree , original_ptx_filenameId , 'contents' );

% Get the original_ptx_filename value :
original_ptx_filename = get( lenaTree , contentId , 'value' );


return