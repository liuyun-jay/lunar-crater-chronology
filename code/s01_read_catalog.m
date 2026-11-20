 % ========================================================================
 % 文件名：s01_read_catalog.m
 % 作用：读取全月撞击坑编目，把坐标、直径、深度和来源整理成统一格式。
 % 通俗原理：原始文件既有说明行又有制表符分隔的数据，还可能有拼写错误。
 %       本程序先自动找到表头，再按关键词找列，最后把直径由米换算成公里。
 %       处理结果保存为 catalog.mat，以后可直接读取缓存，不必每次解析大文件。
 % 输入：rawFile 原始 TXT 路径；cacheFile 缓存 MAT 文件路径。
 % 输出：cat 结构体，字段为 lon/lat（度）、D/depth（km）、source 和元信息。
 % 使用：cat = s01_read_catalog(cfg.rawCatalog, cfg.cacheCatalog)。
 % ========================================================================
 function cat = s01_read_catalog(rawFile, cacheFile) % 函数声明：读取并统一全月撞击坑编目
 %S01_READ_CATALOG 读取全月撞击坑编目 LU1319373 并统一字段
 %
 % 数据来源：Wang, Y., Wu, B., Xue, H., Li, X., & Ma, J. (2021).
 % An improved global catalog of lunar impact craters (>=1 km) with 3D

%   morphometric information and updates on global crater analysis.
%   JGR: Planets, 126, e2020JE006728. 数据 DOI: 10.5281/zenodo.4983248
%
%   原始文件特征（已核对）：
%   - 制表符（TAB）分隔；
%   - 前 16 行是说明文字，第 17 行是字段名（原始表头里 "Longitude"
%     被拼写成 "Lonitude"，脚本按关键字匹配，不依赖拼写）；
%   - 直径与深度单位是【米】，本函数统一换算为【千米】；
%   - 含 Source 字段：0=本编目自产，1/3=源自 Robbins (2019)，
%     2/4=源自 Head et al. (2010)。
%
%   输出结构体 cat：lon, lat（度），D, depth（km），source，header，source_file

if exist(cacheFile, 'file') % 缓存文件已存在时优先读缓存
   S = load(cacheFile); % 加载缓存 MAT 文件
   cat = S.cat; % 取出缓存的编目结构体
   fprintf(' 已从缓存读取编目：%s（%d 个撞击坑）\n', cacheFile, numel(cat.D)); % 打印缓存来源与编目坑数
   return; % 直接返回，跳过重新解析
end % 结束缓存分支

fprintf(' 解析原始编目：%s\n', rawFile); % 打印正在解析的原始文件路径

% ---- 1. 定位字段名所在行与分隔符 ----
hdrIdx = NaN; % 初始化表头行号为未找到
delim = sprintf('\t'); % 默认分隔符设为制表符
fid = fopen(rawFile, 'r', 'n', 'UTF-8'); % 以 UTF-8 编码打开文本文件
if fid < 0, error('无法打开文件：%s', rawFile); end % 打开失败时报错，避免后续空句柄
for i = 1:60 % 只在前 60 行内搜索表头
    line = fgetl(fid); % 逐行读取一行文本
    if ~ischar(line), break; end % 读到文件末尾则停止搜索
    if contains(line, 'Diameter') && (contains(line, 'Lon') || contains(line, 'Lat')) % 同含 Diameter 与 Lon/Lat 即判定为表头
       hdrIdx = i; % 记录表头所在行号
       if ~contains(line, sprintf('\t')) % 表头不含制表符时改用逗号分隔
          delim = ','; % 分隔符切换为逗号
       end % 结束分隔符判断
       headerLine = line; % 保存表头原始文本以便解析列名
       break; % 找到表头后立即跳出搜索
    end % 结束表头判定
end % 结束前 60 行搜索循环
fclose(fid); % 关闭文件句柄
if isnan(hdrIdx) % 未找到表头时进入报错
    error('未能在前 60 行中找到字段名行，请检查文件格式。'); % 提示未找到字段名行并终止
end % 结束表头存在性检查
fprintf(' 字段名位于第 %d 行，分隔符为 TAB\n', hdrIdx); % 打印表头行号与分隔符信息

% ---- 2. 解析列名（对拼写错误保持鲁棒）----
cols = strtrim(strsplit(headerLine, delim)); % 按分隔符拆分表头并去空白
low = lower(cols); % 列名转小写，容忍大小写差异
idxLon = find(contains(low, {'lonitude', 'longitude', 'lon'}), 1); % 关键词匹配经度列（兼容原始拼写错漏）
idxLat = find(contains(low, {'latitude', 'lat'}), 1); % 关键词匹配纬度列
idxDia = find(contains(low, 'diameter'), 1); % 关键词匹配直径列
idxDep = find(contains(low, 'depth'), 1); % 关键词匹配深度列（可选）
idxSrc = find(strcmp(low, 'source'), 1); % 精确匹配来源列（可选）
if isempty(idxLon) || isempty(idxLat) || isempty(idxDia) % 关键列缺失时进入报错
    error('未能识别经纬度/直径列，表头为：%s', headerLine); % 报错并打印表头原文
end % 结束关键列检查
fprintf(' 使用列：经度=%s，纬度=%s，直径=%s', ... % 打印选用的经度/纬度/直径列名
    cols{idxLon}, cols{idxLat}, cols{idxDia}); % 填入三个关键列名
if ~isempty(idxDep), fprintf('，深度=%s', cols{idxDep}); end % 存在深度列时打印其列名
if ~isempty(idxSrc), fprintf('，来源=%s', cols{idxSrc}); end % 存在来源列时打印其列名

fprintf('\n'); % 补换行结束表头信息输出

% ---- 3. 读取数值矩阵 ----
t0 = tic; % 开始计时读取大文件
M = readmatrix(rawFile, 'NumHeaderLines', hdrIdx, 'Delimiter', delim, ... % 跳过表头行按分隔符读数值矩阵
          'OutputType', 'double'); % 指定读入为双精度数值
fprintf(' 读取 %d 行 × %d 列，用时 %.1f s\n', size(M, 1), size(M, 2), toc(t0)); % 打印矩阵尺寸与读取耗时

cat.lon = M(:, idxLon); % 经度列赋给编目
cat.lat = M(:, idxLat); % 纬度列赋给编目
cat.D = M(:, idxDia) / 1000;        % m -> km；直径由米换算为千米
if ~isempty(idxDep) % 存在深度列时读取深度
   cat.depth = M(:, idxDep) / 1000; % m -> km；深度由米换算为千米
else % 无深度列时进入空值分支
   cat.depth = []; % 深度字段置空，保持结构一致
end % 结束深度列判断
if ~isempty(idxSrc) % 存在来源列时读取来源
   cat.source = M(:, idxSrc); % 来源编号直接取原始数值
else % 无来源列时进入默认分支
   cat.source = zeros(size(cat.D)); % 来源默认全部记为 0（不明）
end % 结束来源列判断

% ---- 4. 清洗与坐标统一 ----
n0 = numel(cat.D); % 记录清洗前的记录总数
bad = ~isfinite(cat.lon) | ~isfinite(cat.lat) | ~isfinite(cat.D) | cat.D <= 0; % 标记坐标或直径非有限、直径非正的记录
cat.lon(bad) = []; cat.lat(bad) = []; cat.D(bad) = []; % 同步剔除坏记录的经纬度与直径
if ~isempty(cat.depth), cat.depth(bad) = []; end % 有深度时同步剔除坏记录深度
cat.source(bad) = []; % 同步剔除坏记录的来源编号
cat.lon = mod(cat.lon + 180, 360) - 180; % 经度归一到 [-180,180]
fprintf(' 剔除无效记录 %d 条，保留 %d 条\n', n0 - numel(cat.D), numel(cat.D)); % 打印剔除与保留的记录数

% ---- 5. 基础统计（用于第三方检查）----
fprintf(' 直径范围：%.2f–%.2f km（中位 %.2f km）\n', ... % 打印直径范围与中位直径
   min(cat.D), max(cat.D), median(cat.D)); % 填入直径最小、最大与中位值
srcIds = unique(cat.source); % 统计全部不同的来源编号
fprintf(' 来源构成：'); % 打印来源构成提示
for s = srcIds(:)' % 逐个来源统计记录数
   fprintf(' Source=%d: %d 条(%.1f%%)', s, sum(cat.source == s), ... % 打印该来源的条数与占比
      100 * sum(cat.source == s) / numel(cat.D)); % 计算该来源所占百分比
end % 结束来源构成循环
fprintf('\n'); % 换行结束来源统计输出

cat.header = headerLine; % 把表头原文存入编目元信息
cat.source_file = rawFile; % 记录原始数据文件路径

% ---- 6. 缓存（体积大，用 v7.3）----
if ~exist(fileparts(cacheFile), 'dir'), mkdir(fileparts(cacheFile)); end % 缓存目录不存在时先创建
save(cacheFile, 'cat', '-v7.3'); % 用 v7.3 格式缓存编目（体积大）
fprintf(' 已缓存到：%s\n', cacheFile); % 打印缓存文件路径
end % 结束编目读取函数
