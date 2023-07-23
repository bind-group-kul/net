function [lf] = net_normalize_fnsleadfield(lf,normalizeparam)

Ndipoles = size(lf,2)/3;

for i=1:size(lf,2)
      lf(:,i) = lf(:,i) - mean(lf(:,i));
end
    
for ii=1:Ndipoles
    tmplf = lf(:, (3*ii-2):(3*ii));
    if normalizeparam==0.5
        % normalize the leadfield by the Frobenius norm of the matrix
        % this is the same as below in case normalizeparam is 0.5
        nrm = norm(tmplf, 'fro');
    else
        % normalize the leadfield by sum of squares of the elements of the leadfield matrix to the power "normalizeparam"
        % this is the same as the Frobenius norm if normalizeparam is 0.5
        nrm = sum(tmplf(:).^2)^normalizeparam;
    end
    if nrm>0
        tmplf = tmplf ./ nrm;
    end
    lf(:, (3*ii-2):(3*ii)) = tmplf;
end
