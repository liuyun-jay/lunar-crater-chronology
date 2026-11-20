% ========================================================================
% 文件名：test_synthetic.m
% 作用：不读取真实编目，用完全合成的数据端到端测试整个程序链。
% 通俗原理：给定 3.70 Ga，生成一批假撞击坑，再走构建 CSFD、年龄拟合、
%     蒙特卡洛、敏感性分析和出图。测试图放入 figures/_test/，
%     不会覆盖正式论文图片。
% 输出：命令行测试结果和 figures/_test/ 中的测试图。
% ========================================================================
%% TEST_SYNTHETIC 合成数据端到端测试（不依赖真实编目）
% 目的：在真实数据到位之前，先验证"构建 CSFD → 反演年龄 → 误差传播 →
% 敏感性 → 出图"整条链路能否正常运行，并检查反演结果是否回到设定年龄。

% 输出图件写入 figures/_test/，不覆盖正式图件。

clear; clc; close all; % 清空环境并关闭旧图窗
here = fileparts(mfilename('fullpath')); % 取本文件所在目录
addpath(here); % 把 code 目录加入搜索路径

cfg = config(); % 读取项目配置
cfg.dirFigures = fullfile(cfg.dirFigures, '_test'); % 测试图件改放 _test 子目录
if ~exist(cfg.dirFigures, 'dir'), mkdir(cfg.dirFigures); end % 测试图目录不存在则新建
model = s04_model(); % 加载生产函数与年代模型

T_true = 3.70; % 设定合成数据真实年龄
area = 2 * pi * cfg.R_moon^2 * (1 - cos(100 / cfg.R_moon)); % 半径 100 km 的球面圆

rng(20260922); % 固定随机数种子保证复现
D = synthesize_craters(T_true, area, 1.0, 50.0, model); % 生成合成撞击坑编目
fprintf('合成编目：T_true = %.2f Ga，面积 %.0f km²，坑数 %d（预期 %.1f）\n', ... % 打印合成编目统计信息
   T_true, area, numel(D), model_csfd(1.0, T_true, model) * area); % 输出真实年龄、面积与坑数

R = struct(); % 初始化结果结构体
R.key = 'synthetic'; R.name = '合成月海区域（自检）'; % 填写测试区键名与名称
R.lat = 0; R.lon = 0; R.radius_km = 100; R.area_km2 = area; R.n = numel(D); R.D = D; % 填写位置、面积与直径
R.lat_in = zeros(size(D)); R.lon_in = zeros(size(D)); % 填充分布内坐标占位
R.ref_age = T_true; R.ref_age_src = '合成数据设定值'; % 填写参考年龄及来源

R.cs = s03_csfd(R.D, R.area_km2, cfg.csfd); % 构建 CSFD 统计
R.fit = s05_fit_age(R.cs.D, R.cs.n_cum, R.cs.area_km2, model, cfg.fit); % 拟合反演表面年龄
R.mc = s06_montecarlo(R.cs.counts, R.cs.D, R.cs.area_km2, model, cfg.fit, cfg.mc); % 蒙特卡洛误差传播

ranges = [1 5; 1 10; 1 20; 2 10; 1.5 15]; % 列出敏感性分析拟合区间
for j = 1:size(ranges, 1) % 逐个区间重新拟合
   fopt = cfg.fit; fopt.Dfit_min = ranges(j,1); fopt.Dfit_max = ranges(j,2); % 替换本次拟合的直径区间
   f = s05_fit_age(R.cs.D, R.cs.n_cum, R.cs.area_km2, model, fopt); % 用该区间做年龄拟合
   R.sens(j, :) = [ranges(j,1), ranges(j,2), f.T, f.npts]; % 记录该区间拟合结果
end % 结束敏感性循环

fprintf('单次反演结果：%.3f Ga（设定 %.2f Ga）\n', R.fit.T, T_true); % 打印单次反演年龄
fprintf('蒙特卡洛：中位 %.3f Ga，16–84%% [%.3f, %.3f] Ga\n', ... % 打印蒙特卡洛中位数与区间
   R.mc.T_med, R.mc.T_lo, R.mc.T_hi); % 输出三个分位数结果

ST = s07_selftest(model, struct('Tlist', [0.5 1 2 3 3.7], 'Dlo', 1, 'Dhi', 20, ... % 运行模型自检并生成对照
  'area', area, 'nreal', 60, 'seed', 20260922)); % 传入自检参数

R.cluster.R = NaN; R.cluster.n = NaN; % 占位的高地聚类结果
s09_plot_results(R, ST, cfg); % 绘制测试图件
fprintf('\n 端到端测试完成，测试图件位于：%s\n', cfg.dirFigures); % 打印测试完成提示
