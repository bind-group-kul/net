function [map2i, mapFROMi,freq] = net_hermes_mapping(source,option)
%NET_HERMES_MAPPING     Compute phase connectivity metrics on source
%                       activities, using seed voxel(s) defined by the
%                       user.
%                       
%Input:                 SOURCE - matrix containing one time course per
%                                voxel, organized as [time_samples x
%                                n_voxel].
%                       OPTION - structure defining: sampling frequency,
%                                connectivity metric, indices of seed
%                                  voxels and maximum time delay (when
%                                  required).

Fs     = option.Fs;
method = upper(option.method);
seed   = option.seedindx; % couple of seeds (left,right)
maxLag = str2double(option.maxLag);

% set window parameters
window_length  = option.window_duration; % windows length in seconds (keep 1s as previous works)
window_samples = round(window_length*Fs);
ntp     = length(resample(source.time, Fs, round(Fs*size(source.sensor_data,2)/size(source.sft_data_tensor,3)))); %% size(source,1) modified because SOURCE is a structure
nwin    = fix(ntp/window_samples);

%the following is about the data, independent of the method used
config.window.length    = window_samples;
config.window.alignment = 'epoch';
config.window.fs        = Fs;
config.window.baseline  = 0;
config.nfft             = 2^ceil(log2(Fs)) ;
config.towindow         = false; % FALSE if input data are already epoched, TRUE if input data are given as entire time course
config.bandcenter       = 2:0.5:80; % central band frequencies to analyse
config.bandwidth        = 1; % bandwidth of the spectral windows centered in config.bandcenter
 
if strcmpi(option.orthogonalize,'on') || strcmpi(option.orthogonalize,'yes')
    config.flag_orth=1;
else
    config.flag_orth=0;
end

% allocate space
nseed  = size(seed,1);
nvox   = length(find( source.inside == 1 )); %% size(source,2) modified because SOURCE is a structure
data   = zeros(window_samples,2,nwin,1);
freq   = [];

%% The following is about the PDC methods
switch method
	case {'PDC'}
        config.measures   = {'PDC'};
        
        n_attempts = 15;
        order_vect = zeros(1,n_attempts);
        rand('seed',0); %#ok<RAND>
        for iter = 1:n_attempts
        	list = randperm(nvox);
            % modified because data need to be reconstructed from the structure SOURCE
            vox1 = source.pca_projection(list(1),(3*list(1)-2):(3*list(1)))*source.imagingkernel((3*list(1)-2):(3*list(1)),:)*squeeze(sum(source.sft_data_tensor,2));
            vox2 = source.pca_projection(list(2),(3*list(2)-2):(3*list(2)))*source.imagingkernel((3*list(2)-2):(3*list(2)),:)*squeeze(sum(source.sft_data_tensor,2));
            for w = 1:nwin
            	% data(:,1,w,:) = source((w-1)*window_samples+1:w*window_samples, list(1));
                % data(:,2,w,:) = source((w-1)*window_samples+1:w*window_samples, list(2));
                data(:,1,w,:) = vox1((w-1)*window_samples+1:w*window_samples);
                data(:,2,w,:) = vox2((w-1)*window_samples+1:w*window_samples);
            end
            order_vect(iter) = net_find_order(data); % define the order of the model
        end
        
        config.orderMAR = round(mean(order_vect));
        
        dim3     = max(pow2(nextpow2(config.orderMAR)),64); %%%% modified by JS because "output.PDC.data" is 2x2x64x308 
        map2i    = zeros(nvox,nseed,dim3);
        mapFROMi = zeros(nvox,nseed,dim3);
        
        for i = 1:nseed % seed voxel
            kk = seed(i);
            data1 = zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
            for q = 1:size(source.sft_data_tensor,2)
                data1(q,:) = source.pca_projection(kk,(3*kk-2):(3*kk))*source.imagingkernel((3*kk-2):(3*kk),:)*squeeze(source.sft_data_tensor(:,q,:)); %% source.pca_projection(kk,:) modified to consider only the voxel of interest
            end
         for j = 1:nvox % all voxels to compare with the seed
            % the connection strenght of the seed with itself is the
            % highest: set as 1
            if j == kk
                map2i(j,i,:,:)  = 1;
                mapFROMi(j,i,:) = 1;
            else
                % prepare data matrix considering the couple of voxel (i,j)
                data2 = zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
                for q = 1:size(source.sft_data_tensor,2)
                	data2(q,:) = source.pca_projection(j,(3*j-2):(3*j))*source.imagingkernel((3*j-2):(3*j),:)*squeeze(source.sft_data_tensor(:,q,:)); % frequencies x time points
                end
                
                if config.flag_orth==1  % orthogonalization on
                    
                	for q = 1:size(source.sft_data_tensor,2)
                        data2ortho(q,:) = data2(q,:)-regress(data2(q,:)',data1(q,:)')*data1(q,:); %% regression value changes when the order of the input changes
                    end
                    
                end
                %%%%%%%%%%%%%%%%%%%%%%%%% CHANGE INPUT FOR METRICS, USE THE FREQUENCY DECOMPOSITION %%%%%%%%%%%%%%%%%%%%%%%%%
                for w = 1:nwin
                    data(:,1,w,:) = data1((w-1)*window_samples+1:w*window_samples);
                    data(:,2,w,:) = data2ortho((w-1)*window_samples+1:w*window_samples);
                end
                % compute the correlation metric
                output          = H_methods_PDC ( data, config );
                % save aji in column i
                map2i(j,i,:)    = mean(output.PDC.data(2,1,:,:),4);  % average on time windows
                % save aij in column i
                mapFROMi(j,i,:) = mean(output.PDC.data(1,2,:,:),4);  % average on time windows
            end
         end
        end
        % save fft frequencies
        freq = output.fftFreq;
        
    case {'DTF'}
        config.measures   = {'DTF'};
        
        n_attempts = 15;
        order_vect = zeros(1,n_attempts);
        rand('seed',0); %#ok<RAND>
        for iter = 1:n_attempts
            list = randperm(nvox);
            % modified because data need to be reconstructed from the structure SOURCE
            vox1 = source.pca_projection(list(1),(3*list(1)-2):(3*list(1)))*source.imagingkernel((3*list(1)-2):(3*list(1)),:)*squeeze(sum(source.sft_data_tensor,2));
            vox2 = source.pca_projection(list(2),(3*list(2)-2):(3*list(2)))*source.imagingkernel((3*list(2)-2):(3*list(2)),:)*squeeze(sum(source.sft_data_tensor,2));
            for w = 1:nwin
                data(:,1,w,:) = vox1((w-1)*window_samples+1:w*window_samples);
                data(:,2,w,:) = vox2((w-1)*window_samples+1:w*window_samples);
            end
            order_vect(iter) = net_find_order(data); % define the order of the model
        end
        
        config.orderMAR = round(mean(order_vect));
        
        dim3     = max(pow2(nextpow2(config.orderMAR)),64); %%%% modified by JS because "output.DTF.data" is 2x2x64x308 
        map2i    = zeros(nvox,nseed,dim3);
        mapFROMi = zeros(nvox,nseed,dim3);
        
        for i = 1:nseed % seed voxel
            kk = seed(i);
            data1 = zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
            for q = 1:size(source.sft_data_tensor,2)
                data1(q,:) = source.pca_projection(kk,(3*kk-2):(3*kk))*source.imagingkernel((3*kk-2):(3*kk),:)*squeeze(source.sft_data_tensor(:,q,:)); %% source.pca_projection(kk,:) modified to consider only the voxel of interest
            end
         for j = 1:nvox % all voxels to compare with the seed
            % the connection strenght of the seed with itself is the
            % highest: set as 1
            if j == seed(i)
                map2i(j,i,:,:)  = 1;
                mapFROMi(j,i,:) = 1;
            else
                % prepare data matrix considering the couple of voxel (i,j)
                data2 = zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
                for q = 1:size(source.sft_data_tensor,2)
                    data2(q,:) = source.pca_projection(j,(3*j-2):(3*j))*source.imagingkernel((3*j-2):(3*j),:)*squeeze(source.sft_data_tensor(:,q,:)); % frequencies x time points
                end
                
                if config.flag_orth==1  % orthogonalization on
                    
                    for q = 1:size(source.sft_data_tensor,2)
                        data2ortho(q,:) = data2(q,:)-regress(data2(q,:)',data1(q,:)')*data1(q,:); %% regression value changes when the order of the input changes
                    end
                    
                end
                %%%%%%%%%%%%%%%%%%%%%%%%% CHANGE INPUT FOR METRICS, USE THE FREQUENCY DECOMPOSITION %%%%%%%%%%%%%%%%%%%%%%%%%
                for w = 1:nwin
                    data(:,1,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(i));
                    data(:,2,w,:) = source((w-1)*window_samples+1:w*window_samples, j);
                end
                % compute the correlation metric
                output          = H_methods_PDC ( data, config );
                % save aji in column i
                map2i(j,i,:)    = mean(output.DTF.data(2,1,:,:),4);  % average on time windows
                % save aij in column i
                mapFROMi(j,i,:) = mean(output.DTF.data(1,2,:,:),4);  % average on time windows
            end
         end
        end
        % save fft frequencies
        freq = output.fftFreq;

    case {'ICOH'}  %%%% Upper case for "i" modified by JS
        config.measures   = {'iCOH'};
        config.trials     = false;
          
        % third dimension of the output depends on win_samples
        dim3     = ceil((1 + max(256, pow2(nextpow2(2 * floor(window_samples/9))))) / 2);
        map2i    = zeros(nvox,nseed,dim3); 
        mapFROMi = zeros(nvox,nseed,dim3);
        
        for i = 1:nseed % seed voxel
            kk = seed(i);
            data1 = zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
            for q = 1:size(source.sft_data_tensor,2)
                data1(q,:) = source.pca_projection(kk,(3*kk-2):(3*kk))*source.imagingkernel((3*kk-2):(3*kk),:)*squeeze(source.sft_data_tensor(:,q,:)); %% source.pca_projection(kk,:) modified to consider only the voxel of interest
            end
         for j = 1:nvox % all voxels to compare with the seed
                % prepare data matrix considering the couple of voxel (i,j)
                data2 = zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
                for q = 1:size(source.sft_data_tensor,2)
                    data2(q,:) = source.pca_projection(j,(3*j-2):(3*j))*source.imagingkernel((3*j-2):(3*j),:)*squeeze(source.sft_data_tensor(:,q,:)); % frequencies x time points
                end
                
                if config.flag_orth==1  % orthogonalization on
                    
                    for q = 1:size(source.sft_data_tensor,2)
                        data2ortho(q,:) = data2(q,:)-regress(data2(q,:)',data1(q,:)')*data1(q,:); %% regression value changes when the order of the input changes
                    end
                    
                end
                %%%%%%%%%%%%%%%%%%%%%%%%% CHANGE INPUT FOR METRICS, USE THE FREQUENCY DECOMPOSITION %%%%%%%%%%%%%%%%%%%%%%%%%
                for w = 1:nwin
                    data(:,1,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(i));
                    data(:,2,w,:) = source((w-1)*window_samples+1:w*window_samples, j);
                end
                % compute the correlation metric
                output          = H_methods_CM ( data, config );
                % save aji in column i
                map2i(j,i,:)    = mean(output.iCOH.data(2,1,:,:),4);  % average on time windows
                % save aij in column i
                mapFROMi(j,i,:) = mean(output.iCOH.data(1,2,:,:),4);  % average on time windows
         end
        end
        % save fft frequencies
        freq = output.fftFreq;

    case {'COH'}
        config.measures   = {'COH'};
        config.trials     = false;
           
        % third dimension of the output depends on win_samples
        dim3     = ceil((1 + max(256, pow2(nextpow2(2 * floor(window_samples/9))))) / 2);
        map2i    = zeros(nvox,nseed,dim3); 
        mapFROMi = zeros(nvox,nseed,dim3);
        
        for i = 1:nseed % seed voxel
            kk = seed(i);
            data1 = zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
            for q = 1:size(source.sft_data_tensor,2)
                data1(q,:) = source.pca_projection(kk,(3*kk-2):(3*kk))*source.imagingkernel((3*kk-2):(3*kk),:)*squeeze(source.sft_data_tensor(:,q,:)); %% source.pca_projection(kk,:) modified to consider only the voxel of interest
            end
         for j = 1:nvox % all voxels to compare with the seed
                % prepare data matrix considering the couple of voxel (i,j)
                data2 = zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
                for q = 1:size(source.sft_data_tensor,2)
                    data2(q,:) = source.pca_projection(j,(3*j-2):(3*j))*source.imagingkernel((3*j-2):(3*j),:)*squeeze(source.sft_data_tensor(:,q,:)); % frequencies x time points
                end
                
                if config.flag_orth==1  % orthogonalization on
                    
                    for q = 1:size(source.sft_data_tensor,2)
                        data2ortho(q,:) = data2(q,:)-regress(data2(q,:)',data1(q,:)')*data1(q,:); %% regression value changes when the order of the input changes
                    end
                    
                end
                %%%%%%%%%%%%%%%%%%%%%%%%% CHANGE INPUT FOR METRICS, USE THE FREQUENCY DECOMPOSITION %%%%%%%%%%%%%%%%%%%%%%%%%
                for w = 1:nwin
                    data(:,1,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(i));
                    data(:,2,w,:) = source((w-1)*window_samples+1:w*window_samples, j);
                end
                % compute the correlation metric
                output          = H_methods_CM ( data, config );
                % save aji in column i
                map2i(j,i,:)    = mean(output.COH.data(2,1,:,:),4);  % average on time windows
                % save aij in column i
                mapFROMi(j,i,:) = mean(output.COH.data(1,2,:,:),4);  % average on time windows
         end
        end
        % save fft frequencies
        freq = output.fftFreq;
 
    case {'COR'}
        config.measures   = {'COR'};
          
        map2i    = zeros(nvox,nseed,nwin); 
        mapFROMi = zeros(nvox,nseed,nwin);
        
        for i = 1:nseed % seed voxel
            kk = seed(i);
            data1 = zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
            for q = 1:size(source.sft_data_tensor,2)
                data1(q,:) = source.pca_projection(kk,(3*kk-2):(3*kk))*source.imagingkernel((3*kk-2):(3*kk),:)*squeeze(source.sft_data_tensor(:,q,:)); %% source.pca_projection(kk,:) modified to consider only the voxel of interest
            end
         for j = 1:nvox % all voxels to compare with the seed
                % prepare data matrix considering the couple of voxel (i,j)
                data2 = zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
                for q = 1:size(source.sft_data_tensor,2)
                    data2(q,:) = source.pca_projection(j,(3*j-2):(3*j))*source.imagingkernel((3*j-2):(3*j),:)*squeeze(source.sft_data_tensor(:,q,:)); % frequencies x time points
                end
                
                if config.flag_orth==1  % orthogonalization on
                    
                    for q = 1:size(source.sft_data_tensor,2)
                        data2ortho(q,:) = data2(q,:)-regress(data2(q,:)',data1(q,:)')*data1(q,:); %% regression value changes when the order of the input changes
                    end
                    
                end
                %%%%%%%%%%%%%%%%%%%%%%%%% CHANGE INPUT FOR METRICS, USE THE FREQUENCY DECOMPOSITION %%%%%%%%%%%%%%%%%%%%%%%%%
                for w = 1:nwin
                    data(:,1,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(i));
                    data(:,2,w,:) = source((w-1)*window_samples+1:w*window_samples, j);
                end
                % compute the correlation metric
                output          = H_methods_CM ( data, config );
                % save aji in column i
                map2i(j,i,:)    = output.COR.data(2,1,:,:);  % average on time windows
                % save aij in column i
                mapFROMi(j,i,:) = output.COR.data(1,2,:,:);  % average on time windows
         end
        end
    
    case {'XCOR'}
        config.measures   = {'xCOR'};
        config.maxlags    = round(maxLag*Fs); % time delay for cross correlation (>0) in samples
        if (config.maxlags > window_samples/5) || (config.maxlag<0), config.maxlags = round(window_samples/5); end % upper limit suggested by Hermes developers
         
        map2i    = zeros(nvox,nseed,2*config.maxlags + 1); 
        mapFROMi = zeros(nvox,nseed,2*config.maxlags + 1);
        
        for i = 1:nseed % seed voxel
            kk = seed(i);
            data1 = zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
            for q = 1:size(source.sft_data_tensor,2)
                data1(q,:) = source.pca_projection(kk,(3*kk-2):(3*kk))*source.imagingkernel((3*kk-2):(3*kk),:)*squeeze(source.sft_data_tensor(:,q,:)); %% source.pca_projection(kk,:) modified to consider only the voxel of interest
            end
         for j = 1:nvox % all voxels to compare with the seed
                % prepare data matrix considering the couple of voxel (i,j)
                data2 = zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
                for q = 1:size(source.sft_data_tensor,2)
                    data2(q,:) = source.pca_projection(j,(3*j-2):(3*j))*source.imagingkernel((3*j-2):(3*j),:)*squeeze(source.sft_data_tensor(:,q,:)); % frequencies x time points
                end
                
                if config.flag_orth==1  % orthogonalization on
                    
                    for q = 1:size(source.sft_data_tensor,2)
                        data2ortho(q,:) = data2(q,:)-regress(data2(q,:)',data1(q,:)')*data1(q,:); %% regression value changes when the order of the input changes
                    end
                    
                end
                %%%%%%%%%%%%%%%%%%%%%%%%% CHANGE INPUT FOR METRICS, USE THE FREQUENCY DECOMPOSITION %%%%%%%%%%%%%%%%%%%%%%%%%
                for w = 1:nwin
                    data(:,1,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(i));
                    data(:,2,w,:) = source((w-1)*window_samples+1:w*window_samples, j);
                end
                % compute the correlation metric
                output          = H_methods_CM ( data, config );
                % save aji in column i
                map2i(j,i,:)    = mean(output.xCOR.data(2,1,:,:),4);  % average on time windows
                % save aij in column i
                mapFROMi(j,i,:) = mean(output.xCOR.data(1,2,:,:),4);  % average on time windows
         end
        end
    
    case {'PLV'}
        config.measures   = {'PLV'}; 
         
        map2i = zeros(nvox,nseed,length(config.bandcenter)); % map2i and mapFROMi should be equal because in output.PLV.data aij=aji according to the definition of PLV
        mapFROMi = zeros(nvox,nseed,length(config.bandcenter));
        
        for i = 1:nseed % seed voxel
            kk = seed(i);
            data1 = zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
            for q = 1:size(source.sft_data_tensor,2)
                data1(q,:) = source.pca_projection(kk,(3*kk-2):(3*kk))*source.imagingkernel((3*kk-2):(3*kk),:)*squeeze(source.sft_data_tensor(:,q,:)); %% source.pca_projection(kk,:) modified to consider only the voxel of interest
            end
         for j = 1:nvox % all voxels to compare with the seed
                % prepare data matrix considering the couple of voxel (i,j)
                data2 = zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
                for q = 1:size(source.sft_data_tensor,2)
                    data2(q,:) = source.pca_projection(j,(3*j-2):(3*j))*source.imagingkernel((3*j-2):(3*j),:)*squeeze(source.sft_data_tensor(:,q,:)); % frequencies x time points
                end
                
                if config.flag_orth==1  % orthogonalization on
                    
                    for q = 1:size(source.sft_data_tensor,2)
                        data2ortho(q,:) = data2(q,:)-regress(data2(q,:)',data1(q,:)')*data1(q,:); %% regression value changes when the order of the input changes
                    end
                    
                end
                %%%%%%%%%%%%%%%%%%%%%%%%% CHANGE INPUT FOR METRICS, USE THE FREQUENCY DECOMPOSITION %%%%%%%%%%%%%%%%%%%%%%%%%
                for w = 1:nwin
                    data(:,1,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(i));
                    data(:,2,w,:) = source((w-1)*window_samples+1:w*window_samples, j);
                end
                % compute the correlation metric
                output          = H_methods_PS ( data, config );
                % save aji in column i
                map2i(j,i,:)    = mean(output.PLV.data(2,1,:,:),4);  % average on time windows
                % save aij in column i
                mapFROMi(j,i,:) = mean(output.PLV.data(1,2,:,:),4);  % average on time windows
         end
        end
        % save fft frequencies
        freq = config.bandcenter;

    case {'PLI'}
        config.measures   = {'PLI'}; 
        
        map2i    = zeros(nvox,nseed,length(config.bandcenter)); % map2i and mapFROMi should be equal because in output.PLI.data aij=aji according to the definition of PLI
        mapFROMi = zeros(nvox,nseed,length(config.bandcenter));
       
         for i = 1:nseed % seed voxel
            kk = seed(i);
            data1 = zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
            for q = 1:size(source.sft_data_tensor,2)
                data1(q,:) = source.pca_projection(kk,(3*kk-2):(3*kk))*source.imagingkernel((3*kk-2):(3*kk),:)*squeeze(source.sft_data_tensor(:,q,:)); %% source.pca_projection(kk,:) modified to consider only the voxel of interest
            end
          for j = 1:nvox % all voxels to compare with the seed
                % prepare data matrix considering the couple of voxel (i,j)
                data2 = zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
                for q = 1:size(source.sft_data_tensor,2)
                    data2(q,:) = source.pca_projection(j,(3*j-2):(3*j))*source.imagingkernel((3*j-2):(3*j),:)*squeeze(source.sft_data_tensor(:,q,:)); % frequencies x time points
                end
                
                if config.flag_orth==1  % orthogonalization on
                    
                    for q = 1:size(source.sft_data_tensor,2)
                        data2ortho(q,:) = data2(q,:)-regress(data2(q,:)',data1(q,:)')*data1(q,:); %% regression value changes when the order of the input changes
                    end
                    
                end
                %%%%%%%%%%%%%%%%%%%%%%%%% CHANGE INPUT FOR METRICS, USE THE FREQUENCY DECOMPOSITION %%%%%%%%%%%%%%%%%%%%%%%%%
                for w = 1:nwin
                    data(:,1,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(i));
                    data(:,2,w,:) = source((w-1)*window_samples+1:w*window_samples, j);
                end
                % compute the correlation metric
                output          = H_methods_PS ( data, config );
                % save aji in column i
                map2i(j,i,:)    = mean(output.PLI.data(2,1,:,:),4);  % average on time windows
                % save aij in column i
                mapFROMi(j,i,:) = mean(output.PLI.data(1,2,:,:),4);  % average on time windows
         end
        end
        % save fft frequencies
        freq = config.bandcenter;

    case {'WPLI'}
        config.measures   = {'wPLI'};

        map2i    = zeros(nvox,nseed,length(config.bandcenter));
        mapFROMi = zeros(nvox,nseed,length(config.bandcenter)); % map2i and mapFROMi should be equal because in output.wPLI.data aij=aji according to the definition of wPLI 
        
        for i = 1:nseed % seed voxel
            kk = seed(i);
            data1 = zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
            for q = 1:size(source.sft_data_tensor,2)
                data1(q,:) = source.pca_projection(kk,(3*kk-2):(3*kk))*source.imagingkernel((3*kk-2):(3*kk),:)*squeeze(source.sft_data_tensor(:,q,:)); %% source.pca_projection(kk,:) modified to consider only the voxel of interest
            end
         for j = 1:nvox % all voxels to compare with the seed
                % prepare data matrix considering the couple of voxel (i,j)
                data2 = zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
                for q = 1:size(source.sft_data_tensor,2)
                    data2(q,:) = source.pca_projection(j,(3*j-2):(3*j))*source.imagingkernel((3*j-2):(3*j),:)*squeeze(source.sft_data_tensor(:,q,:)); % frequencies x time points
                end
                
                if config.flag_orth==1  % orthogonalization on
                    
                    for q = 1:size(source.sft_data_tensor,2)
                        data2ortho(q,:) = data2(q,:)-regress(data2(q,:)',data1(q,:)')*data1(q,:); %% regression value changes when the order of the input changes
                    end
                    
                end
                %%%%%%%%%%%%%%%%%%%%%%%%% CHANGE INPUT FOR METRICS, USE THE FREQUENCY DECOMPOSITION %%%%%%%%%%%%%%%%%%%%%%%%%
                for w = 1:nwin
                    data(:,1,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(i));
                    data(:,2,w,:) = source((w-1)*window_samples+1:w*window_samples, j);
                end
                % compute the correlation metric
                output          = H_methods_PS ( data, config );
                % save aji in column i
                map2i(j,i,:)    = mean(output.wPLI.data(2,1,:,:),4);  % average on time windows
                % save aij in column i
                mapFROMi(j,i,:) = mean(output.wPLI.data(1,2,:,:),4);  % average on time windows
         end
        end
        % save fft frequencies
        freq = config.bandcenter;
        
    case {'RHO'}
        config.measures   = {'RHO'}; 
 
        map2i    = zeros(nvox,nseed,length(config.bandcenter));
        mapFROMi = zeros(nvox,nseed,length(config.bandcenter)); % map2i and mapFROMi should be equal because in output.RHO.data aij=aji according to the definition of RHO 
        
        for i = 1:nseed % seed voxel
            kk = seed(i);
            data1 = zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
            for q = 1:size(source.sft_data_tensor,2)
                data1(q,:) = source.pca_projection(kk,(3*kk-2):(3*kk))*source.imagingkernel((3*kk-2):(3*kk),:)*squeeze(source.sft_data_tensor(:,q,:)); %% source.pca_projection(kk,:) modified to consider only the voxel of interest
            end
         for j = 1:nvox % all voxels to compare with the seed
            	% prepare data matrix considering the couple of voxel (i,j)
                data2 = zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
                for q = 1:size(source.sft_data_tensor,2)
                    data2(q,:) = source.pca_projection(j,(3*j-2):(3*j))*source.imagingkernel((3*j-2):(3*j),:)*squeeze(source.sft_data_tensor(:,q,:)); % frequencies x time points
                end
                
                if config.flag_orth==1  % orthogonalization on
                    
                    for q = 1:size(source.sft_data_tensor,2)
                        data2ortho(q,:) = data2(q,:)-regress(data2(q,:)',data1(q,:)')*data1(q,:); %% regression value changes when the order of the input changes
                    end
                    
                end
                %%%%%%%%%%%%%%%%%%%%%%%%% CHANGE INPUT FOR METRICS, USE THE FREQUENCY DECOMPOSITION %%%%%%%%%%%%%%%%%%%%%%%%%
                for w = 1:nwin
                    data(:,1,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(i));
                    data(:,2,w,:) = source((w-1)*window_samples+1:w*window_samples, j);
                end
                % compute the correlation metric
                output          = H_methods_PS ( data, config );
                % save aji in column i
                map2i(j,i,:)    = mean(output.RHO.data(2,1,:,:),4);  % average on time windows
                % save aij in column i
                mapFROMi(j,i,:) = mean(output.RHO.data(1,2,:,:),4);  % average on time windows
         end
        end
        % save fft frequencies
        freq = config.bandcenter;
        
    case {'GC'}
        config.measures	 = {'GC'};
        config.bandwidth = 4;

        map2i	 = zeros(nvox,nseed,nwin);
        mapFROMi = zeros(nvox,nseed,nwin);

        n_attempts = 15;
        order_vect = zeros(1,n_attempts);
        rand('seed',0); %#ok<RAND>
        for iter = 1:n_attempts
            list = randperm(nvox);
            % modified because data need to be reconstructed from the structure SOURCE
            vox1 = source.pca_projection(list(1),(3*list(1)-2):(3*list(1)))*source.imagingkernel((3*list(1)-2):(3*list(1)),:)*squeeze(sum(source.sft_data_tensor,2));
            vox2 = source.pca_projection(list(2),(3*list(2)-2):(3*list(2)))*source.imagingkernel((3*list(2)-2):(3*list(2)),:)*squeeze(sum(source.sft_data_tensor,2));
            for w = 1:nwin
                data(:,1,w,:) = vox1((w-1)*window_samples+1:w*window_samples);
                data(:,2,w,:) = vox2((w-1)*window_samples+1:w*window_samples);
            end
            order_vect(iter) = net_find_order(data); % define the order of the model
        end

        config.orderAR	 = round(mean(order_vect));

        for i = 1:nseed % seed voxel
            kk = seed(i);
            data1 = zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
            for q = 1:size(source.sft_data_tensor,2)
                data1(q,:) = source.pca_projection(kk,(3*kk-2):(3*kk))*source.imagingkernel((3*kk-2):(3*kk),:)*squeeze(source.sft_data_tensor(:,q,:)); %% source.pca_projection(kk,:) modified to consider only the voxel of interest
            end
         for j = 1:nvox % all voxels to compare with the seed
                % prepare data matrix considering the couple of voxels (i,j)
                data2 = zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
                for q = 1:size(source.sft_data_tensor,2)
                    data2(q,:) = source.pca_projection(j,(3*j-2):(3*j))*source.imagingkernel((3*j-2):(3*j),:)*squeeze(source.sft_data_tensor(:,q,:)); % frequencies x time points
                end
                
                if config.flag_orth==1  % orthogonalization on
                    
                    for q = 1:size(source.sft_data_tensor,2)
                        data2ortho(q,:) = data2(q,:)-regress(data2(q,:)',data1(q,:)')*data1(q,:); %% regression value changes when the order of the input changes
                    end
                    
                end
                %%%%%%%%%%%%%%%%%%%%%%%%% CHANGE INPUT FOR METRICS, USE THE FREQUENCY DECOMPOSITION %%%%%%%%%%%%%%%%%%%%%%%%%
                for w = 1:nwin
                    data(:,1,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(i));
                    data(:,2,w,:) = source((w-1)*window_samples+1:w*window_samples, j);
                end
                % compute the correlation metric
                output			= H_methods_GC( data, config );
                % save aji in column i
                map2i(j,i,:)    = mean(output.GC.data(2,1,:,:),4); % average on time windows
                % save aij in column i
                mapFROMi(j,i,:)	= mean(output.GC.data(1,2,:,:),4); % average on time windows
         end
        end

%     case {'M'}
%         config.measures = {'M'};
%         
%         map2i    = zeros(nvox,nseed,nwin);
%         mapFROMi = zeros(nvox,nseed,nwin);
%         
%         for i = 1:nseed % seed voxel
%             kk = seed(i);
%             data1 = zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
%             for q = 1:size(source.sft_data_tensor,2)
%                 data1(q,:) = source.pca_projection(kk,(3*kk-2):(3*kk))*source.imagingkernel((3*kk-2):(3*kk),:)*squeeze(source.sft_data_tensor(:,q,:)); %% source.pca_projection(kk,:) modified to consider only the voxel of interest
%             end
%          for j = 1:nvox % all voxels to compare with the seed
%                 % prepare data matrix considering the couple of voxel (i,j)
%                 data2 = zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
%                 for q = 1:size(source.sft_data_tensor,2)
%                     data2(q,:) = source.pca_projection(j,(3*j-2):(3*j))*source.imagingkernel((3*j-2):(3*j),:)*squeeze(source.sft_data_tensor(:,q,:)); % frequencies x time points
%                 end
%                 
%                 if config.flag_orth==1  % orthogonalization on
%                     
%                     for q = 1:size(source.sft_data_tensor,2)
%                         data2ortho(q,:) = data2(q,:)-regress(data2(q,:)',data1(q,:)')*data1(q,:); %% regression value changes when the order of the input changes
%                     end
%                     
%                 end
%                 %%%%%%%%%%%%%%%%%%%%%%%%% CHANGE INPUT FOR METRICS, USE THE FREQUENCY DECOMPOSITION %%%%%%%%%%%%%%%%%%%%%%%%%
%                 for w = 1:nwin
%                 	data(:,1,w,:) = source((w-1)*win_samples+1:w*win_samples, seed(i));
%                     data(:,2,w,:) = source((w-1)*win_samples+1:w*win_samples, j);
%                 end
%                 % define configuration parameters for this method
%                 [Dim, tau]         = net_find_embedparam(data);
%                 config.EmbDim      = Dim; % embedding dimension (the smallest dimension required to embed an object or a chaotic attractor): [2 10]
%                 config.TimeDelay   = tau; % embedding time delay [1 0.8*win_samples/(config.EmbDim - 1)]
%                 config.Nneighbours = config.EmbDim +1; % number of nearest neighbours to prevent a bias in the value of indexes
%                 config.w1          = config.TimeDelay; % Theiler window to exclude autocorrelation effects from the density estimation
%                 % compute the correlation metric
%                 output          = H_methods_GS ( data, config );
%                 % save aji in column i
%                 map2i(j,i,:)    = mean(output.M.data(2,1,:,:),4);  % average on time windows
%                 % save aij in column i
%                 mapFROMi(j,i,:) = mean(output.M.data(1,2,:,:),4);  % average on time windows
%          end
%         end
% 
%     case {'L'}
%         config.measures = {'L'};
%         
%         map2i    = zeros(nvox,nseed,nwin);
%         mapFROMi = zeros(nvox,nseed,nwin);
%         
%         for i = 1:nseed % seed voxel
%             kk = seed(i);
%             data1 = zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
%             for q = 1:size(source.sft_data_tensor,2)
%                 data1(q,:) = source.pca_projection(kk,(3*kk-2):(3*kk))*source.imagingkernel((3*kk-2):(3*kk),:)*squeeze(source.sft_data_tensor(:,q,:)); %% source.pca_projection(kk,:) modified to consider only the voxel of interest
%             end
%          for j = 1:nvox % all voxels to compare with the seed
%                 % prepare data matrix considering the couple of voxel (i,j)
%                 data2 = zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
%                 for q = 1:size(source.sft_data_tensor,2)
%                     data2(q,:) = source.pca_projection(j,(3*j-2):(3*j))*source.imagingkernel((3*j-2):(3*j),:)*squeeze(source.sft_data_tensor(:,q,:)); % frequencies x time points
%                 end
%                 
%                 if config.flag_orth==1  % orthogonalization on
%                     
%                     for q = 1:size(source.sft_data_tensor,2)
%                         data2ortho(q,:) = data2(q,:)-regress(data2(q,:)',data1(q,:)')*data1(q,:); %% regression value changes when the order of the input changes
%                     end
%                     
%                 end
%                 %%%%%%%%%%%%%%%%%%%%%%%%% CHANGE INPUT FOR METRICS, USE THE FREQUENCY DECOMPOSITION %%%%%%%%%%%%%%%%%%%%%%%%%
%                 for w = 1:nwin
%                 	data(:,1,w,:) = source((w-1)*win_samples+1:w*win_samples, seed(i));
%                     data(:,2,w,:) = source((w-1)*win_samples+1:w*win_samples, j);
%                 end
%                 % define configuration parameters for this method
%                 [Dim, tau]         = net_find_embedparam(data);
%                 config.EmbDim      = Dim; % embedding dimension (the smallest dimension required to embed an object or a chaotic attractor): [2 10]
%                 config.TimeDelay   = tau; % embedding time delay [1 0.8*win_samples/(config.EmbDim - 1)]
%                 config.Nneighbours = config.EmbDim +1; % number of nearest neighbours to prevent a bias in the value of indexes
%                 config.w1          = config.TimeDelay; % Theiler window to exclude autocorrelation effects from the density estimation
%                 % compute the correlation metric
%                 output          = H_methods_GS ( data, config );
%                 % save aji in column i
%                 map2i(j,i,:)    = mean(output.L.data(2,1,:,:),4);  % average on time windows
%                 % save aij in column i
%                 mapFROMi(j,i,:) = mean(output.L.data(1,2,:,:),4);  % average on time windows
%          end
%         end

end
end