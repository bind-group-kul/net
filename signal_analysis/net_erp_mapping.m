function net_erp_mapping(source_filename,options_erp)


if strcmp(options_erp.mapping_enable,'on')
           

NET_folder = net('path');

dd=fileparts(fileparts(source_filename));

deformation_to_mni=[dd filesep 'mr_data' filesep 'iy_anatomy_prepro.nii'];

tpmref_filename=[NET_folder filesep 'template' filesep 'tissues_MNI' filesep 'eTPM6.nii'];


load(source_filename,'source');

[dd,ff,ext]=fileparts(source_filename);

dd2=[dd filesep 'erp_results'];

if ~isdir(dd2)
    mkdir(dd2);  % Create the output folder if it doesn't exist..
end

%% generating epochs

Fs=1/(source.time(2)-source.time(1));

filtered_data=net_filterdata(1000*source.sensor_data,Fs,options_erp.highpass,options_erp.lowpass);

Fs_ref=1000;
if not(Fs==Fs_ref)
filtered_data = (resample(double(filtered_data)',Fs_ref,Fs))';
end

epoched_data = net_epoch(filtered_data,Fs_ref,source.events,options_erp);

erp_data = net_robustaverage(epoched_data,options_erp);

%figure; plot([options_erp.pretrig+1:options_erp.posttrig],erp_data'); xlabel('time (ms)'); ylabel('a.u.'); 

%%

vox_indices=find(source.inside==1);

nvoxels=length(vox_indices);

xdim    = source.dim(1);
ydim    = source.dim(2);
zdim    = source.dim(3);

mat=net_pos2transform(source.pos, source.dim);
res=abs(det(mat(1:3,1:3)))^(1/3); 

pretrig   = round(Fs_ref*options_erp.pretrig/1000);
posttrig  = round(Fs_ref*options_erp.posttrig/1000);

erp_maps=zeros(nvoxels,posttrig);

for k=1:nvoxels
    
    sigx=source.imagingkernel(1+3*(k-1),:)*erp_data(:,-pretrig+1:posttrig-pretrig);
    
    sigy=source.imagingkernel(2+3*(k-1),:)*erp_data(:,-pretrig+1:posttrig-pretrig);
    
    sigz=source.imagingkernel(3*k,:)*erp_data(:,-pretrig+1:posttrig-pretrig);
    
    pow=sigx.^2+sigy.^2+sigz.^2;
           
    erp_maps(k,:) = pow;
   
end


% ==================================================
% 3. Save the ica_map and transform into MNI space
% 3.1 write ica_map Z-score into 'nifit' files
Vt.dim      = source.dim;
Vt.pinfo    = [0.000001 ; 0 ; 0];
Vt.dt       = [16 0];
Vt.fname    = [dd2 filesep 'erp_maps.nii'];
Vt.mat      = net_pos2transform(source.pos, source.dim);

for i = 1:size(erp_maps,2)
    %disp(['NET - saving correlation map of IC ' num2str(i)]);
    Vt.n        = [i 1];
    image       = erp_maps(:,i);
    erp_image   = zeros(xdim*ydim*zdim,1);
    erp_image(vox_indices) = image;
    erp_image   = reshape(erp_image, xdim, ydim, zdim);
    spm_write_vol(Vt, erp_image);
end

net_warp([dd2 filesep 'erp_maps.nii'],deformation_to_mni,tpmref_filename);
           

end