% net_conforming_CTI_gfdm.m
% Ernesto Cuartas M (ECM), 16/06/2020
% Email:  ecuartasm@gmail.com

function cti_rs = gfdm_reslice_CTI(CTI)

c11 = CTI; c12 = CTI; c13 = CTI; c22 = CTI; c23 = CTI; c33 = CTI;
cti_rs = CTI;

c11.anatomy = CTI.anatomy(:,:,:,1);
c12.anatomy = CTI.anatomy(:,:,:,2);
c13.anatomy = CTI.anatomy(:,:,:,3);
c22.anatomy = CTI.anatomy(:,:,:,4);
c23.anatomy = CTI.anatomy(:,:,:,5);
c33.anatomy = CTI.anatomy(:,:,:,6);

cfg     = [];
cfg.dim = CTI.dim;

c11_rs = ft_volumereslice(cfg,c11);
c12_rs = ft_volumereslice(cfg,c12);
c13_rs = ft_volumereslice(cfg,c13);
c22_rs = ft_volumereslice(cfg,c22);
c23_rs = ft_volumereslice(cfg,c23);
c33_rs = ft_volumereslice(cfg,c33);

cti_rs.anatomy(:,:,:,1) = c11_rs.anatomy;
cti_rs.anatomy(:,:,:,2) = c12_rs.anatomy;
cti_rs.anatomy(:,:,:,3) = c13_rs.anatomy;
cti_rs.anatomy(:,:,:,4) = c22_rs.anatomy;
cti_rs.anatomy(:,:,:,5) = c23_rs.anatomy;
cti_rs.anatomy(:,:,:,6) = c33_rs.anatomy;


    
    
