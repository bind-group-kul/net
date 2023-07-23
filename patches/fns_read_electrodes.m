function electrodes = fns_read_electrodes(datafile)

% This function reads the electrodes and the related
% information into the MATLAB workspace.
% last revised by QL, 19.01.2016


electrodes.voxel_sizes  = hdf5read(datafile, '/region/voxel_sizes');
electrodes.info         = hdf5read(datafile, '/region/info');
electrodes.locations    = hdf5read(datafile, '/region/locations');
electrodes.gridlocs     = hdf5read(datafile, '/region/gridlocs');
electrodes.node_sizes   = hdf5read(datafile, '/region/node_sizes');
electrodes.status       = hdf5read(datafile, '/region/status');