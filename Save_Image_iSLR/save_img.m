function [output] = save_img(x,vx,savefname,tmpfile,memo)
% 
% Save img file from weight values and corresponding xyz coordinates.
% [output] = save_img(x,vx,fname,tmpfile,memo);
% 
% INPUT
%     x: value to be saved (n x 1)
%     vx : voxel position (3 x n )
%     savefname: filename to be saved 
%     tmplate: filename of image template 
%      Header information will be used
%

if length(x)~=size(vx,2)
    error('size of x and vx must agree')
end

if nargin <5
 memo = '';
end



if nargin < 4
  disp('under construction...')
  tmpfile = '/home/dcn/isao-n/matlab/tool/spm5/batch/template/save_tmp_EN_unnorm.img';
 
    hdr.dim = [64 64 30];
    hdr.mat = zeros(4,4);
    hdr.dt = [16 0];
    hdr.pinfo = [1 0 0]';
    hdr.n = [1 1];

else
    % loading template img-file 
    hdr = spm_vol(tmpfile); 
end

x = x(:);

% assign values 
img = NaN(hdr.dim);
for i = 1:size(x,1);
  img(vx(1,i),vx(2,i),vx(3,i))= x(i);
end

hdr.descrip = memo;
hdr.private.descrip = ''; 
hdr.fname = savefname;

disp(['Save: ',savefname])

if ~exist(fileparts(savefname),'dir'); mkdir(fileparts(savefname)); end

output = mat2img(hdr,img);


