#!/bin/bash

USER=$(whoami)
read -p "Enter your password: " -s PASSWORD
echo -e "\n"

echo "Welcome $USER"

stream_setup() {
    # Add your stream setup logic here
    read -p "Enter Schema: " schema
    read -p "Enter Stream Code (XYZ): " stream_code
    read -p "Enter Frequency Code (D/W/M): " frequency_code
    read -p "Enter Process From Date (YYYYMMDD): " process_from_date

    case $frequency_code in
        D | d)
            process_to_date=$(date -d "$process_from_date +0 days" +%Y%m%d)
            ;;
        W | w)
            if [ $(date -d "$process_from_date" +%u) -ne 6 ]; then
                echo -e "\nInvalid process from date. For weekly frequency, process from date should be a Saturday\n"
                return
            else
                process_to_date=$(date -d "$process_from_date +6 days" +%Y%m%d)
            fi
            ;;
        M | m)
            if [ $(date -d "$process_from_date" +%d) -ne 01 ]; then
                echo -e "\nInvalid process from date. For monthly frequency, process from date should be the first day of the month\n"
                return
            else
                process_to_date=$(date -d "$process_from_date +1 month -1 day" +%Y%m%d)
            fi
            ;;
        *)
            echo -e "\nInvalid frequency code\n"; return ;;
    esac

    # create temp file to store the exported data
    stream_setup_file="$USER"/output/stream_setup.txt
    touch "$stream_setup_file"

    bteq <<EOF &>> "$USER"/output/teradata_log.txt
    .LOGON $DB_HOST/$DB_USER,$DB_PASSWORD;
    .SET WIDTH 200;
    DELETE FROM $schema.MD_Stream_Log_EDW WHERE stream_code = '$stream_code';
    INSERT INTO $schema.MD_Stream_Log_EDW VALUES ('$stream_code', 'L', 'R', CAST('$process_from_date' AS DATE FORMAT 'YYYYMMDD'), CAST('$process_to_date' AS DATE FORMAT 'YYYYMMDD'), '1', '$frequency_code', CURRENT_DATE, CURRENT_TIMESTAMP);
    .EXPORT REPORT FILE=$stream_setup_file;
    SELECT * FROM $schema.MD_Stream_Log_EDW WHERE stream_code = '$stream_code';
    .EXPORT RESET;
    .LOGOFF;
    .QUIT;
EOF

    if [ $? -eq 0 ]; then
        echo -e "\nStream setup is successful\n"
        cat "$stream_setup_file"
        echo -e "\n"
    else
        echo -e "\nStream setup failed. Please check $USER/output/teradata_log.txt\n"
    fi

    # remove the temp file
    rm -f "$stream_setup_file"
}

err_stream_setup() {
    # Add your ERR stream setup logic here
    read -p "Enter Schema: " schema
    read -p "Enter Stream Code (XYZ): " stream_code
    read -p "Enter Frequency Code (D/W/M): " frequency_code
    read -p "Enter Process From Date (YYYYMMDD): " process_from_date

    case $frequency_code in
        D | d)
            prev_process_from_date=$(date -d "$process_from_date -1 days" +%Y%m%d)
            prev_process_to_date=$(date -d "$process_from_date -1 days" +%Y%m%d)
            process_to_date=$(date -d "$process_from_date +0 days" +%Y%m%d)
            ;;
        W | w)
            if [ $(date -d "$process_from_date" +%u) -ne 6 ]; then
                echo -e "\nInvalid process from date. For weekly frequency, process from date should be a Saturday\n"
                return
            else
                prev_process_from_date=$(date -d "$process_from_date -7 days" +%Y%m%d)
                prev_process_to_date=$(date -d "$process_from_date -1 days" +%Y%m%d)
                process_to_date=$(date -d "$process_from_date +6 days" +%Y%m%d)
            fi
            ;;
        M | m)
            if [ $(date -d "$process_from_date" +%d) -ne 01 ]; then
                echo -e "\nInvalid process from date. For monthly frequency, process from date should be the first day of the month\n"
                return
            else
                prev_process_from_date=$(date -d "$process_from_date -1 month" +%Y%m%d)
                prev_process_to_date=$(date -d "$process_from_date -1 day" +%Y%m%d)
                process_to_date=$(date -d "$process_from_date +1 month -1 day" +%Y%m%d)
            fi
            ;;
        *)
            echo -e "\nInvalid frequency code\n"; return ;;
    esac

    # create temp file to store the exported data
    err_stream_setup_file="$USER"/output/err_stream_setup.txt
    touch "$err_stream_setup_file"

    bteq <<EOF &>> "$USER"/output/teradata_log.txt
    .LOGON $DB_HOST/$DB_USER,$DB_PASSWORD;
    .SET WIDTH 200;
    DELETE FROM $schema.MD_Stream_Log WHERE stream_code = '$stream_code';
    INSERT INTO $schema.MD_Stream_Log VALUES ('$stream_code', 'E', 'R', CAST('$prev_process_from_date' AS DATE FORMAT 'YYYYMMDD'), CAST('$prev_process_to_date' AS DATE FORMAT 'YYYYMMDD'), '1', '$frequency_code', CURRENT_DATE, CURRENT_TIMESTAMP);
    INSERT INTO $schema.MD_Stream_Log VALUES ('$stream_code', 'E', 'I', CAST('$prev_process_from_date' AS DATE FORMAT 'YYYYMMDD'), CAST('$prev_process_to_date' AS DATE FORMAT 'YYYYMMDD'), '1', '$frequency_code', CURRENT_DATE, CURRENT_TIMESTAMP);
    INSERT INTO $schema.MD_Stream_Log VALUES ('$stream_code', 'E', 'C', CAST('$prev_process_from_date' AS DATE FORMAT 'YYYYMMDD'), CAST('$prev_process_to_date' AS DATE FORMAT 'YYYYMMDD'), '1', '$frequency_code', CURRENT_DATE, CURRENT_TIMESTAMP);
    INSERT INTO $schema.MD_Stream_Log VALUES ('$stream_code', 'L', 'R', CAST('$prev_process_from_date' AS DATE FORMAT 'YYYYMMDD'), CAST('$prev_process_to_date' AS DATE FORMAT 'YYYYMMDD'), '1', '$frequency_code', CURRENT_DATE, CURRENT_TIMESTAMP);
    INSERT INTO $schema.MD_Stream_Log VALUES ('$stream_code', 'L', 'I', CAST('$prev_process_from_date' AS DATE FORMAT 'YYYYMMDD'), CAST('$prev_process_to_date' AS DATE FORMAT 'YYYYMMDD'), '1', '$frequency_code', CURRENT_DATE, CURRENT_TIMESTAMP);
    INSERT INTO $schema.MD_Stream_Log VALUES ('$stream_code', 'L', 'C', CAST('$prev_process_from_date' AS DATE FORMAT 'YYYYMMDD'), CAST('$prev_process_to_date' AS DATE FORMAT 'YYYYMMDD'), '1', '$frequency_code', CURRENT_DATE, CURRENT_TIMESTAMP);
    INSERT INTO $schema.MD_Stream_Log VALUES ('$stream_code', 'E', 'R', CAST('$process_from_date' AS DATE FORMAT 'YYYYMMDD'), CAST('$process_to_date' AS DATE FORMAT 'YYYYMMDD'), '1', '$frequency_code', CURRENT_DATE, CURRENT_TIMESTAMP);
    INSERT INTO $schema.MD_Stream_Log VALUES ('$stream_code', 'L', 'R', CAST('$process_from_date' AS DATE FORMAT 'YYYYMMDD'), CAST('$process_to_date' AS DATE FORMAT 'YYYYMMDD'), '1', '$frequency_code', CURRENT_DATE, CURRENT_TIMESTAMP);
    .EXPORT REPORT FILE=$err_stream_setup_file;
    SELECT * FROM $schema.MD_Stream_Log WHERE stream_code = '$stream_code';
    .EXPORT RESET;
    .LOGOFF;
    .QUIT;
EOF
    if [ $? -eq 0 ]; then
        echo -e "\nERR Stream setup is successful\n"
        cat "$err_stream_setup_file"
        echo -e "\n"
    else
        echo -e "\nERR Stream setup failed. Please check $USER/output/teradata_log.txt\n"
    fi

    # remove the temp file
    rm -f "$err_stream_setup_file"
}

generate_backup_queries() {
    # Add your backup queries generation logic here

    file_size=$(stat -c %s "$USER"/input/backup.txt)

    if [ $file_size -gt 0 ]; then
        read -p "Enter Source Schema: " source_schema
        read -p "Enter Target Schema: " target_schema
        read -p "Enter View Schema: " view_schema
        read -p "Enter Backup Name: " backup_name
        read -p "Delete Data From Target Table? (Y/N): " delete_data

        # generate create table and view queries
        {
            echo "-- Step1"
            awk -v source_schema="$source_schema" -v target_schema="$target_schema" -v backup_name="$backup_name" -v delete_data="$delete_data" '{
                print "create table " target_schema "." $0 "_" backup_name " as " source_schema "." $0 " with data;"
            }' "$USER"/input/backup.txt

            echo -e "\n-- Step2"
            awk -v source_schema="$source_schema" -v target_schema="$target_schema" -v backup_name="$backup_name" -v view_schema="$view_schema" '{
                print "create view " view_schema "." $0 "_" backup_name " as locking " target_schema "." $0 "_" backup_name " for access select * from " target_schema "." $0 "_" backup_name ";"
            }' "$USER"/input/backup.txt
        } > "$USER"/output/backup_queries.sql

        if [ "$delete_data" == "Y" ] || [ "$delete_data" == "y" ]; then
            # Add delete queries to the backup_queries.sql file
            {
                echo -e "\n-- Step3"
                awk -v target_schema="$target_schema" -v backup_name="$backup_name" '{
                    print "delete from " target_schema "." $0 ";"
                }' "$USER"/input/backup.txt
            } >> "$USER"/output/backup_queries.sql
        fi

        echo -e "\nBackup queries generation is successful. Please check $USER/output/backup_queries.sql\n"
    else
        echo -e "\nFile is empty. Please insert tables into $USER/input/backup.txt\n"
    fi
}

generate_baseline_queries() {
    # Add your baseline queries generation logic here
    file_size=$(stat -c %s "$USER"/input/baseline.csv)

    if [ $file_size -gt 0 ]; then
        read -p "Enter Schema: " schema
        read -p "Enter Process Date (YYYYMMDD): " process_date

        # generate baseline queries
        {

            awk -F "," -v schema="$schema" -v process_date="$process_date" -v q="'" '{
                if (NR > 1) {
                    if ($2 == "from_date") {
                        print "delete from " schema "." $1 " where " $2 " >= cast(" q process_date q " as date format " q "YYYYMMDD" q ");"
                        print "update " schema "." $1 " set to_date = cast(" q "29991231" q " as date format " q "YYYYMMDD" q ") where to_date >= cast(" q process_date q " as date format " q "YYYYMMDD" q ")-1;"
                        printf "\n"
                    } else {
                        print "delete from " schema "." $1 " where " $2 " >= cast(" q process_date q " as date format " q "YYYYMMDD" q ");"
                        printf "\n"
                    }
                }
            }' "$USER"/input/baseline.csv

        } > "$USER"/output/baseline_queries.sql

        echo -e "\nBaseline queries generation is successful. Please check $USER/output/baseline_queries.sql\n"
    else
        echo -e "\nFile is empty. Please insert values into $USER/input/baseline.csv\n"
    fi
}

check_environment_space() {
    # Add your environment space checking logic here
    read -p "Enter Schema: " schema

    # create temp file to store the exported data
    environment_space_file="$USER"/output/environment_space.txt
    touch "$environment_space_file"

    bteq <<EOF &>> "$USER"/output/teradata_log.txt
    .LOGON $DB_HOST/$DB_USER,$DB_PASSWORD;
    .SET WIDTH 200;
    .EXPORT REPORT FILE=$environment_space_file;
    SELECT
        DatabaseName,
        SUM(CurrentPerm) AS CurrentPerm,
        SUM(MaxPerm) AS MaxPerm,
        SUM(CurrentPerm) / 1024 ** 3 AS UsedSpaceGB,
        SUM(MaxPerm) / 1024 ** 3 AS MaxSpaceGB,
        UsedSpaceGB - MaxSpaceGB AS RemainingSpaceGB
    FROM DBC.DiskSpaceV
    WHERE DatabaseName = '$schema'
    GROUP BY 1;
    .EXPORT RESET;
    .LOGOFF;
    .QUIT;
EOF

    if [ $? -eq 0 ]; then
        echo -e "\nEnvironment space checking is successful\n"
        cat "$environment_space_file"
        echo -e "\n"
    else
        echo -e "\nEnvironment space checking failed. Please check $USER/output/teradata_log.txt\n"
    fi

    # remove the temp file
    rm -f "$environment_space_file"
}

check_table_space() {
    # Add your table space checking logic here
    read -p "Enter Schema: " schema
    read -p "Enter Table Name: " table_name

    # create temp file to store the exported data
    table_space_file="$USER"/output/table_space.txt
    touch "$table_space_file"

    bteq <<EOF &>> "$USER"/output/teradata_log.txt
    .LOGON $DB_HOST/$DB_USER,$DB_PASSWORD;
    .SET WIDTH 200;
    .EXPORT REPORT FILE=$table_space_file;
    SELECT
        DatabaseName,
        TableName,
        SUM(CurrentPerm) / 1024 ** 2 AS CurrentSpaceMB,
        SUM(CurrentPerm) / 1024 ** 3 AS CurrentSpaceGB
    FROM DBC.TableSize
    WHERE DatabaseName = '$schema' AND TableName = '$table_name'
    GROUP BY 1, 2;
    .EXPORT RESET;
    .LOGOFF;
    .QUIT;
EOF

    if [ $? -eq 0 ]; then
        echo -e "\nTable space checking is successful\n"
        cat "$table_space_file"
        echo -e "\n"
    else
        echo -e "\nTable space checking failed. Please check $USER/output/teradata_log.txt\n"
    fi
}

check_prod_refresh_request_status() {
    # Add your production refresh request status checking logic here
    read -p "Enter Reference Number: " ref_number

    # create file to store the exported data
    prod_refresh_request_status_file="$USER"/output/prod_refresh_request_status.txt
    touch "$prod_refresh_request_status_file"

    bteq <<EOF &>> "$USER"/output/teradata_log.txt
    .LOGON $DB_HOST/$DB_USER,$DB_PASSWORD;
    .SET WIDTH 200;
    .EXPORT REPORT FILE=$prod_refresh_request_status_file;
    SELECT Src_TableName, Latest_Status, DBA_Remark FROM PROD_REFRESH_REQUEST WHERE REF_NUMBER = '$ref_number';
    .EXPORT RESET;
    .LOGOFF;
    .QUIT;
EOF

    if [ $? -eq 0 ]; then
        echo -e "\nProduction refresh request status checking is successful\n"
        cat "$prod_refresh_request_status_file"
        echo -e "\n"
    else
        echo -e "\nProduction refresh request status checking failed. Please check $USER/output/teradata_log.txt\n"
    fi
}

check_prod_refresh_dates() {
    sh ./ProdRefreshChecker/xdw_refresh_checker.sh
}

convert_fixed_length_to_delimited_file() {
    # Add your file conversion logic here
    file_size=$(stat -c %s "$USER"/input/fixed_length_to_delimited.txt)

    if [ $file_size -gt 0 ]; then
        # read the input file and extract the values
        src_file=$(awk -F ':' '/src_file/ {print $2}' "$USER"/input/fixed_length_to_delimited.txt | tr -d '"')
        tgt_file=$(awk -F ':' '/tgt_file/ {print $2}' "$USER"/input/fixed_length_to_delimited.txt | tr -d '"')
        widths=$(awk -F ':' '/widths/ {print $2}' "$USER"/input/fixed_length_to_delimited.txt | tr -d '"')

        # validate any of the above values are empty
        if [ -z "$src_file" ] || [ -z "$tgt_file" ] || [ -z "$widths" ]; then
            echo -e "\nPlease provide values for src_file, tgt_file, and widths in the input file\n"
            return
        fi

        sh ./FixedToDelimitedConverter/converter.sh "$src_file" "$tgt_file" "$widths"

        if [ $? -eq 0 ]; then
            echo -e "\nFile conversion is successful. Please check $tgt_file\n"
        else
            echo -e "\nFile conversion failed\n"
        fi
    else
        echo -e "\nFile is empty. Please insert values into $USER/input/fixed_length_to_delimited.txt\n"
    fi
}

create_query_from_structure() {
    # Add your query generation logic here
    file_size=$(stat -c %s "$USER"/input/structure.txt)

    if [ $file_size -gt 0 ]; then
        read -p "Enter Schema: " schema
        read -p "Enter Table Name: " table_name

        awk -f ./PrepareSQL/sqlFromStructure.awk "$schema" "$table_name" < "$USER"/input/structure.txt > "$USER"/output/"$table_name".sql

        if [ $? -eq 0 ]; then
            echo -e "\nQuery generation is successful. Please check $USER/output/$table_name.sql\n"
        else
            echo -e "\nQuery generation failed\n"
        fi
    else
        echo -e "\nFile is empty. Please insert values into $USER/input/structure.txt\n"
    fi
}

main() {
    while true; do
        echo "1. Stream Setup"
        echo "2. ERR Stream Setup"
        echo "3. Generate Backup Queries"
        echo "4. Generate Baseline Queries"
        echo "5. Check Environment Space"
        echo "6. Check Table Space"
        echo "7. Check Prod Refresh Request Status"
        echo "8. Check Prod Refresh Dates"
        echo "9. Convert Fixed Length to Delimited File"
        echo "10. Create Query From Structure"
        echo "99. Exit"
        echo

        read -p "Enter your choice: " CHOICE

        case $CHOICE in
            1)
                stream_setup
                ;;
            2)
                err_stream_setup
                ;;
            3)
                generate_backup_queries
                ;;
            4)
                generate_baseline_queries
                ;;
            5)
                check_environment_space
                ;;
            6)
                check_table_space
                ;;
            7)
                check_prod_refresh_request_status
                ;;
            8)
                check_prod_refresh_dates
                ;;
            9)
                convert_fixed_length_to_delimited_file
                ;;
            99)
                break
                ;;
            10)
                create_query_from_structure
                ;;
            *)
                echo "Invalid choice"
                ;;
        esac
    done
}


if [ -d "$USER" ]; then
    echo -e "\nSet up is completed\n"
else
    mkdir -p "$USER"
    mkdir -p "$USER"/input
    mkdir -p "$USER"/output

    touch "$USER"/input/backup.txt
    #touch "$USER"/input/baseline.csv
    touch "$USER"/input/refreshed_tables.txt
    # touch "$USER"/input/fixed_length_to_delimited.txt
    touch "$USER"/output/teradata_log.txt
    touch $USER/input/structure.txt

    echo "table_name,column_name" > "$USER"/input/baseline.csv
    {
        echo 'src_file:""'
        echo 'tgt_file:""'
        echo 'widths:""'
    } > "$USER"/input/fixed_length_to_delimited.txt

    echo -e "\nSet up is completed\n"
fi

# Set environment variables
export DB_USER="$USER"
export DB_PASSWORD="$PASSWORD"
export DB_HOST="your_db_host"

main