# DBSQL Sentinel

DB Sentinel is a script for automating the backup of MySQL databases. It handles the creation of backups, logging errors, and managing cron jobs for periodic execution.

## Project Structure

```plaintext
├── backup/
├── logs/
├── .mysql.cnf
├── .mysql.cnf.example
├── index.sh
├── util.sh
└── README.md
```

- `backup/`: Directory where database backups are stored.
- `logs/`: Directory where log files are stored.
- `.mysql.cnf`: MySQL configuration file (not included in the repository, create this file with your MySQL credentials).
- `.mysql.cnf.example`: Example MySQL configuration file.
- `index.sh`: Main script to execute the backup.
- `util.sh`: Utility functions used by the main script.
- `README.md`: Project documentation.

## Prerequisites

- MySQL client installed on the system.
- Proper MySQL credentials set up in `.mysql.cnf`.

## Setup

1. **Clone the repository**:

    ```sh
    git clone https://github.com/Mangweli/DBSentinel.git
    cd DBSentinel
    ```

2. **Create MySQL configuration file**:

    Copy `.mysql.cnf.example` to `.mysql.cnf` and fill in your MySQL credentials.

    ```sh
    cp .mysql.cnf.example .mysql.cnf
    ```

3. **Make scripts executable**:

    ```sh
    chmod +x index.sh util.sh
    ```

4. **Set up cron job**:

    The setup function automatically adds a cron job to run the backup script every 3 hours. You can adjust the cron schedule by modifying the `CRON_SCHEDULE` variable in the `setup` function of `util.sh`.

    ```bash
    setup() {
        # Other setup steps...
        local CRON_SCHEDULE="0 */3 * * *"  # Change this to adjust the schedule
        # Other setup steps...
    }
    ```

    Alternatively, you can manually set up the cron job by:
    
    Open crontab for editing:

    ```sh
    crontab -e
    ```

    Add the following line to schedule the backup script to run every 3 hours:

    ```
    0 */3 * * * /path/to/index.sh
    ```

    Save and exit the editor.

## Usage

To manually run the backup script, navigate to the project directory and execute:

```sh
./index.sh



