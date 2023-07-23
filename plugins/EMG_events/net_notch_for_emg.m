%% Purpose
% 1. This functions is used for performing notch filter for 50 Hz.

%%
function data_out=net_notch_for_emg(data_in,Fs)

%% Making sure the number of rows are bigger, because the filtering
% operation happens columnwise(time domain)
if size(data_in,2)>size(data_in,1)
    data_out=data_in';
else
    data_out=data_in;
end

%% These are the stop band limits
stop_bands = [  49.95, 50.05;       %notch 50Hz
                99.95, 100.05;      %notch 100Hz
                149.95, 150.05;     %notch 150Hz
                199.95, 200.05;     %notch 200Hz
                249.95 250.05;      %notch 250Hz
                299.95 300.05       %notch 300Hz
                349.95 350.05       %notch 350Hz
                                ];
                            
%% start filtering
%We design a 1st order cheby filter with 10 db attenuation in stop band
bands_num = size(stop_bands, 1);
for iter_bands = 1:1:bands_num
    
    %We flip the data and do the filtering again, to produce zero phase
    %distortion
    [b,a]=cheby2(1,10,stop_bands(iter_bands, : )*2/Fs,'stop');
    
    data_out=filter(b,a,data_out);
    
    data_out=flipud(data_out);
    data_out=filter(b,a,data_out);
    
    data_out=flipud(data_out);


    % - Additional attenuation
    [b,a]=cheby2(1,10,stop_bands(iter_bands, :)*2/Fs,'stop');
    
    data_out=filter(b,a,data_out);
    
    data_out=flipud(data_out); 
    data_out=filter(b,a,data_out);
    
    data_out=flipud(data_out);
end
%%%%%%%%%%



if size(data_in,2)>size(data_in,1)
    data_out=data_out';
end
%%
% Revision history:
%{
2014-04-13 
    v0.1 Updated the file based on initial versions from Dante
(Revision author : Sri).
   

%}