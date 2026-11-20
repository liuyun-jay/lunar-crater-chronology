% ========================================================================
% 文件名：s10_tables.m
% 作用：把内存中的计算结果写成 5 张 CSV 表格和 4 个区域的 CSFD 明细表。
% 通俗原理：CSV 是纯文本表格，Excel、MATLAB 和其他软件都能直接打开。
%       把年龄、敏感性、自检和半径扫描分开保存，方便论文引用与复核。
% 输入：R 研究区结果；ST 自检结果；cfg 配置。
% 输出：results/table1*.csv 至 table5*.csv 以及 csfd_*.csv。
% 使用：由 run_all.m 自动调用，也可单独运行 export_tables_only.m。
% ========================================================================
function s10_tables(R, ST, cfg) % 函数声明：导出全部结果表
%S10_TABLES 把计算结果导出为 csv，供论文表格与复核使用

w = @(T, f) writetable(T, fullfile(cfg.dirResults, f), 'Encoding', 'UTF-8'); % 定义写 CSV 的匿名函数

%% 表：研究区概况
key = string({R.key}') ; % 提取区域关键字列
name = string({R.name}') ; % 提取区域名称列
lat = [R.lat]'; lon = [R.lon]'; rad = [R.radius_km]'; % 提取中心经纬与半径
area = [R.area_km2]'; ncr = [R.n]'; % 提取面积与坑数
N1 = arrayfun(@(k) R(k).cs.N(1), 1:numel(R))'; % 提取各区域 N(>1km)
refA = [R.ref_age]'; % 提取样品参考年龄
T = table(key, name, lat, lon, rad, area, ncr, N1, refA, ... % 组装表 1 研究区数据表
   'VariableNames', {'key','name','lat_deg','lon_deg','radius_km','area_km2', ... % 指定表 1 变量名
               'n_craters','N_gt_1km','ref_age_Ga'}); % 续列名：坑数与密度等
w(T, 'table1_regions.csv'); % 导出表 1 研究区概况

%% 表：年龄结果
Tfit = arrayfun(@(k) R(k).fit.T, 1:numel(R))'; % 提取拟合年龄
Tmed = arrayfun(@(k) R(k).mc.T_med, 1:numel(R))'; % 提取蒙特卡洛中位年龄
Tlo = arrayfun(@(k) R(k).mc.T_lo, 1:numel(R))'; % 提取 16%分位年龄
Thi = arrayfun(@(k) R(k).mc.T_hi, 1:numel(R))'; % 提取 84%分位年龄
Tsd = arrayfun(@(k) R(k).mc.T_std, 1:numel(R))'; % 提取年龄标准差
nfit = arrayfun(@(k) R(k).fit.npts, 1:numel(R))'; % 提取拟合点数
chi2 = arrayfun(@(k) R(k).fit.chi2red, 1:numel(R))'; % 提取约化卡方
Rclu = arrayfun(@(k) R(k).cluster.R, 1:numel(R))'; % 提取 Clark-Evans 指数
Tvet = arrayfun(@(k) R(k).vetted.fit.T, 1:numel(R))'; % 提取校核子集拟合年龄
N1v = arrayfun(@(k) R(k).vetted.cs.N(1), 1:numel(R))'; % 提取校核子集 N(>1km)
nv = arrayfun(@(k) R(k).vetted.n, 1:numel(R))'; % 提取校核子集坑数
T = table(key, name, ncr, nfit, N1, Tfit, Tmed, Tlo, Thi, Tsd, chi2, refA, Rclu, ... % 组装表 2 年龄结果表
   nv, N1v, Tvet, ... % 续：校核子集三列
   'VariableNames', {'key','name','n_craters','n_fit_points','N_gt_1km','T_fit_Ga', ... % 指定表 2 变量名
              'T_median_Ga','T_p16_Ga','T_p84_Ga','T_1sigma_Ga','chi2_red', ... % 续列名：中位与分位年龄
              'ref_age_Ga','clark_evans_R','n_craters_vetted','N_gt_1km_vetted','T_fit_vetted_Ga'}); % 续列名：参考年龄等
w(T, 'table2_ages.csv'); % 导出表 2 年龄结果

%% 表：拟合区间敏感性
rows = {}; % 初始化敏感性行容器
for k = 1:numel(R) % 遍历各研究区

  for j = 1:size(R(k).sens, 1) % 遍历每个拟合区间
     rows(end+1, :) = {R(k).key, R(k).sens(j,1), R(k).sens(j,2), ... % 追加区间与年龄结果
                 R(k).sens(j,3), R(k).sens(j,4)}; %#ok<AGROW>；续：年龄与拟合点数
  end % 结束区间循环
end % 结束区域循环
T = cell2table(rows, 'VariableNames', {'key','Dfit_min_km','Dfit_max_km','T_Ga','n_points'}); % 把敏感性结果转成表
w(T, 'table3_fit_range_sensitivity.csv'); % 导出表 3 区间敏感性

%% 表：合成数据自检
Tt = arrayfun(@(s) s.T_true, ST)'; % 提取自检设定年龄
Tm = arrayfun(@(s) s.T_fit_mean, ST)'; % 提取平均反演年龄
Ts = arrayfun(@(s) s.T_fit_std, ST)'; % 提取反演标准差
Tb = arrayfun(@(s) s.bias, ST)'; % 提取反演偏差
T = table(Tt, Tm, Ts, Tb, 'VariableNames', ... % 组装表 4 自检结果表
  {'T_true_Ga','T_fit_mean_Ga','T_fit_std_Ga','bias_Ga'}); % 指定表 4 变量名
w(T, 'table4_selftest.csv'); % 导出表 4 自检结果

%% 表：各区域 CSFD 明细
for k = 1:numel(R) % 逐区域导出 CSFD 明细
   cs = R(k).cs; % 取出该区 CSFD 结构
   T = table(cs.edges(1:end-1), cs.edges(2:end), cs.counts, cs.n_cum, cs.N, ... % 组装直径分箱明细表
      'VariableNames', {'D_lower_km','D_upper_km','count_in_bin','cum_count','N_cum_per_km2'}); % 指定 CSFD 明细列名
   w(T, sprintf('csfd_%s.csv', R(k).key)); % 按区域 key 导出 CSFD 表
end % 结束区域循环

%% 表：区域半径敏感性
if isfield(cfg, 'radiusSens') && ~isempty(cfg.radiusSens) % 存在半径敏感性结果时导出
    T = cfg.radiusSens; % 取出半径敏感性表
    w(T, 'table5_radius_sensitivity.csv'); % 导出表 5 半径敏感性
end % 结束条件判断

fprintf(' 已导出结果表：%s\n', cfg.dirResults); % 命令行提示结果目录
end % 函数结束
