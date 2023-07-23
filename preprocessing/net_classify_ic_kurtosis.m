function [kurtosis_channels,kurtx,kurty] = net_classify_ic_kurtosis(IC,A,n_std)


kurtx=kurtosis(IC');
tx=net_tukey(kurtx,n_std);

kurty=kurtosis(A);
ty=net_tukey(kurtx,n_std);

kurtosis_channels=unique([tx ty]);
