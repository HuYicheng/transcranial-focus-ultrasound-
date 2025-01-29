clear; clc; close all;

data = load('E:\桌面\bbb\experiment1\result_kwave_512.mat');
sensor_data = data.sensor_data;

kgrid = load('E:\桌面\bbb\experiment1\time_record_kgrid.mat');
kgrid = kgrid.kgrid;

% 假设你已经有 kgrid.t_array (长度 = Nt)
t = kgrid.t_array;  % 时间轴 [1×Nt]

figure('Name','Pressure signals from 32 sensors');
for n = 1:32
    subplot(8,4,n);          % 8行×4列的子图布局
    plot(t, sensor_data.p(n,:), 'b-'); 
    xlabel('Time (s)');
    ylabel('p (Pa)');
    title(['Sensor ' num2str(n)]);
end

p_data = sensor_data.p;   % [32×Nt]

ref_sig = p_data(32,:);  % 以第1个传感器为参考
time_delay = zeros(32,1);


% f_low = 0.4999999e6;
% f_high = 0.5000001e6;
% 
% fs = 1/kgrid.dt;
% 
% p_data = gather(sensor_data.p);  % 如果 sensor_data.p 是 gpuArray，则转换为普通数组
% p_data = double(p_data);         % 转换为 double 类型
% 
% filtered_p = zeros(size(p_data));  % 初始化存储滤波结果
% 
% for i = 1:size(p_data,1)
%     %对第 i 个传感器信号应用带通滤波
%     p_data(i,:) = bandpass(p_data(i,:), [f_low, f_high], fs);
% end



for i = 1:32
    sig_i = p_data(i,:);
    % MATLAB内置 xcorr, 'coeff' => 归一化互相关
    [xc, lags] = xcorr(sig_i, ref_sig, 'coeff');
    
    % 找到最大相关系数所在的索引
    [~, idx] = max(abs(xc));
    best_lag = lags(idx);   % 互相关峰位置
    
    % 转成时间
    time_delay(i) = best_lag * kgrid.dt;
end

t_max = max(time_delay);

% (3) 如果 t_min < 0，则将整组延迟平移，使最小值变为0

time_delay = t_max-time_delay;  % 这样原先最早到达的传感器变为0

save('time_delay.mat',"time_delay")

% time_delay(i) 表示传感器 i 相对 reference (#1) 的延迟(正值表示 i 比#1 晚到)