#!/usr/bin/env bash
set -e

mkdir -p src/viewfinderpanoramas
cd src/viewfinderpanoramas

echo "========================================="
echo ">>> 全自动高程数据 (HGT) 下载器 (中国全境)"
echo ">>> 数据源: Viewfinder Panoramas (3秒精度)"
echo "========================================="

# 覆盖中国的标准网格编号
GRIDS=(
    # 华南、海南及南海
    "E48" "E49" "E50"
    "F48" "F49" "F50" "F51"
    # 云贵川、华南、华东
    "G46" "G47" "G48" "G49" "G50" "G51"
    "H43" "H44" "H45" "H46" "H47" "H48" "H49" "H50" "H51"
    # 西藏、新疆、中原、华北
    "I43" "I44" "I45" "I46" "I47" "I48" "I49" "I50" "I51"
    "J43" "J44" "J45" "J46" "J47" "J48" "J49" "J50" "J51"
    "K43" "K44" "K45" "K46" "K47" "K48" "K49" "K50" "K51" "K52" "K53"
    # 东北、内蒙古
    "L44" "L45" "L46" "L47" "L48" "L49" "L50" "L51" "L52" "L53"
    "M45" "M46" "M47" "M48" "M49" "M50" "M51" "M52" "M53"
    "N49" "N50" "N51" "N52" "N53"
)

BASE_URL="https://viewfinderpanoramas.org/dem3"

for GRID in "${GRIDS[@]}"; do
    FILE_NAME="${GRID}.zip"
    URL="${BASE_URL}/${FILE_NAME}"

    # 检查是否已经下载或解压
    if [ ! -d "$GRID" ] && [ ! -f "$FILE_NAME" ]; then
        echo ">>> 正在下载区块: $GRID ..."
        # wget -c 开启断点续传，防止网络波动
        wget -c -q --show-progress "$URL" || echo "  [警告]: $GRID 下载失败，可能为纯海洋区域。"
    fi

    # 如果有 zip 包，解压它
    if [ -f "$FILE_NAME" ]; then
        echo "  [执行]: 解压 $GRID ..."
        unzip -q -o "$FILE_NAME"
        rm -f "$FILE_NAME" # 解压后删除 zip，节省硬盘空间
    fi
done

echo "========================================="
echo ">>> 中国区高程数据下载并解压完毕！"
echo "========================================="
