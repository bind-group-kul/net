% SetStiffnessMatrix.m
% Ernesto Cuartas M (ECM), 24/04/2017
% Email:  ecuartasmo@unal.edu.co

function [ mA, c_idx, Cidx, Nz] = SetStiffnessMatrixMex( cfg )

As   = cfg.A;
Is   = cfg.IA;
Js   = cfg.JA;
Cidx = cfg.cidx;

Nz = Is(length(Is),1) + 1;
mA = sparse(Is+1, Js+1, As, Nz, Nz, length(As));
c_idx = zeros(cfg.Size(1)+1, cfg.Size(2)+1, cfg.Size(3)+1);
pos = 0;

% Non Zeros vector Cidx to Matrix c_idx
for c = 1: cfg.Size(3)+1
    for b = 1: cfg.Size(2)+1
        for a = 1: cfg.Size(1)+1
            pos = pos +1;
            c_idx(a,b,c) = Cidx(pos);
        end
    end    
end
