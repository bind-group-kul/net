function net_spm2bp(spm_file)


D=spm_eeg_load(spm_file);

nch=size(D,1);

Fs=fsample(D);

sigs=D(:,:,:);


EEG_filename=[spm_file(1:end-4) '.eeg'];
EEGOUT_header_file=[spm_file(1:end-4) '.vhdr'];
EEGOUT_marker_file=[spm_file(1:end-4) '.vmrk'];

% Write EEG header file

fid = fopen(EEGOUT_header_file,'wt');
fprintf(fid,'Brain Vision Data Exchange Header File Version 1.0\n');
fprintf(fid,'\n');
fprintf(fid,'[Common Infos]\n');
fprintf(fid,'DataFile=');
fprintf(fid,EEG_filename);
fprintf(fid,'\n');
fprintf(fid,'MarkerFile=');
fprintf(fid,EEGOUT_marker_file);
fprintf(fid,'\n');
fprintf(fid,'DataFormat=BINARY\n');
fprintf(fid,'DataOrientation=MULTIPLEXED\n');
fprintf(fid,'NumberOfChannels=');
fprintf(fid,num2str(nch));
fprintf(fid,'\n');
fprintf(fid,'SamplingInterval=');
fprintf(fid,num2str(1000000/Fs));
fprintf(fid,'\n');
fprintf(fid,'\n');
fprintf(fid,'[Binary Infos]\n');
fprintf(fid,'BinaryFormat=IEEE_FLOAT_32\n'); 
fprintf(fid,'\n');
fprintf(fid,'[Channel Infos]\n');
for c = 1 : nch
    fprintf(fid,'Ch');
    fprintf(fid,num2str(c));
    fprintf(fid,'=E');
    fprintf(fid,num2str(c));
    fprintf(fid,',,1\n');
end
fclose(fid);

% Write EEG marker file (channel No.258=ECG channel)


EV=events(D);


fid = fopen(EEGOUT_marker_file,'wt');
fprintf(fid,'Brain Vision Data Exchange Marker File, Version 1.0\n');
fprintf(fid,'\n');
fprintf(fid,'[Common Infos]\n');
fprintf(fid,'Codepage=UTF-8\n');
fprintf(fid,['DataFile=' EEG_filename '\n']);
fprintf(fid,'\n');
fprintf(fid,'[Marker Infos]\n');
for i=1:length(EV)
    if strcmp(EV(i).type,'MR_Pulse')
        ev_code='MRPulse';
    else
        ev_code=EV(i).value;
    end
    ev_time=round(1000000*EV(i).time);
    fprintf(fid,'Mk%d=Stimulus,%s,%d,1,0\n',i,ev_code,ev_time);
end
fclose(fid);


% Write EEG signals

sigs=reshape(sigs,1,numel(sigs));
fid=fopen(EEG_filename,'w');
fwrite(fid,sigs,'float32');
fclose(fid);



return;