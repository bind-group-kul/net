% SetStiffnessMatrix.m
% Ernesto Cuartas M (ECM), 24/04/2017
% Email:  ecuartasmo@unal.edu.co

function potvalue=getpot2(lead,x,y,z,sizehead)

sizehead=sizehead+[1 1 1];
ind=sub2ind(sizehead,x,y,z);
indpot=lead.indexes(ind);
if indpot==0
    potvalue=zeros(1,size(lead.pots,2));
else
    potvalue=lead.pots(indpot,:);
end