function tree = setFrequencySamples(tree, frequencySamplesArray)
%% function setfrequencySample(tree,frequencySamplesArray)
%
%   Insert frequency samples values inside a xml tree, which will be used for
%   lena data.
%
% Input :
%
%   - tree : an xmltree element
%   - frequencySamplesArray (float ) : 2-Dim Array of frequency samples values
%   
% Ouptput :
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







%l=size(frequencySamplesArray,1);


for cp1=1:length(frequencySamplesArray)
    
            
          [tree, Superfrequency_id] = add(tree, frequency_sampleId, 'element', 'superfrequency' );
%           if  ~isempty(frequencySamplesArray.unit)
%               %if   (length(frequencySamplesArray.unit)>=cp1)
%                %  if  (frequencySamplesArray.unit{cp1,2} ==cp1)
%                     unit=frequencySamplesArray.unit{cp1};
%                       tree = attributes(tree,'add',Superfrequency_id,'unit',unit);
%              %end
%               %end
%           end
% 
%             if   ~isempty(frequencySamplesArray.scale)
% 
%            %   if (length(frequencySamplesArray.scale)>=cp1)
%               %if (frequencySamplesArray.scale{cp1,2} ==cp1)
%                   scale=num2str(frequencySamplesArray.scale{cp1});
%                 tree = attributes(tree,'add',Superfrequency_id,'scale',scale);
%               %end
%             %end
%             end


%in=frequencySamplesArray.list_frequencies(cp1,:);
%in=size(frequencySamplesArray.list_frequencies(cp1,:))
if ~isempty(frequencySamplesArray)

            for cp2=1:length(frequencySamplesArray(cp1,:));

        
                [tree, frequency_id] = add(tree, Superfrequency_id, 'element', 'frequency' );
                b=frequencySamplesArray(cp1,cp2);
                if iscell(b)
                   b= cell2mat(b);
                end
                c=num2str(b);
                tree = add( tree, frequency_id, 'chardata',  c);
          end
            
end
end



return

end
