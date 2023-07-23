function [tscore,pval] = net_ttest( imgs )



[xdim,ydim,zdim,nsubj]=size(imgs);

imgs=reshape(imgs,xdim*ydim*zdim,nsubj);

%imgs(isnan(imgs))=0;

%imgs(:,sum(imgs,1)==0)=[];

mask=find(sum(abs(imgs),2)>0);

tscore=zeros(xdim*ydim*zdim,1);
pval=zeros(xdim*ydim*zdim,1);


for i=1:length(mask)
    [~,p,~,stats] = ttest(imgs(mask(i),:));
    tscore(mask(i))=stats.tstat;
    pval(mask(i))=p;
end

tscore = reshape(tscore,xdim,ydim,zdim);
pval = reshape(pval,xdim,ydim,zdim);


end

