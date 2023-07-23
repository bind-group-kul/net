function xyz_individual = net_mni2ind(xyz_mni, iy_filename)
% to transfer the coordinates in MNI space into indiviudal space
%
% xyz_mni:          N*3 matrix, for the coordinates in MNI space
% xyz_individual:   N*3 matrix, for the coordinates in individual space
% iy_filename:      the filename for deformation field
%
% Author: Quanying Liu
% Last version: 07.10.2016

% i=1;
% xyz_mni(i,:) = [-1, -45, 28]; i=i+1;  
% xyz_mni(i,:) = [-1, -50, 25]; i=i+1;  
% xyz_mni(i,:) = [  0, -46, 27]; i=i+1;  
% xyz_mni(i,:) = [  0,  38,  6]; i=i+1;  
% xyz_mni(i,:) = [  0,  40, -2]; i=i+1; 

    xyz_individual = zeros(size(xyz_mni));

    file_map = [net('path') filesep 'template' filesep 'masks' filesep 'rbrainmask.nii'];  % rbrainmask; rmask_QL
    V    = spm_vol(file_map);

    mask = zeros(V.dim);

    %% ------------------------------------------------------------------------
    % To find the ROI with 2mm sphere
    % -------------------------------------------------------------------------
    for i = 1:size(xyz_mni,1)
        ROI_center = round( ft_warp_apply( inv(V.mat),xyz_mni(i,:) ) ); % the center location

        r = 2;  % vox_size = 3; then the radius is r*vox_size mm
        rangeX = ROI_center(1)-r:1:ROI_center(1)+r;
        rangeY = ROI_center(2)-r:1:ROI_center(2)+r;
        rangeZ = ROI_center(3)-r:1:ROI_center(3)+r;
        for ii=rangeX, for jj=rangeY, for kk=rangeZ,
                    if norm([ii, jj, kk] - [ROI_center(1), ROI_center(2), ROI_center(3)]) <= r,
                        mask(ii, jj, kk) = i;
                    end
                end; end; end;
    end

    fname_ROI = 'seeds_mni.nii';
    V1 = V;
    V1.fname = fname_ROI;
    spm_write_vol(V1, mask);


    % ----------------------------------------
    % Transform the ROI from MNI space to individual space
    % -----------------------------------------
    clear matlabbatch
    matlabbatch{1}.spm.util.defs.comp{1}.def        = {iy_filename};
    matlabbatch{1}.spm.util.defs.out{1}.pull.fnames = {fname_ROI};
    matlabbatch{1}.spm.util.defs.out{1}.pull.savedir = 0;
    matlabbatch{1}.spm.util.defs.out{1}.pull.interp = 0;
    matlabbatch{1}.spm.util.defs.out{1}.pull.mask   = 0;
    matlabbatch{1}.spm.util.defs.out{1}.pull.fwhm   = [0 0 0];
    spm_jobman('run',matlabbatch);
    
    clear V1 mask ROI_center
    
    V2 = spm_vol('wseeds_mni.nii');  % read the data in individual space
    for i = 1:size(xyz_mni,1)
        [data, xyz] = spm_read_vols(V2);
        index = find( round(data(:))==i );
        xyz_individual(i,:) = mean(xyz(:,index), 2); % in mm
    end
    
    delete('wseeds_mni.nii');
    delete('seeds_mni.nii');