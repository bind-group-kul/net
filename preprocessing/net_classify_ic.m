%% Purpose
% 1. Detect the bad ICs based on correlation with the artefact signals.
% 2. Finally compare the ratio of a particular IC across different channels
% to detect bad ICs again.
%%
function [good_ics,bad_ics,stats]=net_classify_ic(comp,ref_sigs,artifact_options)

Fs=comp.fs;

IC=comp.trial_full{1};

if isfield(artifact_options,'events')

start_t=round(Fs*artifact_options.events(1).time);

end_t=round(Fs*artifact_options.events(end).time);

IC=IC(:,start_t:end_t);

ref_sigs=ref_sigs(:,start_t:end_t);

end

A=comp.topo;

corr_channels = [];
if ~strcmp(artifact_options.powcorr_thres, 'off')
    [corr_channels,stats.corr_pc] = net_classify_ic_correlation(IC,ref_sigs,artifact_options.powcorr_thres);
end

power_channels = [];
if ~strcmp(artifact_options.power_thres, 'off')
    [power_channels,stats.power] = net_classify_ic_power(IC,artifact_options.power_thres,Fs);
end

outlier_channels = [];
if ~strcmp(artifact_options.outlier_thres, 'off')
    [outlier_channels,stats.outlier] = net_classify_ic_outlier(A,artifact_options.outlier_thres);
end

timekurtosis_channels = [];
if ~strcmp(artifact_options.timekurtosis_thres, 'off')||isnan(artifact_options.timekurtosis_thres)
    [timekurtosis_channels,stats.kurtosis_time] = net_classify_ic_kurtosis_time(IC,artifact_options.timekurtosis_thres);
end

spacekurtosis_channels = [];
if ~strcmp(artifact_options.spacekurtosis_thres, 'off')||isnan(artifact_options.spacekurtosis_thres)
    [spacekurtosis_channels,stats.kurtosis_space] = net_classify_ic_kurtosis_space(A,artifact_options.spacekurtosis_thres);
end

bad_ics = unique([corr_channels power_channels outlier_channels timekurtosis_channels spacekurtosis_channels]);

good_ics = 1:size(IC,1);
good_ics(bad_ics) = [];

