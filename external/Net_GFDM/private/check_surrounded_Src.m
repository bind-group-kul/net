% check_surrounded.m
% Ernesto Cuartas M (ECM), 24/04/2017
% Email:  ecuartasmo@unal.edu.co

function check = check_surrounded_Src(Head,xf,yf,zf,label)

x = floor(xf);
y = floor(yf);
z = floor(zf);

if(Head(x, y, z) == label && Head(x-1, y, z) == label && Head(x+1, y, z) == label && Head(x+2, y, z) == label &&...
    Head(x, y-1, z) == label && Head(x, y+1, z) == label && Head(x, y+2, z) == label &&... 
    Head(x, y, z-1) == label && Head(x, y, z+1) == label && Head(x, y, z+2) == label )
    check = 1;
else
    check = 0;
end
