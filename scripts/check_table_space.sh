#!/bin/bash

read -p "Enter Schema: " schema
read -p "Enter Table Name: " table_name

# create temp file to store the exported data
table_space_file="$DB_USER"/output/table_space.txt
touch "$table_space_file"

bteq <<EOF &>> "$DB_USER"/output/teradata_log.txt
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
    echo -e "\nTable space checking failed. Please check $DB_USER/output/teradata_log.txt\n"
fi

# remove the temp file
rm -f "$table_space_file"