function copy_anatomy(MY_VAR)

%% copy anatomy file
for sub = 1:length(MY_VAR.subnames)
    disp(['Copying anatomy files of ' int2str(sub) ' / ' int2str(length(MY_VAR.subnames))])
    
% Make Directory
if ~exist(fullfile(MY_VAR.image_dir,'anatomy',MY_VAR.subnames{sub}),'dir')
    mkdir(fullfile(MY_VAR.image_dir,'anatomy',MY_VAR.subnames{sub}))
end

% image file without normalization
copyfile([fullfile(MY_VAR.analyze_dir, MY_VAR.subnames{sub},'anatomy'),filesep, '*']...
        ,fullfile(MY_VAR.image_dir,'anatomy',MY_VAR.subnames{sub}))
end