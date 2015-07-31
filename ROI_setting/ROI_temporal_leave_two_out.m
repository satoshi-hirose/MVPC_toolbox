% Temporal ROI determination files for leave two out cross validation are saved

function ROI_temporal_leave_two_out(MY_VAR)

for sub = 1:length(MY_VAR.subnames)
for cros_valid = 1: length(MY_VAR.psych_results{sub})
    
    MY_VAR2                             = MY_VAR; % set default
    MY_VAR2.subnames                    = MY_VAR.subnames(sub);
    MY_VAR2.to_dirn                     = fullfile(MY_VAR.to_dirn,int2str(cros_valid)); %change save dir
    MY_VAR2.psych_results               = MY_VAR.psych_results(sub);
    MY_VAR2.psych_results{1}(cros_valid)   = []; % erase test session
    ROI_temporal(MY_VAR2)
end
    end
