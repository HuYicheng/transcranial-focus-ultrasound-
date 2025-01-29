function delay_measure()

    %% ==== 0. 基本设置 ====
    clear; clc; close all;

    % 元素坐标 .mat 文件 (3×32)
    element_mat_file = 'Element_position.mat';

    % 网格大小 (无降采样)
    Nx = 512;  Ny = 512;  Nz = 512;
    % 体素尺寸(米): 0.5 mm
    dx = 0.5e-3;   
    dy = 0.5e-3;
    dz = 0.5e-3;

    % 声学参数 (仅示例)
    c_brain = 1540;   % m/s
    rho_brain = 1050; % kg/m^3

    %% ==== 1. 读取并处理头骨 NIfTI ====


    % 分配声速、密度
    sound_speed_map = single(c_brain) * ones(Nx, Ny, Nz, 'single');
    density_map     = single(rho_brain) * ones(Nx, Ny, Nz, 'single');

    %% ==== 2. 创建 k-Wave 网格 ====
    fprintf('Creating kgrid...\n');
    kgrid = makeGrid(Nx, dx, Ny, dy, Nz, dz);

    % 定义介质
    medium.sound_speed = sound_speed_map;
    medium.density     = density_map;

    % 这里若要考虑衰减，也可设置:
    % medium.alpha_coeff = ...;  medium.alpha_power = 1.5; (示例)

    %% ==== 3. 读取并映射阵列元素坐标 ====
    fprintf('Loading element positions from %s\n', element_mat_file);
    S = load(element_mat_file);  % 假设变量名是 elem_pos
    if ~isfield(S, 'Element_position')
        error('Element_position.mat 中需要包含变量 Element_position (3×N)');
    end
    elem_pos = S.Element_position;  % 大小 3×32
    [~, nElem] = size(elem_pos);
    fprintf('Loaded %d elements.\n', nElem);

    % 分解坐标(米)
    X = elem_pos(1,:);
    Y = elem_pos(2,:);
    Z = elem_pos(3,:);

    % 网格中心 (Nx/2, Ny/2, Nz/2) => 物理坐标(0,0,0)
    cx = Nx/2;  cy = Ny/2;  cz = Nz/2;

    % 映射 (x,y,z) -> (i,j,k)
    ix = round( X/dx + cx );
    iy = round( Y/dy + cy );
    iz = round( Z/dz + cz );

    if max(iz) > Nz
        shiftZ = max(iz) - Nz;
        iz = iz - shiftZ-50;
    elseif min(iz) < 1
        shiftZ = min(iz) - 1;
        iz = iz - shiftZ;
    end

    % 过滤越界
    valid = (ix>=1 & ix<=Nx) & (iy>=1 & iy<=Ny) & (iz>=1 & iz<=Nz);
    fprintf('Valid elements within grid = %d\n', sum(valid));
    ix = ix(valid);
    iy = iy(valid);
    iz = iz(valid);

    % ========== 构造传感器蒙板 ==========
    sensor_mask_3d = zeros(Nx, Ny, Nz, 'uint8');
    linIndex = sub2ind([Nx, Ny, Nz], ix, iy, iz);
    sensor_mask_3d(linIndex) = 1;

    sensor.mask = sensor_mask_3d;   % 关键：这个就是 sensor 的掩码
    sensor.record = {'p','u'}; 


    %% ==== 4. 定义源信号 (tone burst) ====
    source_mask_3d = zeros(Nx, Ny, Nz, 'uint8');
    source_mask_3d(300, 350, 320) = 1;
    source.p_mask = source_mask_3d;

    f0 = 500e3;   % 500 kHz
    numCycles = 5;
    source_mag = 1; 
    % 这里我们实际上需要先定义时间步 kgrid.setTime(...)
    % 所以先做下一步: time array

    %% ==== 5. 设置时间步长 & 总时长 ====
    c_max = max(medium.sound_speed(:));  % ~2800
    % 安全系数
    cfl_factor = 0.3;
    dt = cfl_factor * dx / c_max;  
    tMax = 200e-6;  % 200 microseconds(示例)
    Nt = round(tMax/dt);

    fprintf('Time step dt = %g s, Nt = %d steps\n', dt, Nt);
    kgrid.setTime(Nt, dt);

    % 现在再正式给 source.p
    source.p = source_mag*toneBurst(1/dt, f0, numCycles);


    %% ==== 7. 可视化头骨和source，receiver坐标 ====
%=== 先绘制 isosurface + plot3
figure('Color','w');
% p = patch(isosurface(bone_mask, 0.5));
% p.FaceColor = [0.8, 0.8, 0.8];
% p.EdgeColor = 'none';
daspect([1,1,1]);
view(3); camlight; lighting gouraud;
hold on;
title('Skull isosurface + Source/Receiver');

%=== Source 索引
[ix_source, iy_source, iz_source] = ind2sub(size(source_mask_3d), find(source_mask_3d==1));
plot3(iy_source, ix_source, iz_source, 'ro', 'MarkerSize',4,'MarkerFaceColor','r');

%=== Receiver 索引
[ix_recv, iy_recv, iz_recv] = ind2sub(size(sensor_mask_3d), find(sensor_mask_3d==1));
plot3(iy_recv, ix_recv, iz_recv, 'go', 'MarkerSize',4,'MarkerFaceColor','g');

% 强制设置坐标轴范围为完整网格尺寸
xlim([1, 512]); % X轴范围 = 列数
ylim([1, 512]); % Y轴范围 = 行数
zlim([1, 512]); % Z轴范围 = 切片数

%=== 给每个 receiver 点加上文字编号
nReceivers = length(ix_recv);
for nr = 1:nReceivers
    % 在 (iy_recv(nr), ix_recv(nr), iz_recv(nr)) 位置放文字 = nr
    % 如果你想打印别的信息, 替换 num2str(nr).
    text(iy_recv(nr), ix_recv(nr), iz_recv(nr), ...
         num2str(nr), ...                   % 文字内容
         'Color','g', 'FontSize',8, ...     % 文字颜色/字号
         'HorizontalAlignment','left', ...  % 对齐方式
         'VerticalAlignment','bottom');
end


    %% ==== 8. 运行 k-Wave 3D ====
    input_args = {
        'PMLSize', 20, ...
        'DataCast', 'gpuArray-single', ...        % 减小内存, 或用 'gpuArray-single'
        'PlotSim', false, ...
    };

    fprintf('Launching kspaceFirstOrder3D...\n');
    tic;
    sensor_data = kspaceFirstOrder3D(kgrid, medium, source, sensor, input_args{:});
    toc;


%     input_args = {
%     'PMLSize', 20, ...
%     'NumThreads','all', ...   % 多核CPU全用
%     'VerboseLevel', 2, ...    % 显示更多命令行信息
%     'DeleteData', false, ...    % 计算结束后删除临时 HDF5 文件
%     'DeviceNum', 0,...
%     'BinaryPath','C:\Users\Huyic\AppData\Roaming\MathWorks\MATLAB Add-Ons\Collections\k-Wave\k-Wave\binaries',...
%     'BinaryName','kspaceFirstOrder-CUDA.exe' ...
%     };
% 
% 
%     disp('Launching kspaceFirstOrder3DG (C++ version)...');
%     tic;
%     sensor_data = kspaceFirstOrder3DG(kgrid, medium, source, sensor, input_args{:});
%     toc;


    %% ==== 9. 结果保存与可视化(可选) ====
    % 保存结果
    save('result_kwave_512.mat','sensor_data','-v7.3');
    save('time_record_kgrid','kgrid');

    % 可视化 p_max切片 (若 sensor_data{1} = p_max)
    if isfield(sensor_data, 'p_max')
        pm = sensor_data.p_max;
        figure;
        imagesc(pm(:,:,round(Nz/2)));
        axis image; colormap hot; colorbar;
        title('p_{max} at middle slice (z)');
    end

    disp('Simulation done. Note: memory usage is extremely high for 512^3 grid.');

end
