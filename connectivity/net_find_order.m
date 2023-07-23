function order = net_find_order(data)
%NET_FIND_ORDER     Define the best order for MAR/AR model as the ratio between 
%                   the minimum index between Akaike and Bayesian Information 
%                   Criterion, and a number between 1 and 5, proportional to
%                   the data correlation.
%
%Input:             DATA matrix - each colums contains one observation of data,
%                   trial information is saved in the third dimension.
%Output:            ORDER       - best order for the autoregressive model.

[win_samples, n_voxel, nwin] = size(data);
ord = zeros(nwin,1);

maxorder = floor((win_samples * nwin - 1)/(2 + nwin) - 1);

% compute Akaike and BIC indices
for i = 1:nwin
    [bic, aic] = cca_find_model_order(data(:,:,i)', 3, maxorder + 1);
    ord(i) = min(bic,aic);
end

% compute the best order for the AR model
order = ceil(median(ord));

if order < 3 
    order = 3;
elseif order > maxorder
    order = maxorder;
end
end