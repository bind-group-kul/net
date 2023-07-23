function [sensor_categories,category_details] = getSensor_categories(lenaTree)
% function sensor_categories = getSensor_categories(lenaTree)
%
%   Get a list of categories present in this file
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   sensor_categories ( cell ) : n x 2 cells : - first row for category
%                                               name
%                                              - second for event number
%
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
    sensor_categories = '';
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
    sensor_categories = '';
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
    sensor_categories = '';
    return
end

% Get the sensor_list elements :
sensor_samplesElements = children( lenaTree , sensor_listId );



elements=get(lenaTree,sensor_samplesElements);

categories_name={};
categories_event={};

if nargout == 2
  category_details=cell{1,length(elements)}
end

for i =1:length(elements)
    attr = elements{i}.attributes;
    for j =1:length(attr)
        if strcmp(attr{j}.key,'category')
            % Check is category name already exists :
            index = find(strcmp(attr{j}.val,categories_name));
            if isempty(index)
                categories_name={categories_name{:},attr{j}.val};
                categories_event={categories_event{:},1};
            else
                categories_event{index}=categories_event{index}+1;
            end
	    
	    if nargout == 2
	      category_details{i}=attr{j}.val;
	    end

        end
    end
end

for i = 1:length(categories_name)
    sensor_categories{i,1} = categories_name{i};
    sensor_categories{i,2} = categories_event{i};
end


return
