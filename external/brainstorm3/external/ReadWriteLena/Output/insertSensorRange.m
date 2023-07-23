function tree=insertSensorRange(tree,sensorList,sensorSamples,coilList, correctionList)
% function insertTimeRange(tree,time_samples,sample_rate,pre_trigger)
%
%   Insert a sensor range dimension in a xml tree, which will be used for
%   lena data.
%
% Input :
%
%   - tree : an xmltree element
%   - sensorList ( float ) : sensor values
%   - sensorSamples (float ) : 2-Dim Array of sensor samples values
%       -First dimension: SuperSensor
%       -Second dimension: sensor samples values for each super sensor 
%
% Ouput :
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

add_coil=false;
add_correction=false;

if nargin < 3
    error('Insufficient number of arguments.');
    return;
elseif nargin == 4
     add_coil=true;
else if nargin==5 
        if ~isempty(coilList)
         add_coil=true;
        end
        if  ~isempty(correctionList)
        add_correction=true;
        end
    else if nargin >5 
            error('Too much arguments.');
        return;
        end
    end
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

% Look for sensor_range element, if one exists, exit with an error :

des_child=children(tree,des_uid);
des_names=get(tree,des_child,'name');

i_sensor=find(strcmp(des_names,'sensor_range'));

if isempty(i_sensor)
    [tree, sensor_uid] = add( tree, des_uid, 'element', 'sensor_range' );
    tree = attributes(tree,'add',sensor_uid,'name','sensor');
    
else
    error('Description already contains a sensor_range element, delete it before any new assignement');
    return;
end


tree = setSensorList(tree, sensorList);

% if add_coil
% tree = setCoilList(tree, coilList)
% end
% 
% if add_correction
%     tree = setCorrectionList(tree, correctionList)
% end

if ~isempty(sensorSamples)
tree = setSensorSample(tree, sensorSamples);
end


return