function net_erp_roi(source_filename,options_erp)


 if strcmp(options_erp.roi_enable,'on')
     
dd=fileparts(fileparts(source_filename));

deformation_file=[dd filesep 'mr_data' filesep 'y_anatomy_prepro.nii'];

NET_folder = net('path');
seed_file=[NET_folder filesep 'template' filesep 'seeds' filesep options_erp.seed_file '.mat'];
seed_info=load(seed_file);
coord_subj=net_project_coord(deformation_file,seed_info.seed_coord_mni);
               
options_erp.seed_file

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

epoched_data = net_epoch(filtered_data,Fs,source.events,options_erp);

erp_data = net_robustaverage(epoched_data,options_erp);

%figure; plot([options_erp.pretrig+1:options_erp.posttrig],erp_data'); xlabel('time (ms)'); ylabel('a.u.'); 

%%


xyz = source.pos(source.inside==1,:)';

%coord_subj = options_erp.seed_coord_subj;

seedindx = zeros(size(coord_subj,1),1);

for i=1:size(coord_subj,1)
    
    pos  = coord_subj(i,:)';
    
    dist = sum((xyz-pos*ones(1,size(xyz,2))).^2);
    
    [~,seedindx(i)] = min(dist);
    
end


pretrig   = round(Fs_ref*options_erp.pretrig/1000);
posttrig  = round(Fs_ref*options_erp.posttrig/1000);

erp_tc=zeros(size(coord_subj,1),posttrig-pretrig);


for i=1:size(coord_subj,1)
    
    k=seedindx(i);
    
    sigx=source.imagingkernel(1+3*(k-1),:)*erp_data;
    
    sigy=source.imagingkernel(2+3*(k-1),:)*erp_data;
    
    sigz=source.imagingkernel(3*k,:)*erp_data;
              
    [~,score] = pca([sigx ; sigy ; sigz]');
            
    sig_pc=score(:,1)';
    
    cc=corr(sig_pc',erp_data');
    
    sig_pc=sig_pc*sign(cc(abs(cc)==max(abs(cc)))); % correct the sign if needed
    
    erp_tc(i,:) = sig_pc;
   
end

save([dd2 filesep 'erp_timecourses.mat'],'erp_tc','options_erp'); 
 
 end
