function [B,C]=net_pulse_subtraction(A,varargin)
% Approach: C=A-B

% A: artifact epochs
% B: scan artifact template
% C: corrected signalsist endsignal

%Initialisation
if nargin>1,
    d=varargin{1};
    w=varargin{2};
    onset=varargin{3};
    artif=varargin{4};
end


B=zeros(size(A));
C=zeros(size(A));
normierung=zeros(1,size(A,2));

%baseline correction
%h=waitbar(0,'baseline correction');
    for j=1:size(A,2) 
       baseline_A(j)=mean(A(1:onset-1,j));
%       waitbar(j/size(A,2),h);
    end
    %close(h);
    
for g=1:size(A,2)
    A_base(:,g)=A(:,g)-baseline_A(g);
end


% creation of weighting matrix
k={};kkk=[];
for j=1:size(A,2);
    k{j}=[j-ceil((d-1)/2):j+floor((d-1)/2)];
    if j<=ceil((d-1)/2);
        k{j}=[1:d];
    end
    if size(A,2)-j<=floor((d-1)/2);
        k{j}=[(size(A,2)-d+1):size(A,2)];
    end


    % here the low-correlation artifact epochs are ignored!!!
    k{j}=setdiff(k{j},artif);
end

%h=waitbar(0,'Korrektur');


% artifact template subtraction
for j=1:size(A,2);
    B_fore=(w.^abs(k{j}-j))*A_base(:,k{j})';
    B(:,j)=B_fore';
    normierung(j)=sum(w.^abs(k{j}-j));
    B(:,j)=B(:,j)./normierung(j);
    C(:,j)=A(:,j)-B(:,j);
   % waitbar(j/size(A,2),h);
end
%close (h);
