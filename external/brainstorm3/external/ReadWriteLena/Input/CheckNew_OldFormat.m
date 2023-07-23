function [fileName, New_Ver]=CheckNew_OldFormat(lena_file)
boolval=false;




% [pathstr, name, ext] = fileparts(char(filename));
% %k=strfind(filename,'.lena');
%  %if ~(isempty(k))
%  if strmatch(ext, '.lena', 'exact')
%     
%     %l=length(filename{1,1});
%     %if (l== k{1,1}+4)
%         boolval=true;
%     %end
%  end


New_Ver=false;
fileName=lena_file;

if isdir(lena_file)
    
header_file =dir (fullfile(lena_file, '/*.header'));
New_Ver=true;

if ~ isempty(header_file)

    data_file =dir (fullfile(lena_file, '/*.data'));
    lena_path=lena_file;
    fileName=fullfile(lena_path,header_file.name);
    
    if isempty(data_file)
       error('Data file name doesn t seem to exist, or is not a valid object')
       return;
    end
    
else   error('Header file name doesn t seem to exist, or is not a valid object')
    return;

end

end



end








