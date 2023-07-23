function X = geometrical_matrix_4thorder(V)
% S. Mohammadi 10/07/2012

if size(V,1) ~= 3
    error('Diffusion gradient vectors in wrong format: 3xN (N = number of diffusion gradients)!')
end

X(1,:)  = V(1,:).^4;
X(2,:)  = V(2,:).^4;
X(3,:)  = V(3,:).^4;

X(4,:)  = 4*V(1,:).^3.*V(2,:);
X(5,:)  = 4*V(1,:).^3.*V(3,:);
X(6,:)  = 4*V(2,:).^3.*V(1,:);
X(7,:)  = 4*V(2,:).^3.*V(3,:);
X(8,:)  = 4*V(3,:).^3.*V(1,:);
X(9,:)  = 4*V(3,:).^3.*V(2,:);

X(10,:) = 6*V(1,:).^2.*V(2,:).^2;
X(11,:) = 6*V(1,:).^2.*V(3,:).^2;
X(12,:) = 6*V(2,:).^2.*V(3,:).^2;

X(13,:) = 12*V(1,:).^2.*V(2,:).*V(3,:);
X(14,:) = 12*V(2,:).^2.*V(1,:).*V(3,:);
X(15,:) = 12*V(3,:).^2.*V(1,:).*V(2,:);
X = X';