function combine_subjects_selected_count(MY_VAR)

load(fullfile(MY_VAR.figure_dir,'results_fig.mat'),'Spatial_ROI','Temporal_ROI')

filter = zeros(MY_VAR.radius*2+1);
for x=-MY_VAR.radius:MY_VAR.radius
    for y=-MY_VAR.radius:MY_VAR.radius
        for z = -MY_VAR.radius:MY_VAR.radius
            if (x)^2+(y)^2+(z)^2  <=(MY_VAR.radius)^2
                filter(x+MY_VAR.radius+1,y+MY_VAR.radius+1,z+MY_VAR.radius+1) = 1;
            else
                filter(x+MY_VAR.radius+1,y+MY_VAR.radius+1,z+MY_VAR.radius+1) = 0;
            end
        end
    end
end

%% method loop
for methodn = 1:length(MY_VAR.method)
    fprintf('method %1.0f\n', methodn)
    for sp = 1:length(MY_VAR.spROI_ind)
        for te = 1:length(MY_VAR.teROI_ind);
            ww = [];
            for sub = 1:length(MY_VAR.subnames)
                if MY_VAR.decoding_from_normalized
                    temp =  img2mat(fullfile(MY_VAR.image_dir,MY_VAR.to_be_saved, [int2str(sp) '_' int2str(te)],MY_VAR.method{methodn},[ MY_VAR.subnames{sub} '.img']));
                else
                    temp =  img2mat(fullfile(MY_VAR.image_dir,MY_VAR.to_be_saved, [int2str(sp) '_' int2str(te)],MY_VAR.method{methodn},['w' MY_VAR.subnames{sub} '.img']));
                end
                
                temp(abs(temp)<=MY_VAR.threshold_within_subjects) = 0; % threshold within subject
                temp = convn(temp,filter);% smoothing across subject
                ww(:,:,:,sub) = temp((MY_VAR.radius+1):(end-MY_VAR.radius),(MY_VAR.radius+1):(end-MY_VAR.radius),(MY_VAR.radius+1):(end-MY_VAR.radius));
                
                
            end
            ww_all = sum(sign(ww),4);
            ww_all_selected = sum(abs(sign(ww)),4);
            
            
            index = find(abs(ww_all)>MY_VAR.threshold_across_subjects); % thoreshold of number of subject (across subject threshold)
            
            [vx_coor_X vx_coor_Y vx_coor_Z]  = ind2sub(size(ww_all),index);
            vx_coor = [vx_coor_X vx_coor_Y vx_coor_Z]';
            values = ww_all(index);
            
            A = spm_clusters(vx_coor);
            for cl_ind = 1:max(A)
                cl_size(cl_ind) = sum(A==cl_ind);
            end
            
            figure; hist(cl_size,1:max(cl_size))
            
            
            for cl_ind = 1:max(A)
                if cl_size(cl_ind) <MY_VAR.threshold_cluster; % cluster threshold
                    vx_coor(:,A == cl_ind)=[];
                    values(A == cl_ind)=[];
                    A(A == cl_ind)=[];
                    
                end
            end
            
            
            
            
            save_img(values,vx_coor,fullfile(MY_VAR.image_dir,MY_VAR.to_be_saved, [int2str(sp) '_' int2str(te)],MY_VAR.method{methodn},'all.img'),...
                fullfile(MY_VAR.image_dir,MY_VAR.to_be_saved, [int2str(sp) '_' int2str(te)],MY_VAR.method{methodn},['w' MY_VAR.subnames{1} '.img']),'')
            n_vx(sp,te) = length(values)
            
            
        end
    end
end
disp(['number of voxels is '])
disp(n_vx)


