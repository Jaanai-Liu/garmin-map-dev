#!/usr/bin/env bash
set -e

mkdir -p src/geofabrik

echo "========================================="
echo ">>> Automated Geofabrik Data Downloader"
echo "========================================="

# --- USER CONFIGURATION START ---
# Add or remove province names based on Geofabrik's naming convention
PROVINCES=(
    "anhui" "chongqing" "fujian" "gansu" "guangdong"
    "guangxi" "guizhou" "hainan" "hebei" "heilongjiang"
    "henan" "hubei" "hunan" "inner-mongolia" "jiangsu"
    "jiangxi" "jilin" "liaoning" "ningxia" "qinghai"
    "shaanxi" "shandong" "shanghai" "shanxi" "sichuan"
    "tibet" "xinjiang" "yunnan" "zhejiang"
)
# --- USER CONFIGURATION END ---

BASE_URL="https://download.geofabrik.de/asia/china"
for PROV in "${PROVINCES[@]}"; do
    FILE_NAME="${PROV}-latest.osm.pbf"
    URL="${BASE_URL}/${FILE_NAME}"
    echo "Checking/Updating: $PROV ..."
    # -N: only download if newer than local file
    # -c: continue getting a partially-downloaded file
    wget -N -c -q --show-progress "$URL" -P src/geofabrik/
done

echo "========================================="
echo ">>> Download Process Complete!"
echo "========================================="
