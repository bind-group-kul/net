function L = net_leadfield_fns(vol, dip)

% 
% fns_leadfield is a function that compute the lead field matrix from the
% potential data obtained using Finite Different Method.
%
% L = fns_leadfield(forwardSolutions, row, col, slice)
%
% L:                Lead field matrix
% forwardSolutions: Forward solution data
% modelSizes:       Size of a volume image
% dipoles:          MRI coordinate locations of dipoles

% $Copyright (C) 2010 by Hung Dang$

% 3D model of a dipole used in FNS
% 
%          0
%          | 0
%          |/
%    0-----x-----0
%         /|
%        0 |
%          0
%
% 
dipoles = ft_warp_apply(inv(vol.transform), dip);
dipoles = round(dipoles);

transfer = vol.transfer;
compress = vol.compress;

ROW = vol.segdim(1) + 1;
COL = vol.segdim(2) + 1;

[M, N] = size(transfer);
[numberOfDipoles, ~] = size(dipoles); 

% Allocate memory for lead field matrix
L = zeros(M, numberOfDipoles * 3);

% Compute lead field matrices for dipoles
for dipoleIdx = 1:numberOfDipoles    
    % Add 1 to convert between MATLAB index and C index
    nnode = dipoles(dipoleIdx, 1) + ...
            dipoles(dipoleIdx, 2) * ROW + ...
            dipoles(dipoleIdx, 3) * COL * ROW + 1; 

    % Compute the lead field matrix for the given node
    if ( nnode <= max(compress) )
        head_x = compress(nnode + 1);
        tail_x = compress(nnode - 1);
        head_y = compress(nnode + ROW);
        tail_y = compress(nnode - ROW);
        head_z = compress(nnode + COL * ROW);
        tail_z = compress(nnode - COL * ROW);
        
        % Extract the lead field matrix for x, y and z component
        L(:, dipoleIdx * 3 - 2) = transfer(:,head_x) - transfer(:,tail_x);
        L(:, dipoleIdx * 3 - 1) = transfer(:,head_y) - transfer(:,tail_y);
        L(:, dipoleIdx * 3)     = transfer(:,head_z) - transfer(:,tail_z);

       % L = transfer(:,[head_x,head_y,head_z]) - transfer(:,[tail_x,tail_y,tail_z]);
    else
        error('FNS:InvalidDipoleLocations', ...
              sprintf(['Dipoles(%d) at (%d, %d, %d) does not belong to the head model. ', ...
                       'You cannot compute lead field for this dipole.'], ...
                      dipoleIdx, ...
                      dipoles(dipoleIdx, 1), ...
                      dipoles(dipoleIdx, 2), ...
                      dipoles(dipoleIdx, 3)));
    end
end