function  F = fastGetLENABin(coef, lena_file,dim_to_read, dimensions_names, level,data_format, data_offset, data_size, data_type)

%   This function reads a lena format file and returns the binary values in
%   F matrix
%
% Parameters :
%  Inputs :
%    - lena_file ( String ) : name of LENA file, 
%
%    Optional :
%    - dim_to_read ( cell ) : sample to read indices for each dimension
%   
%   
%
%  Output :
%    - F ( double ) : data array
%   
% 
%

% CNRS LENA UPR 640

% Check argument number :
 if nargin <3
   smart = 1;
 end

%level=[];

% First check lena_file argument, and read the header :

% if strcmp(class(lena_file),'xmltree')
%   lena_tree = lena_file;
%   lena_file = getfilename(lena_tree);
% elseif exist(lena_file)==2
%   lena_tree = lenaTree( lena_file );
% else
%     error(lena_file,'Provided file name doesn t seem to exist, or is not a valid object')
%     return
% end

% Get the header location :

[lena_file, New_Format]=CheckNew_OldFormat(lena_file);

[lena_path,lena_name]=fileparts(lena_file);
if New_Format
    data_filename = strcat(lena_name,'.data');
else
 data_filename = strcat(lena_name,'.bin');
end
 data_filename = fullfile(lena_path,data_filename);

% Check present dimensions :

 
%history=getHistory(lena_tree);



%     
%  dimensions_names = getDimensions_names(lena_tree);
if iscell(dimensions_names)
length_dimensions_names=length(dimensions_names);
else if ischar(dimensions_names)
        length_dimensions_names=1;
    else if isempty(dimensions_names)
            length_dimensions_names=0;
        end
    end
end



if iscell(dimensions_names)
for i=1:length_dimensions_names
    if strcmp(dimensions_names{i},'frequency_range')
        frequency_dim=i;
    elseif strcmp(dimensions_names{i},'sensor_range')
        sensor_dim=i;
    elseif strcmp(dimensions_names{i},'time_range')
        time_dim=i;
    elseif strcmp(dimensions_names{i},'datablock_range')
        datablock_dim=i;
    else
        error(strcat('Found unexpected dimension : ',dimensions_names{i}))
    end
end

else if ischar(dimensions_names)
        if strcmp(dimensions_names,'frequency_range')
            frequency_dim=1;
        elseif strcmp(dimensions_names,'sensor_range')
            sensor_dim=1;
        elseif strcmp(dimensions_names,'time_range')
            time_dim=1;
        elseif strcmp(dimensions_names,'datablock_range')
            datablock_dim=1;
        else
        error(strcat('Found unexpected dimension : ',dimensions_names{i}))
        end
    else
% to do
    end
        
end 

% If no dimension to read is provided, read all :
% if nargin == 1
%     for i = 1:length_dimensions_names
%         dim_to_read{i}='';
%     end
% else  
       if length( dim_to_read) <length_dimensions_names
           for i = length( dim_to_read)+1:length_dimensions_names
               dim_to_read{i}='';
           end
           
     end
% end
% 

% Get data file :
% data_filename = getData_filename(lena_tree,lena_file);
if exist(data_filename)~=2
    error('Can t find data file, provided file name seems to not exist');
    return
end
% 
% % Check data_format and open data file
% data_format = getData_format(lena_tree);
 if strcmp(data_format,'LittleEndian')
     data_fid = fopen(data_filename,'r','l');
 elseif strcmp(data_format,'BigEndian')
     data_fid = fopen(data_filename,'r','b');
 else
     warning('No data_format provided');
     data_fid = fopen(data_filename,'r');
 end
% 
% % Read the offset :
% data_offset = getData_offset(lena_tree);

fread(data_fid,data_offset);

% get data type :

 Mat_data_type = GetMatlabdata_type(data_type, data_size);


% data_type = getData_type(lena_tree);
%  switch(data_type)
%      case 'unsigned fixed'
%          data_type='uint';
%      case 'fixed'
%          data_type='int';
%      case 'floating'
%          data_type='float';
% %    
% %     %case 'float32'
% %      %   data_type='float';
% %         
%      otherwise
%          error('Error : data_type wasn t found, which is required.')
%          return
%  end
% % Get the data size :
% data_size = getData_size(lena_tree);
% data_type=strcat(data_type,num2str(8*data_size));




% if exist('sensor_dim')
%    % sensor_sample_number = getSensors_number(lena_tree);
%     %level(sensor_dim)=sensor_sample_number;
%     
%      sensor_sample_number = getSensor_sample_number(lena_tree);
%     leveldim=sensor_sample_number;
% %[leveldim, sensorList, sensorSample] =ProcessSensorDim(lena_tree, sensor_dim,dimensions_names, dim_to_read);
% level(sensor_dim)=leveldim;
% 
%  
% %     Header.sensors=sensorList;
% % 
% % 
% %     Header.sensorSamples= sensorSample;
% 
% 
% end

% if exist('time_dim')
% %     time_samples = getTime_samples(lena_tree);
% %     sample_rate=getSample_rate(lena_tree);
% %     level(time_dim)=time_samples;
%     
%     [leveldim, time_pretrigger,sample_rate, time_samples] =ProcessTimeDim(lena_tree, time_dim,dimensions_names, dim_to_read);
%     level(time_dim)=leveldim;
%     
%     
%    
% %     Header.timeSamples=time_samples;
% %     
% %        Header.sampleRate=sample_rate;
% %     
% %        Header.preTrigger=time_pretrigger;
%     
%     
% end

% if exist('frequency_dim')
%     frequency_sample_number = getFrequency_sample_number(lena_tree);
%     level(frequency_dim)=frequency_sample_number;
%     frequencies = getFrequencies(lena_tree);
%     frequencysamples=getSuperfrequency_list(lena_tree);
%     
%     dim=(dim_to_read{frequency_dim});
%     if  ~ isempty(dim)
%         frequencies=frequencies(dim(1):dim(end));
%         frequencysamples=frequencysamples(dim(1):dim(end));
%     end
%     
%      
% %        Header.frequencies=frequencies;
% %    
% %        Header.frequencysamples=frequencysamples;
% %    
%     
% end

% if exist('datablock_dim')
%     datablock_samples_number = getDatablock_samples_number(lena_tree);
%     level(datablock_dim)=datablock_samples_number;
%     datablocks = getDatablocks(lena_tree);
%     
%     dim=(dim_to_read{datablock_dim});
%     if  ~ isempty(dim)
%         datablocks=datablocks(dim(1):dim(end));
%            end
%     
%     
% %     Header.datablocks=datablocks;
% end
%  

    
%     Header.data_format=data_format;
%     Header.data_type=data_type;
%     Header.data_size=data_size;
%     Header.dimensions_names=dimensions_names;
%     
%     if ~isempty(history)
%         Header.history=history;
%     end
%     
    
    

% Check which dimensions are provided and which are empty in dim_to_read :






% if ~ exist('dim_to_read');
%  
% dim_to_read='';
% end
% 
% for i = 1:length(dim_to_read)
%     if isempty(dim_to_read{i})
%         dim_to_read{i}=1:level(i);
%     % Specific traitement for time_range
%     elseif exist('time_dim')
%         if dim_to_read{i} == time_dim
%             if length(dim_to_read{i})==2
%             % Compute total time samples :
%             linspace(getPre_trigger(lenaTree) ,...
%                 getPre_trigger(lenaTree)+(getTime_samples(lena_tree)/getSample_rate(lena_tree)),...
%                 getTime_samples(lena_tree));
%             % Search wished time samples :
%             dim_to_read{i}=find(Time>dim_to_read{i}(1)&Time<dim_to_read{i}(2));
%         end
%         end
%     end
% end


% if nargin<2
%     samples_to_read=[1,0];
%     for i=1:length(dim_to_read)
%         
%         samples_to_read(1)=samples_to_read(1)*length(dim_to_read{i});
%     end
% else
%  %   samples_to_read = getBlocktoread(fliplr(dim_to_read),fliplr(level));
%     end

% Extract datas :
%samples = extractBINblocksRevised(data_fid,dim_to_read,level,data_type,data_size);

samples = extractBINblocksRevised4SensorsBis(data_fid,dim_to_read,dimensions_names,level,Mat_data_type,data_size);


if exist ('dim_to_read') & ~ isempty(dim_to_read)
for k=1:length(dim_to_read)
    size_to_read(k)=length(dim_to_read{k});
end
else size_to_read=[];
end


if (length(size_to_read)>1)
F=convertBlocs2matrix(samples, size_to_read);
else F=cell2mat (samples);
end

fclose (data_fid);
% Search Supersensor scales to apply :

if exist('sensor_dim') &   ~exist('frequency_dim')
%coef = getSupersensor_scale(lena_tree,dim_to_read{sensor_dim});
% Apply gains :
if iscell(coef)
coef=cell2mat(coef);
end
if sensor_dim==1
    size_to_read(sensor_dim)=1;
    coef_mat = repmat(coef',size_to_read);
else
    s_t_r_temp=[1,size_to_read(1:sensor_dim-1),size_to_read(sensor_dim+1:end)];
    test=repmat(coef',s_t_r_temp);
    coef_mat=permute(test,[2:sensor_dim,1,sensor_dim+1:length(size_to_read)]);
end

if (length(size_to_read)>1)
F=coef_mat.*F;
else  F=coef.*F;
end
end
%if smart
 %   F=squeeze(F);
%end

return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [leveldim, sensorList, sensorSample]=ProcessSensorDim(lena_tree, sensor_dim,dimensions_names, dim_to_read)

     sensor_sample_number = getSensor_sample_number(lena_tree);
    leveldim=sensor_sample_number;
    
    
    if iscell(dimensions_names)
    for i=1: length( dimensions_names)
        if strcmp(dimensions_names{i}, 'sensor_range')
            if isempty(dim_to_read{i})
                sensor_toread_number=leveldim;
                
            else
            sensor_toread_number=dim_to_read{i};
            
            end
            break;
        end
    end
    
    else   if strcmp(dimensions_names, 'sensor_range')
            if isempty(dim_to_read{1})
                sensor_toread_number=leveldim;
                
            else
            sensor_toread_number=dim_to_read{1};
            
            end
           ;
        end
        
    end
    
    if iscell(sensor_toread_number)
        sensor_toread_number=cell2mat(sensor_toread_number);
    end

    if length(sensor_toread_number) > 1
    
 i1=1;
    
 for i=sensor_toread_number(1): sensor_toread_number(end)
    list_sensor_name{i1} =  getSensor_name(lena_tree,i);
    i1=i1+1;

 end
    
    else  if  sensor_toread_number >0
            i1=1;
          for i=1: sensor_toread_number
    list_sensor_name{i1} =  getSupersensor_name(lena_tree,i);
    i1=i1+1;

          end
        end
   
        
        
    end

if (~ isempty(list_sensor_name))
       
        for i=1:length(list_sensor_name)
            sensor_categories{i} = getSensor_category(lena_tree,list_sensor_name{i} ); 
             sensor_coils{i}=    getSensor_coil_geometry(lena_tree,list_sensor_name{i} );
        end  
  end
 
 sensorList.name=list_sensor_name;
 sensorList.category=sensor_categories;
 sensorList.coils=sensor_coils;

 sensorSample=select_sensors_in(list_sensor_name, lena_tree);


end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [leveldim, time_pretrigger,sample_rate, timesamples_toread]=ProcessTimeDim(lena_tree, time_dim,dimensions_names, dim_to_read)


time_samples = getTime_samples(lena_tree);
    sample_rate=getSample_rate(lena_tree);
    leveldim=time_samples;
    time_pretrigger=getPre_trigger(lena_tree);
    
    
    if iscell(dimensions_names)
        
    for i=1: length( dimensions_names)
        if strcmp(dimensions_names{i}, 'time_range')
            if isempty(cell2mat(dim_to_read(i)))
                timesamples_toread=time_samples;
            else
            timesamples_toread=cell2mat(dim_to_read(i));
            
            end
            break;
        end
    end
    else if strcmp(dimensions_names,'time_range')
            if isempty(cell2mat(dim_to_read(1)))
                timesamples_toread=time_samples;
            else
            timesamples_toread=cell2mat(dim_to_read(1));
            
            end
        end
    end

    
    

end
