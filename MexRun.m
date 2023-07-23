folder = 'C:\SoliD\KU\Net\NET_v2.20\external\smoothpatch_version1b\';
cd(folder);

mex smoothpatch_curvature_double.c
mex smoothpatch_inversedistance_double.c
mex vertex_neighbours_double.c
