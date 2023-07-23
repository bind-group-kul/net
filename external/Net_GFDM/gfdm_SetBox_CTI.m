% gfdm_BoxMri.m
% Ernesto Cuartas M (ECM), 16/06/2020
% Email:  ecuartasm@gmail.com

function cti_bx = gfdm_SetBox_CTI(CTI, Box)

cti_bx = CTI;
data   = CTI.anatomy;
bx     = Box.bx;
lon_sd = Box.lon_sd;

mri_bx_i = data(bx(1,1):bx(1,2), bx(2,1):bx(2,2), bx(3,1):bx(3,2),: );

data_bx = zeros(size(mri_bx_i,1)+lon_sd*2, size(mri_bx_i,2)+lon_sd*2, size(mri_bx_i,3)+lon_sd*2,6);
data_bx(lon_sd:lon_sd + size(mri_bx_i,1)-1, lon_sd:lon_sd + size(mri_bx_i,2)-1, lon_sd:lon_sd + size(mri_bx_i,3)-1,:) = mri_bx_i;
dim    = [size(data_bx,1) size(data_bx,2) size(data_bx,3) ];

cti_bx.anatomy   = data_bx;
cti_bx.transform = Box.transform;
cti_bx.dim       = dim;
cti_bx.hdr.dim   = dim;




