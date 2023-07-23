function  [value]= net_apen_code(A,m,r)

media = mean(A);
desviacion = std(A);

% [nChan, leng] = size(A);
% for i = 1:nChan
%     rt(i,:) = ((A(i,:)-media)/desviacion);
% end
rt = ( (A-media)/desviacion );

switch m
    
    case 1
        
        
        N = length(rt);
        m = 1;
        SD = std(rt,1);
        R = SD*r;
        cou1 = 0;
        
        for i = 1 : N-m
            a = rt(i);
            
            
            for j = 1 : N-m
                e = rt(j);
                
                
                
                d1 = abs(e-a);
                
                
                
                
                if ( (d1 <= R ))
                    cou1 = cou1 + 1;
                else
                    continue;
                end
            end
            
            ic(i) = cou1;
            cou1 = 0;
        end
        
        cou2 = 0;
        
        for i = 1 : N-m
            a = rt(i);
            b = rt(i+1);
            
            
            for j = 1 : N-m
                e = rt(j);
                f = rt(j+1);
                
                
                
                d1 = abs(e-a);
                d2 = abs(f-b);
                
                
                
                if ( (d1 <= R) & (d2 <= R))
                    cou2 = cou2 + 1;
                else
                    continue;
                end
            end
            
            id(i) = cou2;
            cou2 = 0;
        end
        
        enn = 0;
        
        for u = 1 : N-m
            ratio = id(u)/ic(u);
            enn = enn + log(ratio);
        end
        
        value = ((-1)*enn)/(N-m);
        
        
        
        
    case 2
        
        %%% For m = 2 %%%
        
        
        N = length(rt);
        m = 2;
        SD = std(rt,1);
        R = SD*r;
        cou1 = 0;
        
        for i = 1 : N-m
            a = rt(i);
            b = rt(i+1);
            
            
            for j = 1 : N-m
                e = rt(j);
                f = rt(j+1);
                
                
                d1 = abs(e-a);
                d2 = abs(f-b);
                
                
                
                if ( (d1 <= R) & (d2 <= R))
                    cou1 = cou1 + 1;
                else
                    continue;
                end
            end
            
            ic(i) = cou1;
            cou1 = 0;
        end
        
        cou2 = 0;
        
        for i = 1 : N-m
            a = rt(i);
            b = rt(i+1);
            c = rt(i+2);
            
            
            for j = 1 : N-m
                e = rt(j);
                f = rt(j+1);
                g = rt(j+2);
                
                
                d1 = abs(e-a);
                d2 = abs(f-b);
                d3 = abs(g-c);
                
                
                if ( (d1 <= R) & (d2 <= R) & (d3 <= R))
                    cou2 = cou2 + 1;
                else
                    continue;
                end
            end
            
            id(i) = cou2;
            cou2 = 0;
        end
        
        enn = 0;
        
        for u = 1 : N-m
            ratio = id(u)/ic(u);
            enn = enn + log(ratio);
        end
        
        value = ((-1)*enn)/(N-m);
        
        
    case 3
        
        
        
        
        %%% For m = 3 %%%
        N = length(rt);
        m = 3;
        SD = std(rt,1);
        R = SD*r;
        cou1 = 0;
        
        for i = 1 : N-m
            a = rt(i);
            b = rt(i+1);
            c = rt(i+2);
            
            for j = 1 : N-m
                e = rt(j);
                f = rt(j+1);
                g = rt(j+2);
                
                d1 = abs(e-a);
                d2 = abs(f-b);
                d3 = abs(g-c);
                
                
                if ( (d1 <= R) & (d2 <= R) & (d3 <= R) )
                    cou1 = cou1 + 1;
                else
                    continue;
                end
            end
            
            ic(i) = cou1;
            cou1 = 0;
        end
        
        cou2 = 0;
        
        for i = 1 : N-m
            a = rt(i);
            b = rt(i+1);
            c = rt(i+2);
            d = rt(i+3);
            
            for j = 1 : N-m
                e = rt(j);
                f = rt(j+1);
                g = rt(j+2);
                h = rt(j+3);
                
                d1 = abs(e-a);
                d2 = abs(f-b);
                d3 = abs(g-c);
                d4 = abs(h-d);
                
                if ( (d1 <= R) & (d2 <= R) & (d3 <= R) & (d4 <= R))
                    cou2 = cou2 + 1;
                else
                    continue;
                end
            end
            
            id(i) = cou2;
            cou2 = 0;
        end
        
        enn = 0;
        
        for u = 1 : N-m
            ratio = id(u)/ic(u);
            enn = enn + log(ratio);
        end
        
        value = ((-1)*enn)/(N-m);
        
end