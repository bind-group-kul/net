function [SLm, HITm, RECm, D, E, P] = net_synchronization_likelihood(data, PREF, P)
% Didn't test it!!!!!!!!!!!!!!
%
% Function to calculate synchronization likelihood between two time signals
% Input:
%   data: matrix of time signal samples (samples, 2 channels)
%   PREF: pair of optimal p_ref values
%   P: parameter structure containing
%       fs: sampling frequency
%       m: time-delay embedding dimension m
%       lag: time-delay
% Output:
%   SLm: synchronization likelihood matrix (2 channels, iterations i)
%   HITm: matrix of number of hits (2 channels, iterations i)
%   RECm: logical matrix, 1: recurrence of reference vector i, 0: otherwise 
%         (2 channels, iterations i, state vectors j)
%   D: Distance matrix containing Euclidean distances between the reference
%           vector and state vectors (2 channels, iterations i, state vectors j)
%   E: threshold distances epsilon (2 channels, iterations i)
%   P: updated parameter structure
%
% Quanying
% 18.03.2015

%% initialize core vars
if isempty(PREF)
    P.p_ref   = P.p_ref * ones(1,2);
else
    P.p_ref   = PREF;
end

[P] = define_parameters(data,P);

%% initialize vars - inner loop
win_j    = 1:(P.n_samples - P.lag*(P.m-1));
n_win_j  = floor((P.n_samples/P.m)-(P.m+1));

%% initialize matrices
E      = ones(2,P.n_it);
RECm   = zeros(2,P.n_it,n_win_j);
HITm   = zeros(2,P.n_it);
SLm    = zeros(2,P.n_it);
D_sort = zeros(2,P.n_it,n_win_j);
D      = zeros(2,P.n_it,n_win_j);

%%
c_c_i   = 0;
for c_i = 1:(P.n_samples - P.lag*(P.m-1))
    disp(c_i)
    if mod(c_i, P.speed) == 0
        
        c_c_i = c_c_i + 1;
        
        % determine the valid j times, P.w1<|i-j|<P.w2
        valid_range = abs(c_i-win_j) > P.w1 & abs(c_i-win_j) < P.w2; % vector of valid range positions
        start = find(valid_range,1,'first');
        stop =  find(valid_range,1,'last');
        valid_range(1:length(valid_range)) = 0;
        
        for k = start:P.m:stop % P.m = P.speed of win_j
            valid_range(k) = 1;
        end
        
        valid_range(c_i) = 0;
        n_valid_js = sum(valid_range); % number of valid range positions
        
        if n_valid_js == 0
            continue
        end
        
        % construct compressed table of euclidean distances
        c_c_j = 0; %counter
        for c_j = 1:(P.n_samples - P.lag*(P.m-1))
            
            if valid_range(c_j)
                c_c_j = c_c_j + 1;
                
                for chan = 1 : 2
                    data_i = data(c_i + P.lag * (0:(P.m-1)), chan);
                    data_j = data(c_j+P.lag*(0:(P.m-1)),chan);
                    dwin_i_j = abs(data_i - data_j);
                    
                    D(chan,c_c_i,c_c_j) = sum(dwin_i_j);
                end %for chan
                
            end %if valid range
            
        end %for c_j
        
        if length(P.p_ref) == 1 && P.p_ref < (1/n_valid_js)
            
            fprintf(2,'WARNING: 1/valid J`s < P.p_ref (%.3f < %.3f)\n',P.p_ref,1/n_valid_js);
            fprintf(2,'         Values will be set to zero.\n');
            RECm(:,c_c_i,:) = 0;
            HITm(:,c_c_i) = 0;
            SLm(:,c_c_i) = 0;
            
            continue
            
        end
        
        % E(k): the actual threshold distance such that the fraction
        % of all distances |x_{k,i} - x_{k,j}| less than E(k) is P.p_ref
        
        D_sort(1,c_c_i,1:n_valid_js) = sort(D(1,c_c_i,1:n_valid_js));
        
        E(1,c_c_i) = D_sort(1,c_c_i,ceil(P.p_ref(1) * n_valid_js));
        
        D_sort(2,c_c_i,1:n_valid_js) = sort(D(2,c_c_i,1:n_valid_js));
        
        E(2,c_c_i) = D_sort(2,c_c_i,ceil(P.p_ref(2) * n_valid_js));
        
        
% construct output
        
        % first channel X | Y
        RECm_tmp = squeeze(D(1,c_c_i,1:n_valid_js))' <= ...
            (E(1,c_c_i) * ones(1,n_valid_js));
        
        RECm_tmp = double(RECm_tmp); %matlab 6.5
        
        RECm(1,c_c_i,1:size(RECm_tmp,2)) = RECm_tmp;
        
        % then channel Y | X
        RECm_tmp = squeeze(D(2,c_c_i,1:n_valid_js))' <= ...
            (E(2,c_c_i) * ones(1,n_valid_js));
        
        RECm_tmp = double(RECm_tmp); %matlab 6.5
        
        RECm(2,c_c_i,1:size(RECm_tmp,2)) = RECm_tmp;
        
        % calculate hits in X | Y and Y | X
        RECx_tmp = squeeze(RECm(1,c_c_i,1:size(RECm_tmp,2)))';
        RECy_tmp = squeeze(RECm(2,c_c_i,1:size(RECm_tmp,2)))';
        
        HITm(1,c_c_i) = RECx_tmp * RECy_tmp';
        HITm(2,c_c_i) = RECy_tmp * RECx_tmp';
        
        n_RECx_tmp = diag(RECx_tmp * RECx_tmp');
        n_RECy_tmp = diag(RECy_tmp * RECy_tmp');
        SLm(1,c_c_i) = (RECx_tmp * RECy_tmp') / n_RECx_tmp;
        SLm(2,c_c_i) = (RECy_tmp * RECx_tmp') / n_RECy_tmp;
        
    end
    
end

end %function