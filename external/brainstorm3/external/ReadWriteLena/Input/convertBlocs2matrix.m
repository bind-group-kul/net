function mat = convertBlocs2matrix(echantillons, dimensions)
% function mat = convertBlocs2matrix(echantillons, dimensions)
%
%   Function to convert data block cells in echantillons to matrix with
%   dimensions provided in "dimensions" ( cf LENA data format )
%
% Inputs :
%   - echantillons ( cells ) : datas stored in cells
%   - dimensions ( doublle array ) : dimensions of output matrix with
%   re-organised datas
%
% Ouputs :
%   - mat ( double array ) : matrix with dimensions precised by
%   "dimensions" and containing datas from echantillons
%

mat = zeros(flipdim(dimensions,2));
index = 1;

tb=waitbar(0,'Convert samples to matrix');

for i = 1 : length(echantillons)
    mat(index:index+length(echantillons{i})-1)=echantillons{i};
    index=index+length(echantillons{i});
    waitbar(i/length(echantillons),tb);
end

close(tb);

mat=permute(mat,flipdim([1:length(dimensions)],2));

return
