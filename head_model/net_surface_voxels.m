function ind_surf=net_surface_voxels(vol)
%Returns the index of all surface voxels in a binary volume
%The neighborhood of a voxel is defined by kernel

ind=find(vol);
sz=size(vol);
coor=zeros(length(ind),3);
[coor(:,1),coor(:,2),coor(:,3)]=ind2sub(sz,ind);

krnl=[];
for i=-1:1
    for j=-1:1
        for k=-1:1
            if ~(i==0 & j==0 & k==0)
                krnl=[krnl,[i;j;k]];
            end
        end
    end
end

x=repmat(coor(:,1),1,26)-repmat(krnl(1,:),length(ind),1);
y=repmat(coor(:,2),1,26)-repmat(krnl(2,:),length(ind),1);
z=repmat(coor(:,3),1,26)-repmat(krnl(3,:),length(ind),1);

bound1 = find( x<=0 );
bound2 = find( y<=0 );
bound3 = find( z<=0 );
bound4 = find( x>=sz(1) );
bound5 = find( y>=sz(2) );
bound6 = find( z>=sz(3) );
bound = unique([bound1; bound2; bound3; bound4; bound5; bound6]);
voxal_bound = mod(bound, size(x,1));
voxal_bound = unique(voxal_bound);

x(voxal_bound, :) = [];
y(voxal_bound, :) = [];
z(voxal_bound, :) = [];
ind(voxal_bound) = [];

ind_ngh=sub2ind(sz,x,y,z);
ind_surf = ind(voxal_bound);
for i=1:length(ind)
    if ~all(vol(ind_ngh(i,:)))
        ind_surf=[ind_surf;ind(i)];
    end
end
