function tree = setCoilList(tree, coilList)
%%%%%%%ajouter trois parametres: sensor_category, sensor_name et sensor_coils
%% function setSensorList(tree,sensorList)
%
%   Insert sensor list values inside a xml tree, which will be used for
%   lena data.
%
% Input :
%
%   - tree : an xmltree element?
%   - sensorList (float ) : sensor list values
%   
% Ouptput :
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
 

% Get the children ids :
child = children( tree , root(tree) );

% Get the children names :
names = get( tree , child , 'name' );

% Find the description id :
descriptionId = child(find(strcmp(names,'description')));

% Check the  child was found :
if isempty( descriptionId )
      [tree, descriptionId] = add( tree, root(tree), 'element', 'description' );
end

% Get the description elements :
descriptionElements = children(tree , descriptionId );


% Get the description children names :
names = get( tree , descriptionElements , 'name' );

% Find the frequency_range id :
sensor_rangeId = descriptionElements(find(strcmp(names,'sensor_range')));

% Check the  child was found :
if isempty( sensor_rangeId )
      [tree, sensor_rangeId] = add(tree, descriptionId, 'element', 'sensor_range' );
end

% Get the frequency_range elements :
sensor_rangeElements = children( tree ,  sensor_rangeId);

% Get the frequency_range children names :
names = get( tree , sensor_rangeElements , 'name' );

% Find the frequency_samples id :
sensor_listId = sensor_rangeElements(find(strcmp(names,'sensor_list')));

% Check the  child was found :
if isempty( sensor_listId )
          [tree, sensor_listId] = add(tree, sensor_rangeId, 'element', 'sensor_list' );
          tree = attributes(tree,'add',sensor_rangeId,'name','sensor');

end


sensor_samplesElements = children( tree , sensor_listId );



elements=get(tree,sensor_samplesElements);

sensor_listElements = children( tree ,  sensor_listId);

% Get the frequency_range children names :
names = get( tree , sensor_listElements , 'name' );

% Find the frequency_samples id :
sensorId = sensor_listElements(find(strcmp(names,'sensor')));





% for cp=1:length(coilList.position)
%           index=coilList.index(cp);
%           sensorId=getSensorId(elements,index);
%           
%           position=coilList.position{1,cp};
%              orientation=coilList.orientation{1,cp};
%              tree= setCoilElement(tree, sensorId, position, orientation);
%          
%                  
% 
% end


for cp=1:length(coilList)
          %index=coilList.index(cp);
          sensorId=getSensorId(elements,cp);
          
          position=coilList{1,cp}.position;
          if exist(coilList{1,cp}.orientation)
             orientation=coilList{1,cp}.orientation;
          
          else orientation=[];
          end
             tree= setCoilElement(tree, sensorId, position, orientation);
         
                 

end



return
end



function sensorId=getSensorId( elements, index)

sensorId=elements{1,index}.uid;
end













function tree = setCoilElement(tree, sensorId, position, orientation)
    
    [tree, coilId] = add(tree, sensorId, 'element', 'coil' );
    [tree, positionId] = add(tree, coilId, 'element', 'position' );
    [tree, orientationId] = add(tree, coilId, 'element', 'orientation');

   
     tree = attributes(tree,'add',positionId,'x',num2str(position(1)));
     tree = attributes(tree,'add',positionId,'y',num2str(position(2)));
     tree = attributes(tree,'add',positionId,'z',num2str(position(3)));

     tree = attributes(tree,'add',orientationId,'x',num2str(orientation(1)));
     tree = attributes(tree,'add',orientationId,'y',num2str(orientation(2)));
     tree = attributes(tree,'add',orientationId,'z',num2str(orientation(3)));
     %ff
 
    
end




