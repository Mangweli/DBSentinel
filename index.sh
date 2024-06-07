#!/bin/bash

# Source utility functions
UTIL_FILE="$(dirname "$0")/util.sh"
if [ -f $UTIL_FILE ]; then
    source $UTIL_FILE
else
    echo "[$(date +"%F %T")]: ERROR: util.sh file not found!"
    exit 1
fi

# Call the setup function
setup

MYSQL_CNF_FILE="$(dirname "$0")/.mysql.cnf"

# Create log and backup directory if they doesn't exists
mkdir -p $LOG_DIR
mkdir -p $BACKUP_DIR

# Load env file
# ENV_FILE="$(dirname "$0")/.env";
# load_env_file "$ENV_FILE" "$LOG_DIR"

# Ensure .cnf file exists
if [ ! -f "$MYSQL_CNF_FILE" ]; then
    handle_error "MySQL .cnf file not found at $MYSQL_CNF_FILE" $LOG_DIR
    exit 1
fi

# Perform database backup
perform_backup "$LOG_DIR" "$BACKUP_DIR" "$MYSQL_CNF_FILE"