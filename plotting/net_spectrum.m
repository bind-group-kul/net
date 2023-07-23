function [spectrum, base] = net_spectrum(trace_in, Fs, display_flag)
% function:  [spectrum, base] = net_spectrum(trace_in, Fs, display_flag)
%           to calculate the spectrum and frequency;
%           plot the spectrum of EEG data
%
% input:
%     trace_in: EEG data
%     Fs: sampling frequency of EEG data
%
% output:
%     spectrum: spectrum density
%     base: frequency
%
% Example:
%     [spectrum, base] = net_spectrum(D(31,:,1), 1000, 'on')
%
% by QL, 27.03.2015

if nargin == 1||nargin>3
    error('Wrong input arguments.');
elseif nargin == 2
    display_flag = 'off';
end

if size(trace_in,2)>size(trace_in,1)
    trace_in=trace_in';
end
if size(trace_in,2)~=1
    error('Please input 1-channel EEG');
end

% trace = trace_in.*repmat(hanning(length(trace_in)),1,size(trace_in,2));
trace = trace_in;
spectrum = fft(trace).*conj(fft(trace));
base = 2*Fs*(0:length(spectrum)-1)/(2*(length(spectrum)-1));
spectrum = spectrum/length(base);

if strcmp(display_flag, 'on')||strcmp(display_flag, 'ON')
    figure;
    subplot(2,1,1); plot([1:size(trace,1)]./Fs, trace,'b');
    
    subplot(2,1,2); plot(base, spectrum,'b');
    z = min(100,Fs/4);
    axis([0 z 0 1.2*max(spectrum(base>2 & base<Fs-2))]);
    xlabel('Hertz');
end

