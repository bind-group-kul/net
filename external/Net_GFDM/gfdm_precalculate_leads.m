% gfdm_precalculate_leads.m
% Ernesto Cuartas M (ECM), 24/04/2017
% Updated: 02/06/2020
% Email: ecuartasm@gmail.com

function lead = gfdm_precalculate_leads( cfg )
% gfdm_precalculate_leads.m
% Ernesto Cuartas M (ECM), 24/04/2017
% Updated: 02/06/2020
% Email: ecuartasm@gmail.com
% 
% GFDM_PRECALCULATE_LEADS calculates lead-pair potentials for a given set of 
% electrode positions. The calculations are performed using the reciprocity 
% theorem for finite differences. This routine takes about 5 minutes per 
% lead-pair (par of electrodes), using the number of electrodes minus one 
% to complete the task. Each lead-pair is solved as a single linear system 
% using iLU factorization preconditioner and BiCG-Stabilized solver.Time 
% can be larger than 5 minutes if the stiff matrix contains anisotropic 
% conductivity values. Eg: for a set of 70 electrodes, 1mm^3 voxel size, 
% realistic head model, with +5million Non-zero voxels, this routine can 
% yield +6h of calculations. in addition, the amount of memory needed to 
% allocate the output is directly proportional to the amount of Non-zero 
% voxels. For the example mentioned the amount of memory used for the output 
% is +1.4Gb. Although it is possible to calculate the potentials just for 
% the GM area, or even for a given source distribution, drastically reducing 
% the amount of memory needed to allocate the output.
%
% INPUT: ( cfg ) The cfg argument is a structure containing:
%   cfg.vol            head model structure, output -> gfdm_prepare_headmodel
%   cfg.electrodes     electrodes structure, output -> gfdm_prepare_elecs
%   cfg.mri            structural aligned MRI
%   cfg.solver         a structure holding the linear solver paremeters
%       solver.tol     tolerance error;
%       solver.maxit   maximun number of iterations
%   cfg.gmask          a string that allows the reduction of the stored potentials 
%                      in the head volume. This parameter can be  'source', 'gm', or 'all'.
%                      'all' -> will return the potentials for the entire volume.
%                      'gm' -> will return the potentials just for the GM 
%                      tissue volume, allowing not only a high reduction of 
%                      the memory needed for the precalculated leal-pairs but 
%                      also to select any position/orientation for sources placed inside the GM.
%                      'source' -> will return the potentials needed for a grid 
%                      source distribution obtained using ft_prepare_sourcemodel. 
%                      Eg: grid = ft_prepare_sourcemodel(cfg)
%   cfg.grid           a structur containing a regular 3D source grid
%                      obtained using ft_prepare_sourcemodel. Just for
%                      gmask == 'source'.
%                      Eg: grid = ft_prepare_sourcemodel(cfg)
%
% OUTPUT: ( lead ) structure containing the precalculated lead-pairs
%   lead.vol           head model structure, output -> gfdm_prepare_headmodel
%   lead.electrodes    electrodes structure, output -> gfdm_prepare_elecs  
%   lead.mri           structural aligned MRI
%   lead.c_idx         3D array holding the Non-zero indexation
%   lead.solver        structur holding the performance parameters for the
%                      linear solver in every lead-pair
%        solver.tleads    vector containing the spend time for every lead-pair
%        solver.fla       vector containing the final flags for the BiCG-Stabilized solver
%        solver.rra       vector holding the final relative residual errors
%        solver.ita       vector holding the number of iterations needed to solve every lead-pair
%        solver.rva       cell array containing the relative error progression for every lead-pair
%   lead.indexes       sparse vector containing the Non-zero potentials indexes
%   lead.pots          sparce matrix (number of voxels x 3) holding the x,
%                      y and z potentials in the head volume
%
% EXAMPLE: example using already corregistered electrodes and aligned MRI
% data
%   cfg               = [];
%   cfg.vol           = vol;
%   cfg.elec          = elec_FDM;
%   cfg.mri           = mri_aligned;
%   cfg.solver.tol    = 1e-10;
%   cfg.solver.maxit  = 700;
%   cfg.gmask = 'gm';
%   lead = gfdm_precalculate_leads( cfg );


% source memory allocation space
if(strcmp(cfg.gmask, 'source'))    
    %%%%%%%%% FIX %%%%%%%%%%%%%%%%% vol.segmentation, no mri
    pos = cfg.grid.pos;
    ins = cfg.grid.inside;
    Tr  = cfg.mri.transform;
    
    [nonz val] = find(ins == 1);
    posi = pos(nonz,:);
%     posi = posi * 10; % to mm
    posmri = ft_warp_apply(Tr^(-1), posi); % transform to head coordinates
    
    cfg_gm = [];
    cfg_gm.source_loc = posmri;
    cfg_gm.c_idx = cfg.vol.c_idx;
    cfg_gm.NoNonZeros = cfg.vol.Nz;
    gm_zM = FindSourceReciprocitySpace( cfg_gm );
    
elseif(strcmp(cfg.gmask, 'gm'))
    gm_idx = cfg.vol.gm_idx;
    Seg = cfg.vol.box.anatomy;
    
    Msk = cell(size(gm_idx));
    for a = 1:length(gm_idx)
        Msk{a} = (Seg == gm_idx(a));
    end
    gmvol = zeros(size(Seg));
    for a = 1:length(gm_idx)
        gmvol = gmvol | Msk{a};
    end

    cfg_gm = [];
    cfg_gm.c_idx = cfg.vol.c_idx;
    cfg_gm.gmvol = gmvol;
    cfg_gm.Nz    = cfg.vol.Nz;
    gm_zM        = FindGMReciprocitySpace( cfg_gm );
    
    clear Msk;    
%     clear gmvol;
else
    gm_zM  = ones(cfg.vol.Nz, 1);
end

elc = cfg.elec.elecpos;
lds = cfg.elec.leadp;

nele = length(cfg.elec.elecpos);
c_idx = cfg.vol.c_idx;

mA = cfg.vol.stiff;
% Building iLU decomposition for the solver
[iL,iU] = ilu(mA,struct('droptol',1e-15));

tol     = cfg.solver.tol;
maxit   = cfg.solver.maxit;
Cidx    = cfg.vol.Cidx;
Nz      = cfg.vol.Nz;
NoLeads = length(lds);

lead = [];
lead.vol    = cfg.vol;
lead.c_idx  = cfg.vol.c_idx;
lead.solver = cfg.solver;
lead.mri    = cfg.mri;
lead.gmask  = cfg.gmask;
lead.elec   = cfg.elec;

lead.indexes = sparse(Cidx);
lead.pots    = sparse(Nz,NoLeads);
lindx        = lead.indexes;

lead.solver.tleads = zeros(NoLeads,1);
lead.solver.fla = zeros(NoLeads,1);
lead.solver.rra = zeros(NoLeads,1);
lead.solver.ita = zeros(NoLeads,1);
lead.solver.rva = cell(NoLeads,1);

tott = 0;
for k = 1:NoLeads
    tic
    fprintf('Calculating LeadPair %d/%d\n', k, NoLeads);
    B = sparse(zeros(Nz,1));
    
    ld1 = lds(k,1);
    ld2 = lds(k,2);
    
    p1 = c_idx( elc(ld1,1), elc(ld1,2), elc(ld1,3) );
    p2 = c_idx( elc(ld2,1), elc(ld2,2), elc(ld2,3) );
    
    B(p1) = 1;
    B(p2) = -1;
    
    % Iterative non stacionary BiCG Stabilazed solver with iLU preconditioner
    [xa, fla, rra, ita, rva] = bicgstab(mA,B,tol,maxit, iL, iU);
    potk = xa .* gm_zM;

    lead.pots(:,k) = sparse(potk);
    
    tbicg = toc;
    tott = tott + tbicg;
    
    lead.solver.tleads(k) = tbicg;
    lead.solver.fla(k) = fla;
    lead.solver.rra(k) = rra;
    lead.solver.ita(k) = ita;
    lead.solver.rva{k} = rva;
    
    fprintf('LeadPair %d ready - time: %f  - lead: %d -> %d\n', k, tbicg, ld1, ld2);
    fprintf('Flag: %d   |   Relative residual: %e \n', fla, rra);
end

lead.solver.tott = tott;
fprintf('LeadField ready - Total time: %f\n', tott); 