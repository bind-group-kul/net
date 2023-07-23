function lenaTree = setFrequencyList(lenaTree, frequencies)
% function frequencies = getfrequencies(lenaTree)
%
%   Get the frequencies
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   frequencies ( double ) : matrix of frequency samples
%

% Get the children ids :
%frequencies=[50 10 20];
lena_file='time_freq.lena';
lenaTree=createSimpleLENA(lena_file,'LittleEndian','float','4');
%if exist(lena_file)==2
%lenaTree=lenatree(lena_file);
child = children( lenaTree , root(lenaTree) );
%end
% Get the children names :
names = get( lenaTree , child , 'name' );

% Find the description id :
descriptionId = child(find(strcmp(names,'description')));

% Check the  child was found :
if isempty( descriptionId )
      [lenaTree, descriptionId] = add( lenaTree, root(lenaTree), 'element', 'description' );
else
    %warning( 'Can t find any description parameter in the file' )
    %frequencies = [];
    %return
   % description_id=children(descriptionId);
end

% Get the description elements :
descriptionElements = children( lenaTree , descriptionId );


% Get the description children names :
names = get( lenaTree , descriptionElements , 'name' );

% Find the time_samples id :
frequency_rangeId = descriptionElements(find(strcmp(names,'frequency_range')));

% Check the  child was found :
if isempty( frequency_rangeId )
      [lenaTree, frequency_rangeId] = add( lenaTree, descriptionId, 'element', 'frequency_range' );
%else
 %   error('Description already contains a sensor_range element, delete it before any new assignement');
    %return;
end
% Get the frequency_range elements :
frequency_rangeElements = children( lenaTree ,  frequency_rangeId);

% Get the frequency_range children names :
names = get( lenaTree , frequency_rangeElements , 'name' );

% Find the frequency_samples id :
frequency_listId = frequency_rangeElements(find(strcmp(names,'frequency_list')));

% Check the  child was found :
if isempty( frequency_listId )
          [lenaTree, frequency_listId] = add( lenaTree, frequency_rangeId, 'element', 'frequency_list' );
    %warning( 'Can t find any frequency_samples parameter in the file' )
    %frequencies=[];
    %return
end


% find frequencies, assuming each super frequency contains only 1
% frequency ( ie we search all chardata elements )


for cp=1:length(frequencies)
    
          [lenaTree, frequency_id] = add( lenaTree, frequency_listId, 'element', 'frequency' );
          c=num2str(frequencies(cp));
          lenaTree = add( lenaTree, frequency_id, 'chardata',  c);
            
   
end


% f=find(lenaTree, frequency_listId,'type','chardata');
% 
% frequencies_char = get(lenaTree,f,'value');
% frequencies = zeros(1,length(frequencies_char));
% for i=1:length(frequencies_char)
%     frequencies(i)=str2num(frequencies_char{i});
% end
save(lenaTree,lena_file);

return
