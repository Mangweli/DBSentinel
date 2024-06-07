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
    echo "ENV FILE LOCATION: $ENV_FILE"
    echo "LOG DIR LOCATION: $LOG_DIR"
    if [ -f "$ENV_FILE" ]; then
        # export $(grep -v '^#' "$ENV_FILE" | xargs)
        set -a # Automatically export all variables
        source "$ENV_FILE"
        set +a # Stop automatically exporting variables
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

setup() {
    # Define Directories and files path
    export LOG_DIR="$(dirname "$0")/logs"
    export BACKUP_DIR="$(dirname "$0")/backup"
    
    local ENV_FILE="$(dirname "0")/.env"
    local UTIL_FILE="$(dirname "0")/util.sh"
    local SCRIPT_PATH="$(realpath "$0" 2>/dev/null || echo $(cd "$(dirname "$0")" && pwd)/$(basename "$0"))"
    local CRON_SCHEDULE="0 */3 * * *"

   # Create log and backup directory if they doesn't exists
    mkdir -p $LOG_DIR
    mkdir -p $BACKUP_DIR

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

    # Check if the cron job already exists and if the schedule is the same
    local CRON_JOB="$CRON_SCHEDULE $SCRIPT_PATH"
    local CURRENT_CRON=$(crontab -l 2>/dev/null | grep -F "$SCRIPT_PATH")

    local TIMESTAMP=$(date +"%F_%H-%M-%S")
    local CURRENT_DATE=$(date +"%F")
    local LOG_FILE="${LOG_DIR}/${CURRENT_DATE}_log.log"

    if [ -n "$CURRENT_CRON" ]; then
        # Check if the schedule is the same
        local CURRENT_SCHEDULE=$(echo "$CURRENT_CRON" | awk '{print $1, $2, $3, $4, $5}')
        if [ "$CRON_SCHEDULE" == "$CURRENT_SCHEDULE" ]; then
            echo "[$(date +"%F %T")]: INFO: Cron job already exists and schedule is the same" >> "$LOG_FILE"
        else
            # Remove the existing cron job with incorrect schedule
            (crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH") | crontab -
            echo "[$(date +"%F %T")]: INFO: Removed existing cron job with incorrect schedule" >> "$LOG_FILE"
            # Add the new cron job with the correct schedule
            (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
            if [ $? -eq 0 ]; then
                echo "[$(date +"%F %T")]: INFO: Cron job added successfully with correct schedule" >> "$LOG_FILE"
            else
                handle_error "Failed to add cron job with correct schedule" "$LOG_DIR"
                exit 1
            fi
        fi
    else
        # Add the cron job to the system if it doesn't exit
        (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
        if [ $? -eq 0 ]; then
            echo "[$(date +"%F %T")]: INFO: Cron job added successfully" >> "$LOG_FILE"
        else
            handle_error "Failed to add cron job" "$LOG_DIR"
            exit 1
        fi
    fi

    # Export variables for other scripts
    export LOG_DIR BACKUP_DIR 

}