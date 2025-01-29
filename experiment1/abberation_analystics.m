clc;clear;

data=load('result_abberation_correction_512.mat')
sensor_data=data.sensor_data

p_max_all = sensor_data.p_max_all;
p_max_all= gather(p_max_all);


% 头骨 NIfTI 文件名 (替换成你自己的实际文件)
skull_nii_file = '..\template_median_with_skull.nii\template_median_with_skull.nii';

skull = niftiread(skull_nii_file);
skull = (skull>500);

% % 读取 skull 在 Z 轴方向上的范围
% [z_min, z_max] = bounds(find(any(any(skull, 1), 2)));

% % 第一次滤波：只保留 skull 所在的 Z 轴区域
% filtered_p1 = zeros(size(p_max_all));  % 初始化
% filtered_p1(:, :, z_min:z_max) = p_max_all(:, :, z_min:z_max);
% 
% % 第二次滤波：在第一次滤波的基础上，去除 skull 区域
% skull_mask = skull > 0;  % 创建二值掩码
% filtered_p2 = filtered_p1;  % 基于第一次滤波的结果
% filtered_p2(skull_mask) = 0;
% 
% [pmax_val, pmax_idx] = max(p_max_all(:));
% [ix0, iy0, iz0] = ind2sub(size(p_max_all), pmax_idx);
% 
% 
% sliceViewer(filtered_p2);