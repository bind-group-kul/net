function datablock_samples = getDatablock_samples_number(lenaTree)
% function datablock_samples_number = getDatablock_samples_number(lenaTree)
%
%   Get the datablock sample number
%
% Input :
%   lenaTree ( lenaTree object )
%
% Output :
%   datablock_samples_number ( double ) : datablock sample number
%

% Get the children ids :
child = children( lenaTree , root(lenaTree) );

% Get the children names :
names = get( lenaTree , child , 'name' );

% Find the description id :
descriptionId = child(find(strcmp(names,'description')));

% Check the  child was found :
if isempty( descriptionId )
    error( 'Can t find any description parameter in the file' )
    return
end

% Get the description elements :
descriptionElements = children( lenaTree , descriptionId );


% Get the description children names :
names = get( lenaTree , descriptionElements , 'name' );

% Find the datablock_range id :
datablock_rangeId = descriptionElements(find(strcmp(names,'datablock_range')));

% Check the  child was found :
if isempty( datablock_rangeId )
    warning( 'Can t find any datablock_range parameter in the file' )
    datablock_samples_number = '';
    return
end

% Get the datablock_range elements :
datablock_rangeElements = children( lenaTree , datablock_rangeId );

% Get the datablock_range children names :
names = get( lenaTree , datablock_rangeElements , 'name' );

% Find the datablock_samples id :
datablock_samplesId = datablock_rangeElements(find(strcmp(names,'datablock_samples')));

% Check the  child was found :
if isempty( datablock_samplesId )
    warning( 'Can t find any datablock_samples parameter in the file' )
    datablock_samples_number = '';
    return
end

% Get the datablock_samples content:
datablock_samples = get( lenaTree , datablock_samplesId , 'contents' );

% Get the datablock_samples contents size :
%datablock_samples_number = length( datablock_samplesContents );


return