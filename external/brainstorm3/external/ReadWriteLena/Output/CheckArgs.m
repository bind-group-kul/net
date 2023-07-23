function  [data_format,data_type,data_size, datablocks,sensorList, sensorSamples, frequenciesList, frequencySamples ,time_samples,sample_rate, pre_trigger, history]= CheckArgs(header)
    
data_format=[];
data_type=[];
data_size=[]; 
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
%len=numel(argval{1});
%while i<=  len
%va1 = varargin{1,1}{i,1};
 %  if ischar (va1) && ~isempty(va1)
  %  a= strmatch(va1,{'sensorList', 'coilList', 'correctionList', 'sensorSamples', 'frequenciesList',' frequencySamples ','time_samples','sample_rate', 'pre_trigger' }, 'exact'))
   % if ~isempty(a)
    %    val=a[1];
    
    
    if     isfield(header, 'datablocks')  & ~isempty(header.datablocks)
              datablocks=header.datablocks;
    end

    if   isfield(header, 'sensors')  &  ~ isempty(header.sensors)
              sensorList=header.sensors;
    end      
    
    if  isfield(header, 'sensorSamples')  &  ~ isempty(header.sensorSamples)
              sensorSamples=header.sensorSamples;
    end 
    
    
     if  isfield(header, 'timeSamples')  &  ~ isempty(header.timeSamples)
              time_samples=header.timeSamples;
     end 
    
     
     
          if  isfield(header, 'sampleRate')  &  ~ isempty(header.sampleRate)
              sample_rate=header.sampleRate;
        end 

     if  isfield(header, 'preTrigger')  &  ~ isempty(header.preTrigger)
              pre_trigger=header.preTrigger;
     end 
        
     
          if  isfield(header, 'frequencies')  &  ~ isempty(header.frequencies)
              frequenciesList=header.frequencies;
          end 

        
          
       if  isfield(header, 'frequencysamples')  &  ~ isempty(header.frequencysamples)
              frequencySamples=header.frequencysamples;
       end 


      if  isfield(header, 'data_format')  &  ~ isempty(header.data_format)
              data_format=header.data_format;
      end 
 
      
        
      if  isfield(header, 'data_type')  &  ~ isempty(header.data_type)
              data_type=header.data_type;
      end 
        
      
      if  isfield(header, 'data_size')  &  ~ isempty(header.data_size)
              data_size=header.data_size;
      end 
 
 
        
       if  isfield(header, 'history')  &  ~ isempty(header.history)
              history=header.history;
        end 
 
       
%           case 'sensorList'
%               sensorList=argval{1,1}{i+1,1};
%               
%            case 'coilList'
%             coilList=argval{1,1}{i+1,1};
%             
%             case 'correctionList'
%               correctionList=argval{1,1}{i+1,1};
%               
%                     case 'sensorSamples'
%               sensorSamples=argval{1,1}{i+1,1};
%               
%                     case 'correctionList'
%               correctionList=argval{1,1}{i+1,1};              
%                     case 'frequenciesList'
%               frequenciesList=argval{1,1}{i+1,1};
%               
%                     case 'frequencySamples'
%               frequencySamples=argval{1,1}{i+1,1};
%               
%                     case 'time_sample'
%               time_samples=argval{1,1}{i+1,1};
%               
%                     case 'sample_rate'
%               sample_rate=argval{1,1}{i+1,1};
%               
%                     case 'pre_trigger'
%               pre_trigger=argval{1,1}{i+1,1};
%               
%                  case 'history'
%               history=argval{1,1}{i+1,1};
%       end
    %end
 %  end


%i=i+2;
%end
 %end
end
