# Data | 数据准备

本仓库**不分发**原始撞击坑编目，只保留读取、校验和缓存代码。要让 `run_all`
真正跑出四个研究区的年龄，需要按下面的步骤自行获取编目。本页给出的是"哪一个
版本、从哪里拿、怎么校验、单位是什么"的完整说明——只写数据集名字是不够的，
因为同名文件存在多个版本，单位（米/千米）和来源字段都会直接改变定年结果。

---

## 1. 数据是什么

| 项 | 值 |
| --- | --- |
| 编目名称 | **LU1319373** — Lunar Global Crater Catalog（直径 ≥ 1 km） |
| 数据作者 | Wang, Y. & Wu, B.（2021） |
| 记录数 | **1,319,373** 条（本项目实测：文件共 1,319,390 行 = 17 行说明/表头 + 1,319,373 条记录） |
| 直径范围 | 0.98 – 2491.90 km，中位 1.56 km（本项目 `s01` 实测输出） |
| 来源构成 | Source=0：1,006,919 条（76.3%）；Source=1：311,777 条（23.6%）；Source=2：322 条；Source=3：354 条；Source=4：1 条 |
| 坐标系 | 月固坐标系（selenographic），十进制度，经度 −180 … +180 |

对应论文：Wang, Y., Wu, B., Xue, H., Li, X., & Ma, J. (2021). *An improved global
catalog of lunar impact craters (≥1 km) with 3D morphometric information and
updates on global crater analysis.* **JGR: Planets, 126, e2020JE006728.**
DOI: [10.1029/2020JE006728](https://doi.org/10.1029/2020JE006728)

---

## 2. 从哪里下载（唯一权威来源）

| 项 | 值 |
| --- | --- |
| 数据发布页 | <https://zenodo.org/records/4983248> |
| 数据集 DOI | **10.5281/zenodo.4983248** |
| 文件名 | `LU1319373_Wang&Wu_2021.rar` |
| 文件大小 | **25,340,193** 字节（约 24.2 MiB） |
| 校验值 | **md5 `df786c981cb848a5151d0262dba22f5a`** |
| 记录发布 | 2021-06-18（记录最后更新 2021-08-20） |
| 版本说明 | Zenodo 该记录只有一个数据版本，目录里的 DOI 即版本 DOI；引用时请同时给出数据集 DOI 与上面论文 DOI |

> 该记录同时包含 `R-Value Maps/` 目录（14 个 `.tif`/`.mxd` 文件）。本项目**只用**
> 其中的 `LU1319373_Wang & Wu_2021.txt`，其余文件与本流程无关。

---

## 3. 下载、校验、解压

PowerShell（Windows）：

```powershell
# 1) 下载（Zenodo 会跳到签名地址；若报 schannel CRYPT_E_REVOCATION_OFFLINE 就加 --ssl-no-revoke）
curl.exe -L --ssl-no-revoke --retry 8 --retry-all-errors `
  -o "LU1319373_Wang&Wu_2021.rar" `
  "https://zenodo.org/api/records/4983248/files/LU1319373_Wang%26Wu_2021.rar/content"

# 2) 校验（必须与上表一致，否则不要用这份数据）
(Get-FileHash "LU1319373_Wang&Wu_2021.rar" -Algorithm MD5).Hash.ToLower()

# 3) 解压出编目本体（7-Zip；WinRAR 亦可）
& "C:\Program Files\7-Zip\7z.exe" x "LU1319373_Wang&Wu_2021.rar" `
  "-odata/raw/LU1319373" "LU1319373_Wang & Wu_2021.txt"
```

macOS / Linux：`curl -LO` 同一 URL，`md5sum` 校验，`unrar x` 或 `7z x` 解压。

---

## 4. 期望的目录与文件名

```
data/raw/LU1319373/LU1319373_Wang & Wu_2021.txt     ← 77,241,513 字节
```

`code/config.m` 里的默认路径就是它（`cfg.rawCatalog`）。如果放在别处或改名，
只改 `cfg.rawCatalog` 一处即可；脚本按表头关键字识别列，不依赖文件名。

首次运行后会在 `data/processed/catalog.mat` 生成解析缓存（v7.3，约 60 MB，
已在 `.gitignore` 中忽略）。删除该文件即可强制重新解析原始文本。

---

## 5. 文件内部结构（已核对）

- 编码 UTF-8，**TAB 分隔**，共 9 列；
- 第 1–16 行是说明文字，**第 17 行是表头**；
- 表头原文（注意原始文件里的两处拼写错误，脚本按关键字匹配所以不受影响）：

```
ID  Lonitude(degree)  Latitude(degree)  Diameter(m)  Depth(m)  Source
    Source_lon(degree)  Soure_lat(degree)  Source_dia(m)
```

| 列 | 含义 | 单位 |
| --- | --- | --- |
| `ID` | 统一编号 | — |
| `Lonitude(degree)` | 坑心经度（原文拼写缺 `g`） | 十进制度，−180…180 |
| `Latitude(degree)` | 坑心纬度 | 十进制度，−90…90 |
| `Diameter(m)` | 撞击坑直径 | **米** |
| `Depth(m)` | 撞击坑深度（DEM 高斯拟合） | **米** |
| `Source` | 记录来源代码 | — |
| `Source_lon` / `Soure_lat` / `Source_dia` | 原始来源的坐标与直径（仅 1/3、2/4 行有值） | 度 / 米 |

**Source 代码含义**（来自文件自带说明）：

| 代码 | 含义 |
| --- | --- |
| 0 | 本编目自产（Wang & Wu, 2021） |
| 1 | 来自 Robbins (2019)，经过坑缘拟合处理 |
| 2 | 来自 Head et al. (2010)，经过坑缘拟合处理 |
| 3 | 来自 Robbins (2019)，未做坑缘拟合 |
| 4 | 来自 Head et al. (2010)，未做坑缘拟合 |

代码里自动完成的单位与坐标处理（`code/s01_read_catalog.m`）：

1. `Diameter`、`Depth` 由**米换算为千米**（`/1000`）；
2. 经度归一到 `[-180, 180]`；
3. 剔除坐标或直径非有限、直径 ≤ 0 的记录；
4. `cat.source` 原样保留 0–4，供 `diagnose_sources.m` 做来源子集对照。

---

## 6. 为什么数据不进仓库

- 原始编目 77 MB（压缩后 24 MB），进仓库会让 clone 变得很重；
- 编目版权归数据作者所有，**本仓库不二次分发**，请遵守 Zenodo 记录上的使用条款；
- 代码只需要路径和格式，缓存文件已在 `.gitignore` 中忽略。

---

## 7. 自查清单：解析成功后应当看到

运行 `run('code/run_all.m')`，第 1 步输出必须与下表吻合，否则说明下载到的不是
本页描述的那个版本：

| 检查项 | 期望值 |
| --- | --- |
| 读取规模 | 1,319,390 行 × 9 列 |
| 保留记录 | 1,319,373 条 |
| 直径范围 | 0.98 – 2491.90 km（中位 1.56 km） |
| Source=0 占比 | 1,006,919 条（76.3%） |
| 四个研究区坑数（半径 120 km，面积 45,221 km²） | 静海 1120 / 风暴洋 672 / 嫦娥五号 386 / 笛卡尔高地 1729 |

---

## 8. 没有数据也能跑

`code/test_synthetic.m` 用合成编目走完"CSFD → 年龄反演 → 蒙特卡洛 → 敏感性 →
出图"整条链路，不需要任何外部数据，适合先确认环境可用：

```matlab
run('code/test_synthetic.m')
```
