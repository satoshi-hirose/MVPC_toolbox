function [errTable_tr,errTable_te,model] = islr(xtrain,ttrain,xtest,ttest,repn,classification)

% number of features
n_feat = size(xtrain,2);

% initialization
esti_curr_te_prob = ones(length(unique(ttrain)),length(ttest));
esti_curr_tr_prob = ones(length(unique(ttrain)),length(ttrain));

% iterative training and test
for i = 1:repn
    fprintf('%s / %s \n',int2str(i),int2str(repn))
    
    if ~isempty(xtrain)
        [errTable_tr{i,1},errTable_te{i,1},model2{i,1}] = slr_clsfy(xtrain,ttrain,xtest,ttest,classification);
    else % if no feature exists,
        % estimate all labels as 1 without training
        errTable_tr{i,1}        = slr_error_table(ttrain,ones(size(ttrain)));
        errTable_te{i,1}        = slr_error_table(ttest,ones(size(ttest)));
        model2{i,1}.ww          = 0;
        model2{i,1}.Ptr         = calc_percor(errTable_tr{i,1});
        model2{i,1}.Pte         = calc_percor(errTable_te{i,1});
    end
    
    % feature reduction
    xtrain                  = xtrain(:,(sum(model2{i,1}.ww(1:end-1,:),2)==0));
    xtest                   =  xtest(:,(sum(model2{i,1}.ww(1:end-1,:),2)==0));
    
    % prediction of a single SLR sub-classifier
    [xxx, esti_te{i,1}]     = max(model2{i,1}.Pte');
    [xxx, esti_tr{i,1}]     = max(model2{i,1}.Ptr');
    
    % percent correct for a single SLR sub-classifier
    percent_corr_te{i,1}    = calc_percor(errTable_te{i,1}) ;
    percent_corr_tr{i,1}    = calc_percor(errTable_tr{i,1}) ;
    
    
    % probability voting
    % for test data
    esti_curr_te_prob               = esti_curr_te_prob .* model2{i,1}.Pte';
    [xxx, voting_esti_te_prob{i,1}] = max(esti_curr_te_prob);
    errTable_te_vote_prob{i,1}      = slr_error_table(ttest,voting_esti_te_prob{i,1}');
    percent_corr_te_vote_prob{i,1}  = calc_percor(errTable_te_vote_prob{i,1});
    
    esti_te_prob{i,1}               = esti_curr_te_prob';
    
    % for training data
    esti_curr_tr_prob               = esti_curr_tr_prob .* model2{i,1}.Ptr';
    [xxx, voting_esti_tr_prob{i,1}] = max(esti_curr_tr_prob);
    errTable_tr_vote_prob{i,1}      = slr_error_table(ttrain,voting_esti_tr_prob{i,1}');
    percent_corr_tr_vote_prob{i,1}  = calc_percor(errTable_tr_vote_prob{i,1});
    
    esti_tr_prob{i,1}               = esti_curr_tr_prob';
    
    %                 % simple voting
    %                     % for test data
    %                         esti_curr_te                = cell2mat(esti_te);
    %                         voting_esti_te{i,1}         = mode(esti_curr_te,1);
    %                         errTable_te_vote{i,1}       = slr_error_table(ttest,voting_esti_te{i,1}');
    %                         percent_corr_te_vote{i,1}   = calc_percor(errTable_te_vote{i,1});
    %
    %                     % for training data
    %                         esti_curr_tr                = cell2mat(esti_tr);
    %                         voting_esti_tr{i,1}         = mode(esti_curr_tr,1);
    %                         errTable_tr_vote{i,1}       = slr_error_table(ttrain,voting_esti_tr{i,1}');
    %                         percent_corr_tr_vote{i,1}   = calc_percor(errTable_tr_vote{i,1});
    
    
    
end


%% compute weight of each meta classifiers
temp   = zeros(size(model2{1}.ww,1)-1,size(model2{1}.ww,2));    % temp = [(number of voxels), (number of labels)
temp_2 = 1:n_feat;                                           % temp2 = 1:(number of voxels)
const = zeros(1,size(model2{1}.ww,2)); % constant term
for i = 1:repn
    const = const+ model2{i}.ww(end,:);
    
    temp(temp_2,:) = model2{i}.ww(1:(end-1),:);
    temp_2 = temp_2(~logical(sum(model2{i}.ww(1:end-1,:),2)));
    model3{i,1}.ww = [temp;const];
end

%% replace results
% parameter (number of iteration)
for i = 1:repn
    model3{i,1}.repn = i;
end

for i = 1:repn
    model3{i,1}.Ptr = esti_tr_prob{i,1};
    model3{i,1}.Pte = esti_te_prob{i,1};
end

for i = 1:repn
    Pte_sub{i,1} = model2{i}.Pte;
    Ptr_sub{i,1} = model2{i}.Ptr;
end

model        = struct(  'parameter',                {{struct('name','num_of_rep','space',(1:repn)')}},...
    'model',                    {model3},...
    'esti_te_sub',              {esti_te},...
    'esti_tr_sub',              {esti_tr},...
    'percor_te_sub',            {percent_corr_te},...
    'percor_tr_sub',            {percent_corr_tr},...
    'errTable_te_sub',          {errTable_te},...
    'errTable_tr_sub',          {errTable_tr},...
    'Pte_sub',                  {Pte_sub},...
    'Ptr_sub',                  {Ptr_sub},...
    'esti_te_meta',             {voting_esti_te_prob},...
    'esti_tr_meta',             {voting_esti_tr_prob},...
    'errTable_te_meta',         {errTable_te_vote_prob},...
    'errTable_tr_meta',         {errTable_tr_vote_prob},...
    'percor_te_meta',           {percent_corr_te_vote_prob},...
    'percor_tr_meta',           {percent_corr_tr_vote_prob});

% re-define the outputs 'errTable_tr' and 'errTable_te' as the
% performance of meta-classifier
errTable_te = model.errTable_te_meta;
errTable_tr = model.errTable_tr_meta;
if length(errTable_te) < repn
    errTable_te = [errTable_te; repmat(errTable_te(end),repn - length(errTable_te),1)];
    errTable_tr = [errTable_tr; repmat(errTable_tr(end),repn - length(errTable_te),1)];
end




function [errTable_tr,errTable_te,model] = slr_clsfy(xtrain,ttrain,xtest,ttest,classification)

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
