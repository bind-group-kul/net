function [dimensions_names,time_samples,sample_rate,pre_trigger,frequencies, list_sensor_name, list_Supersensor_name, datablocks,level, data_format,data_offset,data_size,data_type,coef,lena_tree] = AnovaReadLENADim(lena_file,dim_to_read,smart)
% function F,lena_tree = readTFCartoLENA(lena_file,dim_to_read)
% function F,lena_tree = readTFCartoLENA(lena_file,dim_to_read,smart)
%
%   This function reads a lena format file.
%
% Parameters :
%  Inputs :
%    - lena_file ( String ) : name of LENA file, or lenaTree object if
%                             file as already been read
%    - dim_to_read ( cell ) : sample to read indices for each dimension
%   Optionnal :
%    - smart ( boolean ) : if set to 1, singleton dimensions are removed
%                          in output matrix ( default : 1 )
%
%  Output :
%    - F ( double ) : data array
%    - lena_tree ( xmldimtree ) : header xml tree object, that can be used as
%                              input so that function doesn't need to read
%                              again the header
%
% Usage :
%   F=fastReadLENA('/path/to/file/test.lena');
%       will return a matrix containing all datas
%
%   F=fastReadLENA('/path/to/file/test.lena',{ 2 , [ ] , [5:12] });
%       will return a matrix containing datas for :
%           - 2nd element in first dimension
%           - all elements in second dimension
%           - elements 5 to 12 in third dimension
%
% AB 21/05/2007
% CNRS LENA UPR 640

% Check argument number :
if nargin <3
  smart = 1;
end

% Check Nex or Old format

lena_file=CheckNew_OldFormat(lena_file);

% First check lena_file argument, and read the header :

if strcmp(class(lena_file),'xmltree')
  lena_tree = lena_file;
  lena_file = getfilename(lena_tree);
elseif exist(lena_file)==2
  lena_tree = lenaTree( lena_file );
else
    %lena_file=lena_file
    msg=strcat(lena_file, ' ', ' doesn t seem to exist, or is not a valid object');
    
    errordlg( msg, 'File Error' );
    return
end

% Get the header location :
[lena_path,lena_name]=fileparts(lena_file);

data_format = getData_format(lena_tree);
data_offset = getData_offset(lena_tree);
data_size = getData_size(lena_tree);
data_type = getData_type(lena_tree);

% Check present dimensions :

dimensions_names = getDimensions_names(lena_tree);
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
            %frequency_dim=1;
            %sensor_dim=1;
            %time_dim=1;
            %datablock_dim=1;
            
        end
      
end 

% If no dimension to read is provided, read all :
if nargin == 1
    for i = 1:length_dimensions_names
        dim_to_read{i}=[];
    end
end






list_sensor_name=[];

list_Supersensor_name=[];


frequencies =[];

time_samples=[];
sample_rate=[];
pre_trigger=[];
datablocks=[];
level=[];
coef=[];

if exist('sensor_dim')
    sensors_number = getSensors_number(lena_tree);
   
    
    
     Supersensors_number = getSensor_sample_number(lena_tree);
    level(sensor_dim)=Supersensors_number;
    
    
    for i=1: sensors_number
    list_sensor_name{i} =  getSensor_name(lena_tree,i);
    end
    
    
     for i=1: Supersensors_number
%     list_Supersensor_name{i} =  getSupersensor_name(lena_tree,i);
coef{i} = getSupersensor_scale(lena_tree,i);

     end
    
    
list_Supersensor_name=    getSupersensor_list(lena_tree);
%coef = getSupersensor_scale(lena_tree,dim_to_read{sensor_dim});
 

end



if exist('time_dim')
    time_samples = getTime_samples(lena_tree);
    sample_rate=getSample_rate(lena_tree);
    pre_trigger=getPre_trigger(lena_tree);
    level(time_dim)=time_samples;
end

if exist('frequency_dim')
    frequency_sample_number = getFrequency_sample_number(lena_tree);
    level(frequency_dim)=frequency_sample_number;
    frequencies = getFrequencies(lena_tree);
    
%       for i=1: frequency_sample_number
%     frequencies{i} =  num2str(listfrequencies(i)); %getSensor_name(lena_tree,i);
% 
%     end
    
end

if exist('datablock_dim')
    datablock_samples = getDatablock_samples(lena_tree);
    level(datablock_dim)=length(datablock_samples);
     datablocks = getDatablocks(lena_tree);
end




return
