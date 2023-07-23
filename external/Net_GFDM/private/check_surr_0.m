% check_surr_0.m
% Ernesto Cuartas M (ECM), 24/04/2017
% Email:  ecuartasmo@unal.edu.co

function check=check_surr_0(As,psa)

sz = size(As);

x = psa(1);
y = psa(2);
z = psa(3);

sel = -1:1;

if(x-1 >= 1 && x+1 <= sz(1) && y-1 >= 1 && y+1 <= sz(2) && z-1 >= 1 && z+1 <= sz(3) )
    Vec = As(sel+x, sel+y, sel+z);
    [sa, pa, va]= find(Vec > 0);
else
    va = 0;
end

if sum(va) == 27
    check=1;
else
    check=0; 
end