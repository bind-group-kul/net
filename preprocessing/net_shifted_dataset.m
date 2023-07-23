function DatShift=net_shifted_dataset(Data,varargin)
%% Creates a 3D matrix with shifted copies of the same dataset.
% Input arguments
% Data, NxM double matrix. Data matrix
% 
%  'lag', [4] integer number of samples. The datasets are lagged by this
%               quantity.
%          
%  'Nshifts', [5]  integer numbers of lagged copies. 
%
%
%   Output:
%   DatShift, NxMxNshifts double matrix. Lagged data matrix.
%  Usage: 
%   
%   DatShift=GetShiftedDataset(Data,'lag',4,'Nshifts',5);

lag=4;
Nshifts=5;

if mod(nargin-1,2)
    error('Even arguments number, please');
end

for i=1:2:(nargin-1)
    switch varargin{i}
        case 'lag'
            lag=varargin{i+1};
        case 'Nshifts'
            Nshifts=varargin{i+1};
    end
end

DatShift=zeros([size(Data)-[0,lag*(Nshifts)],Nshifts]);
for j=1:Nshifts
    lagI=lag*(j-1);
    lagE=lag*(Nshifts-j+1);
    DatShift(:,:,j)=Data(:,1+lagI:end-lagE);
end