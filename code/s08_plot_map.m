% ========================================================================
% 文件名：s08_plot_map.m
% 作用：绘制全月撞击坑密度地图，并标出 4 个研究区。

% 通俗原理：把月球表面切成 1°×1° 小格，每格统计坑数后除以该格的真实
%       球面面积，得到可比较的密度；颜色越亮表示单位面积坑越多。
%       圆形边界也用球面公式计算，避免在高纬度变形。
% 输入：cat 编目；cfg 配置；R 研究区结果。
% 输出：figures/fig1_catalog_map.png。
% ========================================================================
function s08_plot_map(cat, cfg, R) % 函数声明：绘制全月密度地图
%S08_PLOT_MAP 绘制全月撞击坑密度分布图（图 1）并标注研究区

fig = figure('Color', 'w', 'Position', [80 80 1180 620]); % 新建图 1 画布
ax = axes(fig); hold(ax, 'on'); % 创建坐标区并保持叠加

% ---- 1° x 1° 网格上的实际密度（每个网格除以自身球面面积）----
edgesLon = -180:1:180; % 经度网格边界取 1 度
edgesLat = -90:1:90; % 纬度网格边界取 1 度
ix = discretize(cat.lon, edgesLon); % 把坑经度归入网格列
iy = discretize(cat.lat, edgesLat); % 把坑纬度归入网格行
ok = ~isnan(ix) & ~isnan(iy); % 筛除越界的经纬度
cnt = accumarray([iy(ok), ix(ok)], 1, ... % 按网格统计撞击坑数
           [numel(edgesLat)-1, numel(edgesLon)-1]); % 指定统计矩阵行列数

phiE = deg2rad(edgesLat); % 纬度边界转成弧度
dA = cfg.R_moon^2 * deg2rad(1) * abs(diff(sin(phiE))); % 每行网格面积 (km^2)
dens = cnt ./ dA(:);                     % km^-2；每格坑数除以真实球面面积
dens(dens <= 0) = NaN; % 空格子设为 NaN 不显示

imagesc(ax, edgesLon(1:end-1)+0.5, edgesLat(1:end-1)+0.5, log10(dens)); % 用伪彩色显示对数密度
set(ax, 'YDir', 'normal'); % 纬度轴方向设为向上
colormap(ax, flipud(hot)); % 使用翻转的 hot 色图
cb = colorbar(ax); % 添加颜色条
cb.Label.String = 'log_{10}[N(D\geq1 km) / km^{-2}]'; % 色标标题为对数密度
cb.Label.FontName = 'SimSun'; % 色标字体设为宋体
caxis(ax, [-5.6 -2.6]); % 固定色标范围便于比较

% ---- 研究区位置 ----
colors = [0.10 0.45 0.85; 0.85 0.33 0.10; 0.00 0.55 0.35; 0.55 0.20 0.70]; % 设置四个研究区颜色
for k = 1:numel(R) % 逐个研究区画范围
   [clat, clon] = circle_latlon(R(k).lat, R(k).lon, R(k).radius_km, cfg.R_moon); % 按球面公式算圆周经纬
   plot(ax, clon, clat, '-', 'Color', colors(k, :), 'LineWidth', 2.0); % 绘制研究区圆形边界
   text(ax, R(k).lon, R(k).lat, sprintf(' %d', k), 'Color', colors(k, :), ... % 在中心标区域序号
      'FontWeight', 'bold', 'FontSize', 13, 'FontName', 'SimSun'); % 序号加粗并设字体
end % 结束研究区循环

xlabel(ax, '经度 (°E)', 'FontName', 'SimSun'); % 横轴标注经度
ylabel(ax, '纬度 (°N)', 'FontName', 'SimSun'); % 纵轴标注纬度
title(ax, '全月撞击坑密度分布与研究区位置（数据：LU1319373，Wang et al., 2021）', ... % 图 1 标题含数据来源
    'FontName', 'SimSun', 'FontSize', 12); % 设置标题字体字号
axis(ax, [-180 180 -90 90]); % 固定全月经纬范围
set(ax, 'FontName', 'SimSun', 'FontSize', 10); % 设置坐标区字体字号
box(ax, 'on'); % 显示坐标框
aspect_equal(ax); % 按经纬比例校正纵横比

legend(ax, arrayfun(@(k) sprintf('%d %s', k, R(k).name), 1:numel(R), ... % 生成研究区图例
   'UniformOutput', false), 'Location', 'southoutside', 'Orientation', 'horizontal', ... % 图例横排放在图下方
   'FontName', 'SimSun', 'FontSize', 9); % 设置图例字体与字号

exportgraphics(fig, fullfile(cfg.dirFigures, 'fig1_catalog_map.png'), 'Resolution', 300); % 导出图 1 为 300 dpi PNG
close(fig); % 关闭图 1 窗口
end % 主函数结束

 % ------------------------------------------------------------------------
 function [lat2, lon2] = circle_latlon(lat1, lon1, radius_km, R) % 子函数：生成球面圆边界
 %CIRCLE_LATLON 生成球面上以 (lat1,lon1) 为中心、半径 radius_km 的圆
 th = linspace(0, 2*pi, 361); % 圆周方位角采样 361 点
 d = radius_km / R; % 把半径换算成角半径
 p1 = deg2rad(lat1); l1 = deg2rad(lon1); % 中心点经纬转弧度
 p2 = asin(sin(p1)*cos(d) + cos(p1)*sin(d)*cos(th)); % 球面公式求圆周纬度
 l2 = l1 + atan2(sin(th)*sin(d)*cos(p1), cos(d) - sin(p1)*sin(p2)); % 球面公式求圆周经度
 lat2 = rad2deg(p2); % 纬度转回角度
 lon2 = mod(rad2deg(l2) + 180, 360) - 180; % 经度归一化到正负 180 度
 end % 子函数结束

 function aspect_equal(ax) % 子函数：设置等比例显示
 p = get(ax, 'Position'); % 记录坐标区原位置
 xl = xlim(ax); yl = ylim(ax); % 读取坐标轴范围
 ratio = (diff(xl)) / (diff(yl)); % 计算横纵范围之比
 set(ax, 'DataAspectRatio', [1 1 1], 'PlotBoxAspectRatio', [ratio 1 1]); % 按范围比设置盒形比例
 set(ax, 'Position', p); % 恢复坐标区原位置
 end % 子函数结束
