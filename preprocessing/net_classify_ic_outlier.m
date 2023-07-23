function [outlier_channels,outx] = net_classify_ic_outlier(A, rel_thres)
% Description: checks the ratio of the powers in the re-ordered component
%   step 1: order the components with highest power
%   setp 2: find out the ratio of the weights of each component across its two most top channels
% QL, 21.04.2015

[nchan,Nc]=size(A);

power = sum(A.^2,1)/nchan;
            
[~,order] = sort(power,'descend');  %order the components with highest power, will be easier to threshold later on..
  
    
A=A(:,order); %only the columns are reordered, as we put the ICs with high power in front..

outx=zeros(1,Nc);

for i=1:Nc
    [vt,order]=sort(abs(A(:,i)),'descend');
    outx(i) = vt(1)/vt(2) ; %Find out the ratio of the weights of each component across its two most top channels..
end

outlier_channels=find(outx>rel_thres);
