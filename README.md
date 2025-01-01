Here is a `README.md` file for your project:

```markdown
# Database Management Automation Script

## Description
The automation script streamlines database management tasks with a menu-driven interface. It performs operations like stream setup, generating backup and baseline queries, checking environment and table space, verifying production refresh status, and converting fixed-length files to delimited files. It uses `bteq` commands for Teradata database interactions.

## Prerequisites
- Bash shell
- Teradata `bteq` utility

## Setup
1. Clone the repository.
2. Ensure the `bteq` utility is installed and accessible in your PATH.

## Usage
Run the `main.sh` script and follow the menu-driven interface to perform various database management tasks.

```shell
./main.sh
```

## Menu Options
1. **Stream Setup**: Set up a stream in the database.
2. **ERR Stream Setup**: Set up an ERR stream in the database.
3. **Generate Backup Queries**: Generate SQL queries for backing up tables.
4. **Generate Baseline Queries**: Generate SQL queries for baseline data.
5. **Check Environment Space**: Check the space usage of a database schema.
6. **Check Table Space**: Check the space usage of a specific table.
7. **Check Prod Refresh Request Status**: Check the status of a production refresh request.
8. **Check Prod Refresh Dates**: Check the refresh dates for production tables.
9. **Convert Fixed Length to Delimited File**: Convert a fixed-length file to a delimited file.
99. **Exit**: Exit the script.

## Input Files
- `input/backup.txt`: List of tables for backup.
- `input/baseline.csv`: CSV file with baseline data.
- `input/refreshed_tables.txt`: List of refreshed tables.
- `input/fixed_length_to_delimited.txt`: Configuration for file conversion.

## Output Files
- `output/teradata_log.txt`: Log file for Teradata operations.
- `output/backup_queries.sql`: Generated backup queries.
- `output/baseline_queries.sql`: Generated baseline queries.
- `output/prod_refresh_request_status.txt`: Production refresh request status.
- `output/prod_refresh_dates.txt`: Production refresh dates.


## Copyrights
This project is copyrighted by [Mullu Venkata Satyam].
```

This `README.md` provides an overview of the project, setup instructions, usage details, and information about input and output files.