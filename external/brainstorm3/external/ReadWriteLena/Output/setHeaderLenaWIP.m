  function tree=setHeaderLenaWIP(xml_file,data_format,data_type,data_size, varargin )
 
% % % 
% %
% %
% % This function will create a LENA xml file with supplied  arguments in
%    varargin
% %
% %   Inputs :
% %       - xml_file      ( string )  : file name to create
% %
% %       - data_format   ( string )  : endianness ('LittleEndian' or 'BigEndian')
% %
% %       - data_type     ( string )  : data type ( 'float', 'int', etc ... )
% 
% %       - data_size     ( string )  : size of data
%
%         - varargin                  : a structure of arguments containing the following:   
% 
% %             - data_blocks             :  Cell array of string defining class name for each block/trial in the buffer 
% %                                              example data_blocks={'trial 1'; 'trial 2'; 'trial 3'; 'trial 4'};
% 
% %             - sensorList              : Struct made of 2 fields
% %                                           1. name:        Cell array of strings defining the names of the sensors
% %                                           2. category:    Cell array of strings specifying type of sensors (meg, eeg, adc, eog, ecg)
% 
% %                                             example:    sensorsList.name= {'PO7'; 'PO6';'PO5'};
% %                                               sensorsList.category= {'eeg'; 'meg' ;'eog'};
% 
% %               - coilList               : struct  made of 3 fields: 
% 
% %                                       1. index:array of integer, the ith element of the array is the index of the sensor to which belongs the i th coil   (for MEG
% %                                       several coils can be specified)
% 
% %                                       2. position: array of float vertors, the ith vector is the position of the ith coil 
% 
% %                                       3. orientation: array of float vertors, the ith vector is the orientation of the ith coil 
% %
% %                                       example:    coilList.index=[2,2,3];
% %                                                   coilList.position={[0.23,1.85,0.36], [1.54,0.96,1.42], [1.87,1.69,1.32]};
% %                                                   coilList.orientation={[0,1,1], [1,0,1], [0,1,0]};
% %
% %             - correctionList            : struct made of 3 fields
% %               
% %                                      1. type: cell array of strings  specifying the type of correction
% 
% %                                      2. index: array of integer, the ith
% %                                      element of the array is the index of
% %                                      the sensor to which belongs the i th correction 
% %                                       (several corrections can be specified)
% %
% %                                      3. Element: Cell aray of element.
% %                                      Each element can be a singleton or
% %                                      an array of multiple singletons. 
% %                                      A singleton is a cell of 2 values:
% %                                      a string (name of the sensor) and a float (
% %                                      correction coefficient ) example: {'BG1-610',0.1328}
% %                   
% %                                       example:correctionList.type={'RB1G', 'IO3G', 'IO2G'};
% 
% %                                               correctionList.index=[1, 1, 3];
% 
% %                                               correctionList.Element={{'BG1-610',0.1328}; [{'BG2-610', 0.236}; {'BG3-610', 1.25}; {BG4-610', 4.53}]; {'BG5-610', 1.45}};
% % 
% % 
% % 
% 
% %           - sensorSamples             :   struct made of 4 fields
% %                                       1. list_sensors: cell array of cell
% %                                       elements. Each element is a
% %                                       supersensor
% %                                       
% %                                        2. unit: array of cell element: the
% %                                       first component is the unit of the
% %                                       sensor and the second is the index
% %                                       of the supersensor in the
% %                                       list_sensors
% %
% %                                        3.scale:array of cell element: the
% %                                       first component is the unit of the
% %                                       sensor and the second is the index
% %                                       of the super in the
% %                                       list_sensors
% %
% %                                       4. num_sensors:number of sensors in
% %                                       each supersensor of list_sensors
% %                                       
% %                                       example:
% %                                       sensorSamples.unit=[{'v',1};{'v',2}];
% %                                       sensorSamples.scale=[{0,1};{0,2}];
% %                                       sensorSamples.num_sensors=[1;2;1];
% %                                       sensorSamples.list_sensors={{'MZO02-610'};{'MZO01-610', 'MZO03-610'};{'MZO04-610'}};
% %
% %
% %          - frequenciesList           : Array of float defining frequencies
% %                                      example: frequenciesList=[10 20 30 40 50 60 70];
% %
% % 
% %           - frequencySamples          : Cell array of superfrequencies
% %                                       example: frequencySamples={{10, 20} ;{20} ;{30} ;{40, 50}; {50}; {60} ;{70}};
% %
% %          - timeSamples               : number of time samples (must be
% %                                         positive)
% %
% %          - sample_rate               : Sample rate of the time dimension
% %          - pre_trigger               : Pre trigger time (must be positive)
% %  
% %
% % Output :
% %       - tree          ( xmltree ) : xml object that has just been stored in the xml
% %                                      file.
% %
% % Notice : The parameters data_format, data_type, data_size are part of
% % the LENA data format. Please refer to its documentation for more
% % informations.
% %
% 
% 
% 
% 
% % Author :
% %
% % Lydia Yahia
% % 05 03 2008
% %
% % LENA CNRS UPR640
% % 


%error(nargchk(4, 14, nargin))
error(nargchk(2,Inf,nargin,'struct'));

datablocks=     [];
sensorList =    [];
coilList=       []; 
correctionList= []; 
sensorSamples=  []; 
frequenciesList=[];
frequencySamples = [];
time_samples=       [];
sample_rate=        []; 
pre_trigger=        [];

if ~isempty(varargin) && nargin<=6
   [datablocks,sensorList, coilList, correctionList, sensorSamples, frequenciesList, frequencySamples ,time_samples,sample_rate, pre_trigger, history]= checkarg(varargin);
    
%    va1 = varargin{1};
%    if ~iscell(va1) || isempty(va1)
%       newstyle = false;
%    elseif ~isempty(strmatch(va1,{'DB' 'db' 'DataBlocks' 'datablocks' 'DATABLOCKS' }, 'exact'))
%       newstyle = false;
%       datablocks=varargin{2}
%    end
end



% Create an xml tree
tree = xmltree;

% Set the root element to 'LENA' :
tree = set(tree,root(tree),'name','LENA');

% Add mandatory arguments :
[ tree , format_uid ] = add(tree,root(tree),'element','data_format');
tree = add(tree,format_uid,'chardata',data_format);

[ tree , type_uid ] = add(tree,root(tree),'element','data_type');

tree = add(tree,type_uid,'chardata',data_type);

[ tree , size_uid ] = add(tree,root(tree),'element','data_size');
tree = add(tree,size_uid,'chardata',num2str(data_size));

if exist('history')
    if ~(isempty(history))
        tree=setHistory(tree, history);
    end
end


if (exist('datablocks'))
if ~(isempty(datablocks))
tree=insertDataBlockRange(tree, datablocks);
end;
end;


%add sensors and sensor samples
if exist('sensorList') || exist('sensorsSamples')
if (~isempty(sensorList) || ~isempty(sensorSamples))
    if (  isfield(sensorList,'coils') &  ~isempty(sensorList.coils)) 
        coilList=sensorList.coils;
    end

tree=insertSensorRange(tree,sensorList,sensorSamples, coilList, correctionList);
end
end

% add frequencies and frequencies samples
% 


if exist('frequenciesList') || exist('frequencySamples')
if (~isempty(frequenciesList) || ~isempty(frequencySamples))
    %frequencySamples=frequenciesList;
tree = insertFrequencyRange(tree, frequenciesList, frequencySamples);

end
end
% Add timeRange
if exist('time_samples') || exist('sample_rate') || exist('pre_trigger')
if (~isempty(time_samples) & ~isempty(sample_rate) & ~isempty(pre_trigger))
tree=insertTimeRange(tree,num2str(time_samples),num2str (sample_rate),num2str(pre_trigger));
end
end




% Save xml :
savexmlLena(tree,xml_file);
%xmlwrite(xml_file,tree);

return






function  [datablocks,sensorList, coilList, correctionList, sensorSamples, frequenciesList, frequencySamples ,time_samples,sample_rate, pre_trigger, history]= checkarg(argval)
    
history=[];
datablocks=[];    
sensorList =[];
coilList=[]; 
correctionList=[]; 
sensorSamples=[]; 
frequenciesList=[];
frequencySamples =[];
time_samples= [];
sample_rate= []; 
pre_trigger=[];
    
    
    i=1;
len=numel(argval{1});
while i<=  len
va1 = varargin{1,1}{i,1};
   if ischar (va1) && ~isempty(va1)
  %  a= strmatch(va1,{'sensorList', 'coilList', 'correctionList', 'sensorSamples', 'frequenciesList',' frequencySamples ','time_samples','sample_rate', 'pre_trigger' }, 'exact'))
   % if ~isempty(a)
    %    val=a[1];
      switch(   va1)
          case 'datablocks'
              datablocks=argval{1,1}{i+1,1};
              
          case 'sensorList'
              sensorList=argval{1,1}{i+1,1};
              
           case 'coilList'
            coilList=argval{1,1}{i+1,1};
            
            case 'correctionList'
              correctionList=argval{1,1}{i+1,1};
              
                    case 'sensorSamples'
              sensorSamples=argval{1,1}{i+1,1};
              
                    case 'correctionList'
              correctionList=argval{1,1}{i+1,1};              
                    case 'frequenciesList'
              frequenciesList=argval{1,1}{i+1,1};
              
                    case 'frequencySamples'
              frequencySamples=argval{1,1}{i+1,1};
              
                    case 'time_sample'
              time_samples=argval{1,1}{i+1,1};
              
                    case 'sample_rate'
              sample_rate=argval{1,1}{i+1,1};
              
                    case 'pre_trigger'
              pre_trigger=argval{1,1}{i+1,1};
              
                 case 'history'
              history=argval{1,1}{i+1,1};
      end
    %end
   end


i=i+2;
end
 end
end
