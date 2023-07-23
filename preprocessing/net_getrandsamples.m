%% Purpose -- Perform Source reconstruction based on a subsample of the data
% 1. Select a set of random samples from the data
%%
function samples_sel = net_getrandsamples(samples,ntp_sel,modality)

if nargin < 3
    
    modality = 'homogeneous';
    
end

ntp=length(samples);

if ntp > ntp_sel 
    
    switch modality
        
        case 'random'
            
            vect=randperm(ntp);
            
            samples_sel=samples(sort(vect(1:ntp_sel)));
                  
            
        case 'homogeneous'
            
            step = ntp/ntp_sel;
            
            samples_sel=samples(round(1:step:ntp));     
            
    end
    
else
    
    samples_sel=samples;
    
    disp('warning: the number of samples is too low to select samples');
    
end

%%
% Revision history:
%{
2014-05-08 
    v0.1 Updated the initial version
    (Revision author : Sri).
   
%}
