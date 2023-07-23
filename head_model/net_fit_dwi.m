function [FA,ADC,Y]=net_fit_dwi(T)


[xdim,ydim,zdim,~]=size(T);

FA=zeros(xdim,ydim,zdim);
ADC=zeros(xdim,ydim,zdim);
Y=zeros(xdim,ydim,zdim,3);

X=sum(abs(T),4);

thres=0.01*max(X(:));

%cont=0;

%tic;

for x=1:xdim
    for y=1:ydim
        for z=1:zdim
            
            % Only process a pixel if it isn't background
            if X(x,y,z)>thres
                %cont=cont+1; disp(cont);
                M=squeeze(T(x,y,z,:));
                % The DiffusionTensor (Remember it is a symetric matrix,
                % thus for instance Dxy == Dyx)
                DiffusionTensor=[M(1) M(2) M(3); M(2) M(4) M(5); M(3) M(5) M(6)];
                DiffusionTensor=DiffusionTensor/abs(det(DiffusionTensor))^(1/3);
                
                % Calculate the eigenvalues and vectors, and sort the
                % eigenvalues from small to large
                [EigenVectors,D]=eig(DiffusionTensor); EigenValues=diag(D);
                [t,index]=sort(EigenValues);
                EigenValues=EigenValues(index); EigenVectors=EigenVectors(:,index);
                %  EigenValues_old=EigenValues;
                
                % Regulating of the eigen values (negative eigenvalues are
                % due to noise and other non-idealities of MRI)
                if((EigenValues(1)<0)&&(EigenValues(2)<0)&&(EigenValues(3)<0)), EigenValues=abs(EigenValues);end
                if(EigenValues(1)<=0), EigenValues(1)=eps; end
                if(EigenValues(2)<=0), EigenValues(2)=eps; end
                
                % Apparent Diffuse Coefficient
                ADCv=(EigenValues(1)+EigenValues(2)+EigenValues(3))/3;
                
                % Fractional Anistropy (2 different definitions exist)
                % First FA definition:
                %FAv=(1/sqrt(2))*( sqrt((EigenValues(1)-EigenValues(2)).^2+(EigenValues(2)-EigenValues(3)).^2+(EigenValues(1)-EigenValues(3)).^2)./sqrt(EigenValues(1).^2+EigenValues(2).^2+EigenValues(3).^2) );
                % Second FA definition:
                FAv=sqrt(1.5)*( sqrt((EigenValues(1)-ADCv).^2+(EigenValues(2)-ADCv).^2+(EigenValues(3)-ADCv).^2)./sqrt(EigenValues(1).^2+EigenValues(2).^2+EigenValues(3).^2) );
                
                % Store the results of this pixel in the volume matrices
                
                FA(x,y,z)=FAv;
                ADC(x,y,z)=ADCv;
                Y(x,y,z,:)=EigenValues;
            end
        end
    end
end


%toc;