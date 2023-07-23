function  V  = TriLinV( lead, xf, yf, zf )

x0 = double(floor(xf));
y0 = double(floor(yf));
z0 = double(floor(zf));

x1 = x0+1;
y1 = y0+1;
z1 = z0+1;

xd = (xf-x0)/(x1-x0);
yd = (yf-y0)/(y1-y0);
zd = (zf-z0)/(z1-z0);

V000 = GetPotIdx(lead, x0, y0, z0);
V100 = GetPotIdx(lead, x1, y0, z0);
V110 = GetPotIdx(lead, x1, y1, z0);
V010 = GetPotIdx(lead, x0, y1, z0);
V001 = GetPotIdx(lead, x0, y0, z1);
V101 = GetPotIdx(lead, x1, y0, z1);
V111 = GetPotIdx(lead, x1, y1, z1);
V011 = GetPotIdx(lead, x0, y1, z1);

V00 = V000*(1-xd) + V100*xd;
V01 = V001*(1-xd) + V101*xd;
V10 = V010*(1-xd) + V110*xd;
V11 = V011*(1-xd) + V111*xd;

V0 = V00*(1-yd) + V10*yd;
V1 = V01*(1-yd) + V11*yd;

V = V0*(1-zd) + V1*zd;

