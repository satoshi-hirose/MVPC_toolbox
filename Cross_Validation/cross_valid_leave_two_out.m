% Leave-two-run-out cross-validation.

% 2010/June/3 SH
% 2010/June/10 IN modified
% 2010/June/11 SH
function cross_valid_leave_two_out(MY_VAR)

% Subject loop
for sub = 1:length(MY_VAR.subnames)
    
    %% start cross validation and save results
    
    for cros_valid = 1: length(MY_VAR.sessions{sub})
        
        % extract original parameters
        MY_VAR2 = MY_VAR;
        % replace subject name to single subject
        MY_VAR2.subnames = MY_VAR.subnames(sub);
        % replace result directory to leave-to-run-out
        MY_VAR2.result_dir = fullfile(MY_VAR.result_dir,'leave_two_out',int2str(cros_valid));
        % replace temporal ROI directory to leave-to-run-out
        MY_VAR2.temporalROIdir = fullfile(MY_VAR.temporalROIdir,int2str(cros_valid));
        
        % remove one session
        MY_VAR2.sessions = MY_VAR.sessions(sub);
        MY_VAR2.sessions{1}(cros_valid) = [];
        
        % run cross validation
        cross_valid(MY_VAR2)
        
        
    end
end
