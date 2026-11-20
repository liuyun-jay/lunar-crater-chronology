% ========================================================================
% 文件名：make_paper_figures.m
% 作用：从已保存的 results.mat 重新生成论文最终版全部插图。
% 通俗原理：主流程已经算完年龄；本程序读取结果文件，用统一风格生成
%     技术路线图、全月地图、CSFD、年龄对照、误差分布、敏感性、
%     自检和编目来源对照图。这样后续只调整版式时不必重算年龄。
% 输入：results/results.mat 与 data/processed/catalog.mat。
% 输出：figures/fig1_route.png 至 fig8_source_compare.png。
% 使用：make_paper_figures。
% ========================================================================
%% MAKE_PAPER_FIGURES 生成论文全部插图的最终版本
% 风格参考用户提供的朱诺案例图件：白底、细黑轴线、浅灰点状网格、
% 柔和配色、面板字母、底部横向图例、图下注记。
% 运行：matlab -batch "run('code/make_paper_figures.m')"

clc; close all; % 清屏并关闭所有图窗
here = fileparts(mfilename('fullpath')); % 取本脚本所在目录
addpath(here); % 把 code 目录加入搜索路径

cfg = config(); % 读取项目配置结构体
S = s11_figstyle(); % 载入论文插图统一风格
FIG = cfg.dirFigures; % 设置图件输出目录

L = load(fullfile(cfg.dirResults, 'results.mat'), 'R', 'ST', 'cfg'); % 载入已保存的计算结果
R = L.R; ST = L.ST; cfg = L.cfg; % 解包结果变量
model = s04_model(); % 载入年代模型参数
ca = load(cfg.cacheCatalog, 'cat'); cat = ca.cat; % 载入撞击坑编目缓存

make_route_figure(FIG, S); % 绘制图 1 技术路线图
make_map_figure(cat, cfg, R, S, FIG); % 绘制图 2 全月密度图
make_csfd_figure(R, cfg, S, FIG); % 绘制图 3 CSFD 拟合图
make_age_figure(R, S, FIG); % 绘制图 4 年龄对照图
make_mc_figure(R, cfg, S, FIG); % 绘制图 5 蒙特卡洛分布图
make_sensitivity_figure(R, S, FIG); % 绘制图 6 拟合区间敏感性图
make_selftest_figure(ST, S, FIG); % 绘制图 7 合成数据自检图
make_source_figure(R, S, FIG); % 绘制图 8 编目来源对照图
fprintf('\n 全部插图已生成到 %s\n', FIG); % 打印插图输出目录

%% ======================================================================
function make_route_figure(FIG, S) % 子函数：绘制技术路线图
fig = figure('Color', 'w', 'Position', [80 80 660 700], 'InvertHardcopy', 'off'); % 创建白色背景画布
ax = axes(fig, 'Position', [0.03 0.04 0.94 0.92]); hold(ax, 'on'); % 创建无框坐标轴并保持
axis(ax, [0 10.6 0 13.2]); axis(ax, 'off'); % 设定画布范围并隐藏坐标轴

ttl = {'① 编目读取与质量核查', '全月撞击坑编目 LU1319373（1319373 条，D ≥ 1 km）' % 技术路线第 1 步标题与说明
      '② 研究区选取',              '球面圆区域、大圆距离筛选、球面面积精确计算' % 技术路线第 2 步标题与说明
      '③ 累积尺寸-频率分布 CSFD', '对数分箱 → 反向累积 → 除以统计面积' % 技术路线第 3 步标题与说明
      '④ 模型曲线归一化', 'N_{model}(D,T) = NPF(D) × CF(T) / CF(1 Ga)' % 技术路线第 4 步标题与说明
      '⑤ 加权最小二乘年龄反演', '对数域加权、网格搜索 + fminbnd 局部细化' % 技术路线第 5 步标题与说明
      '⑥ 蒙特卡洛误差传播', '区间独立泊松重采样（1000 次）' % 技术路线第 6 步标题与说明
      '⑦ 与样品年龄对照及误差诊断', '编目来源 · 区域半径 · 拟合区间 · 次级坑聚集'}; % 技术路线第 7 步标题与说明
y0 = 11.05; h = 1.26; gap = 0.36; % 设置方框纵向布局参数
for i = 1:size(ttl, 1) % 遍历七个流程步骤
    yy = y0 - (i - 1) * (h + gap); % 计算当前方框纵坐标
    rectangle(ax, 'Position', [1.15 yy 7.7 h], 'Curvature', 0.12, ... % 绘制流程步骤方框
       'FaceColor', [0.968 0.975 0.986], 'EdgeColor', [0.36 0.47 0.62], 'LineWidth', 1.0); % 设置方框填充与描边样式
   text(ax, 5.0, yy + h * 0.68, ttl{i, 1}, 'HorizontalAlignment', 'center', ... % 写步骤标题文字
       'FontName', S.fontCNB, 'FontSize', 10.5, 'Color', 'k'); % 设置标题字体与字号
   text(ax, 5.0, yy + h * 0.24, ttl{i, 2}, 'HorizontalAlignment', 'center', ... % 写步骤说明文字
       'FontName', S.fontCN, 'FontSize', 9, 'Color', [0.15 0.15 0.15]); % 设置说明文字字体与颜色
   if i < size(ttl, 1) % 非末步才画连接箭头
       plot(ax, [5.0 5.0], [yy - gap, yy], '-', 'Color', [0.45 0.55 0.68], 'LineWidth', 1.0); % 绘制步骤间连接线
       plot(ax, 5.0, yy - gap + 0.07, 'v', 'MarkerSize', 5, ... % 绘制向下箭头标记
          'MarkerFaceColor', [0.45 0.55 0.68], 'MarkerEdgeColor', 'none'); % 设置箭头填充与描边
   end % 结束箭头判断
end % 结束流程步骤遍历
rectangle(ax, 'Position', [8.95 6.05 1.0 4.1], 'Curvature', 0.12, ... % 绘制右侧检验框
   'FaceColor', [0.988 0.968 0.925], 'EdgeColor', [0.80 0.68 0.42], 'LineWidth', 1.0); % 设置检验框配色
text(ax, 9.45, 9.75, '检验一', 'HorizontalAlignment', 'center', ... % 写检验一标题
   'FontName', S.fontCNB, 'FontSize', 9, 'Color', [0.55 0.42 0.14]); % 设置检验一标题字体
text(ax, 9.45, 9.15, {'合成数据', '回收试验'}, 'HorizontalAlignment', 'center', ... % 写检验一内容文字
   'FontName', S.fontCN, 'FontSize', 8.5, 'Color', [0.25 0.20 0.12]); % 设置检验一内容字体
text(ax, 9.45, 7.35, '检验二', 'HorizontalAlignment', 'center', ... % 写检验二标题
   'FontName', S.fontCNB, 'FontSize', 9, 'Color', [0.55 0.42 0.14]); % 设置检验二标题字体
text(ax, 9.45, 6.75, {'编目来源', '对照试验'}, 'HorizontalAlignment', 'center', ... % 写检验二内容文字
   'FontName', S.fontCN, 'FontSize', 8.5, 'Color', [0.25 0.20 0.12]); % 设置检验二内容字体
text(ax, 5.0, 0.55, '两项独立检验：先用合成数据证明算法正确，再用真实编目判断数据是否可靠', ... % 写底部总结文字
   'HorizontalAlignment', 'center', 'FontName', S.fontCN, 'FontSize', 8.5, ... % 设置总结文字对齐方式
   'Color', [0.40 0.40 0.40]); % 设置总结文字灰色
exportgraphics(fig, fullfile(FIG, 'fig1_route.png'), 'Resolution', 300); % 导出图 1 PNG 图件
close(fig); % 关闭图 1 画布
end % 结束技术路线图函数

%% ======================================================================
function make_map_figure(cat, cfg, R, S, FIG) % 子函数：绘制全月密度图
fig = figure('Color', 'w', 'Position', [50 50 700 430], 'InvertHardcopy', 'off'); % 创建图 2 画布
ax = axes(fig, 'Position', [0.055 0.175 0.795 0.755]); hold(ax, 'on'); % 创建主地图坐标轴

edgesLon = -180:2:180; edgesLat = -90:2:90; % 定义两度经纬网格边界
ix = discretize(cat.lon, edgesLon); % 撞击坑经度落入网格列号
iy = discretize(cat.lat, edgesLat); % 撞击坑纬度落入网格行号
ok = ~isnan(ix) & ~isnan(iy); % 筛除超出范围的记录
cnt = accumarray([iy(ok), ix(ok)], 1, [numel(edgesLat)-1, numel(edgesLon)-1]); % 统计每个网格的撞击坑数
phiE = deg2rad(edgesLat); % 纬度边界转弧度
dA = cfg.R_moon^2 * deg2rad(2) * abs(diff(sin(phiE))); % 计算各纬度带球面网格面积
A2 = repmat(dA(:), 1, size(cnt, 2)); % 扩展面积矩阵到全经度
k = ones(5, 5); % 定义五乘五滑动平均核
Cs = conv2(cnt, k, 'same'); % 撞击坑计数滑动求和
As = conv2(A2, k, 'same'); % 网格面积同步滑动求和
dens = Cs ./ As;         % 5x5 格（约 300 km）滑动平均，突出月海/高地对比
dens(As < 1) = NaN; % 无覆盖区密度置为缺失
v = log10(dens); % 密度取对数便于配色
vv = v(isfinite(v)); % 提取有效密度值
lo = prctile(vv, 5); hi = prctile(vv, 95); % 按数据分位数取色标，避免整图偏暗

% 浅色顺序色标：低密度（月海）冷浅、高密度（高地）暖深
c = [0.905 0.935 0.965; 0.985 0.985 0.975; 0.980 0.900 0.760; 0.930 0.715 0.500; 0.800 0.450 0.360; 0.600 0.260 0.260]; % 定义六节点顺序色标
cmap = interp1(linspace(0,1,size(c,1)), c, linspace(0,1,160)); % 插值生成一百六十级色标
imagesc(ax, edgesLon(1:end-1)+1, edgesLat(1:end-1)+1, v); % 绘制全球密度栅格图
set(ax, 'YDir', 'normal'); % 纬度轴改为正方向
colormap(ax, cmap); % 应用自定义色标
cb = colorbar(ax); % 添加颜色条
cb.Label.String = 'log_{10}[N(D \geq 1 km) / km^{-2}]'; % 设置颜色条标签文字

cb.Label.FontName = S.fontCN; cb.FontName = S.fontCN; cb.FontSize = S.fsTick; % 设置颜色条字体字号
caxis(ax, [lo hi]); % 固定色标映射范围
style_ax(ax, S, 'XGrid', 'off', 'YGrid', 'off'); % 应用统一坐标轴样式

cols = [0.30 0.45 0.62; 0.75 0.31 0.30; 0.42 0.62 0.48; 0.62 0.47 0.24]; % 四个研究区标记颜色
for k = 1:numel(R) % 遍历四个研究区
    [clat, clon] = circle_latlon(R(k).lat, R(k).lon, R(k).radius_km, cfg.R_moon); % 计算研究区球面圆边界
    plot(ax, clon, clat, '-', 'Color', cols(k, :), 'LineWidth', 1.8); % 绘制研究区边界圆
    text(ax, R(k).lon, R(k).lat, sprintf(' %d', k), 'Color', cols(k, :), ... % 标注研究区编号
       'FontName', S.fontCNB, 'FontSize', 12); % 设置编号字体字号
end % 结束研究区标注
xlabel(ax, '经度 (°E)', 'FontName', S.fontCN, 'FontSize', S.fs); % 设置经度轴标签
ylabel(ax, '纬度 (°N)', 'FontName', S.fontCN, 'FontSize', S.fs); % 设置纬度轴标签
title(ax, '全月撞击坑密度分布与研究区位置', 'FontName', S.fontCNB, ... % 设置图 2 标题文字
    'FontSize', S.fsBig, 'FontWeight', 'normal'); % 设置标题字号与字重
axis(ax, [-180 180 -90 90]); % 固定地图经纬范围
lg = legend(ax, arrayfun(@(k) sprintf('%d %s', k, R(k).name), 1:numel(R), ... % 生成研究区图例
    'UniformOutput', false), 'Location', 'southoutside', 'Orientation', 'horizontal', ... % 图例参数续行
    'FontName', S.fontCN, 'FontSize', 8, 'Box', 'off'); % 设置图例字体与无边框
set(lg, 'Position', [0.05 0.075 0.80 0.055]); % 调整图例位置
note_text(fig, S, '数据：LU1319373（Wang et al., 2021）；2°×2° 网格，经 5×5 格滑动平均；白区为无编目覆盖。'); % 写图 2 底部数据注记
exportgraphics(fig, fullfile(FIG, 'fig2_catalog_map.png'), 'Resolution', 300); % 导出图 2 PNG 图件
close(fig); % 关闭图 2 画布
end % 结束全月密度图函数

%% ======================================================================
function make_csfd_figure(R, cfg, S, FIG) % 子函数：绘制 CSFD 图
n = numel(R); % 研究区数量
fig = figure('Color', 'w', 'Position', [40 40 660 640], 'InvertHardcopy', 'off'); % 创建图 3 画布
tl = tiledlayout(fig, 2, 2, 'Padding', 'compact', 'TileSpacing', 'compact'); % 建立两行两列紧凑面板
tl.Position = [0.085 0.140 0.875 0.830]; % 底部留出台词空间给图注
for k = 1:n % 遍历四个研究区
   ax = nexttile(tl); hold(ax, 'on'); % 定位下一个子图并保持
   cs = R(k).cs; fit = R(k).fit; m = cs.n_cum > 0; % 取出 CSFD 数据与拟合结果
   yl = [min(cs.N(m)) * 0.35, max(cs.N(m)) * 2.6]; % 按累积密度设置纵轴范围
   hP = patch(ax, [cfg.fit.Dfit_min cfg.fit.Dfit_max cfg.fit.Dfit_max cfg.fit.Dfit_min], ... % 绘制拟合区间底纹
      [yl(1) yl(1) yl(2) yl(2)], [0.945 0.965 0.985], 'EdgeColor', 'none'); % 拟合区间底纹坐标与颜色
   uistack(hP, 'bottom'); % 把底纹置于图层底部
   Df = logspace(log10(cfg.csfd.Dmin), log10(cfg.csfd.Dmax), 400); % 生成模型曲线直径采样
   hM = plot(ax, Df, model_csfd(Df, fit.T, model_of()), '-', 'Color', S.palette(2, :), ... % 绘制模型 CSFD 曲线
      'LineWidth', 1.8); % 设置模型曲线线宽
   hO = errorbar(ax, cs.D(m), cs.N(m), [], [], 'o', 'MarkerSize', 4.5, ... % 绘制观测点与误差棒
      'MarkerFaceColor', S.palette(1, :), 'MarkerEdgeColor', S.palette(1, :) * 0.8, ... % 设置观测点填充与描边
      'Color', [0.55 0.55 0.55], 'CapSize', 2.5, 'LineWidth', 0.7); % 设置误差棒颜色与端帽
   style_ax(ax, S, 'XScale', 'log', 'YScale', 'log'); % 设置双对数坐标样式
   xlim(ax, [cfg.csfd.Dmin cfg.csfd.Dmax]); ylim(ax, yl); % 固定子图坐标范围
   xlabel(ax, '撞击坑直径 D (km)'); ylabel(ax, '累积密度 N(>D) (km^{-2})'); % 设置子图轴标签
   panel_title(ax, S, sprintf('(%c) %s', 'a' + k - 1, R(k).name)); % 写子图字母编号与区名
   text(ax, 0.97, 0.955, sprintf('T = %.2f Ga 参考 %.2f Ga', fit.T, R(k).ref_age), ... % 标注反演年龄与参考年龄
      'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ... % 标注位置与对齐参数
      'FontName', S.fontCN, 'FontSize', 9, 'Color', [0.18 0.18 0.18]); % 设置标注字体与颜色
   if k == 1 % 仅第一子图画图例
      legend(ax, [hO hM hP], {'观测值（泊松 1\sigma）', '模型 CSFD', '拟合区间'}, ... % 生成三项图例
         'Location', 'southwest', 'FontName', S.fontCN, 'FontSize', 8, 'Box', 'off'); % 设置图例位置与字体
   end % 结束图例判断
end % 结束研究区遍历
note_text(fig, S, '拟合区间统一取 1–10 km；纵轴为累积密度，观测值误差棒为泊松 1σ。'); % 写图 3 底部方法注记
exportgraphics(fig, fullfile(FIG, 'fig3_csfd.png'), 'Resolution', 300); % 导出图 3 PNG 图件
close(fig); % 关闭图 3 画布

end % 结束 CSFD 图函数

%% ======================================================================
function make_age_figure(R, S, FIG) % 子函数：绘制年龄对照图
n = numel(R); % 研究区数量
Tref = arrayfun(@(k) R(k).ref_age, 1:n); % 提取各区参考年龄
Tfull = arrayfun(@(k) R(k).fit.T, 1:n); % 提取完整编目反演年龄
Tvet = arrayfun(@(k) R(k).vetted.fit.T, 1:n); % 提取校核子集反演年龄
Tlo = arrayfun(@(k) R(k).mc.T_lo, 1:n); % 提取蒙特卡洛年龄下界
Thi = arrayfun(@(k) R(k).mc.T_hi, 1:n); % 提取蒙特卡洛年龄上界

fig = figure('Color', 'w', 'Position', [70 70 640 430], 'InvertHardcopy', 'off'); % 创建图 4 画布
ax = axes(fig, 'Position', [0.085 0.235 0.86 0.60]); hold(ax, 'on'); % 创建年龄对照坐标轴
hb = bar(ax, (1:n)' + [-0.24 0 0.24], [Tref(:) Tfull(:) Tvet(:)], 0.22, ... % 绘制三组并排柱状图
   'EdgeColor', 'none'); % 设置柱状图无描边
hb(1).FaceColor = [0.78 0.83 0.89]; % 参考年龄柱设为浅灰蓝
hb(2).FaceColor = S.palette(1, :); % 完整编目柱设为配色一
hb(3).FaceColor = S.palette(5, :); % 校核子集柱设为配色五
errorbar(ax, (1:n) + 0.0, Tfull, Tfull - Tlo, Thi - Tfull, 'k', ... % 给完整编目柱加误差棒
   'LineStyle', 'none', 'LineWidth', 1.0, 'CapSize', 4); % 设置误差棒线型与端帽
for k = 1:n % 遍历四个研究区
   text(ax, k, Tfull(k) + 0.12, sprintf('%.2f', Tfull(k)), 'HorizontalAlignment', 'center', ... % 标注完整编目年龄值
      'FontName', S.fontCN, 'FontSize', 8.5, 'Color', S.palette(1, :) * 0.8); % 设置年龄标注字体颜色
   text(ax, k + 0.24, Tvet(k) + 0.12, sprintf('%.2f', Tvet(k)), 'HorizontalAlignment', 'center', ... % 标注校核子集年龄值
      'FontName', S.fontCN, 'FontSize', 8.5, 'Color', S.palette(5, :) * 0.8); % 设置校核年龄标注样式
end % 结束年龄标注循环
style_ax(ax, S); % 应用统一坐标轴样式
set(ax, 'XTick', 1:n, 'XTickLabel', arrayfun(@(k) R(k).name, 1:n, 'UniformOutput', false)); % 设置区域名称刻度标签
xtickangle(ax, 10); % 刻度标签倾斜十度
ylabel(ax, '年龄 (Ga)'); ylim(ax, [0 4.9]); % 设置年龄轴与显示范围
lg = legend(ax, {'样品/文献参考年龄', '完整编目反演结果（误差棒为 16–84%）', ... % 生成三组图例
   '人工校核子集反演结果'}, 'Orientation', 'horizontal', 'FontName', S.fontCN, ... % 图例文字续行
   'FontSize', 9, 'Box', 'off'); % 设置图例字号与无边框
set(lg, 'Position', [0.10 0.055 0.80 0.075]); % 调整图例位置
panel_title(ax, S, '撞击坑定年结果与独立年龄对照'); % 设置图 4 标题文字
note_text(fig, S, '完整编目普遍偏老；改用人工校核子集后，静海与风暴洋的结果分别改善为 3.64 Ga 与 3.36 Ga。'); % 写图 4 底部结论注记
exportgraphics(fig, fullfile(FIG, 'fig4_age_compare.png'), 'Resolution', 300); % 导出图 4 PNG 图件
close(fig); % 关闭图 4 画布
end % 结束年龄对照图函数

%% ======================================================================
function make_mc_figure(R, cfg, S, FIG) % 子函数：绘制蒙特卡洛图
n = numel(R); % 研究区数量
fig = figure('Color', 'w', 'Position', [40 40 660 620], 'InvertHardcopy', 'off'); % 创建图 5 画布
tl = tiledlayout(fig, 2, 2, 'Padding', 'compact', 'TileSpacing', 'compact'); % 建立两行两列面板
tl.Position = [0.078 0.165 0.880 0.795]; % 底部留出图例与注记空间
hLeg = gobjects(1, 3); % 预分配图例句柄
for k = 1:n % 遍历四个研究区
   ax = nexttile(tl); hold(ax, 'on'); % 定位下一个子图
   h1 = histogram(ax, R(k).mc.T_samples, 28, 'FaceColor', S.palette(4, :), ... % 绘制年龄样本直方图
      'EdgeColor', 'w', 'FaceAlpha', 0.95); % 设置直方图柱样式
   h2 = xline(ax, R(k).mc.T_med, '-', 'Color', S.palette(1, :), 'LineWidth', 1.8); % 画中位数竖线
   h3 = xline(ax, R(k).ref_age, '--', 'Color', S.palette(5, :), 'LineWidth', 1.6); % 画样品年龄虚线
   style_ax(ax, S); % 应用统一坐标轴样式
   % 蒙特卡洛分布极窄（σ≈0.006–0.015 Ga），在全年龄轴上柱子不可见，
   % 故把横轴放大到中位数 ±10σ，并在样品年龄落在视野外时用文字标注。
   sig = max(R(k).mc.T_std, 1e-3); % 取年龄标准差并防零
   lo = max(0.0, R(k).mc.T_med - 10 * sig); % 横轴下限取中位数减十 σ
   hi = R(k).mc.T_med + 10 * sig; % 横轴上限取中位数加十 σ

   xlim(ax, [lo hi]); % 按十 σ 范围放大横轴
   if R(k).ref_age < lo || R(k).ref_age > hi % 判断样品年龄是否在视野外
      text(ax, 0.04, 0.10, sprintf('样品年龄 %.2f Ga（在视野外）', R(k).ref_age), ... % 标注样品年龄在视野外
         'Units', 'normalized', 'HorizontalAlignment', 'left', ... % 标注位置参数续行
         'FontName', S.fontCN, 'FontSize', 9, 'Color', S.palette(5, :) * 0.8); % 设置标注字体与颜色
   end % 结束视野外判断
   xlabel(ax, '年龄 (Ga)'); ylabel(ax, '频数'); % 设置子图轴标签
   panel_title(ax, S, sprintf('(%c) %s', 'a' + k - 1, R(k).name)); % 写子图字母与区名
   text(ax, 0.96, 0.90, sprintf('%.2f_{%.2f}^{+%.2f} Ga', R(k).mc.T_med, ... % 标注中位数与上下界
      R(k).mc.T_med - R(k).mc.T_lo, R(k).mc.T_hi - R(k).mc.T_med), ... % 分位数实参续行
      'Units', 'normalized', 'HorizontalAlignment', 'right', 'FontName', S.fontCN, ... % 分位数标注参数续行
      'FontSize', 9, 'Color', [0.25 0.25 0.25]); % 设置分位数标注样式
   if k == 1, hLeg = [h1 h2 h3]; end % 第一子图句柄用于图例
end % 结束研究区遍历
lg = legend(hLeg, {'蒙特卡洛样本', '中位数', '样品年龄'}, 'Orientation', 'horizontal', ... % 生成三项统一图例
   'FontName', S.fontCN, 'FontSize', 8.5, 'Box', 'off'); % 设置图例字体与无边框
lg.Layout.Tile = 'south'; % 把图例放到布局底部
note_text(fig, S, '每次实现均对每个直径区间独立做泊松重采样后再累积、再拟合；统计误差远小于与样品年龄的偏差。'); % 写图 5 底部方法注记
exportgraphics(fig, fullfile(FIG, 'fig5_montecarlo.png'), 'Resolution', 300); % 导出图 5 PNG 图件
close(fig); % 关闭图 5 画布
end % 结束蒙特卡洛图函数

%% ======================================================================
function make_sensitivity_figure(R, S, FIG) % 子函数：绘制敏感性图
n = numel(R); % 研究区数量
fig = figure('Color', 'w', 'Position', [70 70 680 420], 'InvertHardcopy', 'off'); % 创建图 6 画布
ax = axes(fig, 'Position', [0.085 0.20 0.64 0.70]); hold(ax, 'on'); % 创建敏感性坐标轴
mk = {'o', 's', '^', 'd'}; % 四个区域标记形状
h = gobjects(1, n); % 预分配曲线句柄数组
for k = 1:n % 遍历四个研究区
   h(k) = plot(ax, 1:size(R(k).sens, 1), R(k).sens(:, 3), ['-' mk{k}], ... % 绘制年龄随区间变化曲线
      'Color', S.palette(k, :), 'LineWidth', 1.6, 'MarkerSize', 6, ... % 设置曲线颜色与标记大小
      'MarkerFaceColor', 'w', 'MarkerEdgeColor', S.palette(k, :)); % 设置空心标记样式
   plot(ax, 1:size(R(k).sens, 1), repmat(R(k).ref_age, 1, size(R(k).sens, 1)), ':', ... % 画参考年龄细点线
      'Color', S.palette(k, :) * 0.75 + 0.25, 'LineWidth', 1.0); % 设置参考线颜色与线宽
end % 结束研究区遍历
style_ax(ax, S); % 应用统一坐标轴样式
labels = arrayfun(@(j) sprintf('%.1f–%.0f', R(1).sens(j, 1), R(1).sens(j, 2)), ... % 生成拟合区间刻度标签
   1:size(R(1).sens, 1), 'UniformOutput', false); % 标签生成参数续行
set(ax, 'XTick', 1:numel(labels), 'XTickLabel', labels); % 应用区间刻度标签
xlabel(ax, '拟合区间 (km)'); ylabel(ax, '反演年龄 (Ga)'); % 设置图 6 轴标签
ylim(ax, [1.6 4.4]); % 固定年龄显示范围
legend(ax, h, arrayfun(@(k) R(k).name, 1:n, 'UniformOutput', false), ... % 生成四区图例
   'Location', 'eastoutside', 'FontName', S.fontCN, 'FontSize', 9, 'Box', 'off'); % 图例放到轴外右侧
panel_title(ax, S, '拟合区间对反演年龄的影响'); % 设置图 6 标题文字
note_text(fig, S, '细点线为各区域样品年龄；拟合区间从 1–5 km 放宽到 1–20 km，年龄变化不超过 0.03 Ga。'); % 写图 6底部敏感性注记
exportgraphics(fig, fullfile(FIG, 'fig6_sensitivity.png'), 'Resolution', 300); % 导出图 6 PNG 图件
close(fig); % 关闭图 6 画布
end % 结束敏感性图函数

%% ======================================================================
function make_selftest_figure(ST, S, FIG) % 子函数：绘制回收试验图
fig = figure('Color', 'w', 'Position', [70 70 620 420], 'InvertHardcopy', 'off'); % 创建图 7 画布
ax = axes(fig, 'Position', [0.10 0.18 0.86 0.70]); hold(ax, 'on'); % 创建回收试验坐标轴
Tt = arrayfun(@(s) s.T_true, ST); % 提取设定年龄
Tm = arrayfun(@(s) s.T_fit_mean, ST); % 提取回收年龄均值
Ts = arrayfun(@(s) s.T_fit_std, ST); % 提取回收年龄标准差
plot(ax, [0 4.5], [0 4.5], '--', 'Color', [0.55 0.55 0.55], 'LineWidth', 1.1); % 绘制一比一参考虚线

errorbar(ax, Tt, Tm, Ts, 'o', 'MarkerSize', 7, 'MarkerFaceColor', S.palette(5, :), ... % 绘制回收点与误差棒
   'MarkerEdgeColor', S.palette(5, :) * 0.75, 'Color', S.palette(5, :) * 0.8, ... % 设置回收点描边颜色
   'LineWidth', 1.4, 'CapSize', 5); % 设置误差棒线宽与端帽
for i = 1:numel(Tt) % 遍历各设定年龄
   text(ax, Tt(i) + 0.10, Tm(i), sprintf('%+.3f', Tm(i) - Tt(i)), ... % 标注反演偏差数值
      'FontName', S.fontCN, 'FontSize', 8.5, 'Color', [0.20 0.20 0.20]); % 设置偏差标注样式
end % 结束偏差标注循环
style_ax(ax, S); % 应用统一坐标轴样式
axis(ax, [0 4.5 0 4.5]); % 固定横纵轴范围
xlabel(ax, '设定年龄 T_{true} (Ga)'); ylabel(ax, '反演年龄 T_{fit} (Ga)'); % 设置图 7 轴标签
panel_title(ax, S, '合成数据回收试验：每个年龄 200 次实现'); % 设置图 7 标题文字
note_text(fig, S, '虚线为 1:1 参考线；标注为反演偏差。3.7 Ga 处偏差仅 0.001 Ga，说明算法链本身无系统性错误。'); %写图 7 底部自检注记
exportgraphics(fig, fullfile(FIG, 'fig7_selftest.png'), 'Resolution', 300); % 导出图 7 PNG 图件
close(fig); % 关闭图 7 画布
end % 结束回收试验图函数

%% ======================================================================
function make_source_figure(R, S, FIG) % 子函数：绘制来源对照图
n = numel(R); % 研究区数量
Nall = arrayfun(@(k) R(k).cs.N(1), 1:n); % 提取完整编目累积密度
Nvet = arrayfun(@(k) R(k).vetted.cs.N(1), 1:n); % 提取校核子集累积密度

fig = figure('Color', 'w', 'Position', [60 60 700 400], 'InvertHardcopy', 'off'); % 创建图 8 画布
ax1 = axes(fig, 'Position', [0.075 0.20 0.34 0.66]); hold(ax1, 'on'); % 创建左侧密度子图
hb = barh(ax1, [(1:n)' - 0.16, (1:n)' + 0.16], [Nall(:) Nvet(:)], 0.30, ... % 绘制两组水平柱状图
   'EdgeColor', 'none'); % 设置柱状图无描边
hb(1).FaceColor = S.palette(1, :); % 完整编目柱设为配色一
hb(2).FaceColor = S.palette(5, :); % 校核子集柱设为配色五
set(ax1, 'YTick', 1:n, 'YTickLabel', arrayfun(@(k) R(k).name, 1:n, 'UniformOutput', false), ... % 设置区域名称刻度标签
   'YDir', 'reverse'); % 纵向刻度反向排列
style_ax(ax1, S, 'XGrid', 'on', 'YGrid', 'off'); % 应用左图坐标轴样式
xlabel(ax1, 'N(>1 km) (km^{-2})'); % 设置左图横轴标签
panel_title(ax1, S, '(a) 撞击坑密度'); % 设置左子图标题
legend(ax1, {'完整编目', '人工校核子集'}, 'FontName', S.fontCN, 'FontSize', 8.5, ... % 生成左图两项图例
   'Box', 'off', 'Location', 'southeast'); % 设置左图图例位置

ax2 = axes(fig, 'Position', [0.575 0.20 0.34 0.66]); hold(ax2, 'on'); % 创建右侧偏差子图
dF = arrayfun(@(k) R(k).fit.T - R(k).ref_age, 1:n); % 完整编目年龄偏差
dV = arrayfun(@(k) R(k).vetted.fit.T - R(k).ref_age, 1:n); % 校核子集年龄偏差
hb2 = barh(ax2, [(1:n)' - 0.16, (1:n)' + 0.16], [dF(:) dV(:)], 0.30, 'EdgeColor', 'none'); % 绘制偏差水平柱状图
hb2(1).FaceColor = S.palette(1, :); % 完整编目偏差柱配色
hb2(2).FaceColor = S.palette(5, :); % 校核子集偏差柱配色
plot(ax2, [0 0], [0.4 n + 0.6], '-', 'Color', [0.3 0.3 0.3], 'LineWidth', 1.0); % 画零偏差参考竖线
set(ax2, 'YTick', 1:n, 'YTickLabel', {}, 'YDir', 'reverse'); % 设置右图刻度并隐藏标签
style_ax(ax2, S, 'XGrid', 'on', 'YGrid', 'off'); % 应用右图坐标轴样式
xlabel(ax2, '反演年龄 − 样品年龄 (Ga)'); % 设置右图横轴标签
panel_title(ax2, S, '(b) 与样品年龄的偏差'); % 设置右子图标题
note_text(fig, S, ' 完整编目的撞击坑密度约为人工校核子集的 5 倍，导致年龄系统性偏老；改用校核子集后偏差明显缩小。'); % 写图 8 底部对照注记
exportgraphics(fig, fullfile(FIG, 'fig8_source_compare.png'), 'Resolution', 300); % 导出图 8 PNG 图件
close(fig); % 关闭图 8 画布
end % 结束来源对照图函数

%% ======================================================================
function style_ax(ax, S, varargin) % 子函数：统一坐标轴样式
set(ax, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'ZColor', 'k', ... % 设置白底与黑色轴线
   'Box', 'off', 'TickDir', 'out', 'LineWidth', 0.8, ... % 去边框并让刻度朝外
   'FontName', S.fontCN, 'FontSize', S.fsTick, ... % 设置统一字体与刻度字号
   'GridColor', S.gridCol, 'GridAlpha', 1, 'GridLineStyle', ':', ... % 设置浅灰点状网格
   'XGrid', 'on', 'YGrid', 'on', 'Layer', 'top'); % 打开网格并置顶图层
if ~isempty(varargin), set(ax, varargin{:}); end % 应用调用方附加设置
end % 结束坐标轴样式函数

function panel_title(ax, S, txt) % 子函数：写子图标题
title(ax, txt, 'FontName', S.fontCNB, 'FontSize', S.fsTitle, ... % 用黑体写子图标题
    'FontWeight', 'normal', 'Color', 'k'); % 设置标题字重与颜色
end % 结束子图标题函数

function note_text(fig, S, txt) % 子函数：添加底部注记
annotation(fig, 'textbox', [0.03 0.008 0.94 0.045], 'String', txt, ... % 创建图下注记文本框
  'EdgeColor', 'none', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ... % 设置无边框与左对齐
  'FontName', S.fontCN, 'FontSize', S.fsNote, 'Color', [0.15 0.15 0.15]); % 设置注记字体字号颜色
end % 结束底部注记函数

function [lat2, lon2] = circle_latlon(lat1, lon1, radius_km, R) % 子函数：球面圆边界点
th = linspace(0, 2*pi, 361); % 生成圆周方位角序列
d = radius_km / R; % 区域半径换算为球心角
p1 = deg2rad(lat1); l1 = deg2rad(lon1); % 圆心经纬度转弧度
p2 = asin(sin(p1)*cos(d) + cos(p1)*sin(d)*cos(th)); % 球面三角求边界点纬度
l2 = l1 + atan2(sin(th)*sin(d)*cos(p1), cos(d) - sin(p1)*sin(p2)); % 球面三角求边界点经度
lat2 = rad2deg(p2); % 纬度结果转回角度
lon2 = mod(rad2deg(l2) + 180, 360) - 180; % 经度归一化到正负 180
end % 结束球面圆边界函数

function m = model_of() % 子函数：缓存年代模型参数
persistent mp % 声明持久变量保存模型
if isempty(mp), mp = s04_model(); end % 首次调用时载入模型
m = mp; % 返回缓存的模型参数
end % 结束模型缓存函数
