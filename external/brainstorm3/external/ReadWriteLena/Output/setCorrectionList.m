function tree = setSensorList(tree, correctionList)
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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sensor_samplesElements = children( tree , sensor_listId );



elements=get(tree,sensor_samplesElements);

sensor_listElements = children( tree ,  sensor_listId);

% Get the frequency_range children names :
names = get( tree , sensor_listElements , 'name' );

% Find the frequency_samples id :
sensorId = sensor_listElements(find(strcmp(names,'sensor')));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%






for cp=1:length(correctionList.index)
          
          index=correctionList.index(cp);
          sensorId=getSensorId(elements,index);
          
          type=correctionList.type{1,cp};
          
          list_elem=correctionList.Element{cp,1};
             tree= setCorrectionElement(tree, sensorId,type, list_elem);      

end


return
end



function sensorId=getSensorId( elements, index)

sensorId=elements{1,index}.uid;
end










function tree = setCorrectionElement(tree, sensorId, type, list_elem)
    
    [tree, correctionId] = add(tree, sensorId, 'element', 'correction' );
    
     tree = attributes(tree,'add',correctionId,'type',type);
        
        
        if  (length(list_elem)>0)
    
         for i=1:size(list_elem,1)
               
            sensor =list_elem{i,1};
            coeff=list_elem{i,2};
            tree= setCorrectionElementList(tree, correctionId,sensor, coeff);
         end

        end   
        
end






function tree = setCorrectionElementList(tree, correctionId, sensor, coeff)
    
    [tree, elementId] = add(tree, correctionId, 'element', 'element' );
    
        tree = attributes(tree,'add',elementId,'sensor',sensor);
        tree = attributes(tree,'add',elementId,'coeff',coeff);

      
    
    
end

