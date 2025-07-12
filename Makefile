# Default target: show help
.DEFAULT_GOAL := help

# Define the scripts
PROFILES_SCRIPT := ./create-profiles.sh
DOWNLOAD_SCRIPT := ./download.sh
OFFLINE_SCRIPT := ./create-offline.sh
TEST_SCRIPT := ./create-test.sh
PRUSA_SCRIPT := ./create-prusa.sh

# Targets
.PHONY: help profiles download offline clean all test prusa

help:
	@echo "Available targets:"
	@echo "  make download   - Run the download script to fetch and prepare files"
	@echo "  make profiles   - Run the script to generate profiles from downloaded content"
	@echo "  make offline    - Generate zipped offline profiles with manifests"
	@echo "  make test       - Run the test setup using caribou-fff-test into processed-test"
	@echo "  make prusa      - Create profiles for the PrusaSlicer"
	@echo "  make clean      - Delete 'processed', and 'processed-test' directories"
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

test:
	@echo "Running test profile creation script..."
	$(TEST_SCRIPT)

prusa:
	@echo "Creating Prusa-compatible settings..."
	$(PRUSA_SCRIPT)

clean:
	rm -rf download processed processed-test PrusaSlicer-settings-non-prusa-fff

all: download profiles offline prusa
