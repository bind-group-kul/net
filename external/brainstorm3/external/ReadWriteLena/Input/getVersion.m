function version = getVersion(lenaTree)
% function version = getVersion(lenaTree)
%
%   Get the format version number.
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   version ( double ) : format version number
%

% Get the children ids :
child = children( lenaTree , root(lenaTree) );

% Get the children names :
names = get( lenaTree , child , 'name' );

% Find the version id :
versionId = child(find(strcmp(names,'version')));

% Check the version child was found :
if isempty(versionId)
    error( 'Can t find any version parameter in the file' )
    return
end

% Get its content id :
contentId = get( lenaTree , versionId , 'contents' );

% Get the version value :
version_value = get( lenaTree , contentId , 'value' );

% Convert string to integer :
version = str2double( version_value );

return