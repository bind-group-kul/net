function lenaTree = getExam(lenaTree, exam)
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
    [lenaTree, examId] = add( lenaTree, root(lenaTree), 'element', 'exam' );
    lenaTree = add(lenaTree,examId,'chardata',exam);

else error( 'exam parameter exists in the file' )
    return
end
% % Get its content id :
% contentId = get( lenaTree , examId , 'contents' );
% 
% % Get the exam value :
% exam = get( lenaTree , contentId , 'value' );


return