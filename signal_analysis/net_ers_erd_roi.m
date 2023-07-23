function net_ers_erd_roi(source_filename,options_ers_erd)

if strcmp(options_ers_erd.roi_enable,'on')
            
dd=fileparts(fileparts(source_filename));

deformation_file=[dd filesep 'mr_data' filesep 'y_anatomy_prepro.nii'];

NET_folder = net('path');
seed_file=[NET_folder filesep 'template' filesep 'seeds' filesep options_ers_erd.seed_file '.mat'];
seed_info=load(seed_file);
coord_subj=net_project_coord(deformation_file,seed_info.seed_coord_mni);


load(source_filename,'source');

[dd,ff,ext]=fileparts(source_filename);

dd2=[dd filesep 'ers_erd_results'];

if ~isdir(dd2)
    mkdir(dd2);  % Create the output folder if it doesn't exist..
end

%% generating epochs

Fs=1/(source.time(2)-source.time(1));

hp=options_ers_erd.highpass;

lp=options_ers_erd.lowpass;

%filtered_data=net_filterdata(1000*source.sensor_data,Fs,hp,lp);

filtered_data=1000*source.sensor_data;

%%
xyz = source.pos(source.inside==1,:)';

%coord_subj = options_ers_erd.seed_coord_subj;

seedindx = zeros(size(coord_subj,1),1);

for i=1:size(coord_subj,1)
    
    pos  = coord_subj(i,:)';
    
    dist = sum((xyz-pos*ones(1,size(xyz,2))).^2);
    
    [~,seedindx(i)] = min(dist);
    
end
%%



large_window = 1; % window length in sec
step_window  = 0.1; % step length in sec
frequencies  = [1:lp]; % in Hz    ??

window2 = hann( round(Fs*large_window) ); % in points/samples
overlap = round( Fs*(large_window-step_window)); % in points/samples (integer)

Fs_new=(1/step_window);


for i=1:size(coord_subj,1)
    
    k=seedindx(i);
    
    sigx=source.imagingkernel(1+3*(k-1),:)*filtered_data;
    
    sigy=source.imagingkernel(2+3*(k-1),:)*filtered_data;
    
    sigz=source.imagingkernel(3*k,:)*filtered_data;
    
    [~, F, T, Px] = spectrogram(sigx, window2, overlap, frequencies, Fs);
    
    [~, F, T, Py] = spectrogram(sigy, window2, overlap, frequencies, Fs);
    
    [~, F, T, Pz] = spectrogram(sigz, window2, overlap, frequencies, Fs);
    
    % Sum the three PSDs for each 'seed' voxel
    Ptot = Px+Py+Pz;

    [epoched_ers_erd,times] = net_ers_erd(Ptot,Fs_new,source.events,options_ers_erd);
    
    ers_erd_mat = net_robustaverage(epoched_ers_erd,options_ers_erd);

    if i==1
        
        ers_erd_matrix=zeros(size(coord_subj,1),length(frequencies),length(times));

    end
           
    ers_erd_matrix(i,:,:) = ers_erd_mat;
   
end


save([dd2 filesep 'ers_erd_matrix.mat'],'ers_erd_matrix','frequencies','times','options_ers_erd'); 
 

end