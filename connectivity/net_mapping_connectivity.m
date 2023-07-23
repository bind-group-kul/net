function net_mapping_connectivity(source_filename,options_seed)

if strcmp(options_seed.map_enable,'on')
         

NET_folder = net('path');
    
dd=fileparts(fileparts(source_filename));

deformation_to_subj=[dd filesep 'mr_data' filesep 'y_anatomy_prepro.nii'];
deformation_to_mni=[dd filesep 'mr_data' filesep 'iy_anatomy_prepro.nii'];

tpmref_filename=[NET_folder filesep 'template' filesep 'tissues_MNI' filesep 'eTPM6.nii'];
         
seed_file=[NET_folder filesep 'template' filesep 'seeds' filesep options_seed.seed_file '.mat'];
seed_info=load(seed_file);
coord_subj=net_project_coord(deformation_to_subj,seed_info.seed_coord_mni);



load(source_filename,'source');

[dd,ff,ext] = fileparts(source_filename);

dd2 = [dd filesep 'seeding_results'];

if ~isdir(dd2)
    mkdir(dd2);  % Create the output folder if it doesn't exist..
end


vox_indices = find(source.inside==1);

nvoxels = length(vox_indices);

xdim    = source.dim(1);
ydim    = source.dim(2);
zdim    = source.dim(3);

%res=source.cfg.vol.resolution;

Fs = 1/(source.time(2)-source.time(1));

frequencies = [1:1:80];

xyz = source.pos(vox_indices,:)';

%coord_subj = options_seed.seed_coord_subj;

seedindx = zeros(size(coord_subj,1),1);

for i=1:size(coord_subj,1)
    
    pos  = coord_subj(i,:)';
    
    dist = sum((xyz-pos*ones(1,size(xyz,2))).^2);
    
    [~,seedindx(i)] = min(dist);
    
end



switch options_seed.connectivity_measure
    
    case 'blp_corr'
        
        winsize  = round(Fs*options_seed.window_duration);
        overlap  = round(Fs*options_seed.window_overlap);
        
        [S, F, T, P] = spectrogram(source.time, winsize, overlap, frequencies, Fs);
        
        
        FT_all = zeros(length(F),length(T),nvoxels);
        
        for k=1:nvoxels
            
            %disp(k);
            
            sigx = source.imagingkernel(1+3*(k-1),:)*source.sensor_data;
            
            sigy = source.imagingkernel(2+3*(k-1),:)*source.sensor_data;
            
            sigz = source.imagingkernel(3*k,:)*source.sensor_data;
            
            [Sx, F, T, Px] = spectrogram(sigx, winsize, overlap, frequencies, Fs);
        
            [Sy, F, T, Py] = spectrogram(sigy, winsize, overlap, frequencies, Fs);
        
            [Sz, F, T, Pz] = spectrogram(sigz, winsize, overlap, frequencies, Fs);
        
            FT_all(:,:,k) = Sx+Sy+Sz;
           
        end
        
        corr_map = zeros(length(seedindx),nvoxels,length(F));
        
        if strcmp(options_seed.orthogonalize,'on') %%%% "option.SEED" modified by JS
            
            for k = 1:length(seedindx)
                Si = FT_all(:,:,seedindx(k))';
                for w = 1:nvoxels
                    Sj = FT_all(:,:,w)';
                    corr_map(k,w,:) = net_orthogonalize_corr(Si, Sj);
                end
            end
            
        else
            for k = 1:length(seedindx)
                Si = FT_all(:,:,seedindx(k))';
                for w = 1:nvoxels
                    Sj = FT_all(:,:,w)';
                    for f = 1:length(F)
                        corr_map(k,w,f) = corr(Si(:,f), Sj(:,f));
                    end
                end
            end
        end
            
         vect_f = (F>options_seed.highpass & F<options_seed.lowpass);
            
         seed_map = mean(corr_map(:,:,vect_f),3)';
        
        
        Vt.dim      = source.dim;
        Vt.pinfo    = [0.000001 ; 0 ; 0];
        Vt.dt       = [16 0];
        Vt.fname    = [dd2 filesep 'seed_maps.nii'];
        Vt.mat      = net_pos2transform(source.pos, source.dim);
        
        
        for i=1:size(seed_map,2)
            
            Vt.n         = [i 1];
            image        = seed_map(:,i);
            seed_image   = zeros(xdim*ydim*zdim,1);
            seed_image(vox_indices) = image;
            seed_image   = reshape(seed_image, xdim, ydim, zdim);
            spm_write_vol(Vt, seed_image);
            
        end
        
    otherwise
        
        t  = source.time;
        
        new_Fs = str2double(options_seed.fs);
        
        t_res = resample(t,new_Fs,Fs);
        
        Ntime = length(t_res);
        
        brain_signals = zeros(Ntime,nvoxels);
        
        
        for k=1:nvoxels
            
            sigx = source.imagingkernel(1+3*(k-1),:)*source.sensor_data;
            
            sigy = source.imagingkernel(2+3*(k-1),:)*source.sensor_data;
            
            sigz = source.imagingkernel(3*k,:)*source.sensor_data;
            
            [~,score] = pca(resample([sigx ; sigy ; sigz]',new_Fs,Fs));
            
            brain_signals(:,k) = score(:,1);
            
        end
        
        if strcmp(options_seed.orthogonalize,'on') %%%% "options_SEED" modified by JS
            
            [coeff_tot,score_tot] = pca(brain_signals);
            
            brain_signals = brain_signals-score_tot(:,1)*coeff_tot(:,1)';
            
        end
        
        options_connphase.Fs       = new_Fs;
        options_connphase.window_duration = options_seed.window_duration;
        options_connphase.method   = options_seed.connectivity_measure;
        options_connphase.seedindx = seedindx;
        options_connphase.maxLag   = options_seed.maxLag;
        
        
        [map2i, mapFROMi,freq] = net_phaseconn_map(brain_signals,options_connphase);
        
        if not(isempty(freq))
            vect_f = find(freq>options_seed.highpass & freq<options_seed.lowpass);
            
            seed_in  = mean(map2i(:,:,vect_f),3);
            seed_out = mean(mapFROMi(:,:,vect_f),3);
            
        else
            
            seed_in  = map2i;
            seed_out = mapFROMi;
        end
        
        
        
        Vt1.dim      = source.dim;
        Vt1.pinfo    = [0.000001 ; 0 ; 0];
        Vt1.dt       = [16 0];
        Vt1.fname    = [dd2 filesep 'seed_in_maps.nii'];
        Vt1.mat      = net_pos2transform(source.pos, source.dim);
        
        Vt2.dim      = source.dim;
        Vt2.pinfo    = [0.000001 ; 0 ; 0];
        Vt2.dt       = [16 0];
        Vt2.fname    = [dd2 filesep 'seed_out_maps.nii'];
        Vt2.mat      = net_pos2transform(source.pos, source.dim);
        
        
        for i=1:size(seed_in,2)
            
            Vt1.n        = [i 1];
            image        = seed_in(:,i);
            seed_image   = zeros(xdim*ydim*zdim,1);
            seed_image(vox_indices) = image;
            seed_image   = reshape(seed_image, xdim, ydim, zdim);
            spm_write_vol(Vt1, seed_image);
            
            
            Vt2.n        = [i 1];
            image        = seed_out(:,i);
            seed_image   = zeros(xdim*ydim*zdim,1);
            seed_image(vox_indices) = image;
            seed_image   = reshape(seed_image, xdim, ydim, zdim);
            spm_write_vol(Vt2, seed_image);
            
            
        end
        
        
end

net_warp([dd2 filesep 'seed*maps.nii'],deformation_to_mni,tpmref_filename);
           
end
