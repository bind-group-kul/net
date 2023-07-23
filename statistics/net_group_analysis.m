function net_group_analysis(main_directory,options)

if any(strcmpi(options.flag,{'erp','ers_erd','rsn','seed'}))
    
    NET_folder = net('path');
    dd = dir([main_directory filesep 'dataset*']);
    
    sx=zeros(1,numel(dd));
    for i=1:length(dd)
        sx(i)=str2num(dd(i).name(8:end));
    end
    
    [~,b]=intersect(sx,options.subjects,'stable');
    dd=dd(b);
    nsubj=length(dd);
    
    tpm_file=[NET_folder filesep 'template' filesep 'tissues_MNI' filesep 'eTPM12.nii'];
    
    %% statistic on connectivity maps
    ff=dir([dd(1).folder filesep dd(1).name filesep '**' filesep options.flag '*_mni.nii']);
    filelist=cell(length(ff),1);
    for j=1:length(ff)
        str=['..' ff(j).folder(2+length(dd(1).folder)+length(dd(1).name):end) filesep ff(j).name];
        filelist{j,:}=str;
    end
    
    % preparing data and performing statistical analysis
    for j=1:length(ff)
        filename = [dd(1).folder filesep dd(1).name filesep filelist{j,:}(4:end)];
        V = spm_vol(filename);
        nmaps=length(V);
        output_file=[dd(1).folder filesep 'group' filesep filelist{j,:}(4:end)];
        
        for k=1:nmaps
            if k==1
                [ddx,ffx,ext]=fileparts(output_file);
                if not(isdir(ddx))
                    mkdir(ddx);
                end
                Vt=spm_vol([tpm_file ',1']);
                tpm_img=sqrt(spm_read_vols(Vt));
                Vt.fname=[ddx filesep 'mask.nii'];
                spm_write_vol(Vt,tpm_img);
                
                clear matlabbatch
                
                matlabbatch{1}.spm.spatial.coreg.write.ref = {filename};
                matlabbatch{1}.spm.spatial.coreg.write.source = {[ddx filesep 'mask.nii']};
                matlabbatch{1}.spm.spatial.coreg.write.roptions.interp = 0;
                matlabbatch{1}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
                matlabbatch{1}.spm.spatial.coreg.write.roptions.mask = 0;
                matlabbatch{1}.spm.spatial.coreg.write.roptions.prefix = 'r';
                
                spm_jobman('run',matlabbatch);
                
                movefile([ddx filesep 'rmask.nii'],[ddx filesep 'mask.nii']);
                
                Vm=spm_vol([ddx filesep 'mask.nii']);
                mask=spm_read_vols(Vm);
                mask=round(mask);
                spm_write_vol(Vm,mask);
            end
            
            flag=zeros(1,nsubj);
            for s = 1:nsubj
                filename = [dd(s).folder filesep dd(s).name filesep filelist{j,:}(4:end)];
                V = spm_vol(filename);
                data=spm_read_vols(V);
                imagex=data(:,:,:,k);
                imagex(isnan(imagex))=0;
                
                if s==1
                    imgs=zeros(size(imagex,1),size(imagex,2),size(imagex,3),nsubj);
                end
                
                imagex(mask==0)=0;
                if strcmpi(options.demean,'yes')
                    imagex(mask==1)=imagex(mask==1)-mean(imagex(mask==1));
                end
                
                if strcmpi(options.global_scaling,'yes')
                    imagex(mask==1)=mean(imagex(mask==1))+(imagex(mask==1)-mean(imagex(mask==1)))/std(imagex(mask==1));
                end
                
                if not(isnan(mean(imagex(:))))
                    flag(s)=1;
                end
                
                imgs(:,:,:,s)=imagex;
            end
            
            imgs(:,:,:,flag==0)=[];
            mean_img=mean(imgs,4);
            av = 0;
            if strcmpi(options.global_demean,'yes')
                av= mean(mean_img(mask==1));
            end
            
            for kk=1:size(imgs,4)
                ima=imgs(:,:,:,kk);
                ima(mask==1)=ima(mask==1)-av;
                imgs(:,:,:,kk)=ima;
            end
        end
        
        mean_img=mean(imgs,4);
        
        if strcmpi(options.ffx,'yes')
            
            V(1).fname=[dd(s).folder filesep 'group' filesep filelist{j,:}(4:end-4)  '_ffx.nii'];
            V(1).pinfo=[0.00001; 0 ; 0];
            V(1).dt=[16 0];
            V(1).n=[k 1];
            spm_write_vol(V(1),mean_img);
        end
        
        clear pcorr;
        
        if exist([dd(s).folder filesep 'group' filesep filelist{j,:}(4:end-4)  '_prob.nii'],'file')
            Vt=spm_vol([dd(s).folder filesep 'group' filesep filelist{j,:}(4:end-4)  '_prob.nii']);
            if length(Vt)>=k
                pcorr=spm_read_vols(Vt(k));
            end
        end
        
        if strcmpi(options.rfx,'yes')
            [tscore,pvalues] = net_ttest(imgs);
            V(1).fname=[dd(s).folder filesep 'group' filesep filelist{j,:}(4:end-4)  '_rfx.nii'];
            V(1).pinfo=[0.00001; 0 ; 0];
            V(1).dt=[16 0];
            V(1).n=[k 1];
            spm_write_vol(V(1),tscore);
        end
        
        if strcmpi(options.overwrite,'yes') || not(exist('pcorr','var'))
            if strcmpi(options.mult_comp,'tfce')
                pcorr = matlab_tfce('onesample',1,imgs,[],'nperm',options.permutations);
                V(1).fname=[dd(s).folder filesep 'group' filesep filelist{j,:}(4:end-4)  '_prob.nii'];
                V(1).pinfo=[0.00001; 0 ; 0];
                V(1).dt=[16 0];
                V(1).n=[k 1];
                spm_write_vol(V(1),pcorr);
            end
            
            if strcmpi(options.mult_comp,'fdr') && exist('pvalues','var')
                [~, ~, pcorr] = fdr_bh(pvalues,options.p_thres,'pdep','yes');
                V(1).fname=[dd(s).folder filesep 'group' filesep filelist{j,:}(4:end-4)  '_prob.nii'];
                V(1).pinfo=[0.00001; 0 ; 0];
                V(1).dt=[16 0];
                V(1).n=[k 1];
                spm_write_vol(V(1),pcorr);
            end
        end
        
        if strcmpi(options.ffx,'yes') && exist('pcorr','var')
            V(1).fname=[dd(s).folder filesep 'group' filesep filelist{j,:}(4:end-4)  '_ffx_thres.nii'];
            V(1).pinfo=[0.00001; 0 ; 0];
            V(1).dt=[16 0];
            V(1).n=[k 1];
            spm_write_vol(V(1),mean_img.*(pcorr<options.p_thres));
        end
        
        if strcmpi(options.rfx,'yes') && exist('pcorr','var')
            V(1).fname=[dd(s).folder filesep 'group' filesep filelist{j,:}(4:end-4)  '_rfx_thres.nii'];
            V(1).pinfo=[0.00001; 0 ; 0];
            V(1).dt=[16 0];
            V(1).n=[k 1];
            spm_write_vol(V(1),tscore.*(pcorr<options.p_thres));
        end
    end
    
    %% statistic on activity matrices
if any(strcmpi(options.flag,{'erp','ers_erd'}))
    % 1. get datasets included for group analysis
    dataset_folders = dir([main_directory filesep 'dataset*']);
    sx=zeros(1,length(dataset_folders));
    for i=1:length(dataset_folders)
        sx(i)=str2num(dataset_folders(i).name(8:end));
    end
    [a,b,c]=intersect(sx,options.subjects,'stable');
    dataset_folders=dataset_folders(b);
    
    subject_num=length(dataset_folders);
    
    % 2. make output folder
    group_folder = [main_directory, filesep, 'group'];
    if(~exist(group_folder, 'dir'))
        mkdir(group_folder);
    end
    
    % processing .mat files
    fprintf(['Processing ', options.flag,'.mat files...']);
    ff=dir([dd(1).folder filesep dd(1).name filesep 'eeg_*' filesep options.flag '*' filesep options.flag '*.mat']);
    filelist=cell(length(ff),1);
    for j=1:length(ff)
        str=['..' ff(j).folder(2+length(dd(1).folder)+length(dd(1).name):end) filesep ff(j).name];
        filelist{j,:}=str;
    end
    
    for j=1:length(ff)
        filename = [dd(1).folder filesep dd(1).name filesep filelist{j,:}(4:end)];
        
        output_file=[dd(1).folder filesep 'group' filesep filelist{j,:}(4:end)];
        [ddx,ffx,ext]=fileparts(output_file);
        
        if not(isdir(ddx))
            mkdir(ddx);
        end
        
        if strcmpi(ffx(end-2:end),'roi')
            varname = [ options.flag '_roi'];
        else
            varname = [ options.flag '_sensor'];
        end
        
        if strcmpi(options.flag,'erp')
            filename = [dd(1).folder filesep dd(1).name filesep filelist{j,:}(4:end)];
            load(filename,varname,'elecpos')
            erp1 = eval(varname); ncond = numel(erp1);
            for c = 1:ncond
                dim = size(erp1(c).erp_tc);
                all_data = zeros(nsubj,prod(dim));
                for s = 1:nsubj
                    filename = [dd(s).folder filesep dd(s).name filesep filelist{j,:}(4:end)];
                    load(filename,varname)
                    erp = eval(varname);
                    all_data(s,:) = erp(c).erp_tc(:);
                    clear erp
                end

                output(c).mean_data = mean(all_data,1);
                output(c).std_data = std(all_data,0,1);
                output(c).tscore_data = sqrt(nsubj)*output(c).mean_data./output(c).std_data;
                clear all_data
            end

            % saving ffx results
            for i=1:ncond
                erp(i).condition_name = erp1(i).condition_name;
                erp(i).time_axis = erp1(i).time_axis;
                erp(i).erp_tc = reshape(output(i).mean_data,dim);
                erp(i).label = erp1(i).label;
            end
            save([output_file(1:(end-4)) '_ffx.mat'], 'erp','elecpos'), clear erp

            % saving rfx results
            for i=1:ncond
                erp(i).condition_name = erp1(i).condition_name;
                erp(i).time_axis = erp1(i).time_axis;
                erp(i).erp_tc = reshape(output(i).tscore_data,dim);
                erp(i).label = erp1(i).label;
            end
            save([output_file(1:(end-4)) '_rfx.mat'], 'erp','elecpos'), clear erp
            clear output erp1
        
        else
            filename = [dd(1).folder filesep dd(1).name filesep filelist{j,:}(4:end)];
            load(filename,varname,'elecpos')
            erserd1 = eval(varname); ncond = numel(erserd1);
            for c = 1:ncond
                dim = size(erserd1(c).tf_map);
                all_data = zeros(nsubj,prod(dim));
                for s = 1:nsubj
                    filename = [dd(s).folder filesep dd(s).name filesep filelist{j,:}(4:end)];
                    load(filename,varname)
                    erserd = eval(varname);
                    all_data(s,:) = erserd(c).tf_map(:);
                    clear erserd
                end

                output(c).mean_data = mean(all_data,1);
                output(c).std_data = std(all_data,0,1);
                output(c).tscore_data = sqrt(nsubj)*output(c).mean_data./output(c).std_data;
                clear all_data
            end

            % saving ffx results
            for i=1:ncond
                ers_erd(i).condition_name = erserd1(i).condition_name;
                ers_erd(i).time_axis = erserd1(i).time_axis;
                ers_erd(i).frequency_axis = erserd1(i).frequency_axis;
                ers_erd(i).tf_map = reshape(output(i).mean_data,dim);
                ers_erd(i).label = erserd1(i).label;
            end
            save([output_file(1:(end-4)) '_ffx.mat'], 'ers_erd','elecpos'), clear ers_erd

            % saving rfx results
            for i=1:ncond
                ers_erd(i).condition_name = erserd1(i).condition_name;
                ers_erd(i).time_axis = erserd1(i).time_axis;
                ers_erd(i).frequency_axis = erserd1(i).frequency_axis;
                ers_erd(i).tf_map = reshape(output(i).tscore_data,dim);
                ers_erd(i).label = erserd1(i).label;
            end
            save([output_file(1:(end-4)) '_rfx.mat'], 'ers_erd','elecpos'), clear ers_erd
            clear output erserd1
        end
    end
end

    %% statistic on matrix connectivity
if any(strcmpi(options.flag,{'sica','tica','rsn','seed'}))
    ff=dir([dd(1).folder filesep dd(1).name filesep '**' filesep options.flag '*' filesep' '**' filesep '*matrix_connectivity.mat']);    
    filelist=cell(length(ff),1);
    for j=1:length(ff)
        str=['..' ff(j).folder(2+length(dd(1).folder)+length(dd(1).name):end) filesep ff(j).name];
        filelist{j,:}=str;
    end
    
    for j=1:length(ff)
    load([dd(1).folder filesep dd(1).name filelist{1}(3:end)],'seed_info'); nseed = numel(seed_info);
    matrices = zeros(nseed, nseed, 80, nsubj);
    for s = 1:nsubj
        load([dd(s).folder filesep dd(s).name filelist{1}(3:end)],'corr_matrix');
        corr_matrix(corr_matrix==0) = nan;
        matrices(:,:,:,s) = corr_matrix;
        clear corr_matrix
    end
    
    grouppath = [dd(1).folder filesep 'group' filelist{1}(3:end-24)];
    if not(isdir(grouppath))
        mkdir(grouppath);
    end
    
    % average over bands
    bands = {1:4; 4:8; 8:13; 13:30; 30:80}; nband = numel(bands);
    bandmatrices = zeros(nseed, nseed, nband, nsubj);
    pvals = zeros(nseed, nseed, nband); tvals = zeros(nseed, nseed, nband);
    for b = 1:nband
        bandmatrices(:,:,b,:) = nanmean(matrices(:,:,bands{b},:),3);
        
        for n = 1:nseed
            for m = n+1:nseed
                [~,pvals(n,m,b),~,stats] = ttest(squeeze(bandmatrices(n,m,b,:))); tvals(n,m,b) = stats.tstat;
                pvals(m,n,b) = pvals(n,m,b); tvals(m,n,b) = tvals(n,m,b);
            end
        end
    end
    
    if strcmpi(options.ffx,'yes')
        data = nanmean(bandmatrices,4); data(isnan(data)) = 0;
        save([ grouppath filesep 'matrix_connectivity_ffx.mat'], 'data','seed_info')
        for b = 1:nband
            T = table(data(:,:,b));
            writetable(T,[ grouppath filesep 'matrix_connectivity_(' num2str(bands{b}(1)) '-' num2str(bands{b}(end)) ')Hz_ffx.xlsx'],'WriteVariableNames',0,'Sheet',1);
            clear T
        end
        clear data
%         for b = 1:nband
%             conn_data = nanmean(squeeze(bandmatrices(:,:,b,:)),3); conn_data(isnan(conn_data)) = 0;
%             save([ grouppath filesep 'connectivity_' bandname{b} '_band_ffx.mat'], 'conn_data','seed_info')
%             T = table(conn_data);
%             writetable(T,[ grouppath filesep 'connectivity_' bandname{b} '_band_ffx.xlsx'],'WriteVariableNames',0,'Sheet',1);
%             
%             clear conn_data T
%         end
    end
    
    if strcmpi(options.rfx,'yes')
        data = tvals;
        save([ grouppath filesep 'matrix_connectivity_rfx.mat'], 'data','pvals','seed_info')
        for b = 1:nband
            T = table(data(:,:,b));
            writetable(T,[ grouppath filesep 'matrix_connectivity_(' num2str(bands{b}(1)) '-' num2str(bands{b}(end)) ')Hz_rfx.xlsx'],'WriteVariableNames',0,'Sheet',1);
            T2 = table(pvals(:,:,b)); writetable(T2,[ grouppath filesep 'matrix_connectivity_(' num2str(bands{b}(1)) '-' num2str(bands{b}(end)) ')Hz_rfx.xlsx'],'WriteVariableNames',0,'Sheet',2);
            clear T T2            
        end
        data = data.*(pvals<options.p_thres);
        save([ grouppath filesep 'matrix_connectivity_rfx_thres.mat'], 'data','seed_info')
        for b = 1:nband
            T = table(data(:,:,b));
            writetable(T,[ grouppath filesep 'matrix_connectivity_(' num2str(bands{b}(1)) '-' num2str(bands{b}(end)) ')Hz_rfx_thres.xlsx'],'WriteVariableNames',0,'Sheet',1);
            clear T
        end
        clear data
%         for b = 1:nband
%             conn_data = tvals(:,:,b); p = pvals(:,:,b);
%             save([ grouppath filesep 'connectivity_' bandname{b} '_band_rfx.mat'], 'conn_data','p','seed_info')
%             T = table(conn_data);
%             writetable(T,[ grouppath filesep 'connectivity_' bandname{b} '_band_rfx.xlsx'],'WriteVariableNames',0,'Sheet',1);
%             T2 = table(p); writetable(T2,[ grouppath filesep 'connectivity_' bandname{b} '_band_rfx.xlsx'],'WriteVariableNames',0,'Sheet',2);
%             clear T T2
%             conn_data = conn_data.*(p<options.p_thres);
%             save([ grouppath filesep 'connectivity_' bandname{b} '_band_rfx_thres.mat'], 'conn_data','seed_info')
%             T = table(conn_data);
%             writetable(T,[ grouppath filesep 'connectivity_' bandname{b} '_band_rfx_thres.xlsx'],'WriteVariableNames',0,'Sheet',1);
%             
%             clear conn_data T
%         end
    end
    end
end        

    fprintf('\n*** STATISTICAL ANALYSIS: DONE! ***\n')
else
    fprintf('PARAMETER *stats.flag* NOT VALID! Choose among: I) activity analysis (''erp'',''ers_erd''); II) connectivity analysis (''sica'',''tica'',''rsn'',''seed'')')
end