function Dn=net_eemd_correction(D,options_eemd)


Nstd=options_eemd.std_rel;
NR=options_eemd.realizations;
MaxIter=options_eemd.maxiter;  
thres_kurt=options_eemd.thres_kurt;

Dn=D;

list_eeg=meegchannels(Dn);

sigs=Dn(list_eeg,:,:);

samples_process=Dn.samples_process;
cut_samples=find(samples_process);


[~, WM, DWM] = fastica(sigs(:,cut_samples),'only', 'white');
whitesigs=WM*sigs;


whitesigs_clean=whitesigs;
for i=1:size(whitesigs,1)  
    modes=net_eemd(whitesigs(i,:),Nstd,NR,MaxIter);
    kurtx=kurt(modes(:,cut_samples)');
    bad_modes=kurtx>thres_kurt;
    disp(['running EEMD on PC no. ' num2str(i) ' : removed ' num2str(sum(bad_modes)) ' modes']);
    whitesigs_clean(i,:)=whitesigs(i,:)-sum(modes(bad_modes,:),1);
end

disp('EEMD-corrected data recontructed!');

sigs_clean=DWM*whitesigs_clean;

Dn(list_eeg,:,:)=sigs_clean;

Dn.save;
