% Convert DICOM file to NIFTI file
% for all subjects, for all sessions and anatomical images.
%
% Input
%    MY_VAR
%         .load_dir          % string.
%         .subnames_load     % 1 x [Number of subjects] cell array. Each cell contains string.
%         .T1                % 1 x [Number of subjects] cell array. Each cell contains string.
%         .T2(optional)      % 1 x [Number of subjects] cell array. Each cell contains string.
%         .EPIs              % 1 x [Number of subjects] cell array. Each cell contains cell array of 1 x [Number of sessions].
%         .save_dir          % string.
%         .subnames_save     % 1 x [Number of subjects] cell array. Each cell contains string.
%         .anatomy_dir       % string.
%         .shortname         % 1 x N matrix.
%         .prescan_n         % Integer.
%
% 2014.08.26 modified by SH

function convert_DICOM_to_NIFTI(MY_VAR)


%% subject loop
for sub = 1:length(MY_VAR.subnames_load)
    %% %%%%%%%%%%%%%%%%%%%
    % functional images %%
    %%%%%%%%%%%%%%%%%%%%%%
    sess_save = 0; % set session number to zero

    %% session loop
    for sess_load = MY_VAR.EPIs{sub}

        sess_save = sess_save +1; % increse session number

        %% set directory to use
        frm_dirn   = fullfile(MY_VAR.load_dir,MY_VAR.subnames_load{sub});
        to_dirn    = fullfile(MY_VAR.save_dir,MY_VAR.subnames_save{sub},int2str(sess_save));
        prefix     = sess_load{1};

        mvpc_dicom_convert(frm_dirn,to_dirn,prefix)

        %% make NIFTI file name shorter (0006.hdr, 0006.img, 0007.hdr, 0007.img, ...)
        % get NIFTI file name
        [P_img,dirs]  = spm_select('List',to_dirn,'^*\.img$');
        [P_hdr,dirs]  = spm_select('List',to_dirn,'^*\.hdr$');

        for scans = 1:size(P_img,1)
            if scans > MY_VAR.prescan_n
                movefile(fullfile(to_dirn,P_img(scans,:)),fullfile(to_dirn,P_img(scans,MY_VAR.shortname)))
                movefile(fullfile(to_dirn,P_hdr(scans,:)),fullfile(to_dirn,P_hdr(scans,MY_VAR.shortname)))
            else
                delete(fullfile(to_dirn,P_img(scans,:))); % delete prescans
                delete(fullfile(to_dirn,P_hdr(scans,:))); % delete prescans
            end
        end % end NIFTI files loop

        %%
        fprintf('subject %2.0f/%2.0f session %2.0f/%2.0f complete.\n', sub, length(MY_VAR.subnames_load),sess_save,length(MY_VAR.EPIs{sub}));
    end % end session loop

    %% %%%%%%%%%%%%%%%%%%
    %%% anatomy files %%%
    %%%%%%%%%%%%%%%%%%%%%
    %% set & make anatomy folder
    to_dirn    = fullfile(MY_VAR.save_dir,MY_VAR.subnames_save{sub},MY_VAR.anatomy_dir);

    %% T1
    %% set directory to use
    frm_dirn   = fullfile(MY_VAR.load_dir,MY_VAR.subnames_load{sub});

    %% prefix
    prefix = MY_VAR.T1{sub};

    mvpc_dicom_convert(frm_dirn,to_dirn,prefix)

    %% make NIFTI file name shorter (T1.hdr, T1.img)
    [P_img,dirs]  = spm_select('List',to_dirn,'^s.*\.img$');% get NIFTI file name
    [P_hdr,dirs]  = spm_select('List',to_dirn,'^s.*\.hdr$');

    movefile(fullfile(to_dirn,P_hdr),fullfile(to_dirn,'T1.hdr')); % rename header and image files
    movefile(fullfile(to_dirn,P_img),fullfile(to_dirn,'T1.img'));

    %% T2

    %% check whether T2 will be used. 2014/Mar. added by SH
    try
        MY_VAR.T2{sub};
        if ~exist(fullfile(MY_VAR.load_dir,MY_VAR.subnames_load{sub},MY_VAR.T2{sub}),'dir')
            error('')
        end
        T2flg = 1;
    catch
        T2flg = 0;
    end

    if T2flg == 1
        %% set directory to use
        frm_dirn   = fullfile(MY_VAR.load_dir,MY_VAR.subnames_load{sub});

        %% prefix
        prefix = MY_VAR.T2{sub};

        mvpc_dicom_convert(frm_dirn,to_dirn,prefix)


        %% make NIFTI file name shorter (T2.hdr, T2.img)
        [P_img,dirs]  = spm_select('List',to_dirn,'^s.*\.img$');% get NIFTI file name
        [P_hdr,dirs]  = spm_select('List',to_dirn,'^s.*\.hdr$');

    movefile(fullfile(to_dirn,P_hdr),fullfile(to_dirn,'T2.hdr')); % rename header and image files
    movefile(fullfile(to_dirn,P_img),fullfile(to_dirn,'T2.img'));
    end

end