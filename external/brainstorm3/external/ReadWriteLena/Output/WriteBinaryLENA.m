function  status = WrireBinaryLENA(MatData, lena_file,dim_to_write)
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
%    - lena_dtree ( xmltree ) : header xml tree object, that can be used as
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

warning('This LENA format is obsolete !')

status=true;
if nargin <2
    status= false;
  return 
end



% First check lena_file argument, and read the header :

if strcmp(class(lena_file),'xmltree')
  lena_tree = lena_file;
  lena_file = getfilename(lena_tree);
elseif exist(lena_file)==2
  lena_tree = lenaTree( lena_file );
else
    status=false;
    error('Provided file name doesn t seem to exist, or is not a valid object')
    return
end

% Get the header location :
[lena_path,lena_name]=fileparts(lena_file);


% Check present dimensions :

dimensions_names = getDimensions_names(lena_tree);

if ~ isempty(dimensions_names)
if iscell(dimensions_names)

for i=1:length(dimensions_names)
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
else
    
    if strcmp(dimensions_names,'frequency_range')
        frequency_dim=1;
    elseif strcmp(dimensions_names,'sensor_range')
        sensor_dim=1;
    elseif strcmp(dimensions_names,'time_range')
        time_dim=1;
    elseif strcmp(dimensions_names,'datablock_range')
        datablock_dim=1;
    else
        error(strcat('Found unexpected dimension : ',dimensions_names))
    end
end
end


% If no dimension to write is provided, write all :
 if nargin <3
     if iscell(dimensions_names)
     for i = 1:length(dimensions_names)
         dim_to_write{i}=[];
     end
     else dim_to_write=[];
     end
 end
%

% Get data file :
%data_filename = getData_filename(lena_tree,lena_file);
%[lena_path,lena_name]=fileparts(lena_file);
if ~ isempty(lena_path)
data_filename = strcat(lena_path,'/',lena_name,'.bin');
else data_filename = strcat(lena_name,'.bin');
end
%if exist(data_filename)~=2
 %   error('Can t find data file, provided file name seems to not exist');
  %  return
%end

% Check data_format and open data file
%data_format = getData_format(lena_tree);
% if strcmp(data_format,'LittleEndian')
%     data_fid = fopen(data_filename,'wb','l');
% elseif strcmp(data_format,'BigEndian')
%     data_fid = fopen(data_filename,'r','b');
% else
%     warning('No data_format provided');
    data_fid = fopen(data_filename,'wb');
    if (data_fid==-1)
        status=false;
        return
    end
        
%end

level=[];
% Read the offset :
data_offset = getData_offset(lena_tree);

%for i=1: data_offset
    c=zeros(data_offset,1);
    
fwrite(data_fid,c);
%end

% get data type :
data_type = getData_type(lena_tree);
% switch(data_type)
%     case 'unsigned fixed'
%         data_type='uint';
%     case 'fixed'
%         data_type='int';
%     case 'floating'
%         data_type='float';
%     case 'float32'
%        data_type='float';
%   
%     case 'float'
%        data_type='float';    
%         
%     otherwise
%         error('Error : data_type wasn t found, which is required.')
%         return
% end
% Get the data size :
data_size = getData_size(lena_tree);
%data_type=strcat(data_type,num2str(8*data_size));
Mat_data_type = GetMatlabdata_type(data_type, data_size);


if exist('sensor_dim')
    sensor_sample_number = getSensors_number(lena_tree);
    level{sensor_dim}=sensor_sample_number;
end

if exist('time_dim')
    time_samples = getTime_samples(lena_tree);
    level{time_dim}=time_samples;
end

if exist('frequency_dim')
    frequency_sample_number = getFrequency_sample_number(lena_tree);
    level{frequency_dim}=frequency_sample_number;
end

if exist('datablock_dim')
    datablock_samples_number = getDatablock_samples_number(lena_tree);
    level{datablock_dim}=datablock_samples_number;
end

% Check which dimensions are provided and which are empty in dim_to_write :

for i = 1:length(dim_to_write)
    if isempty(dim_to_write{i})
        dim_to_write{i}=1:level{i};
    % Specific traitement for time_range
    elseif exist('time_dim')
        if dim_to_write{i} == time_dim
        if length(dim_to_write{i})==2
            % Compute total time samples :
            linspace(getPre_trigger(lenaTree) ,...
                getPre_trigger(lenaTree)+(getTime_samples(lena_tree)/getSample_rate(lena_tree)),...
                getTime_samples(lena_tree));
            % Search wished time samples :
            dim_to_write{i}=find(Time>dim_to_write{i}(1)&Time<dim_to_write{i}(2));
        end
        end
    end
end

% if nargin<2
%     samples_to_write=[1,0]
%     for i=1:length(dim_to_write)
%         samples_to_write(1)=samples_to_write(1)*length(dim_to_write{i})
%     end
% else
%     samples_to_write = getBlocktoread(fliplr(dim_to_write),fliplr(level));
% end


%Write Binary Datalena
if iscell(MatData)
mat=cell2mat(MatData);
else 
    mat =MatData;
end
a=size(mat);
%mat=squeeze(mat);
%mat=mat' ;%reshape(mat, a(2),a(1)); % extension a plus de deux dimensions

command2='';
matrice_index='';
for i = 1:length(a)-1
     command2 = [command2 'for j' int2str(i) '=1:a(' int2str(i) ') '];
     matrice_index=[matrice_index 'j' int2str(i) ', '];
end

matrice_index=[matrice_index ':'];

if length (dim_to_write)>0 & iscell(MatData)

command2= [command2 'fwrite(data_fid,  cell2mat(MatData (' matrice_index  ') ),Mat_data_type);'];
else if length (dim_to_write)>0
        command2= [command2 'fwrite(data_fid,  MatData (' matrice_index  ') ,Mat_data_type);'];
    else
        command2= [command2 'fwrite(data_fid,  MatData ,Mat_data_type);'];
    end
end
    
%eval (commandWrite);
%fwrite(data_fid, Mat,data_type);

for i = 1:length(a)-1
     command2 = [command2 'end, '];
end

 eval(command2); 


%mat=permute(mat,flipdim([1:length(dim_to_write)],2));

%fwrite(data_fid, mat,data_type);
% Extract datas :
% samples = extractBINblocks(data_fid,samples_to_write,data_type,data_size);
% 
% for k=1:length(dim_to_write)
%     size_to_write(k)=length(dim_to_write{k});
% end
% 
% F=convertBlocs2matrix(samples, size_to_write);
% 
% 
% % Search Supersensor scales to apply :
% coef = getSupersensor_scale(lena_tree,dim_to_write{sensor_dim});
% % Apply gains :
% if sensor_dim==1
%     size_to_write(sensor_dim)=1;
%     coef_mat = repmat(coef',size_to_write);
% else
%     s_t_r_temp=[1,size_to_write(1:sensor_dim-1),size_to_write(sensor_dim+1:end)];
%     test=repmat(coef',s_t_r_temp);
%     coef_mat=permute(test,[2:sensor_dim,1,sensor_dim+1:length(size_to_write)]);
% end
% 
% F=coef_mat.*F;
% 
% if smart
%     F=squeeze(F);
% end
fclose (data_fid);
return
