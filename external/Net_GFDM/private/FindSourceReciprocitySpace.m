function gm_idx = FindSourceReciprocitySpace( cfg )

c_idx  = cfg.c_idx;
posmri = cfg.source_loc;
gm_idx_v = zeros(size(c_idx));
gm_idx = zeros(cfg.NoNonZeros,1);

for a = 1:length(posmri)
    src = posmri(a,:);
    p0 = floor(src);
    gm_idx_v(p0(1)-1:p0(1)+2, p0(2):p0(2)+1,   p0(3):p0(3)+1)   = 1;
    gm_idx_v(p0(1):p0(1)+1,   p0(2)-1:p0(2)+2, p0(3):p0(3)+1)   = 1;
    gm_idx_v(p0(1):p0(1)+1,   p0(2):p0(2)+1,   p0(3)-1:p0(3)+2) = 1;        
end

sz = size(c_idx);
pos = 1;
for c = 1:sz(3)
    for b = 1:sz(2)
        for a = 1:sz(1)
            if(c_idx(a,b,c) ~= 0)
                gm_idx(pos) = gm_idx_v(a, b, c);
                pos = pos+1;
            end
        end
    end
end

