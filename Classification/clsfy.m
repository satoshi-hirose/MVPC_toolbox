function [errTable_tr,errTable_te,model] = clsfy(xtrain,ttrain,xtest,ttest,method)
%
% clsfy.m : classification
% [errTable_tr,errTable_te,model] = clsfy(xtrain,ttrain,xtest,ttest,parm)
%
%-- Inputs
%    xtrain [Ntraining x Nfeat matrix] 	: matrix of feature values of training data
%    ttrain [Ntraining x 1 matrix]	: matrix of labels of training data.
%    xtest  [Ntest x Nfeat matrix]	: matrix of feature values of test data
%    ttest  [Ntest x 1 matrix]		: matrix of labels of test data
%    method [string or structure]: **See ReadMe file**
%
%-- Outputs
%    errTable_tr : error table for training data set (fitting)
%    errTable_te : error table for ttest data set (fitting)
%    model       : other training parameters are included as a struct
%
% if leaning algorithm requires (a) parameter(s)
% method should be a structure including fields named 'method' and paramaters
% the algorithm require. (See around line 60)
%
% currently, the algorithms below are implemented

%
% %% Sparse Logistic Regression Toolbox 
% %% http://www.cns.atr.jp/~oyamashi/SLR_WEB.html
% 'slr'
% 'islr'
%
% %% libSVM
%
% 'svm'
% 'svm_rfe'
% 'svm_rfe_M'
% 'ab_svm'
% 'ab_svm_repeat'
% 
% %% GLM net
% http://cran.r-project.org/web/packages/glmnet/index.html
% 'L1'
% 'L1_slr_repeat'
% 'elast'
% 'elast_repeat'
%
% Modified by SH 2011/Dec
% Modified by SH 2013/Apr (iSLR model)
% Modified by SH 2014/Jul


%% Load the settings for algorithms (load default settings if parameters are not determiend)


if isstruct(method)
    method_name = method.method;
else
    method_name = method;
end

switch method_name
    case 'slr'

    case 'islr'
        if isfield(method,'repn');              repn            = method.repn;              else    repn            = 100;          end
    
    case 'svm'
        if isfield(method,'c');                 c               = method.c;                 else    c               = 1;            end
    
    case 'svm_rfe'
        if isfield(method,'steps');             steps           = method.steps;             else    steps           = [0.1:0.1:1];  end
        if isfield(method,'c');                 c               = method.c;                 else    c               = 1;            end
    
    case 'ab_svm'
        if isfield(method,'feat_size');         feat_size       = method.feat_size;         else    feat_size       = 0.5;          end
        if isfield(method,'ensemble_size');     ensemble_size   = method.ensemble_size;     else    ensemble_size   = 10;           end
        if isfield(method,'c');                 c               = method.c;                 else    c               = 1;            end
    
    case 'ab_svm_repeat'
        if isfield(method,'feat_size');         feat_size       = method.feat_size;         else    feat_size       = 0.1:0.1:1;    end
        if isfield(method,'ensemble_size');     ensemble_size   = method.ensemble_size;     else    ensemble_size   = 10;           end
        if isfield(method,'c');                 c               = method.c;                 else    c               = 1;            end
    
    case 'L1'
        if isfield(method,'lambda');            lambda          = method.lambda;            else    lambda          = 1;            end
    
    case 'L1_repeat'
        if isfield(method,'lambda');            lambda          = method.lambda;            else    lambda          = 2.^[-4:8];     end
    
    case 'elast'
        if isfield(method,'lambda');            lambda          = method.lambda;            else    lambda          = 1;            end
        if isfield(method,'alpha');             alpha           = method.alpha;             else    alpha           = 0.1;          end
    
    case 'elast_repeat'
        if isfield(method,'lambda');            lambda          = method.lambda;            else    lambda          = 2.^[-4:8];     end
        if isfield(method,'alpha');             alpha           = method.alpha;             else    alpha           = 0.1:0.1:1;    end
        
    case 'elast2'
        if isfield(method,'lambda1');           lambda1         = method.lambda1;           else    lambda1         = 1;            end
        if isfield(method,'lambda2');           lambda2         = method.lambda2;           else    lambda2         = 1;            end

    case 'elast2_repeat'
        if isfield(method,'lambda1');           lambda1         = method.lambda1;           else    lambda1         = 2.^[-2:5];    end
        if isfield(method,'lambda2');           lambda2         = method.lambda2;           else    lambda2         = 10.^[-1:4];   end
 

end

%% preparation
% rewrite label if needed
if ~(sum(~(unique(ttrain) == (1:length(unique(ttrain)))')) == 0)
    warning('THE DETERMINATION OF LABELS ARE WRONG. LABELS ARE RE-DETERMINED');
    ttrain_uni = unique(ttrain);
    disp(ttrain_uni');
    
    for i = 1:length(ttrain)
        ttrain(i)    = find(ttrain_uni == ttrain(i));
    end
    
    for i = 1:length(ttest)
        ttest(i)    = find(ttrain_uni == ttest(i));
    end
end

% check whether the problem is binary or multi-class 
if length(unique(ttrain)) == 2;
    classification = 'binary';
else
    classification = 'multi';
end


%% --- classification ---
switch method_name
    case 'slr'
        %% SLR with "Sparse Logistic Regression Toolbox"
        
        % initial parameter settings 
        % (see "Sparse Logistic Regression Toolbox")
            nlearn = 1000;
            scale_mode = 'none';
            mean_mode = 'none';
            amax = 1e8;
            nstep = nlearn;
            displaytext = 0;
            usebias     = 1;
        
        % training and label prediction
            switch classification
                case 'multi'
                [ww,ix_eff_all,errTable_tr,errTable_te,parm_clsfy,xxx,Ptr,Pte]...
                    = muclsfy_smlr(xtrain,ttrain,xtest,ttest,'nlearn',nlearn,'scale_mode',scale_mode,'mean_mode',mean_mode,'amax',amax,'displaytext',displaytext,'nstep',nstep,'usebias',usebias);

                case 'binary'
                [ww, ix_eff_all, errTable_tr, errTable_te, parm_clsfy, xxx,Ptr,Pte]...
                    = biclsfy_slrvar(xtrain,ttrain,xtest,ttest,'nlearn',nlearn,'scale_mode',scale_mode,'mean_mode',mean_mode,'amax',amax,'displaytext',displaytext,'nstep',nstep,'usebias',usebias);
            end
        
        % save the output "model"
            model.ww        = ww;
            model.Ptr       = Ptr;
            model.Pte       = Pte;
        
  case 'islr'
        %% iSLR with "Sparse Logistic Regression Toolbox"
        [errTable_tr,errTable_te,model] = islr(xtrain,ttrain,xtest,ttest,repn,classification);
      
    case 'svm'
        %% C-SVM with "LibSVM"
        Libsvm_options = ['-s 0 -t 0 -c ' int2str(c)];
        
        model_curr = svmtrain(ttrain, xtrain,Libsvm_options);
        ttrain_pred = svmpredict(ttrain, xtrain, model_curr);
        ttest_pred = svmpredict(ttest, xtest, model_curr);
    
        % performance evaluation
            errTable_tr = slr_error_table(ttrain,ttrain_pred);
            errTable_te = slr_error_table(ttest,ttest_pred);
        
        % save the output "model"
            model = struct;
            model.Pte = ttest_pred;
            model.Ptr = ttrain_pred;

    case 'svm_rfe'
        %% SVM with Recursive Feature Elimination with "Libsvm"
        Libsvm_options = ['-s 0 -t 0 -c ' int2str(c)];
        [errTable_tr,errTable_te,model] = svm_rfe(xtrain,ttrain,xtest,ttest,steps,Libsvm_options);

    case 'ab_svm'
        %% AB-SVM with "Libsvm"
        if strcmp(classification,'multi'); error('Attribute Bagging is implemented only for binary classification'); end
        Libsvm_options = ['-s 0 -t 0 -c ' int2str(c)];
        % feature size determination
        % (if smaller than 1, convert propotion -> number of features)
            if feat_size <= 1; feat_size = floor(size(xtrain,2)*feat_size); end
        
        % iterative training and test
            for i = 1:ensemble_size
                used_voxels = find(randperm(size(xtrain,2)) <= feat_size);
                 [errTable_tr{i,1},errTable_te{i,1},model{i,1}] = clsfy(xtrain(:,used_voxels),ttrain,xtest(:,used_voxels),ttest,struct('method','svm','c',c));

                 model{i,1}.used_voxels = used_voxels;
                 
                 % for test data
                     % sub-classifier's prediction
                     esti_te{i,1}  = model{i,1}.Pte';
                     % meta_classifier's prediction with voting
                     voting_esti_te{i,1} = mode(cell2mat(esti_te),1);
                     % performance evaluation for meta-classifer
                     errTable_te_vote{i,1}       = slr_error_table(ttest,voting_esti_te{i,1}');
                     percent_corr_te_vote{i,1}   = calc_percor(errTable_te_vote{i,1});

                 % for training data
                     % sub-classifier's prediction
                     esti_tr{i,1}  = model{i,1}.Ptr';
                     % meta_classifier's prediction with voting
                     voting_esti_tr{i,1} = mode(cell2mat(esti_tr),1);
                     % performance evaluation for meta-classifer
                     errTable_tr_vote{i,1}       = slr_error_table(ttrain,voting_esti_tr{i,1}');
                     percent_corr_tr_vote{i,1}   = calc_percor(errTable_tr_vote{i,1});
            end
            
        % save the model
            model        = struct(  'esti_te',                  {esti_te},...
                                    'esti_tr',                  {esti_tr},...
                                    'errTable_te',              {errTable_te},...
                                    'errTable_tr',              {errTable_tr},...
                                    'voting_esti_te',           {voting_esti_te},...
                                    'voting_esti_tr',           {voting_esti_tr},...
                                    'errTable_te_vote',         {errTable_te_vote},...
                                    'errTable_tr_vote',         {errTable_tr_vote},...
                                    'percent_corr_te_vote',     {percent_corr_te_vote},...
                                    'percent_corr_tr_vote',     {percent_corr_tr_vote});

        % re-define the outputs 'errTable_tr' and 'errTable_te' as the
        % performance of meta-classifier
            errTable_tr = errTable_tr_vote{end};
            errTable_te = errTable_te_vote{end};

    case 'ab_svm_repeat'
        %% This is for the parameter search of AB-SVM
       
        for i = 1:length(feat_size)
                [errTable_tr{i,1},errTable_te{i,1},model2{i}] = clsfy(xtrain,ttrain,xtest,ttest,struct('method','ab_svm','feat_size',feat_size(i),'ensemble_size',ensemble_size,'c',c));
 
        end
        
        model.model = model2;
        model.parameter{1} = struct('name','num_of_feat','space',feat_size(:));
        
  
        
    case 'L1'
        %% L1 with "GLM net"
        
        [errTable_tr,errTable_te,model] = ...
            clsfy(xtrain,ttrain,xtest,ttest,struct('method','elast','alpha',1,'lambda',lambda));
        
        % remove meaningless information from "model"
        model = rmfield(model,'alpha');
    case 'L1_repeat'
        %% This is for the parameter search of L1

        model2 = {};
        i = 1;
        for lambda_each = lambda
            [errTable_tr{i,1},errTable_te{i,1},model2{i,1}] = ...
                clsfy(xtrain,ttrain,xtest,ttest,struct('method','L1','lambda',lambda_each));
            i = i+1;
        end
        
        model.model = model2;
        model.parameter{1} = struct('name','lambda','space',lambda(:));
        
    case 'elast'
        %% ElasticNet with "GLM net"
        
        % define the classifier for "GLM net"
            options = glmnetSet(struct('alpha', alpha, 'lambda',lambda,'standardize',false));
            
        % training
            switch classification
                case  'binary'
                fit=glmnet(xtrain,ttrain,'binomial',options);
                case 'multi'
                fit=glmnet(xtrain,ttrain,'multinomial',options);
            end        
        
                % probablistic prediction
            % for training data set
                Ptr = glmnetPredict(fit,xtrain,[],'response');
            % for test data set
                Pte = glmnetPredict(fit,xtest,[],'response');
        
        % deterministic prediction
            % training data set
                label_est_tr = glmnetPredict(fit,xtrain,[],'class');
            % for test data set
                label_est_te = glmnetPredict(fit,xtest,[],'class');
                
        % if error(s) (ex. no feature survived), all labels are predicted as label 1
        % and the predicted probabilities for each labels are equal 
            switch classification
                case 'binary'
                    % deterministic prediction
                    if isempty(label_est_tr); label_est_tr = ones(size(ttrain)); end
                    if isempty(label_est_te); label_est_te = ones(size(ttest)); end
                    % probablistic prediction
                    if isempty(Ptr); Ptr = 0.5*ones(size(ttrain)); end
                    if isempty(Pte); Pte = 0.5*ones(size(ttest)); end
                case 'multi'
                    % deterministic prediction
                    if isempty(label_est_tr); label_est_tr = ones(size(ttrain)); end
                    if isempty(label_est_te); label_est_te = ones(size(ttest)); end
                    % probablistic prediction
                    if isempty(Ptr); Ptr = 1/length(unique(ttrain(:)))*ones(size(ttrain),length(unique(ttrain(:)))); end
                    if isempty(Pte); Pte = 1/length(unique(ttest(:)))*ones(size(ttest),length(unique(ttest(:)))); end
            end
        
        % performance evaluation
            % training data set
            errTable_tr = slr_error_table(ttrain, label_est_tr);
            % test data set
            errTable_te = slr_error_table(ttest , label_est_te);
        
        % get weight vector
            switch classification
                case 'binary'
                    model.ww = sparse([fit.beta;fit.a0]);
                case 'multi'
                    model.ww = sparse([cell2mat(fit.beta);fit.a0]);
            end
        
        % if binary, rewite Ptr and Pte
            if strcmp(classification, 'binary')
                Ptr = [1-Ptr,Ptr];
                Pte = [1-Pte,Pte];
            end
            
        % save the model
            model.alpha = alpha;
            model.lambda = lambda;
            model.Ptr        = Ptr;
            model.Pte        = Pte;
        
    case 'elast_repeat'
        %% This is for the parameter search of Elast

        model2 = {};
        for i = 1:length(lambda)
            lambda_each = lambda(i);
            
            for j = 1:length(alpha)
                alpha_each = alpha(j);
                disp([int2str((i-1) * length(alpha) + j) '/'  int2str(length(lambda) * length(alpha))])
                [errTable_tr{i,j},errTable_te{i,j},model2{i,j}] = ...
                    clsfy(xtrain,ttrain,xtest,ttest,struct('method','elast','alpha',alpha_each,'lambda',lambda_each));
            end
        end
        model.model = model2;
        model.parameter{1} = struct('name','lambda','space',lambda(:));
        model.parameter{2} = struct('name','alpha','space',alpha(:));

        
    case 'elast2'
        %% ElasticNet with "GLM net"
        % the penalty was defined with lambda1 and lambda2, 

        
        lambda = lambda1+lambda2;
        alpha  = lambda1/(lambda1+lambda2);
        [errTable_tr,errTable_te,model] = ...
                    clsfy(xtrain,ttrain,xtest,ttest,struct('method','elast','alpha',alpha,'lambda',lambda));
            
        % save the model
            model.lambda1    = lambda1;
            model.lambda2    = lambda2;
        
    case 'elast2_repeat'
        %% This is for the parameter search of Elast2

        model2 = {};
        for i = 1:length(lambda1)
            lambda1_each = lambda1(i);
            
            for j = 1:length(lambda2)
                lambda2_each = lambda2(j);
                disp([int2str((i-1) * length(lambda2) + j) '/'  int2str(length(lambda1) * length(lambda2))])
                [errTable_tr{i,j},errTable_te{i,j},model2{i,j}] = ...
                    clsfy(xtrain,ttrain,xtest,ttest,struct('method','elast2','lambda1',lambda1_each,'lambda2',lambda2_each));
            end
        end
        model.model = model2;
        model.parameter{1} = struct('name','lambda1','space',lambda1);
        model.parameter{2} = struct('name','lambda2','space',lambda2);

   
         
end