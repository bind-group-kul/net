% W_modelE.m
% Ernesto Cuartas M (ECM), 24/04/2017
% Email:  ecuartasmo@unal.edu.co

function W_modelE(Par)

afdm_F = fopen(Par.fnameE,'w+');

for i=1:length(Par.Electrodes)
    fprintf(afdm_F,'%1.15f  %1.15f  %1.15f\n', Par.Electrodes(i,1)-1, Par.Electrodes(i,2)-1, Par.Electrodes(i,3)-1);    
end

for i=1:length(Par.Leads)
    fprintf(afdm_F,'%d  %d\n', Par.Leads(i,1), Par.Leads(i,2));    
end

fclose(afdm_F);