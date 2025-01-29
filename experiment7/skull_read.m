clear; clc; close all;

vol = niftiread('..\template_median_with_skull.nii\template_median_with_skull.nii');

% 读取头信息
info = niftiinfo('..\template_median_with_skull.nii\template_median_with_skull.nii');

size(vol)

voxelSize = info.PixelDimensions

vol = vol>500;
volumeViewer(vol);

