function [outlier,normal,Q1,Q3] = net_tukey(x,k,flag)

if nargin<3
    flag = 'both';
end

Q1=prctile(x,25);

Q3=prctile(x,75);

range=Q3-Q1;

switch flag
    
    case 'both'
    vect=(x<Q1-k*range | x>Q3+k*range);

    case 'low'
    vect=(x<Q1-k*range);
    
    case 'high'
    vect=(x>Q3+k*range);
end

outlier=find(vect);

normal=find(not(vect));

end