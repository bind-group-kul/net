function [Results, OPTIONS] = bst_lcmvbf(Gain, OPTIONS)
% LCMVBF: Spatial filtering solution.
%
% USAGE:  [Results, OPTIONS] = bst_lcmvbf(Gain, OPTIONS)
%                    OPTIONS = bst_lcmvbf()
%
% NOTES:
%     - This function is not optimized for stand-alone command calls.
%     - Please use the generic BST_SOURCEIMAGING function, or the GUI.a
%
% INPUTS:
%     - Gain       : Forward field matrix for all the channels
%     - OPTIONS    : Structure of parameters (described in bst_sourceimaging.m)
%          |- Data           : Post-stimulus matrix (channels x times)
%          |- DataBaseline   : Pre-stimulus matrix (channels x times)
%          |- Tikhonov       : Tikhonov regularization percentage parameter
%          |- isConstrained  : 0 = source orientation is not constrained
%          |                   1 = orientation is constrained normal to surface
%          |- OutputFormat   : 0 = Filter Output
%                              1 = Neural Index
%                              2 = Normalized Filter Output
%                              3 = Source Power
% OUTPUTS:
%     - Results : Structure
%          |- ImageGridAmp  : If filterOutput = true, then []. Otherwise, the source map
%          |                  is the neural activity index for neuralIndex true and the
%          |                  source power for neuralIndex false.
%          |- ImagingKernel : If filterOutput = false, then []. Otherwise, the
%                             spatial filter of the beamformer. Multiply by the data
%                             to get the spatial map.
%
% @=============================================================================
% This software is part of the Brainstorm software:
% http://neuroimage.usc.edu/brainstorm
% 
% Copyright (c)2000-2014 University of Southern California & McGill University
% This software is distributed under the terms of the GNU General Public License
% as published by the Free Software Foundation. Further details on the GPL
% license can be found at http://www.gnu.org/copyleft/gpl.html.
% 
% FOR RESEARCH PURPOSES ONLY. THE SOFTWARE IS PROVIDED "AS IS," AND THE
% UNIVERSITY OF SOUTHERN CALIFORNIA AND ITS COLLABORATORS DO NOT MAKE ANY
% WARRANTY, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
% MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, NOR DO THEY ASSUME ANY
% LIABILITY OR RESPONSIBILITY FOR THE USE OF THIS SOFTWARE.
%
% For more information type "brainstorm license" at command prompt.
% =============================================================================@
%
% Authors: Esen Kucukaltun-Yildirim, October 2004
%          John Mosher, Syed Ashrafulla, Francois Tadel, 2009

if (nargin == 0)
    Results.OutputFormat  = 1;
    Results.Data          = [];
    Results.Tikhonov      = 10;
    Results.DataBaseline  = [];
    Results.isConstrained = 1;
    return;
end

%% ===== LCMV BF ESTIMATE =====
% Set flags:
%  neuralIndex  : true --> return the neural activity index in ImageGridAmp
%  filterOutput : true --> return the spatial filter in ImagingKernel
%  isNormalized : true --> same as filterOutput, but normalize filter coefs
neuralIndex  = (OPTIONS.OutputFormat == 1);
filterOutput = (OPTIONS.OutputFormat == 0 || OPTIONS.OutputFormat == 2);
isNormalized = (OPTIONS.OutputFormat == 2);

%% ====== GET FORWARD FIELD =====
% Get forward field
Kernel = Gain; 
Kernel(abs(Kernel(:)) < eps) = eps; % Set zero elements to strictly non-zero
[nChannels, nSources] = size(Kernel); % size of Gain Matrix

%% ===== COVARIANCE MATRICES =====
% Invert the data covariance matrix, with regularization
% If user does not regularize, Lambda = 0 --> direct inverse
m = size(OPTIONS.Data, 2);
F = bst_bsxfun(@minus, OPTIONS.Data, mean(OPTIONS.Data,2));
[U,S] = svd(F*F'/(m-1)); % Covariance = 1/(m-1) * F * F'
S = diag(S); % Covariance = Cm = U*S*U'
Si = diag(1 ./ (S + S(1) * OPTIONS.Tikhonov / 100)); % 1/(S^2 + lambda I)
Cm_inv = U*Si*U'; % U * 1/(S^2 + lambda I) * U' = Cm^(-1)

if neuralIndex % Generate regularized noise covariance matrix for neural index
    m = size(OPTIONS.DataBaseline, 2);
    OPTIONS.DataBaseline = bst_bsxfun(@minus, OPTIONS.DataBaseline, mean(OPTIONS.DataBaseline,2));
    [U,S] = svd(F*F'/(m-1)); % Covariance = 1/(m-1) * F * F'
    S = diag(S); % Covariance = Cm = U*S*U'
    Si = diag(1./(S + S(1) * OPTIONS.Tikhonov / 100)); % 1/(S^2 + lambda I)
    Cn_inv = U*Si*U'; % U * 1/(S^2 + lambda I) * U' = Cm^(-1)
end
clear F U S Si m Lambda

% ===== CALCULATE POWERS AND FILTERS =====
if OPTIONS.isConstrained % constrained LCMV
    % source power = (G Cm^-1 G')^(-1)
    source_power = sum(Kernel.*(Cm_inv*Kernel)).^-1;
    if neuralIndex % need noise power for NAI calculation
        % noise power = (G Cn^-1 G')^(-1)
        noise_power = sum(Kernel.*(Cn_inv*Kernel)).^-1;
    elseif filterOutput % beamformer filter = (G Cm^-1 G')^-1 (G'Cm^-1)
        spatialFilter = repmat(source_power',1,size(Cm_inv,2)).*(Kernel'*Cm_inv);
    else 
        % Already calculated before the if block
    end
else % unconstrained LCMV
    source_power = zeros(1,nSources/3); % source power
    for i = 1:3:nSources
        Gi = Kernel(:,i:i+2); % At each vertex, src pwr = tr{(G Cm^-1 G')^(-1)}
        source_power(floor(i/3+1)) = trace(lcmvPInv(Gi'*Cm_inv*Gi));
    end
    if neuralIndex
        noise_power = zeros(1,nSources/3);
        for i = 1:3:nSources % calculate noise power for index
            Gi = Kernel(:,i:i+2); % At each vertex, noise pwr = tr{(G Cn^-1 G')^(-1)}
            noise_power(floor(i/3+1)) =  trace(lcmvPInv(Gi'*Cn_inv*Gi));
        end
    elseif filterOutput
        spatialFilter = zeros(nSources, nChannels); % calculate filter for outputs
        for i = 1:3:nSources
            Gi = Kernel(:,i:i+2); % Filter at each vertex = (GCmG')^(-1) (CmG)'
            spatialFilter(i:i+2,:) = lcmvPInv(Gi'*Cm_inv*Gi)*(Cm_inv*Gi)';
        end
    else 
        % Already calculated before the if block
    end
end

%% ===== ASSIGN MAPS AND KERNELS =====
ImageGridAmp = []; 
ImagingKernel = [];
if neuralIndex
    % (G Cs^-1 G')^-1 / (G Cn^-1 G')^-1, traces applied already if unconstrained
    ImageGridAmp =  source_power'./noise_power';
elseif filterOutput % === WHAT IS THIS FILTER OUTPUT? ===
    if isNormalized
        tmp = (spatialFilter * OPTIONS.DataBaseline); % Noise data
        mean_Baseline= mean(tmp, 2); std_Baseline = std(tmp, 0, 2); % mu_n,sigma_n
        ImagingKernel = single(bst_bsxfun(@rdivide, ... % (filter - mu_n)/sigma_n
            bst_bsxfun(@minus, spatialFilter, mean_Baseline), std_Baseline));
    else
        ImagingKernel = spatialFilter;
    end
else
    ImageGridAmp = source_power';
end
% Return structure
Results = struct('ImageGridAmp', ImageGridAmp, ...
                 'ImagingKernel', ImagingKernel);

end
    
%% ===== TRUNCATED PSEUDO-INVERSE =====
function X = lcmvPInv(A)
    % Inverse of 3x3 GCG' in unconstrained beamformers.
    % Since most head models have rank 2 at each vertex, we cut all the fat and
    % just take a rank 2 inverse of all the 3x3 matrices
    [U,S,V] = svd(A,0);
    S = diag(S);
    X = V(:,1:2)*diag(1./S(1:2))*U(:,1:2)';
end
