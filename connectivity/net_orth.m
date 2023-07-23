function P = net_orth(Z)
% input:    Z is a M*N matrix
%           M is number of time sample
%           N is number of ROIs
% output:   P is the orthogonalised signals of Z
%
% reference: Colclough, G.L, 2015, A symmetric multivariate leakage
% correction for MEG connectomes, Neuroimage
%
% Quanying Liu
% 22.08.2015

[M, N] = size(Z); 
% M: number of time sample
% N: number of ROIs

if M<N
    error('the number of time samples should be bigger than number of ROIs');
end
D1 = diag( ones(N,1) );  % initial state
P1 = ones(M,N)*D1;       % based on P = O*D;
err1 = 0;
% err2 = norm(Z-P1);  % initial error
% err2 = norm((Z-P1),'fro')  % JS
% err2 = trace(Z'*Z)-2*trace(Z'*P1)+trace(D1.^2);  % JS
err2 = 0;

% minimize the error
while (err2 <= err1) % && abs(err2-err1)>10^(-4) 
    
    err1 = err2;
    
    [U, ~, V] = svd(Z*D1, 0);
    % O = U*ones(M,N)*V';
    O = U*V';
    d = diag(Z'*O);   % get the diagonal elements of Z'*O
    D2 = diag(d);
    P2 = O*D2;
    
%     err2 = norm(Z-P2);
    err2 = norm((Z-P2),'fro')  % JS
%     err2 = trace(Z'*Z)-2*trace(Z'*P2)+trace(D2.^2);  % JS
    D1 = D2;
    clear U V O
end
P = P2;