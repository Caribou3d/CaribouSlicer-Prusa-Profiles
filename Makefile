# Default target: show help
.DEFAULT_GOAL := help

# Define the scripts
PROFILES_SCRIPT := ./create-profiles.sh
DOWNLOAD_SCRIPT := ./download.sh
OFFLINE_SCRIPT := ./create-offline.sh

# Targets
.PHONY: help profiles download offline clean all

help:
	@echo "Available targets:"
	@echo "  make download   - Run the download script to fetch and prepare files"
	@echo "  make profiles   - Run the script to generate profiles from downloaded content"
	@echo "  make offline    - Generate zipped offline profiles with manifests"
	@echo "  make clean      - Delete 'download' and 'processed' directories"
	@echo "  make all        - Run download, profiles, and offline packaging"

profiles:
	@echo "Running profile creation script..."
	$(PROFILES_SCRIPT)

download:
	@echo "Running download script..."
	$(DOWNLOAD_SCRIPT)

offline:
	@echo "Generating offline profiles..."
	$(OFFLINE_SCRIPT)

clean:
	rm -rf download processed

all: download profiles offline
