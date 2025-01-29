clear; clc; close all;


data = load('result_kwave_512.mat');
sensor_data = data.sensor_data;



kgrid = load('time_record_kgrid.mat');
kgrid = kgrid.kgrid;


% 1. 获取采样频率和时间轴
fs = 1 / kgrid.dt;
t = kgrid.t_array;  % [1×Nt]

f0 = 500e3;   % 500 kHz
numCycles = 5;
source_mag = 1; 
source_data = source_mag*toneBurst(fs, f0, numCycles);
source_data = [source_data,zeros(1,length(t)-length(source_data))];
figure('Name','source signal');
plot(t(1:length(source_data)), source_data, 'b-'); 
xlabel('Time (s)');
ylabel('p (Pa)');
title(['Source'] );

figure('Name','Pressure signals from 32 sensors');
for n = 1:32
    subplot(8,4,n);          % 8行×4列的子图布局
    plot(t, sensor_data.p(n,:), 'b-'); 
    xlabel('Time (s)');
    ylabel('p (Pa)');
    title(['Sensor ' num2str(n)]);
end


% % 2. 设置带通滤波器参数（例如频率范围0.4MHz到0.6MHz），可根据实际信号调整
% f_low = 0.4999999e6;
% f_high = 0.5000001e6;
% 
% 
% p_data = gather(sensor_data.p);  % 如果 sensor_data.p 是 gpuArray，则转换为普通数组
% p_data = double(p_data);         % 转换为 double 类型
% 
% filtered_p = zeros(size(p_data));  % 初始化存储滤波结果
% 
% for i = 1:size(p_data,1)
%     % 对第 i 个传感器信号应用带通滤波
%     filtered_p(i,:) = bandpass(p_data(i,:), [f_low, f_high], fs);
% end
% 
% figure('Name','Filtered Pressure signals from 32 sensors');
% for n = 1:32
%     subplot(8,4,n);          % 8行×4列的子图布局
%     plot(t, filtered_p(i,:), 'b-'); 
%     xlabel('Time (s)');
%     ylabel('p (Pa)');
%     title(['Sensor ' num2str(n)]);
% end


% 替换原始数据为滤波后的数据
p_data_filtered = gather(sensor_data.p);

% 4. 选择一个参考传感器信号作为比较基准
%    这里选择第1个传感器作为参考，但你可以根据需要选择其他
ref_idx = 1;
ref_sig = p_data_filtered(ref_idx,:);
ref_sig = source_data;

% 5. 初始化存储时间延迟的数组
num_sensors = size(p_data_filtered,1);
time_delay=[];


% 6. 对每个传感器计算与参考信号的互相关以估计时间延迟
for i = 1:num_sensors
    sig_i = p_data_filtered(i,:);
    
    % 计算互相关，归一化('coeff')
    tau = gccphat(sig_i', ref_sig', fs);
    time_delay = [time_delay;tau];

end

% 7. 调整延迟使最小值为0（如果需要所有延迟均为非负值）
min_delay = min(time_delay);
time_delay = time_delay - min_delay;

% 8. 保存计算出的时间延迟
save('time_delay.mat', "time_delay");



% function [delay, xc] = gcc_phat(sig, ref_sig, fs)
%     % 计算两个信号之间的时延，使用广义互相关相位变换（GCC-PHAT）
%     % sig, ref_sig: 输入信号向量
%     % fs: 采样频率
%     % delay: 估计的时间延迟（秒）
%     % xc: 得到的互相关函数（可选输出）
%     
%     % 确保两个信号长度相同，填充到相同长度（取较长信号长度）
%     n = length(sig) + length(ref_sig) - 1;
%     
%     % 对输入信号进行FFT
%     SIG = fft(sig, n);
%     REF = fft(ref_sig, n);
%     
%     % 计算交叉功率谱，并应用 PHAT 权重
%     R = SIG .* conj(REF);
%     R = R ./ (abs(R) + eps);  % 相位变换（PHAT weighting），避免除以零
%     
%     % 计算反向FFT得到互相关函数
%     xc = ifft(R);
%     
%     % 创建滞后向量
%     lags = -(n-1):(n-1);
%     
%     % 找到最大互相关值对应的滞后
%     [~, max_idx] = max(abs(xc));
%     best_lag = lags(max_idx);
%     
%     % 将滞后转换为时间延迟
%     delay = best_lag / fs;
% end

