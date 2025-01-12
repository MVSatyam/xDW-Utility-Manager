#!/bin/bash

file_size=$(stat -c %s "$DB_USER"/input/structure.txt)

if [ $file_size -gt 0 ]; then
    read -p "Enter Schema: " schema
    read -p "Enter Table Name: " table_name

    awk -f ./scripts/sqlFromStructure.awk "$schema" "$table_name" < "$DB_USER"/input/structure.txt > "$DB_USER"/output/"$table_name".sql

    if [ $? -eq 0 ]; then
        echo -e "\nQuery generation is successful. Please check $DB_USER/output/$table_name.sql\n"
    else
        echo -e "\nQuery generation failed\n"
    fi
else
    echo -e "\nFile is empty. Please insert values into $DB_USER/input/structure.txt\n"
fi