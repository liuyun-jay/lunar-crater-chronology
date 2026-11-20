% ========================================================================
% 文件名：s06_montecarlo.m
% 作用：用蒙特卡洛方法估计年龄的不确定范围。
% 通俗原理：观测到的坑数带有随机涨落。程序把每个直径箱子的计数重新
%       随机生成 1000 次，每次都重新累积、重新拟合年龄；
%       这些年龄样本的中位数和 16%–84% 区间就是最终误差估计。
% 关键：必须重采样“每个箱子的独立计数”，不能直接重采样累积值。
% 输入：counts 每箱计数；D_km 累积点直径；area_km2；model/fitopt/opt。
% 输出：mc 结构体，包含年龄样本、中位数、标准差和百分位区间。
% ========================================================================
function mc = s06_montecarlo(counts, D_km, area_km2, model, fitopt, opt) % 函数声明：泊松重采样传播年龄误差
%S06_MONTECARLO 用泊松重采样传播计数误差，给出年龄的概率分布
%
% 关键点（第三方最常质疑的地方）：
% 必须对"每个直径区间的独立计数"重采样，再重新累积，最后重新拟合。
% 直接对累积计数做 poissrnd 是错的：累积值之间高度相关，
% 独立重采样会破坏这种相关性，导致年龄误差被严重低估。

 %
 % 输入
 % counts : 各直径区间的独立计数（来自 s03_csfd 的 cs.counts）
 % D_km : 累积点直径（cs.D）
 % area_km2 : 面积
 % model : s04_model
 % fitopt : 拟合区间等设置（s05_fit_age 的 opt）
 % opt : 字段 niter, seed
 % 输出
 % T_samples : niter x 1 的年龄样本（Ga）
 % T_med, T_lo, T_hi, T_std : 统计量

 rng(opt.seed); % 固定随机种子，保证误差估计可复现

 counts = counts(:); % 每箱计数转列向量
 niter = opt.niter; % 读取蒙特卡洛重采样次数
 T_samples = nan(niter, 1); % 预分配年龄样本向量

 for it = 1:niter % 逐次蒙特卡洛重采样
    c_pert = rnd_poisson(counts); % 对每箱泊松计数重采样（非累积值）
    n_cum = flipud(cumsum(flipud(c_pert))); % 从大到小重新累积得到累积计数
    fit = s05_fit_age(D_km, n_cum, area_km2, model, fitopt); % 用重采样的累积计数重新反演年龄
    T_samples(it) = fit.T; % 保存本次重采样的年龄
 end % 结束蒙特卡洛迭代

 T_samples = T_samples(isfinite(T_samples)); % 剔除拟合失败的无效年龄样本
 mc.T_samples = T_samples; % 输出全部有效年龄样本
 mc.T_mean = mean(T_samples); % 输出年龄样本均值
 mc.T_std = std(T_samples); % 输出年龄样本标准差（1σ）
 mc.T_med = median(T_samples); % 输出年龄中位数，作为推荐年龄
 mc.T_lo = prctile(T_samples, 15.87); % 输出 16% 分位作为 1σ 下界
 mc.T_hi = prctile(T_samples, 84.13); % 输出 84% 分位作为 1σ 上界
 mc.niter = numel(T_samples); % 输出有效样本数
 end % 结束蒙特卡洛误差传播函数
