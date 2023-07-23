function subject_id = getSubject_id(lenaTree)
% function subject_id = getSubject_id(lenaTree)
%
%   Get the subject id
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   subject_id ( double ) : subject id
%

% Get the children ids :
child = children( lenaTree , root(lenaTree) );

% Get the children names :
names = get( lenaTree , child , 'name' );

% Find the subject_id id :
subject_idId = child(find(strcmp(names,'subject_id')));

% Check the  child was found :
if isempty( subject_idId )
    error( 'Can t find any subject_id parameter in the file' )
    return
end

% Get its content id :
contentId = get( lenaTree , subject_idId , 'contents' );

% Get the subject_id value :
subject_id_value = get( lenaTree , contentId , 'value' );

% Convert string to integer :
subject_id = str2double( subject_id_value );

return