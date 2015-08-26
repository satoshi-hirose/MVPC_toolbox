% Run leave-one-run-out cross validation
% (number of spatial ROI) x (number of temporal ROI) times.
% script 'clsfy.m' is used.
%
% input:
%   MY_VAR
%      .analyze_dir             :string('/home/dcn/hirose/analyze/tapping_decoding/analysis_folder')
%      .subnames                :1 x N_sub cell array({'US','SH','YS'})
%      .decoding_dir            :string('decoding')
%      .spatialROIdir           :string('ROI_spatial')
%      .temporalROIdir          :string('ROI_temporal')
%      .result_dir              :string('results')
%      .method                  :1 x N_method cell array({'svm','rvm','slr'})
%      .normalization_method=   :1 x 4 matrix(0 or 1)(ex. [1 0 0 0])
%                                % 1st element: temporal mean to 100
%                                  2nd element: temporal normalize (Z-score)
%                                  3ed element: temporal normalization assign to samples in temporal_ROI
%                                  4th element: spatial normalize assign to samples in temporal_ROI
%                                  5th element: normalization just before classification, mean and s.d. of training dataset is used for both training and test datset.
%      .sessions                :1 x N_sub cell array. each cell contains 1 x N_sess cell array
%                                   ({{'1','2','3','4','5','6','7','8','9','10'},{'1','2','3','4','5','6','7','8','9','10'},{'1','2','3','4','5','6','7','8','9','10'}})
%      .prefix                  :string('w')
%
% output file: errTable_tr,errTable_te,spROI,teROI
%
% 2010/June/3 SH
% 2010/June/4 SH
%       line 57:sprintf('ROI spatial:\n%s\ntemporal:\n%s',spROI,teROI)
%       delete semicolon to display massage.
%
%       line 54 - : for spe = 1:size(ROIs_spatial,1)
%       move spatial ROI assignment out of tem-loop (CAUTION: not debagged!)
% 2010/June/8 SH
% 2010/June/09 IN   save the variable, "num_of_voxel" (line 144)
% 2010/June/25 IN   remove NaN voxels
%

function cross_valid(MY_VAR) % 2010/June/8 SH rename cross_valid_beta to cross_valid

%% subject loop
for sub = 1:length(MY_VAR.subnames)
    
    %% preparation
    % get ROI file names
    sp_ROI_dir              = fullfile(MY_VAR.analyze_dir,MY_VAR.subnames{sub},MY_VAR.decoding_dir,MY_VAR.spatialROIdir);
    te_ROI_dir              = fullfile(MY_VAR.analyze_dir,MY_VAR.subnames{sub},MY_VAR.decoding_dir,MY_VAR.temporalROIdir);
    [ROIs_spatial,dirs]     = spm_select('FPList',sp_ROI_dir,['^ROI.*\.mat$']);
    [ROIs_temporal,dirs]    = spm_select('FPList',te_ROI_dir,['^ROI.*\.mat$']);
    
    % get EPI file names
    for sess = 1:length(MY_VAR.sessions{sub})
        if iscell(MY_VAR.sessions{sub})
            sess_dirn = fullfile(MY_VAR.analyze_dir,MY_VAR.subnames{sub},MY_VAR.sessions{sub}{sess});
        else
            sess_dirn = fullfile(MY_VAR.analyze_dir,MY_VAR.subnames{sub},int2str(MY_VAR.sessions{sub}(sess)));
        end
        [rawdata{sess},dirs]        =spm_select('FPList',sess_dirn,['^' MY_VAR.prefix '.*\.img$']);
    end
    
    %% Spatial ROI loop
    for spe = 1:size(ROIs_spatial,1)
        clear assigned_data
        % load spatial ROI file
        spROI = deblank(ROIs_spatial(spe,:));
        load(spROI)
        
        % get first EPI conversion matrix
        matrix = spm_vol(rawdata{1}(1,:));        % 2010/June/8 SH
        matrix = matrix.mat;
        
        
        % Extract the voxel values in the spatial ROI & apply temporal HPF
        % Each cell of assigned_data corresponds each sessions
        % and the sizse of each cell is (number of voxels) x (number of samples)
        for sess = 1:length(MY_VAR.sessions{sub})
            % Extract the voxel values in the spatial ROI
            [assigned_data{sess,1},XYZmm] = extract_ROI(ROI,mat2cell(rawdata{sess},ones(size(rawdata{sess},1),1),size(rawdata{sess},2)),matrix);
            
            % drift removing   modified by IN 2011/Feb/09
            if isfield(MY_VAR,'remove_drift')==1 && MY_VAR.remove_drift==1
                assigned_data{sess,1} = remove_drift_voxels(assigned_data{sess,1},MY_VAR.TR);
            end
            
        end
        
        %% temporal ROI loop
        for tem = 1:size(ROIs_temporal,1)
            teROI = deblank(ROIs_temporal(tem,:));
            sprintf('ROI spatial:\n%s\ntemporal:\n%s',spROI,teROI)
            
            %% load & assign temporal_ROI
            
            % load temporal ROI file
            load(teROI)
            
            % Extract the necessary volume values
            % Normalizing and temporal averaging is also done here.
            X_all = assign_tempo_ROI(assigned_data,tempo_ROI,MY_VAR.normalization_method(1:4));
            
            % Remove the voxels which contains NaN
            % at least in one sample %% modified by IN 2010/June/25
            %                        %% modified by SH 2014/Sep/3
            % find NaN voxels
            ix_nan_X = find(any(isnan(cell2mat(X_all)))); % Get index of NOT NaN voxels
            % extract the NaN voxels from training and test dat
            for sess = 1:length(MY_VAR.sessions{sub})
                X_all{sess}(:,ix_nan_X)=[];
            end
            XYZmm(:,ix_nan_X) = [];
            
            % Get label
            Y_all = label; % get label
            
            %% Method loop
            for methodn = 1:length(MY_VAR.method)
                % Get classification algorithm information
                method  = MY_VAR.method{methodn};
                
                %% parallel processing
                if isfield(MY_VAR,'parallel_process') && MY_VAR.parallel_process
                    % Each problem contains one cross validation analysis
                    paradirn = MY_VAR.parallel_dir;
                    % initialization for parallel processing
                    init_parallel(paradirn)
                    % save problem information
                    filen = add_num(paradirn,'parallel','.mat');
                    save(filen,'MY_VAR','X_all','Y_all','sub','method','spROI','teROI','XYZmm');
                else
                    %% Serial processing
                    
                    % Start leave-one-session-out cross validation
                    for test_sess = 1:length(MY_VAR.sessions{sub})
                        % Devide voxel values and labels
                        % into training and test data set
                        % set training brain activity data
                        training_X              = X_all;
                        training_X{test_sess}   = [];
                        training_X              = cell2mat(training_X);
                        
                        % set test brain activity data
                        test_X                  = X_all{test_sess};
                        
                        % set training label data
                        training_Y              = Y_all;
                        training_Y{test_sess}   = [];
                        training_Y              = cell2mat(training_Y);
                        
                        % set test label data
                        test_Y                  = Y_all{test_sess};
                        
                        
                        % normalize features
                        if MY_VAR.normalization_method(5)
                            t_mean = mean(training_X,1);
                            t_sd   = std(training_X,[],1);
                            
                            training_X  = (training_X - repmat(t_mean,[size(training_X,1),1]))./repmat(t_sd,[size(training_X,1),1]);
                            test_X      = (test_X    - repmat(t_mean,[size(test_X    ,1),1]))./repmat(t_sd,[size(test_X    ,1),1]);
                        end
                        % run clsfy
                        [errTable_tr{test_sess},errTable_te{test_sess},model{test_sess}] = clsfy(training_X,training_Y,test_X,test_Y,method);
                        
                    end % end session loop
                end
                if ~isfield(MY_VAR,'parallel_process') || ~MY_VAR.parallel_process
                    %% save results
                    % get save folder path & make it if not exist
                    % Get method name
                    if isstruct(method); method_name = method.method; else method_name = method; end
                    
                    % Get directory name
                    to_dirn                 = fullfile(MY_VAR.analyze_dir,MY_VAR.subnames{sub},MY_VAR.decoding_dir,MY_VAR.result_dir,method_name);
                    
                    % Make directory if not exist
                    if ~(exist(to_dirn,'dir')); mkdir(to_dirn); end
                    
                    % Define file names
                    [temp,sp_ROI_name] = fileparts(spROI);sp_ROI_name = sp_ROI_name(4:end);
                    [temp,te_ROI_name] = fileparts(teROI);te_ROI_name = te_ROI_name(4:end);
                    filename = fullfile(to_dirn,['decoding_res',sp_ROI_name,te_ROI_name,'.mat']);
                    
                    % Get number of voxels used for decoding
                    num_of_voxel = size(test_X,2);% 2010/June/10 IN add
                    
                    % Save results file
                    save(filename,'errTable_tr','errTable_te','spROI','teROI','XYZmm','num_of_voxel','model')
                    
                end
                
            end % end method loop
            
        end % end temporal ROI loop
    end % end spatial ROI loop
end % end subject loop

%% subfunction

%% initial settings for parallel processing
function init_parallel(paradirn)

% make directory for parallel processing
if ~exist(paradirn,'dir'); mkdir(paradirn); end
% save parallel directory
if ~exist(fullfile(cd,'parallel_dirn.mat'),'file'); save('parallel_dirn.mat','paradirn'); end
% save initial number.mat file
if ~exist(fullfile(paradirn,'number.mat'),'file'); my_number = 0; save(fullfile(paradirn,'number'),'my_number'); end

