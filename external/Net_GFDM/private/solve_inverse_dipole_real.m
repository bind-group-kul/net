function Result = solve_inverse_dipole_real(V, lead, dipole, solver) 
 
% center = lead.vol.cent_pos;
% solver.MaxFunEvals = 1e6;
% solver.MaxIter     = 1e5;
 
L  = lead.elec.leadp;
Ad = inv(trans_avr_lead(L));

Random = zeros(1,3);
Random(1,1:3) = dipole;
Result = zeros(1,7);

[Result(1,1:3),out]=fminsearch('dip_pos_inv_struct',Random(1,1:3),optimset('TolX',1.e-8,'TolFun',1.e-8,'Display','off','MaxFunEvals',solver.MaxFunEvals,'MaxIter',solver.MaxIter), V, lead, Ad, lead.vol.gm_idx);
% [Result(1,1:3),out]=fminsearch('dip_pos_inv_struct',Random(1,1:3),optimset('TolX',1.e-8,'TolFun',1.e-8,'Display','off','MaxFunEvals',1000000,'MaxIter',100000), V, hm.mr,hm.lead,Ad,hm.CSFlabel);
C = TriLinIterpolationPots(lead,Result(1,1:3));
C = -Ad*[C;0 0 0];
psC=(C'*C)\C';
Ori=psC*V;

Ori=Ori./norm(Ori);
Result(1,4:6)=[Ori(1),Ori(2),Ori(3)];

Result(1,7)=out;
