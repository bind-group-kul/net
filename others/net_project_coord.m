function coord=net_project_coord(deform_file,coord_mni)

nseeds=size(coord_mni,1);

Vx=spm_vol([deform_file ',1,1']);
Vy=spm_vol([deform_file ',1,2']);
Vz=spm_vol([deform_file ',1,3']);
[datax,xyz]=spm_read_vols(Vx);
[datay,xyz]=spm_read_vols(Vy);
[dataz,xyz]=spm_read_vols(Vz);
datax=datax(:);
datay=datay(:);
dataz=dataz(:);

coord=zeros(size(coord_mni));

for i=1:nseeds
    
    pos=coord_mni(i,:)';
    
    dist=sum((xyz-pos*ones(1,size(xyz,2))).^2);
    
    [val,pos]=min(dist);
    
    coord(i,:)=[datax(pos) datay(pos) dataz(pos)];
    
end