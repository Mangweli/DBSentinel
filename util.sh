#!/bin/bash

# Function to handle errors
handle_error() {
    local ERROR_MESSAGE=$1
    local LOG_DIR=$2

    local CURRENT_DATE=$(date +"%F")
    local ERROR_LOG_FILE="${LOG_DIR}/${CURRENT_DATE}_error.log"

    echo "[$(date +"%F %T")]: ERROR: $ERROR_MESSAGE" >> "$ERROR_LOG_FILE"
    echo "$ERROR_MESSAGE" >&2
}

# Function to load .env file
load_env_file() {
    local ENV_FILE=$1
    local LOG_DIR=$2
    if [ -f "$ENV_FILE" ]; then
        while IFS='=' read -r key value; do
            if [[ ! $key =~ ^\s*# ]] && [[ $key ]] && [[ $value ]]; then
                export "$key"="$(echo $value | sed -e 's/^"//' -e 's/"$//')"
            fi
        done < "$ENV_FILE"
    else
        handle_error ".env file not found at : $ENV_FILE" "$LOG_DIR"
        exit 1
    fi
}

# Function to perform database backup
perform_backup() {
    local LOG_DIR=$1
    local BACKUP_DIR=$2
    local MYSQL_CNF_FILE=$3

    local TIMESTAMP=$(date +"%F_%H-%M-%S")
    local CURRENT_DATE=$(date +"%F")

    local LOG_FILE="${LOG_DIR}/${CURRENT_DATE}_log.log"
    local ERROR_LOG_FILE="${LOG_DIR}/${CURRENT_DATE}_error.log"

    echo "[$(date +"%F %T")]: INFO: Backup started" >> "$LOG_FILE"
    echo Backup Process started. This might take same time but all activities are logged in the log file. Please wait...

    # Get a list of all databases
    local DATABASES=$(mysql --defaults-extra-file="$MYSQL_CNF_FILE" -e "SHOW DATABASES;"  | grep -Ev "(Database|information_schema|performance_schema|mysql|sys)")

    if [ $? -ne 0 ]; then
        handle_error "Failed to retrieve list of databases"
        exit 1
    fi

    # Loop through the list of databases and back it up
    for DB in $DATABASES; do
        local FILENAME="${BACKUP_DIR}/${DB}_${TIMESTAMP}.sql"
        echo "[$(date +"%F %T")]: INFO: Started Backup of $DB" >> "$LOG_FILE"
        if mysqldump --defaults-extra-file="$MYSQL_CNF_FILE" --single-transaction --routines --triggers --events "$DB" > "$FILENAME"; then
            echo "[$(date +"%F %T")]: INFO: Database $DB backed up successfully to $FILENAME" >> "$LOG_FILE"
        else
            echo "[$(date +"%F %T")]: ERROR: Error backing up database $DB" >> "$LOG_FILE" >&2
        fi

        echo "[$(date +"%F %T")]: INFO: Backup Complete of $DB" >> "$LOG_FILE"

    done
    echo "[$(date +"%F %T")]: INFO: Backup Process completed" >> "$LOG_FILE"
    echo Backup Process Completed.
}