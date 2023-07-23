function D = ConTenV2(v1, eigv)

% v1 = pos - cent;
v1 = v1 / norm(v1);

v1p = [-v1(2) v1(1) 0];
if(norm(v1p) == 0)
    v1p = [v1(2) -v1(1) 0] + [0 v1(3) -v1(2)];
end

v1c = cross(v1, v1p);

v1p = v1p / norm(v1p);
v1c = v1c / norm(v1c);

T1 = [v1', v1p', v1c'];

D = (T1) * eigv * T1';

