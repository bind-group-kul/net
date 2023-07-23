function Dnew=net_restore_sampfreq(D,Dold)

data=D(:,:,:);

Fsnew=fsample(Dold);

Fs=fsample(D);

datanew = (resample(data',Fsnew/Fs,1))';
datanew=datanew(:,1:size(Dold,2),:);

raw_filename=[path(D) filesep fname(D)];
delete(D);

S = [];  % changed by DM 26.11.13
S.D = Dold;
S.newname = raw_filename;
Dnew = spm_eeg_copy(S);%The function that creates a copy of the mat and dat file and creates a MEEG SPM object-

Dnew(:,:,:)=datanew;
Dnew.save;