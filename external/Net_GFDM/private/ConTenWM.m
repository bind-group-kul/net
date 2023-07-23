function tensr = ConTenWM(DTI, eigv, cond_iso)

if(sum(DTI(:)) == 0)
    tensr = cond_iso*eye(3);
else    
    [evc, eva] = eig(DTI);
    Vx = evc(:,1);
    Vy = evc(:,2);
    Vz = evc(:,3);
    eva_v = diag(eva);
    if(eva_v(1)<0)
        Vx = -1*Vx;
    end
    if(eva_v(2)<0)
        Vy = -1*Vy;
    end
    if(eva_v(3)<0)
        Vz = -1*Vz;
    end
    eva_v = abs(eva_v);
    evc_c = [Vx,Vy,Vz];
    
    [pm cm] = max(eva_v);    
    vec = evc_c(:,cm);    
    
    if(cm == 1)
        evc_c = [Vx,Vy,Vz];
    elseif(cm == 2)
        evc_c = [Vy,Vz,Vx];
    else
        evc_c = [Vz,Vx,Vy];
    end
    
    tensr = evc_c * eigv * evc_c';    
%     tensr = ConTenV2(vec', eigv);
end

