#!/bin/bash
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
            exit 1
        else
            process_to_date=$(date -d "$process_from_date +6 days" +%Y%m%d)
        fi
        ;;
    M | m)
        if [ $(date -d "$process_from_date" +%d) -ne 01 ]; then
            echo -e "\nInvalid process from date. For monthly frequency, process from date should be the first day of the month\n"
            exit 1
        else
            process_to_date=$(date -d "$process_from_date +1 month -1 day" +%Y%m%d)
        fi
        ;;
    *)
        echo -e "\nInvalid frequency code\n"; exit 1 ;;
esac

# create temp file to store the exported data
stream_setup_file="$DB_USER"/output/stream_setup.txt
touch "$stream_setup_file"

bteq <<EOF &>> "$DB_USER"/output/teradata_log.txt
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
    echo -e "\nStream setup failed. Please check $DB_USER/output/teradata_log.txt\n"
fi

# remove the temp file
rm -f "$stream_setup_file"