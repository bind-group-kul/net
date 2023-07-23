function vol = net_headmodel_fns(mri, varargin)

% FT_HEADMODEL_FNS creates the volume conduction structure to be used
% in the FNS forward solver.
%
% Use as
%   vol = ft_headmodel_fns(seg, ...)
%
% Optional input arguments should be specified in key-value pairs and
% can include
%   tissuecond       = matrix C [9XN tissue types]; where N is the number of
%                      tissues and a 3x3 tensor conductivity matrix is stored
%                      in each column.
%   tissue           = see fns_contable_write
%   tissueval        = match tissues of segmentation input
%   transform        = 4x4 transformation matrix (default eye(4))
%   units            = string (default 'cm')
%   sens             = sensor information (for which ft_datatype(sens,'sens')==1)
%   deepelec         = used in the case of deep voxel solution
%   tolerance        = scalar (default 1e-8)
%
% Standard default values for conductivity matrix C are derived from
% Saleheen HI, Ng KT. New finite difference formulations for general
% inhomogeneous anisotropic bioelectric problems. IEEE Trans Biomed Eng.
% 1997
%
% Additional documentation available at:
% http://hunghienvn.nmsu.edu/wiki/index.php/FNS
%
% See also FT_PREPARE_VOL_SENS, FT_COMPUTE_LEADFIELD

% Copyright (C) 2011, Cristiano Micheli and Hung Dang
%
% This file is part of FieldTrip, see http://www.ru.nl/neuroimaging/fieldtrip
% for the documentation and details.
%
%    FieldTrip is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    FieldTrip is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with FieldTrip. If not, see <http://www.gnu.org/licenses/>.
%
% $Id: ft_headmodel_fns.m 8918 2013-11-29 12:46:24Z roboos $

ft_hastoolbox('fns', 1);

% get the optional arguments
tissue       = ft_getopt(varargin, 'tissue', []);
tissueval    = ft_getopt(varargin, 'tissueval', []);
tissuecond   = ft_getopt(varargin, 'tissuecond', []);
sens         = ft_getopt(varargin, 'sens', []);
deepelec     = ft_getopt(varargin, 'deepelec', []); % used in the case of deep voxel solution
tolerance    = ft_getopt(varargin, 'tolerance', 1e-6);


if isempty(sens)
    error('A set of sensors is required')
end

if ispc
    error('FNS only works on Linux and OSX')
end

if any(strcmp(varargin(1:2:end), 'unit')) || any(strcmp(varargin(1:2:end), 'units'))
    % the geometrical units should be specified in the input geometry
    error('the ''unit'' option is not supported any more');
end

% check the consistency between tissue values and the segmentation
vecval = ismember(tissueval,unique(mri.seg(:)));
if any(vecval)==0
    warning('Some of the tissue values are not in the segmentation')
end

% create the files to be written
try
    %tmpfolder = pwd;
    %tmpfolder=tempdir;
    tmpfolder=[net('path') filesep 'others' filesep 'tmp' filesep 'fns'];
    if exist(tmpfolder)
        rmdir(tmpfolder,'s');
    end
    mkdir(tmpfolder);
    
    vdir=pwd;
    cd(tmpfolder);
    [tmp,tname] = fileparts(tempname);
    segfile   = [tname];
    [tmp,tname] = fileparts(tempname);
    confile   = [tname '.csv'];
    [tmp,tname] = fileparts(tempname);
    elecfile = [tname '.h5'];
    [tmp,tname] = fileparts(tempname);
    exefile   = [tname '.sh'];
    [tmp,tname] = fileparts(tempname);
    datafile  = [tname '.h5'];
    
    
    % this requires the fieldtrip/fileio toolbox
    ft_hastoolbox('fileio', 1);
    
    % write the segmentation on disk
    disp('writing the segmentation file...')
    data = uint8(mri.seg);
    V.fname = [segfile '.img'];
    V.dim = mri.dim;
    V.pinfo = [1 0 0]';
    V.dt = [4 0];
    V.mat = mri.transform;
    spm_write_vol(V,data);  % changed by QL, 21.11.2014
    
    %
    %     mri_temp = [];
    %     mri_temp.dim = size(mri.seg);
    %     mri_temp.transform = eye(4);
    %     mri_temp.seg = uint8(mri.seg);
    %     cfg = [];
    %     cfg.datatype = 'uint8';
    %     cfg.coordsys = 'spm';
    %     cfg.parameter = 'seg';
    %     cfg.filename = segfile;
    %     cfg.filetype = 'analyze';
    %     ft_volumewrite(cfg, mri_temp);  % default
    
    % write the cond matrix on disk, load the default cond matrix in case not specified
    disp('writing the conductivity file...')
    condmatrix = fns_contable_write('tissue',tissue,'tissueval',tissueval,'tissuecond',tissuecond);
    csvwrite(confile,condmatrix);
    
    % write the positions of the electrodes on disk
    %     disp('writing the electrodes file...')
    %     voxel_sizes = double([3 3 3]');  % double(1.0e-03*[3 3 3]);
    %     node_sizes = int32(mri.dim'+1);
    %     pos = ft_warp_apply(inv(mri.transform), sens.elecpos); % in voxel coordinates!
    %     fns_elec_write(int32(pos), voxel_sizes, node_sizes, elecfile)
    %     % convert pos into int32 datatype.
    %    % hdf5write(elecfile, 'region/gridlocs', int32(pos));   % changed by QL, 14.11.2014
    %    % fns_elec_write(int32(pos), [1 1 1], size(mri.seg), elecfile); % Hung: convert pos to int32 datatype.
    electrodes.info = 'Fitted electrodes';
    
    electrodes.node_sizes = int32(mri.dim'+1);  
    electrodes.voxel_sizes = double( 1.0e-02*abs([mri.transform(1,1) mri.transform(2,2) mri.transform(3,3)]) );  % in m: 0.0040
    
    pos = ft_warp_apply(inv(mri.transform), sens.elecpos); % in voxel coordinates!
    electrodes.locations = pos;
    electrodes.gridlocs = int32(round(pos));
    electrodes.values = zeros(size(pos,1),1);
    electrodes.status = ones(size(pos,1),1);
    
   fns_region_write(elecfile,electrodes);
   
    % Exe file
    efid = fopen(exefile, 'w');
    if ~ispc
        fprintf(efid,'#!/usr/bin/env bash\n');
        pp=net_getpath('fns');  % changed by QL
        % pp = 'Users/quanyingliu/Documents/ZET_updated/external/fieldtrip-20140921/external/fns';
        fprintf(efid,[pp filesep 'elecsfwd -img ' tmpfolder segfile ' -electrodes ' tmpfolder elecfile ' -data ', ...
            tmpfolder datafile ' -contable ' tmpfolder confile ' -TOL ' num2str(tolerance) ' \n']);%2>&1 > /dev/null
    end
    fclose(efid);
    
    % run the shell instructions
    system(sprintf('chmod +x %s', exefile));   % changed by DM
    system([tmpfolder filesep exefile]);   % changed by DM
    
    % FIXME: find a clever way to store the huge transfer matrix (vista?)
    % [transfer,status] = fns_read_transfer(['/private/tmp/' datafile]);
    [transfer, compress] = fns_read_transfer(datafile);
    transfer = transfer';
    
    cleaner(segfile,confile,elecfile,exefile,datafile);
    
catch ME
    disp('The transfer matrix was not written')
    cleaner(segfile,confile,elecfile,exefile,datafile)
    cd(tmpfolder)
    rethrow(ME)
end

% start with an empty volume conductor
vol = [];
vol.tissue     = tissue;
vol.tissueval  = tissueval;
vol.transform  = mri.transform;
vol.segdim     = size(mri.seg);
vol.dim =      size(mri.seg);
vol.units      = mri.unit;
vol.type       = 'fns';
vol.transfer   = transfer;
vol.compress = compress;  % added by QL, 15.01.2015

if ~isempty(deepelec)
    vol.deepelec  = deepelec;
end

cd(vdir);

function cleaner(segfile,confile,elecfile,exefile,datafile)
delete([segfile '.hdr']);
delete([segfile '.img']);
delete(confile);
delete(elecfile);
delete(exefile);
delete(datafile);
