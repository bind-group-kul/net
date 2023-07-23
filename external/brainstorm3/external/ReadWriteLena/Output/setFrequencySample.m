function tree = setFrequencySample(tree, frequencySamplesArray)
%% function setFrequencySample(tree,frequencySamplesArray)
%
%   Insert frequency samples values inside a xml tree, which will be used for
%   lena datas.
%
% Inputs :
%
%   - tree : an xmltree element
%   - frequencySamplesArray (float ) : 2-Dim Array of frequency samples values
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
frequency_sampleId = frequency_rangeElements(find(strcmp(names,'frequency_samples')));

% Check the  child was found :
if isempty( frequency_sampleId )
          [tree, frequency_sampleId] = add(tree, frequency_rangeId, 'element', 'frequency_samples' );
end



size1= size(frequencySamplesArray,2);





for cp1=1:size1
    
            
          [tree, Superfrequency_id] = add(tree, frequency_sampleId, 'element', 'superfrequency' );
          size2= length(frequencySamplesArray{cp1});
          
          for cp2=1:size2
        
              [tree, frequencysample_id] = add(tree, Superfrequency_id, 'element', 'frequency' );
          c=num2str(frequencySamplesArray{cp2, cp1});
          tree = add( tree, frequencysample_id, 'chardata',  c);
          end
            
   
end



return
