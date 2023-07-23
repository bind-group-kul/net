% check_surr_I.m
% Ernesto Cuartas M (ECM), 24/04/2017
% Email:  ecuartasmo@unal.edu.co

function check = check_surr_I(As,psa)

sz = size(As);

x = round(psa(1));
y = round(psa(2));
z = round(psa(3));

if(x >= 1 && x <= sz(1) && y >= 1 && y <= sz(2) && z >= 1 && z <= sz(3) )
    if(As(x,y,z) > 0)
        check = 1;
    else
        check = 0;
    end
else
    check=0;
end