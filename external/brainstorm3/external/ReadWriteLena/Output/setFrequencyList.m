function tree = setFrequencyList(tree, frequencyList)
%% function setFrequencySample(tree,frequencySamplesArray)
%
%   Insert frequency list values inside a xml tree, which will be used for
%   lena datas.
%
% Inputs :
%
%   - tree : an xmltree element
%   - frequencyList (float ) : frequency list values
%   
% Ouptputs :
%
%   - tree : xmltree with added informations
%
% See also : createSimpleLENA, insertSimpleElements,deleteLENAelement,copyLENAelement
%
%
% Lydia Yahia  18 02 2008
%
% LENA CNRS UPR640
%


% Get the children ids :
child = children( tree , root(tree) );

% Get the children names :
names = get( tree , child , 'name' );

% Find the description id :
descriptionId = child(find(strcmp(names,'description')));

% Check the  child was found :
if isempty( descriptionId )
      [tree, descriptionId] = add( tree, root(tree), 'element', 'description' );
end

% Get the description elements :
descriptionElements = children(tree , descriptionId );


% Get the description children names :
names = get( tree , descriptionElements , 'name' );

% Find the frequency_range id :
frequency_rangeId = descriptionElements(find(strcmp(names,'frequency_range')));

% Check the  child was found :
if isempty( frequency_rangeId )
      [tree, frequency_rangeId] = add(tree, descriptionId, 'element', 'frequency_range' );
end

% Get the frequency_range elements :
frequency_rangeElements = children( tree ,  frequency_rangeId);

% Get the frequency_range children names :
names = get( tree , frequency_rangeElements , 'name' );

% Find the frequency_samples id :
frequency_listId = frequency_rangeElements(find(strcmp(names,'frequency_list')));

% Check the  child was found :
if isempty( frequency_listId )
          [tree, frequency_listId] = add(tree, frequency_rangeId, 'element', 'frequency_list' );
end



for cp=1:length(frequencyList)
    
          [tree, frequencylist_id] = add(tree, frequency_listId, 'element', 'frequency' );
          c=num2str(frequencyList(cp));
          tree = add( tree, frequencylist_id, 'chardata',  c);
            
   
end



return
