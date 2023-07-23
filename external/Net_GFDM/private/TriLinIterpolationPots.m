% forward_lead4_struct_h2.m
% Ernesto Cuartas M (ECM), 24/04/2017
% Email:  ecuartasmo@unal.edu.co

function Pote = TriLinIterpolationPots(lead,source)

hvox = lead.vol.VoxelSize;

xf = source(1);
yf = source(2);
zf = source(3);

Vxa  = TriLinV( lead, xf-1, yf,   zf );
Vxb  = TriLinV( lead, xf+1, yf,   zf );
Vya  = TriLinV( lead, xf,   yf-1, zf );
Vyb  = TriLinV( lead, xf,   yf+1, zf );
Vza  = TriLinV( lead, xf,   yf,   zf-1 );
Vzb  = TriLinV( lead, xf,   yf,   zf+1 );

Vx = (Vxb - Vxa)./(2*hvox(1));
Vy = (Vyb - Vya)./(2*hvox(2));
Vz = (Vzb - Vza)./(2*hvox(3));

Pote = [Vx' Vy' Vz'];
  