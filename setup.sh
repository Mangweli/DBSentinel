#!/bin/bash

# Define Log and Backup Directory
LOG_DIR="$(dirname "$0")/logs"
BACKUP_DIR="$(dirname "$0")/backup"

# Create log and backup directory if they doesn't exists
mkdir -p $LOG_DIR

# Source Utility Functions
UTIL_FILE="$(dirname "0")/util.sh"
if [ -f "$UTIL_FILE" ]; then
    source "$UTIL_FILE"
else
    echo "[$(date +"%F %T")]: ERROR: util.sh file not found!"
    exit 1
fi

# Load .env file
ENV_FILE="$(dirname "0")/.env"
load_env_file "$ENV_FILE" "$LOG_DIR"

# Check of the required environments variables are set
if [ -z "$CRON_SCHEDULE" ] || [ -z "$SCRIPT_PATH" ]; then
    handle_error "CRON_SCHEDULE or SCRIPT_PATH not set in .env file" "$LOG_DIR"
    exit 1
fi

# Ensure SCRIPT_PATH points to an existing file
if [ ! -f "$SCRIPT_PATH" ]; then
    handle_error "SCRIPT_PATH not found at $SCRIPT_PATH" "$LOG_DIR"
    exit 1
fi

# Make the scripts executable
chmod +x "$SCRIPT_PATH"
chmod +x "$UTIL_FILE"

# Check if the cron job already exists
CRON_JOB="$CRON_SCHEDULE $SCRIPT_PATH"
CRON_EXITS=$(crontab -l | grep -F "$SCRIPT_PATH")

if [ -n "$CRON_EXITS" ]; then
    echo "[$(date +"%F %T")]: INFO: Cron job already exists"
else
    # Add the cron job to the crontab
    (crontab -l; echo "$CRON_JOB") | crontab -
    if [ $? -eq 0 ]; then
        echo "[$(date +"%F %T")]: INFO: Cron job added successfully"
    else
        handle_error "Failed to add cron job" "$LOG_DIR"
        exit 1
    fi
fi