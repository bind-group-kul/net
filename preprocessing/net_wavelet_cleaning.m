function D = net_wavelet_cleaning(D, wavelet_option)
% description: denoise by wavelet
%   n = 1, 2, 3
%   p = 0 - not plot figures; 1 - plot figures
% e.g D = net_wavelet_cleaning(D, 3, 0)
%
% last version: 29.10.2013
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p=0;

if nargin<2
    n=3;
elseif nargin==2
    n=wavelet_option.num;
elseif nargin>2
    error('too many parameters!');help net_wavelet_cleaning;
end

list_bch = D.badchannels;
B = sensors(D,'EEG');


list_gch = selectchannels(D,'EEG');
list_gch(list_bch) = [];

data_all = D(:,:,1);
fs = fsample(D);

% select good channels to do wavelet
data_eeg = data_all(list_gch,:);
data_eeg = data_eeg';
nchan = length(list_gch); % added by QY

data_denoise=zeros(size(data_eeg));
for i=1:nchan
    data_denoise( :, i ) = net_eliminate_art( data_eeg(:,i), fs, n);   % denoise by DB7 wavelet
end

D(list_gch,:,1) = data_denoise'; 

D.save;

disp('Artifacts detected and removed! ');

