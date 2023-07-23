function [matrix_in, matrix_out,freq] = net_hermes_matrix(source,option)
%NET_PHASECONN_MATRIX     Compute phase connectivity metrics on source
%                         activities, using seed voxel(s) defined by the
%                         user.
%                       
%Input:                   SOURCE - matrix containing one time course per
%                                  voxel, organized as [time_samples x
%                                  n_voxel].
%                         OPTION - structure defining: sampling frequency,
%                                  connectivity metric, indices of seed
%                                  voxels and maximum time delay (when
%                                  required).

Fs     = option.Fs;
method = upper(option.method);
seed   = option.seedindx; % couple of seeds (left,right)
maxLag = 0.2; % hardcoded value by DM


% set window parameters
window_length  = option.window_duration; % windows length in seconds (keep 1s as previous works)
window_samples = round(window_length*Fs);
ntp     = size(source,1);
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
nseed    = size(seed_info,1);
data     = zeros(window_samples,2,nwin,1);
freq     = [];

%% The following is about the PDC methods
switch method
    case {'PDC'}
        config.measures = {'PDC'};
        
        n_attempts = 15;
        order_vect = zeros(1,n_attempts);
        rand('seed',0); %#ok<RAND>
        for iter=1:n_attempts       %%%% with the new way of computing the order of the AR model, this cycle shouldn't be necessary. JS
            list=randperm(nvox);
            for w=1:nwin
                data(:,1,w,:) = source((w-1)*window_samples+1:w*window_samples, list(1));
                data(:,2,w,:) = source((w-1)*window_samples+1:w*window_samples, list(2));
            end
            
            order_vect(iter) = net_find_order(data); % define the order of the model
        end
        
        config.orderMAR = round(mean(order_vect));
        
        dim3       = max(pow2(nextpow2(config.orderMAR)),64); %%%% modified by JS because "output.PDC.data" is 2x2x64x308 
        matrix_in  = zeros(nseed,nseed,dim3);
        matrix_out = zeros(nseed,nseed,dim3);
        
        for i = 1:nseed % seed voxel
            
            data1=zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
            for q=1:size(source.sft_data_tensor,2)
                data1(q,:)=source.pca_projection(i,:)*source.imagingkernel((3*i-2):(3*i),:)*squeeze(source.sft_data_tensor(:,q,:));
            end
            
            for j = 1:nseed %  voxels to compare with the seed  
                
                if not(i==i)
                
                data2=zeros(size(source.sft_data_tensor,2),size(source.sft_data_tensor,3));
                for q=1:size(source.sft_data_tensor,2)
                    data2(q,:)=source.pca_projection(j,:)*source.imagingkernel((3*j-2):(3*j),:)*squeeze(source.sft_data_tensor(:,q,:));
                end
                
                if config.flag_orth==1  % orthogonalization on
                    
                    for q=1:size(source.sft_data_tensor,2)
                        data2(q,:)=data2(q,:)-regress(data2(q,:)',data1(q,:)')*data1(q,:);
                    end
                    
                end
                
                else
                
                    matrix_in(i,j,:)=1;
                    matrix_in(j,i,:)=1;
                    matrix_out(i,j,:)=1;
                    matrix_out(j,i,:)=1;
                    
                end
                
                % compute the correlation metric
                output            = H_methods_PDC ( data, config );
                % save aji in column i
                matrix_in(i,j,:)  = mean(output.PDC.data(2,1,:,:),4); %1x1x64
                matrix_in(j,i,:)  = matrix_in(i,j,:);
                % save aij in column i
                matrix_out(i,j,:) = mean(output.PDC.data(1,2,:,:),4);
                matrix_out(j,i,:) = matrix_out(i,j,:);
            end
        end
        % save fft frequencies
        freq = output.fftFreq;
        
    case {'DTF'}
        config.measures   = {'DTF'};
        
        n_attempts = 15;
        order_vect = zeros(1,n_attempts);
        rand('seed',0); %#ok<RAND>
        for iter=1:n_attempts       %%%% with the new way of computing the order of the AR model, this cycle shouldn't be necessary. JS
            list=randperm(nvox);
            for w=1:nwin
                data(:,1,w,:) = source((w-1)*window_samples+1:w*window_samples, list(1));
                data(:,2,w,:) = source((w-1)*window_samples+1:w*window_samples, list(2));
            end
            
            order_vect(iter) = net_find_order(data); % define the order of the model
        end
        
        config.orderMAR = round(mean(order_vect));
        
        dim3       = max(pow2(nextpow2(config.orderMAR)),64); %%%% modified by JS because "output.DTF.data" is 2x2x64x308 
        matrix_in  = zeros(nseed,nseed,dim3);
        matrix_out = zeros(nseed,nseed,dim3);
        
        for i = 1:nseed % seed voxel
            for j = i+1:nseed %  voxels to compare with the seed
                % prepare data matrix considering the couple of voxel (i,j)
                for w = 1:nwin
                    data(:,1,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(i));
                    data(:,2,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(j));
                end
                
                % compute the correlation metric
                output            = H_methods_PDC ( data, config );
                % save aji in column i
                matrix_in(i,j,:)  = mean(output.DTF.data(2,1,:,:),4);
                matrix_in(j,i,:)  = matrix_in(i,j,:);
                % save aij in column i
                matrix_out(i,j,:) = mean(output.DTF.data(1,2,:,:),4);
                matrix_out(j,i,:) = matrix_out(i,j,:);
            end
        end
        % save fft frequencies
        freq = output.fftFreq;

    case {'ICOH'}  %%%% Upper case for "i" modified by JS
        config.measures   = {'iCOH'};
        config.trials     = false;
          
        % third dimension of the output depends on win_samples
        dim3       = ceil((1 + max(256, pow2(nextpow2(2 * floor(window_samples/9))))) / 2);
        matrix_in  = ones(nseed,nseed,dim3); 
        matrix_out = ones(nseed,nseed,dim3);
        
        for i = 1:nseed % seed voxel
         for j = i+1:nseed % all voxels to compare with the seed
                % prepare data matrix considering the couple of voxel (i,j)
                for w = 1:nwin
                    data(:,1,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(i));
                    data(:,2,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(j));
                end
                % compute the correlation metric
                output            = H_methods_CM ( data, config );
                % save aji in column i
                matrix_in(i,j,:)  = mean(output.iCOH.data(2,1,:,:),4);
                matrix_in(j,i,:)  = matrix_in(i,j,:);
                % save aij in column i
                matrix_out(i,j,:) = mean(output.iCOH.data(1,2,:,:),4);
                matrix_out(j,i,:) = matrix_out(i,j,:);        
         end
        end
      % save fft frequencies
        freq = output.fftFreq;

    case {'COH'}
        config.measures   = {'COH'};
        config.trials     = false;
           
        % third dimension of the output depends on win_samples
        dim3       = ceil((1 + max(256, pow2(nextpow2(2 * floor(window_samples/9))))) / 2);
        matrix_in  = ones(nseed,nseed,dim3); 
        matrix_out = ones(nseed,nseed,dim3);
        
        for i = 1:nseed % seed voxel
         for j = i+1:nseed % all voxels to compare with the seed
                % prepare data matrix considering the couple of voxel (i,j)
                for w = 1:nwin
                    data(:,1,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(i));
                    data(:,2,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(j));
                end
                % compute the correlation metric
                output            = H_methods_CM ( data, config );
                % save aji in column i
                matrix_in(i,j,:)  = mean(output.COH.data(2,1,:,:),4);  % average on time windows
                matrix_in(j,i,:)  = matrix_in(i,j,:);
                % save aij in column i
                matrix_out(i,j,:) = mean(output.COH.data(1,2,:,:),4);  % average on time windows
                matrix_out(j,i,:) = matrix_out(i,j,:);        
         end
        end
        % save fft frequencies
        freq = output.fftFreq;
    
    case {'COR'}
        config.measures   = {'COR'};
          
        matrix_in  = ones(nseed,nseed,nwin); 
        matrix_out = ones(nseed,nseed,nwin);
        
        for i = 1:nseed % seed voxel
         for j = i+1:nseed % all voxels to compare with the seed
                 for w = 1:nwin
                    data(:,1,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(i));
                    data(:,2,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(j));
                end
                % compute the correlation metric
                output            = H_methods_CM ( data, config );
                % save aji in column i
                matrix_in(i,j,:)  = mean(output.COR.data(2,1,:,:),4);
                matrix_in(j,i,:)  = matrix_in(i,j,:);
                % save aij in column i
                matrix_out(i,j,:) = mean(output.COR.data(1,2,:,:),4);
                matrix_out(j,i,:) = matrix_out(i,j,:);  
         end
        end
    
    case {'XCOR'}
        config.measures   = {'xCOR'};
        config.maxlags    = round(maxLag*Fs); % time delay for cross correlation (>0) in samples
        if (config.maxlags > window_samples/5) || (config.maxlags<0), config.maxlags = round(window_samples/5); end % upper limit suggested by Hermes developers
         
        matrix_in  = ones(nseed,nseed,2*config.maxlags + 1); 
        matrix_out = ones(nseed,nseed,2*config.maxlags + 1);
        
        for i = 1:nseed % seed voxel
         for j = i+1:nseed % all voxels to compare with the seed
                % prepare data matrix considering the couple of voxel (i,j)
                for w = 1:nwin
                    data(:,1,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(i));
                    data(:,2,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(j));
                end
                % compute the correlation metric
                output            = H_methods_CM ( data, config );
                % save aji in column i
                matrix_in(i,j,:)  = mean(output.xCOR.data(2,1,:,:),4);
                matrix_in(j,i,:)  = matrix_in(i,j,:);
                % save aij in column i
                matrix_out(i,j,:) = mean(output.xCOR.data(1,2,:,:),4);
                matrix_out(j,i,:) = matrix_out(i,j,:);
         end
        end
    
    case {'PLV'}
        config.measures   = {'PLV'}; 
         
        matrix_in  = ones(nseed,nseed,length(config.bandcenter)); % map2i and mapFROMi should be equal because in output.PLV.data aij=aji according to the definition of PLV
        matrix_out = ones(nseed,nseed,length(config.bandcenter));
        
        for i = 1:nseed % seed voxel
         for j = i+1:nseed % all voxels to compare with the seed
                 % prepare data matrix considering the couple of voxel (i,j)
                for w = 1:nwin
                    data(:,1,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(i));
                    data(:,2,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(j));
                end
                % compute the correlation metric
                output            = H_methods_PS ( data, config );
                % save aji in column i
                matrix_in(i,j,:)  = mean(output.PLV.data(2,1,:,:),4);
                matrix_in(j,i,:)  = matrix_in(i,j,:);
                % save aij in column i
                matrix_out(i,j,:) = mean(output.PLV.data(1,2,:,:),4);
                matrix_out(j,i,:) = matrix_out(i,j,:);
         end
        end
        % save fft frequencies
        freq = config.bandcenter;

    case {'PLI'}
        config.measures   = {'PLI'}; 
        
        matrix_in  = ones(nseed,nseed,length(config.bandcenter)); % map2i and mapFROMi should be equal because in output.PLI.data aij=aji according to the definition of PLI
        matrix_out = ones(nseed,nseed,length(config.bandcenter));
        
        for i = 1:nseed % seed voxel
         for j = i+1:nseed % all voxels to compare with the seed
                 % prepare data matrix considering the couple of voxel (i,j)
                for w = 1:nwin
                    data(:,1,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(i));
                    data(:,2,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(j));
                end
                % compute the correlation metric
                output            = H_methods_PS ( data, config );
                % save aji in column i
                matrix_in(i,j,:)  = mean(output.PLI.data(2,1,:,:),4);
                matrix_in(j,i,:)  = matrix_in(i,j,:);
                % save aij in column i
                matrix_out(i,j,:) = mean(output.PLI.data(1,2,:,:),4);
                matrix_out(j,i,:) = matrix_out(i,j,:);
         end
        end
        % save fft frequencies
        freq = config.bandcenter;

    case {'WPLI'}
        config.measures   = {'wPLI'};

        matrix_in  = ones(nseed,nseed,length(config.bandcenter)); % map2i and mapFROMi should be equal because in output.wPLI.data aij=aji according to the definition of wPLI
        matrix_out = ones(nseed,nseed,length(config.bandcenter));
        
        for i = 1:nseed % seed voxel
         for j = i+1:nseed % all voxels to compare with the seed
                 % prepare data matrix considering the couple of voxel (i,j)
                for w = 1:nwin
                    data(:,1,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(i));
                    data(:,2,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(j));
                end
                % compute the correlation metric
                output            = H_methods_PS ( data, config );
                % save aji in column i
                matrix_in(i,j,:)  = mean(output.wPLI.data(2,1,:,:),4);
                matrix_in(j,i,:)  = matrix_in(i,j,:);
                % save aij in column i
                matrix_out(i,j,:) = mean(output.wPLI.data(1,2,:,:),4);
                matrix_out(j,i,:) = matrix_out(i,j,:);
         end
        end
        % save fft frequencies
        freq = config.bandcenter;
        
    case {'RHO'}
        config.measures   = {'RHO'}; 
 
        matrix_in  = ones(nseed,nseed,length(config.bandcenter)); % map2i and mapFROMi should be equal because in output.RHO.data aij=aji according to the definition of RHO
        matrix_out = ones(nseed,nseed,length(config.bandcenter));
        
        for i = 1:nseed % seed voxel
         for j = i+1:nseed % all voxels to compare with the seed
                % prepare data matrix considering the couple of voxel (i,j)
                for w = 1:nwin
                    data(:,1,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(i));
                    data(:,2,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(j));
                end
                % compute the correlation metric
                output            = H_methods_PS ( data, config );
                % save aji in column i
                matrix_in(i,j,:)  = mean(output.RHO.data(2,1,:,:),4);
                matrix_in(j,i,:)  = matrix_in(i,j,:);
                % save aij in column i
                matrix_out(i,j,:) = mean(output.RHO.data(1,2,:,:),4);
                matrix_out(j,i,:) = matrix_out(i,j,:);
         end
        end
        % save fft frequencies
        freq = config.bandcenter;

    case {'GC'}
        config.measures	 = {'GC'};
        config.bandwidth = 4;

        matrix_in  = zeros(nseed,nseed,nwin);
        matrix_out = zeros(nseed,nseed,nwin);

        n_attempts = 15;
        order_vect = zeros(1,n_attempts);
        rand('seed',0); %#ok<RAND>
        for iter = 1:n_attempts
            list  = randperm(nvox);
            for w = 1:nwin
                data(:,1,w,:)  = source((w-1)*window_samples+1:w*window_samples, list(1));
                data(:,2,w,:)  = source((w-1)*window_samples+1:w*window_samples, list(2));
            end
            order_vect(iter) = net_find_order(data);
        end

        config.orderAR	 = round(mean(order_vect));

        for i = 1:nseed % seed voxel
         for j = i+1:nseed % all voxels to compare with the seed
                % prepare data matrix considering the couple of voxels (i,j)
                for w = 1:nwin
                    data(:,1,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(i));
                    data(:,2,w,:) = source((w-1)*window_samples+1:w*window_samples, seed(j));
                end
                % compute the correlation metric
                output			  = H_methods_GC( data, config );
                % save aji in column i
                matrix_in(i,j,:)  = mean(output.GC.data(2,1,:,:),4);
                matrix_in(j,i,:)  = matrix_in(i,j,:);
                % save aij in column i
                matrix_out(i,j,:) = mean(output.GC.data(1,2,:,:),4);
                matrix_out(j,i,:) = matrix_out(i,j,:);
          end
        end


 
end