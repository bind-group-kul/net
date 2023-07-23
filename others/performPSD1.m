function [Fxx,Pxx]=performPSD1(data,NFFT,Fs,win,overlap,nCol,minMaxHz,nChan)
% Visualizzazione del PSD dei dati
% nargin at least 6
if nargin< 6
        help explorePSD1;
        return
end   

if nargin==6
     minMaxHz(1)=1;
     minMaxHz(2)=Fs/2;
end

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
            
            plot(Fxx(minMaxHz(1):minMaxHz(2),:),sqrt(Pxx(minMaxHz(1):minMaxHz(2),:)));
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
            
            plot(Fxx(minMaxHz(1):minMaxHz(2),:),sqrt(Pxx(minMaxHz(1):minMaxHz(2),:)));
            j=j+1;
            %pause;
        end
    end
end

if(overlap==0)    
    if (nargin==8)
        [r,c]=size(data);
       
        nTotChan=0;
        ii=0;
        
        j=1;
        while(nTotChan<r)
            for(i=1:nChan)
                ii=ii+1;
                if(ii>r) 
                 %   subplot(nChan/nCol,nCol,i); 
                    plot(0);
                else
                  %  subplot(nChan/nCol,nCol,i);
                    [Pxx(:,i),Fxx(:,i)]=psd(data(j,:),NFFT,Fs,window(win,NFFT),'NOVERLAP');
                    plot(Fxx(minMaxHz(1):minMaxHz(2),:),sqrt(Pxx(minMaxHz(1):minMaxHz(2),:)));
                    j=j+1;
                    %pause;
                end
                
            end
            nTotChan=nTotChan+nChan
            %fprintf('performpsd():Premi un tasto per continuare ...');
            %pause;
        end
    end        
end

if(overlap>0)    
    if (nargin==8)
        [r,c]=size(data);
       
        nTotChan=0;
        ii=0;
        
        j=1;
        while(nTotChan<r)
            for(i=1:nChan)
                ii=ii+1;
                if(ii>r) 
                   % subplot(nChan/nCol,nCol,i); 
                    plot(0);
                else
                    %subplot(nChan/nCol,nCol,i);
                    [Pxx(:,i),Fxx(:,i)]=psd(data(j,:),NFFT,Fs,window(win,NFFT),over);
                    plot(Fxx(minMaxHz(1):minMaxHz(2),:),sqrt(Pxx(minMaxHz(1):minMaxHz(2),:)));
                    j=j+1;
                end
                %pause;
            end
            nTotChan=nTotChan+nChan
            %fprintf('performpsd():Premi un tasto per continuare ...');
            %pause;
        end
    end        
end

