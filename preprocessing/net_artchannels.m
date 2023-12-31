function ind = net_artchannels(this,art_labels)
% Return indices of MRI or BCG channels
% FORMAT ind = emgchannels(this)
%
%  this      - MEEG object
%  ind       - row vector of indices of EMG channels
%
% See also eogchannels, ecgchannels, meegchannels
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Christophe Phillips & Stefan Kiebel
% $Id: emgchannels.m 2884 2009-03-16 18:27:25Z guillaume $

type = chantype(this);

if nargin <2
    
    art_labels=[];
    
end

art_labels=[art_labels,{'MRI','BCG'}];

[ia,ib] = ismember(upper(type),upper(art_labels));

ind = find(ia);
%ind = ind(:)'; % must be row to allow to use it as loop indices
