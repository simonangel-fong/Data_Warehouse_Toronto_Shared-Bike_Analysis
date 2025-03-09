#!/bin/bash

# Script Name: ETL.sh
# Creator: Wenhao Fang
# This script:

# Load parameters
source ./parameters.sh

# Check if a parameter was provided
if [ -z "$1" ]; then
    echo "Lack of url parameter."
    # exit 1
else
    echo "Url $1"

    # clear up
    rm -r $DOWNLOAD_BASE_PATH/*
    rm -r $LOAD_BASE_PATH/*

    log_message "Downloading csv file from url $1..."
    # Download the file to download dir
    # wget -O "$JOB_FILE_ZIP" "$JOB_URL"
    curl -o "$DOWNLOAD_BASE_PATH/data.zip" "$1"
    log_message "Download csv file completed."

    unzip "$DOWNLOAD_BASE_PATH/data.zip" -d "$LOAD_BASE_PATH"
    log_message "Unzip downloaded file."

    find "$LOAD_BASE_PATH" -type f -name "*.csv" -exec mv {} "$LOAD_BASE_PATH" \;

    log_message "Download job completed."
fi
