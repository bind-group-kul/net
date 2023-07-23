function [lena_tree, F] = fastReadLENA(lena_file,dim_to_read)
%   This function reads a lena format file.
%
% Parameters :
%  Input :
%    - lena_file ( String ) : name of LENA file, or lenaTree object if
%                             file as already been read
%    - dim_to_read ( cell ) : sample to read indices for each dimension
%
%  Output :
%    - F ( double ) : data array of the binary values
%    - lena_tree ( xmldimtree ) : header xml tree object, that can be used as
%                              input so that function doesn't need to read
%                              again the header
%
% Usage :
%   F=fastReadLENA('/path/to/file/test.lena');
%       will return a matrix containing all the data
%
%   F=fastReadLENA('/path/to/file/test.lena',{ 2 , [ ] , [5:12] });
%       will return a matrix containing data for :
%           - 2nd element in first dimension
%           - all elements in second dimension
%           - elements 5 to 12 in third dimension
%
% CNRS LENA UPR 640

% Check argument number :
 if nargin <3
   smart = 1;
 end

level=[];






% First check lena_file argument, and read the header :

if strcmp(class(lena_file),'xmltree')
  lena_tree = lena_file;
  lena_file = getfilename(lena_tree);
  new = 0;
elseif exist(lena_file)==2
  [lena_file, new]=CheckNew_OldFormat(lena_file);
  lena_tree = lenaTree( lena_file );
else
    error(lena_file,'Provided file name doesn t seem to exist, or is not a valid object')
    return
end

% Get the header location :
[lena_path,lena_name]=fileparts(lena_file);


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
% to do
    end
        
end 

% If no dimension to read is provided, read all :
if nargin == 1
    for i = 1:length_dimensions_names
        dim_to_read{i}=[];
    end
end


% Get data file :
data_filename = getData_filename(lena_tree,lena_file, new);
if exist(data_filename)~=2
    error('Can t find data file, provided file name seems to not exist');
    return
end

% Check data_format and open data file
data_format = getData_format(lena_tree);
if strcmp(data_format,'LittleEndian')
    data_fid = fopen(data_filename,'r','l');
elseif strcmp(data_format,'BigEndian')
    data_fid = fopen(data_filename,'r','b');
else
    warning('No data_format provided');
    data_fid = fopen(data_filename,'r');
end

% Read the offset :
data_offset = getData_offset(lena_tree);

fread(data_fid,data_offset);

% get data type :
data_type = getData_type(lena_tree);

%Mat_data_type = GetMatlabdata_type(data_type, data_size);



% switch(data_type)
%     case 'unsigned fixed'
%         data_type='uint';
%     case 'fixed'
%         data_type='int';
%     case 'floating'
%         data_type='float';
%     otherwise
%         error('Error : data_type wasn t found, which is required.')
%         return
% end
% Get the data size :
data_size = getData_size(lena_tree);
%data_type=strcat(data_type,num2str(8*data_size));

Mat_data_type = GetMatlabdata_type(data_type, data_size);

if exist('sensor_dim')
    sensor_sample_number = getSensor_sample_number(lena_tree);
    level(sensor_dim)=sensor_sample_number;
end

if exist('time_dim')
    time_samples = getTime_samples(lena_tree);
    level(time_dim)=time_samples;
end

if exist('frequency_dim')
    frequency_sample_number = getFrequency_sample_number(lena_tree);
    level(frequency_dim)=frequency_sample_number;
    frequencies=getFrequencies(lena_tree);
end
if exist('datablock_dim')
    datablock_samples_number = getDatablock_samples_number(lena_tree);
    level(datablock_dim)=datablock_samples_number;
    blocks=getDatablocks(lena_tree);
end

% Check which dimensions are provided and which are empty in dim_to_read :
if ~ exist('dim_to_read');
 
dim_to_read='';
else if length(dim_to_read) < length_dimensions_names
        for k=length(dim_to_read)+1: length_dimensions_names
            dim_to_read{k}='';
        end
    end


end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% BLOCK EDITED BY F.TADEL:  06-Nov-2009
for i = 1:length(dim_to_read)
    if isempty(dim_to_read{i}) &  (~exist('time_dim')   ||   (exist('time_dim') & i~= time_dim))
        dim_to_read{i}=1:level(i);
    elseif isempty(dim_to_read{i}) && exist('time_dim') & i==time_dim
            dim_to_read{i}=0:level(i)-1;
        
%     % Specific traitement for time_range
%         elseif exist('time_dim')
%             if dim_to_read{i} == time_dim
%                 if length(dim_to_read{i})==2
%             % Compute total time samples :
%                 linspace(getPre_trigger(lenaTree) ,...
%                 getPre_trigger(lenaTree)+(getTime_samples(lena_tree)/getSample_rate(lena_tree)),...
%                 getTime_samples(lena_tree));
%             % Search wished time samples :
%             dim_to_read{i}=find(Time>dim_to_read{i}(1)&Time<dim_to_read{i}(2));
%                 end
%             end
%         end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin<2
    samples_to_read=[1,0];
    for i=1:length(dim_to_read)
        
        samples_to_read(1)=samples_to_read(1)*length(dim_to_read{i});
    end
else
 %   samples_to_read = getBlocktoread(fliplr(dim_to_read),fliplr(level));
    end

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

if exist('sensor_dim')
coef = getSupersensor_scale(lena_tree,dim_to_read{sensor_dim});
% Apply gains :
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
