%% this script is to generate external events files for NET
%   2.Jan.2018, by Mingqi Zhao of BIND group

clear;clc;
%% 1. configure experiment informations
condition_name = { 
                        'emg_hand_on';
                        'emg_foot_on';
                        'emg_lips_on';
                        'emg_hand_off';
                        'emg_foot_off';
                        'emg_lips_off';
                                        };
                                    
epoch_start_marker = {
                        'S  3';
                        'S  4';
                        'S  5';
                        'S  6';
                        'S  7';
                        'S  8';
                                                };
                                            
block_duration = [
                       -7,13;
                       -7,13;
                       -7,13; %use start marker as zero, epoch from -7s to 13s, epoch length = 13-(-7)=20s
                       -15,5;
                       -15,5;
                       -15,5; %use start marker as zero, epoch from -15s to 5s, epoch length = 5-(-15)=20s
                                ]; 
                                            
baseline_begining = [
                       1,4;
                       1,4;
                       1,4;
                       1,4;
                       1,4;
                       1,4;
                             ]; % use the first point as zero, from 2s to 6s
                
baseline_ending = [
                       17,20;
                       17,20;
                       17,20;
                       17,20;
                       17,20;
                       17,20;
                             ]; % use the first point as zero, from 17s to 20s
                    

                
 active_duration = [
                            8;
                            8;
                            8;
                            8;
                            8;
                            8;
                            
                                ];
                                    
corresponding_internal_triggers = {
                                             {'S  3'};
                                             {'S  4'};
                                             {'S  5'};
                                             {'S  6'};
                                             {'S  7'};
                                             {'S  8'};
                                                            };

corresponding_channel_numbers = {
                                    [130, 131];  %use two channels for S  3, can be one or more
                                    [132, 133];
                                    [134, 135];
                                    [130, 131];
                                    [132, 133];
                                    [134, 135];
                                                    };
                                                
                                                        
events_type = {
                'ON';    %EMG "ON" time is event time
                'ON';
                'ON';
                'OFF';   %EMG "OFF" time is event time
                'OFF';
                'OFF';
                                };

threshold = [
                 0.11;
                 0.11;
                 0.12;
                 0.09;
                 0.08;
                 0.1;   
                          ]; %normally, start to tune from 0.1. if it is more inside the block,lower the value of that condition by 0.01; if more outside the block, rise the value of that condition by 0.01. iterate one or two times to have a best result 
                            

                                     

condition_num = length(condition_name);                                                  
for iter_conditions = 1:1:condition_num
    experiment_info(iter_conditions).condition_name = condition_name{iter_conditions};
    experiment_info(iter_conditions).epoch_start_marker = epoch_start_marker{iter_conditions};
    experiment_info(iter_conditions).block_duration = block_duration(iter_conditions,:);
    experiment_info(iter_conditions).active_duration = active_duration(iter_conditions);
    experiment_info(iter_conditions).baseline_begining = baseline_begining(iter_conditions,:);
    experiment_info(iter_conditions).baseline_ending = baseline_ending(iter_conditions,:);
    experiment_info(iter_conditions).emg_channels = corresponding_channel_numbers{iter_conditions};
    experiment_info(iter_conditions).internal_triggers = corresponding_internal_triggers{iter_conditions};
    experiment_info(iter_conditions).events_type = events_type{iter_conditions};
    experiment_info(iter_conditions).threshold = threshold(iter_conditions);
end
clear condition* corresponding* event* search* resting* iter* epoch* base* active* block*

%% 2. extract EMG triggers
eeg_filename = '/Users/mingqi.zhao/CodeAndDataSpace/data/pilot/S1_marco M/Mingqi1_marco.mat';
[path, filename]=fileparts(eeg_filename);
external_emg_filename = [path, filesep, filename, '_external_triggers.mat'];
external_emg_csv_filename = [path, filesep, filename, '_external_triggers.csv'];
file_type = 'spm';
emg_channels = [130, 135];

external_events = net_extract_emg_events( eeg_filename, file_type, experiment_info, emg_channels);

%% 4. save mat file
save(external_emg_filename, 'external_events');

%% 5. save csv file
% start to write file
event_num = length(external_events);
fid = fopen(external_emg_csv_filename, 'w');

fprintf(fid, 'Event_type,Event_name,Event_time,Event_duration,Offset\n');

for iter_e = 1:event_num
    fprintf(fid, '%s,%s,%f,%f,%f\n', external_events(iter_e).type, external_events(iter_e).value, external_events(iter_e).time, 6, 0);
end
fclose(fid);
