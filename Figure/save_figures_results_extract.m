% Result extraction and combination for figures.


function save_figures_results_extract(MY_VAR)

%% Get ROI information from first subject.
% Spatial ROI
sp_ROI_dir              = fullfile(MY_VAR.analyze_dir,MY_VAR.subnames{1},MY_VAR.decoding_dir,MY_VAR.spatialROIdir);

Spatial_ROI = {};
sp = 0;
while 1
    sp = sp+1;
    spROI = fullfile(MY_VAR.analyze_dir,MY_VAR.subnames{1},MY_VAR.decoding_dir,MY_VAR.spatialROIdir,['ROI_' int2str(sp) '.mat']);
    if ~exist(spROI,'file'); break; end
    Spatial_ROI{sp,1}.fname = ['ROI_' int2str(sp) '.mat'];
    load(spROI,'ROI_param')
    Spatial_ROI{sp,1}.ROI_param = ROI_param;
    for sub = 1:length(MY_VAR.subnames)
        spROI = fullfile(MY_VAR.analyze_dir,MY_VAR.subnames{sub},MY_VAR.decoding_dir,MY_VAR.spatialROIdir,['ROI_' int2str(sp) '.mat']);
        load(spROI,'ROI')
        Spatial_ROI{sp,1}.num_vox(sub) = size(ROI,2);
    end
end
    

% Temporal ROI
te_ROI_dir              = fullfile(MY_VAR.analyze_dir,MY_VAR.subnames{sub},MY_VAR.decoding_dir,MY_VAR.temporalROIdir);

Temporal_ROI = {};
te = 0;
while 1
te = te+1;
    teROI = fullfile(MY_VAR.analyze_dir,MY_VAR.subnames{1},MY_VAR.decoding_dir,MY_VAR.temporalROIdir,['ROI_' int2str(te) '.mat']);
    if ~exist(teROI,'file'); break; end
    Temporal_ROI{te,1}.fname = ['ROI_' int2str(te) '.mat'];
    load(teROI,'tR_timing')
    Temporal_ROI{te,1}.timing = tR_timing;
end

%% Get decoder's information
Method_info = cell(length(MY_VAR.method),1);
for methodn = 1:length(MY_VAR.method)
    % name
    Method_info{methodn,1}.name = MY_VAR.method{methodn};
    % parameter fitting
    res_dirn = fullfile(MY_VAR.analyze_dir, MY_VAR.subnames{1},MY_VAR.decoding_dir,MY_VAR.result_dir,MY_VAR.method{methodn});
    load(fullfile(res_dirn,'decoding_res_1_1.mat'),'errTable_te','model')

    if ~iscell(errTable_te{1});
        Method_info{methodn,1}.parameter = 'no parameter';
    elseif exist(fullfile(MY_VAR.analyze_dir, MY_VAR.subnames{1},MY_VAR.decoding_dir,MY_VAR.result_dir,'leave_two_out','1',MY_VAR.method{methodn},'decoding_res_1_1.mat'),'file')
        Method_info{methodn,1}.parameter = 'leave two';
        Method_info{methodn,1}.param_space = model{1}.parameter;
    else
        Method_info{methodn,1}.parameter = 'cheating';
        Method_info{methodn,1}.param_space = model{1}.parameter;
        Method_info{methodn,1}.name = ['CHEAT_PARAMETER_' Method_info{methodn,1}.name];
    end
end
            
%% Performance

%% subject loop
for sub = 1:length(MY_VAR.subnames)
    fprintf('subject %1.0f\n', sub)
    
    %% method loop
    for methodn = 1:length(MY_VAR.method)
        fprintf('method %1.0f\n', methodn)

        for sp = 1:length(Spatial_ROI)
            for te = 1:length(Temporal_ROI)
                %Result file name
                res_filen = fullfile(MY_VAR.analyze_dir, MY_VAR.subnames{sub},MY_VAR.decoding_dir,MY_VAR.result_dir,MY_VAR.method{methodn},['decoding_res',Spatial_ROI{sp,1}.fname(4:end-4),Temporal_ROI{te,1}.fname(4:end-4),'.mat']);
                
                % load error Table
                load(res_filen);
                tmp = errTable_tr;
                while iscell(tmp)
                    tmp = tmp{1};
                end
                dim = length(tmp);
                
                %% Compute accuracy
                switch  Method_info{methodn,1}.parameter
                    case 'no parameter'
                    % No parameter tuning is required.
                        Param_search{sp,te}{methodn,sub}    = []; % dummy
                        Percent_correct{sp,te}{methodn,sub} = calc_percor(change_dim(sum(cat(3,errTable_te{:}),3),dim));
                        Error_Table{sp,te}{methodn,sub} = sum(cat(3,errTable_te{:}),3);
                    case 'leave two'
                    % Leave-two-run-out is completed.
                        % Compute percent correct for each (combination) of the parameters
                        for i1 = 1:size(errTable_te{1},1)
                            for i2 = 1:size(errTable_te{1},2)
                                tmp = zeros(dim);
                                for j = 1:length(errTable_te)
                                    
                                        tmp = change_dim(errTable_te{j}{i1,i2},dim) + tmp;
                                    
                                end
                            Param_search{sp,te}{methodn,sub}.accuracy(i1,i2) = calc_percor(tmp);
                            end
                        end
                        
                        % Compute percent correct with optimized paramter
                        errTable_te_leave_one = errTable_te;
                        errTable_selected     = [];
                        
                        for session = 1:length(errTable_te_leave_one)
                            leave_two_file = fullfile(MY_VAR.analyze_dir, MY_VAR.subnames{sub},MY_VAR.decoding_dir,MY_VAR.result_dir,'leave_two_out'...
                                ,int2str(session),MY_VAR.method{methodn},['decoding_res',Spatial_ROI{sp,1}.fname(4:end-4),Temporal_ROI{te,1}.fname(4:end-4),'.mat']);
                            load(leave_two_file,'errTable_te');

                            leave_two_accuracy = [];
                            for i1 = 1:size(errTable_te{1},1)
                                for i2 = 1:size(errTable_te{1},2)
                                    tmp = zeros(dim);
                                    for j = 1:length(errTable_te)
                                        tmp = change_dim(errTable_te{j}{i1,i2},dim) + tmp;

                                    end
                                    leave_two_accuracy(i1,i2) = calc_percor(tmp);
                                end
                            end
     
 
                                [xxx,tmp] = max(leave_two_accuracy(:));
                                [parameter_selected(1),parameter_selected(2)] = ind2sub(size(leave_two_accuracy),tmp);
                                errTable_selected(:,:,session) = change_dim(errTable_te_leave_one{session}{parameter_selected(1),parameter_selected(2)},dim);
                                
                                for param_ind = 1:length(Method_info{methodn,1}.param_space)
                                    Param_search{sp,te}{methodn,sub}.selected_param(session,param_ind)= Method_info{methodn,1}.param_space{1}.space(parameter_selected(param_ind));
                                end
                                
                        end
                        
                        Percent_correct{sp,te}{methodn,sub} = calc_percor(sum(errTable_selected,3));
                        Error_Table{sp,te}{methodn,sub}     = sum(errTable_selected,3);
                    case 'cheating'
                        %%  BUG EXISTS IN THIS CASE



                    % Leave-two-run-out is NOT completed.
                        % Compute percent correct for each (combination) of the parameters
                        for i1 = 1:size(errTable_te{1},1)
                            for i2 = 1:size(errTable_te{1},2)
                                tmp = zeros(size(errTable_te{1}{i1,i2}));
                                for j = 1:length(errTable_te)
                                    tmp = tmp + errTable_te{j}{i1,i2};
                                end
                            Param_search{sp,te}{methodn,sub}.accuracy(i1,i2) = calc_percor(tmp);
                            end
                        end
                        
                        % Compute percent correct with optimized paramter
                        if length(Method_info{methodn,1}.param_space) == 1
                        % One parameter
                            [Percent_correct{sp,te}{methodn,sub},parameter_selected] = max(Param_search{sp,te}{methodn,sub}.accuracy(i1,i2));

                            Param_search{sp,te}{methodn,sub}.selected_param = repmat(Method_info{methodn,1}.param_space{1}.space(parameter_selected),length(errTable_te_leave_one),1);

                        elseif length(Method_info{methodn,1}.param_space) == 2
                        % Two parameters (i.e. grid search)
                            [xxx,tmp] = max(leave_two_accuracy(:));
                            [parameter_selected(1),parameter_selected(2)] = ind2sub(size(leave_two_accuracy),tmp);
                            Percent_correct{sp,te}{methodn,sub} = Param_search{sp,te}{methodn,sub}.accuracy(parameter_selected(1),parameter_selected(2));
                            
                            Param_search{sp,te}{methodn,sub}.selected_param = repmat(Method_info{methodn,1}.param_space{1}.space(parameter_selected),length(errTable_te_leave_one),1);
                            
                        end

                end
                        
            end
        end
    end
end
    
if ~exist(MY_VAR.figure_dir,'dir'); mkdir(MY_VAR.figure_dir); end


save(fullfile(MY_VAR.figure_dir,'results_fig.mat'),'Spatial_ROI','Temporal_ROI','Method_info','Param_search','Percent_correct','MY_VAR','Error_Table','-v7.3')





%% subfunction

function errtable_mod = change_dim(errtable_ori,dim)
errtable_mod = zeros(dim);
errtable_mod(1:size(errtable_ori,1),1:size(errtable_ori,2)) = errtable_ori;


