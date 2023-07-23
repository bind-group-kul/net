function tree=insertSimpleElements(tree,varargin)
%
% function tree=insertSimpleElement(tree,basic_element,basic_value)
%
% Insert 'basic_element' with chardata 'basic_value' in the root element of
% tree.
%
% Usage : Provide an xml tree, and couples of elements to insert in ( as a
% consequence, you need to provide an odd number of arguments )
%
%
%   Inputs :
%       - tree ( xmltree ) : xml object in which you want to insert an
%       element
%       - varargin ( couples of strings ) : for each couple, give first the
%       name of the element, and then the value to put into
%
%
% Example : tree=insertSimpleElements(tree,'version','1.0');
%
% See also : xmltree, createSimpleLENA, insertTimeRange, deleteLENAelement,
% copyLENAelement
%

% Author
%
% AB 19 12 2006
%
% LENA CNRS UPR640
%


if ~round((nargin/2)-floor(nargin/2))
    error('Wrong agrument number provided. See help insertSimpleElements for more informations')
else

    for i=1:(length(varargin)/2)-1
        % Add element :
        [ tree , basic_uid ] = add(tree,root(tree),'element',varargin{(i-1)*2+1});
        % Fill this element :
        tree = add(tree,basic_uid,'chardata',varargin{i*2});
    end

end

return
