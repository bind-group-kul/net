% check_surr_I.m
% Ernesto Cuartas M (ECM), 24/04/2017
% Email:  ecuartasmo@unal.edu.co

function check = check_surr_FC(As,psa)

sz = size(As);

x_mn = floor(psa(1));
y_mn = floor(psa(2));
z_mn = floor(psa(3));

x_mx = ceil(psa(1));
y_mx = ceil(psa(2));
z_mx = ceil(psa(3));

if(x_mn >= 1 && x_mn <= sz(1) && y_mn >= 1 && y_mn <= sz(2) && z_mn >= 1 && z_mn <= sz(3) &&...
   x_mx >= 1 && x_mx <= sz(1) && y_mx >= 1 && y_mx <= sz(2) && z_mx >= 1 && z_mx <= sz(3)     )
    if(As(x_mn,y_mn,z_mn) || As(x_mx,y_mx,z_mx))
        check = 1;
    else
        check = 0;
    end
else
    check=0;
end