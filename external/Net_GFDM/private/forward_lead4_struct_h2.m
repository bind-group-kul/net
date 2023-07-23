% forward_lead4_struct_h2.m
% Ernesto Cuartas M (ECM), 24/04/2017
% Email:  ecuartasmo@unal.edu.co

function Pot = forward_lead4_struct_h2(Matrix,Source,H,label)
i=Source(1);
j=Source(2);
k=Source(3);

xb=floor(i);
yb=floor(j);
zb=floor(k);

sizehead=size(H);

Pot=zeros(size(Matrix.pots,2),3);
 
  A=[xb,yb,zb,1;...
    xb-1,yb,zb,1;...
    xb,yb+1,zb,1;...
    xb,yb,zb+1,1;...
    xb-1,yb+1,zb,1;...
    xb-1,yb,zb+1,1;...
    xb,yb+1,zb+1,1;...
    xb-1,yb+1,zb+1,1];

  tmp1=getpot2(Matrix,xb,yb,zb,sizehead);
  tmp2=getpot2(Matrix,xb+1,yb,zb,sizehead);
  tmp3=getpot2(Matrix,xb,yb+1,zb,sizehead);
  tmp4=getpot2(Matrix,xb,yb,zb+1,sizehead);
  tmp5=getpot2(Matrix,xb+1,yb+1,zb+1,sizehead);
  
  B = tmp1;
  if check_surrounded(H,xb-1,yb,zb,label)==0
     B=[B; 2*tmp1-tmp2]; 
  else
  B=[B; getpot2(Matrix,xb-1,yb,zb,sizehead)];  
  end
  B=[B; tmp3];
  B=[B; tmp4];
  if check_surrounded(H,xb-1,yb+1,zb,label)==0
     B=[B; 2*tmp3-getpot2(Matrix,xb+1,yb+1,zb,sizehead)]; 
  else
    B=[B; getpot2(Matrix,xb-1,yb+1,zb,sizehead)];  
  end
  if check_surrounded(H,xb-1,yb,zb+1,label)==0
    B=[B; 2* tmp4- getpot2(Matrix,xb+1,yb,zb+1,sizehead)];
  else
    B=[B; getpot2(Matrix,xb-1,yb,zb+1,sizehead)];
  end
  B=[B; getpot2(Matrix,xb,yb+1,zb+1,sizehead)];
  if check_surrounded(H,xb-1,yb+1,zb+1,label)==0
      B=[B; 2* getpot2(Matrix,xb,yb+1,zb+1,sizehead)- tmp5];
  else
      B=[B; getpot2(Matrix,xb-1,yb+1,zb+1,sizehead)];
  end
  
  V1=B(2,:)+(B(1,:)-B(2,:))*(i-xb);
  V2=B(5,:)+(B(3,:)-B(5,:))*(i-xb);
  V3=V1+(V2-V1)*(j-yb);
  
  V4=B(6,:)+(B(4,:)-B(6,:))*(i-xb);
  V5=B(8,:)+(B(7,:)-B(8,:))*(i-xb);
  V6=V4+(V5-V4)*(j-yb);

  x_min=V3+(V6-V3)*(k-zb);  
 
 
  A=[xb+1,yb,zb,1;...
    xb+2,yb,zb,1;...
    xb+1,yb+1,zb,1;...
    xb+1,yb,zb+1,1;...
    xb+2,yb+1,zb,1;...
    xb+2,yb,zb+1,1;...
    xb+1,yb+1,zb+1,1;...
    xb+2,yb+1,zb+1,1];

  if check_surrounded(H,xb+1,yb,zb,label)==0
    B=[2*tmp1-getpot2(Matrix,xb-1,yb,zb,sizehead)];
  else
    B=[tmp2];
  end
  if check_surrounded(H,xb+2,yb,zb,label)==0
    B=[B; 2*tmp2-tmp1];
  else
    B=[B; getpot2(Matrix,xb+2,yb,zb,sizehead)];
  end
  if check_surrounded(H,xb+1,yb+1,zb,label)==0
    B=[B; 2*tmp3-getpot2(Matrix,xb-1,yb+1,zb,sizehead)];
  else
    B=[B; getpot2(Matrix,xb+1,yb+1,zb,sizehead)];
  end
  if check_surrounded(H,xb+1,yb,zb+1,label)==0
    B=[B; 2*tmp4-getpot2(Matrix,xb-1,yb,zb+1,sizehead)];
  else
    B=[B; getpot2(Matrix,xb+1,yb,zb+1,sizehead)];
  end
  if check_surrounded(H,xb+2,yb+1,zb,label)==0
    B=[B; 2*tmp2-tmp1];
  else
    B=[B; getpot2(Matrix,xb+2,yb+1,zb,sizehead)];
  end
  if check_surrounded(H,xb+2,yb,zb+1,label)==0
    B=[B; 2*getpot2(Matrix,xb+1,yb,zb+1,sizehead)-tmp4];
  else
    B=[B; getpot2(Matrix,xb+2,yb,zb+1,sizehead)];
  end
  if check_surrounded(H,xb+1,yb+1,zb+1,label)==0
    B=[B; 2*getpot2(Matrix,xb,yb+1,zb+1,sizehead)-getpot2(Matrix,xb-1,yb+1,zb+1,sizehead)];
  else
    B=[B; tmp5];
  end
  if check_surrounded(H,xb+2,yb+1,zb+1,label)==0
    B=[B; 2*tmp5-getpot2(Matrix,xb,yb+1,zb+1,sizehead)];
  else
    B=[B; getpot2(Matrix,xb+2,yb+1,zb+1,sizehead)];
  end
  
  V1=B(1,:)+(B(2,:)-B(1,:))*(i-xb);
  V2=B(3,:)+(B(5,:)-B(3,:))*(i-xb);
  V3=V1+(V2-V1)*(j-yb);
  
  V4=B(4,:)+(B(6,:)-B(4,:))*(i-xb);
  V5=B(7,:)+(B(8,:)-B(7,:))*(i-xb);
  V6=V4+(V5-V4)*(j-yb);

  x_max=V3+(V6-V3)*(k-zb);
 
  Pot(:,1)=x_max-x_min;
  % de y component
   A=[xb,yb,zb,1;...
    xb+1,yb,zb,1;...
    xb,yb-1,zb,1;...
    xb,yb,zb+1,1;...
    xb+1,yb-1,zb,1;...
    xb+1,yb,zb+1,1;...
    xb,yb-1,zb+1,1;...
    xb+1,yb-1,zb+1,1];
  B=[tmp1];
  B=[B; tmp2];
  if check_surrounded(H,xb,yb-1,zb,label)==0
    B=[B; 2*tmp1-tmp3];
  else
    B=[B; getpot2(Matrix,xb,yb-1,zb,sizehead)];
  end
  B=[B; tmp4];
  
  if check_surrounded(H,xb+1,yb-1,zb,label)==0
    B=[B; 2* tmp2- getpot2(Matrix,xb+1,yb+1,zb,sizehead)];
  else
    B=[B; getpot2(Matrix,xb+1,yb-1,zb,sizehead)];
  end
  B=[B ;getpot2(Matrix,xb+1,yb,zb+1,sizehead)];
  if check_surrounded(H,xb,yb-1,zb+1,label)==0
    B=[B; 2* tmp4- getpot2(Matrix,xb,yb+1,zb+1,sizehead)];
  else
    B=[B; getpot2(Matrix,xb,yb-1,zb+1,sizehead)];
  end
  if check_surrounded(H,xb+1,yb-1,zb+1,label)==0
    B=[B; 2* getpot2(Matrix,xb+1,yb,zb+1,sizehead)- tmp5];
  else
    B=[B;  getpot2(Matrix,xb+1,yb-1,zb+1,sizehead)];
  end
  
  V1=B(3,:)+(B(5,:)-B(3,:))*(i-xb);
  V2=B(1,:)+(B(2,:)-B(1,:))*(i-xb);
  V3=V1+(V2-V1)*(j-yb);
  
  V4=B(7,:)+(B(8,:)-B(7,:))*(i-xb);
  V5=B(4,:)+(B(6,:)-B(4,:))*(i-xb);
  V6=V4+(V5-V4)*(j-yb);
  y_min=V3+(V6-V3)*(k-zb);
  
 
   
   A=[xb,yb+1,zb,1;...
    xb+1,yb+1,zb,1;...
    xb,yb+2,zb,1;...
    xb,yb+1,zb+1,1;...
    xb+1,yb+2,zb,1;...
    xb+1,yb+1,zb+1,1;...
    xb,yb+2,zb+1,1;...
    xb+1,yb+2,zb+1,1];
  if check_surrounded(H,xb,yb+1,zb,label)==0
    B=[2*tmp1-getpot2(Matrix,xb,yb-1,zb,sizehead)];
  else
    B=[tmp3];
  end
  if check_surrounded(H,xb+1,yb+1,zb,label)==0
    B=[B; 2*tmp2-getpot2(Matrix,xb+1,yb-1,zb,sizehead)];
  else
    B=[B; getpot2(Matrix,xb+1,yb+1,zb,sizehead)];
  end
  if check_surrounded(H,xb,yb+2,zb,label)==0;
    B=[B; 2* tmp3- tmp1];
  else
    B=[B; getpot2(Matrix,xb,yb+2,zb,sizehead)];
  end
 
  B=[B; getpot2(Matrix,xb,yb+1,zb+1,sizehead)];
  if check_surrounded(H,xb+1,yb+2,zb,label)==0
    B=[B; 2* getpot2(Matrix,xb+1,yb+1,zb,sizehead)- tmp2];
  else
    B=[B; getpot2(Matrix,xb+1,yb+2,zb,sizehead)];
  end
  if check_surrounded(H,xb+1,yb+1,zb+1,label)==0
    B=[B; 2*getpot2(Matrix,xb+1,yb,zb+1,sizehead)-getpot2(Matrix,xb+1,yb-1,zb+1,sizehead)];
  else
    B=[B ;tmp5];
  end
  
  if check_surrounded(H,xb,yb+2,zb+1,label)==0
    B=[B; 2* getpot2(Matrix,xb,yb+1,zb+1,sizehead)- tmp4];
  else
    B=[B; getpot2(Matrix,xb,yb+2,zb+1,sizehead)];
  end
  
  if check_surrounded(H,xb+1,yb+2,zb+1,label)==0
    B=[B; 2* tmp5- getpot2(Matrix,xb+1,yb,zb+1,sizehead)];
  else
    B=[B;  getpot2(Matrix,xb+1,yb+2,zb+1,sizehead)];
  end
  V1=B(1,:)+(B(2,:)-B(1,:))*(i-xb);
  V2=B(3,:)+(B(5,:)-B(3,:))*(i-xb);
  V3=V1+(V2-V1)*(j-yb);
  
  V4=B(4,:)+(B(6,:)-B(4,:))*(i-xb);
  V5=B(7,:)+(B(8,:)-B(7,:))*(i-xb);
  V6=V4+(V5-V4)*(j-yb);
  y_max=V3+(V6-V3)*(k-zb);
  Pot(:,2)=y_max-y_min;
  
  % de z component
 
    A=[xb,yb,zb,1;...
    xb+1,yb,zb,1;...
    xb,yb+1,zb,1;...
    xb,yb,zb-1,1;...
    xb+1,yb+1,zb,1;...
    xb+1,yb,zb-1,1;...
    xb,yb+1,zb-1,1;...
    xb+1,yb+1,zb-1,1];
 
  
  B=[tmp1];
  B=[B ; tmp2];
  B=[B ; tmp3];
  if check_surrounded(H,xb,yb,zb-1,label)==0
    B=[B; 2*tmp1-tmp4];
  else
    B=[B ; getpot2(Matrix,xb,yb,zb-1,sizehead)];
  end
  B=[B ;getpot2(Matrix,xb+1,yb+1,zb,sizehead)];
  if check_surrounded(H,xb+1,yb,zb-1,label)==0
      B=[B; 2*tmp2-getpot2(Matrix,xb+1,yb,zb+1,sizehead)];
  else
      B=[B; getpot2(Matrix,xb+1,yb,zb-1,sizehead)];
  end
 if check_surrounded(H,xb,yb+1,zb-1,label)==0
    B=[B; 2* tmp3- getpot2(Matrix,xb,yb+1,zb+1,sizehead)];
  else
    B=[B; getpot2(Matrix,xb,yb+1,zb-1,sizehead)];
  end

 
  if check_surrounded(H,xb+1,yb+1,zb-1,label)==0
    B=[B; 2* getpot2(Matrix,xb+1,yb+1,zb,sizehead)- tmp5];
  else
    B=[B;  getpot2(Matrix,xb+1,yb+1,zb-1,sizehead)];
  end
  
  V1=B(4,:)+(B(6,:)-B(4,:))*(i-xb);
  V2=B(7,:)+(B(8,:)-B(7,:))*(i-xb);
  V3=V1+(V2-V1)*(j-yb);
  
  V4=B(1,:)+(B(2,:)-B(1,:))*(i-xb);
  V5=B(3,:)+(B(5,:)-B(3,:))*(i-xb);
  V6=V4+(V5-V4)*(j-yb);
  z_min=V3+(V6-V3)*(k-zb);
 
  
  

 
   
  A=[xb,yb,zb+1,1;...
    xb+1,yb,zb+1,1;...
    xb,yb+1,zb+1,1;...
    xb,yb,zb+2,1;...
    xb+1,yb+1,zb+1,1;...
    xb+1,yb,zb+2,1;...
    xb,yb+1,zb+2,1;...
    xb+1,yb+1,zb+2,1];
  if check_surrounded(H,xb,yb,zb+1,label)==0
    B=[2* tmp1- getpot2(Matrix,xb,yb,zb-1,sizehead)];
  else
    B=[tmp4];
  end
  if check_surrounded(H,xb+1,yb,zb+1,label)==0
    B=[B ; 2* tmp2- getpot2(Matrix,xb+1,yb,zb-1,sizehead)];
  else
    B=[B ; getpot2(Matrix,xb+1,yb,zb+1,sizehead)];
  end
  if check_surrounded(H,xb,yb+1,zb+1,label)==0
    B=[B ; 2* tmp3- getpot2(Matrix,xb,yb+1,zb-1,sizehead)];
  else
    B=[B ; getpot2(Matrix,xb,yb+1,zb+1,sizehead)];
  end
  if check_surrounded(H,xb,yb,zb+2,label)==0
    B=[B ; 2* tmp4- tmp1];
  else
    B=[B ; getpot2(Matrix,xb,yb,zb+2,sizehead)];
  end
  if check_surrounded(H,xb+1,yb+1,zb+1,label)==0
    B=[B ; 2* getpot2(Matrix,xb+1,yb+1,zb,sizehead)- getpot2(Matrix,xb,yb,zb-1,sizehead)];
  else
    B=[B ; tmp5];
  end
 
  if check_surrounded(H,xb+1,yb,zb+2,label)==0
    B=[B; 2* getpot2(Matrix,xb+1,yb,zb+1,sizehead)- tmp2];
  else
    B=[B; getpot2(Matrix,xb+1,yb,zb+2,sizehead)];
  end

  if check_surrounded(H,xb,yb+1,zb+2,label)==0
    B=[B; 2* getpot2(Matrix,xb,yb+1,zb+1,sizehead)- tmp3];
  else
    B=[B; getpot2(Matrix,xb,yb+1,zb+2,sizehead)];
  end

  if check_surrounded(H,xb+1,yb+1,zb+2,label)==0
    B=[B; 2* tmp5- getpot2(Matrix,xb+1,yb+1,zb,sizehead)];
  else
    B=[B;  getpot2(Matrix,xb+1,yb+1,zb+2,sizehead)];
  end
  
  V1=B(1,:)+(B(2,:)-B(1,:))*(i-xb);
  V2=B(3,:)+(B(5,:)-B(3,:))*(i-xb);
  V3=V1+(V2-V1)*(j-yb);
  
  V4=B(4,:)+(B(6,:)-B(4,:))*(i-xb);
  V5=B(7,:)+(B(8,:)-B(7,:))*(i-xb);
  V6=V4+(V5-V4)*(j-yb);
  z_max=V3+(V6-V3)*(k-zb); 
  
  Pot(:,3)=z_max-z_min;