function mribx = CalculateSegmentationBox( segmentedmri )

msk = zeros(size(segmentedmri.anatomy));
msk(segmentedmri.anatomy>0) = 1;

msk_xy = zeros(size(msk,1), size(msk,2) ); 
for a = 1:size(msk,3)
    msk_xy = msk_xy + squeeze(msk(:,:,a));
end

msk_yz = zeros(size(msk,2), size(msk,3) ); 
for a = 1:size(msk,1)
    msk_yz = msk_yz + squeeze(msk(a,:,:));
end

% imshow(msk_yz)
[xm ym1 c] = find(msk_xy~=0);
[ym2 zm c] = find(msk_yz~=0);

bx =  [min(xm)   max(xm);
       min(ym1)  max(ym1);
       min(zm)   max(zm);];

Tr = eye(4);
Tr(1,4) = bx(1,1)-1;  Tr(2,4) = bx(2,1)-1;  Tr(3,4) = bx(3,1)-1;  

mri_sgbx = segmentedmri.anatomy(bx(1,1):bx(1,2), bx(2,1):bx(2,2), bx(3,1):bx(3,2) );

mribx = [];
mribx.dim       = size(mri_sgbx);
mribx.transform = Tr;
mribx.segTr     = segmentedmri.transform;
% mribx.coordsys  = segmentedmri.coordsys;
mribx.unit      = segmentedmri.unit;
mribx.anatomy   = mri_sgbx;
mribx.box       = bx;

% ft_sourceplot([], mribx)


