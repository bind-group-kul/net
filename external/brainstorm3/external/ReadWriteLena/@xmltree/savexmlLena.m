function varargout = save(tree, filename)
% XMLTREE/SAVE Save an XML tree in an XML file
% FORMAT varargout = save(tree,filename)
%
% tree      - XMLTree
% filename  - XML output filename
% varargout - XML string
%_______________________________________________________________________
%
% Convert an XML tree into a well-formed XML string and write it into
% a file or return it as a string if no filename is provided.
%_______________________________________________________________________
% @(#)save.m                 Guillaume Flandin                 01/07/11
  
error(nargchk(1,2,nargin));

prolog = '<?xml version="1.0" ?>\n';
sid='';
%- Return the XML tree as a string
if nargin == 1
	varargout{1} = [sprintf(prolog) ...
		print_subtree(tree,'',root(tree))];
%- Output specified
else
	%- Filename provided
	if isstr(filename)
		[fid, msg] = fopen(filename,'w');
		if fid==-1, error(msg); end
		if isempty(tree.filename), tree.filename = filename; end
	%- File identifier provided
	elseif isnumeric(filename) & prod(size(filename)) == 1
		fid = filename;
		prolog = ''; %- With this option, do not write any prolog
	else
		error('[XMLTree] Invalid argument.');
	end
	fprintf(fid,prolog);
    %sprintf(sid,prolog);
    CR=true;
	save_subtree(tree,fid,root(tree), 0,CR);
	if isstr(filename), fclose(fid); end
	if nargout == 1
		varargout{1} = print_subtree(tree,'',root(tree));
	end
end
end

%=======================================================================
function xmlstr = print_subtree(tree,xmlstr,uid,order)
	if nargin < 4, order = 0; end
	xmlstr = [xmlstr blanks(3*order)];
	switch tree.tree{uid}.type
		case 'element'
			xmlstr = sprintf('%s<%s',xmlstr,tree.tree{uid}.name);
			for i=1:length(tree.tree{uid}.attributes)
				xmlstr = sprintf('%s %s="%s"', xmlstr, ...
					tree.tree{uid}.attributes{i}.key,...
					tree.tree{uid}.attributes{i}.val);
			end
			if isempty(tree.tree{uid}.contents)
				xmlstr = sprintf('%s/>\n',xmlstr);
			else
				xmlstr = sprintf('%s>',xmlstr);
				for i=1:length(tree.tree{uid}.contents)
					xmlstr = print_subtree(tree,xmlstr, ...
						tree.tree{uid}.contents(i),order+1);
  				end
				xmlstr = [xmlstr blanks(3*order)];
				xmlstr = sprintf('%s</%s>\n',xmlstr,...
					tree.tree{uid}.name);
			end
		case 'chardata'
			xmlstr = sprintf('%s%s',xmlstr, ...
				entity(tree.tree{uid}.value));
		case 'cdata'
			xmlstr = sprintf('%s<![CDATA[%s]]>',xmlstr, ...
				tree.tree{uid}.value);
		case 'pi'
			xmlstr = sprintf('%s<?%s %s?>',xmlstr, ...
				tree.tree{uid}.target, tree.tree{uid}.value);
		case 'comment'
			xmlstr = sprintf('%s<!-- %s -->',xmlstr,...
				tree.tree{uid}.value);
		otherwise
			warning(sprintf('Type %s unknown: not saved', ...
				tree.tree{uid}.type));
    end
end

%=======================================================================
function save_subtree(tree,fid,uid,order, CR)
	if nargin < 4, order = 0; end
    sid='';
	%fprintf(fid,blanks(3*order));
%    sprintf(sid,blanks(3*order));

	switch tree.tree{uid}.type
		case 'element'
            
			fprintf(fid,'<%s',tree.tree{uid}.name);
            test=tree.tree{uid}.name;
            sprintf(sid,'<%s',tree.tree{uid}.name);
           
			for i=1:length(tree.tree{uid}.attributes)
				fprintf(fid,' %s="%s"',...
				tree.tree{uid}.attributes{i}.key, ...
				tree.tree{uid}.attributes{i}.val);
            
                test1=tree.tree{uid}.attributes{i}.key;
                test2=tree.tree{uid}.attributes{i}.val;
                sprintf(sid,' %s="%s"',...
				tree.tree{uid}.attributes{i}.key, ...
				tree.tree{uid}.attributes{i}.val);
            end
            len_cont=length(tree.tree{uid}.contents);
            contents=get(tree,children(tree,uid));
			if isempty(tree.tree{uid}.contents) 
				fprintf(fid,'/>\n');
                sprintf(sid,'/>\n');
            else
                CR=testCR(contents);
                if (CR) 
				fprintf(fid,'>\n');
                else
                    fprintf(fid,'>');
                end
                %sprintf(sid,'>');
				for i=1:length(tree.tree{uid}.contents)
					save_subtree(tree,fid,...
						tree.tree{uid}.contents(i),order+1, CR)
  				end
				%fprintf(fid,blanks(3*order));
                
               % if (CR)
				%fprintf(fid,'</%s>',tree.tree{uid}.name);
                %else
                    fprintf(fid,'</%s>\n',tree.tree{uid}.name);
                %end
%                 sprintf(sid,blanks(3*order));
% 				sprintf(sid,'</%s>\n',tree.tree{uid}.name);
			end
		case 'chardata'
			fprintf(fid,'%s',entity(tree.tree{uid}.value));
            sprintf(sid,'%s',entity(tree.tree{uid}.value));
		case 'cdata'
				fprintf(fid,'<![CDATA[%s]]>\',tree.tree{uid}.value);
                sprintf(sid,'<![CDATA[%s]]>\',tree.tree{uid}.value);
		case 'pi'
			fprintf(fid,'<?%s %s?>\',tree.tree{uid}.target, ...
				tree.tree{uid}.value);
		case 'comment'
			fprintf(fid,'<!-- %s -->\',tree.tree{uid}.value);
		otherwise
			warning(sprintf('[XMLTree] Type %s unknown: not saved', ...
				tree.tree{uid}.type));
	end

end
%=======================================================================
function str = entity(str)
	str = strrep(str,'&','&amp;');
	str = strrep(str,'<','&lt;');
	str = strrep(str,'>','&gt;');
	str = strrep(str,'"','&quot;');
	str = strrep(str,'''','&apos;');
    
end  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%?
     
 function cr=testCR(sensorContents)
         
i=1;    
cr=true;
         
    if iscell(sensorContents)
       
        while (i<length(sensorContents)+1)
            if strcmp(sensorContents{i}.type,'chardata')
                    cr=false;
            break;
            end
         i=i+1;
            
        end
       
else  if strcmp(sensorContents.type,'chardata')
                   cr=false;
            
 end
end
end
