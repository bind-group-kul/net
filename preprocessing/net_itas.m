function [eeg_corr,max_scans,B,shift]=net_itas(eeg,marker,interpol,interval,fs,weighting,epochs,low_correlation,maxshift,d)
% This script corrects one single EEG channel for MR gradient artifacts.
% Input:
%
% eeg:              single EEG channel data
% marker:           markers defining the onset of the MR gradient 
%
% Additional input variables and recommended values:
%
% interpol:         defines upsampling of data to increase accuracy (and calculation time)
%                   recommended value = 10
% interval:         defines interval to be corrected, relative to MR
%                   gradient onset
% fs:               samplingrate of EEG data
% weighting:        defines neighbourhood function for artifact template building
%                   recommended value = 0.9
% epochs:           number of epochs in data to correct (subsets are possible)
% low_correlation:  defines exclusion criterion for "bad" artifact epochs,
%                   recommended value = 0.975
% maxshift:         higher value increases maximum shift window and
%                   therefore increases computing time
%                   recommended value = 0.1
% d:                number of epochs to integrate in template for sliding average
%                   recommended value: anything smaller than the number of epochs to correct 
% Output:           
%
% eeg_corr:         corrected eeg
% max_scans:        maximum correlation of single epochs with reference
%                   template
% B                 template
% shift             shift of single epochs to maximize correlation
%
% Example: 
% [eeg_corr,max_scans,B,shift]=itas(eeg,markers,10,[-50 2100],5000,0.9,120,0.975,0.1,10);
% NB: This artifact removal approach does not include any filtering.
%
% Used sub-routines are shift_scans and pulse_subtraction.
%
% Written by members of the EEG-fMRI group, BNIC. Contributions by Robert
% Becker, Petra Ritter and former group members.
% _________________________________________________________________________
% Ritter P, Becker R, Graefe C, Villringer A (2007) Evaluating gradient
% artifact correction of EEG data acquired simultaneously with fMRI. Magn
% Reson Imaging [Epub ahead of print]
% -------------------------------------------------------------------------

% Script Version: 2007/06/08

% Initialization
method='spline';
onset=interval(1,1)*fs/1000;
correlation=0;
loop=0;

% Segmentation of EEG data according to scan start markers
%h=waitbar(0,'Segmentierung');
for j=1:epochs
    A(j,:)=eeg(marker(j)+interval(1)*(fs/1000):marker(j)+interval(2)*(fs/1000));
    %waitbar((j/epochs),h);
end;
%close(h);
clear cc_scans max_scans;

A=double(A);

% if correlation is poor on average, possibly reference artifact is
% non-optimal, another one will be chosen

while correlation<0.9
    loop=loop+1;
    fprintf(['\n Need  ' num2str(loop) ' run(s) to optimize correlation.']);
    
    % Choose random artifact for reference
    randomscan=ceil(rand*epochs);

    fprintf(['\n  Artifact epoch nr. ' num2str(randomscan) ' will be used as reference artifact.']);

    % Interpolation of reference artifact
    %h=waitbar(0,'Interpolation der Referenz');
    A_ref=interp1([0:size(A,2)-1],A(randomscan,:),[0:(1/interpol):size(A,2)-1],method);
    %waitbar(1/size(A,1),h);
    %close(h);

    % Calculation of optimal shifts of markers
    %m=waitbar(0,'Find optimal shift (correlation...)');

    % Single scans are shifted optimally with reference to A_ref
    % Loop over scans
    artif=[];
    
    clear max_scans A_shift shift;
    
    for o=[1:(size(A,1))]
        [cc_scans,A_shift(o,:),shift(o)]=net_shift_scans(A(o,:),A_ref,interpol,method,onset,maxshift);
        max_scans(:,:,o)=cc_scans;
        %waitbar(o/size(A,1),m);
        % If actual artifact epoch shows poor correlation 
        % then ignore for further template building
        if cc_scans<low_correlation
            %Setting up "Ignore" matrix
            artif=[artif o];
        end
    end
    %close(m);
    
    max_scans=squeeze(max_scans);
    max_without_artif=setdiff(max(max_scans),max(max_scans(:,artif)));
    
    % Checks for appropriate choice of reference artifact
    % by estimating the average success of scan shifting
    correlation=mean(max_without_artif);
end

fprintf(['\n' num2str(length(artif)) ' artifact epochs have to be ignored because of low correlation. \n']);
   
% Actual shifting of markers
marker_shift=marker;
marker_shift(1:epochs)=marker(1:epochs)+shift';

% Clean up to save memory 
clear A;

% Artefact correction for shifted data
% Actual template subtraction
% ----------------------
[B,C]=net_pulse_subtraction(A_shift',d,weighting,-onset,artif);

% Replacing uncorrected segments by corrected ones

% Initialization
eeg_corr=eeg;

for j=1:epochs
    eeg_corr(round(marker_shift(j))+interval(1)*fs/1000:round(marker_shift(j))+interval(2)*fs/1000)=C(:,j);
end