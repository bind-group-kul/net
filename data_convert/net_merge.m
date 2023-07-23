clear all;

D(1,:) = 'espm_dante_left1_copy_avgRef_clean_ERD_D100.mat';
D(2,:) = 'espm_dante_left2_copy_avgRef_clean_ERD_D100.mat';

S = [];
S.D = D;
S.recode = 'same';
Dout = spm_eeg_merge(S);

S = [];
S.D = Dout;
S.newname = 'espm_dante_left_copy_avgRef_clean_ERD_D100.mat';
Dnew = spm_eeg_copy(S);

delete(Dout);clear Dout;

D1 = spm_eeg_load( D(1,:) );
D2 = spm_eeg_load( D(2,:) );
event1 = events(D1);
event2 = events(D2);

event = [event1 event2];
Dnew = events(Dnew, [], event);
Dnew.save;