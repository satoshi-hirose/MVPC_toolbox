% Save image (.img) and header files representing the weights.
%

function save_raw_image(MY_VAR)

load(fullfile(MY_VAR.figure_dir,'results_fig.mat'),'Spatial_ROI','Temporal_ROI','Param_search','Method_info')

for methodn = 1:length(MY_VAR.method)
    method_id(methodn) = 0;
    for decoding_methodn = 1:length(Method_info)
        if strcmp(MY_VAR.method{methodn},Method_info{decoding_methodn}.name)
            method_id(methodn) = decoding_methodn;
        end
    end
    if method_id == 0; error(['The decoding analysis with following method(s) is not completed!!:' MY_VAR.method{methodn}]); end
end



%% subject loop
for sub = 1:length(MY_VAR.subnames)
    fprintf('subject %1.0f\n', sub)
    for methodn = method_id

        %% get template file
        if MY_VAR.decoding_from_normalized
            [files,dirs]     = spm_select('FPList',fullfile(MY_VAR.analyze_dir, MY_VAR.subnames{sub},'1'),['^w.*\.hdr$']);
        else
            [files,dirs]     = spm_select('FPList',fullfile(MY_VAR.analyze_dir, MY_VAR.subnames{sub},'1'),['^r.*\.hdr$']);
        end
        template = deblank(files(1,:));
        hdr = spm_vol(deblank(files(1,:)));

        %% method loop
        for methodn = method_id
            fprintf('method %1.0f\n', methodn)

            for sp = 1:length(Spatial_ROI)
                for te = 1:length(Temporal_ROI)
                    load(fullfile(MY_VAR.analyze_dir,MY_VAR.subnames{sub},MY_VAR.decoding_dir,MY_VAR.result_dir,MY_VAR.method{methodn}, ['decoding_res_' int2str(sp) '_' int2str(te) '.mat']))

                    XYZ_vox = hdr(1).mat\[XYZmm; ones(1,size(XYZmm,2))];
                    XYZ_vox = XYZ_vox(1:3,:);
                    XYZ_vox = round(XYZ_vox);

                    for sess = 1:MY_VAR.n_sess
                        %% save image file for each session

                        % get the weight vector(s) in a validation hold


                        selected_parameter = Param_search{sp,te}{sub}.selected_param(sess,:);

                        ww = model{sess}.model{selected_parameter}.ww(1:end-1);

                        save_img(ww(find(ww)),XYZ_vox(:,find(ww)),...
                            fullfile(MY_VAR.image_dir,'raw',[int2str(sp) '_' int2str(te)],MY_VAR.method{methodn},[MY_VAR.subnames{sub} '__' int2str(sess) '.img'])...
                            ,template,'');

                    end
                end
            end
        end

    end

end
