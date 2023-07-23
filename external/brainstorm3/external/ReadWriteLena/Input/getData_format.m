function data_format = getData_format(lenaTree)
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
    error( 'Can t find any data_format parameter in the file' )
    return
end
% Get its content id :
contentId = get( lenaTree , data_formatId , 'contents' );

% Get the data_format value :
data_format = get( lenaTree , contentId , 'value' );


return