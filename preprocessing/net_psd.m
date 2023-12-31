function [Fxx,Pxx]=net_psd(data,NFFT,Fs,win,overlap,minMaxHz,flag)
% Visualizzazione del PSD dei dati
% nargin at least 6



over=round(NFFT-NFFT*(overlap/100));

%commento camillo ----------------------------
resolution=Fs/NFFT;
%maxHz=round(maxHz*(1/resolution)+1);
minMaxHz(1)=round(minMaxHz(1)*(1/resolution)+1);
minMaxHz(2)=round(minMaxHz(2)*(1/resolution)+1);

%commento fine --------------------------------

if(overlap==0)
    if ((nargin>=6)&(nargin<=7))
        [r,c]=size(data);
        
        j=1;
        for(i=1:r)
           % subplot(r/nCol,nCol,i);
            [Pxx(:,i),Fxx(:,i)]=psd(data(j,:),NFFT,Fs,window(win,NFFT),'NOVERLAP');
            if strcmpi(flag,'on')
            plot(Fxx(minMaxHz(1):minMaxHz(2),:),sqrt(Pxx(minMaxHz(1):minMaxHz(2),:)));
            end
            j=j+1;
            %pause;
        end
    end
end

if(overlap>0)
    if ((nargin>=6)&(nargin<=7))
        [r,c]=size(data);
        
        j=1;
        for(i=1:r)
            %subplot(r/nCol,nCol,i);
            [Pxx(:,i),Fxx(:,i)]=psd(data(j,:),NFFT,Fs,window(win,NFFT),over);
            if strcmpi(flag,'on')
            plot(Fxx(minMaxHz(1):minMaxHz(2),:),sqrt(Pxx(minMaxHz(1):minMaxHz(2),:)));
            end
            j=j+1;
            %pause;
        end
    end
end