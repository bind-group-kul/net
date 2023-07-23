% gfdm_BoxMri.m
% Ernesto Cuartas M (ECM), 16/06/2020
% Email:  ecuartasm@gmail.com

function box = gfdm_BoxMri( data )

% mx_v = max(data(:));
% data_n = 100*data/mx_v;

max_val = prctile(data(:),99.5);
thres   = 0.1*max_val;

mask=zeros(size(data));
mask(data>thres)=1;
mask=imfill(mask,4);
%mask=imopen(mask,strel('sphere',3));
mask = bwareaopen(mask,3);
img=bwlabeln(mask);
nvox=zeros(1,max(img(:)));
for i=1:max(img(:))
    nvox(i)=sum(img(:)==i);
end
[val,pos]=max(nvox);
mask=zeros(size(data));
mask(img==pos)=1;

data(mask==0) = 0;
xval=squeeze(sum(sum(data,2),3));
yval=squeeze(sum(sum(data,1),3))';
zval=squeeze(sum(sum(data,1),2));

% datax = data(xval>0,yval>0,zval>0);

[xm c] = find(xval>0);
[ym c] = find(yval>0);
[zm c] = find(zval>0);

box =  [min(xm)  max(xm);
        min(ym)  max(ym);
        min(zm)  max(zm) ];

% msk_xy = zeros(size(msk,1), size(msk,2) ); 
% for a = 1:size(msk,3)
%     msk_xy = msk_xy + squeeze(msk(:,:,a));
% end
% 
% msk_yz = zeros(size(msk,2), size(msk,3) ); 
% for a = 1:size(msk,1)
%     msk_yz = msk_yz + squeeze(msk(a,:,:));
% end

% imshow(msk_yz)
% [xm ym1 c] = find(xval~=0);
% [ym2 zm c] = find(yval~=0);

% box =  [min(xm)  max(xm);
%         min(ym1) max(ym1);
%         min(zm)  max(zm) ];
     
     