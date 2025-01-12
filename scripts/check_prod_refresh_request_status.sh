#!/bin/bash

read -p "Enter Reference Number: " ref_number

# create file to store the exported data
prod_refresh_request_status_file="$DB_USER"/output/prod_refresh_request_status.txt
touch "$prod_refresh_request_status_file"

bteq <<EOF &>> "$DB_USER"/output/teradata_log.txt
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
    echo -e "\nProduction refresh request status checking failed. Please check $DB_USER/output/teradata_log.txt\n"

    # remove the prod_refresh_request_status file
    rm -f "$prod_refresh_request_status_file"
fi