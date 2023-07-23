function hms=net_secs2hms(time_in_secs)
    
    hms=[0 0 0];
    if time_in_secs >= 3600
        hms(1) = floor(time_in_secs/3600);
    end
    if time_in_secs >= 60
        hms(2) = floor((time_in_secs - 3600*hms(1))/60);
    end
    hms(3) = time_in_secs - 3600*hms(1) - 60*hms(2);
end