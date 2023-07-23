function [data,compress] = fns_read_transfer(datafile)

% This function reads the reciprocity data and the related
% information into the MATLAB workspace.
% last revised by QL, 15.01.2015


%% Read in the reciprocity data
hinfo = hdf5info(datafile);

nchan=length(hinfo.GroupHierarchy.Groups(3).Datasets);  % '/recipdata/sol-00i'


vect = hdf5read(datafile, hinfo.GroupHierarchy.Groups(3).Datasets(1).Name);
nvox=length(vect);
data=zeros(nvox,nchan);
data(:,1)=vect;
for i=2:nchan
    vect = hdf5read(datafile, hinfo.GroupHierarchy.Groups(3).Datasets(i).Name);
    data(:,i)=vect;
end

%% Read in other parameters
compress = hdf5read(datafile,'/sparse/compress') + 1;
% gridlocs = hdf5read(infile,'/recipdata/gridlocs');
% node_sizes = hdf5read(infile,'/model/node_sizes');
% voxel_sizes = hdf5read(infile,'/model/voxel_sizes');
    
%% EOF