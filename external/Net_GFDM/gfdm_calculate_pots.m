% gfdm_calculate_pots.m
% Ernesto Cuartas M (ECM), 24/04/2017
% Updated: 02/06/2020
% Email: ecuartasm@gmail.com

function pots = gfdm_calculate_pots(lead, cfg)
% gfdm_calculate_pots.m
% Ernesto Cuartas M (ECM), 24/04/2017
% Updated: 02/06/2020
% Email: ecuartasm@gmail.com
% 
% GFDM_CALCULATE_POTS calculates the leadfield matrix for a given grid-source 
% space and precalculated lead-pairs potentials (gfdm_precalculate_leads output).
% 
% INPUT: ( lead, cfg ). lead is the ouput of the gfdm_precalculate_leads
% function. The cfg argument is the same structure for the gfdm_precalculate_leads
% funtion imput containing:
% cfg.vol            head model structure, output -> gfdm_prepare_headmodel;
% cfg.electrodes     electrodes structure, output -> gfdm_prepare_elecs;
% cfg.mri            structural aligned MRI;
% cfg.solver         structure holding the linear solver paremeters;
% cfg.gmask          string that allows the reduction of the stored potentials;
% cfg.grid           structur containing source position;
% 
% OUTPUT: ( leadfield ) structure holding the leadfield potentials for a given 
% grid for source positions.
% leadfield.inside       logical vector holding flags for the source positions
%                        inside the grey matter;
% leadfield.pos          2D array holding the source positions;
% leadfield.leadfield    cell array holding the leadfiled potentials
% 
% EXAMPLE
% lead -> output -> gfdm_precalculate_leads
% cfg  -> input  -> gfdm_precalculate_leads
% leadfield = gfdm_calculate_pots(lead, cfg);



pos = cfg.grid.pos;
ins = cfg.grid.inside;
% Tr  = lead.mri.transform;
% Ar  = lead.mri.anatomy;
% mri = lead.mri;

[nonz val] = find(ins == 1);
posi = pos(nonz,:);
box_Ti = cfg.vol.box.transform;
mri_Ti = cfg.vol.box.segTr;
Tr = mri_Ti*box_Ti;
posmri = ft_warp_apply(inv(Tr), posi); % transform to head coordinates

% chkps = zeros(length(posmri),1);
% segd = cfg.vol.segmentation.anatomy;
% for a = 1:length(posmri)
%     if( check_surr_L(segd,posmri(a,:), 1) || check_surr_L(segd,posmri(a,:), 2) )
%         chkps(a) = 1;
%     else
%         chkps(a) = 0;
%     end
% end
% 
% [chk_nz tmp] = find(chkps==1);
% [chk_zz tmp] = find(chkps==0);
% 
% mrsg = cfg.vol.segmentation;
% mrsg.transform = eye(4);
% cfgsg             = [];
% cfgsg.tissue      = {'cortex_gm'};
% cfgsg.numvertices = [10000];
% bnd_seg             = ft_prepare_mesh(cfgsg,mrsg);
% % save('seg_mri.mat', 'seg_mri');
% figure
% ft_plot_mesh(bnd_seg(1), 'facecolor',[0.2 0.6 0.2], 'facealpha', 0.8, 'edgecolor', [1 1 1], 'edgealpha', 0.05);
% 
% hold on
% plot3(posmri(chk_nz,1), posmri(chk_nz,2), posmri(chk_nz,3), '*b')
% plot3(posmri(chk_zz,1), posmri(chk_zz,2), posmri(chk_zz,3), '+r')
% axis equal

pots = [];
pots = cfg.grid;
pots.leadfield = cell(1,length(pos));
pots.label = cfg.elec.label;
pots.leadfielddimord = '{pos}_chan_ori';
ft_progress('init', 'text',    'Calculating Potentials...');
for a = 1:length(posmri)
    ft_progress(a/length(posmri), 'Calculating Potentials %d/%d', a, length(posmri));
    source_loc = posmri(a,:);
    pots.leadfield{nonz(a)} = solve_forward_real(lead,source_loc);    
end
ft_progress('close');
disp('Done!!!')