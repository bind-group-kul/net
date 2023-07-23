clear all
close all
clc


script_dir=fileparts(which('electrode_detection_script.m'));
addpath(genpath(script_dir));



xls_data=xls2struct('mr_electrode_detection.xls','data');
xls_params=xls2struct('mr_electrode_detection.xls','parameters');



electrode_size=xls_params(1).parameters_data;
electrode_distance=xls_params(2).parameters_data;
coeff=xls_params(3).parameters_data;
glass_dimension=xls_params(4).parameters_data;
image_threshold=xls_params(5).parameters_data;
image_threshold_bis=xls_params(6).parameters_data;
image_threshold_tris=xls_params(7).parameters_data;
sensorfile=xls_params(8).parameters_data;
template_file=xls_params(9).parameters_data;

sensor_folder=[script_dir filesep 'template_electrodes'];
template_folder=[script_dir filesep 'template_images'];




% SPM SETTINGS
% SPM pre-processing and template folder
spm('defaults', 'FMRI');

spm_jobman('initcfg');


spm('defaults', 'FMRI');

spm_jobman('initcfg');

spm_dir=spm('Dir');


% ANALYSIS
for qq= 1:length(xls_data) % select the subjects for analysis
    
    if strcmp(xls_data(qq).enable,'on')
        
        [folder,net_file,ext]=fileparts(xls_data(qq).mr_filename);
        net_file=[net_file ext];
        
        results_dir=xls_data(qq).output_folder;
        mkdir(results_dir);
        
        processed_dir=[xls_data(qq).output_folder filesep 'tmp' num2str(qq)];
        mkdir(processed_dir);
        
        copyfile([script_dir filesep 'mr_electrode_detection.xls'],[results_dir filesep net_file(1:end-4) '_electrodes.xls']);
        
        % Resampling the dataset to get the same dimensions in each direction
        
        
        if not(exist([processed_dir filesep 'template_electrode_points_mnispace.mat'],'file'))
        
        spm_smooth([folder filesep net_file],[processed_dir filesep 's' net_file],[1 1 1],0);  % smoothing at 1 mm FWHM
        
        
        if not(exist([processed_dir filesep 'ms' net_file],'file'))
            
            
            clear matlabbatch
            
            
            % Run BIAS regularisation, BIAS FWHM, segmentation on the with_net image
            matlabbatch{1}.spm.spatial.preproc.channel.vols = {[processed_dir filesep 's' net_file]}; %Input volume on which seg takes place
            matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.0001; %Bias regularisation
            matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 30; %Bias FWHM
            matlabbatch{1}.spm.spatial.preproc.channel.write = [0 1]; %Save the bias corrected image; saved with prefix 'm'
            matlabbatch{1}.spm.spatial.preproc.tissue(1).tpm = {[template_folder filesep 'c1template.nii']};
            matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus = 2;
            matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [1 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [0 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(2).tpm = {[template_folder filesep 'c2template.nii']};
            matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus = 2;
            matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [1 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [0 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(3).tpm = {[template_folder filesep 'c3template.nii']};
            matlabbatch{1}.spm.spatial.preproc.tissue(3).ngaus = 2;
            matlabbatch{1}.spm.spatial.preproc.tissue(3).native = [1 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(3).warped = [0 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(4).tpm = {[template_folder filesep 'c4template.nii']};
            matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus = 3;
            matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [1 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(5).tpm = {[template_folder filesep 'c5template.nii']};
            matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus = 4;
            matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [1 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(6).tpm = {[template_folder filesep 'c6template.nii']};
            matlabbatch{1}.spm.spatial.preproc.tissue(6).ngaus = 2;
            matlabbatch{1}.spm.spatial.preproc.tissue(6).native = [1 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(6).warped = [0 0];
            matlabbatch{1}.spm.spatial.preproc.warp.mrf = 0;
            matlabbatch{1}.spm.spatial.preproc.warp.reg = 4;
            matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
            matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;
            matlabbatch{1}.spm.spatial.preproc.warp.write = [1 1]; %Saving forward and inverse deformation fields; saved with prefix y and iy
            
            spm_jobman('run',matlabbatch);
            
        end
        
        
        % Resampled and BIAS corrected image. It corresponds to the original
        % dataset that will be used in the following steps
        Vc=spm_vol([processed_dir filesep  'ms' net_file]);
        [imamrs,xyzcoord]=spm_read_vols(Vc);
        
        cmin=min(xyzcoord,[],2);
        cmax=max(xyzcoord,[],2);
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%
        % PART 1: Background Noise Removal
        %%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Image binarization. Threshold is defined as the 10th part of the maximum
        % value from the dataset
        
        spm_smooth([processed_dir filesep 'ms' net_file],[processed_dir filesep 'x' net_file],[2 2 2],0);  % smoothing azt 2 mm FWHM
        Vc2=spm_vol([processed_dir filesep  'ms' net_file]);
        imamrs_smooth=spm_read_vols(Vc2);
        max_imrs = prctile(imamrs_smooth(:),99.5);
        
        tx=image_threshold*max_imrs;
        
        imamrs_threshold = imamrs;
        imamrs_threshold(imamrs_smooth<=tx)=0;
        imamrs_threshold(imamrs_smooth>tx)=1;
        
        Vc.fname=[processed_dir filesep 'threshold_image.nii'];
        spm_write_vol(Vc,imamrs_threshold); %
        
        % All the connected voxels in the image are evaluated and only the ones larger
        % than the electode size are maintaned.
        BW = imamrs_threshold;
        
        CC = bwconncomp(BW);
        
        clear num
        for i=1:CC.NumObjects
            num(i)=length(CC.PixelIdxList{i});
        end
        
        
        vect=find(num>0.2*pi*electrode_size^3*abs(det(Vc.mat(1:3,1:3))));
        
        
        datan=zeros(size(BW));
        
        for pos=vect
            datan(CC.PixelIdxList{pos})=1;
        end
        
        Vc.fname=[processed_dir filesep 'mask.nii'];
        spm_write_vol(Vc,datan); %
        
        
        % Mask is applied to the original image in order to focus the attention on
        % the head and the structrures closely connected.
        masked = datan.*imamrs;
        
        Vc.fname=[processed_dir filesep 'image_masked.nii'];
        spm_write_vol(Vc,masked); %
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%
        % PART 2: Glasses removal
        %%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        % Binarization repeated with the same previousuly described modality. The
        % dataset corresponds to the masked original data. Threshold is defined as the 25th part of the maximum
        % value from the dataset
        
        max_masked = prctile(masked(:),99.5);
        
        tx2=image_threshold_bis*max_masked;
        
        masked_threshold = masked;
        masked_threshold(masked_threshold<=tx2)=0;
        masked_threshold(masked_threshold>0)=1;
        
        Vc.fname=[processed_dir filesep 'threshold_image_masked.nii'];
        spm_write_vol(Vc,masked_threshold); %
        
        
        radius = 1;
        [xgrid, ygrid, zgrid] = meshgrid(-radius:radius);
        ball = (sqrt(xgrid.^2 + ygrid.^2 + zgrid.^2) <= radius);
        
        masked_threshold = imerode(masked_threshold,ball);
        masked_threshold = imdilate(masked_threshold,ball);
        
        % Holes in the mask are filled to create an homogeneous image that will
        % be used for the glass removal part
        [masked_threshold_filled] = filling_mask(masked_threshold);
        
        Vc.fname=[processed_dir filesep 'filled_threshold_image_masked.nii'];
        spm_write_vol(Vc,masked_threshold_filled); %
        
        % All the components in the image are evaluated and only the biggest one,
        % which corresponds to the head and the surrounding structures, is
        % maintained.
        
        
        BW=masked_threshold_filled;
        
        CC = bwconncomp(BW);
        
        clear num
        for i=1:CC.NumObjects
            num(i)=length(CC.PixelIdxList{i});
        end
        
        [max_num,pos] = max(num);
        
        
        datan1=zeros(size(BW));
        datan1(CC.PixelIdxList{pos})=1;
        
        % The binarized image is dilated in order to include all the external
        % structures which are closed to the head. The dilation is run using
        % morphological operators
        
        
        radius = 3;
        [xgrid, ygrid, zgrid] = meshgrid(-radius:radius);
        ball = (sqrt(xgrid.^2 + ygrid.^2 + zgrid.^2) <= radius);
        
        mask_dilated = imdilate(datan1,ball);
        
        
        Vc.fname=[processed_dir filesep 'dilated_mask.nii'];
        spm_write_vol(Vc,mask_dilated); %
        
        
        mask_new=datan;
        mask_new(mask_dilated==1)=0;
        
        
        vc=find(xyzcoord(2,:)<0.5*(cmax(2)+cmin(2)));
        
        mask_new(vc)=0;
        
        % The biggest cluster corresponds to the biggest external structure,
        % which are the glasses
        BW = mask_new;
        
        CC = bwconncomp(BW);
        
        clear num
        for i=1:CC.NumObjects
            num(i)=length(CC.PixelIdxList{i});
        end
        
        
        vect = find(num>glass_dimension*abs(det(Vc.mat(1:3,1:3))));
        
        new_datan1=zeros(size(BW));
        for pos=vect
            new_datan1(CC.PixelIdxList{pos})=1;
        end
        
        radius = 2;
        [xgrid, ygrid, zgrid] = meshgrid(-radius:radius);
        ball = (sqrt(xgrid.^2 + ygrid.^2 + zgrid.^2) <= radius);
        
        new_datan1_dilated = imdilate(new_datan1,ball);
        
        
        Vc.fname=[processed_dir filesep 'glasses.nii'];
        spm_write_vol(Vc,new_datan1_dilated); %
        
        image_masked_deglassed=masked;
        image_masked_deglassed(new_datan1_dilated==1)=0;
        
        Vc.fname=[processed_dir filesep 'image_masked_deglassed.nii'];
        spm_write_vol(Vc,image_masked_deglassed); %
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % PART 3: Retrieval of electrode image
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        % Detected components are separated through a further thresholding
        % The first stages are similar to those ones previously described for the
        % detection of glasses.
        max_newimrs = prctile(image_masked_deglassed(:),99.5);
        
        
        new_image_threshold = image_masked_deglassed;
        new_image_threshold(new_image_threshold<=tx2)=0;
        new_image_threshold(new_image_threshold>0)=1;
        
        
        Vc.fname=[processed_dir filesep 'image_masked_deglassed_thresholded.nii'];
        spm_write_vol(Vc,new_image_threshold); %
        
        [new_image_threshold_filled] = filling_mask(new_image_threshold);
        
        radius = 4;
        [xgrid, ygrid, zgrid] = meshgrid(-radius:radius);
        ball = (sqrt(xgrid.^2 + ygrid.^2 + zgrid.^2) <= radius);
        
        datan2=new_image_threshold_filled;
        datan2 = imerode(datan2,ball);
        datan2 = imdilate(datan2,ball);
        
        
        
        BW=datan2;
        
        CC = bwconncomp(BW);
        
        clear num
        for i=1:CC.NumObjects
            num(i)=length(CC.PixelIdxList{i});
        end
        
        [max_num,pos] = max(num);
        
        datanx=zeros(size(BW));
        datanx(CC.PixelIdxList{pos})=1;
        
        
        
        % Resulting binary image is eroded and dilated using morphological
        % operators. The aim is to create a slightly smaller head volume inside the
        % original head volume. The interest is on defining a border around the
        % surface of the head, where the electrodes are located
        
        radius = 2;
        [xgrid, ygrid, zgrid] = meshgrid(-radius:radius);
        ball = (sqrt(xgrid.^2 + ygrid.^2 + zgrid.^2) <= radius);
        
        datan2 = imdilate(datanx,ball);
        
        
        Vc.fname=[processed_dir filesep 'head_volume.nii'];
        spm_write_vol(Vc,datan2); %
        
        
        %%%
        Vc=spm_vol([processed_dir filesep  'ms' net_file]);
        [imamrs,xyzcoord]=spm_read_vols(Vc);
        
        Vc=spm_vol([processed_dir filesep  'head_volume.nii']);
        [head,xyzcoord]=spm_read_vols(Vc);
        
        head_model =imamrs.*head;
        
        Vc.fname=[processed_dir filesep 'head_model.nii'];
        spm_write_vol(Vc,head_model); %
        %%%
        
        radius = 4;
        [xgrid, ygrid, zgrid] = meshgrid(-radius:radius);
        ball = (sqrt(xgrid.^2 + ygrid.^2 + zgrid.^2) <= radius);
        
        datan3=datan2;
        datan3 = imdilate(datan3,ball);
        datan3 = imdilate(datan3,ball);
        datan3 = imdilate(datan3,ball);
        datan3 = imdilate(datan3,ball);
        datan3 = imdilate(datan3,ball);
        datan3 = imdilate(datan3,ball);
        
        
        
        clear matlabbatch
        
        
        matlabbatch{1}.spm.util.defs.comp{1}.def = {[processed_dir filesep 'y_s' net_file]};
        matlabbatch{1}.spm.util.defs.out{1}.push.fnames = {[template_folder filesep template_file]};
        matlabbatch{1}.spm.util.defs.out{1}.push.weight = {''};
        matlabbatch{1}.spm.util.defs.out{1}.push.savedir.saveusr = {processed_dir};
        matlabbatch{1}.spm.util.defs.out{1}.push.fov.file = {[processed_dir filesep 'iy_s' net_file]};
        matlabbatch{1}.spm.util.defs.out{1}.push.preserve = 0;
        matlabbatch{1}.spm.util.defs.out{1}.push.fwhm = [0 0 0];
        
        
        
        
        spm_jobman('run',matlabbatch);
        
        
        Vt=spm_vol([processed_dir filesep 'w' template_file]);
        mask_template=spm_read_vols(Vt);
        
        mask_template(mask_template<=0.5*max(mask_template(:)))=0;
        mask_template(mask_template>0.5*max(mask_template(:)))=1;
        
        
        
        % Creation of a contour mask around the head which includes the volume where the
        % electroded are located
        electrodes_area=datan3;
        electrodes_area(datan2==1)=0;
        electrodes_area(mask_template==0)=0;
        electrodes_area(new_datan1_dilated==1)=0;
        
        
        Vc.fname=[processed_dir filesep 'search_volume.nii'];
        spm_write_vol(Vc,electrodes_area); %
        
        
        
        electrode_image=imamrs.*electrodes_area;
        
        
        Vc.fname=[processed_dir filesep 'electrode_image.nii'];
        spm_write_vol(Vc,electrode_image); %
        
        
        % Smoothing of detected components
        fwhm=electrode_size;
        
        spm_smooth([processed_dir filesep 'electrode_image.nii'],[processed_dir filesep 'electrode_image_smoothed.nii'],[fwhm fwhm fwhm],0);
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % PART 4: Candidate electrodes detection
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        disp('Detecting candidate electrode positions...');
        
        V1=spm_vol([processed_dir filesep 'electrode_image_smoothed.nii']); %Load the data from the electrode_image
        %V1=spm_vol([intermed_dir filesep 'welectrode_image.nii']); %Load the data from the electrode_image
        [dataz,XYZ]=spm_read_vols(V1);
        
        max_dataz = prctile(dataz(electrodes_area.*imamrs_threshold==1),50);
        
        dataz(dataz<image_threshold_tris*max_dataz)=0;
        
        
        
        Vc.fname=[processed_dir filesep 'electrode_image_smoothed_thresholded.nii'];
        spm_write_vol(Vc,dataz); %
        
        
        %check the image
        
        BW = imregionalmax(dataz,26);
        CC = bwconncomp(BW);
        
        NUM=CC.NumObjects;
        
        voxinten = zeros(1,NUM);
        sizecomp= zeros(1,NUM);  % added by DM 15/07/14
        reconvoxidx = nan(NUM,3);
        
        
        for z=1:NUM     % MODIFIED BY DM 20/05/14
            index = CC.PixelIdxList{z};
            [C,Idx]= max(dataz(index)); %Get the max value of the voxel location..
            %[Idx,Wt]=centerOfGravity(dataz(vect));%Get the centre of gravity..
            %C= dataz(vect(Idx));
            voxinten(z) = C;
            %voxinten(z) = C/Wt;
            reconvoxidx(z,:) = XYZ(:,index(Idx))';
            sizecomp(z) = length(index);
        end
        
        
        reconvert_fname=[processed_dir filesep 'recontructed_electrode_points.mat'];
        save(reconvert_fname,'reconvoxidx');
        
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % PART 5: Registration of electrodes position to MNI space
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        

        
        
        template_pos=elec.chanpos(~fiducialpos,:);
        
        n_electrodes=length(template_pos);
        
        spm_dir=spm('Dir');
        
        spm_jobman('initcfg');
        
        clear matlabbatch;
        matlabbatch{1}.spm.spatial.normalise.estwrite.subj.source = {[processed_dir filesep 'ms' net_file]};
        matlabbatch{1}.spm.spatial.normalise.estwrite.subj.wtsrc = '';
        matlabbatch{1}.spm.spatial.normalise.estwrite.subj.resample = {[processed_dir filesep 'ms' net_file]};
        matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.template = { [spm_dir filesep 'toolbox/OldNorm' filesep 'T1.nii'] };
        matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.weight = '';
        matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.smosrc = 8;
        matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.smoref = 0;
        matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.regtype = 'mni';
        matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.cutoff = 25;
        matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.nits = 1;
        matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.reg = 1;
        matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.preserve = 0;
        matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.bb = [-98 -132 -160; 98 106 130];
        matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.vox = [1 1 1];
        matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.interp = 1;
        matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.wrap = [0 0 0];
        matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.prefix = 'w';
        
        spm_jobman('run', matlabbatch);
        
        
        snmat_fname=[processed_dir filesep 'ms' net_file(1:end-4) '_sn.mat'];
        
        load(snmat_fname);
        
        Q = VG.mat*inv(Affine)/VF.mat;
        invQ=inv(Q);
        
        translations= repmat(Q(1:3,4)',length(reconvoxidx),1)';
        reconvoxidx_mni=(Q(1:3,1:3)*reconvoxidx' + translations)'; %Apply the transformation to the  positions
        
        reconvert_fname=[processed_dir filesep 'recontructed_electrode_points_mni.mat'];
        save(reconvert_fname,'reconvoxidx_mni');
        
        exp=reconvoxidx_mni;
        
        
        
        V1=spm_vol([processed_dir filesep 'wms' net_file]); %Load the data from the electrode_image
        [dataz,XYZ]=spm_read_vols(V1);
        
        
        %if not(exist([processed_dir filesep 'recontructed_electrode_spheres_mnispace.nii'],'file'))
        
        datac=zeros(size(dataz)); % this is to check which points are selected
        
        
        for z=1:length(exp)
            coord=exp(z,:)';
            dist=sqrt(sum((XYZ-coord*ones(1,size(XYZ,2))).^2));
            selvox=find(dist < 15); %15
            datac(selvox)=1;
        end
        
        
        V1.fname=[processed_dir filesep 'recontructed_electrode_spheres_mnispace.nii']; %This image will be the region where we should trace for electrodes..
        spm_write_vol(V1,datac);
        
        %end
        
        
        
        %if not(exist([processed_dir filesep 'template_electrode_spheres.nii'],'file'))
        
        datac=zeros(size(dataz)); % this is to check which points are selected
        
        for z=1:length(template_pos)
            coord=template_pos(z,:)';
            dist=sqrt(sum((XYZ-coord*ones(1,size(XYZ,2))).^2));
            selvox=find(dist < 15);
            datac(selvox)=1;
        end
        
        
        V1.fname=[processed_dir filesep 'template_electrode_spheres.nii']; %This image will be the region where we should trace for electrodes..
        spm_write_vol(V1,datac);
        
        %end
        
        
        
        clear matlabbatch;
        matlabbatch{1}.spm.spatial.normalise.estwrite.subj.source = {[processed_dir filesep 'template_electrode_spheres.nii']};
        matlabbatch{1}.spm.spatial.normalise.estwrite.subj.wtsrc = '';
        matlabbatch{1}.spm.spatial.normalise.estwrite.subj.resample = {[processed_dir filesep 'template_electrode_spheres.nii']};
        matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.template = { [processed_dir filesep 'recontructed_electrode_spheres_mnispace.nii'] };
        matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.weight = '';
        matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.smosrc = 5;
        matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.smoref = 5;
        matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.regtype = 'subj';
        matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.cutoff = 25;
        matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.nits = 1;
        matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.reg = 1;
        matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.preserve = 0;
        matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.bb = [NaN NaN NaN ; NaN NaN NaN];
        matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.vox = [1 1 1];
        matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.interp = 1;
        matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.wrap = [0 0 0];
        matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.prefix = 'w';
        spm_jobman('run', matlabbatch);
        
        
        
        snmat_fname=[processed_dir filesep 'template_electrode_spheres_sn.mat'];
        
        
        
        load(snmat_fname);
        
        M = VG.mat*inv(Affine)/VF.mat;
        
        %The first 3 columns are rotations, hence multiplication, the last column
        %is translation, hence addition; %All units here are in mm space;
        
        translations= repmat(M(1:3,4)',length(template_pos),1)';
        transformedvert=(M(1:3,1:3)*template_pos' + translations)'; %Apply the transformation to the MNI positions
        
        
        
        elecvert_fname=[processed_dir filesep 'template_electrode_points_mnispace.mat'];
        save(elecvert_fname,'transformedvert');
        
        end
        
        
        
        elec = ft_read_sens([sensor_folder filesep sensorfile]);
        elec = ft_convert_units(elec, 'mm');
        
        
        %Remove the fiducials..
        fiducialpos = strcmpi('FidNz',elec.label)|strcmpi('FidT9',elec.label)|...
            strcmpi('FidT10',elec.label)|strcmpi('spmnas',elec.label)|...
            strcmpi('spmlpa',elec.label)|strcmpi('spmrpa',elec.label);
        
        fiducial_pos=elec.chanpos(fiducialpos,:);
        
        elecvert_fname=[processed_dir filesep 'template_electrode_points_mnispace.mat'];
        load(elecvert_fname,'transformedvert');
        
        reconvert_fname=[processed_dir filesep 'recontructed_electrode_points_mni.mat'];
        load(reconvert_fname,'reconvoxidx_mni');
        
        exp=reconvoxidx_mni;
        
        exp_clean=exp;
        
        distmat_exp = pdist2(exp_clean,exp_clean,'euclidean');
        
        
        
        
        mindist=electrode_distance;
        
        
        distmat_clean=distmat_exp;    % REIMPLEMENTED BY DM 20/05/14
        distmat_clean(distmat_clean==0)=NaN;
        
        
        
        while min(distmat_clean(:)) < mindist
            val=min(distmat_clean(:));
            [Xind,Yind]=find(distmat_clean==val);
            if sum(exp_clean(Xind(1),:).^2) < sum(exp_clean(Yind(1),:).^2)  % keep the point that is closer to the origin
                Rind=Yind(1);
            else
                Rind=Xind(1);
            end
            exp_clean(Rind,:)=[];
            
            
            distmat_clean(:,Rind)=[];
            distmat_clean(Rind,:)=[];
        end
        
        
        reconvert_fname=[processed_dir filesep 'recontructed_electrode_points_mni1.mat'];
        save(reconvert_fname,'exp_clean');
        
        
        vv=1;
        
        while not(isempty(vv))
            
            distmat = pdist2(exp_clean,transformedvert,'euclidean');
            
            dist_perp=zeros(1,length(exp_clean));
            for i=1:length(exp_clean)
                [val,pos]=min(distmat(i,:));
                dist_perp(i)=norm(exp_clean(i,:))-norm(transformedvert(pos,:));
            end
            
            dist_perp_sel=dist_perp(dist_perp<prctile(dist_perp,90));
            vv=find(dist_perp>mean(dist_perp_sel)+coeff*std(dist_perp_sel) ); % 4 for 256ch
            
            
            exp_clean(vv,:)=[];
            
        end
        
        reconvert_fname=[processed_dir filesep 'recontructed_electrode_points_mni2.mat'];
        save(reconvert_fname,'exp_clean');
        
        
        niter=10000;
        p_thres=0.5;
        
        model=transformedvert;
        exp_clean_tmp=exp_clean;
        
        rand('seed',0);
        col2=1;
        col=1;
        col_old=[];
        
        
        
        warning off;
        
        while not(isempty(col2)) || length(col)>length(col_old)
            
            distmat=pdist2(model,exp_clean_tmp,'euclidean');
            
            mat=zeros(size(distmat));
            %tic
            for k=1:niter
                %     disp(k);
                list=randperm(length(model));
                
                distmat_tmp = distmat;
                
                for i = list
                    posx = i;
                    [b,posy]=min(distmat_tmp(posx,:));
                    mat(posx,posy)=mat(posx,posy)+1;
                    distmat_tmp(:,posy)=NaN;
                    distmat_tmp(posx,:)=NaN;
                end
            end
            %toc
            
            mat=mat/niter;
            
            col_old=col;
            col=find(max(mat,[],1) > p_thres);
            
            %     [row,col]=find(mat == 1);
            %     disp(numel(col));
            %     disp(numel(col2));
            
            col2 = find(sum(mat,1)' == 0);
            landmarks = exp_clean_tmp(col,:);
            exp_clean_tmp(col2,:)=[];
            
            %     for i = 1:size(landmarks,1)
            %         figure(1)
            %         plot3(landmarks(i,1),landmarks(i,2),landmarks(i,3),'co');
            %         hold on
            %     end
            
            
            data1 = exp_clean_tmp;
            data2= model;
            
            
            config.model = data2;
            config.scene = data1;
            config.ctrl_pts = landmarks;
            config.init_param = zeros(size(landmarks,1),3); % same size of ctrl_points
            config.init_sigma = 0.5000;
            config.outliers = 1;
            config.lambda = 1;
            config.beta = 1;
            config.anneal_rate = 0.9700;
            config.tol = 1.0000e-18;
            config.emtol = 1.0000e-15;
            config.max_iter = 100;
            config.max_em_iter = 10;
            config.motion = 'grbf';
            
            [param, model] = gmmreg_cpd(config);
            
            
        end
        
        % exp_clean_tmp = exp_clean_tmp_attempt;
        % model = model_attempt;
        
        vv=1;
        
        while not(isempty(vv))
            
            distmat = pdist2(exp_clean_tmp,model,'euclidean');
            
            dist_perp=zeros(1,length(exp_clean_tmp));
            for i=1:length(exp_clean_tmp)
                [val,pos]=min(distmat(i,:));
                dist_perp(i)=norm(exp_clean_tmp(i,:))-norm(model(pos,:));
            end
            
            dist_perp_sel=dist_perp(dist_perp>prctile(dist_perp,5) & dist_perp<prctile(dist_perp,95));
            vv=find(dist_perp>mean(dist_perp_sel)+4*std(dist_perp_sel) ); %4 buono
            
            
            exp_clean_tmp(vv,:)=[];
            
        end
        
        
        
        
        
        
        odd=1000;
        
        max_iter=10;
        
        for cont=1:max_iter
            
            
            data1 = exp_clean_tmp;
            data2= model;
            landmarks=exp_clean_tmp;
            
            config.model = data2;
            config.scene = data1;
            config.ctrl_pts = landmarks;
            config.init_param = zeros(size(landmarks,1),3); % same size of ctrl_points
            config.init_sigma = 0.5000;
            config.outliers = 1;
            config.lambda = 1;
            config.beta = 1;
            config.anneal_rate = 0.9700;
            config.tol = 1.0000e-18;
            config.emtol = 1.0000e-15;
            config.max_iter = 100;
            config.max_em_iter = 10;
            config.motion = 'grbf';
            
            [param, model] = gmmreg_cpd(config);
            
            distmat = pdist2(data1,model,'euclidean');
            
            dd=min(distmat,[],1);
            
            odd_old=odd;
            
            odd=mean(dd);
            
            perf=(odd_old-odd)/odd_old;
            
            %disp(perf);
            
        end
        
        
        
        distmat_exp = pdist2(model,exp_clean_tmp,'euclidean');
        
        
        
        snmat_fname=[processed_dir filesep 'ms' net_file(1:end-4) '_sn.mat'];
        
        load(snmat_fname);
        
        % Detected electrodes are transformed back to the individual space (from MNI)
        
        Q = VG.mat*inv(Affine)/VF.mat;
        invQ=inv(Q);
        
        detected=exp_clean_tmp;
        
        translations = repmat(invQ(1:3,4)',length(detected),1)';
        detected_subj =(invQ(1:3,1:3)*detected' + translations)'; %Apply the transformation to the  positions
        
        
        
        V1=spm_vol([processed_dir filesep 'electrode_image_smoothed.nii']); %Load the data from the electrode_image
        
        
        [dataz,XYZ]=spm_read_vols(V1);
        
        dataw=zeros(size(dataz));   % this is to check which points are selected
        
        for z=1:length(detected_subj)
            %disp(z);
            coord=detected_subj(z,:)';
            dist=sqrt(sum((XYZ-coord*ones(1,size(XYZ,2))).^2));
            selvox=find(dist < 5);
            dataw(selvox)=1;
        end
        
        
        V1.fname=[processed_dir filesep 'detected_points_new.nii']; %This image will be the region where we should trace for electrodes..
        spm_write_vol(V1,dataw);
        
        
        
        recontructed=model;
        
        translations = repmat(invQ(1:3,4)',length(recontructed),1)';
        recontructed_subj =(invQ(1:3,1:3)*recontructed' + translations)'; %Apply the transformation to the  positions
        
        
        
        
        
        reconvert_fname=[processed_dir filesep 'electrode_positions.mat'];
        save(reconvert_fname,'recontructed_subj');
        
        elec = ft_read_sens([sensor_folder filesep sensorfile]);
        elec = ft_convert_units(elec, 'mm');
        
        
        %Remove the fiducials..
        realelectpos = strcmpi('FidNz',elec.label)|strcmpi('FidT9',elec.label)|...
            strcmpi('FidT10',elec.label);
        
        
        pos_mni = [fiducial_pos ; recontructed];
        
        translations = repmat(invQ(1:3,4)',length(pos_mni),1)';
        pos_subj =(invQ(1:3,1:3)*pos_mni' + translations)'; %Apply the transformation to the  positions
        
        
        
        fileID = fopen([results_dir filesep net_file(1:end-4) '_electrodes.sfp'],'w');
        
        for i=1:size(pos_subj,1)
            if i==1
                label='FidNz';
            elseif i==2
                label='FidT9';
            elseif i==3
                label='FidT10';
            else
                label=['E' num2str(i-3)];
            end
            fprintf(fileID,'%s\t%f\t%f\t%f\n',label, pos_subj(i,1), pos_subj(i,2), pos_subj(i,3));
        end
        
        fclose(fileID);
        
        %
        
        V1=spm_vol([processed_dir filesep 'electrode_image_smoothed.nii']); %Load the data from the electrode_image
        
        [dataz,XYZ]=spm_read_vols(V1);
        
        dataw=zeros(size(dataz));   % this is to check which points are selected
        
        for z=1:length(pos_subj)
            %disp(z);
            coord=pos_subj(z,:)';
            dist=sqrt(sum((XYZ-coord*ones(1,size(XYZ,2))).^2));
            selvox=find(dist < 5);
            if z <= 3
                dataw(selvox)=2;
            else
                dataw(selvox)=1;
            end
        end
        
        
        V1.fname=[results_dir filesep net_file(1:end-4) '_electrodes.nii']; %This image will be the region where we should trace for electrodes..
        spm_write_vol(V1,dataw);
        
        %rmdir(processed_dir,'s');
        
        
        
        
    end
end