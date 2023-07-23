function  conn_value = net_blp_corr(X,Y,flag)
% X and Y is the power course from spectrogram
% 
% Reference: Hipp JF, Hawellek DJ, Corbetta M, Siegel M and Engel AK (2012). 
%   "Large-scale cortical correlation structure of spontaneous oscillatory 
%   activity." Nature Neuroscience 15(6): 884-890.
%
% Authors: Jessica Samogin & Dante Mantini
% Emails:  jessica.samogin@kuleuven.be & dante.mantini@kuleuven.be


nF = size(X,2);

conn_value=zeros(1,nF);

switch flag


    case 'symmetric'

        X_orth = imag( X.*conj(Y)./abs(Y) );  % X to Y
        Y_orth = imag( Y.*conj(X)./abs(X) );  % Y to X
    
        for f=1:nF
            s1x = X_orth(:,f).*conj(X_orth(:,f));
            s2x = Y_orth(:,f).*conj(Y_orth(:,f));
            s1x = log10(s1x+mean(s1x)/100);
            s2x = log10(s2x+mean(s2x)/100);
            conn_value(f) = atanh(corr(s1x,s2x)); 
        end
        
    case 'asymmetric'

        X_orth = imag( X.*conj(Y)./abs(Y) );  % X to Y
        Y_orth = imag( Y.*conj(X)./abs(X) );  % Y to X
    
        for f=1:nF
            s1  = X(:,f).*conj(X(:,f));
            s2  = Y(:,f).*conj(Y(:,f));
            s1x = X_orth(:,f).*conj(X_orth(:,f));
            s2x = Y_orth(:,f).*conj(Y_orth(:,f));
            s1  = log10(s1+mean(s1)/100);
            s2  = log10(s2+mean(s2)/100);
            s1x = log10(s1x+mean(s1x)/100);
            s2x = log10(s2x+mean(s2x)/100);
            conn_value(f) = atanh(corr(s1,s2x))/2 + atanh(corr(s1x,s2))/2;
        end
        
    otherwise
        
        for f=1:nF
            s1 = X(:,f).*conj(X(:,f));
            s2 = Y(:,f).*conj(Y(:,f));
            s1 = log10(s1+mean(s1)/100);
            s2 = log10(s2+mean(s2)/100);
            conn_value(f) = atanh(corr(s1,s2));    
        end
end