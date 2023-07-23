function echantillons = extractBINblocks(fid,dim_to_read,dim_names,level,data_type,data_size)
% function echantillons = extractBINblocks(fid,mat,data_type,data_size)
%
%   Function to read only parts of a bin file ( cf LENA data format )
%
% Inputs :
%   - fid ( integer ) : fid of the bin file
%   - mat ( double array ) : matrix of samples to read. Size must be N x 2,
%   ie first column for samples to read, second for samples to skip
%   - data_type ( string ) : data type and size ( example : int16 )
%   - data_size ( integer ) : data format size
%
% Ouputs :
%   - echantillons ( cells ) : read datas stored in cells

%tb=waitbar(0,'Read data from bin file');

size_dim=length(dim_to_read);

trial_dim=[];
frequency_dim=[];
sensor_dim=[];

time_dim=[];

first_pos_trial=0;
first_pos_frequency=0;
first_pos_sensor=0;
first_pos_time=0;



% if (size_dim) <4
%     if (size_dim)<3
%          if (size_dim)<2
%          time_dim=dim_to_read
%          time_level=level
%          else %=2
%              sensor_dim=dim_to_read(1);
%              sensor_level=level(1);
%              time_dim=dim_to_read(2);
%              time_level=level(2);
%              
% 
%              
%          end
%     else %=3
%             frequency_dim=dim_to_read(1);
%             frequency_level=level(1);
%             sensor_dim=dim_to_read(2);
%              sensor_level=level(2);
% 
%             time_level=level(3);
%              time_dim=dim_to_read(3);
% 
%     end
% else %=4
%             trial_dim=dim_to_read(1);
%             trial_level=level(1);
%             frequency_level=level(2);
%             sensor_level=level(3);
%             time_level=level(4);
%             frequency_dim=dim_to_read(2);
%             sensor_dim=dim_to_read(3);
%              time_dim=dim_to_read(4);
% 
%     
% end


[trial_dim, trial_level,frequency_dim, frequency_level, sensor_dim, sensor_level, time_dim, time_level ]=GetDimensionsValues(dim_to_read, dim_names, level);



    if ~isempty(trial_dim)
        %dim_trial=length(trial_dim);
        
        trial_dim=cell2mat(trial_dim);

%        first_pos_trial=(trial_dim(1)-1)*(frequency_level*sensor_level*time_level);
         first_pos_trial=Get_First_Pos_Trial(trial_dim, frequency_level, sensor_level,time_level);
    %else  dim_trial=1
    end
        
        
%     if ~isempty(frequency_dim)
%         dim_frequency=length(frequency_dim);
%     else  dim_frequency=1
%     end
%        
        
      if ~isempty(sensor_dim)
%           for i_dim_sensor=1:length(sensor_dim)
%               sensor_dim(i_dim_sensor)=cell2mat(sensor_dim(i_dim_sensor));
%             first_pos_sensor(i_dim_sensor)=(sensor_dim(1)-1)*(time_level);
%             dim_sensor(i_dim_sensor)=length(sensor_dim(i_dim_sensor));
%         
%           end
    sensor_dim=cell2mat(sensor_dim);
    first_pos_sensor=Get_First_Pos_Sensor(sensor_dim, time_level);

    % first_pos_sensor=(sensor_dim(1)-1)*(time_level);
%    first_pos_time=time_dim(1)-1;
%     
     % else  dim_sensor=1
      end
       
        
%       if ~isempty(time_dim)
%         dim_time=length(cell2mat(time_dim));
%       else  dim_time=1
%       end
%        

%       if ~isempty(trial_dim) 
%           if iscell(trial_dim)
%               
%           trial_dim=cell2mat(trial_dim);
%           end
% 
%     first_pos_trial=(trial_dim(1)-1)*(frequency_level*sensor_level*time_level);
%       end
      
    if ~isempty(frequency_dim)
        frequency_dim=cell2mat(frequency_dim);
        first_pos_frequency=Get_First_Pos_Frequency(frequency_dim,  sensor_level,time_level);

%    first_pos_frequency=(frequency_dim(1)-1)*(sensor_level*time_level);
    end
    
   
            
    if ~isempty(time_dim)
        time_dim=cell2mat(time_dim);
    first_pos_time=time_dim(1);
    end





    first_pos=first_pos_time+first_pos_sensor+first_pos_frequency+first_pos_trial;
    
     fseek(fid,data_size*first_pos,'bof');
    
    

     if ~isempty(trial_dim)
        first_trial=trial_dim(1);
        last_trial=trial_dim(end);
    else first_trial=1;last_trial=1;
     end


     if ~isempty(frequency_dim)
        first_frequency=frequency_dim(1);
        last_frequency=frequency_dim(end);
    else first_frequency=1;last_frequency=1;
     end


     if ~isempty(sensor_dim)
        first_sensor=sensor_dim(1);
        last_sensor=sensor_dim(end);
    else first_sensor=1;last_sensor=1;
    end

    
    if ~isempty(time_dim)
        first_time=time_dim(1);
        last_time=time_dim(end);
    else first_time=1;last_time=1;
    end

    k=1;
    

 if exist('time_level') & ~ isempty(time_dim)
remainder_time=time_level-time_dim(end)-1;
 else remainder_time=0;
 end

% if exist('sensor_level')
%  %remainder_sensor=(sensor_level-sensor_dim(end))*time_level;
%   %else remainder_sensor=0;
% 
% end
%  
%  
%  if (~isempty(frequnecy_dim))
%      limit_frequency=frequency_dim(end);
%  else if exist('frequency_level')
%          limit_frequency=frequency_level;
%      end
%  end
%  
%  if (exist('frequency_level') & exist ('sensor_level') & exist ('time_level')) 
%   remainder_frequency=(frequency_level-limit_frequency)*time_level*sensor_level;
%  else if (exist('frequency_level')  & exist ('time_level'))
%            remainder_frequency=(frequency_level-limit_frequency)*time_level;
%  end


 
 % revoir pour la lecture
     first_trial=1;last_trial=1;

 
%      if ~isempty(trial_dim)
%           for i_dim_trial=1:length(trial_dim)
%             first_trial=trial_dim(trial_dim)(1);
%             last_trial=trial_dim(trial_dim)(end);
          
    
%      
%      for i_trial=first_trial:last_trial
%         
%         for i_frequency=first_frequency:last_frequency
%             
%             for i_sensor=first_sensor:last_sensor
%                 echantillons{k}=  fread(fid,dim_time,data_type);
%                
%                   fseek(fid, data_size*(first_pos_time+remainder_time),'cof');
%                     k=k+1;
%                 
%             end
%             if exist('sensor_level')
%             
%             fseek(fid, (first_pos_time+first_pos_sensor+remainder_sensor)*data_size, 'cof');
%             end
%             
%         end
%             if exist('frequency_level')
%            
%              fseek(fid, (first_pos_time+first_pos_sensor+first_pos_frequency+remainder_frequency)*data_size, 'cof');
%             end
%     end
    
    
%end
    
 
        k=1;


    
 %%%%%%%%%%nouvelle tentative
 
  if (isempty(trial_dim) & isempty(trial_level))
    first_pos_trial=1;
    if (isempty(frequency_dim) & isempty(frequency_level))
        first_pos_frequency=1;
              [k, echantillons]= Process_Sensor(fid,data_size, data_type,first_pos_trial, first_pos_frequency,sensor_dim, time_dim,sensor_level,time_level,k); 
    else  if ~isempty(sensor_level) & sensor_level >1

            [k, echantillons]= Process_Frequency_Sensor(fid,data_size, data_type,first_pos_trial, frequency_dim,sensor_dim, time_dim, k,frequency_level, time_level, sensor_level); % frequence/temps
        else  
            [k, echantillons]= Process_Frequency(fid,data_size, data_type,first_pos_trial, frequency_dim,time_dim, k,frequency_level, time_level); % frequence/temps
        end

    end

  
   else if ~isempty(trial_dim) 
              limit_trial=length(trial_dim);
         else if ~isempty(trial_level)
                  limit_trial=trial_level;
              end
          end
              for i_dim_trial=1:limit_trial
                
                  if ~isempty(frequency_level) & ~isempty(sensor_level) & ~isempty(time_level)
                 first_pos_trial=(trial_dim(i_dim_trial)-1)*(frequency_level*sensor_level*time_level);
                 [k, echantillons]= Process_Frequency_Sensor(fid,data_size, data_type,first_pos_trial, frequency_dim,sensor_dim, time_dim, k,frequency_level, time_level, sensor_level); % frequence/temps

                
                 else if ~isempty(sensor_level) & ~isempty(time_level)
                         first_pos_trial=(trial_dim(i_dim_trial)-1)*(sensor_level*time_level);
                         first_pos_frequency=1;
                        [k, echantillons]= Process_Sensor(fid,data_size, data_type,first_pos_trial, first_pos_frequency,sensor_dim, time_dim,sensor_level,time_level,k); 
 
    
                     else if ~isempty(frequency_level) & ~isempty(time_level)
                            first_pos_trial=(trial_dim(i_dim_trial)-1)*(frequency_level*time_level);
                              [k, echantillons]= Process_Frequency(fid,data_size, data_type,first_pos_trial, frequency_dim,time_dim, k,frequency_level, time_level); % frequence/temps

                    
                         else if  ~isempty(sensor_level) & isempty(frequency_level) & isempty(time_level)
                                 [k, echantillons]= Process_Sensor(fid,data_size, data_type,first_pos_trial, first_pos_frequency,sensor_dim, time_dim,sensor_level,time_level,k); 
                 
                             end

                         end

                     end

                  end
              end
          
      end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

function [trial_dim, trial_level,frequency_dim, frequency_level, sensor_dim, sensor_level, time_dim, time_level ]=GetDimensionsValues(dim_to_read, dim_names, level)

trial_dim=[];
frequency_dim=[];
sensor_dim=[];
time_dim=[];

trial_level=[];
frequency_level=[];
sensor_level=[];

time_level=[];

size= length(dim_to_read);
if size==1
    
    switch dim_names
  case 'datablock_range' 
    trial_dim=dim_to_read; trial_level=level;
  case 'frequency_range'
    frequency_dim=dim_to_read; frequency_level=level;
  case 'sensor_range'
    sensor_dim=dim_to_read; sensor_level=level;
  case 'time_range'
    time_dim=dim_to_read; time_level=level;

    end
    
    
else
    
    for i=1:length(dim_to_read)
       
        switch dim_names{i}
  case 'datablock_range' 
    trial_dim=dim_to_read(i); trial_level=level(i);
  case 'frequency_range'
    frequency_dim=dim_to_read(i); frequency_level=level(i);
  case 'sensor_range'
    sensor_dim=dim_to_read(i); sensor_level=level(i);
  case 'time_range'
    time_dim=dim_to_read(i); time_level=level(i);

    end
    end
    
    
end

end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [k, echantillons]= Process_Frequency_Sensor(fid,data_size, data_type,first_pos_trial, frequency_dim,sensor_dim, time_dim, k,frequency_level, time_level, sensor_level); % frequence/temps


   % function  Process_Frequency(first_pos_trial)

        if ~isempty(frequency_dim) 
              limit_frequency=length(frequency_dim);
         else    limit_frequency=frequency_level;
         end
              for i_dim_frequency=1:limit_frequency
                
                  first_pos_frequency=(frequency_dim(i_dim_frequency)-1)*(sensor_level*time_level);
             [k, echantillons]=    Process_Sensor(fid,data_size, data_type,first_pos_trial,first_pos_frequency, sensor_dim, time_dim,sensor_level,time_level,k);
                
                 
              end
    
    




end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 function [k, echantillons]= Process_Frequency(fid,data_size, data_type,first_pos_trial, frequency_dim,time_dim, k,frequency_level, time_level)

   % function  Process_Frequency(first_pos_trial)
   
            first_pos_time=time_dim(1);
            remainder_time=time_level-time_dim(end)-1;
            dim_time=length((time_dim));
       
            if ~isempty(frequency_dim) 
              limit_frequency=length(frequency_dim);
         else 
                  limit_frequency=frequency_level;
              
          end
              for i_dim_frequency=1:limit_frequency
                
              
                         first_pos_frequency=(frequency_dim(i_dim_frequency)-1)*(time_level);
                         
                         %Lecture
                         fseek(fid,data_size*first_pos_frequency,'bof');
                         echantillons{k}=  fread(fid,dim_time,data_type);
                         fseek(fid, data_size*(first_pos_time+remainder_time),'cof');
                            k=k+1;
    
                     
                     end
                  




end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%function  Process_Sensor(first_pos_trial,  first_pos_frequency)
 function [k, echantillons]= Process_Sensor(fid,data_size, data_type,first_pos_trial, first_pos_frequency,sensor_dim, time_dim,sensor_level,time_level,k)   
  
       
if ( isempty(sensor_dim) & isempty(sensor_level) & isempty(time_dim) & isempty(time_level) )
    
     fseek(fid,0,'bof');
     echantillons{k}=  fread(fid,1,data_type);
    %k=1;
    %echantillons=[];
    return;
end

 
 
 if (~ isempty(time_dim) & ~isempty(time_level))
            first_pos_time=time_dim(1)-1;
            remainder_time=time_level-time_dim(end)-1;
            dim_time=length(time_dim);
            
 else  
          first_pos_time=0;
            remainder_time=0;
            time_level=1;
            dim_time=1;

     
 end
       
            if ~isempty(sensor_dim) 
              limit_sensor=length(sensor_dim);
         else 
                  limit_sensor=sensor_level;
              
          end
              for i_dim_sensor=1:limit_sensor
                
              
                         first_pos_sensor=(sensor_dim(i_dim_sensor)-1)*(time_level);
                         
                         %Lecture
                         fseek(fid,data_size*first_pos_sensor,'bof');
                         echantillons{k}=  fread(fid,dim_time,data_type);
                         %position = ftell(fid);
                         fseek(fid, data_size*(first_pos_time+remainder_time),'cof');
                          %position = ftell(fid);
                          k=k+1;
    
                     
                     end
                  

 end

 
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
 function  first_pos_trial=Get_First_Pos_Trial(trial_dim, frequency_level, sensor_level,time_level)
if isempty(frequency_level)
    frequency_level=1;
end
if isempty(sensor_level)
    sensor_level=1;
end
 if isempty(time_level)
     time_level=1;
 end
 
 first_pos_trial=(trial_dim(1)-1)*(frequency_level*sensor_level*time_level);
 
 end
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
 
 
 function  first_pos_frequency=Get_First_Pos_Frequency(frequency_dim,  sensor_level,time_level)

 if isempty(sensor_level)
    sensor_level=1;
end
 if isempty(time_level)
     time_level=1;
 end
 
 first_pos_frequency=(frequency_dim(1)-1)*(sensor_level*time_level);
 
 end
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 function  first_pos_sensor=Get_First_Pos_Sensor(sensor_dim, time_level)
 if isempty(time_level)
     time_level=1;
 end
 
 first_pos_sensor=(sensor_dim(1)-1)*(time_level);
 
 end
 
 
 