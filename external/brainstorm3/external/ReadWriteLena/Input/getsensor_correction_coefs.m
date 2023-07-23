function coefs = getSupersensor_correction_coefs(lenaTree,sensor_name)
% function coefs = getSupersensor_correction_coefs(lenaTree,supersensorIndex,correction)
%
%   Get a supersensor correction coefficients. The supersensorIndex is the position of the
%   supersensor in the header, and correction the name of the correction to consider.
%   The supersensor must contain only one sensor, else an error is raised.
%
% Input :
%   lenaTree ( lenaTree object )
%   supersensorIndex ( double ) : index of the supersensor
%   correction ( string ) : name of the correction to read
%
% Output :
%   coefs ( double ) : correction coefficients : matrix is 2 x n : first
%   line is name of reference sensor, second line is matching coefficient
%

% Get sensor name :
%sensor_name = getSupersensor_name( lenaTree ,  supersensorIndex);


% Get the children ids :
child = children( lenaTree , root(lenaTree) );

% Get the children names :
names = get( lenaTree , child , 'name' );

% Find the description id :
descriptionId = child(find(strcmp(names,'description')));

% Check the  child was found :
if isempty( descriptionId )
    warning( 'Can t find any description parameter in the file' )
    coefs = '';
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
    coefs = '';
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
    coefs = '';
    return
end

% Get the sensor_list elements :
sensor_samplesElements = children( lenaTree , sensor_listId );

% Find the sensor which name is sensor_name

elements=get(lenaTree,children(lenaTree,sensor_samplesElements));
sensor_uid=-1;


if (length(elements)==1)
    temp=elements;
    clear elements;
    elements{1}=temp
end

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
    coefs = '';
    return
end


sensor_children = get(lenaTree,children(lenaTree,sensor_uid));

coefs={};

if length(sensor_children)==1
    temp=sensor_children;
    clear sensor_children;
    sensor_children{1}=temp;
end

for i = 1:length(sensor_children)
    if strmatch(sensor_children{i}.type,'element')
        if strmatch(sensor_children{i}.name,'correction')
            if strmatch(sensor_children{i}.attributes{1}.val,'RB3G')
                coef_temp=get(lenaTree,children(lenaTree,sensor_children{i}.uid),'attributes');
                coefs=cell(2,length(coef_temp));
                for n = 1:length(coef_temp)
                    for m = 1:length(coef_temp{n})
                        if strmatch(coef_temp{n}{m}.key,'sensor')
                            coefs{1,n}=coef_temp{n}{m}.val;
                        elseif strmatch(coef_temp{n}{m}.key,'coeff')
                            coefs{2,n}=str2num(coef_temp{n}{m}.val);
                        end
                    end
                end
            end
        end
    end
end

return

