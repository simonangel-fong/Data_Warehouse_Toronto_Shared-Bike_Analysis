#!/bin/bash

# Script Name: init_dir.sh
# Creator: Wenhao Fang
# This script:
# Sets up the base directory structure for the shared-bike application, including
#     logging and download directories. It ensures that necessary directories are
#     created and initializes logging.

# Import parameters
source ./parameters.sh

######## Initialize direcotry ########

# Remove existing base dir
rm -rf "$BASE_PATH"

# Create directories
mkdir -p "$BASE_PATH"

mkdir -p "$LOG_BASE_PATH"
touch "$LOG_FILE_PATH"

mkdir -p "$DOWNLOAD_BASE_PATH"
mkdir -p "$LOAD_BASE_PATH"
mkdir -p "$EXP_BASE_PATH"

log_message "Directories have been created."
