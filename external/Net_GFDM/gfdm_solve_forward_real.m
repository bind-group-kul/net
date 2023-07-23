% SetStiffnessMatrix.m
% Ernesto Cuartas M (ECM), 24/04/2017
% Email:  ecuartasmo@unal.edu.co

function C = gfdm_solve_forward_real(lead,source_loc)

%lead pairs
L  = lead.elec.leadp;

% Reciprocity source - sink transformation matrix
Ad = trans_avr_lead(L); 

% Trilinear interpolation routine
Ca = TriLinIterpolationPots(lead,source_loc);

% Transforming currents to potentials (Reciprocity)
C  = -Ad\[Ca;0 0 0];