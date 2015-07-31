function str_area = area_list(ix_area,anato_map)
% return area information from index of Anatomical toobox

load(rename_for_load(anato_map))

num_area = size(ix_area,1);
str_area = [];
for n = 1:num_area
    switch ix_area(n,2)
        case 1; str_hemi = '(R)';
        case -1; str_hemi = '(L)';
    end
    
    str_area =[str_area,[MAP(ix_area(n,1)).name,str_hemi,';  ']];
    
end