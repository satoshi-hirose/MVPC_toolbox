% adds the number to avoid file-overwrite

function filename = add_num(dirn,filen_pre,filen_post)

file_num=1;
while exist(fullfile(dirn,[filen_pre,int2str(file_num),filen_post]),'file')
    file_num = file_num+1;
end

filename = fullfile(dirn,[filen_pre,int2str(file_num),filen_post]);



