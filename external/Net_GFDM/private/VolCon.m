function tensr = VolCon( DTI, cond_iso )

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
    
    s_i = cond_iso/(eva_v(1)*eva_v(2)*eva_v(3))^(1/3);
    tensr = s_i*evc_c*abs(eva)*evc_c';
    
    [evc_t, eva_t] = eig(tensr);
    volu   = cond_iso^3;
    volu_t = eva_t(1,1)*eva_t(2,2)*eva_t(3,3);
    
    if( (volu - volu_t)^2 > 1e-10 )
        tensr = cond_iso*eye(3);
    end
end








