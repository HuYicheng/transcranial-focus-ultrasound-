

clc;clear;

data=load('result_abberation_correction_512.mat')
sensor_data=data.sensor_data

p_max_all = sensor_data.p_max_all;
p_max_all= gather(p_max_all);

p_target = p_max_all(300,350,320);


[pmax_val, pmax_idx] = max(p_max_all(:));
[ix0, iy0, iz0] = ind2sub(size(p_max_all), pmax_idx);


sliceViewer(p_max_all);


% ---------- 1) 绘制固定 z = zSlice 的 XY平面 ----------
zSlice = 320;                            % 例如取 z=280
plane_xy = p_max_all(:,:,zSlice);        % 提取一个二维切片 (512×512)

figure('Name', 'XY-plane at fixed z');
imagesc(plane_xy);                       % 显示该二维矩阵
axis image;                              % 等比例显示
colormap('jet');                         % 设定colormap, 可选 'gray','parula','hot'等
colorbar;                                % 添加色带参考
xlabel('Y index');                       % X轴标签 (像素索引)
ylabel('X index');                       % Y轴标签 (像素索引)
title(sprintf('XY plane at z = %d', zSlice));
axis xy;  % 使y轴向上增大

% ---------- 2) 绘制固定 y = ySlice 的 XZ平面 ----------
ySlice = 350;                            % 例如取 y=256
plane_xz = squeeze(p_max_all(:, ySlice, :));  
% plane_xz 此时为大小 [512, 512], 表示 (x,z) 数据
% 如果想让 x 方向对应图像的横轴, z 对应纵轴, 通常不需要转置；
% 如果想把 z 方向放在图像的 x 轴上，可以 plane_xz = plane_xz.'; 视需求而定

figure('Name', 'XZ-plane at fixed y');
imagesc(plane_xz.');
axis image;
colormap('jet');
colorbar;
xlabel('X index');
ylabel('Z index');
title(sprintf('XZ plane at y = %d', ySlice));
axis xy;  % 使y轴向上增大