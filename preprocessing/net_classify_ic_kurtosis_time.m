function [timekurtosis_channels,kurtx] = net_classify_ic_kurtosis_time(IC,thres)

kurtx=kurtosis(IC');

timekurtosis_channels=find(kurtx>thres);
