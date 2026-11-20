 % ========================================================================
 % 文件名：s09_plot_results.m
 % 作用：生成论文中的主要结果图，包括 CSFD、残差、年龄对照、敏感性、
 %       蒙特卡洛年龄分布和合成数据自检图。
 % 通俗原理：同一份 R 结构体里已经有观测值、拟合年龄和随机样本，本程序
 %       只负责把这些数据画成容易阅读的图表，并统一白底黑字格式。
 % 输入：R 研究区结果；ST 合成数据自检结果；cfg 配置。
 % 输出：figures/fig2_csfd.png 至 fig7_selftest.png。
 % 使用：由 run_all.m 自动调用。
 % ========================================================================
 function s09_plot_results(R, ST, cfg) % 函数声明：生成论文全部结果图
 %S09_PLOT_RESULTS 生成论文全部结果图（图 2–图 7）
 %
 % 图 2 CSFD 观测与模型拟合（2×2）
 % 图 3 观测/模型残差比
 % 图 4 估算年龄与样品年龄对照
 % 图 5 拟合区间敏感性
 % 图 6 蒙特卡洛年龄分布（2×2）
 % 图 7 合成数据自检：已知年龄的回收检验

 model = s04_model(); % 载入生产函数与年代模型参数
 fs = 9.5; % 统一图件基础字号

 % 统一为论文用的白底黑字（本机 MATLAB 默认深色主题，否则导出图会变黑）
 set(groot, 'defaultFigureColor', 'w', ... % 设置全局默认图形属性
        'defaultFigureInvertHardcopy', 'off', ... % 导出时保持原始配色
        'defaultAxesColor', 'w', ... % 坐标区背景设为白色
        'defaultAxesXColor', 'k', 'defaultAxesYColor', 'k', 'defaultAxesZColor', 'k', ... % 坐标轴与刻度统一为黑色
      'defaultTextColor', 'k', ... % 文字颜色统一为黑色
      'defaultAxesGridColor', [0.65 0.65 0.65], ... % 网格线设为浅灰色
      'defaultAxesFontName', 'SimSun', 'defaultTextFontName', 'SimSun', ... % 全局字体统一为宋体
      'defaultLegendTextColor', 'k', 'defaultLegendColor', 'w'); % 图例文字黑色、背景白色

%% ---------- 图 2：CSFD ----------
fig = figure('Color', 'w', 'Position', [60 60 1150 900]); % 新建图 2 画布并设白底
tl = tiledlayout(fig, 2, 2, 'Padding', 'compact', 'TileSpacing', 'compact'); % 创建 2×2 分块布局
for k = 1:numel(R) % 遍历每个研究区
   ax = nexttile(tl); hold(ax, 'on'); % 取下一个子图并保持叠加
   cs = R(k).cs; fit = R(k).fit; % 取出该区 CSFD 与拟合结果

  m = cs.n_cum > 0; % 筛选累计坑数非零的直径点
  hObs = errorbar(ax, cs.D(m), cs.N(m), [], [], 'o', 'MarkerSize', 4.2, ... % 绘制观测 CSFD 及泊松误差棒
    'MarkerFaceColor', [0.15 0.35 0.75], 'MarkerEdgeColor', [0.1 0.2 0.5], ... % 设置数据点填充与边框颜色
    'Color', [0.35 0.45 0.65], 'CapSize', 2.5, 'LineWidth', 0.8); % 设置误差棒颜色与线宽

  Df = logspace(log10(cfg.csfd.Dmin), log10(cfg.csfd.Dmax), 300); % 对数空间生成模型直径网格
  Nm = model_csfd(Df, fit.T, model); % 按拟合年龄计算模型 CSFD
  hModel = plot(ax, Df, Nm, '-', 'Color', [0.85 0.25 0.10], 'LineWidth', 1.8); % 绘制橙红色模型 CSFD 曲线

  yl = [min(cs.N(m)) * 0.5, max(cs.N(m)) * 2]; % 按观测值确定纵轴显示范围
  hPatch = patch(ax, [cfg.fit.Dfit_min cfg.fit.Dfit_max cfg.fit.Dfit_max cfg.fit.Dfit_min], ... % 绘制拟合区间的浅色底框
     [yl(1) yl(1) yl(2) yl(2)], [0.85 0.9 0.98], 'EdgeColor', 'none', ... % 给出底框四角坐标与填充色
     'FaceAlpha', 0.55); % 设置底框半透明度
  uistack(findobj(ax, 'Type', 'patch'), 'bottom'); % 把底框压到图层最下方
  legend(ax, [hObs hModel hPatch], ... % 生成观测、模型与区间图例
     {'观测值（泊松 1\sigma）', '模型 CSFD', '拟合区间'}, ... % 图例三行说明文字
     'Location', 'southwest', 'FontName', 'SimSun', 'FontSize', fs - 1); % 图例放在左下角并设宋体

   set(ax, 'XScale', 'log', 'YScale', 'log', 'FontName', 'SimSun', 'FontSize', fs); % 双对数坐标与宋体字号
   xlim(ax, [cfg.csfd.Dmin cfg.csfd.Dmax]); ylim(ax, yl); % 设定横纵坐标轴范围
   grid(ax, 'on'); box(ax, 'on'); % 打开网格与坐标框
   xlabel(ax, '撞击坑直径 D (km)'); ylabel(ax, '累积密度 N(>D) (km^{-2})'); % 标注横纵轴物理量
   title(ax, sprintf('(%c) %s\n 拟合年龄 %.2f Ga（参考 %.2f Ga）', ... % 标题含子图字母、区名与年龄
       'a' + k - 1, R(k).name, fit.T, R(k).ref_age), 'FontSize', fs + 0.5); % 代入子图字母与拟合参数
end % 结束研究区循环
exportgraphics(fig, fullfile(cfg.dirFigures, 'fig2_csfd.png'), 'Resolution', 300); % 导出图 2 为 300 dpi PNG
close(fig); % 关闭图 2 窗口释放内存

%% ---------- 图 2b–2e：逐区域 CSFD 单图（论文正文用） ----------
for k = 1:numel(R) % 逐区域生成单幅 CSFD 图
   fig = figure('Color', 'w', 'Position', [80 80 780 560]); % 新建单幅图窗口
   ax = axes(fig); hold(ax, 'on'); % 创建坐标区并保持叠加
   cs = R(k).cs; fit = R(k).fit; m = cs.n_cum > 0; % 取出数据并筛去零值点
   yl = [min(cs.N(m)) * 0.5, max(cs.N(m)) * 2]; % 计算纵轴显示范围
   hPatch = patch(ax, [cfg.fit.Dfit_min cfg.fit.Dfit_max cfg.fit.Dfit_max cfg.fit.Dfit_min], ... % 先绘制拟合区间底框
       [yl(1) yl(1) yl(2) yl(2)], [0.85 0.9 0.98], 'EdgeColor', 'none', 'FaceAlpha', 0.6); % 底框坐标与半透明度
   hModel = plot(ax, Df, model_csfd(Df, fit.T, model), '-', ... % 绘制模型 CSFD 曲线
       'Color', [0.85 0.25 0.10], 'LineWidth', 1.8); % 设置曲线颜色与线宽
   hObs = errorbar(ax, cs.D(m), cs.N(m), [], [], 'o', 'MarkerSize', 5, ... % 绘制观测点及误差棒
       'MarkerFaceColor', [0.15 0.35 0.75], 'MarkerEdgeColor', [0.1 0.2 0.5], ... % 设置观测点填充颜色
       'Color', [0.35 0.45 0.65], 'CapSize', 3, 'LineWidth', 0.9); % 设置误差棒颜色与端帽
   uistack(hPatch, 'bottom'); % 把底框置于最底层
   set(ax, 'XScale', 'log', 'YScale', 'log', 'FontName', 'SimSun', 'FontSize', fs + 0.5); % 双对数坐标与字体设置
   xlim(ax, [cfg.csfd.Dmin cfg.csfd.Dmax]); ylim(ax, yl); % 设定坐标轴范围
   grid(ax, 'on'); box(ax, 'on'); % 打开网格与坐标框
   xlabel(ax, '撞击坑直径 D (km)'); ylabel(ax, '累积密度 N(>D) (km^{-2})'); % 标注横纵轴物理量
   title(ax, sprintf('%s\n 观测 CSFD 与模型拟合（T = %.2f Ga）', R(k).name, fit.T), ... % 标题为区名与拟合年龄
     'FontName', 'SimSun', 'FontSize', fs + 1.5); % 设置标题字体与字号
  legend(ax, [hObs hModel hPatch], ... % 生成观测、模型与区间图例
     {'观测值（泊松 1\sigma）', '模型 CSFD', '拟合区间'}, ... % 图例三行说明文字
     'Location', 'southwest', 'FontName', 'SimSun', 'FontSize', fs - 0.5); % 设置图例位置与字体
  exportgraphics(fig, fullfile(cfg.dirFigures, ... % 按区域关键字导出单图
     sprintf('fig_csfd_%s.png', R(k).key)), 'Resolution', 300); % 文件名含区域 key
  close(fig); % 关闭单幅图窗口
end % 结束区域循环

%% ---------- 图 3：残差比 ----------
fig = figure('Color', 'w', 'Position', [60 60 1150 900]); % 新建图 3 残差比画布
tl = tiledlayout(fig, 2, 2, 'Padding', 'compact', 'TileSpacing', 'compact'); % 创建 2×2 分块布局
for k = 1:numel(R) % 遍历各研究区
   ax = nexttile(tl); hold(ax, 'on'); % 取子图并保持叠加
   d = R(k).fit.D_used; No = R(k).fit.N_used; % 取出拟合直径与观测值
   Nm = model_csfd(d, R(k).fit.T, model); % 计算同龄模型密度
   plot(ax, d, No ./ Nm, 'o-', 'MarkerSize', 4, 'MarkerFaceColor', [0.2 0.5 0.3], ... % 绘制观测与模型比值曲线
       'Color', [0.2 0.5 0.3], 'LineWidth', 1.0); % 设置曲线颜色与线宽
   yline(ax, 1, 'k--', 'LineWidth', 1.0); % 画比值等于 1 的参考线
   set(ax, 'XScale', 'log', 'FontName', 'SimSun', 'FontSize', fs); % 横轴对数与字体设置
   grid(ax, 'on'); box(ax, 'on'); % 打开网格与坐标框
   xlabel(ax, '撞击坑直径 D (km)'); ylabel(ax, 'N_{obs} / N_{model}'); % 标注横轴与比值纵轴
   title(ax, sprintf('(%c) %s', 'a' + k - 1, R(k).name), 'FontSize', fs + 0.5); % 子图编号与区域名标题
end % 结束研究区循环
exportgraphics(fig, fullfile(cfg.dirFigures, 'fig3_residuals.png'), 'Resolution', 300); % 导出图 3 残差图
close(fig); % 关闭图 3 窗口

%% ---------- 图 4：年龄对照 ----------
fig = figure('Color', 'w', 'Position', [80 80 900 520]); % 新建图 4 年龄对照画布
ax = axes(fig); hold(ax, 'on'); % 创建坐标区并保持叠加
n = numel(R); % 统计研究区数量
x = 1:n; % 设置横轴区域序号
Tref = arrayfun(@(k) R(k).ref_age, 1:n); % 提取各区域样品参考年龄
Tfit = arrayfun(@(k) R(k).mc.T_med, 1:n); % 提取蒙特卡洛中位年龄
Tlo = arrayfun(@(k) R(k).mc.T_lo, 1:n); % 提取 16%分位年龄
Thi = arrayfun(@(k) R(k).mc.T_hi, 1:n); % 提取 84%分位年龄
Terr = [Tfit - Tlo; Thi - Tfit]; % 2 x n：第一行下误差，第二行上误差

bar(ax, x - 0.16, Tref, 0.30, 'FaceColor', [0.72 0.78 0.88], 'EdgeColor', 'none'); % 浅蓝柱表示样品参考年龄
errorbar(ax, x + 0.16, Tfit, Terr(1, :), Terr(2, :), 's', 'MarkerSize', 7, ... % 画定年结果与不对称误差棒
    'MarkerFaceColor', [0.85 0.33 0.10], 'MarkerEdgeColor', [0.6 0.2 0.05], ... % 设置方形标记填充颜色
    'Color', [0.75 0.25 0.08], 'LineWidth', 1.4, 'CapSize', 5); % 设置误差棒颜色与端帽
for k = 1:n % 逐区域标注年龄数值
    text(ax, x(k) + 0.16, Tfit(k) + Terr(2, k) + 0.10, sprintf('%.2f', Tfit(k)), ... % 在误差棒上方写年龄
       'HorizontalAlignment', 'center', 'FontName', 'SimSun', 'FontSize', fs); % 文字居中并设宋体
end % 结束数值标注循环
set(ax, 'XTick', x, 'XTickLabel', arrayfun(@(k) R(k).name, 1:n, 'UniformOutput', false), ... % 横轴刻度改用区域名称
    'FontName', 'SimSun', 'FontSize', fs); % 设置字体与字号
xtickangle(ax, 12); % 刻度标签倾斜 12 度防重叠
ylabel(ax, '年龄 (Ga)'); ylim(ax, [0 4.6]); % 纵轴标题与显示范围
grid(ax, 'on'); box(ax, 'on'); % 打开网格与坐标框
legend(ax, {'样品/文献参考年龄', '本文撞击坑定年结果（16–84%）'}, ... % 两项图例说明
    'Location', 'northoutside', 'Orientation', 'horizontal', 'FontName', 'SimSun'); % 图例置于顶部横排
title(ax, '撞击坑统计定年结果与样品年龄对照', 'FontName', 'SimSun', 'FontSize', 12); % 设置图 4 总标题
exportgraphics(fig, fullfile(cfg.dirFigures, 'fig4_age_compare.png'), 'Resolution', 300); % 导出图 4 年龄对照图
close(fig); % 关闭图 4 窗口

%% ---------- 图 5：拟合区间敏感性 ----------
fig = figure('Color', 'w', 'Position', [80 80 900 520]); % 新建图 5 敏感性画布

ax = axes(fig); hold(ax, 'on'); % 创建坐标区并保持叠加
labels = arrayfun(@(j) sprintf('%.1f–%.0f km', R(1).sens(j,1), R(1).sens(j,2)), ... % 生成拟合区间标签
    1:size(R(1).sens, 1), 'UniformOutput', false); % 遍历每个拟合区间
mk = {'o', 's', '^', 'd', 'v'}; % 各区域标记符号列表
for k = 1:n % 逐区域绘制敏感性曲线
    plot(ax, 1:size(R(k).sens, 1), R(k).sens(:, 3), ['-' mk{k}], ... % 画各区间反演年龄
       'LineWidth', 1.5, 'MarkerSize', 6, 'MarkerFaceColor', 'w'); % 设置线宽与空心标记
    plot(ax, 1:size(R(k).sens, 1), repmat(R(k).ref_age, 1, size(R(k).sens, 1)), ':', ... % 画样品年龄水平虚线
       'LineWidth', 1.0, 'Color', [0.6 0.6 0.6]); % 设置虚线灰色细线
end % 结束区域循环
set(ax, 'XTick', 1:numel(labels), 'XTickLabel', labels, ... % 横轴刻度用区间标签
    'FontName', 'SimSun', 'FontSize', fs); % 设置字体与字号
xlabel(ax, '拟合区间'); ylabel(ax, '反演年龄 (Ga)'); % 标注横轴与年龄纵轴
grid(ax, 'on'); box(ax, 'on'); % 打开网格与坐标框
legend(ax, arrayfun(@(k) R(k).name, 1:n, 'UniformOutput', false), ... % 按区域名生成图例
    'Location', 'eastoutside', 'FontName', 'SimSun', 'FontSize', fs - 0.5); % 图例放在右侧外部
title(ax, '拟合区间对反演年龄的影响（虚线为样品年龄）', 'FontName', 'SimSun', 'FontSize', 12); % 图 5 标题说明虚线含义
exportgraphics(fig, fullfile(cfg.dirFigures, 'fig5_sensitivity.png'), 'Resolution', 300); % 导出图 5 敏感性图
close(fig); % 关闭图 5 窗口

%% ---------- 图 6：蒙特卡洛年龄分布 ----------
fig = figure('Color', 'w', 'Position', [60 60 1150 860]); % 新建图 6 蒙特卡洛画布
tl = tiledlayout(fig, 2, 2, 'Padding', 'compact', 'TileSpacing', 'compact'); % 创建 2×2 分块布局
for k = 1:n % 逐区域绘制年龄分布
   ax = nexttile(tl); hold(ax, 'on'); % 取子图并保持叠加
   histogram(ax, R(k).mc.T_samples, 30, 'FaceColor', [0.35 0.55 0.80], ... % 画蒙特卡洛年龄直方图
       'EdgeColor', 'w', 'FaceAlpha', 0.9); % 设置直方图边框与透明度
   xline(ax, R(k).mc.T_med, '-', 'Color', [0.85 0.25 0.10], 'LineWidth', 2); % 标出中位年龄红色竖线
   xline(ax, R(k).ref_age, '--', 'Color', [0.15 0.6 0.25], 'LineWidth', 1.6); % 标出样品年龄绿色虚线
   xlim(ax, [cfg.fit.Tmin cfg.fit.Tmax]); % 限制年龄显示范围
   set(ax, 'FontName', 'SimSun', 'FontSize', fs); % 设置字体与字号
   grid(ax, 'on'); box(ax, 'on'); % 打开网格与坐标框
   xlabel(ax, '年龄 (Ga)'); ylabel(ax, '频数'); % 标注年龄与频数轴
   title(ax, sprintf('(%c) %s：%.2f_{%.2f}^{+%.2f} Ga', 'a' + k - 1, R(k).name, ... % 标题含中位数与上下误差
       R(k).mc.T_med, R(k).mc.T_med - R(k).mc.T_lo, R(k).mc.T_hi - R(k).mc.T_med), ... % 代入中位年龄与分位数
       'FontSize', fs + 0.5); % 设置标题字号
end % 结束区域循环
legend(nexttile(tl, 1), {'蒙特卡洛样本', '中位数', '样品年龄'}, 'FontName', 'SimSun', 'FontSize', fs - 0.5); % 在第一子图添加三项图例
exportgraphics(fig, fullfile(cfg.dirFigures, 'fig6_montecarlo.png'), 'Resolution', 300); % 导出图 6 蒙特卡洛图
close(fig); % 关闭图 6 窗口

%% ---------- 图 7：合成数据自检 ----------
fig = figure('Color', 'w', 'Position', [80 80 880 500]); % 新建图 7 自检画布
ax = axes(fig); hold(ax, 'on'); % 创建坐标区并保持叠加
Tt = arrayfun(@(s) s.T_true, ST); % 提取合成数据设定年龄
Tm = arrayfun(@(s) s.T_fit_mean, ST); % 提取多次实现平均年龄
Ts = arrayfun(@(s) s.T_fit_std, ST); % 提取反演年龄标准差
errorbar(ax, Tt, Tm, Ts, 'o', 'MarkerSize', 7, 'MarkerFaceColor', [0.2 0.5 0.3], ... % 画设定年龄与反演年龄对照
    'Color', [0.15 0.4 0.25], 'LineWidth', 1.4, 'CapSize', 5); % 设置误差棒颜色与端帽
plot(ax, [0 4.5], [0 4.5], 'k--', 'LineWidth', 1.0); % 画一比一参考线
set(ax, 'FontName', 'SimSun', 'FontSize', fs); % 设置字体与字号
xlabel(ax, '设定年龄 T_{true} (Ga)'); ylabel(ax, '反演年龄 T_{fit} (Ga)'); % 标注设定与反演年龄轴
grid(ax, 'on'); box(ax, 'on'); axis(ax, [0 4.5 0 4.5]); % 网格、边框与等范围坐标
title(ax, sprintf('合成数据自检：%d 次实现的反演偏差与离散度', ST(1).nreal), ... % 标题给出实现次数
    'FontName', 'SimSun', 'FontSize', 12); % 设置标题字体字号
exportgraphics(fig, fullfile(cfg.dirFigures, 'fig7_selftest.png'), 'Resolution', 300); % 导出图 7 自检图
close(fig); % 关闭图 7 窗口

fprintf(' 已输出图件：fig1–fig7 -> %s\n', cfg.dirFigures); % 命令行提示图件输出目录
end % 函数结束
