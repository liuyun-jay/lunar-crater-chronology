% ========================================================================
% 文件名：s02_regions.m
% 作用：按经纬度圈出研究区，并把区域内撞击坑与球面面积整理出来。
% 通俗原理：月球是球体，不能把经度、纬度差直接当成平面距离。
%       本程序用球面大圆距离判断“坑是否在圆内”，再用球冠公式算面积。
%       这样才能正确得到 N(>D) 所需要的分母 A。
% 输入：cat 编目结构体；cfg 配置，其中 cfg.regions 定义中心点和半径。
% 输出：R 结构体数组，包含每个区域的面积、坑数、直径和坐标。
% 使用：R = s02_regions(cat, cfg)。
% ========================================================================
function R = s02_regions(cat, cfg) % 函数声明：按球面圆选取研究区并算面积
%S02_REGIONS 按球面圆选取研究区，并计算球面面积与区域内撞击坑
%
% 第三方检查要点：
% 1) 区域面积必须用球面几何计算，不能用"经纬度差 × 111 km"的平面近似，
% 否则在高纬度（如嫦娥五号位于 43°N）会带来明显的面积误差；
% 2) 区域中心与半径的选择必须能自圆其说（落在单一月海单元内部、
% 避开大型撞击坑溅射毯），并在论文中给出判据。

R = struct('key', {}, 'name', {}, 'lat', {}, 'lon', {}, 'radius_km', {}, ... % 预置空结构体数组模板，统一字段顺序
       'area_km2', {}, 'n', {}, 'D', {}, 'lat_in', {}, 'lon_in', {}, ... % 模板第二组字段：面积、坑数、直径与坐标
       'ref_age', {}, 'ref_age_src', {}); % 模板末组字段：参考年龄及其来源

for k = 1:numel(cfg.regions) % 遍历配置中的四个研究区
   reg = cfg.regions(k); % 取出当前研究区定义

  % 球面圆面积：A = 2*pi*R^2*(1 - cos(r/R))
  A = 2 * pi * cfg.R_moon^2 * (1 - cos(reg.radius_km / cfg.R_moon)); % 球冠面积公式 A=2πR²(1-cos(r/R))

  d = great_circle_km(cat.lat, cat.lon, reg.lat, reg.lon, cfg.R_moon); % 计算每个坑到区域中心的球面大圆距离
  in = d <= reg.radius_km; % 距离不超过半径即判定坑在研究区内

  R(k).key      = reg.key; % 保存区域键名
  R(k).name      = reg.name; % 保存区域中文名
  R(k).lat     = reg.lat; % 保存区域中心纬度
  R(k).lon     = reg.lon; % 保存区域中心经度
  R(k).radius_km = reg.radius_km; % 保存球面圆半径（km）
  R(k).area_km2 = A; % 保存球冠统计面积（km²）
  R(k).n       = sum(in); % 统计区域内撞击坑总数
  R(k).D       = cat.D(in); % 提取区域内撞击坑直径（km）
  R(k).lat_in = cat.lat(in); % 提取区域内撞击坑纬度
  R(k).lon_in = cat.lon(in); % 提取区域内撞击坑经度
  R(k).ref_age = reg.ref_age; % 保存参考年龄（Ga）
  R(k).ref_age_src = reg.ref_age_src; % 保存参考年龄来源说明

  fprintf(' 区域「%s」：中心 (%.3f°, %.3f°) ，半径 %.0f km ，面积 %.0f km² ，坑数 %d\n', ... % 打印区域名称、中心坐标、半径、面积与坑数
    reg.name, reg.lat, reg.lon, reg.radius_km, A, R(k).n); % 填入区域统计量输出参数
end % 结束逐区域循环
end % 结束研究区选取函数

% ------------------------------------------------------------------------
function d = great_circle_km(lat1, lon1, lat2, lon2, R) % 子函数：球面大圆距离（km）
%GREAT_CIRCLE_KM 球面大圆距离（Haversine 公式），单位 km
p1 = deg2rad(lat1); p2 = deg2rad(lat2); % 把两组纬度换算为弧度

 dl = deg2rad(lon2 - lon1); % 经度差换算为弧度
 dp = p2 - p1; % 纬度差（弧度）
 a = sin(dp/2).^2 + cos(p1) .* cos(p2) .* sin(dl/2).^2; % Haversine 公式中间量 a
 d = 2 * R .* atan2(sqrt(a), sqrt(max(1 - a, 0))); % 用 atan2 反解大圆距离，数值稳定
 end % 结束大圆距离子函数
