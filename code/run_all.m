% ========================================================================
% 文件名：run_all.m
% 作用：一键运行撞击坑统计定年全流程。
% 通俗原理：把数据读取、研究区选择、CSFD、年龄反演、蒙特卡洛、敏感性和
%     出图按顺序串起来，用户只需运行这一份主脚本。
% 输入：data/raw 下的原始编目，或 data/processed/catalog.mat 缓存。
% 输出：results/results.mat、CSV 表格和 figures/ 中的主要图件。
% 使用：在项目根目录执行 run('code/run_all.m')。
% ========================================================================
%% RUN_ALL 基于 MATLAB 的撞击坑统计定年——主流程
% 项目：基于 MATLAB 的撞击坑统计定年及其在月球月海年龄估算中的应用
%
% 流程：读取编目 → 选取研究区 → 模型自检 → 构建 CSFD → 反演年龄
%    → 蒙特卡洛误差传播 → 拟合区间敏感性 → 出图 → 保存结果
%
% 运行方式（命令行）： matlab -batch "run('code/run_all.m')"
% 运行时间：读取 130 万条编目约 1–2 分钟，其余步骤数秒至数分钟。

% ----------------------------------------------------------------
% 通俗原理：本文件是“一键总指挥”。它按顺序调用 8 类步骤：

% 1. 读取撞击坑编目；                      2. 圈出 4 个研究区；
% 3. 用合成数据检查算法； 4. 统计撞击坑大小并反演年龄；
% 5. 用随机模拟估计误差； 6. 改变拟合区间看结果是否稳定；
% 7. 检查次级坑聚集；                      8. 保存表格并出图。
% 运行完以后，results/ 中保存数值结果，figures/ 中保存图片。
% 核心判据：N(>D) 是单位面积内的累积撞击坑密度，不是撞击坑总个数；
% 随机模拟必须对每个直径区间的独立计数重采样，再重新累积。
% ----------------------------------------------------------------
clear; clc; close all; % 清空工作区、命令行与旧图窗，保证可重复运行
here = fileparts(mfilename('fullpath')); % 取本脚本所在目录，避免依赖当前路径
addpath(here); % 把 code 目录加入搜索路径以调用各步骤函数
t_start = tic; % 启动总计时器，最后报告总用时

cfg = config(); % 读取项目统一配置
model = s04_model(); % 加载生产函数与年代函数模型

fprintf('\n========== 步骤 1/8：读取全月撞击坑编目 ==========\n'); % 打印步骤标题：读取全月撞击坑编目
cat = s01_read_catalog(cfg.rawCatalog, cfg.cacheCatalog); % 读取编目（优先用缓存）并统一为 km 单位

fprintf('\n========== 步骤 2/8：选取研究区 ==========\n'); % 打印步骤标题：选取研究区
R = s02_regions(cat, cfg); % 用大圆距离与球冠面积圈出四个研究区

fprintf('\n========== 步骤 3/8：合成数据自检（验证算法链） ==========\n'); % 打印步骤标题：合成数据自检
ST = s07_selftest(model, cfg.selftest); % 用已知年龄合成数据验证算法链无系统偏差

fprintf('\n========== 步骤 4/8：逐区域构建 CSFD 并反演年龄 ==========\n'); % 打印步骤标题：逐区域构建 CSFD 并
反演年龄
nR = numel(R); % 统计研究区个数，作为循环上界
for k = 1:nR % 逐个研究区执行定年
   R(k).cs = s03_csfd(R(k).D, R(k).area_km2, cfg.csfd); % 构建该区域的对数分箱 CSFD
   R(k).fit = s05_fit_age(R(k).cs.D, R(k).cs.n_cum, R(k).cs.area_km2, model, cfg.fit); % 加权最小二乘反演该区域模式年龄
   fprintf(' 「%s」：N(>1 km) = %.3e km^-2 ，最佳拟合年龄 %.3f Ga（拟合点数 %d）\n', ... % 打印区域名、N(>1 km) 与
拟合年龄
     R(k).name, R(k).cs.N(1), R(k).fit.T, R(k).fit.npts); % 依次填入区域名、密度、年龄与拟合点数
end % 结束逐区域定年循环

fprintf('\n========== 步骤 5/8：蒙特卡洛误差传播 ==========\n'); % 打印步骤标题：蒙特卡洛误差传播
for k = 1:nR % 逐区域做蒙特卡洛重采样
   R(k).mc = s06_montecarlo(R(k).cs.counts, R(k).cs.D, R(k).cs.area_km2, ... % 传入每箱泊松计数等参数准备重采样
                 model, cfg.fit, cfg.mc); % 继续传入模型、拟合与蒙特卡洛参数
   fprintf(' 「%s」：年龄 %.3f (中位) / 16–84%% 区间 [%.3f, %.3f] Ga，1σ = %.3f Ga\n', ... % 打印中位年龄、16–84% 区
间与 1σ
     R(k).name, R(k).mc.T_med, R(k).mc.T_lo, R(k).mc.T_hi, R(k).mc.T_std); % 填入区域名与蒙特卡洛统计量
end % 结束蒙特卡洛循环

fprintf('\n========== 步骤 6/8：拟合区间敏感性分析 ==========\n'); % 打印步骤标题：拟合区间敏感性分析
fprintf('\n========== 步骤 5b：编目来源对照（人工校核子集） ==========\n'); % 打印子标题：编目来源对照实验
% LU1319373 的 Source 字段：0=机器检测，1/3=源自 Robbins (2019)。
% 用人工校核子集重做一遍，作为主要系统误差的对照实验。
selVetted = (cat.source == 1) | (cat.source == 3); % 按 Source=1/3 选出人工校核撞击坑
catV.lon = cat.lon(selVetted); catV.lat = cat.lat(selVetted); catV.D = cat.D(selVetted); % 构造只含校核坑子集的编目
Rv = s02_regions(catV, cfg); % 用同一套球面几何重新圈四个研究区
for k = 1:nR % 逐区域比较完整编目与校核子集
   Rv(k).cs = s03_csfd(Rv(k).D, Rv(k).area_km2, cfg.csfd); % 对人工校核子集构建 CSFD
   Rv(k).fit = s05_fit_age(Rv(k).cs.D, Rv(k).cs.n_cum, Rv(k).cs.area_km2, model, cfg.fit); % 对校核子集反演年龄，作为系统
误差对照
   R(k).vetted = Rv(k); % 把校核子集结果挂到主结果结构体上
   fprintf(' 「%s」：人工校核子集 %d 个坑，N(>1km)=%.3e，年龄 %.2f Ga\n', ... % 打印校核子集坑数与反演年龄
      R(k).name, Rv(k).n, Rv(k).cs.N(1), Rv(k).fit.T); % 填入区域名、坑数、N(>1km) 与年龄

end % 结束校核子集对照循环

ranges = [1 5; 1 10; 1 20; 2 10; 1.5 15]; % 拟合区间敏感性方案：五组直径上下限（km）
for k = 1:nR % 逐区域遍历敏感性方案
   for j = 1:size(ranges, 1) % 遍历五组拟合区间
      fopt = cfg.fit; % 每组从默认拟合参数出发
      fopt.Dfit_min = ranges(j, 1); % 覆盖本方案的拟合下限直径
      fopt.Dfit_max = ranges(j, 2); % 覆盖本方案的拟合上限直径
      f = s05_fit_age(R(k).cs.D, R(k).cs.n_cum, R(k).cs.area_km2, model, fopt); % 在该区间内重新反演年龄
      R(k).sens(j, :) = [ranges(j, 1), ranges(j, 2), f.T, f.npts]; % 保存区间上下限、年龄与拟合点数
   end % 结束单区域敏感性方案循环
   fprintf(' 「%s」：拟合区间 1–5 km → %.2f Ga；1–10 km → %.2f Ga；1–20 km → %.2f Ga\n', ... % 打印三组典型区间
的年龄对比
      R(k).name, R(k).sens(1,3), R(k).sens(2,3), R(k).sens(3,3)); % 填入区域名与 1–5、1–10、1–20 km 年龄
end % 结束逐区域敏感性循环

fprintf('\n========== 步骤 7/8：次级坑聚集性检验 ==========\n'); % 打印步骤标题：次级坑聚集性检验
for k = 1:nR % 逐区域检验空间分布是否聚集
   R(k).cluster = clustering_test(R(k), cfg); % 计算 Clark–Evans 最近邻指数 R
   fprintf(' 「%s」：Clark–Evans 指数 R = %.3f（<1 表示聚集）\n', ... % 打印 R 指数及判读（R 小于 1 为聚集）
      R(k).name, R(k).cluster.R); % 填入区域名与 R 指数值
end % 结束聚集性检验循环

fprintf('\n========== 步骤 6b：研究区半径敏感性 ==========\n'); % 打印子标题：研究区半径敏感性
radii = [80 100 120]; % 半径敏感性候选值（km）
rows = {}; % 预置元胞数组收集半径敏感性行
for k = 1:nR % 逐区域扫描不同统计半径
   for ir = 1:numel(radii) % 遍历三个候选半径
      cfgR = cfg; cfgR.regions = cfg.regions(k); % 复制配置并只保留当前研究区
      cfgR.regions.radius_km = radii(ir); % 把区域半径改为本候选值
      Rk = s02_regions(cat, cfgR); % 按新半径重新圈定研究区
      csR = s03_csfd(Rk.D, Rk.area_km2, cfg.csfd); % 重新构建该半径下的 CSFD
      fitR = s05_fit_age(csR.D, csR.n_cum, csR.area_km2, model, cfg.fit); % 重新反演该半径下的年龄
      rows(end+1, :) = {R(k).key, radii(ir), Rk.area_km2, Rk.n, fitR.T}; %#ok<AGROW> ；追加一行：区域键、半径、面积、
坑数、年龄
   end % 结束单区域半径循环
end % 结束逐区域半径扫描
cfg.radiusSens = cell2table(rows, 'VariableNames', ... % 把半径敏感性结果整理成表格
   {'key','radius_km','area_km2','n_craters','T_Ga'}); % 指定表格各列名称
disp(cfg.radiusSens); % 在命令行打印半径敏感性表

% 先把计算结果落盘，避免后续出图/导表出错时丢失全部计算
save(fullfile(cfg.dirResults, 'results.mat'), 'R', 'ST', 'cfg', 'model', '-v7.3'); % 先落盘计算结果，防止后续出图失败丢失

fprintf('\n========== 步骤 8/8：出图与结果保存 ==========\n'); % 打印步骤标题：出图与结果保存
s08_plot_map(cat, cfg, R); % 绘制研究区位置与撞击坑分布专题图
s09_plot_results(R, ST, cfg); % 绘制 CSFD 拟合曲线与年龄结果图
s10_tables(R, ST, cfg); % 导出论文所需的结果表格
save(fullfile(cfg.dirResults, 'results.mat'), 'R', 'ST', 'cfg', 'model', '-v7.3'); % 再次保存最新结果（含图表所需字段）

fprintf('\n 全部完成，用时 %.1f 分钟。结果：%s\n', toc(t_start)/60, cfg.dirResults); % 报告总用时与结果目录

% ------------------------------------------------------------------------
function cl = clustering_test(Rk, cfg) % 子函数：Clark–Evans 最近邻聚集性检验
%CLUSTERING_TEST 用 Clark–Evans 最近邻指数检验撞击坑是否空间聚集
% 完全随机（泊松）分布的期望平均最近邻距离为 0.5/sqrt(lambda)，
% 其中 lambda 为单位面积坑数。R < 1 表示聚集（可能含次级坑）。
% 为避免边界效应，仅统计距中心小于 0.8 倍半径的坑。
d_center = great_circle_local(Rk.lat_in, Rk.lon_in, Rk.lat, Rk.lon, cfg.R_moon); % 计算各坑到区域中心的球面距离

 inner = d_center < 0.8 * Rk.radius_km; % 只取中心 0.8R 内核区以避开边界效应
 lat = Rk.lat_in(inner); lon = Rk.lon_in(inner); % 取出内核区撞击坑的纬度与经度
 n = numel(lat); % 统计内核区撞击坑个数
 if n < 20 % 样本过少时不计算指数
    cl.R = NaN; cl.n = n; cl.d_obs = NaN; cl.d_exp = NaN; % 返回 NaN 标记样本不足
    return; % 提前返回，避免无意义计算
 end % 结束样本量判断
 % 投影到局部等距平面（小区域内近似）
 x = cfg.R_moon * deg2rad(lon - Rk.lon) * cosd(Rk.lat); % 把经度差投影为局部平面东向坐标
 y = cfg.R_moon * deg2rad(lat - Rk.lat); % 把纬度差投影为局部平面北向坐标
 % 逐点计算最近邻距离（不用 pdist/squareform，避免依赖工具箱）
 d_nn = inf(n, 1); % 初始化每个坑的最近邻距离
 for i = 1:n % 逐坑搜索最近邻
    dd = hypot(x - x(i), y - y(i)); % 计算该坑到其余所有坑的平面距离
    dd(i) = inf; % 排除自身，避免最近邻距离为零
    d_nn(i) = min(dd); % 取该坑的最近邻距离
 end % 结束逐坑最近邻循环
 lambda = n / (pi * (0.8 * Rk.radius_km)^2); % 内核区单位面积坑数（泊松强度）
 cl.d_obs = mean(d_nn); % 实测平均最近邻距离
 cl.d_exp = 0.5 / sqrt(lambda); % 完全随机分布的期望最近邻距离
 cl.R = cl.d_obs / cl.d_exp; % Clark–Evans 指数 R，小于 1 表示聚集
 cl.n = n; % 记录参与检验的坑数
 end % 结束聚集性检验子函数

 function d = great_circle_local(lat1, lon1, lat2, lon2, R) % 子函数：球面大圆距离（Haversine 公式）
 p1 = deg2rad(lat1); p2 = deg2rad(lat2); % 把两组纬度换算为弧度
 dl = deg2rad(lon2 - lon1); dp = p2 - p1; % 经度差与纬度差换算为弧度
 a = sin(dp/2).^2 + cos(p1).*cos(p2).*sin(dl/2).^2; % Haversine 公式中间量 a
 d = 2 * R .* atan2(sqrt(a), sqrt(max(1 - a, 0))); % 用 atan2 形式反解大圆距离（km）
 end % 结束大圆距离子函数
