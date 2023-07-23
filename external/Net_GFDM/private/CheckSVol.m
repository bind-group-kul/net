function in = CheckSVol( A, pos )

ma = A(pos(1) - 1:pos(1) + 1, pos(2) - 1:pos(2) + 1, pos(3) - 1:pos(3) + 1);

if(sum(ma(:)) >= 27)
    in = 1;
else
    in = 0;
end
