function[filtered] = remove_drift_voxels(raw,TR,cutoff_freq)
% removing drift components for each voxels 
% ---INPUT---
% raw: rawdata matrix(sample x voxel)
% TR (seconds) : fMRI TR
% cutoff_freq (seconds): cutoff frequency (defaults: 128) 
%
% ---OUTPUT---
% filtered: filtered data (sample x voxel)
%
% N.Hagura 10/23/2008
% modified by IN 2011/Apr/12
% modified by SH 2011/Jul/20

%% check the inputs
if nargin < 3; cutoff_freq = 128; end
if nargin < 2; TR = 2; warning('TR is assumed to be 2 second!!'); end

%% design the HPF

num_of_samples = size(raw,1); % this is "k"
cutoff = fix(2*num_of_samples*TR/cutoff_freq + 1);
designed_filter = spm_dctmtx(num_of_samples,cutoff);
designed_filter = designed_filter(:,2:end);

%% apply filter to each voxel data
filtered = NaN(size(raw));

for num_feat = 1:size(raw,2)
    filtered(:,num_feat) = raw(:,num_feat) - designed_filter*(designed_filter'*raw(:,num_feat));

% %% !!for bug check!! shold be commented out
%     plot(raw(:,num_feat)); hold on; plot(filtered(:,num_feat),'r'); hold off; pause
end

