function box = BoxMri( msk )

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

bx =  [min(xm)  min(ym1)  min(zm);
       max(xm)  max(ym1)  max(zm)];

box = [ bx ; mean([bx(1,1) bx(2,1)]) mean([bx(1,2) bx(2,2)]) mean([bx(1,3) bx(2,3)]) ];