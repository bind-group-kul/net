function [mask4] = net_filling_mask(mask4)
for zz=1:size(mask4,2)
    ima=squeeze(mask4(:,zz,:));
    if sum(ima(:))>0 && sum(ima(:))<numel(ima)
        [L,NUM] = bwlabeln(1-ima,8);
        vox=zeros(1,NUM);
        for z=1:NUM
            vox(z)=sum(L(:)==z);%The number of voxel locations belonging to a particular component..
        end
        
        [Y,I]=sort(vox,'descend'); %For selecting the biggest component..
        ima_new=zeros(size(ima));
        ima_new(L<I(1) | L>I(1))=1; %Setting all other components to zero, apart from the biggest one..
        mask4(:,zz,:)=ima_new;
    end
end

for zz=1:size(mask4,1)
    ima=squeeze(mask4(zz,:,:));
    if sum(ima(:))>0 && sum(ima(:))<numel(ima)
        [L,NUM] = bwlabeln(1-ima,8);
        vox=zeros(1,NUM);
        for z=1:NUM
            vox(z)=sum(L(:)==z);%The number of voxel locations belonging to a particular component..
        end
        
        [Y,I]=sort(vox,'descend'); %For selecting the biggest component..
        ima_new=zeros(size(ima));
        ima_new(L<I(1) | L>I(1))=1; %Setting all other components to zero, apart from the biggest one..
        mask4(zz,:,:)=ima_new;
    end
end

for zz=1:size(mask4,3)
    ima=squeeze(mask4(:,:,zz));
    if sum(ima(:))>0 && sum(ima(:))<numel(ima)
        [L,NUM] = bwlabeln(1-ima,8);
        vox=zeros(1,NUM);
        for z=1:NUM
            vox(z)=sum(L(:)==z);%The number of voxel locations belonging to a particular component..
        end
        
        [Y,I]=sort(vox,'descend'); %For selecting the biggest component..
        ima_new=zeros(size(ima));
        ima_new(L<I(1) | L>I(1))=1; %Setting all other components to zero, apart from the biggest one..
        mask4(:,:,zz)=ima_new;
    end
end

end

