#!/bin/bash

# Define parameters

export PROJECT_NAME="toronto_shared_bike"

export BASE_PATH="$HOME/$PROJECT_NAME"
export DOWNLOAD_BASE_PATH="$BASE_PATH/download"
export LOAD_BASE_PATH="$BASE_PATH/load"
export EXP_BASE_PATH="$BASE_PATH/exp"

export LOG_BASE_PATH="$BASE_PATH/log"
export LOG_FILE="logfile"
export LOG_FILE_PATH="$LOG_BASE_PATH/$LOG_FILE"

export ORCL_PATH="/u01/app/oracle/oradata/ORCL"
export PROJECT_ORCL_DATAFILE="$PROJECT_ORCL_PATH/users01.dbf"
export SEED_ORCL_PATH="$ORCL_PATH/pdbseed"
export PROJECT_ORCL_PATH="$ORCL_PATH/$PROJECT_NAME"

# Define a log function
log_message() {
    local message=$1
    local date_format=$(date +"%Y-%m-%d %H:%M:%S:")
    echo -e $date_format $message | tee -a $LOG_FILE_PATH
}
