
function [end_line str] = write_text(str,start_line)

temp = start_line;
str_curr = deblank(str);
    
for j = 1:ceil(length(str_curr)/100)
    if j == ceil(length(str_curr)/100)
        str_write = str_curr((j-1)*100+1:end);
    else
        str_write = str_curr((j-1)*100+1:j*100);
    end
    text(0.01,0.99-0.03*temp,str_write,'Interpret','none','FontSize',8,'FontName','Courier')
    temp = temp + 1;
end
end_line = temp - 1;