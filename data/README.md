# LU1319373 crater catalog | 数据集来源与准备

本项目使用 **LU1319373** 全球月球撞击坑编目（直径 ≥1 km，共 1,319,373 条记录），该编目由 **Yiran Wang、Bo Wu 等**建立，并公开保存在 Zenodo。

## Data publication / 原始研究文献

Wang, Y., Wu, B., Xue, H., Li, X., & Ma, J. (2021). *An Improved Global Catalog of Lunar Impact Craters (≥1 km) With 3D Morphometric Information and Updates on Global Crater Analysis*. **Journal of Geophysical Research: Planets**. DOI: https://doi.org/10.1029/2020JE006728

## Download / 正式数据来源

| 发布记录 | DOI / 链接 | 压缩包及 Zenodo 公布的 MD5 |
|---|---|---|
| Zenodo Version 1 | [10.5281/zenodo.4605503](https://doi.org/10.5281/zenodo.4605503) | `LU1319373_Wang & Wu_2021.rar` · `e3eb01bb2426aa4010a06c7152808f5c` |
| Zenodo 较新记录 | [10.5281/zenodo.4983248](https://doi.org/10.5281/zenodo.4983248) | `LU1319373_Wang&Wu_2021.rar` · `df786c981cb848a5151d0262dba22f5a` |

**说明：** 上表校验值属于原始 **RAR 压缩包**，不是解压后的 TXT 文件。两个存档的校验值不同，复现时应明确记录实际使用的版本；本仓库目前没有保存原研究所用 TXT 的 SHA-256，因此不将其与某个存档强行视为字节级完全一致。

## Configure / 配置方法

1. 从 Zenodo 下载对应 RAR 压缩包并解压，先核对实际文件名、列名及单位。
2. 将用于程序输入的 TXT 编目放置在：

   `data/raw/LU1319373/LU1319373_Wang & Wu_2021.txt`

3. 如果解压后的文件名或路径不同，修改 `code/config.m` 中的 `cfg.rawCatalog`。
4. 检查经纬度所在坐标系、直径单位（米 / km）及 `source` 来源编码，并保留下载信息。
5. 运行 `run('code/run_all.m')`，与研究报告中的四区 CSFD、模式年龄和来源子集对照相比较。

## Verify files / 校验与记录

**Windows PowerShell：**

```powershell
Get-FileHash -Algorithm MD5 ".\LU1319373_Wang & Wu_2021.rar"
Get-FileHash -Algorithm SHA256 ".\LU1319373_Wang & Wu_2021.txt"
```

**macOS / Linux：**

```bash
md5sum "LU1319373_Wang & Wu_2021.rar"
sha256sum "LU1319373_Wang & Wu_2021.txt"
```

建议在本地记录：Zenodo DOI、版本、下载日期、压缩包 MD5、解压 TXT SHA-256、记录数、列名与实际研究区筛选配置。外部原始编目遵循数据发布方许可，本仓库不重复分发。

不需要真实编目也可运行 `run('code/test_synthetic.m')` 检查模型的合成数据链路。
