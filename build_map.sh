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
    pyhgtmap -s 20 -0 --pbf --output-prefix=src/contours_cache/contour $HGT_FILES
    echo ">>> [Global]: Contour cache created."
else
    echo ">>> [Global]: Using existing contour cache."
fi

# --- PHASE 2: Region Configuration (USER EDITABLE) ---
# Format: ["RegionName"]="province1 province2 ..."
declare -A REGIONS
REGIONS=(
    ["China_Northeast"]="heilongjiang jilin liaoning hainan"
    ["China_Shanhe"]="shanxi shandong henan hebei"
    ["China_Southwest"]="sichuan yunnan guizhou chongqing"
    ["China_Northwest"]="xinjiang tibet gansu ningxia shaanxi"
    ["China_East"]="shanghai jiangsu zhejiang anhui"
    ["China_South"]="guangdong guangxi fujian"
    ["China_Central"]="hubei hunan jiangxi"
    ["China_North"]="inner-mongolia beijing tianjin"
)

# --- PHASE 3: Processing Loop ---
for REGION_NAME in "${!REGIONS[@]}"; do
    echo -e "\n>>>>>>>> Processing Region: $REGION_NAME <<<<<<<<"
    PROVINCES=${REGIONS[$REGION_NAME]}
    rm -rf build_temp/*

    # Gather road data files
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

    echo "  [Task]: Splitting road network..."
    cd build_temp
    # Split roads into tiles Garmin can handle
    splitter --max-nodes=1000000 merged_roads.osm.pbf > /dev/null

    echo "  [Task]: Compiling final .img (Roads + Contours)..."
    CONTOUR_FILES=$(ls ../src/contours_cache/*.osm.pbf 2>/dev/null || true)

    # Run Mkgmap using the tile config (-c template.args)
    # and appending all contour files
    JAVA_OPTS="-Xmx16G" mkgmap \
        --family-id=1001 \
        --product-id=1 \
        --route \
        --remove-short-arcs \
        --style-file=../my_style/default \
        --description="$REGION_NAME" \
        --gmapsupp \
        -c template.args $CONTOUR_FILES
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
