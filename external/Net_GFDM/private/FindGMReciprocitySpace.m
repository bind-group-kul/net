function gm_idx = FindGMReciprocitySpace( cfg )

Hcr = zeros(5,5,5);
Hcr(1,:,:) = [0 0 0 0 0;
              0 1 1 1 0;
              0 1 1 1 0;
              0 1 1 1 0;
              0 0 0 0 0];
          
Hcr(2,:,:) = [0 1 1 1 0;
              1 1 1 1 1;
              1 1 1 1 1;
              1 1 1 1 1;
              0 1 1 1 0];
          
Hcr(3,:,:) = [0 1 1 1 0;
              1 1 1 1 1;
              1 1 1 1 1;
              1 1 1 1 1;
              0 1 1 1 0];
          
Hcr(4,:,:) = [0 1 1 1 0;
              1 1 1 1 1;
              1 1 1 1 1;
              1 1 1 1 1;
              0 1 1 1 0];
          
Hcr(5,:,:) = [0 0 0 0 0;
              0 1 1 1 0;
              0 1 1 1 0;
              0 1 1 1 0;
              0 0 0 0 0];          
          
          
gm_idx_v = imdilate(cfg.gmvol, Hcr);          

% cnt =  floor((size(Hcr)+1)/2)
          
c_idx  = cfg.c_idx;
gm_idx = zeros(cfg.Nz,1);

sz = size(c_idx);

pos = 1;
for c = 1:sz(3)-1
    for b = 1:sz(2)-1
        for a = 1:sz(1)-1
            if(c_idx(a,b,c) ~= 0)
                if(gm_idx_v(a, b, c))
                    gm_idx(pos) = 1;
                else
                    gm_idx(pos) = 0;
                end
                pos = pos+1;
            end
        end
    end
end

