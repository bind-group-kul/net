% W_modelP.m
% Ernesto Cuartas M (ECM), 24/04/2017
% Email:  ecuartasmo@unal.edu.co

function W_modelP(Par)

afdm_F = fopen(Par.fnameP,'w+');

fprintf(afdm_F,'Size:\n');
fprintf(afdm_F,'%d  %d  %d\n', Par.Size(1), Par.Size(2), Par.Size(3));

fprintf(afdm_F,'VoxelSize:\n');
fprintf(afdm_F,'%1.15f  %1.15f  %1.15f\n', Par.VoxelSize(1), Par.VoxelSize(2), Par.VoxelSize(3));

fprintf(afdm_F,'NoElements:\n');
fprintf(afdm_F,'%d\n', Par.NoElements);

fprintf(afdm_F,'NoNonZeros:\n');
fprintf(afdm_F,'%d\n', Par.NoNonZeros);

fclose(afdm_F);