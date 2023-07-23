clear;
clc;

%This script is to generate a structured triggers information template for
%NET, please read the instructions and change the code for your own
%experiment
%structure of triggers: let's assume for each condition(an on or off event), there exist
%multiple triggers to indicate the time of this event, for example:
%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%    triggers.condition_name    triggers.values(List as a cell)    triggers.pretrig(ms)   triggers.posttrig(ms)    triggers.baseline(ms)    triggers.time_range(ms)                  triggers.bands_of_interest(Hz)                  triggers.duration(s)  triggers.connectivity_time(ms)
%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%   'hand_task_on'              {'S  3a'                      }         -1000                   3000                    [-1000 0]                   [1000 2000]             {'[0 4]', '[4 8]', '[8 13]', '[13 30]', '[30 80]'}                 0                        400
%   'hand_task_off'             {'S  6a', 'S  6b'             }         -1000                   3000                    [-1000 0]                   [1000 2000]             {'[0 4]', '[4 8]', '[8 13]', '[13 30]', '[30 80]'}                 0                        400
%   'foot_task_on'              {'S  4a', 'S  4b', 'S   4c'...}         -1000                   3000                    [-1000 0]                   [1000 2000]             {'[0 4]', '[4 8]', '[8 13]', '[13 30]', '[30 80]'}                 0                        400
%   'foot_task_off'             {'S  7a', 'S  7b', 'S   7c'...}         -1000                   3000                    [-1000 0]                   [1000 2000]             {'[0 4]', '[4 8]', '[8 13]', '[13 30]', '[30 80]'}                 0                        400
%   'lips_task_on'              {'S  5a', 'S  5b', 'S   5c'...}         -1000                   3000                    [-1000 0]                   [1000 2000]             {'[0 4]', '[4 8]', '[8 13]', '[13 30]', '[30 80]'}                 0                        400
%   'lips_task_off'             {'S  8a', 'S  8b', 'S   8c'...}         -1000                   3000                    [-1000 0]                   [1000 2000]             {'[0 4]', '[4 8]', '[8 13]', '[13 30]', '[30 80]'}                 0                        400
%         ...                                  ...
%-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%in the case above, take hand_task_on as example, signal epoches indicated by 'S  3a',
%'S  3b' or 'S  3c' will be considered as the same kind of
%condition(event), and will be averaged together during the calculation
%
%if you plan to do connectivity analysis on the task data, the last two
%fields should be filled in as follows:
%  duration > 0 for a completely randomized design
%           > length of the block in seconds, for a block design
%  connectivity_time (IF duration > 0) > ms to consider after the trigger
%                                        for the connectivity analysis
%
%please note there is no limit of the numbers of conditions(event), and also no
%limit of numbers of triggers.def for each condition(event)
%
%please also remeber to put your template in [NET Folder]/template/triggers
%and also inicate the name in NET .xlsx configuration file
%
% last version: 12.11.2017, by Mingqi Zhao of BIND Group


% code for you to change-----------------------------------------------

template_name = 'template_10_July';%you can name your own template


condition_name_cell = { 
                        'EMG_hand_task_on';
                        'EMG_hand_task_off';
                        'EMG_foot_task_on'
                        'EMG_foot_task_off';
                        'EMG_lips_task_on';
                        'EMG_lips_task_off';
                                        };

                    
triggers_values_cell ={
                         {'EMG_S  3'};
                         {'EMG_S  6'};
                         {'EMG_S  4'};
                         {'EMG_S  7'};
                         {'EMG_S  5'};
                         {'EMG_S  8'};
                                                            };
                                                
pretrig = [
            -5000;
            -5000;
            -5000;
            -5000;
            -5000;
            -5000;           
                    ];
        
posttrig = [
             5000;
             5000;
             5000;
             5000;
             5000;
             5000;

                    ];
                
baseline = {
             [-3000 0];
             [-3000 0];
             [-3000 0];
             [-3000 0];
             [-3000 0];
             [-3000 0];
             
                         };
            
time_range_cell = {
                      {[0 2000], [0 2000], [0 2000], [0 2000], [0 2000], [0 2000]};
                      {[0 2000], [0 2000], [0 2000], [0 2000], [0 2000], [0 2000]};
                      {[0 2000], [0 2000], [0 2000], [0 2000], [0 2000], [0 2000]};
                      {[0 2000], [0 2000], [0 2000], [0 2000], [0 2000], [0 2000]};
                      {[0 2000], [0 2000], [0 2000], [0 2000], [0 2000], [0 2000]};
                      {[0 2000], [0 2000], [0 2000], [0 2000], [0 2000], [0 2000]};
                                };

                            
bands_cell = {
                  {[1 4], [5 8], [8 13], [13 30], [30 50], [40,46]};
                  {[1 4], [5 8], [8 13], [13 30], [30 50], [40,46]};
                  {[1 4], [5 8], [8 13], [13 30], [30 50], [40,46]};
                  {[1 4], [5 8], [8 13], [13 30], [30 50], [40,46]};
                  {[1 4], [5 8], [8 13], [13 30], [30 50], [40,46]};
                  {[1 4], [5 8], [8 13], [13 30], [30 50], [40,46]};
                                                                         };

duration = {
                  0;
                  0;
                  0;
                  0;
                  0;
                  0;
                        };
                    
connectivity_time = {
                        400;
                        400;
                        400;
                        400;
                        400;
                        400;
                                };
                                            
% ---------------------------------------------------------------------



%% check
if(length(condition_name_cell) ~= size(triggers_values_cell, 1))
    error('trigger numbers error: number of trigger condition_names should be the same of number of trigger value sets!');
end

if(length(condition_name_cell) ~= length(pretrig))
    error('trigger numbers error: number of trigger condition_names should be the same of number of pretrigs');
end

time_range_num = length(time_range_cell);
bands_num = length(bands_cell);
if( time_range_num ~= bands_num)
    error('bands number error: bands number shoud be the same of the number of time range');
end
for iter_time_range = 1:time_range_num
    if(length(time_range_cell{iter_time_range}) ~= length(bands_cell{iter_time_range}))
        error('bands and time range: please check the numbers');
    end
end




%% write
for iter_condition = 1:1:length(condition_name_cell)
    triggers(iter_condition).condition_name = condition_name_cell{iter_condition};
    triggers(iter_condition).trig_labels = triggers_values_cell{iter_condition,:};
    triggers(iter_condition).pretrig = pretrig(iter_condition);
    triggers(iter_condition).posttrig = posttrig(iter_condition);
    triggers(iter_condition).baseline = baseline{iter_condition};
    triggers(iter_condition).time_range = time_range_cell{iter_condition};
    triggers(iter_condition).frequency = bands_cell{iter_condition};
end

NET_folder = net('path');
save([NET_folder filesep 'template' filesep 'triggers' filesep template_name], 'triggers');
fprintf(['A new triggers template has been saved as ', template_name, '.mat', ' please check!\n']);
clear;