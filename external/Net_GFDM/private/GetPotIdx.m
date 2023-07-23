% SetStiffnessMatrix.m
% Ernesto Cuartas M (ECM), 24/04/2017
% Email:  ecuartasmo@unal.edu.co

function Pot = GetPotIdx(lead,x,y,z)

ind = lead.c_idx(x, y, z);
if ind == 0
    Pot = zeros(1,size(lead.pots,2));
else
    Pot = lead.pots(ind,:);
end

% sizehead = size(lead.mri.seg);
% sizehead=sizehead+[1 1 1];
% ind2=sub2ind(sizehead,x,y,z);
% indpot2=lead.indexes(ind2);
% if indpot2==0
%     potvalue=zeros(1,size(lead.pots,2));
% else
%     potvalue=lead.pots(indpot2,:);
% end
% isequal(Pot, potvalue)