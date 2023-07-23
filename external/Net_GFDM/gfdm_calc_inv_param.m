function Inve = gfdm_calc_inv_param( lead_R, lead_B, mri_gm, crt )

Inve.crt = crt;
Inve.Cx.mr = squeeze(lead_B.vol.box.anatomy(crt(1), :, :));
Inve.Cy.mr = squeeze(lead_B.vol.box.anatomy(:, crt(2), :));
Inve.Cz.mr = squeeze(lead_B.vol.box.anatomy(:, :, crt(3)));

dip_loc_x = [];
dip_loc_y = [];
dip_loc_z = [];

sz = size(mri_gm);

for b = 1:sz(2)
    for c = 1:sz(3)
        a = crt(1);
        if(mri_gm(a,b,c))
            dip_loc_x = [dip_loc_x; a, b, c];
        end
    end
end

for a = 1:sz(1)
    for c = 1:sz(3)
        b = crt(2);
        if(mri_gm(a,b,c))
            dip_loc_y = [dip_loc_y; a, b, c];
        end
    end
end

for a = 1:sz(1)
    for b = 1:sz(2)
        c = crt(3);
        if(mri_gm(a,b,c))
            dip_loc_z = [dip_loc_z; a, b, c];
        end
    end
end

solver.MaxIter     = 1e2;
solver.MaxFunEvals = 10*solver.MaxIter;
Inve.solver = solver;

Inve.Cx.dip_loc = dip_loc_x;
Inve.Cy.dip_loc = dip_loc_y;
Inve.Cz.dip_loc = dip_loc_z;

% X --------------------------

ndip_X = length(dip_loc_x);

dip_X_x.loc = zeros(ndip_X,3);
dip_X_x.ori = zeros(ndip_X,3);
dip_X_x.res = zeros(ndip_X,1);

dip_X_y.loc = zeros(ndip_X,3);
dip_X_y.ori = zeros(ndip_X,3);
dip_X_y.res = zeros(ndip_X,1);

dip_X_z.loc = zeros(ndip_X,3);
dip_X_z.ori = zeros(ndip_X,3);
dip_X_z.res = zeros(ndip_X,1);

ft_progress('init', 'text', 'Inverse Calc X...');
for a = 1:ndip_X
    ft_progress(a/ndip_X, 'Dipole estimation %d/%d\n', a, ndip_X);

    Vr     = solve_forward_real(lead_R, dip_loc_x(a,:));
    res_x = solve_inverse_dipole_real( Vr(:,1), lead_B, dip_loc_x(a,:), solver );
    res_y = solve_inverse_dipole_real( Vr(:,2), lead_B, dip_loc_x(a,:), solver );
    res_z = solve_inverse_dipole_real( Vr(:,3), lead_B, dip_loc_x(a,:), solver );
    
    dip_X_x.loc(a,:) = res_x(1:3);
    dip_X_x.ori(a,:) = res_x(4:6);
    dip_X_x.res(a,:) = res_x(7);
    
    dip_X_y.loc(a,:) = res_y(1:3);
    dip_X_y.ori(a,:) = res_y(4:6);
    dip_X_y.res(a,:) = res_y(7);
    
    dip_X_z.loc(a,:) = res_z(1:3);
    dip_X_z.ori(a,:) = res_z(4:6);   
    dip_X_z.res(a,:) = res_z(7);
end
ft_progress('close');

Inve.Cx.dipx = dip_X_x;
Inve.Cx.dipy = dip_X_y;
Inve.Cx.dipz = dip_X_z;
Inve.Cx.ndip = ndip_X;

% Y --------------------------

ndip_Y = length(dip_loc_y);

dip_Y_x.loc = zeros(ndip_Y,3);
dip_Y_x.ori = zeros(ndip_Y,3);
dip_Y_x.res = zeros(ndip_Y,1);

dip_Y_y.loc = zeros(ndip_Y,3);
dip_Y_y.ori = zeros(ndip_Y,3);
dip_Y_y.res = zeros(ndip_Y,1);

dip_Y_z.loc = zeros(ndip_Y,3);
dip_Y_z.ori = zeros(ndip_Y,3);
dip_Y_z.res = zeros(ndip_Y,1);

ft_progress('init', 'text', 'Inverse Calc Y...');
for a = 1:ndip_Y
    ft_progress(a/ndip_Y, 'Dipole estimation %d/%d\n', a, ndip_Y);

    Vr     = solve_forward_real(lead_R, dip_loc_y(a,:));
    res_x = solve_inverse_dipole_real( Vr(:,1), lead_B, dip_loc_y(a,:), solver );
    res_y = solve_inverse_dipole_real( Vr(:,2), lead_B, dip_loc_y(a,:), solver );
    res_z = solve_inverse_dipole_real( Vr(:,3), lead_B, dip_loc_y(a,:), solver );
    
    dip_Y_x.loc(a,:) = res_x(1:3);
    dip_Y_x.ori(a,:) = res_x(4:6);
    dip_Y_x.res(a,:) = res_x(7);
    
    dip_Y_y.loc(a,:) = res_y(1:3);
    dip_Y_y.ori(a,:) = res_y(4:6);
    dip_Y_y.res(a,:) = res_y(7);
    
    dip_Y_z.loc(a,:) = res_z(1:3);
    dip_Y_z.ori(a,:) = res_z(4:6);   
    dip_Y_z.res(a,:) = res_z(7);
end
ft_progress('close');

Inve.Cy.dipx = dip_Y_x;
Inve.Cy.dipy = dip_Y_y;
Inve.Cy.dipz = dip_Y_z;
Inve.Cy.ndip = ndip_Y;

% Z --------------------------

ndip_Z = length(dip_loc_z);

dip_Z_x.loc = zeros(ndip_Z,3);
dip_Z_x.ori = zeros(ndip_Z,3);
dip_Z_x.res = zeros(ndip_Z,1);

dip_Z_y.loc = zeros(ndip_Z,3);
dip_Z_y.ori = zeros(ndip_Z,3);
dip_Z_y.res = zeros(ndip_Z,1);

dip_Z_z.loc = zeros(ndip_Z,3);
dip_Z_z.ori = zeros(ndip_Z,3);
dip_Z_z.res = zeros(ndip_Z,1);

ft_progress('init', 'text', 'Inverse Calc Z...');
for a = 1:ndip_Z
    ft_progress(a/ndip_Z, 'Dipole estimation %d/%d\n', a, ndip_Z);

    Vr     = solve_forward_real(lead_R, dip_loc_z(a,:));
    res_x = solve_inverse_dipole_real( Vr(:,1), lead_B, dip_loc_z(a,:), solver );
    res_y = solve_inverse_dipole_real( Vr(:,2), lead_B, dip_loc_z(a,:), solver );
    res_z = solve_inverse_dipole_real( Vr(:,3), lead_B, dip_loc_z(a,:), solver );
    
    dip_Z_x.loc(a,:) = res_x(1:3);
    dip_Z_x.ori(a,:) = res_x(4:6);
    dip_Z_x.res(a,:) = res_x(7);
    
    dip_Z_y.loc(a,:) = res_y(1:3);
    dip_Z_y.ori(a,:) = res_y(4:6);
    dip_Z_y.res(a,:) = res_y(7);
    
    dip_Z_z.loc(a,:) = res_z(1:3);
    dip_Z_z.ori(a,:) = res_z(4:6);   
    dip_Z_z.res(a,:) = res_z(7);
end
ft_progress('close');

Inve.Cz.dipx = dip_Z_x;
Inve.Cz.dipy = dip_Z_y;
Inve.Cz.dipz = dip_Z_z;
Inve.Cz.ndip = ndip_Z;