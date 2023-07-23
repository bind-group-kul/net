function source_ortho = net_othogonalise_time(source)
%NET_ORTHOGONALISE_TIME     orthogonalise source activity (considering the 
%                           main component) according to Gram-Schmidt method
%Input:     source          - source activity described by the first principal
%                             component ( " _pca_source " )
%Output:    source_ortho    - orthogonalised sources

source_ortho = zeros(size(source));
for j = 1:size(source,2)
    v = source(:, j);
    for i = 1:j-1
    	R(i,j) = source_orth(:,i)' * source(:,j);
    	v = v - R(i,j) * source_orth(:,i);
    end
    R(j,j) = norm(v);
    source_orth(:,j) = v/R(j,j);
end