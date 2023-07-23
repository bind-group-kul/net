function datablocks = getDatablocks(lenaTree)
% function datablocks = getdatablocks(lenaTree)
%
%   Get the datablocks
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   datablocks ( double ) : matrix of datablock samples
%

% Get the children ids :
child = children( lenaTree , root(lenaTree) );

% Get the children names :
names = get( lenaTree , child , 'name' );

% Find the description id :
descriptionId = child(find(strcmp(names,'description')));

% Check the  child was found :
if isempty( descriptionId )
    warning( 'Can t find any description parameter in the file' )
    datablocks = [];
    return
end

% Get the description elements :
descriptionElements = children( lenaTree , descriptionId );


% Get the description children names :
names = get( lenaTree , descriptionElements , 'name' );

% Find the time_samples id :
datablock_rangeId = descriptionElements(find(strcmp(names,'datablock_range')));

% Check the  child was found :
if isempty( datablock_rangeId )
    warning( 'Can t find any datablock_range parameter in the file' )
    datablocks=[];
    return
end

% Get the datablock_range elements :
datablock_rangeElements = children( lenaTree ,  datablock_rangeId);

% Get the datablock_range children names :
names = get( lenaTree , datablock_rangeElements , 'name' );

% Find the datablock_samples id :
datablock_samplesId = datablock_rangeElements(find(strcmp(names,'datablock_samples')));

% Check the  child was found :
if isempty( datablock_samplesId )
    warning( 'Can t find any datablock_samples parameter in the file' )
    datablocks=[];
    return
end


% find datablocks, assuming each super datablock contains only 1
% datablock ( ie we search all chardata elements )

datablocks_sampleElements = children( lenaTree , datablock_samplesId );
datablocksContents=get(lenaTree,children(lenaTree,datablocks_sampleElements));
%datablocks_char = get(lenaTree,find(lenaTree, datablock_samplesId,'type','chardata'),'value');
%datablocks = zeros(1,length(datablocks_char));

%%%%%%%%%%%%%%%%%%%cas ou un seul datablock
% if iscell (datablocks_sampleElements)
%     for i=1:length(datablocks_sampleElements)
%     datablocks{i}=datablocks_sampleElements{i};
%     end
% else datablocks=datablocks_sampleElements;
% end


i=1;k=1;
if iscell(datablocksContents)
    while (i<length(datablocksContents)+1)
        if strcmp(datablocksContents{i}.type,'chardata')
                    datablocks{k}=datablocksContents{i}.value;
            k=k+1;
        
        end
        i=i+1;
    end
else  if strcmp(datablocksContents.type,'chardata')
                    datablocks=datablocksContents.value;
        
    end
end


return
