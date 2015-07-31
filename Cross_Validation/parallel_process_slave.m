% parallel processing 
% after the problem saved, you can use this script in multiple MATLABs
% The current directory shold be the same as the original script.

while 1
    
    %% Initialization
    clear
    
    % Load the parallel dicrectory name
    load('parallel_dirn.mat')
    
    % Load the number what should be solved
    % "while" and "try" is used for avoiding the error in the case
    % where one slave try to load the "number.mat"
    % while one slave saving the file "number.mat"
    flg = 1;
    while flg
        try
            load(fullfile(paradirn,'number'))
            my_number = my_number+1
            save(fullfile(paradirn,'number'),'my_number')
            flg = 0;
        catch
            pause(0.5)
        end
    end
    
    
    try
    %% load the problem file.
        if exist(rename_for_load(fullfile(paradirn,['parallel' int2str(my_number),'.mat'])),'file')
            load(rename_for_load(fullfile(paradirn,['parallel' int2str(my_number),'.mat'])))
        % finish the process if all the problems are solved.
        else
            disp('ALL MISSIONS COMPLETED')
            break
        end
        

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
        
    % skip the analysis if the file to be saved is exist
    if ~exist(filename,'file')

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

    end % End session loop

    % Get number of voxels used for decoding
        num_of_voxel = size(test_X,2);% 2010/June/10 IN add

    % Save results file
        save(filename,'errTable_tr','errTable_te','spROI','teROI','XYZmm','num_of_voxel','model')

    end

%% If error, save the error file.
    catch
        error_data = lasterror;
        save(rename_for_load(fullfile(paradirn,['error' int2str(my_number),'.mat'])))
    end
end % end while loop