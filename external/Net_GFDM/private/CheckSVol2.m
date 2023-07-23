function in = CheckSVol2( A, pos )

ma_x = squeeze( A(pos(1) - 1:pos(1) + 1, pos(2), pos(3)) );
ma_y = squeeze( A(pos(1), pos(2) - 1:pos(2) + 1, pos(3)) );
ma_z = squeeze( A(pos(1), pos(2), pos(3) - 1:pos(3) + 1) );

if(sum(ma_x) + sum(ma_y) + sum(ma_z) >= 9)
    in = 1;
else
    in = 0;
end
