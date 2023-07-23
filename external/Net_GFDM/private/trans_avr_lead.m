% trans_avr_lead.m
% Ernesto Cuartas M (ECM), 24/04/2017
% Email:  ecuartasmo@unal.edu.co

function A=trans_avr_lead(B)
n=size(B,1);
A=zeros(n+1,n+1);
for i =1 : n
  A(i,B(i,1))=1;
  A(i,B(i,2))=-1;
  
end
A(n+1,:)=ones(1,n+1);
