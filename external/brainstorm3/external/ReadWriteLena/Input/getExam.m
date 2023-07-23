function exam = getExam(lenaTree)
% function exam = getExam(lenaTree)
%
%   Get the exam name
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   exam ( string ) : exam name
%

% Get the children ids :
child = children( lenaTree , root(lenaTree) );

% Get the children names :
names = get( lenaTree , child , 'name' );

% Find the exam id :
examId = child(find(strcmp(names,'exam')));

% Check the  child was found :
if isempty( examId )
    error( 'Can t find any exam parameter in the file' )
    return
end
% Get its content id :
contentId = get( lenaTree , examId , 'contents' );

% Get the exam value :
exam = get( lenaTree , contentId , 'value' );


return