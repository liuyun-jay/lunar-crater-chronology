# Reproducibility guide | 复现指南

## MATLAB 环境

推荐 **MATLAB R2025a**，这是原项目复核所用版本。 `prctile` 自 R2022a 起已包含在 MATLAB 本体中。CI 用 MATLAB R2025a 扫描源代码并运行合成数据冒烟测试。

## A. 快速端到端合成测试（无需外部编目）

从仓库根目录执行：

```matlab
run('code/test_synthetic.m')
```

- 固定合成年龄 `T_true = 3.70 Ga`，半径 `100 km`，区域面积约 `31,407 km²`。
- 对多个已知年龄执行每年龄 **60 次**合成实现；使用 `seed=20260922`。
- 执行 CSFD → 模型反演 → 泊松重采样 → 直径区间敏感性分析 → 输出 7 张测试图件。
- MATLAB R2025a 评估记录示例：单次回收 **3.696 Ga**（设定 3.70 Ga），蒙特卡洛中位数 **3.697 Ga**。

## B. 生产配置自检（仍无需外部编目）

```matlab
addpath('code');
cfg = config();
model = s04_model();
st = s07_selftest(model, cfg.selftest);
```

- 每个设定年龄 **200 次**、面积 **70,000 km²**、种子 `20260922`。
- 评估记录得到五个年龄的平均绝对偏差约 **0.029 Ga**，最大约 **0.046 Ga**。
- 注意不要把生产配置的最大偏差当成 A 中快速测试的必然上限。

## C. 全月编目真实数据计算

1. 按 [LU1319373 数据说明](../data/README.md) 下载、解压并记录真实数据版本。
2. 根据实际 TXT 文件位置修改 `code/config.m` 的 `cfg.rawCatalog`。
3. 执行：

```matlab
run('code/run_all.m')
```

4. 复核四个研究区的统计面积、坑数、CSFD、模式年龄、蒙特卡洛区间和输出图件。

## Entry points / 入口脚本与数据依赖

| 入口 | 用途 | 外部 LU1319373 编目 |
|---|---|---|
| `code/test_synthetic.m` | 合成数据端到端测试 | 不需要 |
| `code/run_all.m` | 完整编目计算与出图 | 需要 |
| `code/analyze_crater_age.m` | 以传入的编目结构体进行单区分析 | 由调用方提供 |
| `code/check_regions.m` | 检查各研究区及半径设置 | 需要 |
| `code/diagnose_ages.m` | 诊断模式年龄与参考年龄差异 | 需要 |
| `code/diagnose_ce5.m` | 嫦娥五号区域半径敏感性 | 需要 |
| `code/diagnose_sources.m` | 编目来源子集对照 | 需要 |
| `code/export_tables_only.m` | 从已保存的结果重新导表 | 需要预先生成的 results.mat |
| `code/make_paper_figures.m` | 从已保存的结果导出论文图件 | 需要预先生成结果与编目缓存 |

## Quality checks / 自动检查

`.github/workflows/matlab-ci.yml` 在主分支提交、PR 和手动触发时执行：

1. R2025a `codeIssues` 对 `code/` 全部 MATLAB 文件做静态分析，遇到 error 级问题即失败。
2. `test_synthetic.m` 检查合成数据计算流程可以运行并出图。

`codeIssues` 的 warning / info 单独显示，但不阻止 CI；完整编目数据不在仓库里，所以自动检查不执行真实编目的完整重算。

## Output interpretation

代码字段 `fit.chi2red` 是按自由度缩放的加权残差目标值，**不是严格定义的约化 χ² 统计量**；解释时请参见 [研究发现](RESEARCH_INSIGHTS.md)。
