 function [cat, meta] = import_catalog_file(path) % 函数声明：读取并统一常见格式的撞击坑编目
 %IMPORT_CATALOG_FILE 读取常见的撞击坑编目文件
 %
 % 支持：
 % .mat : 含结构体变量 cat，字段至少为 lon、lat、D
 % .txt : 优先按项目 LU1319373 格式解析，失败后按表头自动识别
 % .csv : 按表头自动识别 lon/lat/diameter
 % .xlsx : 按表头自动识别 lon/lat/diameter
 %
 % 输出 cat 统一使用 km，字段为 lon、lat、D、source（如有）。
 % 本函数只负责数据读取与单位整理，不包含 CSFD 或年龄反演算法。

 if ~isfile(path) % 先检查输入文件路径是否存在
    error('找不到数据文件：%s', path); % 文件不存在时报错并提示路径
 end % 结束文件存在性检查

 [~, ~, ext] = fileparts(path); % 提取文件扩展名以判断格式
 ext = lower(ext); % 扩展名统一转小写，避免大小写差异

 switch ext % 按扩展名分派到不同读取分支
   case '.mat' % MATLAB 数据文件分支
      S = load(path); % 加载 MAT 文件中的变量
      assert(isfield(S, 'cat'), 'MAT 文件中没有变量 cat。'); % 断言文件内含编目结构体 cat
      cat = S.cat; % 取出编目结构体
      meta = struct('read_mode', 'MATLAB MAT', ... % 记录读取方式为 MATLAB MAT
                'diameter_unit', '文件原始单位'); % 记录直径沿用文件原始单位

   case '.txt' % 文本编目分支，优先 LU1319373 格式
     cacheFile = [tempname, '.mat']; % 为文本解析准备临时缓存路径
     try % 优先尝试按项目编目格式解析
         cat = s01_read_catalog(path, cacheFile); % 调用编目读取函数解析文本
         meta = struct('read_mode', 'LU1319373 文本格式', ... % 记录读取方式为 LU1319373 文本
                  'diameter_unit', 'm -> km'); % 记录直径已由米换算为千米
     catch % 解析失败时转入通用表格读取
         cat = read_table_catalog(path); % 按表头关键字自动识别列读取
         meta = struct('read_mode', '按表头识别文本', ... % 记录读取方式为按表头识别
                  'diameter_unit', '自动判断'); % 记录直径单位由程序自动判断
     end % 结束文本解析格式尝试
     if isfile(cacheFile) % 若临时缓存已生成则准备清理
         delete(cacheFile); % 删除临时缓存文件，避免残留
     end % 结束临时缓存清理

  case {'.csv', '.xlsx', '.xls'} % 电子表格编目分支
    cat = read_table_catalog(path); % 按表头自动识别经纬度与直径列
    meta = struct('read_mode', '按表头识别表格', ... % 记录读取方式为按表头识别表格
              'diameter_unit', '自动判断'); % 记录直径单位自动判断结果

  otherwise % 其他扩展名一律拒绝
    error('暂不支持文件类型：%s', ext); % 报错提示暂不支持该文件类型
end % 结束格式分派

required = {'lon', 'lat', 'D'}; % 列出统一编目必须具备的字段
missing = required(~isfield(cat, required)); % 找出缺失的必需字段
if ~isempty(missing) % 存在缺失字段则进入报错
   error('编目缺少字段：%s', strjoin(missing, ', ')); % 报错并列出缺失字段名
end % 结束字段完整性检查

cat.lon = double(cat.lon(:)); % 经度统一转双精度列向量
cat.lat = double(cat.lat(:)); % 纬度统一转双精度列向量
cat.D = double(cat.D(:)); % 直径统一转双精度列向量
bad = ~isfinite(cat.lon) | ~isfinite(cat.lat) | ... % 标记坐标非有限的坏记录
     ~isfinite(cat.D) | cat.D <= 0; % 直径非有限或非正也视为无效
if isfield(cat, 'source') % 编目含来源字段时同步清洗
    cat.source = double(cat.source(:)); % 来源编号转为双精度列向量
    cat.source(bad) = []; % 删除坏记录对应的来源编号
end % 结束来源字段清洗
cat.lon(bad) = []; % 删除坏记录的经度
cat.lat(bad) = []; % 删除坏记录的纬度
cat.D(bad) = []; % 删除坏记录的直径
cat.lon = mod(cat.lon + 180, 360) - 180; % 经度归一到 [-180,180] 区间

if isempty(cat.D) % 若清洗后没有记录则进入报错
    error('文件中没有有效的撞击坑记录。'); % 提示文件无有效撞击坑记录
end % 结束有效记录检查

meta.n_records = numel(cat.D); % 统计有效记录条数
meta.lon_range = [min(cat.lon), max(cat.lon)]; % 记录经度范围供结果追溯
meta.lat_range = [min(cat.lat), max(cat.lat)]; % 记录纬度范围供结果追溯
meta.diameter_range_km = [min(cat.D), max(cat.D)]; % 记录直径范围（km）
end % 结束编目导入主函数

function cat = read_table_catalog(path) % 子函数：按表头识别列的表格读取
T = readtable(path, 'VariableNamingRule', 'preserve'); % 保留原始列名读取表格
names = string(T.Properties.VariableNames); % 取全部列名转字符串数组
low = lower(names); % 列名转小写，便于不区分大小写匹配

idxLon = find(contains(low, ["lon", "longitude", "经度"]), 1); % 按关键词定位经度列
idxLat = find(contains(low, ["lat", "latitude", "纬度"]), 1); % 按关键词定位纬度列
idxDia = find(contains(low, ["diameter", "diam", "直径"]) | low == "d", 1); % 按关键词或单字母 D 定位直径列

if isempty(idxLon) || isempty(idxLat) || isempty(idxDia) % 关键列识别失败时进入报错分支
    error(['无法从表头识别经纬度和直径列。可用列名示例：', ... % 报错说明无法从表头识别关键列
        'lon/longitude/经度、lat/latitude/纬度、diameter/D/直径。']); % 给出可接受的列名示例
end % 结束关键列识别检查

lon = double(T{:, idxLon}); % 取出经度列并转双精度
lat = double(T{:, idxLat}); % 取出纬度列并转双精度
D = double(T{:, idxDia}); % 取出直径列并转双精度

% 常见编目以 m 为单位；若中位直径明显大于 km 编目，则换算为 km。

 unitName = 'km'; % 先假定直径单位为千米
 if median(D(isfinite(D) & D > 0), 'omitnan') > 10 % 中位直径大于 10 时判定为米制
    D = D / 1000; % 直径由米换算为千米
    unitName = 'm -> km'; % 记录已做米到千米的单位换算
 end % 结束直径单位判断

 cat = struct('lon', lon, 'lat', lat, 'D', D); % 组装统一编目结构体
 idxSrc = find(contains(low, ["source", "来源"]), 1); % 查找可选的来源列
 if ~isempty(idxSrc) % 存在来源列时读取
    cat.source = double(T{:, idxSrc}); % 读取来源编号并转双精度
 end % 结束来源列读取
 cat.header = strjoin(cellstr(names), ', '); % 把原始表头拼成字符串存档
 cat.source_file = path; % 记录数据来源文件路径
 cat.imported_diameter_unit = unitName; % 记录导入时的直径单位判断结果
 end % 结束表格读取子函数
