clc;clear;

data=load('result_abberation_correction_512.mat')
sensor_data=data.sensor_data

p_max_all = sensor_data.p_max_all;
p_max_all= gather(p_max_all);

p_max_all = p_max_all(:,:,1:433);

[pmax_val, pmax_idx] = max(p_max_all(:));
[ix0, iy0, iz0] = ind2sub(size(p_max_all), pmax_idx);


sliceViewer(p_max_all);