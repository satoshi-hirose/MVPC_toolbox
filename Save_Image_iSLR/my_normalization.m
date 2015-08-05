% template: Normalze parameter file ('T1_sn.mat')
% fname:    cell structure of files. 

function my_normalization(fname,template) 

%% normalization
                % set parameters
            jobs{1}.spatial{1}.normalise{1}.write.subj(1).matname{1}        = template;
            jobs{1}.spatial{1}.normalise{1}.write.subj(1).resample = fname;
            jobs{1}.spatial{1}.normalise{1}.write.roptions         =  ...
            struct(     'preserve',	{0}, ...
                        'bb',       {[-78,-112,-72;78,76,85;]}, ...
                        'vox',      [2 2 2], ...
                        'interp',   0, ...
                        'wrap',     [0 0 0] );
            % run_job
              spm_jobman('run',jobs);