function combine_folds(MY_VAR)


for sp = MY_VAR.spROI_ind
    for te = MY_VAR.teROI_ind
        for methodn = 1:length(MY_VAR.method)
            for sub = 1:length(MY_VAR.subnames)
                clear matrix_sub
                for sess = 1:MY_VAR.n_sess
                    [matrix_sub(:,:,:,sess)] = img2mat(fullfile(MY_VAR.image_dir,'raw',[int2str(sp) '_' int2str(te)], MY_VAR.method{methodn},[MY_VAR.subnames{sub} '__' int2str(sess) '.hdr']));
                end
                Hdr = spm_vol(fullfile(MY_VAR.image_dir,'raw',[int2str(sp) '_' int2str(te)], MY_VAR.method{methodn},[MY_VAR.subnames{sub} '__' int2str(sess) '.hdr']));
                
                for to_be_saved_ind = 1:length(MY_VAR.to_be_saved)
                    switch MY_VAR.to_be_saved{to_be_saved_ind}
                        case 'mean'
                            matrix_mean = mean(matrix_sub,4);
                        case 'selected'
                            matrix_mean = sign(sum(abs(matrix_sub),4));
                        case 'selected_count'
                            matrix_mean = sum(sign(abs(matrix_sub)),4);
                        case 'sign'
                            matrix_mean = sum(sign(matrix_sub),4);
                    end
                    
                    if ~exist(fullfile(MY_VAR.image_dir,MY_VAR.to_be_saved{to_be_saved_ind},[int2str(sp) '_' int2str(te)], MY_VAR.method{methodn}),'dir');
                        mkdir(fullfile(MY_VAR.image_dir,MY_VAR.to_be_saved{to_be_saved_ind},[int2str(sp) '_' int2str(te)], MY_VAR.method{methodn}))
                    end
                    
                    Hdr.fname = fullfile(MY_VAR.image_dir,MY_VAR.to_be_saved{to_be_saved_ind},[int2str(sp) '_' int2str(te)], MY_VAR.method{methodn},[MY_VAR.subnames{sub} '.img']);
                    mat2img(Hdr,matrix_mean);
                    
                    if ~MY_VAR.decoding_from_normalized
                        my_normalization({Hdr.fname},fullfile(MY_VAR.image_dir,'anatomy',MY_VAR.subnames{sub}, 'T1_sn.mat'))
                    end
                    
                end
            end
        end
    end
end