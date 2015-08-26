% Define temporal ROI and set label
% input:
%   MY_VAR
%   .analyze_dir        string('/home/dcn/hirose/analyze/tapping_decoding/analysis_folder')
%   .to_dirn            string('ROI_temporal')
%   .subnames           1 x N_sub cell array ({'US','SH','YS'})
%   .psychdir           string('psych')
%   .psych_results      1 x N_sess cell array
%                                      ({'decoding_1.mat','decoding_2.mat',.
%                                        'decoding_3.mat','decoding_4.mat',
%                                        'decoding_5.mat','decoding_6.mat',
%                                        'decoding_7.mat','decoding_8.mat',
%                                        'decoding_9.mat','decoding_10.mat'})
%   .temporal_ROIs      1 x N_timing cell array. each cell contains one
%   (single volume) or multiple(average of multiple volumes) strings.
%   .decoding_dir       string('decoding')
%
% output file:
%   ROI_01.mat, ROI_02.mat, ...
% each matfiles contain
% tempo_ROI: N_sess x 1 cell array. each cell contains (number of events) x 1(or >1 for average analysis) matrix
% label    : N_sess x 1 cell array. each cell contains (number of events) x 1 matrix
% tR_timing: number(or 1 x n matrix for average analysis)


function ROI_temporal(MY_VAR)

%% subject loop
for sub = 1:length(MY_VAR.subnames)
    %% set & make directory for temporal ROI files
    to_dirn = fullfile(MY_VAR.analyze_dir,MY_VAR.subnames{sub},MY_VAR.decoding_dir,MY_VAR.to_dirn);
    if exist(to_dirn,'dir'); error('ROI files already exist. Remove the old ROI files or rename MY_VAR.decoding_dir.'); end
    mkdir(to_dirn);
    
    %% set directory containing 'decoding_1.mat' ...
    psych_dirn  = fullfile(MY_VAR.analyze_dir,MY_VAR.subnames{sub},MY_VAR.psychdir);
    
    %% ROI definition loop
    for num_roi = 1:length(MY_VAR.temporal_ROIs)
 clear label_all tempo_ROI %2015/08/26 SH added
        %% session loop
        for sess = 1:length(MY_VAR.psych_results{sub})
            
            % load label & timing
            load(fullfile(psych_dirn,MY_VAR.psych_results{sub}{sess}))
            
            % Make tR_timing
            tR_timing = MY_VAR.temporal_ROIs{num_roi};
            
            % Set labels for decoding
            % rewrite the labels
            label2 = zeros(size(label));
            for labn = 1:length(MY_VAR.label)
                for labnn = 1:length(MY_VAR.label{labn})
                    label2(label == MY_VAR.label{labn}(labnn)) = labn;
                end
            end
            label_temp = label2;
            
            % Erase the information of the trial with no-interest
            volume_to_align (label_temp==0) =[];
            label_temp      (label_temp==0) =[];
            label_all{sess,1} = label_temp;
            
            % set temporal ROI for decoding
            tempo_ROI_temp = [];
            for ave = 1:length(MY_VAR.temporal_ROIs{num_roi})
                tempo_ROI_temp = [tempo_ROI_temp,volume_to_align + tR_timing(ave)];
            end
            tempo_ROI{sess,1} = tempo_ROI_temp;
        end
            label = label_all;
        
        % save label, tR_timing, and tempo_ROI(volume number of interest)
        filename = add_num(to_dirn,'ROI_','.mat');
        save(filename,'label','tempo_ROI','tR_timing')
        fprintf('Temporal ROI file saved to \n %s. \n', filename);
    end
end
