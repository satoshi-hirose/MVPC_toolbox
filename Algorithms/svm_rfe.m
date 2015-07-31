function [errTable_tr,errTable_te,model] = svm_rfe(xtrain,ttrain,xtest,ttest,steps,Libsvm_options)
%
% svm_rfe.m: Support Vector Machine with Recursive Feature Elimmination
% [errTable_tr,errTable_te,model] = svm_rfe(xtrain,ttrain,xtest,ttest,classification,steps,svm_options)
%
%-- Inputs
%    xtrain [Ntraining x Nfeat matrix] 	: matrix of feature values of training data
%    ttrain [Ntraining x 1 matrix]	: matrix of labels of training data.
%    xtest  [Ntest x Nfeat matrix]	: matrix of feature values of test data
%    ttest  [Ntest x 1 matrix]		: matrix of labels of test data
%    classification [string]        : binary or mult-class classification ('binary' or 'multi')
%    steps  [N_iter x 1 matrix]     : Number (or proportion) of features to be survived in each feature elimination steps
%                                     If all components of steps <= 1, the values are treated as proportion to the number of total features.
%-- Outputs
%    errTable_tr : error table for training data set (fitting)
%    errTable_te : error table for ttest data set (fitting)
%    model       : other training parameters are included as a struct
%
% NOTE: for multiclass classification, we do not have full confidence.
% 
% Edited by SH 2014/Mar
% Modified by SH 2014/Jul

%% Preparation
% Get number of features
n_feat = size(xtrain,2);

% Change "steps" if it is defined as the proportion. 
if all(steps <= 1)
    steps = round(steps*n_feat);
end

% add SVM without feature elimination
steps = [steps(:);n_feat]; 

% remove components of steps > n_feat
steps(steps>n_feat) = []; 

% Re-order as descending and remove duplication in "steps"
steps = unique(steps);
steps = steps(end:-1:1);

% initialize 
ranking = zeros(1,n_feat);
xtrain_ori = xtrain;
j=1;

%% Iterative training & feature reduction
for i = steps(2:end)'
    survived_feat = find(ranking==0);
    % SVM
    xtrain = xtrain_ori(:,survived_feat);
    model_curr = svmtrain(ttrain, xtrain,Libsvm_options);
    ttrain_pred = svmpredict(ttrain, xtrain, model_curr);
    ttest_pred = svmpredict(ttest, xtest(:,ranking==0), model_curr);
    % RFE
      % compute weight
      if model_curr.nr_class == 2 % binary
          w = (model_curr.sv_coef' * full(model_curr.SVs))';
      else % multiclass
          k=1;
          clear w
          for class1 = 1:(model_curr.nr_class-1)
              for class2 = (class1+1):model_curr.nr_class
                  if class1 == 1
                      coef = [model_curr.sv_coef(1:model_curr.nSV(1),(class2-1)); model_curr.sv_coef(sum(model_curr.nSV(1:(class2-1))):sum(model_curr.nSV(1:class2)),1)];
                      SVs = [model_curr.SVs(1:model_curr.nSV(1),:); model_curr.SVs(sum(model_curr.nSV(1:(class2-1))):sum(model_curr.nSV(1:class2)),:)];
                      w(:,k) = SVs'*coef;k=k+1;
                  else
                      coef = [model_curr.sv_coef(sum(model_curr.nSV(1:(class1-1))):sum(model_curr.nSV(1:class1)),(class2-1)); model_curr.sv_coef(sum(model_curr.nSV(1:(class2-1))):sum(model_curr.nSV(1:class2)),(class1))];
                      SVs = [model_curr.SVs(sum(model_curr.nSV(1:(class1-1))):sum(model_curr.nSV(1:class1)),:); model_curr.SVs(sum(model_curr.nSV(1:(class2-1))):sum(model_curr.nSV(1:class2)),:)];
                      w(:,k) = SVs'*coef;k=k+1;
                  end
              end
          end
      end
    [temp, rank_curr] = sort(sum(w.^2,2)); % 1= most inefficient
    removed_feat = survived_feat(rank_curr(1:(sum(ranking==0)-i)));
    ranking(removed_feat)=j;
    % performance evaluation
    errTable_tr{j} = slr_error_table(ttrain,ttrain_pred);
    errTable_te{j} = slr_error_table(ttest,ttest_pred);
    j=j+1;
end
    % final SVM
    xtrain = xtrain_ori(:,ranking==0);
    model_curr = svmtrain(ttrain, xtrain,Libsvm_options);
    ttrain_pred = svmpredict(ttrain, xtrain, model_curr);
    ttest_pred = svmpredict(ttest, xtest(:,ranking==0), model_curr);
    % performance evaluation
    errTable_tr{j} = slr_error_table(ttrain,ttrain_pred);
    errTable_te{j} = slr_error_table(ttest,ttest_pred);
    % rank for survived features
    ranking(ranking==0)=j;
    
    % change order of ranking, i.e. 1=most efficient
    ranking = max(ranking) - ranking+1;

%% save parameters
model               = struct;
model.parameter{1}  = struct('name','num_of_feat','space',steps);
model.rank          = ranking; % "rank" may be used when you perform SVM-RFE based mapping.
