function w_smooth = my_smooth(w,radius)



filter = zeros(radius*2+1);
for x=-radius:radius
    for y=-radius:radius
        for z = -radius:radius
            if (x)^2+(y)^2+(z)^2  <=(radius)^2
                filter(x+radius+1,y+radius+1,z+radius+1) = 1;
            else
                filter(x+radius+1,y+radius+1,z+radius+1) = 0;
            end
        end
    end
end


x_sum = convn(w,filter);
w_smooth = sign(x_sum((radius+1):(end-radius),(radius+1):(end-radius),(radius+1):(end-radius)));