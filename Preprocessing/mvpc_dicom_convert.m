% Convert DICOM file to NIFTI file
% DICOM files in a directory is converted to NIFTI files.
% NIFTI files are separeted into subdirectories, following rule.
%
% Input
%         load_dir          % string.
%         save_dir          % string.
%         prefix            % string.
%
% 2014.08.26 coded by SH (modified from convert_DICOM_to_NIFITI.m

function mvpc_dicom_convert(load_dir,save_dir,prefix)

%% error if load directory is not exist
if ~(exist(load_dir,'dir')); error('WRONG FRM_DIRN'); end

%% preparation
c_dir = pwd;% remember current directory

%% temporary directory (necessary to avoid errors due to too long DICOM filename)
temp_dirn  = fullfile(save_dir,'temp');% set temporary directory
if ~(exist(temp_dirn,'dir')); mkdir(temp_dirn); end % make temporary directory if it is not exist

%% save directory
if ~(exist(save_dir,'dir')); mkdir(save_dir); end % make temporary directory if it is not exist

%% replace spacial characters
prefix = strrep(prefix,'.','\.');
prefix = strrep(prefix,'^','\^');

data_path = spm_select('FPList',load_dir,['^', prefix, '.*\.(DCM|dcm)$']);

disp(['converting'])
disp(data_path(1:min(5,size(data_path,1)),:))
if 5<size(data_path,1); disp(['etc. (' int2str(size(data_path,1)) ' files)']); end
disp('to')
disp(save_dir)

%% copy raw DICOM files to temporary folder with shorter name(s.t. 1.dcm, 2.dcm, ...)
for scans = 1:size(data_path,1)
copyfile(deblank(data_path(scans,:)),fullfile(temp_dirn,[int2str(scans) '.dcm']));
end

%% convert DICOM to NIFTI
% get temporary saved DICOM files path
[data_path,dirs]  = spm_select('FPList',temp_dirn,'^*\.dcm$');

cd(save_dir)

%start converting
hdrs = spm_dicom_headers(data_path); %read header
spm_dicom_convert(hdrs, 'all', 'flat', 'img'); % convert DICOM to NIFTI and save it to current folder

% delete temporary files
delete(fullfile(temp_dirn,'*')); % delete temporary files
rmdir(temp_dirn)
cd(c_dir)