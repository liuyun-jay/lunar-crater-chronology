% ========================================================================
% 文件名：s07_selftest.m
% 作用：用已知年龄的合成数据反复检验整套定年算法。
% 通俗原理：给定 T_true，先造出合成编目，再走一遍和真实数据完全相同
%       的 CSFD 构建与年龄拟合。若平均反演年龄接近 T_true，说明
%       算法没有系统性错误；偏离部分只反映随机涨落。
% 输入：model 模型；cfg 测试年龄、面积、直径范围和重复次数。
% 输出：st 结构体数组，包含设定年龄、平均反演年龄、标准差和偏差。
% 使用：ST = s07_selftest(model, cfg.selftest)。
% ========================================================================
function st = s07_selftest(model, cfg) % 函数声明：合成数据自检，检验算法链
%S07_SELFTEST 合成数据自检：验证"构建 CSFD → 反演年龄"这条链本身是否正确
%
% 做法：给定真实年龄 T_true，按模型 CSFD 生成一份合成撞击坑编目
% （含泊松涨落），再用与真实数据完全相同的流程反演年龄。
% 如果代码正确，反演结果应当在统计误差范围内回到 T_true。
%
% 这一步把两类误差分开：
% (1) 代码/公式是否写对                     —— 由本自检回答
% (2) 真实编目是否完备、区域是否均一 —— 由后文误差分析回答
%
% 输出结构体数组 st，每个元素对应一个测试年龄：
% T_true, T_fit_mean, T_fit_std, bias, nreal

if ~isfield(cfg, 'Dlo'), cfg.Dlo = 1.0; end % 缺少直径下限时补默认 1 km
if ~isfield(cfg, 'Dhi'), cfg.Dhi = 20.0; end % 缺少直径上限时补默认 20 km
if ~isfield(cfg, 'area'), cfg.area = 7.0e4; end % 缺少统计面积时补默认 7 万 km²
if ~isfield(cfg, 'nreal'), cfg.nreal = 200; end % 缺少重复次数时补默认 200 次
if ~isfield(cfg, 'seed'), cfg.seed = 20260922; end % 缺少随机种子时补默认值

Tlist = cfg.Tlist; % 取出待检验的已知合成年龄列表

rng(cfg.seed); % 固定随机种子，保证自检可复现
st = struct('T_true', {}, 'T_fit_mean', {}, 'T_fit_std', {}, 'bias', {}, 'nreal', {}); % 预置自检结果结构体数组模板

for it = 1:numel(Tlist) % 遍历每个已知真实年龄
   T_true = Tlist(it); % 当前设定的真实年龄（Ga）
   Tfit = nan(cfg.nreal, 1); % 预分配本次年龄的重复反演结果

  for r = 1:cfg.nreal % 对同一真实年龄重复抽样多次
     D_syn = synthesize_craters(T_true, cfg.area, cfg.Dlo, cfg.Dhi, model); % 按模型 CSFD 生成合成撞击坑直径

     csfd_opt.Dmin = cfg.Dlo; % 合成数据分箱下限取抽样下限
     csfd_opt.Dmax = min(cfg.Dhi, cfg.Dlo * 10^2); % 分箱上限不超出合成抽样上限
     csfd_opt.nbins = 24; % 自检沿用 24 个对数分箱
     cs = s03_csfd(D_syn, cfg.area, csfd_opt); % 用与真实数据相同流程构建 CSFD

     fitopt.Dfit_min = cfg.Dlo; % 拟合下限与合成直径下限一致
     fitopt.Dfit_max = min(cfg.Dhi, 10); % 拟合上限取抽样上限与 10 km 的较小者
     fitopt.Tmin = 0.01; fitopt.Tmax = 4.5; fitopt.TgridN = 300; % 年龄搜索 0.01–4.5 Ga，网格 300 点

    fit = s05_fit_age(cs.D, cs.n_cum, cs.area_km2, model, fitopt); % 反演年龄，检验能否回到设定值
    Tfit(r) = fit.T; % 保存本次反演的年龄
  end % 结束重复次数循环

  st(it).T_true = T_true; % 记录设定的真实年龄
  st(it).T_fit_mean = mean(Tfit); % 记录重复反演的平均年龄
  st(it).T_fit_std = std(Tfit); % 记录反演年龄的标准差
  st(it).bias    = mean(Tfit) - T_true; % 记录平均偏差，反映系统误差
  st(it).nreal = cfg.nreal; % 记录重复次数
  fprintf(' 自检 T_true = %.2f Ga -> 反演 %.3f ± %.3f Ga (偏差 %+0.3f Ga)\n', ... % 打印真实年龄、反演均值标准差与偏差
     T_true, st(it).T_fit_mean, st(it).T_fit_std, st(it).bias); % 填入自检打印所需各项数值
end % 结束真实年龄遍历
end % 结束自检函数
