function pots = gfdm_calculate_leadfield(lead, grid)
% gfdm_calculate_leadfield.m
% Ernesto Cuartas M (ECM), 24/04/2017
% Email:  ernesto.cuartas@kuleuven.be, ecuartasm@gmail.com
% 
% GFDM_CALCULATE_LEADFIELD calculates the leadfield matrix for a given grid-source 
% space and precalculated lead-pairs potentials (gfdm_precalculate_leads output)
% 
% INPUT: precalculated lead-pairs potentials structure (output -> gfdm_precalculate_leads)
%        volumetric source space from field trip (output -> ft_prepare_sourcemodel)
%   lead    output -> gfdm_precalculate_leads
%   grid    output -> ft_prepare_sourcemodel
% 
% OUTPUT: leadfield potentials for many dipole locations on a regular 3D grid 
%   pots    leadfield potentials for a gieven electrode configuration and source positions 
% 
% EXAMPLE: Regular 3mm grid and precalculated lead-pair potentials
% cfg = [];
% cfg.mri             = seg_fd;
% cfg.grid.resolution = 3;
% cfg.grid.unit       = 'mm';
% cfg.smooth          = 'no';
% subject_grid        = ft_prepare_sourcemodel(cfg);
% leadfield           = gfdm_calculate_leadfield(lead, subject_grid);

pos = grid.pos;
ins = grid.inside;
Tr  = lead.mri.transform;
Ar  = lead.mri.anatomy;
mri = lead.mri;

[nonz val] = find(ins == 1);
posi = pos(nonz,:);
posmri = ft_warp_apply(inv(mri.transform), posi); % transform to head coordinates

% pots = lead.grid;
pots.leadfield = cell(1,length(pos));
% pots.label = lead.elec.label;
pots.leadfielddimord = '{pos}_chan_ori';
ft_progress('init', 'text',    'Calculating Potentials...');
for a = 1:length(posmri)
    ft_progress(a/length(posmri), 'Calculating Potentials %d/%d', a, length(posmri));
    source_loc = posmri(a,:);
    pots.leadfield{nonz(a)} = solve_forward_real(lead,source_loc);    
end
ft_progress('close');
disp('Done!!!')