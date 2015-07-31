function [roidata,XYZmm]= extract_ROI(XYZmm_ROI,raw_data,matrix)
%[roidata,XYZmm] = extract_roi(XYZmm_ROI,raw_data)
% require Volumes toolbox(http://sourceforge.net/projects/spmtools/)
% all raw_data must be sampled in same slice
% input:
%       XYZmm_ROI: ROI coodinates 
%       raw_data : cell array of rawdata path
% 
% output:
%       roidata  : extracted data from ROI(2-dimentional matrix row: volume, column: voxel)
%       XYZmm    : position of extracted voxel (mm)
%
% 2010/May/12 IN
% 2010/June/2 SH
% 2010/June/8 SH
% 2011?Dec/9  SH

if nargin == 2                      % 2010/June/8 SH
% get conversion matrix of rawdata
    temp            = spm_vol(raw_data{1});
    matrix          = temp.mat; % conversion matrix (voxel -> mm)
end    

    inv_matrix      = inv(matrix); %conversion matrix (mm -> voxel)

% XYZmm_ROI -> voxel space
    XYZvox_ROI      = inv_matrix*[XYZmm_ROI; ones(1, size(XYZmm_ROI,2))];
    XYZvox_ROI      = XYZvox_ROI(1:3,:);

% choose unique voxel
    XYZvox_ROI      = round(XYZvox_ROI);
    XYZvox_ROI      = unique(XYZvox_ROI','rows')';
% convert to mm space
    XYZmm 	        = matrix*[XYZvox_ROI; ones(1, size(XYZvox_ROI,2))];
    XYZmm           = XYZmm(1:3,:);

% set batch parameters
    bch.src.srcimgs         = raw_data;
    bch.avg                 = 'none';
    bch.interp              = 0;  % nearest neighbour
    bch.roispec{1}.roilist  = XYZmm;

% run Volume Toolbox batch, variable 'ext' will be made
while 1
    try
    ext = tbxvol_extract(bch);
break    
    catch
        disp(lasterr)
    end
end

% extract ROI data
roidata = vertcat(ext(1:end).raw);