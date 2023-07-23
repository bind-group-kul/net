function lenaTree = lenaTree(file_name)
% function lenaTree = lenaTree(file_name)
% Constructor of the lenaTree class
%
% Inputs :
%   file_name ( string ) : name of the input lena Format file
%le, with 
% Outputs :
%   lenaTree ( xmltree ) : data tree extracted from file
%
%____________________________________________________________
%
% This is the constructor of the lenaXML objects, which allows
% to read / write lena format files. If the file exists,
% lenaTree is the xmltree object corresponding. If it doesn't,
% it creates a minimalistic lena file.
%____________________________________________________________
%
% seealso : xmltree

% Test if files exist or not :
if exist( file_name )==0

    % Create an xml tree
    try
        lenaTree = xmltree;
    catch
        error('An error occurred while using xmltree : please verify your xmltree installation');
        return
    end

    % Set the root element to 'LENA' :
    lenaTree = set(lenaTree,root(lenaTree),'name','LENA');

    % Add mandatory arguments :
    [ lenaTree , format_uid ] = add(lenaTree,root(lenaTree),'element','data_format');
    lenaTree = add(lenaTree,format_uid,'chardata',' ');

    [ lenaTree , type_uid ] = add(lenaTree,root(lenaTree),'element','data_type');
    lenaTree = add(lenaTree,type_uid,'chardata',' ');

    [ lenaTree , size_uid ] = add(lenaTree,root(lenaTree),'element','data_size');
    lenaTree = add(lenaTree,size_uid,'chardata',' ');

    [lenaTree, entry_uid] = add( lenaTree, root(lenaTree), 'element', 'description' );

    % Check if file_name contains the .lena extension, if not add it : 
    if ~strcmp(file_name(end-4:end),'.lena')
       strcat( file_name , '.lena' );
    end

    % Save to file
    save(lenaTree,file_name);
    
elseif exist( file_name )==2

    lenaTree = xmltree(file_name);
    
else
    error('A problem occurred with the lena file name');
    return
end

return

