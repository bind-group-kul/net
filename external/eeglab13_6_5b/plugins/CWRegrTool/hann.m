function window = my_hann(length)

%
% a hann windowing function (i.e., a cos^x function) for windowing with the
% CW regression toolbox. needed if you do not have the signal-processing
% toolbox!!
%

if rem(length,2)
    % Odd length windowindowindow
    x = (0:((length+1)/2)-1)'/(length-1);
    window = 0.5 - 0.5*cos(2*pi*x);
    window = [window; window(end-1:-1:1)];
else
    % Even length windowindowindow
    x = (0:(length/2)-1)'/(length-1);
    window = 0.5 - 0.5*cos(2*pi*x);
    window = [window; window(end:-1:1)];
end


