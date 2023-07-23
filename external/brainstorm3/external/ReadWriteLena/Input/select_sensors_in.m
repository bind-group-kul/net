function sample_sensors=select_sensors_in(sel_sensor, lenafile)

Supersensor_list = getSupersensor_list(lenafile); 

% mat_sel_sensor=reshape(sel_sensor,length(sel_sensor),1);
%  mat_Supersensor_list=reshape(Supersensor_list, length(Supersensor_list),1);
dim=size(Supersensor_list,2);
res=1;
if dim >1
    
for i=1: size(Supersensor_list,1)
    foundsensor=true;
    
     mat_sel_sensor=reshape(sel_sensor,length(sel_sensor),1);
         mat_Supersensor_list=reshape(Supersensor_list, length(Supersensor_list),dim);
    for j=1:size(Supersensor_list,2)
        
       
        foundsensor=false;
        for k=1:length(sel_sensor)
             s1=sel_sensor{k};
             s2=Supersensor_list{i,j};
            if  strcmp(s1,s2)
                foundsensor=true;
                
                    break;
            end
        end
        

        if ~foundsensor
            break;
        end
    end
    if foundsensor
         for i1=1:size(Supersensor_list,2)
         Superlist_sensors{res,i1}=Supersensor_list{i,i1};
         end
        Superlist_unit{res,:}=getSupersensor_unit(lenafile,i);
        Superlist_scale{res,:}=1;%getSupersensor_scale(lenafile,i);
        res=res+1;
    end
    
end
else  
    
    
    for i=1: length(Supersensor_list)
        mat_sel_sensor=reshape(sel_sensor,length(sel_sensor),1);
         mat_Supersensor_list=reshape(Supersensor_list, length(Supersensor_list),1);
        foundsensor=false;
        for k=1:length(sel_sensor)
             s1=sel_sensor{k};
             s2=Supersensor_list{i};
            if strcmp(s1,s2)
                foundsensor=true;
            end
        end
       
        if foundsensor
        Superlist_sensors{res,:}=Supersensor_list{i};
        Superlist_unit{res,:}=getSupersensor_unit(lenafile,i);
        Superlist_scale{res,:}=1;%getSupersensor_scale(lenafile,i);
        
        res=res+1;
        end
    
    end
end

dim=size(Superlist_sensors,2);
dim0=size(Superlist_sensors,1);
if dim>1
sample_sensors.list_sensors=reshape (Superlist_sensors,dim0,dim);

 
else
sample_sensors.list_sensors=reshape (Superlist_sensors,length(Superlist_sensors),1);
end
sample_sensors.unit=reshape (Superlist_unit,length(Superlist_unit),1);
sample_sensors.scale=reshape (Superlist_scale,length(Superlist_scale),1);


end