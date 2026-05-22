#!/usr/bin/env bash
set -e

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
OUT_DIR="output/$TIMESTAMP"
mkdir -p "$OUT_DIR"
mkdir -p build_temp
mkdir -p src/contours_cache

echo "========================================="
echo ">>> Garmin Map Build Pipeline (Decoupled)"
echo ">>> Batch: $TIMESTAMP"
echo "========================================="

# --- PHASE 1: Pre-process Contours (Cache) ---
echo ">>> [Global]: Processing HGT to Contour PBF..."
if [ -z "$(ls -A src/contours_cache 2>/dev/null)" ]; then
    HGT_FILES=$(find src/viewfinderpanoramas -type f -name "*.hgt")
    if [ -z "$HGT_FILES" ]; then
        echo ">>> [Error]: No .hgt files found in src/viewfinderpanoramas/"
        exit 1
    fi
    # Convert HGT to OSM PBF format
    # -s 50: 50m contour step (coarse enough for watch display)
    # -c 200,50: major contours every 200m, medium every 50m
    # --no-zero-contour: skip sea level (reduces coastal/ocean noise)
    # --simplifyContoursEpsilon=0.0002: RDP simplification (~50% fewer nodes)
    pyhgtmap -s 50 -c 200,50 --no-zero-contour --simplifyContoursEpsilon=0.0002 --pbf --output-prefix=src/contours_cache/contour $HGT_FILES
    echo ">>> [Global]: Contour cache created."
else
    echo ">>> [Global]: Using existing contour cache."
fi

# --- PHASE 2: Region Configuration (USER EDITABLE) ---
# Format: ["RegionName"]="province1 province2 ..."
declare -A REGIONS
REGIONS=(
    ["China_Northeast"]="heilongjiang jilin liaoning"
    ["China_Shanhe"]="shanxi shandong henan hebei"
    ["China_Southwest"]="sichuan yunnan guizhou chongqing"
    ["China_Northwest"]="tibet gansu ningxia shaanxi qinghai"
    ["China_Xinjiang"]="xinjiang"
    ["China_East"]="shanghai jiangsu zhejiang anhui"
    ["China_South"]="guangdong guangxi fujian hainan"
    ["China_Central"]="hubei hunan jiangxi"
    ["China_North"]="inner-mongolia beijing tianjin"
)

# --- PHASE 3: Processing Loop ---
for REGION_NAME in "${!REGIONS[@]}"; do
    echo -e "\n>>>>>>>> Processing Region: $REGION_NAME <<<<<<<<"
    PROVINCES=${REGIONS[$REGION_NAME]}
    rm -rf build_temp/*

    MERGE_ARGS=""
    for PROV in $PROVINCES; do
        FILE="src/geofabrik/${PROV}-latest.osm.pbf"
        if [ -f "$FILE" ]; then
            MERGE_ARGS="$MERGE_ARGS $FILE"
        fi
    done

    if [ -z "$MERGE_ARGS" ]; then continue; fi

    echo "  [Task]: Merging road networks..."
    osmium merge $MERGE_ARGS -o build_temp/merged_roads.osm.pbf --overwrite

    echo "  [Task]: Extracting regional contours from global cache..."

    echo "    -> Calculating exact bounding box (this may take a few seconds)..."
    BBOX=$(osmium fileinfo -e -g data.bbox build_temp/merged_roads.osm.pbf | tr -d '() ')

    if [ -z "$BBOX" ]; then
        echo "  [Error]: 边界计算失败！"
        exit 1
    fi

    if [ ! -f src/contours_cache/china_merged_contours.osm.pbf ]; then
        echo "    -> Compiling all contour tiles into a single global cache (First run only)..."
        osmium merge src/contours_cache/contour*.pbf -o src/contours_cache/china_merged_contours.osm.pbf --overwrite
    fi

    osmium extract -b $BBOX src/contours_cache/china_merged_contours.osm.pbf -o build_temp/regional_contours.osm.pbf --overwrite

    echo "  [Task]: Merging roads and contours (no renumber needed; ID ranges don't overlap)..."
    osmium merge build_temp/merged_roads.osm.pbf build_temp/regional_contours.osm.pbf -o build_temp/final_combined.osm.pbf --overwrite
    rm build_temp/merged_roads.osm.pbf build_temp/regional_contours.osm.pbf

    echo "  [Task]: Splitting fused map data..."
    cd build_temp
    splitter --max-nodes=1000000 --keep-complete=false final_combined.osm.pbf > /dev/null
    rm final_combined.osm.pbf

    echo "  [Task]: Compiling final .img (Roads + Contours)..."
    JAVA_OPTS="-Xmx16G" mkgmap \
        --family-id=1001 \
        --product-id=1 \
        --code-page=65001 \
        --name-tag-list=name:zh,name:zh-Hans,int_name,name \
        --index \
        --route \
        --remove-short-arcs \
        --transparent \
        --polygon-size-limits="24:12, 18:10, 16:8" \
        --style-file=../my_style/minimal \
        --description="$REGION_NAME" \
        --gmapsupp \
        -c template.args
    cd ..

    # Final Validation
    if [ -f "build_temp/gmapsupp.img" ] && [ $(stat -c%s "build_temp/gmapsupp.img") -gt 5242880 ]; then
        mv build_temp/gmapsupp.img "$OUT_DIR/${REGION_NAME}.img"
        SIZE=$(du -h "$OUT_DIR/${REGION_NAME}.img" | cut -f1)
        echo "  [Success]: -> $OUT_DIR/${REGION_NAME}.img ($SIZE)"
    else
        echo "  [Failure]: Build failed or file too small for $REGION_NAME"
    fi
done

rm -rf build_temp
echo "========================================="
echo ">>> Build Pipeline Finished!"
echo "========================================="
