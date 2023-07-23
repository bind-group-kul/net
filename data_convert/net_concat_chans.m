%% Purpose
% 1. This functions is for concatenating two MEEG objects.

%%
function [ Dx ] = net_concat_chans( Sc )

% [ D2 ] = osl_concat_spm_eeg_chans( Sc )
%
% Clones a passed in Sc.D and concats passed in channels
% Needs:
% Sc.D

% Sc.newchandata (3D matrix of data (channels, samples, trials))
% Sc.newchanlabels (list of str names (channels))
% Sc.newchantype (list of str types (channels))


D=Sc.D;
dpath=D.path;
dname=D.fname;

Sc.newname=[dpath filesep 'tmp.mat'];

%This step creates a clone of the size that can accomodate both the old
%channels + new channels.
D2=clone(D,Sc.newname,[size(D,1)+size(Sc.newchandata,1),size(Sc.newchandata,2),size(Sc.newchandata,3)],0);

chanind=(size(D,1)+1):(size(D,1)+size(Sc.newchandata,1));

%Copy the old data into the clone now..
D2(1:size(D,1),:,:)=D(:,:,:);
%Copy the new data into the clone now..
D2(chanind,:,:)=Sc.newchandata;


%Copy the old channel info into the clone now..
D2 = chanlabels(D2, 1:size(D,1), D.chanlabels);
D2 = chantype(D2, 1:size(D,1), D.chantype);


%Copy the new channel info into the clone now..
for ii=1:length(chanind),
    D2 = chanlabels(D2, chanind(ii), Sc.newchanlabels{ii});
    D2 = chantype(D2, chanind(ii), Sc.newchantype{ii});
end;


%This step is specifically for bad channels
if ~isempty(D.badchannels)
    badchan = D.chanlabels(D.badchannels);
    badchanind = spm_match_str(D2.chanlabels, badchan);
    D2 = badchannels(D2, badchanind, 1);
end


D2.save;

delete(D);
clear D;

Sx=[];
Sx.D=D2;
Sx.newname = [dpath filesep dname];
Sx.outfile = [dpath filesep dname];  % add by QL, 14.03.2016, for SPM12
Dx=spm_eeg_copy(Sx);
%D=path(D,dpath);
%D=fname(D,dname);
%D=fnamedat(D,[dname(1:end-4) '.dat']);
%D.save;

delete(D2);
clear D2;
%%
% Revision history:
%{
2014-04-13 
    v0.1 Updated the file based on initial versions from Dante
(Revision author : Sri).
   

%}

