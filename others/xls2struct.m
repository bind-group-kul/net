function s = xls2struct( varargin )
% Crea una estructura a partir de los datos de un archivo excel
%
%    La primera fila (del rango) contiene el nombre de los campos de la estructura, y
% los datos de cada columna deben ser del mismo tipo. Detecta
% automaticamente el numero de columnas y filas con datos, y el tipo de
% estos.

% Pablo Navarro Castillo
% pnavarrc@ing.puc.cl


switch nargin
   case 1
      filename = varargin{1};
      sheet    = 1;
      range    = 'A1:Z500';
   case 2
      filename = varargin{1};
      sheet    = varargin{2};
      range    = 'A1:Z500';
   case 3
      filename = varargin{1};
      sheet    = varargin{2};
      range    = varargin{3};
   otherwise
      error('Wrong number of arguments');
end

[NumXLS, TxtXLS, RawXLS] = xlsread( filename, sheet, range );

for i=1:size(RawXLS,2)
    for j=1:size(RawXLS,1)
    xy(j,i)=sum(isnan(RawXLS{j,i}));
    end
end

yvect=find(xy(1,:)==0);
xy=xy(2:end,yvect);
xvect=[1 1+find(prod(xy')==0)];

RawXLS=RawXLS(xvect,yvect);


HeadXLS = RawXLS(1, :);
DataXLS = RawXLS(2:end,:);

for i=1:length(HeadXLS)
    str=HeadXLS{i};
    pos=strfind(str,' ');
    str(pos)='_';
    pos=strfind(str,'-');
    str(pos)='_';
    HeadXLS{i}=str;
end

s = cell2struct(DataXLS, HeadXLS, 2);




