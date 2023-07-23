function  setData_filename(lenaTree,lena_file,data_filename  )
% function data_filename = getData_filename(lenaTree,lena_file)
%
%   Try to get the datafile_name from lenaTree. If lena_file is provided,
%   return the data file name with full path. If no matching field exists
%   in the lenaTree, construct it from lena_file name.
%
% Input :
%   lenaTree ( lenaTree object )
%   lena_file ( string ) : name of lena header file
%   data_filename ( string ) : data file name
%

[lena_path,lena_name]=fileparts(lena_file);


% Get the children ids :
child = children( lenaTree , root(lenaTree) );

% Get the children names :
names = get( lenaTree , child , 'name' );

if isempty(names)
    [lenaTree, data_filenameId] = add( tree, root(lenaTree), 'element', 'name' );
    set( lenaTree , data_filenameId , 'value',data_filename );
    % Get the data_filename value :
    set( lenaTree , contentId , 'value' );
    
else
    error('Description already contains a name element, delete it before any new assignement');
    return;
end

% Find the data_filename id :
data_filenameId = child(find(strcmp(names,'data_filename')));

% Check the data_filename child was found :
if isempty( data_filenameId )
    warning( 'Can t find any data_filename parameter in the file : I try to construct it from lena file name ...' )
    data_filename = strcat(lena_name,'.bin')
else
    % Get its content id :
    contentId = get( lenaTree , data_filenameId , 'contents' );
    % Get the data_filename value :
    data_filename = get( lenaTree , contentId , 'value' );
end

if nargin>1
    data_filename = fullfile(lena_path,data_filename)
end

return