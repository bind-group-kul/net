function Dn=net_reconstruct_sensorspace(D,comp,ica_options)

dname = fname(D);
S = [];
S.D = D;
S.newname=[path(D) filesep dname(1:end-4) '_clean.mat'];
Dn = spm_eeg_copy(S);

IC=comp.trial{1};

A=comp.topo;

good_ics=comp.good_ics;

bad_ics=comp.bad_ics;

sel=selectchannels(D,'EEG');

data=Dn(sel,:,:);

if strcmp(ica_options.reconstruction,'recombine')
    
    clean_data = A(:,good_ics)*IC(good_ics,:);
    
elseif strcmp(ica_options.reconstruction,'remove')
    
    clean_data = data-A(:,bad_ics)*IC(bad_ics,:);
    
else
    
    disp('ERROR! this recontruction option is not known');
    
end

Dn(sel,:,:)=clean_data;

Dn.save;