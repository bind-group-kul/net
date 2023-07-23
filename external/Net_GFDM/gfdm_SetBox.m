% gfdm_SetBox.m
% Ernesto Cuartas M (ECM), 16/06/2020
% Email:  ecuartasm@gmail.com

function mri_bx = gfdm_SetBox( mri, bx, lon_sd)

mri_bx_i = mri(bx(1,1):bx(1,2), bx(2,1):bx(2,2), bx(3,1):bx(3,2) );

mri_bx = zeros(size(mri_bx_i,1)+lon_sd*2, size(mri_bx_i,2)+lon_sd*2, size(mri_bx_i,3)+lon_sd*2);
mri_bx(lon_sd:lon_sd + size(mri_bx_i,1)-1, lon_sd:lon_sd + size(mri_bx_i,2)-1, lon_sd:lon_sd + size(mri_bx_i,3)-1) = mri_bx_i;




