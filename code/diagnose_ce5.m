% ========================================================================
% 文件名：diagnose_ce5.m
% 作用：专门扫描嫦娥五号着陆区的区域半径如何影响年龄结果。
% 通俗原理：年轻玄武岩单元面积有限。半径太大会混入周围老地形，半径
%     太小则坑数不足。本脚本同时比较完整编目和人工校核子集，
%     帮助判断“最合适的统计范围”。
% 输出：命令行半径扫描表。
% ========================================================================
%% DIAGNOSE_CE5 嫦娥五号着陆区的区域半径扫描
% 关心的问题：嫦娥五号所在的年轻玄武岩单元面积有限，取多大半径才能
% 既落在年轻单元内部、又保证有足够的撞击坑？取不同半径时反演年龄如何变化？

clear; clc; % 清空工作区与命令行
here = fileparts(mfilename('fullpath')); % 取本文件所在目录
addpath(here); % 加入函数搜索路径

cfg = config(); % 读取项目配置
model = s04_model(); % 载入生产函数与年代模型
cat = s01_read_catalog(cfg.rawCatalog, cfg.cacheCatalog); % 读取撞击坑编目

reg = cfg.regions(strcmp({cfg.regions.key}, 'ce5')); % 取出嫦娥五号区域配置
radii = [30 40 50 60 80 100 120]; % 待扫描的七个半径

fprintf('\n================ 嫦娥五号着陆区半径扫描 ================\n'); % 打印半径扫描标题
fprintf('（样品年龄 2.03 Ga）\n'); % 提示样品年龄 2.03 Ga
fprintf('%8s %12s %8s %12s %10s %10s %10s\n', ... % 打印表头格式
   'R(km)', 'Area(km2)', '坑数', 'N(>1km)', 'T_全部', 'T_Robbins', 'Robbins 坑数'); % 表头各列列名

for r = radii % 遍历每个半径
   cfgR = cfg; cfgR.regions = reg; cfgR.regions.radius_km = r; % 配置区域与当前半径
   Rk = s02_regions(cat, cfgR); % 筛选区域内的坑
   cs = s03_csfd(Rk.D, Rk.area_km2, cfg.csfd); % 构建累积 CSFD
   fopt = cfg.fit; fopt.Tmax = 6; % 放宽年龄上限到 6 Ga
   f = s05_fit_age(cs.D, cs.n_cum, cs.area_km2, model, fopt); % 用完整编目拟合年龄

   % Robbins 子集
   sel = cat.source == 1 | cat.source == 3; % 筛选 Robbins 来源记录
   catS.lon = cat.lon(sel); catS.lat = cat.lat(sel); catS.D = cat.D(sel); % 构造 Robbins 子集编目
   RkS = s02_regions(catS, cfgR); % 统计子集区域坑数
   if RkS.n >= 5 % 子集坑数足够时拟合
      csS = s03_csfd(RkS.D, RkS.area_km2, cfg.csfd); % 构建子集 CSFD
      fS = s05_fit_age(csS.D, csS.n_cum, csS.area_km2, model, fopt); % 拟合子集年龄
      TS = fS.T; % 保存子集年龄
   else % 坑数不足分支
      TS = NaN; % 年龄记为 NaN
   end % 结束条件判断
   fprintf('%8.0f %12.0f %8d %12.3e %10.2f %10.2f %10d\n', ... % 打印该半径一行结果
      r, Rk.area_km2, Rk.n, cs.N(1), f.T, TS, RkS.n); % 代入各统计量
end % 结束半径循环
