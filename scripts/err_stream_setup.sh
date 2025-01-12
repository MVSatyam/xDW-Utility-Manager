#!/bin/bash

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
            exit 1
        else
            prev_process_from_date=$(date -d "$process_from_date -7 days" +%Y%m%d)
            prev_process_to_date=$(date -d "$process_from_date -1 days" +%Y%m%d)
            process_to_date=$(date -d "$process_from_date +6 days" +%Y%m%d)
        fi
        ;;
    M | m)
        if [ $(date -d "$process_from_date" +%d) -ne 01 ]; then
            echo -e "\nInvalid process from date. For monthly frequency, process from date should be the first day of the month\n"
            exit 1
        else
            prev_process_from_date=$(date -d "$process_from_date -1 month" +%Y%m%d)
            prev_process_to_date=$(date -d "$process_from_date -1 day" +%Y%m%d)
            process_to_date=$(date -d "$process_from_date +1 month -1 day" +%Y%m%d)
        fi
        ;;
    *)
        echo -e "\nInvalid frequency code\n"; exit 1 ;;
esac

# create temp file to store the exported data
err_stream_setup_file="$DB_USER"/output/err_stream_setup.txt
touch "$err_stream_setup_file"

bteq <<EOF &>> "$DB_USER"/output/teradata_log.txt
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
    echo -e "\nERR Stream setup failed. Please check $DB_USER/output/teradata_log.txt\n"
fi

# remove the temp file
rm -f "$err_stream_setup_file"