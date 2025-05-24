#!/bin/bash

set -e

# Create download directory relative to script location
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
download_dir="$script_dir/download"

# Fresh start
rm -rf "$download_dir"
mkdir -p "$download_dir"
cd "$download_dir"

# URLs to download
declare -A urls=(
  [prusa-fff]="https://storage.googleapis.com/prusa3d-content-prod-14e8-preset-repo-api-public/prusa-fff/prusa-fff-offline.zip"
  [prusa-sla]="https://storage.googleapis.com/prusa3d-content-prod-14e8-preset-repo-api-public/prusa-sla/prusa-sla-offline.zip"
  [non-prusa-fff]="https://storage.googleapis.com/prusa3d-content-prod-14e8-preset-repo-api-public/non-prusa-fff/non-prusa-fff-offline.zip"
  [non-prusa-sla]="https://storage.googleapis.com/prusa3d-content-prod-14e8-preset-repo-api-public/non-prusa-sla/non-prusa-sla-offline.zip"
)

# Download and unzip each file
for key in "${!urls[@]}"; do
  zip_file="${key}.zip"
  folder="${key}"

  echo "Downloading ${key}..."
  curl -L -o "$zip_file" "${urls[$key]}"

  echo "Extracting to $folder..."
  rm -rf "$folder"
  mkdir -p "$folder"
  unzip -q "$zip_file" -d "$folder"

  # Extract nested vendor_indices.zip if present
  if [[ -f "$folder/vendor_indices.zip" ]]; then
    unzip -q "$folder/vendor_indices.zip" -d "$folder"
  fi

  # Remove outer zip, inner zip, and manifest if present
  rm -f "$zip_file"
  rm -f "$folder/vendor_indices.zip"
  rm -f "$folder/manifest.json"
done

# Rename non-prusa folders
mv non-prusa-fff non-caribou-fff
mv non-prusa-sla non-caribou-sla

# Move prusa-* content into non-caribou-* folders
mv prusa-fff/* non-caribou-fff/
mv prusa-sla/* non-caribou-sla/
rm -rf prusa-fff prusa-sla


# Copy caribou-fff from script directory to download directory
cp -r "$script_dir/caribou-fff" "$download_dir/"

echo "Download and prep complete in: $download_dir"
