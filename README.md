# Garmin Maps (China Regions)

🔗 **项目开源地址:** [https://github.com/Jaanai-Liu/garmin-map-dev](https://github.com/Jaanai-Liu/garmin-map-dev)

## 项目概述

本项目旨在解决佳明（Garmin）户外手表（如 Fenix 系列）加载全国详图时出现的卡顿问题。通过使用 OpenStreetMap (OSM) 开源路网数据与高精度高程数据（HGT），将中国大陆划分为多个大区进行独立编译。

> **⚠️ 注意：**
> 本仓库仅包含 NixOS 环境下的自动化构建脚本与样式配置，**不包含**最终编译好的 `.img` 地图实体文件。你可以克隆本仓库，在本地一键编译出属于你的纯净版地图。

**核心优势：**

- **区域解耦**：按大区生成 `.img` 镜像，用户可按需加载，显著降低手表芯片的渲染压力和内存占用。
- **性能优化**：通过自定义样式表（Style）过滤了大量建筑物多边形（Polygons），在保留核心导航信息的同时提升地图缩放流畅度。
- **高程集成**：内置 20 米精度的等高线数据。

## 数据来源 (Data Sources)

本项目的自动化编译依赖于以下两大开源地理数据源。路网数据可通过脚本自动拉取，高程数据需按需手动下载：

### 1. 路网与基础地物数据 (OSM PBF)

- **来源**: [Geofabrik (OpenStreetMap 免费镜像站)](https://download.geofabrik.de/asia/china.html)
- **说明**: Geofabrik 每天都会打包最新的全球 OSM 数据。本项目内置的 `download_data.sh` 脚本默认会全自动从该网站拉取中国各省份的最新 `.osm.pbf` 文件。

### 2. 高程与等高线数据 (DEM HGT)

- **来源**: [Viewfinder Panoramas (3" 分辨率)](http://viewfinderpanoramas.org/Coverage%20map%20viewfinderpanoramas_org3.htm)
- **说明**: 该网站提供全球极其精准的数字高程模型（DEM）。
- **操作须知**: 请在网页地图上点击你需要的中国区域方块（如 `J47`、`I48` 等），下载压缩包并解压出 `.hgt` 文件，然后将这些文件放入本项目的 `src/viewfinderpanoramas/` 目录下。`build_map.sh` 脚本会自动扫描它们并生成 20 米精度的等高线。

## 省份分组

目前默认的分组逻辑如下（可在脚本中自行调整组合）：

| 大区名称            | 包含省份/地区                      |
| :------------------ | :--------------------------------- |
| **China_Shanhe**    | 山西、山东、河南、河北             |
| **China_East**      | 上海、江苏、浙江、安徽             |
| **China_South**     | 广东、广西、福建                   |
| **China_Southwest** | 四川、云南、贵州、重庆             |
| **China_Northwest** | 西藏、青海、甘肃、宁夏、陕西 |
| **China_Xinjiang**  | 新疆                             |
| **China_Central**   | 湖北、湖南、江西                   |
| **China_North**     | 内蒙古、北京、天津                 |
| **China_Northeast** | 黑龙江、吉林、辽宁、海南           |

## 文件目录结构

```text
.
├── devenv.nix          # NixOS 开发环境配置，定义工具链依赖
├── download_data.sh    # 数据拉取脚本：从 Geofabrik 镜像站同步最新路网
├── build_map.sh        # 核心编译脚本：处理缝合、重编号、切片及封装
├── my_style/           # 自定义地图样式：用于控制元素显示逻辑（如屏蔽建筑）
├── src/
│   ├── geofabrik/      # 存放下载的原始路网 PBF 文件
│   ├── contours_cache/ # 存放处理后的等高线 PBF 缓存
│   └── viewfinderpanoramas/ # 存放原始 HGT 高程文件
└── output/             # 编译后输出地图目录
```

## 使用方法

### 1. 环境准备

本项目基于 NixOS `devenv` 构建。进入当前文件夹以进入开发环境或者使用其他系统配置开发环境，所需配置参考devenv.nix。

### 2. 获取数据

运行脚本下载所需的省份路网数据：

```bash
./download_data.sh
```

### 3. 开始编译

执行自动化构建流程：

```bash
./build_map.sh
```

### 4. 导入手表

编译完成后，进入 `output/` 下对应的批次文件夹，将生成的 `.img` 文件拷贝至佳明手表的 `Internal Storage/GARMIN/` 目录下。Fenix 7 系列总容量约 **16GB**，每张地图约 300MB~1GB，可按需选择加载。

#### Windows / macOS

手表通过 USB 连接电脑后，会以 U 盘形式自动挂载。直接将 `.img` 文件拖入 `Garmin` 文件夹即可。

#### Linux

Garmin 手表走 MTP 协议，不会自动挂载为磁盘，需手动操作。

**1. 连接手表，确认识别：**

```bash
lsusb | grep -i garmin
# Bus 001 Device 011: ID 091e:4f42 Garmin International
```

**2. 通过 gio 挂载：**

```bash
# 查看设备 activation_root
gio mount -l -i | grep -A 5 "091e"

# 挂载（替换为实际路径）
gio mount "mtp://091e_4f42_0000d838bc27/"
```

**3. 复制地图：**

```bash
gio copy China_Southwest.img "mtp://091e_4f42_0000d838bc27/Internal Storage/GARMIN/"
```

> 注意：Linux 下 MTP 不支持直接用 `cp`，必须用 `gio copy`。

**4. 验证并卸载：**

```bash
ls -lh "mtp://091e_4f42_0000d838bc27/Internal Storage/GARMIN/"China*.img
gio mount -u "mtp://091e_4f42_0000d838bc27/"
```

**5. 拔线，重启手表**，进入地图菜单即能看到新地图。

---

## 技术说明 (FAQ)

- **为什么不直接全量合并？** 强行合并全国数据会导致 ID 冲突和切片索引超限。解耦编译可以确保 ID 唯一性并提升编译成功率。
- **如何修改分组？** 修改 `build_map.sh` 中的 `REGIONS` 关联数组即可自定义你的专属区域。
