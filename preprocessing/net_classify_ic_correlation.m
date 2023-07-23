function [corr_channels,M_pc]=net_classify_ic_correlation(IC,REF,thres)


M_pc=corr(abs(hilbert(IC')),abs(hilbert(REF')));

list_max=max(M_pc,[],2);

corr_channels=find(list_max>thres)';

M_pc=M_pc';
