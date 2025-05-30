#!/bin/bash

set -e

echo "[INFO] Starting offline profile packaging..."

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
download_dir="$script_dir/download"
offline_dir="$script_dir/processed/offline"

if [ ! -d "$download_dir" ]; then
  echo -e "\n[ERROR] 'download' directory not found. Please run 'make download' first.\n"
  exit 1
fi

echo "[INFO] Copying Caribou profiles ..."
rm -rf "$download_dir/caribou-fff"
cp -r "$script_dir/caribou-fff" "$download_dir/caribou-fff"

echo "[INFO] Preparing offline directory..."
rm -rf "$offline_dir"
mkdir -p "$offline_dir"

# Process non-caribou folders normally
folders=("non-caribou-fff" "non-caribou-sla")

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

for folder in "${folders[@]}"; do
  echo "[INFO] Processing: $folder"
  src_folder="$download_dir/$folder"
  dest_folder="$offline_dir/$folder"

  cp -r "$src_folder" "$dest_folder"

  echo "[INFO] Cleaning unnecessary files in: $dest_folder"
  rm -f "$dest_folder/vendor_indices.zip"
  rm -f "$dest_folder/manifest.json"

  echo "[INFO] Updating .ini files in: $folder"
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

  echo "[INFO] Creating vendor_indices.zip for: $folder"
  pushd "$dest_folder" > /dev/null
  if ls *.idx 1> /dev/null 2>&1; then
    zip -o vendor_indices.zip *.idx
    rm -f *.idx
  fi

  echo "[INFO] Writing manifest.json for: $folder"
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

  echo "[INFO] Zipping complete folder: $folder"
  zip_name="${folder}-offline.zip"
  zip -rq "../$zip_name" ./
  popd > /dev/null

done

# Special case for caribou-fff
folder="caribou-fff"
echo "[INFO] Processing: $folder (special case)"
src_folder="$download_dir/$folder"
dest_folder="$offline_dir/$folder"

cp -r "$src_folder" "$dest_folder"
rm -f "$dest_folder/vendor_indices.zip" "$dest_folder/manifest.json"

idx_file=$(find "$dest_folder" -type f -name "*.idx" | head -n 1)
vendor_name=$(basename "$idx_file" .idx)
version=$(awk 'NR==2 {print $1; exit}' "$idx_file")
ini_file="$download_dir/$folder/Caribou/$version.ini"
cp "$ini_file" "$(dirname "$idx_file")/Caribou.ini"

find "$dest_folder" -type f -name "*.ini" | while read -r ini_file; do
  vendor_dir=$(basename "$(dirname "$ini_file")")
  sed -i 's|config_update_url = .*|config_update_url = https://caribou3d.com/CaribouSlicer/preset-repo/settings-master/'"$vendor_dir"'/|g' "$ini_file"
  sed -i 's|^[#[:space:]]*changelog_url[[:space:]]*=.*|# changelog_url =|g' "$ini_file"
  sed -i 's|files.prusa3d.com/wp-content/uploads/repository/PrusaSlicer-settings-master/live/|caribou3d.com/CaribouSlicer/repository/vendors/|g' "$ini_file"
  sed -i 's/ PrusaSlicer/ CaribouSlicer/g' "$ini_file"
  sed -i 's/non-prusa-fff/non-caribou-fff/g' "$ini_file"
  sed -i 's/prusa-fff/non-caribou-fff/g' "$ini_file"
  sed -i 's/non-prusa-sla/non-caribou-sla/g' "$ini_file"
  sed -i 's/prusa-sla/non-caribou-sla/g' "$ini_file"
done

pushd "$dest_folder" > /dev/null
if ls *.idx 1> /dev/null 2>&1; then
  zip -o vendor_indices.zip *.idx Caribou.ini
  rm -f *.idx Caribou.ini
fi

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

zip_name="${folder}-offline.zip"
zip -rq "../$zip_name" ./
popd > /dev/null

echo "✅ Offline preset package ready in: $offline_dir"
