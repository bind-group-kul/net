function [spacekurtosis_channels,kurty] = net_classify_ic_kurtosis_space(A,thres)


kurty=kurtosis(A);

spacekurtosis_channels=find(kurty>thres);
