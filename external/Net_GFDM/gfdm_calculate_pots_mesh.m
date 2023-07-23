% afdm_calculate_pots.m
% Ernesto Cuartas M (ECM), 24/04/2017
% Email:  ecuartasmo@unal.edu.co

function pots = gfdm_calculate_pots_mesh(lead, gm_mesh)

nsrc = length(gm_mesh.pnt);
pots = zeros(lead.elec.nelec, nsrc);

ft_progress('init', 'text',    'Calculating Potentials...');
for a = 1:nsrc
    ft_progress(a/nsrc, 'Calculating Potentials %d/%d', a, nsrc);
    source_loc = gm_mesh.pnt(a,:);
    pota = solve_forward_real(lead,source_loc);
    poti = pota * gm_mesh.nor(a,:)';
    pots(:,a) = poti;
end
ft_progress('close');
disp('Done!!!')