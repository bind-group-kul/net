function net_tissues_sMRI(img_filename,tpm_filename,options_segment)

net_folder=net('path');


[dd,ff,ext]=fileparts(img_filename);

V=spm_vol(tpm_filename);
ntissues=length(V);



switch ntissues
    
    case 4
        
        segtemplate_image=[net_folder filesep 'template' filesep 'tissues_MNI' filesep 'eTPM3_binary.nii'];
        segindiv_image=[dd filesep 'weTPM3_binary.nii'];
        
    case 6
        
        segtemplate_image=[net_folder filesep 'template' filesep 'tissues_MNI' filesep 'eTPM6_binary.nii'];
        segindiv_image=[dd filesep 'weTPM6_binary.nii'];
        
        
    case 12
        
        segtemplate_image=[net_folder filesep 'template' filesep 'tissues_MNI' filesep 'eTPM12_binary.nii'];
        segindiv_image=[dd filesep 'weTPM12_binary.nii'];
        
        
end


deformation_file=[dd filesep 'iy_' ff '.nii'];

V1=spm_vol(img_filename);
datat=spm_read_vols(V1);



Vx=spm_vol([dd filesep ff '_tpm' ext]);
datatot=spm_read_vols(Vx);
Vt=Vx(1);

res=(abs(det(Vt.mat(1:3,1:3))))^(1/3); % determine image resolution


if strcmpi(options_segment.segmentation_mode,'mrtim')
    
    masksegm = net_tissues_mrtim(datat,datatot,res);
    
    disp('Saving results...')

    V=V1;
    V.fname=[dd filesep ff '_segment' ext];
    V.dt=[4 0];
    V.pinfo=[1;0; 0];
    V.n=[1 1];
    spm_write_vol(V,masksegm);
    
    % Save single tissue masks (optional)
    maskflag = 0; % maskflag: save individual tissue masks (1) or not (0)
    
    if maskflag == 1
        folder_tiss = [dd filesep 'tissue_masks'];
        if ~exist(folder_tiss,'dir')
            mkdir([dd filesep 'tissue_masks'])
        end
        V.fname = [dd filesep 'tissue_masks/bGM.nii'];
        spm_write_vol(V,masksegm==1);
        V.fname = [dd filesep 'tissue_masks/cGM.nii'];
        spm_write_vol(V,masksegm==2);
        V.fname = [dd filesep 'tissue_masks/bWM.nii'];
        spm_write_vol(V,masksegm==3);
        V.fname = [dd filesep 'tissue_masks/cWM.nii'];
        spm_write_vol(V,masksegm==4);
        V.fname = [dd filesep 'tissue_masks/brainstem.nii'];
        spm_write_vol(V,masksegm==5);
        V.fname = [dd filesep 'tissue_masks/CSF.nii'];
        spm_write_vol(V,masksegm==6);
        V.fname = [dd filesep 'tissue_masks/spongiosa.nii'];
        spm_write_vol(V,masksegm==7);
        V.fname = [dd filesep 'tissue_masks/compacta.nii'];
        spm_write_vol(V,masksegm==8);
        V.fname = [dd filesep 'tissue_masks/muscle.nii'];
        spm_write_vol(V,masksegm==9);
        V.fname = [dd filesep 'tissue_masks/fat.nii'];
        spm_write_vol(V,masksegm==10);
        V.fname = [dd filesep 'tissue_masks/eyes.nii'];
        spm_write_vol(V,masksegm==11);
        V.fname = [dd filesep 'tissue_masks/skin.nii'];
        spm_write_vol(V,masksegm==12);
    end
   
    disp('::: MR-TIM :::   Head tissue segmentation done.')
    
elseif strcmpi(options_segment.segmentation_mode,'advanced')
    
    
    [~,segment]=max(datatot,[],4);
    
    
    %% applying the head mask
    
    [xx,yy,zz] = ndgrid(-5:5);
    nhood6 = sqrt(xx.^2 + yy.^2 + zz.^2) <= ceil(6/res);
    nhood5 = sqrt(xx.^2 + yy.^2 + zz.^2) <= ceil(5/res);
    nhood4 = sqrt(xx.^2 + yy.^2 + zz.^2) <= ceil(4/res);
    nhood3 = sqrt(xx.^2 + yy.^2 + zz.^2) <= ceil(3/res);
    nhood2 = sqrt(xx.^2 + yy.^2 + zz.^2) <= ceil(2/res);
    nhood1 = sqrt(xx.^2 + yy.^2 + zz.^2) <= ceil(1/res);
    
    mask=zeros(size(segment));
    mask(datat>0.001*max(datat(:)))=1;
    mask=imdilate(mask,nhood5);
    mask=imfill(mask,'holes');
    for i=1:size(mask,3)
        mask(:,:,i)=imfill(mask(:,:,i),'holes');
    end
    mask=imerode(mask,nhood5);
    mask = smooth3(mask,'box',5);
    mask(mask<0.5)=0;
    mask(mask>=0.5)=1;
    mask=imerode(mask,nhood2);   % added by DM
    
    
    
    % Vt.fname=[dd filesep ff '_t1' ext];
    % Vt.dt=[4 0];
    % spm_write_vol(Vt,mask);
    
    
    segment(mask==0)=0;
    segment(segment==ntissues)=ntissues-1;
    
    switch ntissues
        
        case 4
            
            im1=zeros(size(segment));
            im1(segment==1)=1;
            im1=imfill(im1,'holes');
            for i=5
                %im1=medfilt3(im1,[7 7 7]);
                im1 = smooth3(im1,'box',7);
                im1(im1<0.5)=0;
                im1(im1>=0.5)=1;
            end
            
            im2=zeros(size(segment));
            im2(segment==2)=1;
            im2=imfill(im2,'holes');
            for i=5
                %im2=medfilt3(im2,[7 7 7]);
                im2 = smooth3(im2,'box',7);
                im2(im2<0.5)=0;
                im2(im2>=0.5)=1;
            end
            im2b=imdilate(im1,nhood4);
            im2b=imdilate(im2b,nhood4);
            im2(im2b==1)=1;
            im2(im1==1)=0;
            
            im3=mask;
            im3(im1==1)=0;
            im3(im2==1)=0;
            
            segment(im1==1)=1;
            segment(im2==1)=2;
            segment(im3==1)=3;
            
            
        case 6
            
            
            mask=imerode(mask,nhood1);   % added by DM
            mask_full=mask;
            
            [fx,fy,fz] = gradient(mask_full);
            
            border=zeros(size(mask_full));
            
            border(abs(fx)+abs(fy)+abs(fz)>0)=1;
            
            
            %     Vt.fname=['tmp.nii'];
            %     Vt.dt=[4 0];
            %     Vt.pinfo=[1;  0; 0];
            %     Vt.n=[1 1];
            %     spm_write_vol(Vt,border);
            
            
            vos=squeeze(sum(sum(border,1),2));
            
            xx=find(vos>0);
            
            
            [val,pos]=max(vos(xx(1:ceil(length(xx)/10))));
            
            yy=find(vos(xx(pos+1:pos+ceil(length(xx)/20)))<median(vos(xx)));
            
            outlier=[1:xx(pos+min(yy))];
            
            % outlier = net_tukey(vos,3);
            %
            % outlier=outlier(vos(outlier)>mean(vos));
            
            border(:,:,outlier)=0;
            
            cc=bwconncomp(border);
            
            nx=zeros(1,cc.NumObjects);
            for i=1:cc.NumObjects
                nx(i)=length(cc.PixelIdxList{i});
            end
            [~,pos]=max(nx);
            
            border=zeros(size(segment));
            border(cc.PixelIdxList{pos})=1;
            
            border=imdilate(border,nhood1);
            
            %segment(segment==ntissues)=0;
            %segment(border==1)=ntissues;
            
            mask_full(border==1)=1;
            mask(border==1)=1;
            
            
            
            % Vt.fname=[dd filesep ff '_t1' ext];
            % Vt.dt=[4 0];
            % spm_write_vol(Vt,border);
            
            segment=zeros(size(mask));
            
            %% correcting GM and WM
            
            thres2=0.4;
            
            im1=zeros(size(segment));
            im1(datatot(:,:,:,1)>thres2)=1;
            cc=bwconncomp(im1);
            nx=zeros(1,cc.NumObjects);
            for i=1:cc.NumObjects
                nx(i)=length(cc.PixelIdxList{i});
            end
            [~,pos]=max(nx);
            im1=zeros(size(segment));
            im1(cc.PixelIdxList{pos})=1;
            
            im2=zeros(size(segment));
            im2(datatot(:,:,:,2)>thres2)=1;
            cc=bwconncomp(im2);
            nx=zeros(1,cc.NumObjects);
            for i=1:cc.NumObjects
                nx(i)=length(cc.PixelIdxList{i});
            end
            [~,pos]=max(nx);
            im2=zeros(size(segment));
            im2(cc.PixelIdxList{pos})=1;
            
            
            
            segment(im2==1)=2; % update WM
            
            segment(im1==1)=1; % update GM
            
            mask2=zeros(size(segment));
            mask2(segment>0)=1;
            mask2=imfill(mask2,'holes');
            
            datax=datatot(:,:,:,1:2);
            
            for i=1:2
                data=zeros(size(segment));
                data(segment==i)=1;
                datax(:,:,:,i)=smooth3(data,'gaussian',[5 5 5]);
            end
            
            datax(:,:,:,3)=0.0001*ones(size(segment));
            
            [~,ss]=max(datax,[],4);
            ss(ss==3)=0;
            
            segment(mask2==1)=ss(mask2==1);
            
            %     Vt.fname=[dd filesep ff '_t1' ext];
            %     Vt.dt=[4 0];
            %     spm_write_vol(Vt,segment);
            
            
            %% correcting CSF
            
            thres3=0.3;
            
            im12=zeros(size(segment));
            im12(segment>=1 & segment<=2)=1;
            
            im12=imfill(im12,'holes');
            
            min_cluster=1000;
            nvox=round(min_cluster/res.^3);
            im12 = bwareaopen(im12,nvox);
            
            im12dr=imdilate(im12,nhood2);
            
            im12dr = smooth3(im12dr,'box',7);
            im12dr(im12dr<0.5)=0;
            im12dr(im12dr>=0.5)=1;
            
            
            im12dr(im12==1)=0;
            
            im12dr = bwareaopen(im12dr,nvox);
            
            im3=zeros(size(segment));
            im3(datatot(:,:,:,3)>thres3)=1;
            
            im3(im12dr==1)=1;
            
            cc=bwconncomp(im3);
            nx=zeros(1,cc.NumObjects);
            for i=1:cc.NumObjects
                nx(i)=length(cc.PixelIdxList{i});
            end
            [~,pos]=max(nx);
            im3=zeros(size(segment));
            im3(cc.PixelIdxList{pos})=1;
            
            %im6 = bwareaopen(im6,nvox);
            
            segment(im3==1)=3; % update CSF
            
            %     Vt.fname=[dd filesep ff '_t3' ext];
            %     spm_write_vol(Vt,segment);
            
            %% correcting compacta and spongiosa
            
            thres=0.05;
            
            im4=zeros(size(datat,1),size(datat,2),size(datat,3));
            
            im4(datatot(:,:,:,4)>thres)=1;
            
            im4(segment>=1 & segment<=3)=0;
            
            im4 = bwareaopen(im4,nvox);
            
            im4=imdilate(im4,nhood4);
            im4=imdilate(im4,nhood4);
            im4=imdilate(im4,nhood4);
            
            im4=imerode(im4,nhood4);
            im4=imerode(im4,nhood4);
            im4=imerode(im4,nhood4);
            im4=imerode(im4,nhood2); %DM
            
            
            im3b=imfill(im3,'holes');
            
            im3c = smooth3(im3b,'box',9);
            im3c(im3c<0.5)=0;
            im3c(im3c>=0.5)=1;
            
            im3d=imdilate(im3c,nhood3);
            
            im3d(im3c==1)=0;
            
            im4(im3d==1)=1;
            
            
            
            im4b=imerode(im4,nhood3);
            
            im4b=imdilate(im4b,nhood3);
            
            im4c=im4-im4b;
            
            im4c = bwareaopen(im4c,round(100/res^3));
            
            im4c=imdilate(im4c,nhood2);
            
            im4(im4c==1)=1;
            
            
            im4 = smooth3(im4,'box',5);
            im4(im4<0.5)=0;
            im4(im4>=0.5)=1;
            
            im4(im3==1)=0;
            
            cc=bwconncomp(im4);
            
            nx=zeros(1,cc.NumObjects);
            for i=1:cc.NumObjects
                nx(i)=length(cc.PixelIdxList{i});
            end
            [~,pos]=max(nx);
            
            im4=zeros(size(segment));
            im4(cc.PixelIdxList{pos})=1;
            
            
            im4(im3==1)=0;
            im4(im2==1)=0;
            im4(im1==1)=0;
            
            
            segment(im4==1)=4; % update skull
            
            
            %         Vt.fname=[dd filesep ff '_t4' ext];
            %         spm_write_vol(Vt,segment);
            
            
            %% correcting soft tissues
            
            
            thres2=0.5;
            
            im5=zeros(size(segment));
            im5(datatot(:,:,:,5)>thres2)=1;
            
            im5=imdilate(im5,nhood4);
            im5 = smooth3(im5,'box',5);
            im5(im5<0.5)=0;
            im5(im5>=0.5)=1;
            im5=imdilate(im5,nhood4);
            im5 = smooth3(im5,'box',5);
            im5(im5<0.5)=0;
            im5(im5>=0.5)=1;
            
            
            im5=imerode(im5,nhood4);
            im5=imerode(im5,nhood2);
            im5=imerode(im5,nhood2);
            
            im5(im1==1)=0;
            im5(im2==1)=0;
            im5(im3==1)=0;
            im5(im4==1)=0;
            
            cc=bwconncomp(im5);
            
            nx=zeros(1,cc.NumObjects);
            for i=1:cc.NumObjects
                nx(i)=length(cc.PixelIdxList{i});
            end
            [~,pos]=max(nx);
            
            im5=zeros(size(segment));
            im5(cc.PixelIdxList{pos})=1;
            
            segment(im5==1)=5;  % update soft tissues
            segment(segment==0 & mask_full==1)=5;
            
            
            %         Vt.fname=[dd filesep ff '_t5' ext];
            %         spm_write_vol(Vt,segment);
            
            
            
            
            %% overlay skin
            
            
            segment(border==1)=6;  % update skin
            segment(mask_full==0)=0;
            
            
            %         Vt.fname=[dd filesep ff '_t6' ext];
            %         spm_write_vol(Vt,segment);
            
            
            
        case 12
            
            mask=imerode(mask,nhood1);   % added by DM
            mask_full=mask;
            
            [fx,fy,fz] = gradient(mask_full);
            
            border=zeros(size(mask_full));
            
            border(abs(fx)+abs(fy)+abs(fz)>0)=1;
            
            
            %     Vt.fname=['tmp.nii'];
            %     Vt.dt=[4 0];
            %     Vt.pinfo=[1;  0; 0];
            %     Vt.n=[1 1];
            %     spm_write_vol(Vt,border);
            
            
            vos=squeeze(sum(sum(border,1),2));
            
            xx=find(vos>0);
            
            
            [val,pos]=max(vos(xx(1:ceil(length(xx)/10))));
            
            yy=find(vos(xx(pos+1:pos+ceil(length(xx)/20)))<median(vos(xx)));
            
            outlier=[1:xx(pos+min(yy))];
            
            % outlier = net_tukey(vos,3);
            %
            % outlier=outlier(vos(outlier)>mean(vos));
            
            border(:,:,outlier)=0;
            
            cc=bwconncomp(border);
            
            nx=zeros(1,cc.NumObjects);
            for i=1:cc.NumObjects
                nx(i)=length(cc.PixelIdxList{i});
            end
            [~,pos]=max(nx);
            
            border=zeros(size(segment));
            border(cc.PixelIdxList{pos})=1;
            
            border=imdilate(border,nhood1);
            
            %segment(segment==ntissues)=0;
            %segment(border==1)=ntissues;
            
            mask_full(border==1)=1;
            mask(border==1)=1;
            
            
            
            % Vt.fname=[dd filesep ff '_t1' ext];
            % Vt.dt=[4 0];
            % spm_write_vol(Vt,border);
            
            
            segment=zeros(size(mask));
            
            %% correcting GM and WM
            
            thres2=0.4;
            
            im1=zeros(size(segment));
            im1(datatot(:,:,:,1)>thres2)=1;
            cc=bwconncomp(im1);
            nx=zeros(1,cc.NumObjects);
            for i=1:cc.NumObjects
                nx(i)=length(cc.PixelIdxList{i});
            end
            [~,pos]=max(nx);
            im1=zeros(size(segment));
            im1(cc.PixelIdxList{pos})=1;
            
            im2=zeros(size(segment));
            im2(datatot(:,:,:,2)>thres2)=1;
            cc=bwconncomp(im2);
            nx=zeros(1,cc.NumObjects);
            for i=1:cc.NumObjects
                nx(i)=length(cc.PixelIdxList{i});
            end
            [~,pos]=max(nx);
            im2=zeros(size(segment));
            im2(cc.PixelIdxList{pos})=1;
            
            im3=zeros(size(segment));
            im3(datatot(:,:,:,3)>thres2)=1;
            cc=bwconncomp(im3);
            nx=zeros(1,cc.NumObjects);
            for i=1:cc.NumObjects
                nx(i)=length(cc.PixelIdxList{i});
            end
            [~,pos]=max(nx);
            im3=zeros(size(segment));
            im3(cc.PixelIdxList{pos})=1;
            
            im4=zeros(size(segment));
            im4(datatot(:,:,:,4)>thres2)=1;
            cc=bwconncomp(im4);
            nx=zeros(1,cc.NumObjects);
            for i=1:cc.NumObjects
                nx(i)=length(cc.PixelIdxList{i});
            end
            [~,pos]=max(nx);
            im4=zeros(size(segment));
            im4(cc.PixelIdxList{pos})=1;
            
            im5=zeros(size(segment));
            im5(datatot(:,:,:,5)>thres2)=1;
            cc=bwconncomp(im5);
            nx=zeros(1,cc.NumObjects);
            for i=1:cc.NumObjects
                nx(i)=length(cc.PixelIdxList{i});
            end
            [~,pos]=max(nx);
            im5=zeros(size(segment));
            im5(cc.PixelIdxList{pos})=1;
            
            
            
            
            segment(im5==1)=5; % update brainstem
            
            segment(im4==1)=4; % update cWM
            
            segment(im3==1)=3; % update bWM
            
            segment(im2==1)=2; % update cGM
            
            segment(im1==1)=1; % update bGM
            
            mask2=zeros(size(segment));
            mask2(segment>0)=1;
            %     mask2=imfill(mask2,'holes');  % commented Gaia 10.07.19
            
            datax=datatot(:,:,:,1:5);
            
            for i=1:5
                data=zeros(size(segment));
                data(segment==i)=1;
                datax(:,:,:,i)=smooth3(data,'gaussian',[5 5 5]);
            end
            
            datax(:,:,:,6)=0.0001*ones(size(segment));
            
            [~,ss]=max(datax,[],4);
            ss(ss==6)=0;
            
            segment(mask2==1)=ss(mask2==1);
            
            %     Vt.fname=[dd filesep ff '_t1' ext];
            %     Vt.dt=[4 0];
            %     spm_write_vol(Vt,segment);
            
            
            %% correcting CSF    % Gaia 10.07.19
            
            thres3=0.3;
            
            im12345=zeros(size(segment));
            im12345(segment>=1 & segment<=5)=1;
            
            %     im12345=imfill(im12345,'holes');
            
            min_cluster=1000;
            nvox=round(min_cluster/res.^3);
            im12345 = bwareaopen(im12345,nvox);
            
            im12345dr=imdilate(im12345,nhood2);
            
            %    im12345dr=medfilt3(im12345dr,[7 7 7]);
            im12345dr = smooth3(im12345dr,'box',7);
            im12345dr(im12345dr<0.5)=0;
            im12345dr(im12345dr>=0.5)=1;
            
            im12345dr=imfill(im12345dr,'holes'); %%%
            im12345dr(im12345==1)=0;
            
            im12345dr = bwareaopen(im12345dr,nvox);
            
            im6=zeros(size(segment));
            im6(datatot(:,:,:,6)>thres3)=1;
            
            im6(im12345dr==1)=1;
            
            cc=bwconncomp(im6);
            nx=zeros(1,cc.NumObjects);
            for i=1:cc.NumObjects
                nx(i)=length(cc.PixelIdxList{i});
            end
            [~,pos]=max(nx);
            im6=zeros(size(segment));
            im6(cc.PixelIdxList{pos})=1;
            
            nx(pos)=0;
            [~,pos]=max(nx);
            im6(cc.PixelIdxList{pos})=1;
            
            %im6 = bwareaopen(im6,nvox);
            
            segment(im6==1)=6; % update CSF
            
            %     Vt.fname=[dd filesep ff '_t6' ext];
            %     spm_write_vol(Vt,segment);
            
            
            %% correcting CSF old
            %
            %     thres3=0.3;
            %
            %     im12345=zeros(size(segment));
            %     im12345(segment>=1 & segment<=5)=1;
            %
            %     im12345=imfill(im12345,'holes');
            %
            %     min_cluster=1000;
            %     nvox=round(min_cluster/res.^3);
            %     im12345 = bwareaopen(im12345,nvox);
            %
            %     im12345dr=imdilate(im12345,nhood2);
            %
            % %    im12345dr=medfilt3(im12345dr,[7 7 7]);
            %      im12345dr = smooth3(im12345dr,'box',7);
            %      im12345dr(im12345dr<0.5)=0;
            %      im12345dr(im12345dr>=0.5)=1;
            %
            %
            %     im12345dr(im12345==1)=0;
            %
            %     im12345dr = bwareaopen(im12345dr,nvox);
            %
            %     im6=zeros(size(segment));
            %     im6(datatot(:,:,:,6)>thres3)=1;
            %
            %     im6(im12345dr==1)=1;
            %
            %     cc=bwconncomp(im6);
            %     nx=zeros(1,cc.NumObjects);
            %     for i=1:cc.NumObjects
            %         nx(i)=length(cc.PixelIdxList{i});
            %     end
            %     [~,pos]=max(nx);
            %     im6=zeros(size(segment));
            %     im6(cc.PixelIdxList{pos})=1;
            %
            %     %im6 = bwareaopen(im6,nvox);
            %
            %     segment(im6==1)=6; % update CSF
            %
            % %     Vt.fname=[dd filesep ff '_t6' ext];
            % %     spm_write_vol(Vt,segment);
            
            %% correcting compacta and spongiosa
            
            thres=0.05;
            
            im78=zeros(size(datat,1),size(datat,2),size(datat,3));
            
            im78(datatot(:,:,:,7)+datatot(:,:,:,8)>thres)=1;
            
            im78(segment>=1 & segment<=6)=0;
            
            im78 = bwareaopen(im78,nvox);
            
            im78=imdilate(im78,nhood4);
            im78=imdilate(im78,nhood4);
            im78=imdilate(im78,nhood4);
            
            im78=imerode(im78,nhood4);
            im78=imerode(im78,nhood4);
            im78=imerode(im78,nhood4);
            im78=imerode(im78,nhood2); %DM
            
            
            im6b=imfill(im6,'holes');
            
            %im6c=medfilt3(im6b,[9 9 9]);
            im6c = smooth3(im6b,'box',9);
            im6c(im6c<0.5)=0;
            im6c(im6c>=0.5)=1;
            
            im6d=imdilate(im6c,nhood3);
            
            im6d(im6c==1)=0;
            
            im78(im6d==1)=1;
            
            
            
            im78b=imerode(im78,nhood3);
            
            im78b=imdilate(im78b,nhood3);
            
            im78c=im78-im78b;
            
            im78c = bwareaopen(im78c,round(100/res^3));
            
            im78c=imdilate(im78c,nhood2);
            
            im78(im78c==1)=1;
            
            
            %im78=medfilt3(im78,[5 5 5]);
            im78 = smooth3(im78,'box',5);
            im78(im78<0.5)=0;
            im78(im78>=0.5)=1;
            
            im78(im6==1)=0;
            
            cc=bwconncomp(im78);
            
            nx=zeros(1,cc.NumObjects);
            for i=1:cc.NumObjects
                nx(i)=length(cc.PixelIdxList{i});
            end
            [~,pos]=max(nx);
            
            im78=zeros(size(segment));
            im78(cc.PixelIdxList{pos})=1;
            
            
            %     Vt.fname=[dd filesep ff '_t78' ext];
            %     spm_write_vol(Vt,im78);
            
            
            
            im7=zeros(size(im78));
            im7(datatot(:,:,:,7)>thres)=1;
            
            im7=imdilate(im7,nhood4);
            im7=imdilate(im7,nhood4);
            
            im7=imerode(im7,nhood4);
            %  im7=imerode(im7,strel('sphere',round(4/res)));
            
            
            im78d=imerode(im78,nhood2);
            im7=im7.*im78d;
            
            im7=imdilate(im7,nhood4);
            im7=imdilate(im7,nhood4);
            %im7=medfilt3(im7,[11 11 11]);
            im7 = smooth3(im7,'box',11);
            im7(im7<0.5)=0;
            im7(im7>=0.5)=1;
            im7=imerode(im7,nhood4);
            im7=imerode(im7,nhood4);
            
            
            
            im7b=imerode(im7,nhood3);
            
            im7b=imdilate(im7b,nhood3);
            
            im7c=im7-im7b;
            
            
            
            im7d=imdilate(im7c,nhood2);
            
            im7(im7d==1)=1;
            
            im7=imerode(im7,nhood3); %DM
            
            im7 = bwareaopen(im7,round(100/res^3));
            
            im7=imdilate(im7,nhood4);
            im7=imdilate(im7,nhood4);
            im7=imerode(im7,nhood4);
            im7=imerode(im7,nhood4);
            
            
            
            
            cc=bwconncomp(im7);
            
            nx=zeros(1,cc.NumObjects);
            for i=1:cc.NumObjects
                nx(i)=length(cc.PixelIdxList{i});
            end
            [~,pos]=max(nx);
            
            im7=zeros(size(segment));
            im7(cc.PixelIdxList{pos})=1;
            
            im7(im1==1)=0;
            im7(im2==1)=0;
            im7(im3==1)=0;
            im7(im4==1)=0;
            im7(im5==1)=0;
            im7(im6==1)=0;
            
            
            segment(im7==1)=7; % update spongiosa
            
            %      Vt.fname=[dd filesep ff '_t7' ext];
            %      spm_write_vol(Vt,im7);
            
            im78x=imdilate(im7,nhood2);
            im78(im78x==1)=1;
            
            im8=im78;
            
            im8(im7==1)=0;
            
            im8(im1==1)=0;
            im8(im2==1)=0;
            im8(im3==1)=0;
            im8(im4==1)=0;
            im8(im5==1)=0;
            im8(im6==1)=0;
            
            segment(im8==1)=8; % update compacta
            
            %         Vt.fname=[dd filesep ff '_t8' ext];
            %         spm_write_vol(Vt,im8);
            
            
            %% correcting muscle and fat
            
            
            thres=0.05;
            thres2=0.5;
            
            im9=zeros(size(segment));
            im9(datatot(:,:,:,9)>thres2)=1;
            
            im9=imdilate(im9,nhood4);
            %im9=medfilt3(im9,[5 5 5]);
            im9 = smooth3(im9,'box',5);
            im9(im9<0.5)=0;
            im9(im9>=0.5)=1;
            im9=imdilate(im9,nhood4);
            %im9=medfilt3(im9,[5 5 5]);
            im9 = smooth3(im9,'box',5);
            im9(im9<0.5)=0;
            im9(im9>=0.5)=1;
            
            
            im9=imerode(im9,nhood4);
            im9=imerode(im9,nhood2);
            im9=imerode(im9,nhood2);
            
            im9(im1==1)=0;
            im9(im2==1)=0;
            im9(im3==1)=0;
            im9(im4==1)=0;
            im9(im5==1)=0;
            im9(im6==1)=0;
            im9(im7==1)=0;
            im9(im8==1)=0;
            
            cc=bwconncomp(im9);
            
            nx=zeros(1,cc.NumObjects);
            for i=1:cc.NumObjects
                nx(i)=length(cc.PixelIdxList{i});
            end
            [~,pos]=max(nx);
            
            im9=zeros(size(segment));
            im9(cc.PixelIdxList{pos})=1;
            
            segment(im9==1)=9;  % update muscle
            
            %
            %         Vt.fname=[dd filesep ff '_t9' ext];
            %         spm_write_vol(Vt,im9);
            
            
            
            im12d=imdilate(border,nhood2);
            im12d(mask_full==0)=0;
            im12d(border==1)=0;
            
            im10=zeros(size(segment));
            im10(datatot(:,:,:,10)>thres)=1;
            
            im10(mask_full==0)=0;
            im10(border==1)=0;
            im10(im9==1)=0;
            im10(im12d==1)=1;
            
            im10(im6==1)=0;
            im10(im7==1)=0;
            im10(im8==1)=0;
            
            im10(im1==1)=0;
            im10(im2==1)=0;
            im10(im3==1)=0;
            im10(im4==1)=0;
            im10(im5==1)=0;
            
            im10 = bwareaopen(im10,round(100/res^3));
            
            %  im10=medfilt3(im10,[3 3 3]);
            
            segment(im10==1)=10;  % update fat
            segment(segment==0 & mask_full==1)=10;
            
            
            %     Vt.fname=[dd filesep ff '_t10' ext];
            %     spm_write_vol(Vt,im10);
            
            
            
            %% correcting eyes
            
            
            thres4=0.8;
            
            im11=zeros(size(segment));
            im11(datatot(:,:,:,11)>thres4)=1;
            
            im11 = bwareaopen(im11,round(1000/res^3));
            
            %im11=medfilt3(im11,[7 7 7]);
            im11 = smooth3(im11,'box',7);
            im11(im11<0.5)=0;
            im11(im11>=0.5)=1;
            im11=imdilate(im11,nhood2);
            
            
            im11(im1==1)=0;
            im11(im2==1)=0;
            im11(im3==1)=0;
            im11(im4==1)=0;
            im11(im5==1)=0;
            im11(im6==1)=0;
            im11(im7==1)=0;
            im11(im8==1)=0;
            
            %     Vt.fname=[dd filesep ff '_t11' ext];
            %     spm_write_vol(Vt,im11);
            
            segment(im11==1)=11;  % update eyes
            
            %% overlay skin
            
            segment(border==1)=12;  % update skin
            segment(mask_full==0)=0;
            
            
            
    end
    
    %% filling gaps
    
    %    Vt.fname=[dd filesep ff '_t10' ext];
    %    spm_write_vol(Vt,segment);
    
    min_cluster=1000;
    nvox=round(min_cluster/res.^3);
    
    
    for kk=1:ntissues
        img=zeros(size(mask));
        img(segment==kk)=1;
        cc=bwconncomp(img,18);
        for zz=1:cc.NumObjects
            if length(cc.PixelIdxList{zz})<nvox
                segment(cc.PixelIdxList{zz})=0;
            end
        end
    end
    
    
    
    datax=zeros(size(datatot));
    for i=1:ntissues
        data=zeros(size(segment));
        data(segment==i)=1;
        datax(:,:,:,i)=smooth3(data,'gaussian',[5 5 5]);
    end
    
    datax(:,:,:,ntissues+1)=0.0001*ones(size(segment));
    
    [~,ss]=max(datax,[],4);
    ss(ss==ntissues+1)=0;
    %ss(im0==1)=0;
    
    %segment(ss>0 & segment==0)=ss(ss>0 & segment==0);
    
    segment(mask==1 & segment==0)=ss(mask==1 & segment==0);
    
    
    % segment(border==1)=ntissues;
    % segment(mask==0)=0;
    %segment(mask==1 & segment==0)=10;
    
    
    mask_new=zeros(size(segment));
    
    mask_new(segment==0)=1;
    mask_new(mask==0)=0;
    
    
    cc=bwconncomp(mask_new);
    
    %     num_vox=zeros(1,cc.NumObjects);
    %     for zz=1:cc.NumObjects
    %
    %         num_vox(zz)= length(cc.PixelIdxList{zz});
    %
    %     end
    
    %[~,pos]= max(num_vox);
    %for zz=[1:pos-1 pos+1:cc.NumObjects]
    for zz=1:cc.NumObjects
        %if num_vox(zz)<=nvox
        img_cluster=zeros(size(segment));
        img_cluster(cc.PixelIdxList{zz})=1;
        [fx,fy,fz] = gradient(img_cluster);
        vv=segment(abs(fx)+abs(fy)+abs(fz)>0);
        vv(vv==0)=[];
        %segment(cc.PixelIdxList{zz})=mode(vv);
        if not(isempty(vv))
            segment(cc.PixelIdxList{zz})=min(vv);
        end
        %end
    end
    
    
    
    %% saving the results in an image
    
    Vt.fname=[dd filesep ff '_segment' ext];
    
    Vt.dt=[4 0];
    
    Vt.pinfo=[1;  0; 0];
    
    Vt.n=[1 1];
    
    spm_write_vol(Vt,segment);
    
    
else
    %{
    clear matlabbatch
    
    [bb_i,vox_i]=net_world_bb(img_filename);
    
    matlabbatch{1}.spm.util.defs.comp{1}.def = {deformation_file};
    matlabbatch{1}.spm.util.defs.out{1}.push.fnames = {segtemplate_image};
    matlabbatch{1}.spm.util.defs.out{1}.push.weight = {''};
    matlabbatch{1}.spm.util.defs.out{1}.push.savedir.saveusr = {dd};
    matlabbatch{1}.spm.util.defs.out{1}.push.fov.bbvox.bb = bb_i;
    matlabbatch{1}.spm.util.defs.out{1}.push.fov.bbvox.vox = vox_i;
    matlabbatch{1}.spm.util.defs.out{1}.push.preserve = 0;
    matlabbatch{1}.spm.util.defs.out{1}.push.fwhm = 0;
    matlabbatch{1}.spm.util.defs.out{1}.push.prefix = 'w';
    
    
    spm_jobman('run',matlabbatch);
    
    
    
    movefile(segindiv_image,[dd filesep ff '_segment.nii']);
    %}
    
    % Version NET 2.16
    clear matlabbatch
    
    matlabbatch{1}.spm.util.defs.comp{1}.def = {deformation_file};
    matlabbatch{1}.spm.util.defs.out{1}.pull.fnames = {segtemplate_image};
    matlabbatch{1}.spm.util.defs.out{1}.pull.savedir.saveusr = {dd};
    matlabbatch{1}.spm.util.defs.out{1}.pull.interp = 0;
    matlabbatch{1}.spm.util.defs.out{1}.pull.mask = 1;
    matlabbatch{1}.spm.util.defs.out{1}.pull.fwhm = [0 0 0];
    matlabbatch{1}.spm.util.defs.out{1}.pull.prefix = 'w';
    
    spm_jobman('run',matlabbatch);
    
    movefile(segindiv_image,[dd filesep ff '_segment.nii']);
    
end


