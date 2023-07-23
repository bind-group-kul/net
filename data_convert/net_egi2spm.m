%% Purpose
% 1. Main function that converts EGI files to SPM format.
% 2. Create sensor information compatible to field trip structure.
% 3. Add EOG, EMG signals.
% 4. Do the notch filtering at 50 Hz and detrending on EEG channels.

%%
function D = net_egi2spm(X)

% Main function for converting different M/EEG formats to SPM8 format.
% FORMAT D = spm_eeg_convert(S)
% S                - can be string (file name) or struct (see below)
%
% If S is a struct it can have the optional following fields:
% X.raweeg_filename        - file name
% X.output_file     -


%Check if both raw data and position files are specified

if ~isfield(X, 'raweeg_filename'),    error('EEG filename must be specified!');
else
    raweeg_filename = X.raweeg_filename;
end

output_file=X.output_filename;



% correct event file is needed

A=dir([raweeg_filename filesep 'Events*.xml']);
if size(A,1)>0   % added by QL, 07.10.2014 to check whether there is events*.xml file.
    ev_file=A.name;
    
    if not(isempty(strfind(ev_file,'255')))
        movefile([raweeg_filename filesep ev_file],[raweeg_filename filesep 'Events_DIN_1.xml']);
    end
end


%Supply details in a struct format for the SPM function to start the file
%conversion

S = [];
S.dataset = raweeg_filename; %file name
S.channels = 'all'; %Which channels to convert?
S.checkboundary = 1; %To check if there are breaks in the file
S.usetrials = 1; %we don't use a trail definition file
S.datatype = 'float32-le'; %input data is of 32 bit float format
S.eventpadding = 0; %This is for trial borders, we don't use them
S.saveorigheader = 0; % Don't keep the original header
S.inputformat = []; % we don't use it
S.outfile = output_file; %Save the converted file with a prefix spm_
S.continuous = true; %The data is not epoched it is continuous

%Send this information to SPM function to start conversion
disp('Data Conversion: Reading data...');
D = spm_eeg_convert(S);



Fs = fsample(D);


% The step below is for adding ocular (EOG) and muscle (EMG) signals, they
% are computed from the signals from different electrode positions, we need
% this later on for artefact reduction.
nchan=size(D,1);

if round(log2(nchan))==7
%if strcmp(sens.type,'egi128')
    eye_vertical = 0.5*(D(127,:,1)-D(21,:,1)+D(126,:,1)-D(14,:,1));
    eye_horizontal = D(128,:,1) - D(125,:,1); % Fixed JB 04/03/15
    eye_horizontal=eye_horizontal-(smooth(eye_horizontal',10*Fs,'moving'))';
    muscle_sig = 0.5*( D(119,:,1)+D(48,:,1)-D(44,:,1)-D(114,:,1) );
%elseif strcmp(sens.type,'egi256')
elseif     round(log2(nchan))==8
    eye_vertical = 0.5*( D(241,:,1)+D(238,:,1)-D(37,:,1)-D(18,:,1) );
    eye_horizontal = D(252,:,1)-D(226,:,1);
    muscle_sig = 0.5*( D(233,:,1)+D(251,:,1)-D(68,:,1)-D(210,:,1) );
%elseif strcmp(sens.type,'egi64')  % Fixed QL and Dante 26/08/16
elseif round(log2(nchan))==6  % Fixed QL and Dante 26/08/16
    eye_vertical = 0.5*( D(10,:,1)+D(5,:,1)-D(63,:,1)-D(62,:,1) );    
    eye_horizontal = D(1,:,1)-D(17,:,1);    
    muscle_sig = zeros(1, size(D,2)); % we did not find channels for muscle noise in 64 channels
end

eye_vertical = eye_vertical-(smooth(eye_vertical',10*Fs,'moving'))';
eye_vertical = (smooth(eye_vertical',round(Fs/10),'moving'))';
eye_vertical = detrend(eye_vertical')';
eye_vertical = net_fir_hanning(eye_vertical,Fs,0.1,7);

eye_horizontal = eye_horizontal-(smooth(eye_horizontal',10*Fs,'moving'))';
eye_horizontal = detrend(eye_horizontal')';
eye_horizontal = (smooth(eye_horizontal',round(Fs/100),'moving'))';
eye_horizontal = eye_horizontal-sum(eye_horizontal.*eye_vertical)/sum(eye_vertical.^2)*eye_vertical;
eye_horizontal = net_fir_hanning(eye_horizontal,Fs,0.1,7);

muscle_sig = muscle_sig-(smooth(muscle_sig',100*Fs,'moving'))';
muscle_sig = detrend(muscle_sig')';
muscle_sig = muscle_sig-sum(muscle_sig.*eye_vertical)/sum(eye_vertical.^2)*eye_vertical-sum(muscle_sig.*eye_horizontal)/sum(eye_horizontal.^2)*eye_horizontal;
muscle_sig = net_fir_hanning(muscle_sig,Fs,13,80);


%Create new channels for the EOG,EMG signals
disp('Data Conversion: ADD the EOG and EMG channels...');
S=[];
S.D=D;
S.newchandata=[eye_vertical ; eye_horizontal; muscle_sig];
S.newchanlabels = [{'vEOG'},{'hEOG'},{'SWL'}];
S.newchantype = [{'EOG'},{'EOG'},{'EMG'}];


%Concatenate the channels with the existing channels
D = net_concat_chans( S );


D.save;

%%
% Revision history:
%{
2014-04-13
    v0.1 Updated the file based on initial versions from Dante and
    Quanying(Revision author : Sri).
   

%}
