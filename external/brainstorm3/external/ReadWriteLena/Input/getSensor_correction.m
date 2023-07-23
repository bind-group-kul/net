function sensor_coil_geometry = getSensor_correction(lenaTree,sensor_name)
% function sensor_coil_geometry = getSensor_coil_geometry(lenaTree,sensor_name)
%
%   Get the sensor coils geometry ( ie position and orientation )
%
% Input :
%   lenaTree ( lenaTree object )
%   sensor_name ( string ) : name of the sensor
%
% Output :
%   sensor_coil_geometry ( double array n x 2 x 3 ) : sensor coils geometry
%   array which size is ( number of coils ) x ( position , orientation ) x
%   ( axis x , axis y , axis z )
%

% Get the children ids :
child = children( lenaTree , root(lenaTree) );

% Get the children names :
names = get( lenaTree , child , 'name' );

% Find the description id :
descriptionId = child(find(strcmp(names,'description')));

% Check the  child was found :
if isempty( descriptionId )
    warning( 'Can t find any description parameter in the file' )
    sensor_coil_geometry='';
    return
end

% Get the description elements :
descriptionElements = children( lenaTree , descriptionId );


% Get the description children names :
names = get( lenaTree , descriptionElements , 'name' );

% Find the sensor_range id :
sensor_rangeId = descriptionElements(find(strcmp(names,'sensor_range')));

% Check the  child was found :
if isempty( sensor_rangeId )
    warning( 'Can t find any sensor_range parameter in the file' )
    sensor_coil_geometry = '';
    return
end

% Get the sensor_range elements :
sensor_rangeElements = children( lenaTree , sensor_rangeId );

% Get the sensor_range children names :
names = get( lenaTree , sensor_rangeElements , 'name' );

% Find the sensor_list id :
sensor_listId = sensor_rangeElements(find(strcmp(names,'sensor_list')));

% Check the  child was found :
if isempty( sensor_listId )
    warning( 'Can t find any sensor_list parameter in the file' )
    sensor_coil_geometry = '';
    return
end

% Get the sensor_list elements :
sensor_samplesElements = children( lenaTree , sensor_listId );

% Find the sensor which name is sensor_name

elements=get(lenaTree,children(lenaTree,sensor_samplesElements));
sensor_uid=-1;
i=1;
while (sensor_uid<0)&(i<length(elements)+1)
    if strcmp(elements{i}.type,'chardata')
        if strcmp(elements{i}.value,sensor_name)
            sensor_uid=elements{i}.parent;
        end
    end
    i=i+1;
end

if sensor_uid<0
    error('Given sensor name doesn t seem to exist')
    return
end

% Get the coils id :
sensor_contents=get(lenaTree,children(lenaTree,sensor_uid));
sensor_coil_geometry=[];
if length(sensor_contents)==1
    temp=sensor_contents;
    clear sensor_contents;
    sensor_contents{1}=temp;
    clear temp;
end
for i=1:length(sensor_contents)
    if strcmp(sensor_contents{i}.type,'element')
        if strcmp(sensor_contents{i}.name,'correction')
            geometry=zeros(1,2,3);
            correction_contents=get(lenaTree,children(lenaTree,sensor_contents{i}.uid));
            if length(correction_contents)==1
                temp=correction_contents;
                clear correction_contents;
                correction_contents{1}=temp;
                clear temp;
            end
            for j=1:length(correction_contents)
                switch correction_contents{j}.name
                    case 'element'
                        for k=1:length(coil_contents{j}.attributes)
                            switch coil_contents{j}.attributes{k}.key
                                case 'x'
                                    geometry(end,1,1)=str2double(coil_contents{j}.attributes{k}.val);
                                case 'y'
                                    geometry(end,1,2)=str2double(coil_contents{j}.attributes{k}.val);
                                case 'z'
                                    geometry(end,1,3)=str2double(coil_contents{j}.attributes{k}.val);
                               otherwise 
                                    warning('error while reading coil position');
                                    return
                            end
                        end
                    case 'orientation'
                        for k=1:length(coil_contents{j}.attributes)
                            switch coil_contents{j}.attributes{k}.key
                                case 'x'
                                    geometry(end,2,1)=str2double(coil_contents{j}.attributes{k}.val);
                                case 'y'
                                    geometry(end,2,2)=str2double(coil_contents{j}.attributes{k}.val);
                                case 'z'
                                    geometry(end,2,3)=str2double(coil_contents{j}.attributes{k}.val);
                               otherwise 
                                    warning('error while reading coil orientation');
                                    return
                            end
                        end
                end
            end
            % Add antoher element in first dimension for another coil :
            sensor_coil_geometry=cat(1,sensor_coil_geometry,geometry);
            clear geometry;
        end
    end
end

return