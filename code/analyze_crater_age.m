 % ========================================================================
 % 文件名：analyze_crater_age.m
 % 作用：单研究区撞击坑统计定年的统一入口。
 % 通俗原理：它本身不做数学公式，只负责把调用方给出的参数装配好，
 %       然后依次调用已验证的 s02_regions → s03_csfd → s05_fit_age →
 %       s06_montecarlo，再补上拟合区间敏感性。这样不同调用入口
 %       共享同一条算法链，避免各自重复实现同一套计算。
 % 输入：
 % cat      : 撞击坑编目结构体，至少包含 lon、lat、D；可含 source。
 % regionKey : 研究区 key，默认 'tranquillitatis'。
 % opt      : 可选参数 radius_km、Dfit_min、Dfit_max、mc_niter、mc_seed、
 %          source（'full' / 'vetted'）、Dmin、Dmax、nbins。
 % 输出：out 结构体，包含研究区、CSFD、最佳拟合年龄、蒙特卡洛误差、
 %      敏感性和统一输出所需的关键指标。
 % 使用：out = analyze_crater_age(cat, 'tranquillitatis', opt)。
 % ========================================================================
 function out = analyze_crater_age(cat, regionKey, opt) % 函数声明：单区域定年统一入口
 %ANALYZE_CRATER_AGE 单研究区 CSFD 构建、年龄反演与误差传播

 if nargin < 2 || isempty(regionKey) % 未指定研究区时进入默认分支
    regionKey = 'tranquillitatis'; % 默认研究区取静海（Apollo 11 着陆区）
 end % 结束默认研究区判断
 if nargin < 3 || isempty(opt) % 未给出可选参数时进入默认分支
    opt = struct(); % 空结构体表示全部沿用配置文件默认值
 end % 结束可选参数判断

 validateattributes(cat, {'struct'}, {'nonempty'}, mfilename, 'cat', 1); % 校验第一输入必须是非空结构体编目
 required = {'lon', 'lat', 'D'}; % 列出编目必须具备的三个字段
 missing = required(~isfield(cat, required)); % 找出编目中缺失的必需字段
 if ~isempty(missing) % 存在缺失字段时进入报错分支

  error('编目结构体缺少字段：%s', strjoin(missing, ', ')); % 报错并列出缺失字段名，阻止错误计算
end % 结束字段完整性检查

cfg = config(); % 读取项目统一配置（路径、研究区、算法参数）
model = s04_model(); % 加载 Neukum 生产函数与年代函数模型
reg = select_region(cfg.regions, regionKey); % 按 key 或中文名定位目标研究区

% ---- 可选参数；未给时完全沿用 config.m 的论文默认值 ----
if isfield(opt, 'radius_km') && ~isempty(opt.radius_km) % 调用方给出区域半径时覆盖默认值
    reg.radius_km = opt.radius_km; % 用可选半径替换研究区半径（km）
end % 结束半径覆盖判断

csOpt = cfg.csfd; % 以配置中的 CSFD 分箱参数为基准
for f = {'Dmin', 'Dmax', 'nbins'} % 遍历可被覆盖的三个分箱参数名
   if isfield(opt, f{1}) && ~isempty(opt.(f{1})) % 该分箱参数存在且非空时才覆盖
       csOpt.(f{1}) = opt.(f{1}); % 把可选分箱参数写入 CSFD 设置
   end % 结束单个分箱参数判断
end % 结束分箱参数遍历

fitOpt = cfg.fit; % 以配置中的拟合参数为基准
for f = {'Dfit_min', 'Dfit_max', 'Tmin', 'Tmax', 'TgridN'} % 遍历拟合区间与年龄网格参数名
   if isfield(opt, f{1}) && ~isempty(opt.(f{1})) % 该拟合参数被显式给出时执行覆盖
       fitOpt.(f{1}) = opt.(f{1}); % 写入调用方指定的拟合参数
   end % 结束单个拟合参数判断
end % 结束拟合参数遍历

mcOpt = cfg.mc; % 以配置中的蒙特卡洛参数为基准
for f = {'niter', 'seed'} % 遍历重采样次数与随机种子两个参数
   if isfield(opt, f{1}) && ~isempty(opt.(f{1})) % 该蒙特卡洛参数被给出时执行覆盖
       mcOpt.(f{1}) = opt.(f{1}); % 写入调用方指定的蒙特卡洛参数
   end % 结束单个蒙特卡洛参数判断
end % 结束蒙特卡洛参数遍历

% ---- 编目来源子集：完整编目或人工校核记录（Source=1/3）----
sourceName = '完整编目'; % 数据来源标记默认取完整编目
if isfield(opt, 'source') && ~isempty(opt.source) % 若指定了编目来源子集则进入分支
    sourceName = opt.source; % 记录调用方选择的数据来源标识
end % 结束编目来源判断
catWork = cat; % 复制一份工作编目，避免修改原始输入
if strcmpi(sourceName, 'vetted') % 识别是否要求人工校核子集
    if ~isfield(cat, 'source') % 校核子集需要 source 字段，先检查
       error('当前编目没有 source 字段，无法选择“人工校核子集”。'); % 缺少 source 字段时报错，无法挑选校核记录
    end % 结束 source 字段检查
    keep = ismember(cat.source(:), [1, 3]); % 来源子集判据：Source=1/3 视为人工校核坑
    catWork.lon = cat.lon(keep); % 只保留校核坑的经度
    catWork.lat = cat.lat(keep); % 只保留校核坑的纬度
    catWork.D = cat.D(keep); % 只保留校核坑的直径
    sourceName = '人工校核子集（Source=1/3）'; % 把来源标记更新为人工校核子集
end % 结束编目来源子集筛选

cfgR = cfg; % 复制配置用于只分析单个研究区
cfgR.regions = reg; % 把配置的研究区替换为目标区域
regionResult = s02_regions(catWork, cfgR); % 用球面大圆与球冠面积圈定研究区
r = regionResult(1); % 取唯一区域结果，再逐项挂接算法输出

% ---- 核心算法链：CSFD → 年龄反演 → 泊松蒙特卡洛 ----
r.cs = s03_csfd(r.D, r.area_km2, csOpt); % 构建对数分箱 CSFD 与累积密度 N(>D)
r.fit = s05_fit_age(r.cs.D, r.cs.n_cum, r.cs.area_km2, model, fitOpt); % 加权最小二乘反演最佳拟合年龄

r.mc = s06_montecarlo(r.cs.counts, r.cs.D, r.cs.area_km2, model, fitOpt, mcOpt); % 对每箱独立计数做泊松重采样传播误差

% ---- 拟合区间敏感性：报告全部结果，不选择性地挑区间 ----
sensRanges = [1 5; 1 10; 1 20; 2 10; 1.5 15]; % 拟合区间敏感性方案：五组直径上下限（km）
sens = repmat(struct('Dfit_min', [], 'Dfit_max', [], ... % 预分配敏感性结果结构体数组
              'T', [], 'n_points', [], 'chi2red', []), ... % 结果字段：年龄、拟合点数、reduced χ²
          size(sensRanges, 1), 1); % 按方案数确定结构体数组长度
for j = 1:size(sensRanges, 1) % 遍历五组拟合区间方案
   fopt = fitOpt; % 每组方案都从基准拟合参数出发
   sens(j).Dfit_min = sensRanges(j, 1); % 记录本方案的拟合下限直径
   sens(j).Dfit_max = sensRanges(j, 2); % 记录本方案的拟合上限直径
   fopt.Dfit_min = sensRanges(j, 1); % 把本方案下限写入临时拟合参数
   fopt.Dfit_max = sensRanges(j, 2); % 把本方案上限写入临时拟合参数
   f = s05_fit_age(r.cs.D, r.cs.n_cum, r.cs.area_km2, model, fopt); % 在该拟合区间内重新反演年龄
   sens(j).T        = f.T; % 保存该区间的最佳拟合年龄
   sens(j).n_points = f.npts; % 保存该区间参与拟合的点数
   sens(j).chi2red = f.chi2red; % 保存该区间的 reduced χ² 指标
end % 结束拟合区间敏感性循环

% ---- 统一输出字段 ----
out.key         = r.key; % 输出区域键名，便于批量汇总
out.name         = r.name; % 输出区域中文名称
out.lat       = r.lat; % 输出研究区中心纬度
out.lon        = r.lon; % 输出研究区中心经度
out.radius_km       = r.radius_km; % 输出统计圆半径（km）
out.area_km2       = r.area_km2; % 输出球冠统计面积（km²）
out.n_craters     = r.n; % 输出区域内撞击坑总数
out.N_gt_1km         = r.cs.N(1); % 输出 1 km 处的累积密度 N(>1 km)
out.n_fit_points = r.fit.npts; % 输出参与拟合的累积点数
out.T_mode         = r.fit.T; % 输出加权最小二乘的模式年龄
out.T_median        = r.mc.T_med; % 输出蒙特卡洛年龄中位数
out.T_lo        = r.mc.T_lo; % 输出年龄分布 16% 分位下界
out.T_hi        = r.mc.T_hi; % 输出年龄分布 84% 分位上界
out.T_std        = r.mc.T_std; % 输出蒙特卡洛年龄标准差（1σ）
out.chi2red      = r.fit.chi2red; % 输出拟合的 reduced χ² 拟合优度
out.reference_age = reg.ref_age; % 输出样品或文献参考年龄（Ga）
out.reference_source = reg.ref_age_src; % 输出参考年龄的来源说明
out.data_source = sourceName; % 输出本结果使用的编目来源子集
out.mc_niter      = r.mc.niter; % 输出有效蒙特卡洛样本数
out.cs         = r.cs; % 输出完整 CSFD 结构体供复核
out.fit       = r.fit; % 输出拟合细节：网格、残差、使用点
out.mc          = r.mc; % 输出蒙特卡洛年龄样本链
out.sens        = sens; % 输出五组拟合区间的敏感性结果
out.model        = model; % 输出所用生产函数与年代函数参数
out.parameters = struct('csfd', csOpt, 'fit', fitOpt, 'mc', mcOpt); % 输出本次运行实际生效的全部算法参数
out.completed_at = char(datetime('now', 'TimeZone', 'local', ... % 记录完成时间，便于结果追溯
                       'Format', 'yyyy-MM-dd HH:mm:ss')); % 指定时间格式为年月日时分秒
end % 结束单区域定年主函数

% ------------------------------------------------------------------------
function reg = select_region(regions, key) % 子函数：在研究区列表里按标识查区域
%SELECT_REGION 同时接受项目内 key 或完整中文区域名，便于按名称调用
idx = find(strcmp({regions.key}, key), 1); % 先按英文 key 精确匹配
if isempty(idx) % key 未命中时进入名称匹配分支
    idx = find(strcmp({regions.name}, key), 1); % 再按中文区域名精确匹配
end % 结束英文 key 匹配判断
if isempty(idx) % 两种匹配都失败则报错
    error('未知研究区“%s”。', key); % 提示未知研究区名，终止计算
end % 结束名称匹配判断

reg = regions(idx); % 取出命中的研究区配置结构体
end % 结束区域查找子函数
