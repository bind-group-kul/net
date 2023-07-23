function tree=insertDataBlocksRange(tree,data_blocks)
% function insertTimeRange(tree,time_samples,sample_rate,pre_trigger)
%
%   Insert a frequency range dimension in a xml tree, which will be used for
%   lena datas.
%
% Inputs :
%
%   - tree : an xmltree element
%   - frequencyList ( float ) : frequency values
%   - frequencySamples (float ) : 2-Dim Array of frequency samples values
%       -First dimension: SuperFrequencies
%       -Second dimension: frequency samples values for each super frequency 
%
% Ouputs :
%
%   - tree : xmltree with added informations
%
% See also : createSimpleLENA, insertSimpleElements,deleteLENAelement,copyLENAelement
%
%
% Lydia Yahia  18 02 2008
%
% LENA CNRS UPR640
%

if nargin < 2
    error('Insufficient number of arguments.');
    return;
elseif nargin > 2
    error('To much arguments supplied.');
    return;
end


% Find description element, or create it if none exists

child=children(tree,root(tree));

names=get(tree,child,'name');

i=find(strcmp(names,'description'));

if isempty(i)
    [tree, des_uid] = add( tree, root(tree), 'element', 'description' );
else
    des_uid=child(i);
end

% Look for time_range element, if one exists, exit with an error :

des_child=children(tree,des_uid);
des_names=get(tree,des_child,'name');

i_datablock=find(strcmp(des_names,'datablock_range'));

if isempty(i_datablock)
    [tree, datablock_uid] = add( tree, des_uid, 'element', 'datablock_range' );
    tree = attributes(tree,'add',datablock_uid,'name','datablock');
else
    error('Description already contains a datablock_range element, delete it before any new assignement');
    return;
end



tree = setDataBlockSample(tree, data_blocks);



return