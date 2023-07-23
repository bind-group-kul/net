
function net_save_file(filename, sighilp_ds_norm, sigy, sigz)

% function: net_save_file(filename, sigx, sigy, sigz)
% descript: to save files in transparant way
%           especially for parallel cacluation
% Quanying Liu, 09.02.2015

if nargin<2
    error('Not enough inputs');
    
elseif nargin == 2
    save(filename, 'sighilp_ds_norm', '-append');
    
    
elseif nargin == 4
    save(filename, 'sigx', 'sigy', 'sigz');
    
else
    error('The number of inputs is wrong.');
    
end

end
