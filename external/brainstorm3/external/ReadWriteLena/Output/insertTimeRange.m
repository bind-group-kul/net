function tree=insertTimeRange(tree,time_samples,sample_rate,pre_trigger)
% function insertTimeRange(tree,time_samples,sample_rate,pre_trigger)
%
%   Insert a Time range dimension in a xml tree, which will be used for
%   lena datas.
%
% Inputs :
%
%   - tree : an xmltree element
%   - time_samples ( int ) : number of samples
%   - sample_rate (int ) : sample rate
%   Optionnals :
%   - pre_trigger ( float ) : pre-trigger time
%
% Ouptputs :
%
%   - tree : xmltree with added informations
%
% See also : createSimpleLENA, insertSimpleElements,deleteLENAelement,copyLENAelement
%
%
% AB 08 01 2007
%
% LENA CNRS UPR640
%

if nargin < 3
    error('Insufficient number of arguments.');
    return;
elseif nargin > 4
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

i_time=find(strcmp(des_names,'time_range'));

if isempty(i_time)
    [tree, time_uid] = add( tree, des_uid, 'element', 'time_range' );
    tree = attributes(tree,'add',time_uid,'name','time');
else
    error('Description already contains a time_range element, delete it before any new assignement');
    return;
end

[tree, timespl_uid] = add( tree, time_uid, 'element', 'time_samples' );
tree = add(tree,timespl_uid,'chardata',time_samples);
[tree, timerate_uid] = add( tree, time_uid, 'element', 'sample_rate' );
tree = add(tree,timerate_uid,'chardata',sample_rate);
if nargin > 3
    [tree, timepretgr_uid] = add( tree, time_uid, 'element', 'pre_trigger' );
    tree = add(tree,timepretgr_uid,'chardata',pre_trigger);
end


return