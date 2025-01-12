#!/bin/bash

read -p "Enter Schema: " schema

# create temp file to store the exported data
environment_space_file="$DB_USER"/output/environment_space.txt
touch "$environment_space_file"

bteq <<EOF &>> "$DB_USER"/output/teradata_log.txt
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
    echo -e "\nEnvironment space checking failed. Please check $DB_USER/output/teradata_log.txt\n"
fi

# remove the temp file
rm -f "$environment_space_file"