function [elec]=net_elec_positions(elecfile,segimg_filename,fid_labels,template_file,img_filename,template_image,method)


template=ft_read_sens(template_file);
template = ft_convert_units(template, 'mm');
tpl_labels=template.label;

% READ ELECTRODES POSITIONS
% -------------------------
sens = ft_read_sens(elecfile);
sens = ft_convert_units(sens, 'mm');
sens_label=sens.label;

sens_label_corr=sens_label;
for i=1:length(sens_label)    % only for Kirstin's BP recording
    idx = strfind(sens_label{i},'_');
    if not(isempty(idx))
        sens_label_corr{i} = sens_label{i}(idx+1:end);
    end
end
for i=1:length(sens_label)
    sens_label_corr{i} = upper(sens_label_corr{i});
end
sens.label = sens_label_corr;

for i=1:length(tpl_labels)
    tpl_labels{i} = upper(tpl_labels{i});
end

[c,ia,ib] = intersect(tpl_labels,sens.label,'stable');

sens.chanpos=sens.chanpos(ib,:);
sens.chantype=sens.chantype(ib,:);
sens.chanunit=sens.chanunit(ib,:);
sens.elecpos=sens.elecpos(ib,:);
sens.label=sens.label(ib);


%% identify anatomical landmarks
fiducials_mni = zeros(length(fid_labels),3);
for i=1:length(fid_labels)
    idx = strcmpi(template.label,fid_labels{i});
    fiducials_mni(i,:) = template.elecpos(idx,:);
end

% Fiducials coordinates in individual space
landmark_struct = net_set_fiducials(fiducials_mni, img_filename, template_image);


%% Obtain individual headshape model from MR image
V = spm_vol([segimg_filename ',1']);
[seg_image,xyz] = spm_read_vols(V);
%headshape=xyz(:,seg_image==max(seg_image(:)))';
mask=zeros(size(seg_image));
mask(seg_image>0)=1;
[fx,fy,fz] = gradient(mask);

headshape=xyz(:,abs(fx)+abs(fy)+abs(fz)>0)';

% Downsample headshape
npoints_pre=size(headshape,1);
npoints_post=50000;
rand('seed',0);

if npoints_post<npoints_pre
    vect=randperm(npoints_pre);
    vect=vect(1:npoints_post);
    headshape_res=headshape(vect,:);
else
    headshape_res = headshape;
end



% figure; scatter3(headshape_res(:,1),headshape_res(:,2),headshape_res(:,3));
% hold on;
% scatter3(landmark_struct(:,1),landmark_struct(:,2),landmark_struct(:,3),'r');
% scatter3(fiducials_mni(:,1),fiducials_mni(:,2),fiducials_mni(:,3),'g');
% 

% 
% figure; scatter3(headshape_res(:,1),headshape_res(:,2),headshape_res(:,3));
% hold on;
% scatter3(sens.elecpos(:,1),sens.elecpos(:,2),sens.elecpos(:,3),'r');
%  

%----------

if strcmpi(method,'none')
    
    scalpvert_aligned2=sens.elecpos;
    
else

if strcmpi(method,'affine')

    scalpvert=sens.elecpos;
    
    landmark_funct = zeros(length(fid_labels),3);
    for i=1:length(fid_labels)
        idx = strcmpi(sens.label,fid_labels{i});
        landmark_funct(i,:) = scalpvert(idx,:);
    end
    
    M1 = net_rigidreg(landmark_struct',landmark_funct');

    scalpvert_affine = (M1(1:3,1:3)*scalpvert'+M1(1:3,4)*ones(1,size(scalpvert,1)))';
   
    sens.elecpos=scalpvert_affine;
    
%     figure; scatter3(landmark_struct(:,1),landmark_struct(:,2),landmark_struct(:,3));
% hold on;
% scatter3(scalpvert_affine(:,1),scalpvert_affine(:,2),scalpvert_affine(:,3),'r');

    
end    


% figure; scatter3(headshape_res(:,1),headshape_res(:,2),headshape_res(:,3));
% hold on;
% scatter3(sens.elecpos(:,1),sens.elecpos(:,2),sens.elecpos(:,3),'r');
%  



inward_shift_range=-5:10;  % in mm

fitt_dist=zeros(size(sens.elecpos,1),length(inward_shift_range));

for kk=1:length(inward_shift_range)
    
    inward_shift=inward_shift_range(kk);
    
    disp(['examining inward shift = ' num2str(inward_shift) ' mm']);
    
    scalpvert=net_shift_pos(sens.elecpos,inward_shift);
    
%         scalpvert(:,1)=scalpvert(:,1)-mean(scalpvert(:,1));
%         scalpvert(:,2)=scalpvert(:,2)-mean(scalpvert(:,2));
%         scalpvert(:,3)=scalpvert(:,3)-mean(scalpvert(:,3));
    
%     figure; scatter3(headshape_res(:,1),headshape_res(:,2),headshape_res(:,3));
%     hold on;
%     scatter3(scalpvert(:,1),scalpvert(:,2),scalpvert(:,3),'r');
%     

    
    landmark_funct = zeros(length(fid_labels),3);
    for i=1:length(fid_labels)
        idx = strcmpi(sens.label,fid_labels{i});
        landmark_funct(i,:) = scalpvert(idx,:);
    end
    
    
    % Align recorded positions to individual space
    M1 = net_rigidreg(landmark_struct',landmark_funct');
    
    
    scalpvert_aligned1 = (M1(1:3,1:3)*scalpvert'+M1(1:3,4)*ones(1,size(scalpvert,1)))';
    
    
%     figure; scatter3(headshape_res(:,1),headshape_res(:,2),headshape_res(:,3));
%     hold on;
%     scatter3(scalpvert_aligned1(:,1),scalpvert_aligned1(:,2),scalpvert_aligned1(:,3),'r');
%     
    
    
    % Align to headshape
    
    Options=[];
    %Options.Registration = 'Rigid';
    
    if strcmpi(method,'affine')
        Options.Registration = 'Affine';
    else
        Options.Registration = 'Rigid';
    end
    
    [~,M2]=ICP_finite(headshape_res, scalpvert_aligned1, Options);
    
    
    scalpvert_aligned2 = (M2(1:3,1:3)*scalpvert_aligned1'+M2(1:3,4)*ones(1,size(scalpvert_aligned1,1)))';
    
    
%     figure; scatter3(headshape_res(:,1),headshape_res(:,2),headshape_res(:,3));
%     hold on;
%     scatter3(scalpvert_aligned2(:,1),scalpvert_aligned2(:,2),scalpvert_aligned2(:,3),'r');

    
    
    for j = 1:size(scalpvert_aligned2,1)
        coord = scalpvert_aligned2(j,:);
        dist = sum((headshape-ones(size(headshape,1),1)*coord).^2,2); % Compute the distance from each vertices to the sensor position
        fitt_dist(j,kk)=min(dist);
    end
    
end


% figure; imagesc(inward_shift_range,[1:size(scalpvert_aligned2,1)],fitt_dist); colorbar;
% xlabel('inward shift (mm)'); ylabel('channel number'); title('headshape to electrode distance');

[val,pos]=min(mean(fitt_dist,1));

inward_shift=inward_shift_range(pos);

disp(['selected inward shift: ' num2str(inward_shift) ' mm - mean distance: ' num2str(val) ' mm']);

scalpvert=net_shift_pos(sens.elecpos,inward_shift);
% 
%         scalpvert(:,1)=scalpvert(:,1)-mean(scalpvert(:,1));
%         scalpvert(:,2)=scalpvert(:,2)-mean(scalpvert(:,2));
%         scalpvert(:,3)=scalpvert(:,3)-mean(scalpvert(:,3));

landmark_funct = zeros(length(fid_labels),3);
for i=1:length(fid_labels)
    idx = strcmpi(sens.label,fid_labels{i});
    landmark_funct(i,:) = scalpvert(idx,:);
end


% Align recorded positions to individual space
M1 = net_rigidreg(landmark_struct',landmark_funct');

scalpvert_aligned1 = (M1(1:3,1:3)*scalpvert'+M1(1:3,4)*ones(1,size(scalpvert,1)))';


% figure; scatter3(headshape_res(:,1),headshape_res(:,2),headshape_res(:,3));
% hold on;
% scatter3(scalpvert_aligned1(:,1),scalpvert_aligned1(:,2),scalpvert_aligned1(:,3),'r');

% Align to headshape
Options=[];

if strcmpi(method,'affine')
    Options.Registration = 'Affine';
else
    Options.Registration = 'Rigid';
end

[~,M2]=ICP_finite(headshape_res, scalpvert_aligned1, Options);

scalpvert_aligned2 = (M2(1:3,1:3)*scalpvert_aligned1'+M2(1:3,4)*ones(1,size(scalpvert_aligned1,1)))';

% figure; scatter3(headshape_res(:,1),headshape_res(:,2),headshape_res(:,3));
% hold on;
% scatter3(scalpvert_aligned2(:,1),scalpvert_aligned2(:,2),scalpvert_aligned2(:,3),'r');


end

% Align to exact headshape vertices
scalpvert_final = scalpvert_aligned2;
for j = 1:size(scalpvert_aligned2,1)
    coord = scalpvert_aligned2(j,:);
    dist = sum((headshape-ones(size(headshape,1),1)*coord).^2,2); % Compute the distance from each vertices to the sensor position
    [~,pos] = min(dist); % Find the vertice that is close to the sensor position
    scalpvert_final(j,:)=headshape(pos,:); % Now use that vertices as the sensor position
end

% 
% figure; scatter3(headshape_res(:,1),headshape_res(:,2),headshape_res(:,3));
% hold on;
% scatter3(scalpvert_final(:,1),scalpvert_final(:,2),scalpvert_final(:,3),'r','filled');


elec = [];
elec.label=upper(sens.label);
elec.corP = scalpvert_final;