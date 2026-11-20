% ========================================================================
% 文件名：s04_model.m
% 作用：把 Neukum 生产函数与月球年代函数打包成一个统一模型。
% 通俗原理：生产函数回答“不同大小的坑之间是什么比例”，年代函数回答
%        “时间越老，坑总数增加多快”。二者相乘才能得到某个年龄的
%        完整 CSFD；其中归一化 CF(1 Ga) 防止两者基准不统一。
% 输入：无。
% 输出：model 结构体，包含 NPF 系数、CF 函数句柄和有效直径范围。
% 使用：model = s04_model()，之后由 model_csfd 和 s05_fit_age 调用。
% ========================================================================
function model = s04_model() % 函数声明：返回生产函数与年代函数模型
%S04_MODEL 返回月球撞击坑统计定年的生产函数与年代函数系数
%
% model.npf_coeff : Neukum 生产函数（NPF）11 阶多项式系数，a0..a11
%               log10 N(D) = a0 + a1*x + ... + a11*x^11, x = log10(D/km)
% model.CF         : 年代函数句柄 N(1) = f(T)，T 单位 Ga，N(1) 单位 km^-2
% model.CF_1Ga : 1 Ga 参考密度，用于归一化
%
% 参考文献（写作与核对时需回到原文确认系数与适用区间）：
% Neukum, G., Ivanov, B. A., & Hartmann, W. K. (2001).
%      Cratering records in the inner solar system in relation to the lunar
%      reference system. Space Science Reviews, 96, 55-86.
% Michael, G. G., & Neukum, G. (2010). Planetary surface dating from crater
%      size-frequency distribution measurements. EPSL, 294(3-4), 223-229.

model.npf_coeff = [-3.0876, -3.557528, 0.781027, 1.021521, -0.156012, ... % NPF 多项式系数 a0–a4，x=log10(D/km)
          -0.444058, 0.019977, -0.086850, -0.005874, -0.006809, ... % 继续给出 NPF 系数 a5–a9
           8.25e-4, 5.54e-5]; % 末段系数 a10、a11，补足 12 项

model.CF = @(T) 5.44e-14 .* (exp(6.93 .* T) - 1) + 8.38e-4 .* T; % 年代函数 CF(T)：D=1 km 处累积密度随年龄增大

% 归一化基准：生产函数多项式的量级对应 1 Ga 的累积密度，
% 因此模型密度必须除以 CF(1 Ga)。
model.CF_1Ga = model.CF(1); % 取 1 Ga 处的 CF 作为归一化基准

% 生产函数有效区间（km），来自 Neukum et al. (2001)
model.D_min_valid = 0.01; % 生产函数有效直径下限 0.01 km
model.D_max_valid = 300; % 生产函数有效直径上限 300 km

end % 结束模型构造函数
