function elec=net_coregister_sensors(elecfile,mri_folder,eeg_folder,anat_filename,options_pos_convert)

NET_folder=net('path');

segimg_filename=[mri_folder filesep 'anatomy_prepro_segment.nii'];

img_filename=[mri_folder filesep 'anatomy_prepro.nii'];

fids=options_pos_convert.fiducial_labels;

tpl=options_pos_convert.template;

electrode_template_file=[NET_folder filesep 'template' filesep 'electrode_position' filesep tpl '.sfp'];

if not(exist(electrode_template_file,'file'))
    
    disp('problem with template montage!');
    
    return;
    
end


if strcmpi(fids,'all')
    
    template=ft_read_sens(electrode_template_file);
    template = ft_convert_units(template, 'mm');
    lbs=template.label;
    fid_labels=[];
    for kk=1:size(lbs,1)
        fid_labels{kk}=deblank(lbs(kk,:));
    end
    
else
    
    cont=0;
    fid_labels=[];
    while not(isempty(fids))
        [token, fids] = strtok(fids);
        cont=cont+1;
        fid_labels{cont}=token;
    end
    
end

if length(fid_labels)<3
    
    disp('problem with fiducial labels!');
    
    return;
    
end



elecx=net_elec_positions(elecfile,segimg_filename,fid_labels,electrode_template_file,img_filename,anat_filename,options_pos_convert.alignment);

fileID = fopen([mri_folder filesep 'electrode_positions.sfp'],'w');
for i = 1:length(elecx.label)
    fprintf(fileID, '%s\t%f\t%f\t%f\n',elecx.label{i}, elecx.corP(i,1), elecx.corP(i,2), elecx.corP(i,3)); % real sensors
end
fclose(fileID);

V=spm_vol(segimg_filename);
[segment,XYZ]=spm_read_vols(V);

exp = elecx.corP'; % electrodes coordinates

% datac=zeros(size(segment)); % this is to check which points are selected
% for z=1:length(exp)
%     coord=exp(:,z);
%     dist=sqrt(sum((XYZ-coord*ones(1,size(XYZ,2))).^2));
%     selvox= dist < 5;
%     datac(selvox)=1;
% end
% V.pinfo=[1;0;0];
% V.dt=[2 0];
% V.fname=[mri_folder filesep 'electrode_positions.nii']; %This image will be the region where we should trace for electrodes..
% spm_write_vol(V,datac);


% S = [];
% S.D = [eeg_folder filesep 'raw_eeg.mat'];
% S.task = 'loadeegsens'; %Loading eeg sensors will be the task to be done
% S.source = 'locfile';   % Use a location file for doing the above task
% S.sensfile = [mri_folder filesep 'electrode_positions.sfp'];
% S.save = true;
% D = spm_eeg_prep(S);
% D.save;

D=spm_eeg_load([eeg_folder filesep 'raw_eeg.mat']);
elec = ft_read_sens([mri_folder filesep 'electrode_positions.sfp']);
D = sensors(D, 'EEG', elec);
D.save;
elec.nelec = length(elec.elecpos);

%Ntissues=max(segment(:));

A=V(1).mat(1:3,1:3);
%B=V(1).mat(1:3,4);
res=abs(det(A))^(1/3);


mask=zeros(size(segment));
mask(segment>0)=1;
mask=imfill(mask,'holes');

niter=5;

mask_smooth=mask;
for kk=1:niter
    mask_smooth = smooth3(mask_smooth,'box',7);
end
mask_smooth=round(mask_smooth);


x=XYZ(1,:)'; x=reshape(x,size(mask));
y=XYZ(2,:)'; y=reshape(y,size(mask));
z=XYZ(3,:)'; z=reshape(z,size(mask));


fv = isosurface(x,y,z,mask,0);
fv=smoothpatch(fv,1,5);
%     figure; p=patch(fv);
%     %nn=patchnormals(fv);
%     p.FaceColor = [0.8 0.8 0.8];
%     p.EdgeColor = 'none';
%     daspect([1 1 1])
%     view(3);
%     axis tight
%     camlight
%     lighting gouraud

points_tot=fv.vertices';
list=zeros(1,length(exp));
for kk=1:length(exp)
    coord=exp(:,kk);
    dist=sqrt(sum((points_tot-coord*ones(1,size(points_tot,2))).^2));
    [a,pos]=min(dist);    % disp(a);
    list(kk)=pos;
end

points=points_tot(:,list)';

fv2 = isosurface(x,y,z,mask_smooth,0);
fv2=smoothpatch(fv2,1,5);
norm2=patchnormals(fv2);
%     figure; p2=patch(fv2);
%     p2.FaceColor = [0.8 0.8 0.8];
%     p2.EdgeColor = 'none';
%     daspect([1 1 1])
%     view(3);
%     axis tight
%     camlight
%     lighting gouraud

points_tot=fv2.vertices';
list=zeros(1,length(exp));
for kk=1:length(exp)
    coord=exp(:,kk);
    dist=sqrt(sum((points_tot-coord*ones(1,size(points_tot,2))).^2));
    [~,pos]=min(dist);    % disp(a);
    list(kk)=pos;
end


normals=norm2(list,:);


elec_radius=4;
NOP = 360; verSamp = 5;
r = 0.5:0.5:elec_radius; % parameters used for modeling of electrodes and gel

gel_height = 2; elec_height = 4; % heights of electrodes and gel

center=mean(fv.vertices,1);

electrode_coord=points;

%segment_new=segment;
segment_new=zeros(size(segment));

[xx,yy,zz] = ndgrid(-5:5);
nhood5 = sqrt(xx.^2 + yy.^2 + zz.^2) <= ceil(5/res);

niter=3;
mask_new=mask;
for i=1:niter
    mask_new=imdilate(mask_new,nhood5);
end
mask_new(mask==1)=0;
vect=find(mask_new(:)==1);
XYZout=XYZ(:,vect);

gel_C=cell(length(electrode_coord),1);
elec_C=cell(length(electrode_coord),1);

for i=1:length(electrode_coord)
    
    normal=normals(i,:);
    gel_out = electrode_coord(i,:) +  gel_height*normal;
    electrode = gel_out + elec_height*normal;
    gel_in = gel_out - 2*gel_height*normal; % coordinates of the boundaries of gel and electrode
    if norm(center - gel_out) < norm(center - electrode_coord(i,:))
        normal = -normal;
        gel_out = electrode_coord(i,:) +  gel_height*normal;
        electrode = gel_out + elec_height*normal;
        gel_in = gel_out - 2*gel_height*normal;
    end % make sure the normal is pointing out
    
    gel_X = zeros(length(r)*verSamp*4,NOP); gel_Y = zeros(length(r)*verSamp*4,NOP); gel_Z = zeros(length(r)*verSamp*4,NOP);
    elec_X = zeros(length(r)*verSamp,NOP); elec_Y = zeros(length(r)*verSamp,NOP); elec_Z = zeros(length(r)*verSamp,NOP);
    for j = 1:length(r)
        [gel_X(((j-1)*verSamp*4+1):verSamp*4*j,:), gel_Y(((j-1)*verSamp*4+1):verSamp*4*j,:), gel_Z(((j-1)*verSamp*4+1):verSamp*4*j,:)] = cylinder2P(ones(verSamp*4)*r(j),NOP,gel_in,gel_out);
        [elec_X(((j-1)*verSamp+1):verSamp*j,:), elec_Y(((j-1)*verSamp+1):verSamp*j,:), elec_Z(((j-1)*verSamp+1):verSamp*j,:)] = cylinder2P(ones(verSamp)*r(j),NOP,gel_out,electrode);
    end % Use cylinders to model electrodes and gel, and calculate the coordinates of the points that make up the cylinder
    
    gel_coor = floor([gel_X(:) gel_Y(:) gel_Z(:)]);
    gel_coor = unique(gel_coor,'rows');
    elec_coor = floor([elec_X(:) elec_Y(:) elec_Z(:)]);
    elec_coor = unique(elec_coor,'rows'); % clean-up of the coordinates
    
    dist=sqrt(sum((XYZout-electrode_coord(i,:)'*ones(1,size(XYZout,2))).^2));
    selvox= find(dist < 15);
    XYZsel=XYZout(:,selvox);
    D=pdist2(gel_coor,XYZsel');
    vv= min(D,[],1)<=1;
    %indx=vect(selvox(vv));
    [a,b,c]=ind2sub(size(segment),vect(selvox(vv)));
    for ww=1:length(a)
        segment_new(a(ww),b(ww),c(ww))=1;
    end
    
    
    D=pdist2(elec_coor,XYZsel');
    vv= min(D,[],1)<=1;
    %indx=vect(selvox(vv));
    [a,b,c]=ind2sub(size(segment),vect(selvox(vv)));
    for ww=1:length(a)
        segment_new(a(ww),b(ww),c(ww))=2;
    end
    
    
    gel_C{i} = gel_coor; elec_C{i} = elec_coor; % buffer for coordinates of each electrode and gel point
    fprintf('%d out of %d electrodes placed...\n',i,length(electrode_coord));
    
    
end

%% saving results

V.fname=[mri_folder filesep 'electrode_positions.nii'];
spm_write_vol(V,segment_new);

%% plotting results
%     figure; p=patch(fv);
%     p.FaceColor = [1 0.9 0.8];
%     p.EdgeColor = 'none';
%     daspect([1 1 1])
%     view(3);
%     axis tight
%     camlight
%     lighting gouraud
%     %   gel_C{i} = gel_coor; elec_C{i} = elec_coor; % buffer for coordinates of each electrode and gel point
%     hold on;
%     for i=1:length(electrode_coord)
%         gel_coor=gel_C{i}; elec_coor=elec_C{i};
%         plot3(elec_coor(:,1),elec_coor(:,2),elec_coor(:,3),'.b');
%         plot3(gel_coor(:,1),gel_coor(:,2),gel_coor(:,3),'.w');
%     end


%end
