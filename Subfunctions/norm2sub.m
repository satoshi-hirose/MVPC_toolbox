% 2010/June/8 SH
function sub_XYZmm = norm2sub(sn_mat,norm_XYZmm)
 
P=sn_mat; % select y_deformation_sn.nii
P=[repmat(P,3,1) [',1,1';',1,2';',1,3']];
V=spm_vol(P);

norm_vox = V(1).mat\[norm_XYZmm; ones(1,size(norm_XYZmm,2))];
sub_XYZmm(1,:) = spm_sample_vol(V(1),norm_vox(1,:),norm_vox(2,:),norm_vox(3,:),1);
sub_XYZmm(2,:) = spm_sample_vol(V(2),norm_vox(1,:),norm_vox(2,:),norm_vox(3,:),1);
sub_XYZmm(3,:) = spm_sample_vol(V(3),norm_vox(1,:),norm_vox(2,:),norm_vox(3,:),1);
