% check_surrounded.m
% Ernesto Cuartas M (ECM), 24/04/2017
% Email:  ecuartasmo@unal.edu.co

function check = check_surrounded_GM(Head,xf,yf,zf,label)
x = round(xf);
y = round(yf);
z = round(zf);
if(Head(x, y, z) == label)
    check = 1;
else
    check = 0;
end
