% ========================================================================
% 文件名：diagnose_sources.m
% 作用：比较不同来源子集对年龄的影响，并检查次级坑空间聚集。
% 通俗原理：编目里的每条记录都标了来源。机器自动检测部分可能混入次级
%     坑和误检；人工校核子集通常更可靠。逐组比较年龄和 Clark–Evans
%     最近邻指数，可以判断系统误差主要来自哪一类记录。
% 输出：命令行来源子集诊断表。
% ========================================================================
%% DIAGNOSE_SOURCES 检查编目来源构成对定年结果的影响
% 背景：LU1319373 有 Source 字段：0=本编目机器检测；1/3=源自 Robbins(2019)；
%    2/4=源自 Head et al.(2010)。若机器检测部分混入大量虚假/次级坑，
%    则只用人工校核过的子集应当给出更年轻、更接近样品的年龄。
% 同时用 Clark–Evans 最近邻指数检验各子集的空间聚集性
%    （次级坑成簇 -> R 明显小于 1）。

clear; clc; % 清空工作区与命令行
here = fileparts(mfilename('fullpath')); % 取本文件所在目录
addpath(here); % 加入函数搜索路径

cfg = config(); % 读取项目配置
model = s04_model(); % 载入生产函数与年代模型
cat = s01_read_catalog(cfg.rawCatalog, cfg.cacheCatalog); % 读取撞击坑编目

RADIUS = 120; % 统一使用 120 km 半径
subsets = { '全部',        true(size(cat.D)); % 定义四个来源子集
       '机器检测(0)', cat.source == 0; % 机器自动检测记录
       'Robbins(1,3)', cat.source == 1 | cat.source == 3; % Robbins 来源记录
       'Head(2,4)',    cat.source == 2 | cat.source == 4 }; % Head 来源记录

fprintf('\n================ 来源子集诊断（半径 %d km）================\n', RADIUS); % 打印诊断标题
for k = 1:numel(cfg.regions) % 遍历各研究区
   reg = cfg.regions(k); % 取当前区域
   fprintf('\n%s（样品参考 %.2f Ga）\n', reg.name, reg.ref_age); % 打印区名与样品年龄
   fprintf(' %-16s %8s %10s %10s %10s %10s\n', ... % 打印诊断表表头
      '子集', '坑数', 'N(>1km)', 'T_fit', 'T_1-10', 'ClarkEvans'); % 表头各个列名

  for s = 1:size(subsets, 1) % 遍历来源子集
     name = subsets{s, 1}; % 取出子集名称
     sel = subsets{s, 2}; % 取出子集逻辑索引

    % 只保留该子集，构造临时编目
    catS.lon = cat.lon(sel); catS.lat = cat.lat(sel); catS.D = cat.D(sel); % 按子集构造临时编目
    cfgR = cfg; cfgR.regions = reg; cfgR.regions.radius_km = RADIUS; % 配置当前区域与半径
    Rk = s02_regions(catS, cfgR); % 统计区域内的子集坑
    if Rk.n < 5 % 坑数不足则跳过
       fprintf(' %-16s %8d %10s %10s %10s %10s\n', name, Rk.n, '-', '-', '-', '-'); % 输出缺失占位行
       continue; % 进入下一子集
    end % 结束坑数判断
    cs = s03_csfd(Rk.D, Rk.area_km2, cfg.csfd); % 构建该子集 CSFD
    fopt = cfg.fit; fopt.Tmax = 6; % 放宽年龄上限到 6 Ga
    f1 = s05_fit_age(cs.D, cs.n_cum, cs.area_km2, model, fopt); % 用默认区间拟合年龄
    fopt2 = fopt; fopt2.Dfit_min = 3; fopt2.Dfit_max = 30; % 改用 3 到 30 km 区间
    f2 = s05_fit_age(cs.D, cs.n_cum, cs.area_km2, model, fopt2); % 对照区间拟合年龄
    ce = clark_evans(Rk, cfg); % 计算 Clark-Evans 指数
    fprintf(' %-16s %8d %10.3e %10.2f %10.2f %10.3f\n', ... % 输出该子集一行结果
       name, Rk.n, cs.N(1), f1.T, f2.T, ce); % 代入各统计量
  end % 结束子集循环
end % 结束区域循环

fprintf('\n 注：N(>1km) 为区域内全部直径≥1 km 的累积密度；\n'); % 说明 N(>1km)的含义
fprintf(' T_fit 用 1-10 km 拟合，T_1-10 为对照列（3-30 km 拟合）。\n'); % 说明两列拟合区间

% ------------------------------------------------------------------------
function R = clark_evans(Rk, cfg) % 子函数：最近邻聚集指数
% 仅用距中心 0.8R 以内的坑，减少边界效应
d = great_circle(Rk.lat_in, Rk.lon_in, Rk.lat, Rk.lon, cfg.R_moon); % 计算内部坑到中心距离
inner = d < 0.8 * Rk.radius_km; % 只取 0.8R 以内的坑
lat = Rk.lat_in(inner); lon = Rk.lon_in(inner); % 取出内部坑坐标
n = numel(lat); % 统计内部坑数量
if n < 20, R = NaN; return; end % 样本不足返回 NaN
x = cfg.R_moon * deg2rad(lon - Rk.lon) * cosd(Rk.lat); % 经度差投影为平面 x
y = cfg.R_moon * deg2rad(lat - Rk.lat); % 纬度差投影为平面 y
dnn = inf(n, 1); % 最近邻距离初始化为无穷
for i = 1:n % 遍历每个坑
   dd = hypot(x - x(i), y - y(i)); % 计算到其他各坑距离
   dd(i) = inf; % 把自身距离置为无穷
   dnn(i) = min(dd); % 取最近邻距离
end % 结束坑循环

lambda = n / (pi * (0.8 * Rk.radius_km)^2); % 按内部面积估算面密度
R = mean(dnn) / (0.5 / sqrt(lambda)); % 实际与期望最近邻之比
end % 子函数结束

function d = great_circle(lat1, lon1, lat2, lon2, R) % 子函数：球面大圆距离
p1 = deg2rad(lat1); p2 = deg2rad(lat2); % 纬度转成弧度
dl = deg2rad(lon2 - lon1); dp = p2 - p1; % 经纬差转成弧度
a = sin(dp/2).^2 + cos(p1).*cos(p2).*sin(dl/2).^2; % 计算 haversine 中间量
d = 2 * R .* atan2(sqrt(a), sqrt(max(1 - a, 0))); % 反算球面距离
end % 子函数结束
