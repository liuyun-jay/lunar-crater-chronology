% ========================================================================
% 文件名：config.m
% 作用：项目的“总开关”。统一保存路径、月球常数、研究区和算法参数。
% 通俗原理：后续程序都从这里读取同一套设置，避免每个文件各写一遍常数，
%       也便于只改一个文件就调整区域半径、拟合区间或蒙特卡洛次数。
% 输入：无。
% 输出：cfg 结构体，包含文件夹路径、月球半径、4 个研究区和算法参数。
% 使用：几乎所有脚本开始计算前都先调用 cfg = config()。
% 注意：经纬度采用月球固定坐标系，纬度单位是度，直径单位是 km。
% ========================================================================
function cfg = config() % 函数声明：返回项目统一配置结构体
%CONFIG 项目统一配置：路径、常数、研究区、算法参数

% ---- 路径 ----
here = fileparts(mfilename('fullpath')); % 取本配置文件所在目录（code/）
cfg.root      = fileparts(here);            % 项目根目录
cfg.dirRaw = fullfile(cfg.root, 'data', 'raw'); % 原始数据存放目录
cfg.dirProc = fullfile(cfg.root, 'data', 'processed'); % 预处理与缓存目录
cfg.dirResults = fullfile(cfg.root, 'results'); % 数值结果输出目录
cfg.dirFigures = fullfile(cfg.root, 'figures'); % 图件输出目录
for d = {cfg.dirProc, cfg.dirResults, cfg.dirFigures} % 遍历需要自动创建的三个输出目录
   if ~exist(d{1}, 'dir'), mkdir(d{1}); end % 目录不存在时创建，保证写出不报错
end % 结束输出目录创建循环

% ---- 原始数据与缓存 ----
cfg.rawCatalog = fullfile(cfg.dirRaw, 'LU1319373', ... % 原始全月编目路径（第一段）
                    'LU1319373_Wang & Wu_2021.txt'); % 原始编目文件名，供 s01 读取
cfg.cacheCatalog = fullfile(cfg.dirProc, 'catalog.mat'); % 编目缓存文件路径，避免重复解析

% ---- 月球常数 ----
cfg.R_moon = 1737.4;   % 月球平均半径 (km)

% ---- 研究区定义 ----
% center_lat/lon 为月固坐标系（度），radius_km 为球面圆半径。
% ref_age 为返回样品或文献给出的参考年龄（Ga），仅用于对照，不参与反演。
cfg.regions = struct( ... % 研究区定义：用结构体数组存四个区域
  'key',     {'tranquillitatis', 'procellarum', 'ce5', 'highlands'}, ... % 四个研究区的英文键名
  'name',     {'静海（Apollo 11 着陆区）', '风暴洋（Apollo 12 着陆区）', ... % 研究区中文名称（前两个）
            '嫦娥五号着陆区（年轻玄武岩单元）', '笛卡尔高地（Apollo 16，对照区）'}, ... % 研究区中文名称（后两个）
  'lat',    {0.674, -3.012, 43.06, -8.973}, ... % 四个区域中心纬度（度）
  'lon',     {23.473, -23.422, -51.92, 15.501}, ... % 四个区域中心经度（度）
  'radius_km', {120, 120, 120, 120}, ... % 四个区域统计圆半径（km）
  'ref_age', {3.70, 3.20, 2.03, 4.20}, ... % 参考年龄（Ga），仅供对照不参与反演
  'ref_age_src',{'Apollo 11 玄武岩样品（约 3.6–3.8 Ga）', ... % 静海参考年龄的样品依据
            'Apollo 12 玄武岩样品（约 3.1–3.3 Ga）', ... % 风暴洋参考年龄的样品依据

        '嫦娥五号玄武岩样品（Che et al., 2021；Li et al., 2021）', ... % 嫦娥五号参考年龄的文献依据
        '高地表面，无就地样品年龄；仅作方法适用边界对照'} ... % 高地对照区说明：无就地样品年龄
); % 结束研究区结构体数组构造

% ---- CSFD 分箱参数 ----
cfg.csfd.Dmin = 1.0; % 编目下限 (km)
cfg.csfd.Dmax = 50.0; % 分箱上限 (km)
cfg.csfd.nbins = 24; % 对数分箱数，兼顾分辨率与每箱计数

% ---- 默认拟合区间 ----
cfg.fit.Dfit_min = 1.0; % 加权最小二乘拟合区间下限（km）
cfg.fit.Dfit_max = 10.0; % 拟合区间上限（km），避开饱和段
cfg.fit.Tmin = 0.01; % 年龄搜索下限（Ga）
cfg.fit.Tmax = 4.5; % 年龄搜索上限（Ga）
cfg.fit.TgridN = 400; % 年龄粗扫描网格点数（对数等距）

% ---- 蒙特卡洛 ----
cfg.mc.niter = 1000; % 蒙特卡洛重采样次数
cfg.mc.seed = 20260922; % 随机种子，保证结果可复现

% ---- 合成数据自检 ----
cfg.selftest.Tlist = [0.5 1.0 2.0 3.0 3.7]; % 自检使用的已知合成年龄（Ga）
cfg.selftest.Dlo = 1.0; % 自检合成编目直径下限（km）
cfg.selftest.Dhi = 20.0; % 自检合成编目直径上限（km）
cfg.selftest.area = 7.0e4; % 自检统计面积（km²），与月海区域同量级
cfg.selftest.nreal = 200; % 每个合成年龄的重复次数
cfg.selftest.seed = 20260922; % 自检随机种子
end % 结束配置函数
