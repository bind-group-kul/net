function net_matrix_connectivity(source_filename,options_seed)

if strcmp(options_seed.matrix_enable,'on')


dd=fileparts(fileparts(source_filename));

deformation_file=[dd filesep 'mr_data' filesep 'y_anatomy_prepro.nii'];

NET_folder = net('path');
seed_file=[NET_folder filesep 'template' filesep 'seeds' filesep options_seed.seed_file '.mat'];
seed_info=load(seed_file);
coord_subj=net_project_coord(deformation_file,seed_info.seed_coord_mni);


load(source_filename,'source');  % to save the matrix bigger than 2GB, added by QL, 04.12.2014

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
        
        
        FT_all = zeros(length(F),length(T),size(coord_subj,1));
        
        for q=1:size(coord_subj,1)
            
            k=seedindx(q);
            
            %disp(k);
            
            sigx = source.imagingkernel(1+3*(k-1),:)*source.sensor_data;
            
            sigy = source.imagingkernel(2+3*(k-1),:)*source.sensor_data;
            
            sigz = source.imagingkernel(3*k,:)*source.sensor_data;
            
            [Sx, F, T, Px] = spectrogram(sigx, winsize, overlap, frequencies, Fs);
        
            [Sy, F, T, Py] = spectrogram(sigy, winsize, overlap, frequencies, Fs);
        
            [Sz, F, T, Pz] = spectrogram(sigz, winsize, overlap, frequencies, Fs);
        
            FT_all(:,:,q) = Sx+Sy+Sz;
           
        end
        
        freq = F;
        
        corr_matrix = zeros(length(seedindx),length(seedindx),length(freq));
        
        if strcmp(options_seed.orthogonalize,'on') || strcmp(options_seed.orthogonalize,'yes')
            
            for k = 1:length(seedindx)
                Si = FT_all(:,:,k)';
                for w = k+1:length(seedindx)
                    Sj = FT_all(:,:,w)';
                    corr_matrix(k,w,:) = net_orthogonalize_corr(Si, Sj);
                    corr_matrix(w,k,:) = corr_matrix(k,w,:);
                end
            end
            
        else
            for k = 1:length(seedindx)
                Si = FT_all(:,:,k)';
                for w = k+1:length(seedindx)
                    Sj = FT_all(:,:,w)';
                    for f=1:length(freq)
                        corr_matrix(k,w,f) = corr(Si(:,f).*conj(Si(:,f)), Sj(:,f).*Sj(:,f));
                        corr_matrix(w,k,:) = corr_matrix(k,w,:);
                    end
                end
            end
        end
            
            
       save([dd2 filesep 'seed_matrix.mat'],'corr_matrix','freq','options_seed');

        
    otherwise
        
        t  = source.time;
        
        new_Fs = str2double(options_seed.fs);
        
        t_res  = resample(t,new_Fs,Fs);
        
        Ntime  = length(t_res);
        
        brain_signals = zeros(Ntime,nvoxels);
        
        
        for k=1:nvoxels
            
            sigx = source.imagingkernel(1+3*(k-1),:)*source.sensor_data;
            
            sigy = source.imagingkernel(2+3*(k-1),:)*source.sensor_data;
            
            sigz = source.imagingkernel(3*k,:)*source.sensor_data;
            
            [~,score] = pca(resample([sigx ; sigy ; sigz]',new_Fs,Fs));
            
            brain_signals(:,k) = score(:,1);
            
        end
        
        if strcmp(options_seed.orthogonalize,'on')
            
            [coeff_tot,score_tot] = pca(brain_signals);
            
            brain_signals = brain_signals-score_tot(:,1)*coeff_tot(:,1)';
            
        end
        
        options_connphase.Fs       = new_Fs;
        options_connphase.window_duration = options_seed.window_duration;
        options_connphase.method   = options_seed.connectivity_measure;
        options_connphase.seedindx = seedindx;
        options_connphase.maxLag   = options_seed.maxLag;
        
        
        [corr_matrix_in, corr_matrix_out,freq] = net_phaseconn_matrix(brain_signals,options_connphase);
        
        save([dd2 filesep 'seed_matrix_in.mat'],'corr_matrix_in','freq','options_seed'); 
        
        save([dd2 filesep 'seed_matrix_out.mat'],'corr_matrix_out','freq','options_seed'); 
        
end

end