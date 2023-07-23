% gfdm_cti_downsample.m
% Ernesto Cuartas M (ECM), 06/04/2017
% Updated: 02/06/2020
% Email:  ecuartasm@gmail.com

function cti_ds = gfdm_cti_downsample(cfg,CTI)

segment = CTI.anatomy;
dw_s = cfg.downsample;

cti_r = zeros(length(1:dw_s:size(segment,1)), length(1:dw_s:size(segment,2)), length(1:dw_s:size(segment,3)), 6);

for a = 1:size(cti_r,1)
    for b = 1:size(cti_r,2)
        for c = 1:size(cti_r,3)  
            cti_r(a,b,c,:) = segment((2*a-1),(2*b-1),(2*c-1),:);
        end
    end
end

cti_ds = CTI;
cti_ds.dim = [length(1:dw_s:size(segment,1)), length(1:dw_s:size(segment,2)), length(1:dw_s:size(segment,3))];
cti_ds.anatomy = cti_r;