function net_ers_erd_mapping(source_filename,options_ers_erd)

if strcmp(options_ers_erd.mapping_enable,'on')
               
NET_folder = net('path');

dd=fileparts(fileparts(source_filename));

deformation_to_mni=[dd filesep 'mr_data' filesep 'iy_anatomy_prepro.nii'];

tpmref_filename=[NET_folder filesep 'template' filesep 'tissues_MNI' filesep 'eTPM6.nii'];


load(source_filename,'source');


dd2=[dd filesep 'ers_erd_results'];

if ~isdir(dd2)
    mkdir(dd2);  % Create the output folder if it doesn't exist..
end

%% generating epochs

Fs=1/(source.time(2)-source.time(1));

hp=options_ers_erd.highpass;

lp=options_ers_erd.lowpass;

%filtered_data=net_filterdata(1000*source.sensor_data,Fs,hp,lp);

time_range=str2num(options_ers_erd.time_range);

filtered_data=1000*source.sensor_data;


%%

vox_indices=find(source.inside==1);

nvoxels=length(vox_indices);

xdim    = source.dim(1);
ydim    = source.dim(2);
zdim    = source.dim(3);

mat=net_pos2transform(source.pos, source.dim);
res=abs(det(mat(1:3,1:3)))^(1/3); 



    large_window = 1; % window length in sec
    step_window  = 0.1; % step length in sec
    frequencies  = [1:lp]; % in Hz    ??
    
     window2 = hann( round(Fs*large_window) ); % in points/samples
    overlap = round( Fs*(large_window-step_window)); % in points/samples (integer)

Fs_new=(1/step_window);

ers_erd_maps=zeros(nvoxels,length(frequencies));

for k=1:nvoxels
    
    sigx=source.imagingkernel(1+3*(k-1),:)*filtered_data;
    
    sigy=source.imagingkernel(2+3*(k-1),:)*filtered_data;
    
    sigz=source.imagingkernel(3*k,:)*filtered_data;
    
    [~, F, T, Px] = spectrogram(sigx, window2, overlap, frequencies, Fs);
    
    [~, F, T, Py] = spectrogram(sigy, window2, overlap, frequencies, Fs);
    
    [~, F, T, Pz] = spectrogram(sigz, window2, overlap, frequencies, Fs);
    
    % Sum the three PSDs for each 'seed' voxel
    Ptot = Px+Py+Pz;
    
    
    epoched_ers_erd = net_ers_erd(Ptot,Fs_new,source.events,options_ers_erd);
    
    ers_erd_mat = net_robustaverage(epoched_ers_erd,options_ers_erd);
    
    ss=ceil(Fs_new/1000*(time_range(1)-options_ers_erd.pretrig));
    ee=fix(Fs_new/1000*(time_range(2)-options_ers_erd.pretrig));
           
    ers_erd_maps(k,:) = mean(ers_erd_mat(:,[ss:ee]),2)';
   
end



% ==================================================
% 3. Save the ica_map and transform into MNI space
% 3.1 write ica_map Z-score into 'nifit' files
Vt.dim      = source.dim;
Vt.pinfo    = [0.001 ; 0 ; 0];
Vt.dt       = [16 0];
Vt.fname    = [dd2 filesep 'ers_erd_maps.nii'];
Vt.mat      = net_pos2transform(source.pos, source.dim);

for i = 1:size(ers_erd_maps,2)
    %disp(['NET - saving correlation map of IC ' num2str(i)]);
    Vt.n        = [i 1];
    image       = ers_erd_maps(:,i);
    ers_erd_image   = zeros(xdim*ydim*zdim,1);
    ers_erd_image(vox_indices) = image;
    ers_erd_image   = reshape(ers_erd_image, xdim, ydim, zdim);
    spm_write_vol(Vt, ers_erd_image);
end


net_warp([dd2 filesep 'ers_erd_maps.nii'],deformation_to_mni,tpmref_filename);
           
end
