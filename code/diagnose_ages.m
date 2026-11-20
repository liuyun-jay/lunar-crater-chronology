% ========================================================================
% 文件名：diagnose_ages.m
% 作用：诊断为什么四个区域的年龄差异比预期小，尤其是年轻月海偏老。
% 通俗原理：把观测 CSFD 与“样品年龄下的模型 CSFD”逐直径比较，再扫描
%     不同拟合下限。这样可以判断问题来自数据污染、拟合区间还是
%     模型本身，而不是凭感觉下结论。
% 输出：命令行诊断表，主要结论见 docs/第三方检查记录.md。
% ========================================================================
%% DIAGNOSE_AGES 诊断为什么各区域反演年龄异常接近
% 背景：首轮检验中，静海、风暴洋、嫦娥五号、高地四个区域分别反演出
%    3.85–3.90、3.73–3.77、3.61–3.78、3.98–4.00 Ga，与样品年龄
%    （3.7 / 3.2 / 2.03 Ga）明显不符，且彼此接近。需要判断：
%    (1) 是小直径端的次级坑/虚假检测污染？
%    (2) 还是拟合区间选得太低？
%    (3) 还是模型归一化有误？
% 做法：比较观测 CSFD 与"样品参考年龄下的模型 CSFD"，再看拟合下限
%    从 1 km 逐步抬高到 8 km 时反演年龄如何变化。

clear; clc; % 清空工作区与命令行
here = fileparts(mfilename('fullpath')); % 取本文件所在目录
addpath(here); % 加入函数搜索路径

cfg = config(); % 读取项目配置
model = s04_model(); % 载入生产函数与年代模型
cat = s01_read_catalog(cfg.rawCatalog, cfg.cacheCatalog); % 读取撞击坑编目

RADIUS = 120;                % 用较大半径以保证统计量
Dprobe = [1 1.5 2 3 5 8 12 20]; % 用于比较的直径节点
dminList = [1 1.5 2 3 4 5 6 8]; % 拟合下限扫描

fprintf('\n============ 诊断 1：观测 CSFD 与参考年龄模型对比（半径 %d km）============\n', RADIUS); % 打印
诊断 1 标题
for k = 1:numel(cfg.regions) % 遍历各研究区
   reg = cfg.regions(k); % 取当前区域
   cfgR = cfg; cfgR.regions = reg; cfgR.regions.radius_km = RADIUS; % 配置区域与统一半径
   Rk = s02_regions(cat, cfgR); % 筛选区域内的坑
   cs = s03_csfd(Rk.D, Rk.area_km2, cfg.csfd); % 构建累积 CSFD

  Nref = model_csfd(Dprobe, reg.ref_age, model); % 样品年龄下的模型
  fprintf('\n%s（样品年龄 %.2f Ga）\n', reg.name, reg.ref_age); % 打印区名与样品年龄
  fprintf(' %8s %12s %12s %8s\n', 'D(km)', 'N_obs', 'N_model', '比值'); % 打印比较表表头
  for j = 1:numel(Dprobe) % 遍历各探测直径
     % 观测：取直径 >= Dprobe(j) 的个数除以面积
     Nobs = sum(Rk.D >= Dprobe(j)) / Rk.area_km2; % 统计观测累积密度
     fprintf(' %8.1f %12.3e %12.3e %8.2f\n', ... % 输出观测模型与比值
        Dprobe(j), Nobs, Nref(j), Nobs / Nref(j)); % 代入直径与两个密度
  end % 结束直径循环
end % 结束区域循环

fprintf('\n============ 诊断 2：拟合下限扫描（Dfit_max = 30 km）============\n'); % 打印诊断 2 标题
fprintf('%-28s', '区域'); % 打印区域列名
for dm = dminList, fprintf('%9.1f', dm); end % 打印各拟合下限
fprintf(' （参考年龄）\n'); % 表头补参考年龄列

for k = 1:numel(cfg.regions) % 再次遍历各研究区

  reg = cfg.regions(k); % 取当前区域
  cfgR = cfg; cfgR.regions = reg; cfgR.regions.radius_km = RADIUS; % 配置区域与统一半径
  Rk = s02_regions(cat, cfgR); % 筛选区域内的坑
  cs = s03_csfd(Rk.D, Rk.area_km2, cfg.csfd); % 构建累积 CSFD

  fprintf('%-28s', reg.name(1:min(26, end))); % 打印区域名称
  for dm = dminList % 遍历拟合下限
     fopt = cfg.fit; fopt.Dfit_min = dm; fopt.Dfit_max = 30; fopt.Tmax = 6; % 设置下限上限与年龄范围
     f = s05_fit_age(cs.D, cs.n_cum, cs.area_km2, model, fopt); % 按该下限拟合年龄
     fprintf('%9.2f', f.T); % 打印该下限的年龄
  end % 结束下限循环
  fprintf(' (%.2f)\n', reg.ref_age); % 行末打印参考年龄
end % 结束区域循环

fprintf('\n============ 诊断 3：统计量与饱和度检查 ============'); % 打印诊断 3 标题
for k = 1:numel(cfg.regions) % 遍历各研究区
   reg = cfg.regions(k); % 取当前区域
   cfgR = cfg; cfgR.regions = reg; cfgR.regions.radius_km = RADIUS; % 配置区域与统一半径
   Rk = s02_regions(cat, cfgR); % 筛选区域内的坑
   fprintf('\n%s：半径 %d km，面积 %.0f km²\n', reg.name, RADIUS, Rk.area_km2); % 打印半径与面积
   for Dq = [1 2 3 5 10 20] % 遍历阈值直径
      n = sum(Rk.D >= Dq); % 统计超阈值的坑数
      fprintf(' D>=%2.0f km：%5d 个（N=%.3e km^-2）\n', Dq, n, n / Rk.area_km2); % 输出坑数与累积密度
   end % 结束阈值循环
   % 直径中位数与分位数
   q = prctile(Rk.D, [10 50 90]); % 计算直径分位数
   fprintf(' 区域内直径分位（10/50/90）：%.2f / %.2f / %.2f km\n', q(1), q(2), q(3)); % 输出直径分位数
end % 结束区域循环
