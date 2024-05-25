#!/bin/bash

# Load .env file

# Function to handle errors
handle_error() {
    local TIMESTAMP=$(date +"%F_%H-%M-%S")
    local ERROR_MESSAGE=$1
    echo "$TIMESTAMP: ERROR: $ERROR_MESSAGE" >> "$ERROR_LOG_FILE"
    echo "$ERROR_MESSAGE" >&2
}

# Function to perform database backup
perform_backup() {
    local TIMESTAMP=$(date +"%F_%H-%M-%S")
    local CURRENT_DATE=$(date +"%F")

    local LOG_FILE="${LOG_DIR}/${CURRENT_DATE}_log.log"
    local ERROR_LOG_FILE="${LOG_DIR}/${CURRENT_DATE}_error.log"

    echo "$TIMESTAMP: INFO: Backup started" >> "$LOG_FILE"

    # Get a list of all databases
    local DATABASES=$(mysql --defaults-extra-file="$MYSQL_CNF_FILE" -e "SHOW DATABASES;"  | grep -Ev "(Database|information_schema|performance_schema|mysql|sys)")

    if [ $? -ne 0 ]; then
        handle_error "Failed to retrieve list of databases"
        exit 1
    fi

    # Loop through the list of databases and back it up
    for DB in $DATABASES; do
        local FILENAME="${BACKUP_DIR}/${DB}_${TIMESTAMP}.sql"
        echo "$TIMESTAMP: INFO: Started Backup of $DB" >> "$LOG_FILE"
        if mysqldump --defaults-extra-file="$MYSQL_CNF_FILE" --single-transaction --routines --triggers --events "$DB" > "$FILENAME"; then
            echo "[$(date +"%F %T")] Database $DB backed up successfully to $FILENAME" >> "$LOG_FILE"
        else
            echo "[$(date +"%F %T")] Error backing up database $DB" >> "$LOG_FILE" >&2
        fi

        echo "$TIMESTAMP: INFO: Backup Complete of $DB" >> "$LOG_FILE"

    done
    echo "$TIMESTAMP: INFO: Backup Process completed" >> "$LOG_FILE"
}

# Load .env file
ENV_FILE="$(dirname "$0")/.env"
if [ -f $ENV_FILE ]; then
    export $(grep -v '^#' $ENV_FILE | xargs)
else
    handle_error ".env file not found!"
    exit 1
fi

# Ensure .cnf file exists
if [ ! -f "$MYSQL_CNF_FILE" ]; then
    handle_error "MySQL .cnf file not found at $MYSQL_CNF_FILE"
    exit 1
fi

# Check if the environment variables are set
if [ -z "$MYSQL_CNF_FILE" ]; then
    handle_error "MYSQL_CNF_FILE parameter not set in .env file"
    exit 1
fi

# Define Log and Backup Directory
LOG_DIR="$(dirname "$0")/logs"
BACKUP_DIR="$(dirname "$0")/backup"

# Create log and backup directory if they doesn't exists
mkdir -p $LOG_DIR
mkdir -p $BACKUP_DIR

# Perform database backup
perform_backup

