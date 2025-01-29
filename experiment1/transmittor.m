clear; clc; close all;

% --------------------
% 设定球面半径 (米) 和每圈的基本参数
% --------------------
R = 0.15;         % 15 cm => 0.15 m (球面半径)
% 三圈的“纬度角”(相对 z 轴)，可自行定义
theta1 = (16+1)/150;   % 第1圈 30度
theta2 = (16+1)*2/150;   % 第2圈 60度
theta3 = (16+1)*3/150; % 第3圈 120度

% 每圈的元素数
n1 = 5;   
n2 = 11;  
n3 = 16;  

% --------------------
% 第1圈 (绕 z轴, θ=theta1)
% --------------------
phi1 = linspace(0, 2*pi, n1+1); 
phi1(end) = [];   % 去除末尾点避免重复
x1 = R * sin(theta1).*cos(phi1);
y1 = R * sin(theta1).*sin(phi1);
z1 = R * cos(theta1)*ones(size(phi1));

% --------------------
% 第2圈 (绕 z轴, θ=theta2)，之后整体旋转90°
%   如果想让法线方向变化，可考虑绕 x/y 轴旋转。
%   这里演示绕 z轴旋转，改变的是在 xy 面的相位。
% --------------------
phi2 = linspace(0, 2*pi, n2+1);
phi2(end) = [];
x2_0 = R * sin(theta2).*cos(phi2);
y2_0 = R * sin(theta2).*sin(phi2);
z2_0 = R * cos(theta2)*ones(size(phi2));

% 绕 z轴旋转90° (顺时针or逆时针由矩阵决定)
% 旋转矩阵 Rz(90°) = [0 -1  0
%                      1  0  0
%                      0  0  1]
Rz_90 = [0 -1 0; 
         1  0 0; 
         0  0 1];

xyz2_0 = [x2_0; y2_0; z2_0];
xyz2_rot = Rz_90 * xyz2_0; 
x2 = xyz2_rot(1,:);
y2 = xyz2_rot(2,:);
z2 = xyz2_rot(3,:);



% --------------------
% 第3圈 (绕 z轴, θ=theta3, 不旋转)
% --------------------
phi3 = linspace(0, 2*pi, n3+1);
phi3(end) = [];
x3 = R * sin(theta3).*cos(phi3);
y3 = R * sin(theta3).*sin(phi3);
z3 = R * cos(theta3)*ones(size(phi3));

% --------------------
% 合并所有坐标 (三圈)
% --------------------
X = [x1, x2, x3];
Y = [y1, y2, y3];
Z = [z1, z2, z3];

Element_position=[X;Y;Z];
save('Element_position.mat', 'Element_position');

% --------------------
% 3D 可视化
% --------------------
figure('Color','w'); 
hold on; axis equal; grid on;
xlabel('X'); ylabel('Y'); zlabel('Z');
title('Three Rings on a Sphere (Second Ring Rotated 90^{\circ})');

% 分别画三圈
plot3(x1, y1, z1, 'ro','MarkerSize',8,'MarkerFaceColor','r','DisplayName','Ring1');
plot3(x2, y2, z2, 'go','MarkerSize',6,'MarkerFaceColor','g','DisplayName','Ring2');
plot3(x3, y3, z3, 'bo','MarkerSize',6,'MarkerFaceColor','b','DisplayName','Ring3');

% 绘制一个半透明的球面做参考
[xx,yy,zz] = sphere(60);       % sphere(分辨率)
surf(R*xx, R*yy, R*zz, ...
    'FaceAlpha', 0.1, ...      % 半透明
    'EdgeColor','none', ...
    'FaceColor',[0.5 0.5 0.5], ...
    'DisplayName','Sphere');

legend('Location','best');
view(3);   % 3D 视角
