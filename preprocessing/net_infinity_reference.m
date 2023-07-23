%% Purpose
% Step 1. Use the lead-field matrix (G)
% Step 2: re-refence at infinity (Refer to REST paper from Dezhong Yao)
% Step 2a) Compute Gavg = avg(G); mean across all sensors in a single timepoint;
% Step 2b) Compute Ga = G-Gavg; 
% Step 2c) Compute Ra = G*inv(Ga); Average reference standardisation matrix
% Step 2d) Compute Va = V - avg(V); Average re-referenced data;
% Step 2e) Compute Vinf = Ra*Va; Infinity re-referenced data;

function [ Refmatrix_inf ] = net_infinity_reference( headmodel_filename )


try
    
    load(headmodel_filename,'leadfield');
    
    A=leadfield.leadfield(leadfield.inside);
    
    nchan=size(A{1},1);
    
    
    G=zeros(nchan,size(A{1},2)*length(A)); %Just to unwrap the cell elements
    for i=1:length(A)
        G(:,3*(i-1)+1:3*i)=A{i};
    end
    
    for i=1:size(G,2)
        G(:,i) = G(:,i) - mean(G(:,i));
    end
    
    
     for i=1:length(A)
            tmplf = G(:, (3*i-2):(3*i));
            nrm = norm(tmplf, 'fro');
            if nrm>0
                tmplf = tmplf ./ nrm;
            end
            G(:, (3*i-2):(3*i)) = tmplf;
     end

    
    Refmatrix_avg = eye(nchan)-ones(nchan)*1/nchan;
    Gx = mean(G,1); % G_ave is sparce matrix; mean along columnwise(across sensors)
    G_ave = G-repmat(Gx, size(G,1),1);%Removing the mean from each entry;
    Refmatrix_inf = G*pinv(G_ave,0.05) * Refmatrix_avg;    % the value 0.05 is for real data; for simulated data, it may be set as zero. G*Ra*G = G, get size(Ra) = [129 129];Step for computing Ga
    
    
catch
    disp(['error loading leadfield matrix for ' headmodel_filename]);
end
%%
% Revision history:
%{
2014-05-05 
    v0.1 Updated the file based on initial versions from Dante and
    Quanying(Revision author : Sri).
   

%}

