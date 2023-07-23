%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EEG chunk
% funtion: cut data into separate files
% last version: 23.10.2013
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;clear;warning off
%%%%%%%%%%%%
% defining paths
%%%%%%%%%%%%
NET_folder = net('path');


output_folder = '/Users/quanyingliu/Documents/EEG_resting/dante';
if not(isdir(output_folder))
    mkdir(output_folder);
end



spm_filename = '/Users/quanyingliu/Documents/EEG_resting/dante/spm_dante_resting_20141013_050630.mat';

[d,f,ext]=fileparts(spm_filename);
if not(strcmp(d,output_folder))
    copyfile(spm_filename,[output_folder filesep f '.mat']);
    copyfile(spm_filename,[output_folder filesep f '.dat']);
end

chunks_option(1).run_name='spm_dante_resting';
chunks_option(1).beginning_time=10;
chunks_option(1).end_time=300;


% chunks_option(1).run_name='koen_resting_state_1';
% chunks_option(1).beginning_time=7;
% chunks_option(1).end_time=57;
% chunks_option(2).run_name='koen_motor_task_1';
% chunks_option(2).beginning_time=57;
% chunks_option(2).end_time=550;
% chunks_option(3).run_name='koen_resting_state_2';
% chunks_option(3).beginning_time=550;
% chunks_option(3).end_time=600;
% chunks_option(4).run_name='koen_motor_task_2';
% chunks_option(4).beginning_time=600;
% chunks_option(4).end_time=1090;
% chunks_option(5).run_name='koen_resting_state_3';
% chunks_option(5).beginning_time=1090;
% chunks_option(5).end_time=1140;


clear job

job.data = {[output_folder filesep f '.mat']};
for i=1:length(chunks_option)
    job.chunk(i).chunk_beg.t_rel = net_secs2hms(chunks_option(i).beginning_time);
    job.chunk(i).chunk_end.t_rel = net_secs2hms(chunks_option(i).end_time);
end
job.options.overwr = 1;
job.options.fn_prefix = 'chk';
job.options.numchunk = 1;

crc_run_chunking(job);

for i=1:length(chunks_option)
    S=[];
    S.D       = [output_folder filesep 'chk' num2str(i) '_' f];
    S.newname = [output_folder filesep chunks_option(i).run_name];
    spm_eeg_copy(S);
    delete([output_folder filesep 'chk' num2str(i) '_' f '.mat']);
    delete([output_folder filesep 'chk' num2str(i) '_' f '.dat']);
end
