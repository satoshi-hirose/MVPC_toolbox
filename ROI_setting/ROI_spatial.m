%% ROI_spatial
% Save spatial ROI parameter files.
%
% input:
%   MY_VAR
%      .analyze_dir         string
%      .anato_map           string
%      .subnames            1 x N_sub cell array
%      .to_dirn             string
%      .SPMdir              string
%      .decoding_dir        string
%
% %% ROI parameters
% % Five types of ROI selsction are available.
% 
% %% Whole-brain analysis.
% % The boundary is determined by SPM
% MYV.ROI_spatial.spatial_ROIs(1).method          = 'whole_brain';
% 
% %% Anatomical structure based ROIs.
% % The brain areas that is determined by Anatomical Toolbox are selected.
% % This example selectes birateral M1.
% % (Area 4a, Area 4p)
% % First row indicates the index of the area (see Area List below).
% % Second row indicates the hemisphere (-1: Left, 1: Right).
% MYV.ROI_spatial.spatial_ROIs(2).method          = 'anat';
% MYV.ROI_spatial.spatial_ROIs(2).areas           = [29,-1;29,1;37,-1;37,1];
% 
% %% Functinal mapping based ROI.
% % The voxels that have higher t-score than the threshold are selected.
% % The treshold can be determined with 
% % T-score itself or number of voxels.
% % if MYV.ROI_spatial.spatial_ROIs(3).threshold >= 100,
% % program assumes thoreshold was defined by number of voxels.
% % ex.
% % .threshold = 1000 -> top 1,000 voxels are selected.
% % .threshold = 3    -> voxels with t-value > 3 are selected.
% 
% MYV.ROI_spatial.spatial_ROIs(3).method          = 'func';
% MYV.ROI_spatial.spatial_ROIs(3).act_map         = 'spmT_0003.img';
% MYV.ROI_spatial.spatial_ROIs(3).threshold       = 1000;
% 
% %%  Intersection of Anatomical and Functional ROI
% % The voxels with T values > the threshold in the certain brain areas are selected.
% % Like Functional ROI, when the thoeshold is defined with the number >= 100,
% % the script assumes that the threshold is defined with the number of the voxels to be selected,
% % rather than t-score itself.
% 
% % This Example selects top 100 voxels in the birateral M1.
% MYV.ROI_spatial.spatial_ROIs(4).method          = 'anat_and_func';
% MYV.ROI_spatial.spatial_ROIs(4).areas           = [29,-1;29,1;37,-1;37,1];
% MYV.ROI_spatial.spatial_ROIs(4).act_map         = 'spmT_0003.img';
% MYV.ROI_spatial.spatial_ROIs(4).threshold       = 100;

function ROI_spatial(MY_VAR)
%% check & load anatomical toolbox map, check SPM directory
if isfield(MY_VAR,'anato_map')  ; load(MY_VAR.anato_map); else disp('no Anatomical map defined'); end % load anatomy toolbox map
if ~isfield(MY_VAR,'SPMdir')    ; disp('no SPM result defined'); end

%% subject loop
for sub = 1:length(MY_VAR.subnames)
    
    % set directory including SPM.mat and spmT_XXX.
        if isfield(MY_VAR,'SPMdir'); spm_dir = fullfile(MY_VAR.analyze_dir,MY_VAR.subnames{sub},MY_VAR.SPMdir); end
    
    % set & make directory for save ROI
        to_dirn     = fullfile(MY_VAR.analyze_dir,MY_VAR.subnames{sub},MY_VAR.decoding_dir,MY_VAR.to_dirn);
        if exist(to_dirn,'dir'); error('ROI files already exist'); end
        mkdir(to_dirn);
    
    %% ROI definitions loop
    for ROI_num = 1:length(MY_VAR.spatial_ROIs)
        % extract current ROI definition
            ROI_param   =   MY_VAR.spatial_ROIs(ROI_num);
        
        %% switch method
        switch ROI_param.method
            case 'anat'
                %% anatomical ROI from anatomical MAP
                % combine multiple anatomical ROIs
                % The voxels with probability > 0 are selected.
                ROI             = [];
                for arean = 1:size(ROI_param.areas,1)
                    ROI_LR          = MAP(ROI_param.areas(arean,1)).XYZmm;
                    ROI_one_region  = ROI_LR(:,(MAP(ROI_param.areas(arean,1)).LR == ROI_param.areas(arean,2)));
                    ROI             = [ROI ROI_one_region]; 
                end
                
                % make header information
                ROI_hdr = MAP(1).MaxMap;
                ROI_hdr.descrip = 'spm - 3D normalized';
                
                % output is normalized mm coordinats
                
            case 'func'
                %% Functional ROI form SPM analysis (T-map)
                % The voxels with T values > the threshold are selected.
                % When the thoeshold is defined with the number >100,
                % the script assumes that the threshold is defined with the
                % number of the voxels to be selected,
                % rather than t-score itself.
                
                

                % get file path of the activation map (t-map)
                activity    = img2mat(fullfile(spm_dir,ROI_param.act_map));
                header      = spm_vol(fullfile(spm_dir,ROI_param.act_map));
                
                % check whether normalized brain or not
                temp = load(fullfile(spm_dir,'SPM'));
                header2 = spm_vol(deblank(temp.SPM.xY.P(1,:)));
                header.descrip = [header.descrip ' -- ' header2.descrip];

                % get dimension of the activation map and conversion matrix
                dim         = header.dim;
                convert_mat = header.mat;
                
                % Select above threshold voxel
                % in voxel coordinates (XYZ_ROI_all)
                % and mm corrdinates (XYZmm_ROI_all)
                
                    % Define the threshold.
                    % if the threshold >= 100, re-define the threshold with 
                    % t-value.
                    
                    % assume it means num of voxels
                    if ROI_param.threshold >= 100
                        temp = sort(activity(:),1,'descend');
                        
                        % error if the threshold > the number of available
                        % voxels.
                        if ROI_param.threshold >length(temp)
                            error('TOO LARGE N-of-VOXELS')
                        end
                        
                        % define the threshold T-value
                        threshold_height = temp(ROI_param.threshold);
                    
                    % assume it means t-value itself.
                    else
                        threshold_height = ROI_param.threshold;
                    end
                    
                    % Get the index of the voxels > threshold
                    % (voxel coordinates)
                    [XYZ_ROI_X,XYZ_ROI_Y,XYZ_ROI_Z] = ind2sub(dim,find(activity>=threshold_height & activity~=0));
                    XYZ_ROI_all                     = [XYZ_ROI_X';XYZ_ROI_Y';XYZ_ROI_Z'];
                    
                    % convert in mm coordinates
                    XYZmm_ROI_all                   =   convert_mat*[XYZ_ROI_all; ones(1, size(XYZ_ROI_all,2))];
                    XYZmm_ROI_all                   =   XYZmm_ROI_all(1:3,:);
                    
                    ROI         = XYZmm_ROI_all;
                    ROI_param.threshold_height = threshold_height;
                
                    ROI_hdr = header;
                
                    % output is subject or normalized mm coordinats
                    % Depends on the t-map.
                    
            case 'whole_brain'
                %% extract all voxels in whole brain
                % SPM tmap is used. At least one T-map is needed.
                
                activity    = img2mat(fullfile(spm_dir,'spmT_0001.img'));
                header      = spm_vol(fullfile(spm_dir,'spmT_0001.img'));
                % get dimension of the activity map and conversion matrix
                dim         = header.dim;
                convert_mat = header.mat;
                
                % check whether normalized brain or not
                temp = load(fullfile(spm_dir,'SPM'));
                header2 = spm_vol(deblank(temp.SPM.xY.P(1,:)));
                header.descrip = [header.descrip ' -- ' header2.descrip];                
                
                % All the voxels are selected except masked (value = 0)
                % voxels out of the brain.
                [XYZ_ROI_X,XYZ_ROI_Y,XYZ_ROI_Z] = ind2sub(dim,find(activity~=0));
                XYZ_ROI_all                     = [XYZ_ROI_X';XYZ_ROI_Y';XYZ_ROI_Z'];
                XYZmm_ROI_all                   =   convert_mat*[XYZ_ROI_all; ones(1, size(XYZ_ROI_all,2))];
                XYZmm_ROI_all                   =   XYZmm_ROI_all(1:3,:);
                
                ROI         = XYZmm_ROI_all;
                ROI_hdr     = header;

                % output is subject or normalized mm coordinats
                % Depends on the t-map.
                

                
            case 'anat_and_func'
                %% functional & anatomical ROI
                % The voxels with T values > the threshold in the defined 
                % brain areas are selected.
                % When the thoeshold is defined with the number > 100,
                % the script assumes that the threshold is defined with the
                % number of the voxels to be selected,
                % rather than t-score itself.                
                
                % brain activation, hearder, conversion matrix and inverse
                % matrix is defined.
                activity    = img2mat(fullfile(spm_dir,ROI_param.act_map));
                header      = spm_vol(fullfile(spm_dir,ROI_param.act_map));
                dim         = header.dim;
                convert_mat = header.mat;
                inverse_mat = inv(convert_mat);
                
                % check whether normalized brain or not
                temp = load(fullfile(spm_dir,'SPM'));
                header2 = spm_vol(squeeze(temp.SPM.xY.P(1,:)));
                header.descrip = [header.descrip ' -- ' header2.descrip];
                
                % set anatomical ROI (mm)
                anat_ROI             = [];
                for arean = 1:size(ROI_param.areas,1)
                    ROI_LR                  = MAP(ROI_param.areas(arean,1)).XYZmm;
                    ROI_one_region          = ROI_LR(:,(MAP(ROI_param.areas(arean,1)).LR == ROI_param.areas(arean,2)));
                    anat_ROI                = [anat_ROI ROI_one_region];
                end
                
                % if the activation map is not normalized, anatomical ROI
                % is deformed to the subject space.
                if isempty(strfind(header.descrip,'3D normalized')) % no normalized activation map
                     anat_ROI = norm2sub(fullfile(MY_VAR.analyze_dir,MY_VAR.subnames{sub},MY_VAR.anatomy_dir,'y_deformation_sn.nii') ,anat_ROI);
                end
                
                % extract anatomical ROI
                [ROI_activity,ROI_XYZmm]= extract_ROI(anat_ROI,{fullfile(spm_dir,ROI_param.act_map)});
                
                % Apply functional masking
                
                % assume it means the number of voxels
                if ROI_param.threshold >= 100 
                    temp = sort(ROI_activity(:),1,'descend');
                    if ROI_param.threshold >length(temp)
                        % error if the threshold > the number of available
                        % voxels.
                        error('TOO LARGE N-of-VOXELS')
                    end
                    threshold_height = temp(ROI_param.threshold);

                % assume it means t-value itself
                else
                    threshold_height = ROI_param.threshold;
                end
                
                % Get ROI in mm coordinates
                XYZmm_ROI_all  =  ROI_XYZmm(:,(ROI_activity>=threshold_height & ROI_activity~=0));

                ROI         = XYZmm_ROI_all;
                ROI_param.threshold_height = threshold_height;
                ROI_hdr = header;
                
                % output is subject or normalized mm coordinats
                % Depends on the t-map.
                
        end
        
        %% save anatomical ROI file
        
        % Change subject brain corrdinates
        % if ROI is defined in standard brain coordinates
        % and if decoding shold be performed with individual brain
        if (~isempty(strfind(ROI_hdr.descrip,'3D normalized')))...
                && ~(isfield(MY_VAR,'decoding_from_normalized') && (MY_VAR.decoding_from_normalized == 1))
            ROI = norm2sub(fullfile(MY_VAR.analyze_dir,MY_VAR.subnames{sub},MY_VAR.anatomy_dir,'y_deformation_sn.nii') ,ROI);
            ROI_hdr.descrip = 'deformed to unnorm';
        end
        
        % Save ROI files to spatial ROI directory.
            % save ROI(XYZ in mm coodinates), and ROI_param
            filename = add_num(to_dirn,'ROI_','.mat');
            save(filename,'ROI','ROI_param')
            fprintf('Spatial ROI file saved to \n %s. \n', filename);
        end
        
        clear ROI ROI_param
        
    end
end