function tree = setDataBlockSamples(tree, datablockSamples)
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
datablock_rangeId = descriptionElements(find(strcmp(names,'datablock_range')));

% Check the  child was found :
if isempty( datablock_rangeId )
      [tree, datablock_rangeId] = add(tree, descriptionId, 'element', 'datablock_range' );
end

% Get the frequency_range elements :
datablock_rangeElements = children( tree ,  datablock_rangeId);

% Get the frequency_range children names :
names = get( tree , datablock_rangeElements , 'name' );

% Find the frequency_samples id :
datablock_sampleId = datablock_rangeElements(find(strcmp(names,'datablock_samples')));

% Check the  child was found :
if isempty( datablock_sampleId )
          [tree, datablock_sampleId] = add(tree, datablock_rangeId, 'element', 'datablock_samples' );
end


if ~ iscell(datablockSamples) 
         [tree, datablock_trialId] = add(tree, datablock_sampleId, 'element', 'trial' );
          c=datablockSamples;
          tree = add( tree, datablock_trialId, 'chardata',  c);
    
else
for cp=1:length(datablockSamples)
    
          [tree, datablock_trialId] = add(tree, datablock_sampleId, 'element', 'trial' );
           a=size(datablockSamples);
           if a(1)==length(datablockSamples)
          c=datablockSamples{cp,1};
           else 
               c=datablockSamples{1,cp};
           end
          tree = add( tree, datablock_trialId, 'chardata',  c);
            
   
end
end


return
