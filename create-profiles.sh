#!/bin/bash

set -e

echo "[INFO] Starting full profile creation..."

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
download_dir="$script_dir/download"

if [ ! -d "$download_dir" ]; then
  echo
  echo "Error: 'download' directory not found. Please run 'make download' first."
  echo
  exit 0
fi

echo "[INFO] Copying Caribou profiles ..."
rm -rf "$download_dir/caribou-fff"
cp -r "$script_dir/caribou-fff" "$download_dir/caribou-fff"

echo "[INFO] Cleaning old processed directory..."
rm -rf ./processed/upload
rm -rf ./processed/profiles

echo "[INFO] Creating directory structure..."
mkdir -p ./processed/upload/preset-repo/settings-master
mkdir -p ./processed/profiles
mkdir -p ./processed/upload/repository/vendors

base_dir="./download"
sources=("$base_dir/caribou-fff" "$base_dir/non-caribou-fff" "$base_dir/non-caribou-sla")

settings_dest="./processed/upload/preset-repo/settings-master"
profiles_dest="./processed/profiles"
repository_dest="./processed/upload/repository/vendors"

cp ArchiveRepositoryManifest.json ./processed/upload/preset-repo/
cp ArchiveRepositoryManifest.json ./processed/profiles/
cp CaribouSlicer.version ./processed/upload

for src in "${sources[@]}"; do
    echo "[INFO] Processing vendors from: $src"
    for vendor_dir in "$src"/*/; do
        vendor_name=$(basename "$vendor_dir")
        target_dir="$settings_dest/$vendor_name"

        rm -rf "$target_dir"
        cp -r "$vendor_dir" "$target_dir"
        find "$target_dir" -type f -name "*.ini" -exec rm -f {} +
    done

    cp -r "$src"/* "$profiles_dest"/
    cp -r "$src"/* "$repository_dest"/

    echo "[INFO] Done processing: $src"
done

for idx_file in "$profiles_dest"/*.idx; do
    vendor_name=$(basename "$idx_file" .idx)
    version=$(awk 'NR==2 {print $1; exit}' "$idx_file")
    ini_file="$profiles_dest/$vendor_name/${version}.ini"

    if [[ -f "$ini_file" ]]; then
        echo "[INFO] Generating top-level ini for: $vendor_name"
        sed -i 's|config_update_url = .*|config_update_url = https://caribou3d.com/CaribouSlicer/preset-repo/settings-master/'"$vendor_name"'/|g' "$ini_file"
        sed -i 's|^[#[:space:]]*changelog_url[[:space:]]*=.*|# changelog_url =|g' "$ini_file"
        sed -i 's|files.prusa3d.com/wp-content/uploads/repository/PrusaSlicer-settings-master/live/|caribou3d.com/CaribouSlicer/repository/vendors/|g' "$ini_file"
        sed -i 's/ PrusaSlicer/ CaribouSlicer/g' "$ini_file"

        cp "$ini_file" "$profiles_dest/$vendor_name.ini"
    else
        echo "Warning: $ini_file not found for $vendor_name"
    fi

done

find "$profiles_dest"/*/ -type f -name "*.ini" -exec rm -f {} +

for ini_file in "$profiles_dest"/*.ini; do
    sed -i 's/non-prusa-fff/non-caribou-fff/g' "$ini_file"
    sed -i 's/prusa-fff/non-caribou-fff/g' "$ini_file"
    sed -i 's/non-prusa-sla/non-caribou-sla/g' "$ini_file"
    sed -i 's/prusa-sla/non-caribou-sla/g' "$ini_file"
done

for src in "${sources[@]}"; do
    folder=$(basename "$src")
    cp -r "$src" ./processed/upload/preset-repo/$folder
    for ini_file in ./processed/upload/preset-repo/"$folder"/*/*.ini; do
        vendor_name=$(basename $(dirname "$ini_file"))
        sed -i 's|config_update_url = .*|config_update_url = https://caribou3d.com/CaribouSlicer/preset-repo/settings-master/'"$vendor_name"'/|g' "$ini_file"
        sed -i 's|^[#[:space:]]*changelog_url[[:space:]]*=.*|# changelog_url =|g' "$ini_file"
        sed -i 's|files.prusa3d.com/wp-content/uploads/repository/PrusaSlicer-settings-master/live/|caribou3d.com/CaribouSlicer/repository/vendors/|g' "$ini_file"
        sed -i 's/ PrusaSlicer/ CaribouSlicer/g' "$ini_file"
    done
    echo "[INFO] Updated .ini files in ./processed/upload/preset-repo/$folder"

    dir_path="./processed/upload/preset-repo/$folder"
    echo "[INFO] Zipping .idx files in: $dir_path"
    if find "$dir_path" -maxdepth 1 -name "*.idx" | grep -q "."; then
        pushd "$dir_path" > /dev/null || continue
        zip -o vendor_indices.zip *.idx
        rm -f *.idx
        echo "[INFO] Zipped and removed .idx files in $dir_path"
        popd > /dev/null
    else
        echo "[INFO] No .idx files found in $dir_path"
    fi

    find ./processed/upload/preset-repo/"$folder"/* -type f ! \( -name "*.ini" -o -name "vendor_indices.zip" \) -exec rm -f {} +
done

find "$repository_dest" -type f -name "*.ini" | while read -r ini_file; do
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

for idx_file in "$repository_dest"/*.idx; do
    vendor_name=$(basename "$idx_file" .idx)
    version=$(awk 'NR==2 {print $1; exit}' "$idx_file")
    ini_file="$repository_dest/$vendor_name/${version}.ini"
    target_ini="$repository_dest/$vendor_name.ini"

    if [[ -f "$ini_file" ]]; then
        echo "[INFO] Copying versioned ini for $vendor_name"
        cp "$ini_file" "$target_ini"
    else
        echo "Warning: $ini_file not found for $vendor_name"
    fi
done

pushd "$repository_dest" > /dev/null
zip -o vendor_indices.zip *.idx
mv vendor_indices.zip ../
popd > /dev/null

echo "✅ All vendor directories processed successfully."
