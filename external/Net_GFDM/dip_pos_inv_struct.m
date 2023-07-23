function f = dip_pos_inv_struct(Source,Pot,lead,Ai,label)

i=(floor(real(Source(1))));
j=(floor(real(Source(2))));
k=(floor(real(Source(3))));
%fprintf('%f %f %f\n',i,j,k);
nel=size(Pot,1);
[x y z] = size(lead.vol.box.anatomy);
% label=max(H(:))-2; % CSF label
if i<3 
    i=3;
end
if j<3
    j=3;
end
if k<3
    k=3;
end

if i>x-2
    i=x-2;
end
if j>y-2
    j=y-2;
end
if k>z-2
    k=z-2;
end

if (check_surrounded_GM(lead.vol.box.anatomy,i,j,k,label))
    Source = [i j k];
    C   = TriLinIterpolationPots(lead,Source);
    C   = -Ai*[C;0 0 0];
    psC = (C'*C)^(-1)*C';
    out = ((eye(nel)-C*psC)*Pot);
    f   = sqrt((norm(out,'fro'))^2/(norm(Pot,'fro'))^2);
else
    f = 1000;
end

