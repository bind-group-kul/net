function data_filename = getData_filename(lenaTree,lena_file, new)
% function data_filename = getData_filename(lenaTree,lena_file)
%
%   Try to get the datafile_name from lenaTree. If lena_file is provided,
%   return the data file name with full path. If no matching field exists
%   in the lenaTree, construct it from lena_file name.
%
% Input :
%   lenaTree ( lenaTree object )
%   lena_file ( string ) : name of lena header file
%
% Output :
%   data_filename ( string ) : data file name
%



 if nargin <3
   new = false;
 end

[lena_path,lena_name]=fileparts(lena_file);


% Get the children ids :
child = children( lenaTree , root(lenaTree) );

% Get the children names :
names = get( lenaTree , child , 'name' );

% Find the data_filename id :
data_filenameId = child(find(strcmp(names,'data_filename')));
data_filename = '';

% Check the data_filename child was found :
if ~isempty( data_filenameId )
    % Get its content id :
    contentId = get( lenaTree , data_filenameId , 'contents' );
    % Get the data_filename value :
    data_filename = get( lenaTree , contentId , 'value' );
end
% If file name was not found: Try data file with DATA extension
if isempty(data_filename) || ~exist(data_filename, 'file')
    data_filename = fullfile(lena_path, [lena_name, '.data']);
end
% If file name was not found: Try data file with BIN extension
if isempty(data_filename) || ~exist(data_filename, 'file')
    data_filename = fullfile(lena_path, [lena_name, '.bin']);
end

% if nargin>1
%     data_filename = fullfile(lena_path,data_filename);
% end

