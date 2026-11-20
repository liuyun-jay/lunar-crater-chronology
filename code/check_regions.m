% ========================================================================
% 文件名：check_regions.m
% 作用：在正式定年之前检查每个研究区的样本量、来源构成和半径稳定性。
% 通俗原理：定年不是“随便圈一块地”就能做。若区域内坑太少、半径稍微
%     改变结果就大幅变化，说明统计基础不牢。本脚本扫描 80、100、
%     120 km 三种半径，把这些问题一次看全。
% 输出：命令行报告和 results/check_regions.csv。
% ========================================================================
%% CHECK_REGIONS 研究区可行性检验（第三方检查环节）
% 目的：在正式定年之前，先用真实编目回答三个问题：
% 1) 每个候选区域在不同半径下各有多少撞击坑？样本量够不够定年？
% 2) 区域内撞击坑的来源构成（自产 / Robbins / Head）是否合理？
% 3) 不同半径下反演年龄是否稳定（区域是否均一）？
% 输出：命令行报告 + results/check_regions.csv

clear; clc; % 清空工作区与命令行
here = fileparts(mfilename('fullpath')); % 取本文件所在目录
addpath(here); % 把该目录加入搜索路径

cfg = config(); % 读取项目配置
model = s04_model(); % 载入生产函数与年代模型
cat = s01_read_catalog(cfg.rawCatalog, cfg.cacheCatalog); % 读取并清洗撞击坑编目

radii = [80 100 120]; % 待检验的三种区域半径
rows = {}; % 初始化结果行容器

fprintf('\n================ 区域可行性检验 ================\n'); % 打印检查标题
for k = 1:numel(cfg.regions) % 遍历每个候选区域
   reg = cfg.regions(k); % 取出当前区域参数
   fprintf('\n 区域 %d：%s（中心 %.3f°N, %.3f°E）\n', k, reg.name, reg.lat, reg.lon); % 打印区域编号与中心
   for r = radii % 遍历三种半径
      cfgR = cfg; % 复制一份配置
      cfgR.regions = reg; % 配置中只保留当前区域
      cfgR.regions.radius_km = r; % 设置当前扫描半径
      Rk = s02_regions(cat, cfgR); % 按半径筛选区域内的坑

     cs = s03_csfd(Rk.D, Rk.area_km2, cfg.csfd); % 构建累积 CSFD
     fit = s05_fit_age(cs.D, cs.n_cum, cs.area_km2, model, cfg.fit); % 拟合反演表面年龄

     % 区域内来源构成
     d = great_circle(cat.lat, cat.lon, reg.lat, reg.lon, cfg.R_moon); % 计算各坑到区域中心距离
     in = d <= r; % 标记落在半径内的坑
     srcStr = ''; % 来源统计字符串初始化
     for s = unique(cat.source(in))' % 遍历区域内各来源编号
        srcStr = [srcStr, sprintf('S%d:%d ', s, sum(cat.source(in) == s))]; %#ok<AGROW>；累加各来源坑数
     end % 结束来源循环

    fprintf(' 半径 %3d km：面积 %7.0f km²，坑数 %5d，N(>1km)=%.3e，拟合年龄 %.2f Ga（%d 点） 来源 %s\n', ... %打印面积坑数年龄与来源
      r, Rk.area_km2, Rk.n, cs.N(1), fit.T, fit.npts, srcStr); % 代入各统计量
    rows(end+1, :) = {reg.key, r, Rk.area_km2, Rk.n, cs.N(1), fit.T, fit.npts}; %#ok<AGROW>；追加一行结果记录
  end % 结束半径循环
end % 结束区域循环

T = cell2table(rows, 'VariableNames', ... % 把结果转成表格
   {'key','radius_km','area_km2','n_craters','N_gt_1km','T_Ga','n_fit_points'}); % 指定结果表列名
if ~exist(cfg.dirResults, 'dir'), mkdir(cfg.dirResults); end % 确保结果目录存在
writetable(T, fullfile(cfg.dirResults, 'check_regions.csv'), 'Encoding', 'UTF-8'); % 导出区域检查 CSV
fprintf('\n 结果已保存：%s\n', fullfile(cfg.dirResults, 'check_regions.csv')); % 提示结果保存路径

function d = great_circle(lat1, lon1, lat2, lon2, R) % 子函数：球面大圆距离
p1 = deg2rad(lat1); p2 = deg2rad(lat2); % 纬度转成弧度
dl = deg2rad(lon2 - lon1); dp = p2 - p1; % 经纬差转成弧度
a = sin(dp/2).^2 + cos(p1).*cos(p2).*sin(dl/2).^2; % 计算 haversine 中间量
d = 2 * R .* atan2(sqrt(a), sqrt(max(1 - a, 0))); % 反算球面距离
end % 子函数结束
