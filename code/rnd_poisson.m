 % ========================================================================
 % 文件名：rnd_poisson.m
 % 作用：自己生成泊松随机数，避免依赖需要额外安装的统计工具箱。
 % 通俗原理：撞击坑在某区域的计数近似服从泊松分布。对于均值很大的情况，
 %       把均值拆成若干小份分别抽样，再把结果相加；泊松分布相加后
 %       仍是泊松分布，所以计算正确且循环次数可控。
 % 输入：lambda 非负均值，可以是标量或向量。
 % 输出：k 与 lambda 同形状的非负整数。
 % 关键：每份使用 Knuth 乘积法，连乘均匀随机数直到小于 exp(-lam/m)。
 % ========================================================================
 function k = rnd_poisson(lambda) % 函数声明：自实现泊松随机数发生器
 %RND_POISSON 自实现泊松随机数发生器（不依赖 Statistics Toolbox）
 %
 % 算法：把 Poisson(lam) 拆成 m 个独立 Poisson(lam/m) 之和，每份用 Knuth
 % 乘积法抽样。泊松分布对求和封闭，因此结果是精确的（浮点误差以内）；
 % 拆分保证每份均值小于 20，Knuth 法的循环次数可控。

 %
 %   之所以自己写：本机 MATLAB 未安装 Statistics and Machine Learning
 %   Toolbox，poissrnd 不可用；同时自实现也让论文的核心算法完全透明。
 %
 %   输入 lambda：非负标量或向量
 %   输出 k ：与 lambda 同形的非负整数

 lambda = max(lambda(:), 0); % 均值转列向量并截断负值
 k = zeros(numel(lambda), 1); % 预分配输出随机数向量
 for i = 1:numel(lambda) % 逐个均值元素抽样
    lam = lambda(i); % 当前元素的泊松均值
    if lam <= 0 % 均值为 0 时直接返回 0
        continue; % 跳过本次抽样
    end % 结束零均值判断
    m = max(1, ceil(lam / 20)); % 按均值约 20 拆成 m 份，控制循环次数
    lamPart = lam / m; % 每份的泊松均值
    L = exp(-lamPart); % Knuth 乘积法的比较阈值 exp(-lam/m)
    total = 0; % 累加各份抽样结果
    for j = 1:m % 遍历 m 个独立小泊松分量
        p = 1; % 乘积初始化为 1
        n = 0; % 计数初始化为 0
        while true % Knuth 乘积法抽样循环
           n = n + 1; % 计数加一
           p = p * rand(); % 连乘均匀随机数
           if p <= L % 乘积跌破阈值即停止
              break; % 跳出抽样循环
           end % 结束阈值判断
        end % 结束 Knuth 抽样循环
        total = total + n - 1; % 该分量抽样值累加进总数
    end % 结束分量循环
    k(i) = total; % 保存该元素的泊松随机数
 end % 结束逐元素抽样
 end % 结束泊松随机数函数
