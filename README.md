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

`backup/`: Directory where database backups are stored.
`logs/`: Directory where log files are stored.
`.mysql.cnf`: MySQL configuration file (not included in the repository, create this file with your MySQL credentials).
`.mysql.cnf.example`: Example MySQL configuration file.
`index.sh`: Main script to execute the backup.
`util.sh`: Utility functions used by the main script.
`README.md`: Project documentation.

Prerequisites

MySQL client installed on the system.
Proper MySQL credentials set up in `.mysql.cnf.`

Setup
Clone the repository:


