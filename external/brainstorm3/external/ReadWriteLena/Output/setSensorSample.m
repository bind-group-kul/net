function tree = setSensorSample(tree, sensorSamplesArray)
%% function setSensorSample(tree,sensorSamplesArray)
%
%   Insert sensor samples values inside a xml tree, which will be used for
%   lena data.
%
% Input :
%
%   - tree : an xmltree element
%   - sensorSamplesArray (float ) : 2-Dim Array of sensor samples values
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
sensor_sampleId = sensor_rangeElements(find(strcmp(names,'sensor_samples')));

% Check the  child was found :
if isempty( sensor_sampleId )
          [tree, sensor_sampleId] = add(tree, sensor_rangeId, 'element', 'sensor_samples' );
end







l=size(sensorSamplesArray.list_sensors,1);


for cp1=1:size(sensorSamplesArray.list_sensors,1)
    
            
          [tree, Supersensor_id] = add(tree, sensor_sampleId, 'element', 'supersensor' );
          if  ~isempty(sensorSamplesArray.unit)
              %if   (length(sensorSamplesArray.unit)>=cp1)
               %  if  (sensorSamplesArray.unit{cp1,2} ==cp1)
                    unit=sensorSamplesArray.unit{cp1};
                      tree = attributes(tree,'add',Supersensor_id,'unit',unit);
             %end
              %end
          end

            if   ~isempty(sensorSamplesArray.scale)

           %   if (length(sensorSamplesArray.scale)>=cp1)
              %if (sensorSamplesArray.scale{cp1,2} ==cp1)
                  scale=num2str(sensorSamplesArray.scale{cp1});
                tree = attributes(tree,'add',Supersensor_id,'scale',scale);
              %end
            %end
            end


%in=sensorSamplesArray.list_sensors(cp1,:);
%in=size(sensorSamplesArray.list_sensors(cp1,:))
if ~isempty(sensorSamplesArray.list_sensors)

            for cp2=1:length(sensorSamplesArray.list_sensors(cp1,:));

        
                [tree, sensor_id] = add(tree, Supersensor_id, 'element', 'sensor' );
                c=num2str(sensorSamplesArray.list_sensors{cp1,cp2});
                tree = add( tree, sensor_id, 'chardata',  c);
          end
            
end
end



return

end
