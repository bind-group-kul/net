function Path_str = net_getpath(str)

elements=strread(path,'%s','delimiter', pathsep);
ispresent = cellfun(@(s) ~isempty(strfind(s,str)), elements);
index=find(ispresent);
if not(isempty(index))
Path_str=elements{index(1)};
else
    Path_str=[];
end
