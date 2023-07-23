function [M1] = net_rigidreg(data1, data2)
% Computes homogenious transformation matrix based on two sets
% of points from two coordinate systems
%
% FORMAT [M1] = net_rigidreg(data1, data2)
% Input:
% data1      - locations of the first set of points corresponding to the
%            3D surface to register onto 
% data2      - locations of the second set of points corresponding to the
%            second 3D surface to be registered 
%__________________________________________________________________________

 
M       = mean(data1,2);
S       = mean(data2,2);
data1=data1-M*ones(1,size(data1,2));
data2=data2-S*ones(1,size(data2,2));

R1      = data1*pinv(data2);

t1 = M - R1*S;
M1 = [R1 t1; 0 0 0 1];
