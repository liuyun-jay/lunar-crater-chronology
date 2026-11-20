# Lunar Crater Chronology in MATLAB | MATLAB 月球撞击坑统计定年

**A computational planetary-science course/research project** exploring crater size-frequency distributions (CSFD), lunar surface age estimation and uncertainty assessment.  
**状态：** 本科课程/探索性研究项目；不是已发表或同行评审的论文。代码从项目文档的 MATLAB 附录整理，**尚未在当前环境重新运行验证**。

## Project overview / 项目简介

This project estimates model ages of selected lunar regions from crater counts using MATLAB. It combines spherical region selection, CSFD statistics, Neukum-based chronology, optimization and Monte Carlo resampling. The analysis compares different crater-catalog subsets and investigates whether catalog composition and region choice affect inferred ages.

基于全月撞击坑编目，构建月球表面撞击坑累积尺寸—频率分布，利用 Neukum 生产函数/年代函数反演模式年龄，并通过合成数据回收、蒙特卡洛重采样、拟合区间敏感性和编目来源子集对照分析检验结果与方法适用性。

**Study areas / 研究区**
- Mare Tranquillitatis — Apollo 11 landing region / 静海
- Oceanus Procellarum — Apollo 12 landing region / 风暴洋
- Chang'e-5 landing region / 嫦娥五号着陆区
- Descartes Highlands — Apollo 16 comparison region / 笛卡尔高地

## Key methods / 核心方法

- Lunar-fixed coordinates and great-circle distances for regional crater selection
- Cumulative size-frequency distribution (CSFD), logarithmic diameter bins
- Neukum production/chronology functions and weighted least-squares age fitting
- Poisson Monte Carlo resampling for count-related uncertainty
- Synthetic-data recovery tests, diameter-range and region-radius sensitivity
- Comparisons of full-catalog and source-filtered crater subsets
- Figures, tables and diagnostic outputs

## Figures / 图件

Eight figures from the study report are retained in the separate project upload package. They are not yet in this GitHub repository. Numerical results have not been reproduced by running these extracted MATLAB sources in the present environment.

## Repository layout / 目录

```text
code/                    26 MATLAB source files, extracted from the report appendix
  run_all.m               Main data-to-figures workflow
  config.m                Paths, study areas, model/evaluation settings
  test_synthetic.m        Synthetic-data workflow test
  analyze_crater_age.m    Single-region analysis interface
  ...                     CSFD, fitting, diagnostics, visualization

docs/                     Research context and important limitations
data/raw/                 Put locally obtained source catalog here (not included)
```

## Run / 运行

**Reported development environment:** MATLAB R2025a, using built-in MATLAB functions without additional toolboxes. The following instructions describe the original intended workflow, **not a newly verified installation**.

1. Obtain the **LU1319373** lunar crater catalog from its original source and confirm that you may use it. The full catalog is **not redistributed** in this repository.
2. Place the originally named data file at:

   `data/raw/LU1319373/LU1319373_Wang & Wu_2021.txt`

   Alternatively, update `cfg.rawCatalog` in `code/config.m` to your local catalog path.
3. From the repository root in MATLAB, execute:

```matlab
run('code/run_all.m')
```

To exercise the model without the external crater catalog, inspect `code/test_synthetic.m`; it uses synthetic input and was included as a test in the original appendix. **Not run/tested by the portfolio packaging process.**

### Data and reproducibility

- The full 1.3-million-record crater catalog and local caches are not included. See [`data/README.md`](data/README.md).
- Analysis scripts may generate `results/`, `figures/`, and `data/processed/` at runtime.
- The `.m` files were recovered from the **November 2026 report appendix**. They are not guaranteed byte-for-byte identical to the author's original working `.m` files. Please compare against the original project folder before a research reproduction or scientific release.
- The public figures document reported calculations; reproducibility requires the specified catalog, matching MATLAB version and rerunning all scripts.

## Research limitations / 研究局限

> **Crater-count model ages are not sample-dated ages.** The result can depend on catalog detection method/source, diameter completeness, mixed geological units, reference chronology and fitting choices. In particular, a catalog complete only to about 1 km is not appropriate to resolve some very young lunar surfaces; the Chang'e-5 region needs higher-resolution cataloging and careful geological-unit boundaries.

The original report documents these limitations rather than treating every returned numerical age as physically definitive. More details: [Results and limitations](docs/RESULTS_AND_LIMITATIONS.md).

## Authorship and use

Personal academic/learning portfolio of [@liuyun-jay](https://github.com/liuyun-jay). This repository is not a journal publication. Third-party crater catalog data are not included. **No software license is granted here by default**; contact the author before reuse or redistribution beyond applicable legal exceptions.