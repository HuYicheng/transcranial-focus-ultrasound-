clc;clear;

data=load('result_abberation_correction_512.mat')
sensor_data=data.sensor_data

p_max_all = sensor_data.p_max_all;
p_max_all= gather(p_max_all);

% 读取 skull 在 Z 轴方向上的范围
z_min = 1;
z_max = 430;

% 第一次滤波：只保留 skull 所在的 Z 轴区域
filtered_p1 = zeros(size(p_max_all));  % 初始化
filtered_p1(:, :, z_min:z_max) = p_max_all(:, :, z_min:z_max);


[pmax_val, pmax_idx] = max(filtered_p1(:));
[ix0, iy0, iz0] = ind2sub(size(filtered_p1), pmax_idx);


sliceViewer(filtered_p1);