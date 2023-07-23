function vec_out = my_vector_shifter(vec_in,shift)


if abs(shift)>numel(vec_in)
    error('the shift value you specified is bigger than the size of the vector!');
end

if shift==0
    vec_out=vec_in;
elseif shift<0
    end_point = vec_in(end);
    vec_out = [vec_in(1-shift:end) end_point*ones(1,-shift)];
       
elseif shift>0
    
    begin_point = vec_in(1);
    vec_out = [begin_point*ones(1,shift) vec_in(1:end-shift)];
end