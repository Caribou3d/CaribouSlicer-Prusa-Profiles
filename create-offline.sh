#!/bin/bash

set -e

# Determine script directory
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
download_dir="$script_dir/download"
offline_dir="$script_dir/processed/offline"

# Safety check
if [ ! -d "$download_dir" ]; then
  echo -e "\nError: 'download' directory not found. Please run 'make download' first.\n"
  exit 1
fi

# Clean and prepare offline directory
rm -rf "$offline_dir"
mkdir -p "$offline_dir"

# Define input folders
folders=("caribou-fff" "non-caribou-fff" "non-caribou-sla")

# Manifest entries map
declare -A names=(
  [caribou-fff]="Caribou FFF"
  [non-caribou-fff]="Non-Caribou FFF"
  [non-caribou-sla]="Non-Caribou SLA"
)
declare -A descriptions=(
  [caribou-fff]="Caribou FFF printer profiles"
  [non-caribou-fff]="Non-Caribou FFF printer profiles"
  [non-caribou-sla]="Non-Caribou SLA printer profiles"
)

# Copy folders into offline
for folder in "${folders[@]}"; do
  src_folder="$download_dir/$folder"
  dest_folder="$offline_dir/$folder"
  cp -r "$src_folder" "$dest_folder"

  # Remove unnecessary files
  rm -f "$dest_folder/vendor_indices.zip"
  rm -f "$dest_folder/manifest.json"

  # Replace URLs and identifiers in ini files
  find "$dest_folder" -type f -name "*.ini" | while read -r ini_file; do
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

  # Zip all .idx files into vendor_indices.zip and remove them
  pushd "$dest_folder" > /dev/null
  if ls *.idx 1> /dev/null 2>&1; then
    zip -o vendor_indices.zip *.idx
    rm -f *.idx
  fi

  # Write manifest.json for this folder
  cat > "manifest.json" <<EOF
{
  "name": "${names[$folder]}",
  "description": "${descriptions[$folder]}",
  "visibility": "",
  "id": "$folder",
  "url": "https://caribou3d.com/CaribouSlicer/preset-repo/$folder",
  "index_url": "https://caribou3d.com/CaribouSlicer/preset-repo/$folder/vendor_indices.zip",
  "offline_archive_url": "https://caribou3d.com/CaribouSlicer/Releases/00_Offline-Profiles/${folder}-offline.zip"
}
EOF

  # Zip entire folder content and move one level up
  zip_name="${folder}-offline.zip"
  zip -rq "../$zip_name" ./*
  popd > /dev/null

done

echo "Offline preset package ready in: $offline_dir"
