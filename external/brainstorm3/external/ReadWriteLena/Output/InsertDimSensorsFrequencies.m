function tree=InsertDimSensorsFrequencies(header, tree)
  
  if isfield(header,'frequencies') || isfield(header,'frequencysamples')
      if isfield(header,'sensors') || isfield(header,'sensorsSamples')
            [rank_sensor,  rank_frequency]=getRankDimSensorFrequency(header.dimensions_names);
            if  rank_sensor > rank_frequency
                tree=AddFrequencies(header, tree);
                tree=AddSensors(header, tree);
            else                   tree=AddSensors(header, tree);
                                tree=AddFrequencies(header, tree);
            end
      else                 tree=AddFrequencies(header, tree);
      end
  else        if isfield(header,'sensors') || isfield(header,'sensorsSamples')
                         tree=AddSensors(header, tree);
               end
  end
  
   
end
%   
% 
%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [rank_sensor,  rank_frequency]=getRankDimSensorFrequency(dim_names)
 
 rank_sensor=0;
 rank_frequency=0;
 
 for i=1:length(dim_names)
       
     if strcmp (dim_names{i}, 'frequency_range')
         rank_frequency=i;
         
     else 
         
         if strcmp (dim_names{i}, 'sensor_range')
         rank_sensor=i;
         end
     end    
 end
 
end
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tree= AddSensors(header , tree)




if isfield(header,'sensors') || isfield(header,'sensorsSamples')
if (~isempty(header.sensors) || ~isempty(header.sensorSamples))
    if (  isfield(header.sensors,'coils') &  ~isempty(header.sensors.coils)) 
        coilList=header.sensors.coils;
    end


    
    
tree=insertSensorRange(tree,header.sensors,header.sensorSamples, header.sensors.coils);
end
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tree= AddFrequencies(header, tree)

if isfield(header,'frequencies') || isfield(header,'frequencysamples')
if (~isempty(header.frequencies) || ~isempty(header.frequencysamples))
%frequencySamples=frequenciesList;
tree = insertFrequencyRange(tree, header.frequencies, header.frequencysamples);
%tree = setFrequencySamples(tree, frequencySamplesArray)
end
end


end

