% Convert DICOM file to NIFTI file
% for all subjects, for all sessions and anatomical images.
%
% Input
%    MY_VAR
%         .load_dir          % string.
%         .subnames_load     % 1 x [Number of subjects] cell array. Each cell contains string.
%         .T1                % 1 x [Number of subjects] cell array. Each cell contains string.
%         .T2                % 1 x [Number of subjects] cell array. Each cell contains string.
%         .EPIs              % 1 x [Number of subjects] cell array. Each cell contains cell array of 1 x [Number of sessions].
%         .save_dir          % string.
%         .subnames_save     % 1 x [Number of subjects] cell array. Each cell contains string.
%         .anatomy_dir       % string.
%         .shortname         % 1 x N matrix.
%         .prescan_n         % Integer.
%
% 2014.08.26 modified by SH

function convert_DICOM_to_NIFTI(MY_VAR)
%% preparation
    c_dir = pwd;% remember current directory
    temp_dirn  = fullfile(MY_VAR.save_dir,'temp');% set temporary directory
    if ~(exist(temp_dirn,'dir')); mkdir(temp_dirn); end % make temporary directory if it is not exist

%% subject loop
for sub = 1:length(MY_VAR.subnames_load)
%% %%%%%%%%%%%%%%%%%%%
% functional images %%
%%%%%%%%%%%%%%%%%%%%%%
    sess_save = 0; % set session number zero
       
    %% session loop
    for sess_load = MY_VAR.EPIs{sub}

        sess_save = sess_save +1; % increse session number

        %% set directory to use
            frm_dirn   = fullfile(MY_VAR.load_dir,MY_VAR.subnames_load{sub},sess_load{1});
            to_dirn    = fullfile(MY_VAR.save_dir,MY_VAR.subnames_save{sub},int2str(sess_save));

        %% make and go to save folder
            if ~(exist(to_dirn,'dir')); mkdir(to_dirn); end
            cd(to_dirn); % cd to save folder 
        %% error if from_dir is not exist
            if ~(exist(frm_dirn,'dir')); error('WRONG FRM_DIRN'); end
            
        %% get DICOM data filename
            [data_path,dirs]  = spm_select('FPList',frm_dirn,'^*\.dcm$');

        %% copy raw DICOM files to temporary folder with shorter name(s.t. 1.dcm, 2.dcm, ...)
            for scans = 1:size(data_path,1)
                copyfile(deblank(data_path(scans,:)),fullfile(temp_dirn,[int2str(scans) '.dcm'])); 
            end

        %% convert DICOM to NIFTI
            % get temporary saved DICOM files path
            [data_path,dirs]  = spm_select('FPList',temp_dirn,'^*\.dcm$');

            %start converting
            hdrs = spm_dicom_headers(data_path); %read header
            spm_dicom_convert(hdrs, 'all', 'flat', 'img'); % convert DICOM to NIFTI and save it to current folder

            % delete temporary files
            delete(fullfile(temp_dirn,'*')); % delete temporary files

        %% make NIFTI file name shorter (0006.hdr, 0006.img, 0007.hdr, 0007.img, ...)

            % get NIFTI file name
            [P_img,dirs]  = spm_select('List',to_dirn,'^*\.img$');
            [P_hdr,dirs]  = spm_select('List',to_dirn,'^*\.hdr$');

            for scans = 1:size(P_img,1)
                if scans > MY_VAR.prescan_n
                    temp = int2str(scans);
                    temp = [strrep(int2str(zeros(1,4-length(temp))),' ','') temp '.img'];
                    movefile(P_img(scans,:),temp)
                    movefile(P_hdr(scans,:),strrep(temp,'img','hdr'))
                else
                    delete(P_img(scans,:)); % delete prescans
                    delete(P_hdr(scans,:)); % delete prescans
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
 if ~(exist(to_dirn,'dir')); mkdir(to_dirn); end; % make and go to save folder
 cd(to_dirn); % cd to save folder

%% T1
        %% set directory to use
            frm_dirn   = fullfile(MY_VAR.load_dir,MY_VAR.subnames_load{sub},MY_VAR.T1{sub});


        %% get DICOM data filename
            [data_path,dirs]  = spm_select('FPList',frm_dirn,'^*\.dcm$');

        %% copy raw DICOM files to temporary folder with shorter name(s.t. 1.dcm, 2.dcm, ...)
            for scans = 1:size(data_path,1)
                copyfile(deblank(data_path(scans,:)),fullfile(temp_dirn,[int2str(scans) '.dcm'])); 
            end

        %% convert DICOM to NIFTI
            % get temporary saved DICOM files path
            [data_path,dirs]  = spm_select('FPList',temp_dirn,'^*\.dcm$');

            %start converting
            hdrs = spm_dicom_headers(data_path); %read header
            spm_dicom_convert(hdrs, 'all', 'flat', 'img'); % convert DICOM to NIFTI and save it to current folder

            % delete temporary files
            delete(fullfile(temp_dirn,'*')); % delete temporary files

            %% make NIFTI file name shorter (T1.hdr, T1.img)
            [P_img,dirs]  = spm_select('List',to_dirn,'^s.*\.img$');% get NIFTI file name
            [P_hdr,dirs]  = spm_select('List',to_dirn,'^s.*\.hdr$');

            movefile(P_hdr,'T1.hdr'); % rename header and image files
           movefile(P_img,'T1.img'); 

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
            frm_dirn   = fullfile(MY_VAR.load_dir,MY_VAR.subnames_load{sub},MY_VAR.T2{sub});

        %% get DICOM data filename
            [P,dirs]  = spm_select('List',frm_dirn,'^*\.dcm$');
            data_path = [char(ones(size(P,1),1)*[frm_dirn filesep])  P]; % convert relative path name to absolute path

        %% copy raw DICOM files to temporary folder with shorter name(s.t. 1.dcm, 2.dcm, ...)
            for scans = 1:size(data_path,1)
                copyfile(deblank(data_path(scans,:)),fullfile(temp_dirn,[int2str(scans) '.dcm'])); 
            end

        %% convert DICOM to NIFTI
            % get temporary saved DICOM files path
            [P,dirs]  = spm_select('List',temp_dirn,'^*\.dcm$');
            data_path = [char(ones(size(P,1),1)*[temp_dirn filesep])  P]; % convert relative path name to absolute path

            %start converting
            hdrs = spm_dicom_headers(data_path); %read header
            spm_dicom_convert(hdrs, 'all', 'flat', 'img'); % convert DICOM to NIFTI and save it to current folder

            % delete temporary files
            delete(fullfile(temp_dirn,'*')); % delete temporary files

       %% make NIFTI file name shorter (T2.hdr, T2.img)
            [P_img,dirs]  = spm_select('List',to_dirn,'^s.*\.img$');% get NIFTI file name
            [P_hdr,dirs]  = spm_select('List',to_dirn,'^s.*\.hdr$');

            movefile(P_hdr,'T2.hdr'); % rename header and image files
            movefile(P_img,'T2.img'); 
end            
       %% Delete 'dicom_headers.mat'
       delete('dicom_headers.mat')

end % end subject loop
rmdir(temp_dirn)
cd(c_dir)