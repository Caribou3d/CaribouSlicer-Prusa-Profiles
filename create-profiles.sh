#!/bin/bash

set -e

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
download_dir="$script_dir/download"

# Safety check: don't proceed if download directory is missing
if [ ! -d "$download_dir" ]; then
  echo  
  echo "Error: 'download' directory not found. Please run 'make download' first."
  echo
  exit 0
fi

# Remove existing processed directory if it exists
rm -rf ./processed

# Recreate base directory structure
mkdir -p ./processed/preset-repo/settings-master
mkdir -p ./processed/profiles
mkdir -p ./processed/repository/vendors

# List of source root folders from download
base_dir="./download"
sources=("$base_dir/caribou-fff" "$base_dir/non-caribou-fff" "$base_dir/non-caribou-sla")

# Destination for vendor settings
settings_dest="./processed/preset-repo/settings-master"
# Destination for full profiles
profiles_dest="./processed/profiles"
# Destination for repository vendors
repository_dest="./processed/repository/vendors"

# Copy manifest and version to preset-repo
cp ArchiveRepositoryManifest.json ./processed/preset-repo/
cp ArchiveRepositoryManifest.json ./processed/profiles/
cp CaribouSlicer.version ./processed/

# Loop over all source folders
for src in "${sources[@]}"; do
    # Copy vendor directories to settings-master (remove .ini files)
    for vendor_dir in "$src"/*/; do
        vendor_name=$(basename "$vendor_dir")
        target_dir="$settings_dest/$vendor_name"

        rm -rf "$target_dir"
        cp -r "$vendor_dir" "$target_dir"
        find "$target_dir" -type f -name "*.ini" -exec rm -f {} +
    done

    # Copy full contents to profiles directory
    cp -r "$src"/* "$profiles_dest"/
    # Copy full contents to repository/vendors directory
    cp -r "$src"/* "$repository_dest"/

    echo "Processed: $src"
done

# Copy versioned .ini files to profiles directory and rename
for idx_file in "$profiles_dest"/*.idx; do
    vendor_name=$(basename "$idx_file" .idx)
    version=$(awk 'NR==2 {print $1; exit}' "$idx_file")
    ini_file="$profiles_dest/$vendor_name/${version}.ini"

    if [[ -f "$ini_file" ]]; then
        sed -i 's|config_update_url = .*|config_update_url = https://caribou3d.com/CaribouSlicer/preset-repo/settings-master/'"$vendor_name"'/|g' "$ini_file"
        sed -i 's|^[#[:space:]]*changelog_url[[:space:]]*=.*|# changelog_url =|g' "$ini_file"
        sed -i 's|files.prusa3d.com/wp-content/uploads/repository/PrusaSlicer-settings-master/live/|caribou3d.com/CaribouSlicer/repository/vendors/|g' "$ini_file"
        sed -i 's/ PrusaSlicer/ CaribouSlicer/g' "$ini_file"

        cp "$ini_file" "$profiles_dest/$vendor_name.ini"
    else
        echo "Warning: $ini_file not found for $vendor_name"
    fi

done

# Remove all .ini files from vendor subdirectories in profiles
find "$profiles_dest"/*/ -type f -name "*.ini" -exec rm -f {} +

# Replace content in all top-level .ini files in profiles directory (order matters)
for ini_file in "$profiles_dest"/*.ini; do
    sed -i 's/non-prusa-fff/non-caribou-fff/g' "$ini_file"
    sed -i 's/prusa-fff/non-caribou-fff/g' "$ini_file"
    sed -i 's/non-prusa-sla/non-caribou-sla/g' "$ini_file"
    sed -i 's/prusa-sla/non-caribou-sla/g' "$ini_file"
done

# Copy full source directories again into processed/preset-repo/ and apply .ini changes
for src in "${sources[@]}"; do
    folder=$(basename "$src")
    cp -r "$src" ./processed/preset-repo/$folder
    for ini_file in ./processed/preset-repo/"$folder"/*/*.ini; do
        vendor_name=$(basename $(dirname "$ini_file"))
        sed -i 's|config_update_url = .*|config_update_url = https://caribou3d.com/CaribouSlicer/preset-repo/settings-master/'"$vendor_name"'/|g' "$ini_file"
        sed -i 's|^[#[:space:]]*changelog_url[[:space:]]*=.*|# changelog_url =|g' "$ini_file"
        sed -i 's|files.prusa3d.com/wp-content/uploads/repository/PrusaSlicer-settings-master/live/|caribou3d.com/CaribouSlicer/repository/vendors/|g' "$ini_file"
        sed -i 's/ PrusaSlicer/ CaribouSlicer/g' "$ini_file"
    done
    echo "Updated .ini files in ./processed/preset-repo/$folder"

    # Zip .idx files and keep the zip file
    dir_path="./processed/preset-repo/$folder"
    echo "Zipping in: $dir_path"
    if find "$dir_path" -maxdepth 1 -name "*.idx" | grep -q "."; then
        pushd "$dir_path" > /dev/null || continue
        zip -o vendor_indices.zip *.idx
        rm -f *.idx
        echo "Zipped and removed .idx files in $dir_path"
        popd > /dev/null
    else
        echo "No .idx files found in $dir_path"
    fi

    # Clean non-ini and non-zip files from vendor folders after zipping idx files
    find ./processed/preset-repo/"$folder"/* -type f ! \( -name "*.ini" -o -name "vendor_indices.zip" \) -exec rm -f {} +
done

# Replace identifiers and URLs in all .ini files in repository/vendors (before copying Vendor.ini)
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

# Copy processed and replaced versioned ini to Vendor.ini
for idx_file in "$repository_dest"/*.idx; do
    vendor_name=$(basename "$idx_file" .idx)
    version=$(awk 'NR==2 {print $1; exit}' "$idx_file")
    ini_file="$repository_dest/$vendor_name/${version}.ini"
    target_ini="$repository_dest/$vendor_name.ini"

    if [[ -f "$ini_file" ]]; then
        cp "$ini_file" "$target_ini"
    else
        echo "Warning: $ini_file not found for $vendor_name"
    fi
done

# Zip all .idx files into vendor_indices.zip and move to repository (keep idx files)
pushd "$repository_dest" > /dev/null
zip -o vendor_indices.zip *.idx
mv vendor_indices.zip ../
popd > /dev/null

echo "All vendor directories processed with updated structure, ini replacements applied, .idx zipped, and content organized in processed/preset-repo, processed/profiles, and processed/repository/vendors."
