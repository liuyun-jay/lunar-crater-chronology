 % ========================================================================
 % 文件名：s03_csfd.m
 % 作用：把研究区内一堆直径数值整理成累积尺寸-频率分布 CSFD。
 % 通俗原理：按直径从小到大切出若干互不重叠的箱子，先数每个箱子里有
 %       几个坑，再从大到小累加，得到“至少大于某直径”的坑数；
 %       最后除以研究区面积，把“个数”变成科学上通用的“密度”。
 % 输入：D_km 直径向量；area_km2 研究区面积；opt 分箱设置。
 % 输出：cs 结构体，包含箱边界、每箱计数、累积计数和 N(>D)。
 % 注意：N(>D) 必须除以面积，否则不同大小的区域之间无法比较。
 % ========================================================================
 function cs = s03_csfd(D_km, area_km2, opt) % 函数声明：构建累积尺寸-频率分布 CSFD
 %S03_CSFD 由撞击坑直径构建累积尺寸-频率分布 N(>D)
 %
 % 输入
 % D_km : 区域内撞击坑直径（km），向量
 % area_km2 : 统计面积（km^2）
 % opt : 结构体，字段 Dmin, Dmax, nbins
 % 输出（结构体 cs）
 % edges : 分箱边界（km，对数等间距）
 % counts : 各箱的坑数（互不重叠）
 % n_cum : 各箱下界对应的累积个数
 % D         : 累积点对应的直径（取箱下界，标准做法）
 % N         : 累积密度 N(>D)，km^-2
 % area : 面积
 %

% 注意：N(>D) 是"密度"而非"数量"，必须除以统计面积。直径小于 Dmin 的
% 撞击坑不参与统计，但只要累积起点取箱下界，N(>D)（D>=Dmin）仍然正确。

D_km = D_km(:); % 直径转列向量，统一方向
D_km = D_km(isfinite(D_km) & D_km > 0); % 剔除非有限与非正的直径

edges = logspace(log10(opt.Dmin), log10(opt.Dmax), opt.nbins + 1); % 生成对数等距分箱边界
counts = histcounts(D_km, edges); % 统计每个直径区间的独立泊松计数
counts = counts(:); % 计数转列向量

n_cum = flipud(cumsum(flipud(counts))); % 从大直径向小累加得累积计数

cs.edges = edges(:); % 输出分箱边界
cs.counts = counts; % 输出每箱独立计数
cs.n_cum = n_cum; % 输出累积计数
cs.D = edges(1:end-1)'; % 累积点直径取箱下界
cs.N = n_cum ./ area_km2; % 除以面积得到累积密度 N(>D)
cs.area_km2 = area_km2; % 记录统计面积供复核
cs.n_total_above_Dmin = n_cum(1); % 记录 Dmin 以上撞击坑总数
end % 结束 CSFD 构建函数
