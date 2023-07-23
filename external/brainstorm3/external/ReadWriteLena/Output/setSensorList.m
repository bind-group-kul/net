function tree = setSensorList(tree, sensorList)
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
        %  tree = attributes(tree,'add',sensor_rangeId,'name','sensor');

end


%sensor_list doit etre une structure avec les sensor categories, les
%sensors names et les coils




for cp=1:length(sensorList.name)
              %tree = set(tree, sensor_listId, 'element', sensor ); 
          [tree, sensorId] = add(tree, sensor_listId, 'element', 'sensor' );
          
          tree=add_category(tree, sensorList, sensorId, cp);
          tree = add(tree, sensorId, 'chardata',char(sensorList.name{1,cp}) );
         tree = setCoillist(tree, sensorList.coils{cp},sensorId);

            
          
end




return
end




function tree = setCoillist(tree, coilList,sensorId)

if ~isempty(coilList)
    dim=size(coilList,1);
    if (dim >0) 

    for i1=1: size(coilList,1)
%        for i2=1: size(coilList,2)
    position=coilList(i1,1,:);
    orientation=coilList(i1,2,:);
  tree= setCoilElement(tree, sensorId, position, orientation);      
 %       end
        
    end
    
else
for i=1: size(coilList,1)
    position=coilList(i,1);
    orientation=coilList(i,2);

tree= setCoilElement(tree, sensorId, position, orientation);
end
end
end
end

function tree=add_category(tree, sensorList, sensorId, cp)
  
if (~isempty(sensorList))
               if (~isempty(sensorList.category{1,cp}))
              cat=sensorList.category{1, cp};
          
              tree = attributes(tree,'add',sensorId,'category',cat);
          
               
               end
          end
        
end



function tree=add_impedance(tree, sensorList, sensorId, cp)
end

function   tree=add_physic_min(tree, sensorList, sensorId, cp)
end

function tree=add_physic_max(tree, sensorList, sensorId, cp)
end

function tree=add_low_filter(tree, sensorList, sensorId, cp)
end

function tree=add_pass_filter(tree, sensorList, sensorId, cp)
end


function tree = setCoilElement(tree, sensorId, position, orientation)
    
    [tree, coilId] = add(tree, sensorId, 'element', 'coil' );
   % tree= set(tree,coilId, 'name', 'position');
   
    
     [tree, positionId] = add(tree, coilId, 'element', 'position' );
    [tree, orientationId] = add(tree, coilId, 'element', 'orientation');

     
     %tree= set(tree,positionId, 'name', 'position');
     
   %tree = attributes(tree,'add',coilId,1,'name','position');
%  [tree, orientationId] = attributes(tree,'set',coilId,2,'name','orientation');

%     [tree, orientationId] = add(tree, coilId, 'element', 'orientation');

   
     tree = attributes(tree,'add',positionId,'x',num2str(position(1)));
      tree = attributes(tree,'add',positionId,'y',num2str(position(2)));
      tree = attributes(tree,'add',positionId,'z',num2str(position(3)));
% 
      tree = attributes(tree,'add',orientationId,'x',num2str(orientation(1)));
      tree = attributes(tree,'add',orientationId,'y',num2str(orientation(2)));
      tree = attributes(tree,'add',orientationId,'z',num2str(orientation(3)));
     %ff
 
    
end





