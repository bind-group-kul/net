function tikhonov_par = net_tikhonov_estimate(leadfield,sigs,ntpsample)

% INPUTS: 
%leadfield: from forward solution, 
%sigs: clean data from channels exactly as would be entered to the source localisation function
%ntpsample: should be between 0 and 1; since it would be very time consuming and may crash the computer to estimate tikhonov
%parameter for each and every time point, a ratio of the whole time course should be chosen.


B=leadfield.leadfield(leadfield.inside);
nchan=size(B{1},1);
A=zeros(nchan,length(B));
for i=1:length(B)
    A(:,3*(i-1)+1:3*i)=B{i};
end

[U,s,V] = csvd(A);
numSamples = size(sigs,2);

ntp_sel=fix(numSamples*ntpsample);
samples=[1:numSamples];

datasub = sigs(:, net_getrandsamples(samples, ntp_sel,'homogeneous'));

lambda_gcv=zeros(1,size(datasub,2));

for ii=1:size(datasub,2)
    b=datasub(:,ii);
    [lambda_gcv(ii),G,reg_param]= net_gcv(U,s,b);
end
tikhonov_par=mean(lambda_gcv);
