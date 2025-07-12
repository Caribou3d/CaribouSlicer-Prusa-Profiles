#!/bin/bash

set -e

echo "[INFO] Starting PrusaSlicer settings preparation..."

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
src_idx="$script_dir/caribou-fff/Caribou.idx"
dest_dir="$script_dir/PrusaSlicer-settings-non-prusa-fff"

# Clean and recreate destination directory
rm -rf "$dest_dir"
mkdir -p "$dest_dir"

# Copy Caribou.idx as index.idx
cp "$src_idx" "$dest_dir/index.idx"

# Extract version from second line
version=$(awk 'NR==2 {print $1; exit}' "$dest_dir/index.idx")
version_ini="$script_dir/caribou-fff/Caribou/${version}.ini"
dest_ini="$dest_dir/${version}.ini"

# Copy and patch version.ini
if [[ -f "$version_ini" ]]; then
    cp "$version_ini" "$dest_ini"

    # Apply replacements
    sed -i 's|repo_id = caribou-fff|repo_id = non-prusa-fff|g' "$dest_ini"
    sed -i 's|config_update_url = https://caribou3d.com/CaribouSlicer/preset-repo/settings-master/Caribou/|config_update_url = https://files.prusa3d.com/wp-content/uploads/repository/PrusaSlicer-settings-master/live/Caribou/|g' "$dest_ini"

    echo "[INFO] Patched and copied $version.ini to $dest_dir"
else
    echo "[ERROR] Version file $version_ini not found!"
    exit 1
fi

# Copy all .png, .stl, .svg assets
cp "$script_dir/caribou-fff/Caribou/"*.{png,stl,svg} "$dest_dir/" 2>/dev/null || true

echo "✅ Done: PrusaSlicer settings created at $dest_dir"
