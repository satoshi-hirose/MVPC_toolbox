function [Y, V] = img2mat(filename)
%syntax [Y, XYZ]=img2mat('filename');
%Y holds the data for each voxel over the scan time period--4D matrix
%XYZ has the quatitative coordinate information  
V=spm_vol(filename);
Y= spm_read_vols(V,0);