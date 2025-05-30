#!/bin/bash

set -e

echo "[INFO] Starting test profile creation..."

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
download_dir="$script_dir/download"

if [ ! -d "$download_dir" ]; then
  echo
  echo "Error: 'download' directory not found. Please run 'make download' first."
  echo
  exit 0
fi

echo "[INFO] Copying Caribou test profiles ..."
rm -rf "$download_dir/caribou-fff"
cp -r "$script_dir/caribou-fff-test" "$download_dir/caribou-fff"

echo "[INFO] Preparing test output structure..."
rm -rf ./processed-test
mkdir -p ./processed-test/preset-repo/settings-master
mkdir -p ./processed-test/repository/vendors

cp ArchiveRepositoryManifest.json ./processed-test/preset-repo/
cp CaribouSlicer.version ./processed-test/

echo "[INFO] Processing caribou-fff for preset-repo..."
src="$download_dir/caribou-fff"
for vendor_dir in "$src"/*/; do
    vendor_name=$(basename "$vendor_dir")
    target_dir="./processed-test/preset-repo/settings-master/$vendor_name"
    rm -rf "$target_dir"
    cp -r "$vendor_dir" "$target_dir"
    find "$target_dir" -type f -name "*.ini" -exec rm -f {} +
done

cp -r "$src" ./processed-test/preset-repo/
for ini_file in ./processed-test/preset-repo/caribou-fff/*/*.ini; do
    vendor_name=$(basename $(dirname "$ini_file"))
    sed -i 's|config_update_url = .*|config_update_url = https://caribou3d.com/CaribouSlicer/preset-repo/settings-master/'"$vendor_name"'/|g' "$ini_file"
    sed -i 's|^[#[:space:]]*changelog_url[[:space:]]*=.*|# changelog_url =|g' "$ini_file"
    sed -i 's|files.prusa3d.com/wp-content/uploads/repository/PrusaSlicer-settings-master/live/|caribou3d.com/CaribouSlicer/repository/vendors/|g' "$ini_file"
    sed -i 's/ PrusaSlicer/ CaribouSlicer/g' "$ini_file"
done

# Zip .idx files in preset-repo/caribou-fff and delete them
if find ./processed-test/preset-repo/caribou-fff -maxdepth 1 -name "*.idx" | grep -q "."; then
    echo "[INFO] Zipping vendor_indices.zip in preset-repo/caribou-fff"
    pushd ./processed-test/preset-repo/caribou-fff > /dev/null
    zip -o vendor_indices.zip *.idx
    rm -f *.idx
    popd > /dev/null
fi

echo "[INFO] Populating test repository..."
for src in "$download_dir/caribou-fff" "$download_dir/non-caribou-fff" "$download_dir/non-caribou-sla"; do
    cp -r "$src"/* ./processed-test/repository/vendors/
done

find ./processed-test/repository/vendors -type f -name "*.ini" | while read -r ini_file; do
    vendor_name=$(basename "$(dirname "$ini_file")")
    sed -i 's|config_update_url = .*|config_update_url = https://caribou3d.com/CaribouSlicer/preset-repo/settings-master/'"$vendor_name"'/|g' "$ini_file"
    sed -i 's|^[#[:space:]]*changelog_url[[:space:]]*=.*|# changelog_url =|g' "$ini_file"
    sed -i 's|files.prusa3d.com/wp-content/uploads/repository/PrusaSlicer-settings-master/live/|caribou3d.com/CaribouSlicer/repository/vendors/|g' "$ini_file"
    sed -i 's/ PrusaSlicer/ CaribouSlicer/g' "$ini_file"
    sed -i 's/non-prusa-fff/non-caribou-fff/g' "$ini_file"
    sed -i 's/prusa-fff/non-caribou-fff/g' "$ini_file"
    sed -i 's/non-prusa-sla/non-caribou-sla/g' "$ini_file"
    sed -i 's/prusa-sla/non-caribou-sla/g' "$ini_file"
done

echo "[INFO] Creating top-level .ini files from versioned entries..."
for idx_file in ./processed-test/repository/vendors/*.idx; do
    vendor_name=$(basename "$idx_file" .idx)
    version=$(awk 'NR==2 {print $1; exit}' "$idx_file")
    ini_file="./processed-test/repository/vendors/$vendor_name/${version}.ini"
    target_ini="./processed-test/repository/vendors/$vendor_name.ini"
    if [[ -f "$ini_file" ]]; then
        cp "$ini_file" "$target_ini"
    else
        echo "Warning: $ini_file not found for $vendor_name"
    fi
done

# Also copy top-level Caribou.ini if exists in subfolder
if [[ -f ./processed-test/repository/vendors/Caribou/${version}.ini ]]; then
    cp ./processed-test/repository/vendors/Caribou/${version}.ini ./processed-test/repository/vendors/Caribou.ini
fi

pushd ./processed-test/repository/vendors > /dev/null
zip -o vendor_indices.zip *.idx
mv vendor_indices.zip ../
popd > /dev/null

# Clean non-Caribou top-level .ini/.idx and folders
find ./processed-test/repository/vendors -maxdepth 1 -mindepth 1 -type d ! -name 'Caribou*' -exec rm -rf {} +
find ./processed-test/repository/vendors -maxdepth 1 -type f -name "*.ini" ! -name 'Caribou.ini' -exec rm -f {} +
find ./processed-test/repository/vendors -maxdepth 1 -type f -name "*.idx" ! -name 'Caribou.idx' -exec rm -f {} +

echo "✅ Test vendor setup complete: processed-test ready."
