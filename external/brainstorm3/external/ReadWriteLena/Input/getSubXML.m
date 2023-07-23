function [subxmlstring,k] = getSubXML(xmlstring, tag)

subxmlstring='';
k='';
xmlstring=normalize(xmlstring);
k1=findstr(xmlstring, strcat('<',tag));
k2=findstr(xmlstring, strcat('</',tag,'>'));
if ~ isempty(k1) & ~ isempty(k2) 
subxmlstring=xmlstring(k1: k2+length(tag)+2);
k=k1(1);
else
warning( 'Can t find the specified tag  in the file' )

end 
end




function str = normalize(str)
	% Find white characters (space, newline, carriage return, tabs, ...)
	i = isspace(str);
	i = find(i == 1);
	str(i) = ' ';
	% replace several white characters by only one
	if ~isempty(i)
		j = i - [i(2:end) i(end)];
		k = find(j == -1);
		str(i(k)) = [];
    end
end