function my_spm_run(MY_VAR)

% make SPM job & run it. for all subjects in MY_VAR.subnames
% This script make many files in appropriate directories.
% for detail, see descriptions in SPM toolbox.
% 
% SPM batch files will be saved in MY_VAR.analyze_dir
% input:
%      MY_VAR
%         .prefix               1 x 4 logical matrix (1 or 0).
%         .subnames             1 x [Number of subjects] cell array.
%         .SPM_method           1 x N cell array.
%         .sessions             1 x [Number of subjects] cell array. Each cell contains 1 x [Number of sessions] cell array.
%         .analyze_dir          String.
%         .anatomy_dir          String.
%         .normalize_template   String.
%         .SPMdir               String.
%         .psychdir             String.
%         .TR                   Number.
%         .slice_order          1 x [number of slices] integer matrix.
%         .contrasts.name       1 x [number of contrast] cell array. Each cell contains string.
%         .contrasts.con        1 x [number of contrast] cell array. Each cell contains 1 x [number of model] matrix.
%
% 2010/June/3 SH
% 2010/June/7 SH
% 2010/JUNE/8 SH
% 2014/Mar.   SH Add Coregistration without T2 sameslice.

c_dir = cd;

%% subject loop
for sub = 1:length(MY_VAR.subnames)
    subname = MY_VAR.subnames{sub};
% check flags
    slicetiming_flag        = MY_VAR.prefix(1); % 2010/JUNE/8 SH
    reslice_flag            = MY_VAR.prefix(2);
    normalize_flag          = MY_VAR.prefix(3);
    smoothing_flag          = MY_VAR.prefix(4);    
%% method loop
for methodn = 1:length(MY_VAR.SPM_method)
    method = MY_VAR.SPM_method{methodn};
    jobs =[];
    prefix = set_prefix(slicetiming_flag,reslice_flag, normalize_flag,smoothing_flag);

    switch method
        case 'slice_timing'
        %% slice timing correction
            
            data        =   get_img(fullfile(MY_VAR.analyze_dir, MY_VAR.subnames{sub}), MY_VAR.sessions{sub}, prefix);

            first_slice =   data{1}(1,:);
            temp = spm_vol(first_slice);
            slice_num   =   temp.dim(3);

            jobs{1}.temporal{1}.st.scans    = data;
            jobs{1}.temporal{1}.st.nslices  = slice_num;
            jobs{1}.temporal{1}.st.tr       = MY_VAR.TR;
            jobs{1}.temporal{1}.st.ta       = MY_VAR.TR - (MY_VAR.TR/slice_num);
            jobs{1}.temporal{1}.st.so       = MY_VAR.slice_order;
            jobs{1}.temporal{1}.st.refslice = floor(slice_num/2+1);

            slicetiming_flag = 1;

        case 'realign'
        %% realignment
            data        =   get_img(fullfile(MY_VAR.analyze_dir, MY_VAR.subnames{sub}), MY_VAR.sessions{sub}, prefix);
            
            jobs{1}.spatial{1}.realign{1}.estimate.data     = data; %cell array
            jobs{1}.spatial{1}.realign{1}.estimate.eoptions = ...
                struct(    'quality', {1}, ...
                           'sep'    , {4}, ...
                           'fwhm'   , {5}, ...
                           'rtm'    , {0}, ...
                           'interp' , {2}, ...
                           'wrap'   , {[0 0 0]},...
                           'weight' , {{}}              );
                       

            
            
        case 'coregister'
        %% coregister
            % get first EPI
            data        =   get_img(fullfile(MY_VAR.analyze_dir, MY_VAR.subnames{sub}), MY_VAR.sessions{sub}, prefix);
            EPI         =   data{1}(1,:);

            % get T1&T2 anatomy
            dirana      = fullfile(MY_VAR.analyze_dir, MY_VAR.subnames{sub}, MY_VAR.anatomy_dir);
            T1          = fullfile(dirana,'T1.img');
            T2          = fullfile(dirana,'T2.img');

        if exist(T2, 'file') % with T2 sameslice exist
            % set parameters for sameslice -> EPI
            jobs{1}.spatial{1}.coreg{1}.estimate.ref{1}        = EPI; 
            jobs{1}.spatial{1}.coreg{1}.estimate.source{1}     = T2; 
            jobs{1}.spatial{1}.coreg{1}.estimate.other{1}      = '';
            jobs{1}.spatial{1}.coreg{1}.estimate.eoptions      = ...
                struct(    'cost_fun', {'nmi'}, ...
                           'sep'     , {[4,2]}, ...
                           'tol'     , {[0.02,0.02,0.02,0.001,0.001,0.001,0.01,0.01,0.01,0.001,0.001,0.001]},...
                           'fwhm'    , {[7,7]}          );  

            % set parameters for sameslice -> EPI

            jobs{2}.spatial{1}.coreg{1}.estimate.ref{1}        = T2; %cell array
            jobs{2}.spatial{1}.coreg{1}.estimate.source{1}     = T1; %cell array
            jobs{2}.spatial{1}.coreg{1}.estimate.other{1}      = '';
            jobs{2}.spatial{1}.coreg{1}.estimate.eoptions      = ...
                struct(    'cost_fun', {'nmi'}, ...
                           'sep'     , {[4,2]}, ...
                           'tol'     , {[0.02,0.02,0.02,0.001,0.001,0.001,0.01,0.01,0.01,0.001,0.001,0.001]},...
                           'fwhm'    , {[7,7]}          );
        else
            % set parameters for sameslice -> EPI
            jobs{1}.spatial{1}.coreg{1}.estimate.ref{1}        = EPI; 
            jobs{1}.spatial{1}.coreg{1}.estimate.source{1}     = T1; 
            jobs{1}.spatial{1}.coreg{1}.estimate.other{1}      = '';
            jobs{1}.spatial{1}.coreg{1}.estimate.eoptions      = ...
                struct(    'cost_fun', {'nmi'}, ...
                           'sep'     , {[4,2]}, ...
                           'tol'     , {[0.02,0.02,0.02,0.001,0.001,0.001,0.01,0.01,0.01,0.001,0.001,0.001]},...
                           'fwhm'    , {[7,7]}          );  

        end
            

        case 'reslice' 
        %% reslice % 2010/JUNE/8 SH
            % get first EPI and 
            data        =   get_img(fullfile(MY_VAR.analyze_dir, MY_VAR.subnames{sub}), MY_VAR.sessions{sub}, prefix);
            data        =   strvcat(data);                                    % change cell array to matrix
            data        =   mat2cell(data,ones(size(data,1),1),size(data,2)); % change matrix to cell array (each cell is file name of one EPI image)
            first_EPI   =   data{1};
            
            jobs{1}.spatial{1}.coreg{1}.write.ref{1} = first_EPI;
            jobs{1}.spatial{1}.coreg{1}.write.source = data;

            jobs{1}.spatial{1}.coreg{1}.write.roptions        = ...
                struct( 'interp', 1, ...
                        'wrap'  , [0 0 0], ...
                        'mask'  , 0 );
           reslice_flag            = 1;
        case 'normalize'
        %% normalization
        
            %% get img files(EPI)
            data        =   get_img(fullfile(MY_VAR.analyze_dir, MY_VAR.subnames{sub}), MY_VAR.sessions{sub}, prefix);
            data        =   strvcat(data);                                    % change cell array to matrix
            data        =   mat2cell(data,ones(size(data,1),1),size(data,2)); % change matrix to cell array (each cell is file name of one EPI image)
            %% get T1 anatomy
            dirana          = fullfile(MY_VAR.analyze_dir, MY_VAR.subnames{sub}, MY_VAR.anatomy_dir);
            T1              = fullfile(dirana,'T1.img');
            data{end+1,1}   = T1;

            
            %% set parameters
            jobs{1}.spatial{1}.normalise{1}.estwrite.subj.source{1}      = T1; %cell array
            jobs{1}.spatial{1}.normalise{1}.estwrite.subj.wtsrc          = {}; %cell array
            jobs{1}.spatial{1}.normalise{1}.estwrite.subj.resample       = data; %cell array
            jobs{1}.spatial{1}.normalise{1}.estwrite.eoptions            =  ...
            struct(    'template'  ,{{[MY_VAR.normalize_template ',1']}},...
                       'weight'    ,{{}},...
                       'smosrc'    ,{8},...
                       'smoref'    ,{0},...
                       'regtype'   ,{'mni'},...
                       'cutoff'    ,{25},...
                       'nits'      ,{16},...
                       'reg'       ,{1}                );


            jobs{1}.spatial{1}.normalise{1}.estwrite.roptions         =  ...
            struct(     'preserve',	{0}, ...
                        'bb',       {[-78,-112,-72;78,76,85;]}, ...
                        'vox',      [2 2 2], ...
                        'interp',   1, ...
                        'wrap',     [0 0 0] );
           
            normalize_flag          = 1;

            
            
            


            
            
        case 'smoothing'
        %% smoothing
            % get EPIs
            %% get img files(EPI)
            data        =   get_img(fullfile(MY_VAR.analyze_dir, MY_VAR.subnames{sub}), MY_VAR.sessions{sub}, prefix);
            data        =   strvcat(data);                                    % change cell array to matrix
            data        =   mat2cell(data,ones(size(data,1),1),size(data,2)); % change matrix to cell array (each cell is file name of one EPI image)
  
            % set parameters

            jobs{1}.spatial{1}.smooth.data         = data; %cell array
            jobs{1}.spatial{1}.smooth.fwhm         = [8 8 8]; 
            jobs{1}.spatial{1}.smooth.dtype        = 0;
            
            
            smoothing_flag = 1; %Added by SH 2011/11/22
    
        case 'first_level'
        %% first level analysis
        % make directory for SPM
        to_dirn = fullfile(MY_VAR.analyze_dir, MY_VAR.subnames{sub},MY_VAR.SPMdir);
        if ~(exist(to_dirn,'dir'))
        mkdir(to_dirn)
        end

        
        data        =   get_img(fullfile(MY_VAR.analyze_dir, MY_VAR.subnames{sub}), MY_VAR.sessions{sub}, prefix);
        
        % set parameters
        jobs{1}.stats{1}.fmri_spec.dir{1} = to_dirn;
        jobs{1}.stats{1}.fmri_spec.timing=struct(...
            'units',    {'secs'},...
            'RT',       {MY_VAR.TR},...
            'fmri_t',   {16}, ...
            'fmri_t0',  {1}             );

        for sess = 1:length(MY_VAR.sessions{sub}) 

            % get session img data (vertical cell array: each cell contatins one volume)
            data_sess =  mat2cell(data{sess},ones(size(data{sess},1),1),size(data{sess},2));  
    
            % get session head_movement text data
            if iscell(MY_VAR.sessions{sub})
                dirn_sess = fullfile(MY_VAR.analyze_dir, MY_VAR.subnames{sub},MY_VAR.sessions{sub}{sess}); % modified on 2010/June/07
            else
                dirn_sess = fullfile(MY_VAR.analyze_dir, MY_VAR.subnames{sub},int2str(MY_VAR.sessions{sub}(sess))); % modified on 2010/June/07
            end
            
            [P,dirs]=spm_select('List',dirn_sess,'^*\.txt$');
            head_data=fullfile(dirn_sess,P);  
            
            % get multiple_design
            if iscell(MY_VAR.sessions{sub})
                multiple_design_file = fullfile(MY_VAR.analyze_dir,MY_VAR.subnames{sub},MY_VAR.psychdir,[MY_VAR.multi_des_prefix  MY_VAR.sessions{sub}{sess}]);
            else
                multiple_design_file = fullfile(MY_VAR.analyze_dir,MY_VAR.subnames{sub},MY_VAR.psychdir,[MY_VAR.multi_des_prefix  int2str(MY_VAR.sessions{sub}(sess))]);
            end
            
            % set parameters for session
            jobs{1}.stats{1}.fmri_spec.sess(sess).scans         = data_sess;
            jobs{1}.stats{1}.fmri_spec.sess(sess).cond          = struct([]);
            jobs{1}.stats{1}.fmri_spec.sess(sess).multi{1}      = multiple_design_file;
            jobs{1}.stats{1}.fmri_spec.sess(sess).regress       = struct([]);
            jobs{1}.stats{1}.fmri_spec.sess(sess).multi_reg{1}  = head_data;
            jobs{1}.stats{1}.fmri_spec.sess(sess).hpf           = 128;
        end
  
            % set session independent parameters
            jobs{1}.stats{1}.fmri_spec.fact               = struct([]);
            jobs{1}.stats{1}.fmri_spec.bases.hrf.derivs   = [0,0];
            jobs{1}.stats{1}.fmri_spec.volt               = 1;
            jobs{1}.stats{1}.fmri_spec.global             = 'none';
            jobs{1}.stats{1}.fmri_spec.mask{1}            = '';
            jobs{1}.stats{1}.fmri_spec.cvi                = 'AR(1)';
            
            % set parameters for estimation
            jobs{1}.stats{2}.fmri_est.spmmat{1}           = fullfile(to_dirn,'SPM.mat');
            jobs{1}.stats{2}.fmri_est.method.Classical    = 1;
      
            
            
            
            
        case 'make_contrast'
        %% make contrasts
            % set subject specific parameter
            SPM_file = fullfile(MY_VAR.analyze_dir,MY_VAR.subnames{sub},MY_VAR.SPMdir,'SPM.mat');
            jobs{1}.stats{1}.con.spmmat{1} = SPM_file;
            jobs{1}.stats{1}.con.delete    = 0;

            % 2014/JAN/10 SH 
            n_beta = 0;
            while exist(fullfile(MY_VAR.analyze_dir,MY_VAR.subnames{sub},MY_VAR.SPMdir,['beta_' repmat('0',1,4-length(int2str(n_beta+1))) int2str(n_beta+1) '.hdr']));
                n_beta = n_beta +1;
            end

            % set contrasts
            for conn = 1:length(MY_VAR.contrasts.name)
                jobs{1}.stats{1}.con.consess{conn}.tcon.name     = MY_VAR.contrasts.name{conn};
                
            % 2014/JAN/10 SH 
                if length(MY_VAR.contrasts.con{conn}) == n_beta || length(MY_VAR.contrasts.con{conn}) == (n_beta - length(MY_VAR.sessions{sub}))
                    % full desigin is explicitly modeled        or only the session constants is not modeled. don't care about the constants. SPM will automatically add zeros.
                    jobs{1}.stats{1}.con.consess{conn}.tcon.convec   = MY_VAR.contrasts.con{conn};
                else % the session constant & head movement artifacts are not modeled. The session include the same condition with the same order. 
                    jobs{1}.stats{1}.con.consess{conn}.tcon.convec   = repmat([MY_VAR.contrasts.con{conn} zeros(1,6)],[1 length(MY_VAR.sessions{sub})]);
                end
                
                jobs{1}.stats{1}.con.consess{conn}.tcon.sessrep   = 'none';
            end    
    end
 %% run SPM
 if ~exist(MY_VAR.SPM_log_dir,'dir'); mkdir(MY_VAR.SPM_log_dir); end
    cd(MY_VAR.SPM_log_dir);
    spm_jobman('run',jobs);
    time = clock;
    yr      = int2str(time(1));
    month   = int2str(time(2)); if length(month)==1; month  = ['0' month]; end
    day     = int2str(time(3)); if length(day)  ==1; day    = ['0' day];   end 
    hur     = int2str(time(4)); if length(hur)  ==1; hur    = ['0' hur];   end
    mins    = int2str(time(5)); if length(mins) ==1; mins   = ['0' mins];  end
    
    save(fullfile(MY_VAR.SPM_log_dir,[method yr month day hur mins]), 'jobs')
    fprintf('sub %d/%d name: %s method: %s complete! %s-%s-%s %s:%s \n',sub,length(MY_VAR.subnames),subname,method,yr,month,day,hur,mins);
    
    
    if strmatch(method,'normalize')
                % 2010/JUNE/8 SH
            cwwd = pwd;
            cd(dirana);
            jobs_2{1}.util{1}.defs.comp{1}.sn2def.matname = {fullfile(dirana,'T1_sn.mat')};
            jobs_2{1}.util{1}.defs.comp{1}.sn2def.vox     = [NaN,NaN,NaN];
            jobs_2{1}.util{1}.defs.comp{1}.sn2def.bb      = [NaN,NaN,NaN;NaN,NaN,NaN];
            jobs_2{1}.util{1}.defs.ofname                 = 'deformation_sn';
            jobs_2{1}.util{1}.defs.fnames                 = {''};
            jobs_2{1}.util{1}.defs.interp                 = 1;
            spm_jobman('run',jobs_2);
            cd(cwwd);
    end    
    
    
end
end
cd(c_dir)
%% subfunctions

% set prefix
function prefix = set_prefix(slicetiming_flag,reslice_flag, normalize_flag,smoothing_flag)
prefix ='0';                                                % modified on 2010/June/7
if slicetiming_flag ; prefix = ['a' prefix] ;end            % modified on 2010/June/8
if reslice_flag     ; prefix = ['r' prefix] ;end
if normalize_flag   ; prefix = ['w' prefix] ;end
if smoothing_flag   ; prefix = ['s' prefix] ;end

% get img
function data = get_img(parent_dirn, sess_dirs, prefix)

    for sess = 1:length(sess_dirs)
        if iscell(sess_dirs(sess));
            dirn = fullfile(parent_dirn,sess_dirs{sess});
        else
            dirn = fullfile(parent_dirn,int2str(sess_dirs(sess)));
        end
        [data{sess},dirs]=spm_select('FPList',dirn,['^' prefix '.*\.img$']);
    end



