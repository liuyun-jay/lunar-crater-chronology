% ========================================================================
% 文件名：s05_fit_age.m
% 作用：在候选年龄里寻找一条模型 CSFD，使它与观测 CSFD 最接近。
% 通俗原理：先粗扫一批年龄，再用局部搜索把最优点找得更准。
%       比较时使用对数坐标，因为撞击坑密度会跨越很多个数量级。
%       误差权重与累积坑数成正比，坑越多、数据越可靠的点越重要。
% 输入：D_km 累积点直径；n_cum 累积坑数；area_km2 面积；model/opt 配置。
% 输出：fit 结构体，包含最佳年龄 T、残差、实际使用的拟合点和自由度。
% 使用：fit = s05_fit_age(cs.D, cs.n_cum, cs.area_km2, model, cfg.fit)。
% ========================================================================
function fit = s05_fit_age(D_km, n_cum, area_km2, model, opt) % 函数声明：由累积计数反演模式年龄
%S05_FIT_AGE 由累积计数反演模式年龄
%
% 输入
% D_km : 累积点对应的直径（km），向量
% n_cum : 对应的累积个数
% area_km2 : 面积（km^2）
% model : s04_model 返回的结构体
% opt : 字段 Dfit_min, Dfit_max, Tmin, Tmax
% 输出结构体 fit
% T          : 最佳拟合年龄（Ga）
% Tgrid : 搜索网格
% chi2 : 网格上的加权残差平方和
% chi2red : 自由度校正后的残差
% used : 参与拟合的点是否为有效点（逻辑向量）
% D_used / N_used / n_used : 实际参与拟合的数据
%
% 权重：累积计数 N_cum 的泊松标准差为 sqrt(N_cum)，在对数域中
% sigma(log10 N) ≈ 0.4343/sqrt(N_cum)，故权重 w ∝ N_cum。

mask = (D_km >= opt.Dfit_min) & (D_km <= opt.Dfit_max) & (n_cum > 0) & isfinite(n_cum); % 筛选拟合区间内、计数为正且有限的累积点

D_u = D_km(mask); % 取出参与拟合的直径
n_u = n_cum(mask); % 取出参与拟合的累积坑数
N_u = n_u ./ area_km2; % 把累积计数换算为累积密度 N(>D)
w_u = n_u;             % 权重与累积计数成正比

Tgrid = logspace(log10(opt.Tmin), log10(opt.Tmax), opt.TgridN); % 在年龄上下限之间生成对数等距候选网格
chi2 = zeros(numel(Tgrid), 1); % 预分配每个候选年龄的加权残差平方和
for i = 1:numel(Tgrid) % 遍历候选年龄网格
   Nm = model_csfd(D_u, Tgrid(i), model); % 计算该年龄模型预测的累积密度
   chi2(i) = sum(w_u .* (log10(N_u) - log10(Nm)).^2); % 对数域加权残差平方和，权重按累积计数
end % 结束候选年龄扫描

[~, k] = min(chi2); % 定位残差最小的网格点作为初值
if k == 1 % 最优点落在网格下边界时进入分支
   T = Tgrid(1); % 直接取年龄下边界，避免外推
elseif k == numel(Tgrid) % 最优点落在网格上边界时进入分支
   T = Tgrid(end); % 直接取年龄上边界，避免外推
else % 最优点位于网格内部时做局部细化
   obj = @(t) sum(w_u .* (log10(N_u) - log10(model_csfd(D_u, t, model))).^2); % 定义年龄的一维加权残差目标函数
   T = fminbnd(obj, Tgrid(k - 1), Tgrid(k + 1), optimset('TolX', 1e-8)); % 在相邻网格区间内用有界搜索细化年龄
   chi2(k) = obj(T); % 用细化后的年龄更新该点残差
end % 结束最优点位置判断

fit.T     = T; % 输出最佳拟合年龄（Ga）
fit.Tgrid = Tgrid; % 输出年龄搜索网格，便于复核曲线
fit.chi2 = chi2; % 输出网格上的加权残差平方和
fit.chi2min = min(chi2); % 输出最小残差
fit.npts = numel(D_u); % 输出实际参与拟合的累积点数
fit.dof = max(numel(D_u) - 1, 1); % 自由度取点数减一，至少为 1
fit.chi2red = min(chi2) / fit.dof; % 计算 reduced χ²，衡量拟合优度
fit.D_used = D_u; % 输出实际使用的直径
fit.N_used = N_u; % 输出实际使用的累积密度
fit.n_used = n_u; % 输出实际使用的累积计数
fit.mask = mask; % 输出拟合点的逻辑掩码
end % 结束年龄反演函数
