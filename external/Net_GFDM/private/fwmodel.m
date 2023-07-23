% fwmodel.m
% Ernesto Cuartas M (ECM), 24/04/2017
% Email:  ecuartasmo@unal.edu.co

function fwmodel(fwriteid, i, j, k, T, C1, C2, C3, C4, C5, C6)

fwrite(fwriteid, i-1, 'double', 'n');
fwrite(fwriteid, j-1, 'double', 'n');
fwrite(fwriteid, k-1, 'double', 'n');
fwrite(fwriteid, T, 'double', 'n');
fwrite(fwriteid, C1, 'double', 'n');
fwrite(fwriteid, C2, 'double', 'n');
fwrite(fwriteid, C3, 'double', 'n');
fwrite(fwriteid, C4, 'double', 'n');
fwrite(fwriteid, C5, 'double', 'n');
fwrite(fwriteid, C6, 'double', 'n');
