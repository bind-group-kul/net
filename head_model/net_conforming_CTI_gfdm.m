% net_conforming_CTI_gfdm.m
% Ernesto Cuartas M (ECM), 16/06/2020
% Email:  ecuartasm@gmail.com

function net_conforming_CTI_gfdm(cti_filename_orig, cti_filename, segimg_filename, bx_filename, options_leadfield, options_Nifti_scale)

if exist(cti_filename_orig,'file')
    
    NET_folder=net('path');
    
    CTI = ft_read_mri(cti_filename_orig);
    cti_rs = gfdm_reslice_CTI(CTI);
    
    load(bx_filename);
    cti_bx = gfdm_SetBox_CTI(cti_rs, Box_s);
    clear CTI
    clear cti_rs
        
    mri_subject = ft_read_mri(segimg_filename, 'dataformat', 'nifti_spm');

    conductivity = load([NET_folder filesep 'template' filesep 'tissues_MNI' filesep options_leadfield.conductivity '.mat']);
    
    nlayers = max(mri_subject.anatomy(:));
    
    cond_image = zeros(size(mri_subject.anatomy));
    for i = 1:nlayers
        cond_image(mri_subject.anatomy == i) = conductivity.cond_value(i);
    end
    
    switch nlayers
        case 12
            st_vle = 4;
        case 6
            st_vle = 2;
        case 3
            st_vle = 1;
    end
    
    brn_mask = zeros(size(mri_subject.anatomy));
    brn_mask(mri_subject.anatomy <= st_vle & mri_subject.anatomy > 0) = 1.0;
    
    c_11 = squeeze(cti_bx.anatomy(:,:,:,1)) .* brn_mask;
    c_12 = squeeze(cti_bx.anatomy(:,:,:,2)) .* brn_mask;
    c_13 = squeeze(cti_bx.anatomy(:,:,:,3)) .* brn_mask;
    c_22 = squeeze(cti_bx.anatomy(:,:,:,4)) .* brn_mask;
    c_23 = squeeze(cti_bx.anatomy(:,:,:,5)) .* brn_mask;
    c_33 = squeeze(cti_bx.anatomy(:,:,:,6)) .* brn_mask;
    
    segment = mri_subject.anatomy;
    cti_A    = zeros(size(c_11,1),size(c_11,2), size(c_11,3),6);
    cnd_sphr = zeros(size(c_11,1),size(c_11,2), size(c_11,3));
    for a = 1:size(segment,1)
        for b = 1:size(segment,2)
            for c = 1:size(segment,3)
                if(segment(a,b,c))
                    if(segment(a,b,c) <= st_vle)
                        if(c_11(a,b,c)) 
                            cti_v = options_Nifti_scale*[ c_11(a,b,c), c_12(a,b,c), c_13(a,b,c), c_22(a,b,c), c_23(a,b,c), c_33(a,b,c) ];
                        else       
                            cti_p = eye(3)*cond_image(a,b,c);
                            cti_v = [ cti_p(1,1) cti_p(1,2) cti_p(1,3) cti_p(2,2) cti_p(2,3) cti_p(3,3) ];
                        end
                    else
                        cti_p = eye(3)*cond_image(a,b,c);
                        cti_v = [ cti_p(1,1) cti_p(1,2) cti_p(1,3) cti_p(2,2) cti_p(2,3) cti_p(3,3) ];
                    end
                    cti_A(a,b,c,:) = cti_v;
                end
            end
        end
    end
    
    cti_bx.anatomy   = cti_A;
    cti_bx.transform = mri_subject.transform;
    ft_write_mri_N(cti_filename, cti_bx, 'dataformat', 'nifti');
end