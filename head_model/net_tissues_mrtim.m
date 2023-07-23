function masksegm = net_tissues_mrtim(data_anat,tpm,res)

% Authors: Gaia Amaranta Taberna, Dante Mantini v2.2

fprintf([ ...
'\n' ... 
'================================================== \n' ...
' __   __  ______           _______  ___   __   __ \n' ...
'|  |_|  ||    _ |         |       ||   | |  |_|  | \n' ...
'|       ||   | ||   ____  |_     _||   | |       | \n' ...
'|       ||   |_||_ |____|   |   |  |   | |       | \n' ...
'|       ||    __  |         |   |  |   | |       | \n' ...
'| ||_|| ||   |  | |         |   |  |   | | ||_|| | \n' ...
'|_|   |_||___|  |_|         |___|  |___| |_|   |_| \n' ...
'\n    * MR-BASED HEAD TISSUE MODELLING Toolbox * \n' ...
'================================================== \n \n' ...
]);

disp('Starting head tissue segmentation...')

data_anat=data_anat/max(data_anat(:));

ntissues = 12;
segment_new = zeros([size(data_anat),ntissues+1]);
tpm_new = tpm;

%% WM
disp('1/12')

% processed image
Ior=imreconstruct(imopen(data_anat,strel('sphere',5)),data_anat);

int=min(Ior(:)):.001:max(Ior(:));
hi=histcounts(Ior(Ior>0.01*max(Ior(:))),int);

n=5; % Gaia 03.04.20 *****
% hi_avg = tsmovavg(hi,'s',n,1); % Gaia 03.04.20 *****
hi_avg = movmean(hi',5);

%fitobj = fit(int(n:end)',hi_avg(n:end),'gauss3');
fitobj = fit(int(2:end)',hi_avg,'gauss3');

[mu,idx_mu] = sort([fitobj.b1 fitobj.b2 fitobj.b3]); % 13.12.19b
sigma = 1./[sqrt(2/fitobj.c1^2) sqrt(2/fitobj.c2^2) sqrt(2/fitobj.c3^2)]; % 13.12.19b
sigma = sigma(idx_mu); % 13.12.19b

% mu = [fitobj.b1 fitobj.b2 fitobj.b3]; % mu2 = gm; mu3 = wm % 13.12.19b
% sigma = 1./[sqrt(2/fitobj.c1^2) sqrt(2/fitobj.c2^2) sqrt(2/fitobj.c3^2)]; % 13.12.19b
hi_fit = fitobj(int);

[pks,pks_locs,pks_w] = findpeaks(hi_fit); % 13.12.19b
% t_wm = mu(1)+sigma(1)/4;
t_wm = int(round(pks_locs(1))); % 13.12.19b

locs = int(pks_locs);
if numel(locs)>1
    t_wm = locs(find(locs>0.12,1)); %%%% GAIA 07.03.22: 0.12 instead of 0.15
else
    t_wm = locs(1);
end

% [pks,pks_locs,pks_w] = findpeaks(-hi_fit); % 13.12.19b
% t_wm = int(round(pks_locs(end)-pks_w(end)));  % -2* Gaia 09.12.19 % 13.12.19b
% Iwm = Ior.*(Ior>t_wm); ****

Iwm = (Ior>t_wm);

% tissue probability map (NET)
% img_filename = '/Users/u0114283/Documents/PhD/MR tissues/new_segm/mr_data/rc3anatomy_prepro.nii';
% Vtpm=spm_vol(img_filename);
% data_tpm_b=spm_read_vols(Vtpm);
% img_filename = '/Users/u0114283/Documents/PhD/MR tissues/new_segm/mr_data/rc4anatomy_prepro.nii';
% Vtpm=spm_vol(img_filename);
% data_tpm_c=spm_read_vols(Vtpm);
% img_filename = '/Users/u0114283/Documents/PhD/MR tissues/new_segm/mr_data/rc5anatomy_prepro.nii';
% Vtpm=spm_vol(img_filename);
% data_tpm_bs=spm_read_vols(Vtpm);
% data_tpm_wm = data_tpm_b+data_tpm_c+data_tpm_bs;

data_tpm_b = tpm(:,:,:,3);
data_tpm_c = tpm(:,:,:,4);
data_tpm_bs = tpm(:,:,:,5);
data_tpm_wm = data_tpm_b+data_tpm_c+data_tpm_bs;

% preliminary masks
wm_b = Iwm.*(data_tpm_b>0.05); % 0.01 % 27.10.20
wm_c = Iwm.*(data_tpm_c>0.25); % 0.01 % 27.10.20
wm_bs = Iwm.*(data_tpm_bs>0.05); % 0.01 % 27.10.20

disp('2/12')

% adjust overlap
idx_inters = intersect(find(wm_b),find(wm_c));
idx_inters = [idx_inters; intersect(find(wm_b),find(wm_bs))];
idx_inters = [idx_inters; intersect(find(wm_c),find(wm_bs))];
idx_inters = unique(idx_inters);
wm_b_tpm = data_tpm_b(idx_inters);
wm_c_tpm = data_tpm_c(idx_inters);
wm_bs_tpm = data_tpm_bs(idx_inters);
[~,max_wm_inters]=max([wm_b_tpm wm_c_tpm wm_bs_tpm],[],2); 

% update masks
wm_b(idx_inters(max_wm_inters==2 | max_wm_inters==3)) = 0;
wm_b=imopen(wm_b,strel('sphere',1));
wm_c(idx_inters(max_wm_inters==1 | max_wm_inters==3)) = 0;
wm_c=imopen(wm_c,strel('sphere',1));
wm_bs(idx_inters(max_wm_inters==1 | max_wm_inters==2)) = 0;
wm_bs=imopen(wm_bs,strel('sphere',1));

disp('3/12')

wm_b=imerode(wm_b,strel('sphere',1)); % 13.12.19c
CC = bwconncomp(wm_b);
[~,idx_wm_b]=sort(cellfun(@length,CC.PixelIdxList),'descend');
wm_b = zeros(size(data_anat));
wm_b(CC.PixelIdxList{idx_wm_b(1)}) = 1;
% wm_b=imopen(wm_b,strel('sphere',1)); % 13.12.19b
% wm_b=imerode(wm_b,strel('sphere',1)); % 13.12.19b

wm_c=imerode(wm_c,strel('sphere',1)); % 13.12.19c
CC = bwconncomp(wm_c);
[~,idx_wm_c]=sort(cellfun(@length,CC.PixelIdxList),'descend');
wm_c = zeros(size(data_anat));
wm_c(CC.PixelIdxList{idx_wm_c(1)}) = 1;
% wm_c=imopen(wm_c,strel('sphere',1)); % 13.12.19b
% wm_c=imerode(wm_c,strel('sphere',1)); % 13.12.19b

wm_bs=imerode(wm_bs,strel('sphere',2)); % 13.12.19c
CC = bwconncomp(wm_bs);
[~,idx_wm_bs]=sort(cellfun(@length,CC.PixelIdxList),'descend');
wm_bs = zeros(size(data_anat));
wm_bs(CC.PixelIdxList{idx_wm_bs(1)}) = 1;
wm_bs=imdilate(wm_bs,strel('sphere',1)); % 13.12.19c
% wm_bs=imopen(wm_bs,strel('sphere',1)); % 13.12.19b
% wm_bs=imerode(wm_bs,strel('sphere',1)); % 13.12.19b

wm_tot = zeros(size(wm_b));
wm_tot(find(wm_b)) = 3;
wm_tot(find(wm_c)) = 4;
wm_tot(find(wm_bs)) = 5;

segment_new(:,:,:,4) = wm_b;
segment_new(:,:,:,5) = wm_c;
segment_new(:,:,:,6) = wm_bs;


%% GM
disp('4/12')

% processed brain image
[pks,pks_locs,pks_w] = findpeaks(hi_fit);
if round(pks_locs(1)-pks_w(1)/2)>0
    t_gm = int(round(pks_locs(1)-pks_w(1)/2));
else
    t_gm = 0;
end
Igm = Ior.*(Ior>t_gm);% & Ior<=tr_wm);

% tissue probability map (NET)
% img_filename = '/Users/u0114283/Documents/PhD/MR tissues/new_segm/mr_data/rc1anatomy_prepro.nii';
% Vtpm=spm_vol(img_filename);
% data_tpm_b=spm_read_vols(Vtpm);
% img_filename = '/Users/u0114283/Documents/PhD/MR tissues/new_segm/mr_data/rc2anatomy_prepro.nii';
% Vtpm=spm_vol(img_filename);
% data_tpm_c=spm_read_vols(Vtpm);
% data_tpm_gm = data_tpm_b+data_tpm_c;

data_tpm_b = tpm(:,:,:,1);
data_tpm_c = tpm(:,:,:,2);
data_tpm_gm = data_tpm_b+data_tpm_c;

% adjust bGM mask % Gaia 09.12.19
CC=bwconncomp(data_tpm_b>0.7);
[~,idx]=sort(cellfun(@length,CC.PixelIdxList),'descend');
data_tpm_b2=zeros(size(data_tpm_b));
data_tpm_b2(CC.PixelIdxList{idx(1)})=1;
data_tpm_b2 = imdilate(data_tpm_b2,strel('sphere',3));

% adjust cGM mask % Gaia 09.12.19
CC=bwconncomp(data_tpm_c>0.5);
[~,idx]=sort(cellfun(@length,CC.PixelIdxList),'descend');
data_tpm_c2=zeros(size(data_tpm_c));
data_tpm_c2(CC.PixelIdxList{idx(1)})=1;
data_tpm_c2 = imdilate(data_tpm_c2,strel('sphere',3));
data_tpm_gm = data_tpm_b.*data_tpm_b2+data_tpm_c.*data_tpm_c2;

tpm_new(:,:,:,1) = data_tpm_b.*data_tpm_b2; % data_tpm_b % Gaia 11.12.19
tpm_new(:,:,:,2) = data_tpm_c.*data_tpm_c2; % data_tpm_c % Gaia 11.12.19

% preliminary masks
% gm = (Igm>0).*(data_tpm_gm>0.1).*imcomplement(wm_tot);
gm = imcomplement(wm_tot).*(data_tpm_gm>0.1); % Gaia 03.04.20 ****
CC = bwconncomp(gm);
[~,idx_gm_b]=sort(cellfun(@length,CC.PixelIdxList),'descend');
gm = zeros(size(data_anat));
gm(CC.PixelIdxList{idx_gm_b(1)}) = 1;

disp('5/12')

gm=smooth3(gm,'box',3);
gm=gm>0.3;
CC = bwconncomp(gm);
[~,idx_gm_b]=sort(cellfun(@length,CC.PixelIdxList),'descend');
gm = zeros(size(data_anat));
gm(CC.PixelIdxList{idx_gm_b(1)}) = 1;
gm = gm.*imcomplement(wm_tot);

gm_b = gm.*(data_tpm_b>0.1);
gm_c = gm.*(data_tpm_c>0.1);

% adjust overlap
idx_inters = intersect(find(gm_b),find(gm_c));
gm_b_tpm = data_tpm_b(idx_inters);
gm_c_tpm = data_tpm_c(idx_inters);
[~,max_gm_inters]=max([gm_b_tpm gm_c_tpm],[],2); 

% update masks
gm_b(idx_inters(max_gm_inters==2)) = 0;
% gm_b=imclose(gm_b,strel('sphere',1)); % imopen Gaia 10.12.19 % 13.12.19
gm_c(idx_inters(max_gm_inters==1)) = 0;
% gm_c=imclose(gm_c,strel('sphere',1)); % imopen Gaia 10.12.19 % 13.12.19

gm_b(find(wm_b)) = 0; % 13.12.19
gm_c(find(wm_c)) = 0; % 13.12.19

CC = bwconncomp(gm_b);
[~,idx_gm_b]=sort(cellfun(@length,CC.PixelIdxList),'descend');
gm_b = zeros(size(data_anat));
gm_b(CC.PixelIdxList{idx_gm_b(1)}) = 1;

CC = bwconncomp(gm_c);
[~,idx_gm_c]=sort(cellfun(@length,CC.PixelIdxList),'descend');
gm_c = zeros(size(data_anat));
gm_c(CC.PixelIdxList{idx_gm_c(1)}) = 1;

gm_tot = zeros(size(gm_b));
gm_tot(find(gm_b)) = 1;
gm_tot(find(gm_c)) = 2;

segment_new(:,:,:,2) = gm_b;
segment_new(:,:,:,3) = gm_c;


%% Eyes
disp('6/12')

% tissue probability map (NET)
% img_filename = '/Users/u0114283/Documents/PhD/MR tissues/new_segm/mr_data/rc11anatomy_prepro.nii';
% Vtpm=spm_vol(img_filename);
% data_tpm=spm_read_vols(Vtpm);

data_tpm = tpm(:,:,:,11);

%{
t_eyes = mu(2);
% eyes = (Ior<t_eyes).*(data_tpm>0.7);
eyes = (Ior<t_eyes).*(data_tpm>0.9); % Gaia 02.04.20 ****
%}

eyes = data_tpm>0.9; % Gaia 07.04.20 *** 0.9 ULTIMO %0.7
CC=bwconncomp(eyes);
[~,idx_eyes]=sort(cellfun(@length,CC.PixelIdxList),'descend');
if CC.NumObjects>2
    for k = 3:CC.NumObjects
        eyes(CC.PixelIdxList{idx_eyes(k)}) = 0;
    end
end
eyes2=smooth3(eyes,'box',7);
eyes=zeros(size(data_anat));
eyes(eyes2>0.2)=1;
% eyes = imerode(eyes,strel('sphere',1)); % Gaia 19.11.19

segment_new(:,:,:,12) = eyes;
[~,masksegm]=max(segment_new,[],4);

%% CSF
disp('7/12')

% img_filename = '/Users/u0114283/Documents/PhD/MR tissues/new_segm/mr_data/rc6anatomy_prepro.nii';
% Vtpm=spm_vol(img_filename);
% data_tpm=spm_read_vols(Vtpm);

data_tpm = tpm(:,:,:,6);

csf=(data_tpm>0.05).*imdilate((masksegm>1 & masksegm<12),strel('sphere',3));
csf=smooth3(csf,'box',5);
csf=smooth3(csf>0.1,'box',3)>0.6;

% *****
maskbrain = imfill(masksegm>1 & masksegm<12,'holes');
q = quantile(Ior(data_tpm>0.3),[0.025 0.975]);
csf = (Ior>q(1) & Ior<q(2)).*(data_tpm>0.01);
csf = csf + imdilate(maskbrain,strel('sphere',1));
csf(csf>1) = 1;
csf = csf.*imdilate((masksegm>1 & masksegm<12),strel('sphere',3));
csf=smooth3(csf,'box',5);
csf=smooth3(csf>0.1,'box',3)>0.6;
% *****

CC = bwconncomp(csf);
[~,idx_csf]=sort(cellfun(@length,CC.PixelIdxList),'descend');
csf = zeros(size(data_anat));
csf(CC.PixelIdxList{idx_csf(1)}) = 1;
if numel(CC.PixelIdxList)>1
    csf(CC.PixelIdxList{idx_csf(2)}) = 1;
end
csf(find(wm_tot)) = 0; % 13.12.19
csf(find(gm_tot)) = 0; % 13.12.19

segment_new(:,:,:,7) = csf;
[~,masksegm]=max(segment_new,[],4);


%% Compacta
disp('8/12')

% tissue probability map (NET)
% img_filename = '/Users/u0114283/Documents/PhD/MR tissues/new_segm/mr_data/rc8anatomy_prepro.nii';
% Vtpm=spm_vol(img_filename);
% data_tpm_comp=spm_read_vols(Vtpm);

data_tpm_comp = tpm(:,:,:,8);
data_tpm_spong = tpm(:,:,:,7);
%{
data2=data_anat;
data2(data2<0.01*max(data_anat(:)))=1;
data3=1-data2;
Icomp=imreconstruct(imopen(data3,strel('sphere',5)),data2);

int=min(Icomp(:)):.001:max(Icomp(:));
hi=histc(Icomp(Icomp<0.99*max(Icomp(:))),int); % Gaia 05.11.19
% hi=histc(Icomp(:),int);   % Gaia 05.11.19
figure,plot(int,hi)
n = 3;
hi_avg = tsmovavg(hi,'s',n,1);
fitobj = fit(int(n:end)',hi_avg(n:end),'gauss3');
[mu,idx_mu] = sort([fitobj.b1 fitobj.b2 fitobj.b3]);
sigma = 1./[sqrt(2/fitobj.c1^2) sqrt(2/fitobj.c2^2) sqrt(2/fitobj.c3^2)];
sigma = sigma(idx_mu);
hi_fit = fitobj(int);
hold on,plot(int,hi_fit)
% t_comp = mu(2);   % Gaia 13.11.19
% t_comp = mu(find(mu>0.15,1));
t_comp = mu(2)-2*sigma(2); % Gaia 01.04.20 ???

% updated mask
comp = (Icomp<(t_comp)); %+sigma(2)));
%}
t_comp = 0.25;
if (mu(1)-sigma(1)) >= t_comp
    comp = data_anat<(mu(1)-sigma(1)) & data_anat>0; % Gaia 02.04.20
else
    comp = data_anat<t_comp & data_anat>0;
end
comp = comp.*((data_tpm_comp+data_tpm_spong)>0.05);
% comp = imerode(comp,strel('sphere',1));

maskbrain = segment_new(:,:,:,1:7);
maskbrain = sum(maskbrain,4);
maskbrain(maskbrain>0) = 1;
maskbrain = imfill(maskbrain,'holes');     % Gaia 14.11.19
comp=smooth3(comp,'box',5);
comp=smooth3(comp>0.3,'box',5)>0.5; % box 3 >0.6
comp(find(maskbrain))=0;

%{
% for i=1:size(maskbrain,3)
%     maskbrain(:,:,i) = imfill(maskbrain(:,:,i),'holes');
% end
% maskbrain_er = imerode(maskbrain,strel('sphere',3));
comp(find(maskbrain))=1;
comp = imerode(comp,strel('sphere',3));
comp(find(maskbrain))=0;

comp = smooth3(comp,'box',5);
comp=smooth3(comp>0.05,'box',5)>0.5; %3, 0.5;
comp=imclose(comp,strel('sphere',5));
comp(find(maskbrain))=0;
%}

CC = bwconncomp(comp);
[~,idx_comp]=sort(cellfun(@length,CC.PixelIdxList),'descend');
comp = zeros(size(data_anat));
comp(CC.PixelIdxList{idx_comp(1)}) = 1;

% segment_new(:,:,:,9) = comp;

%% Skin
disp('9/12')

% tissue probability map (NET)
% img_filename = '/Users/u0114283/Documents/PhD/MR tissues/new_segm/mr_data/rc12anatomy_prepro.nii';
% Vtpm=spm_vol(img_filename);
% data_tpm=spm_read_vols(Vtpm);

% data_tpm = tpm(:,:,:,12);

[xx,yy,zz] = ndgrid(-5:5);
nhood5 = sqrt(xx.^2 + yy.^2 + zz.^2) <= ceil(5/res);
    nhood2 = sqrt(xx.^2 + yy.^2 + zz.^2) <= ceil(2/res);
    
    mask=zeros(size(data_anat));
    mask(data_anat>0.001*max(data_anat(:)))=1;
    mask=imdilate(mask,nhood5);
    mask=imfill(mask,'holes');
    for i=1:size(mask,3)
        mask(:,:,i)=imfill(mask(:,:,i),'holes');
    end
    mask=imerode(mask,nhood5);
    mask = smooth3(mask,'box',5);
    mask(mask<0.5)=0;
    mask(mask>=0.5)=1;
    mask=imerode(mask,nhood2);

%{
% max_val = prctile(data_anat(:),99.5);
% thres   = 0.1*max_val;
mask=zeros(size(data_anat));
% mask(data_anat>thres)=1;
mask(data_anat>0)=1;
mask=imfill(mask,4);
for i=1:size(mask,3)
    mask(:,:,i)=imfill(mask(:,:,i),'holes');
end
mask = bwareaopen(mask,3);
img=bwlabeln(mask);
nvox=zeros(1,max(img(:)));
for i=1:max(img(:))
    nvox(i)=sum(img(:)==i);
end
[~,pos]=max(nvox);
mask=zeros(size(data_anat));
mask(img==pos)=1;
mask = smooth3(mask,'box',[7 7 7]);
mask = (mask>0.7);
CC = bwconncomp(mask);
mask = zeros(size(data_anat));
mask(CC.PixelIdxList{1}) = 1;
%}

mask_dil = imdilate(mask,strel('sphere',2)); % 3
mask_er = mask; %imerode(mask,strel('sphere',1)); % no erosion (Gaia)

masksegm=mask_dil.*masksegm;
skin = mask_dil-mask_er;

% Gaia 10.12.19
CC = bwconncomp(skin);
[~,idx]=sort(cellfun(@length,CC.PixelIdxList),'descend');
skin = zeros(size(data_anat));
skin(CC.PixelIdxList{idx(1)}) = 1;

segment_new(:,:,:,13) = skin;
% masksegm(find(skin)) = 12;

%% Spongiosa
disp('10/12')

% tissue probability map (NET)
% img_filename = '/Users/u0114283/Documents/PhD/MR tissues/new_segm/mr_data/rc7anatomy_prepro.nii';
% Vtpm=spm_vol(img_filename);
% data_tpm=spm_read_vols(Vtpm);

% Adjust compacta
maskskin = imdilate(skin,strel('sphere',3)); % 5
comp(find(maskskin)) = 0;
comp = imerode(comp,strel('sphere',2));

CC=bwconncomp(comp);
[~,idx]=sort(cellfun(@length,CC.PixelIdxList),'descend');
comp = zeros(size(data_anat));
comp(CC.PixelIdxList{idx(1)}) = 1;

comp = imdilate(comp,strel('sphere',1)); %%%%%% 07.04.20 *** % 2 % ultimo

% Dilate compacta
% segment_new(:,:,:,9) = comp;
% [~,masksegm]=max(segment_new,[],4);
% masktot = (masksegm>0 & masksegm<10);
% masktot = imfill(masktot,'holes');
% masktot_dil = imdilate(masktot,strel('sphere',2));  % 2/3  % Gaia 09.12.19
% idxcomp = find(masktot_dil-masktot);
% comp(idxcomp) = 1;

data_tpm = tpm(:,:,:,7);

spong = (data_tpm>0.1);
% spong2=smooth3(spong,'box',5);
% spong2=smooth3(spong2>0.1,'box',3)>0.1;
spong(find(maskbrain))=0;
% spong=spong2;

% maskcomp = imerode(comp,strel('sphere',1));
% maskcomp = imerode(maskcomp,strel('sphere',1));
spong = comp.*spong; % maskcomp

CC=bwconncomp(spong);
[~,idx]=sort(cellfun(@length,CC.PixelIdxList),'descend');
spong = zeros(size(data_anat));
spong(CC.PixelIdxList{idx(1)}) = 1;

%{
spong = imdilate(spong,strel('sphere',3));
spong = spong.*imcomplement(maskbrain);
% spong = imerode(spong,strel('sphere',1)); % Gaia 10.12.19
maskbrain_dil = imdilate(maskbrain,strel('sphere',5));
spong = spong.*maskbrain_dil;
spong = imerode(spong,strel('sphere',1)); % Gaia 10.12.19

aa=maskbrain+2*comp+3*(data_tpm>0);
spong = (aa==4);
%}


%{
[~,masksegm]=max(segment_new,[],4);
masksegm = masksegm-1;
maskcomp = (masksegm>0 & masksegm<11);
maskcomp = imfill(maskcomp,'holes');
maskcomp = imerode(maskcomp,strel('sphere',1));
comp = comp.*maskcomp;

comp(find(spong)) = 0;
%}

% 27.10.20
% spong = imerode(((data_tpm_comp>0.1)+(data_tpm_spong>0.1))>0,strel('sphere',5)).*(data_tpm_spong>0.01);

comp(find(spong)) = 0;
segment_new(:,:,:,9) = comp;
segment_new(:,:,:,8) = spong;

%% Adjust tissue overlap

overlap=find(sum(segment_new,4)>1);
[px,py,pz]=ind2sub(size(segment_new),overlap);
for i=1:length(px)
    maxval=[0; squeeze(tpm_new(px(i),py(i),pz(i),:))];
    idxmax=(maxval==max(maxval));
    segment_new(px(i),py(i),pz(i),:) = squeeze(segment_new(px(i),py(i),pz(i),:)).*idxmax;
end

[~,masksegm]=max(segment_new,[],4);
masksegm = masksegm-1;

% Gaia 12.11.19 
masksegm(find(wm_b)) = 3; % 13.12.19
masksegm(find(wm_c)) = 4; % 13.12.19
masksegm(find(wm_bs)) = 5;
% masksegm(find(spong)) = 7;

% % Gaia 13.11.19 % 13.12.19
% new_wmb = (masksegm==3);
% new_wmb = imdilate(new_wmb,strel('sphere',1));
% new_wmc = (masksegm==4);
% new_wmc = imdilate(new_wmc,strel('sphere',1));
% masksegm(find(new_wmc))=4;
% masksegm(find(new_wmb))=3;

%Border bWM->bGM
masktot = (masksegm==3);
masktot = imfill(masktot,'holes');
masktot_dil = imdilate(masktot,strel('sphere',2)); % 1 % 13.12.19
idxgm = find(masktot_dil-masktot);
masksegm(idxgm)=1;
% cWM->cGM
masktot = (masksegm==4);
masktot = imfill(masktot,'holes');
masktot_dil = imdilate(masktot,strel('sphere',2)); % 1 % 13.12.19
idxgm = find(masktot_dil-masktot);
masksegm(idxgm)=2;

%Border CSF
masktot = (masksegm>0 & masksegm<6);
masktot = imfill(masktot,'holes');
masktot_dil = imdilate(masktot,strel('sphere',2)); % 1 % 13.12.19
idxcsf = find(masktot_dil-masktot);
masksegm(idxcsf)=6;

% border csf = comp % Gaia 09.12.19
masktot = (masksegm>0 & masksegm<7); % & masksegm<8
masktot = imfill(masktot,'holes');
masktot_dil = imdilate(masktot,strel('sphere',2));
idxcomp = find(masktot_dil-masktot);
masksegm(idxcomp)=8;

% border spong --> comp   % Gaia 12.11.19
maskspong = (masksegm==7);
maskspong_dil = imdilate(maskspong,strel('sphere',2)); % 3 % Gaia 09.12.19
idxcomp = find(maskspong_dil-maskspong);
idxcomp = idxcomp(~ismember(idxcomp,intersect(idxcomp,find(maskbrain))));
masksegm(idxcomp)=8;

%% Fat 
disp('11/12')

masktot = (masksegm>0 & masksegm<12);
masktot = imfill(masktot,'holes');
data_tpm_fat = tpm(:,:,:,10);
fat = data_tpm_fat>0;
fat(find(masktot)) = 0;
segment_new(:,:,:,11) = fat;

%% Muscle
disp('12/12')

data_tpm_muscle = tpm(:,:,:,9);
muscle = data_tpm_muscle>0.5;
muscle(find(masktot)) = 0;
%muscle(find(squeeze(segment_new(:,:,:,11)))) = 0;
segment_new(:,:,:,10) = muscle;

%% Adjust 2
disp('Adjusting...')

% adjust overlap muscle/fat
idx_inters = intersect(find(muscle),find(fat));
muscle_tpm = data_tpm_muscle(idx_inters);
fat_tpm = data_tpm_fat(idx_inters);
[~,max_inters]=max([muscle_tpm fat_tpm],[],2);
% update masks
muscle(idx_inters(max_inters==2)) = 0;
fat(idx_inters(max_inters==1)) = 0;
segment_new(:,:,:,10) = zeros(size(squeeze(segment_new(:,:,:,10))));
segment_new(:,:,:,11) = zeros(size(squeeze(segment_new(:,:,:,11))));
segment_new(:,:,:,10) = muscle;
segment_new(:,:,:,11) = fat;

masksegm(find(muscle)) = 9;
masksegm(find(fat)) = 10;

tiss = zeros(size(masksegm));
for i=1:ntissues
    CC=bwconncomp(masksegm==i);
    [~,idx_comp]=sort(cellfun(@length,CC.PixelIdxList),'descend');
    if ~isempty(idx_comp)
        if ~ismember(i,[9, 10])
            tiss(CC.PixelIdxList{idx_comp(1)}) = i;
            if i==6 || i==11
                tiss(CC.PixelIdxList{idx_comp(2)}) = i;
            end
        else
            CC = bwareaopen(masksegm==i,200);
            tiss(find(CC)) = i;
        end
    end
end
masksegm = tiss;

% masksegm(find(skin)) = 12; % commented (Gaia)

%% Fill holes
min_cluster=1000;
nvox=round(min_cluster/res.^3);
     
   for kk=1:ntissues
       img=zeros(size(masksegm));
       img(masksegm==kk)=1;
       cc=bwconncomp(img,18);
       for zz=1:cc.NumObjects
           if length(cc.PixelIdxList{zz})<nvox
               masksegm(cc.PixelIdxList{zz})=0;
           end
       end
   end
   


datax=zeros(size(tpm_new));
for i=1:ntissues
    data=zeros(size(masksegm));
    data(masksegm==i)=1;
    datax(:,:,:,i)=smooth3(data,'gaussian',[5 5 5]);
end

datax(:,:,:,ntissues+1)=0.0001*ones(size(masksegm));

[~,ss]=max(datax,[],4);
ss(ss==ntissues+1)=0;

masksegm(mask_dil==1 & masksegm==0)=ss(mask_dil==1 & masksegm==0);
masksegm(find(eyes)) = 11;

% remove skin from inside % Gaia 10.12.19
CC = bwconncomp(masksegm==12);
[~,idx]=sort(cellfun(@length,CC.PixelIdxList),'descend');
if CC.NumObjects > 1
    for i=2:CC.NumObjects
        masksegm(CC.PixelIdxList{idx(i)}) = 0;
    end
end

% Gap filling
CC = bwconncomp(mask_dil==0);
[~,idx]=sort(cellfun(@length,CC.PixelIdxList),'descend');
if CC.NumObjects > 1
    for i=2:CC.NumObjects
        mask_dil(CC.PixelIdxList{idx(i)}) = 1;
    end
end

mask_gap=zeros(size(masksegm));

mask_gap(masksegm==0)=1;
mask_gap(mask_dil==0)=0;

% Gap fill
cc=bwconncomp(mask_gap);
for zz=1:cc.NumObjects
    img_cluster=zeros(size(masksegm));
    img_cluster(cc.PixelIdxList{zz})=1;
    [fx,fy,fz] = gradient(img_cluster);
    vv=masksegm(abs(fx)+abs(fy)+abs(fz)>0);
    vv(vv==0)=[];
    if not(isempty(vv))
        masksegm(cc.PixelIdxList{zz})=mode(vv); % min
    end
end

masksegm(find(eyes))=11;    % Gaia 19.11.19

%{
masktot = (mask_dil>0); % masksegm>0
masktot = imfill(masktot,'holes');
% masktot_dil = imdilate(masktot,strel('sphere',1));
masktot_er = imerode(masktot,strel('sphere',2));
idxskin = find(masktot-masktot_er);
masksegm(idxskin) = 12;

masksegm = masksegm.*mask_dil;
%}

masksegm(find(skin)) = 12;
masksegm = masksegm .* imfill(skin,'holes');

masktot = (masksegm>0 & masksegm<7); % & masksegm<8
masktot = imfill(masktot,'holes');
masktot_dil = imdilate(masktot,strel('sphere',1));
idxcomp = find(masktot_dil-masktot);
masksegm(idxcomp)=8;

masktot = (masksegm>0 & masksegm<12); % & masksegm<8
masktot = imfill(masktot,'holes');
masktot_dil = imdilate(masktot,strel('sphere',1));
idxskin = find(masktot_dil-masktot);
masksegm(idxskin)=12;

%{
[~,t]=max(tpm,[],4);
masksegm(masksegm==12)=t(masksegm==12);

CC=bwconncomp(masksegm==12);
[~,idx]=sort(cellfun(@length,CC.PixelIdxList),'descend');
if CC.NumObjects > 1
    for i=2:CC.NumObjects
        masksegm(CC.PixelIdxList{idx(i)}) = t(CC.PixelIdxList{idx(i)});
    end
end

masksegm(find(skin)) = 12;
%}
