#!/bin/bash

file_size=$(stat -c %s "$DB_USER"/input/backup.txt)

if [ $file_size -gt 0 ]; then
    read -p "Enter Source Schema: " source_schema
    read -p "Enter Target Schema: " target_schema
    # read -p "Enter View Schema: " view_schema
    read -p "Enter Backup Name: " backup_name
    read -p "Delete Data From Target Table? (Y/N): " delete_data

    # generate view schema
    view_schema="${target_schema:0:4}vtbla"

    # generate create table and view queries
    {
        echo "-- Step1"
        awk -v source_schema="$source_schema" -v target_schema="$target_schema" -v backup_name="$backup_name" -v delete_data="$delete_data" '{
            print "create table " target_schema "." $0 "_" backup_name " as " source_schema "." $0 " with data;"
        }' "$DB_USER"/input/backup.txt
        echo -e "\n-- Step2"
        awk -v source_schema="$source_schema" -v target_schema="$target_schema" -v backup_name="$backup_name" -v view_schema="$view_schema" '{
            print "create view " view_schema "." $0 "_" backup_name " as locking " target_schema "." $0 "_" backup_name " for access select * from " target_schema "." $0 "_" backup_name ";"
        }' "$DB_USER"/input/backup.txt
    } > "$DB_USER"/output/backup_queries.sql

    if [ "$delete_data" == "Y" ] || [ "$delete_data" == "y" ]; then
        # Add delete queries to the backup_queries.sql file
        {
            echo -e "\n-- Step3"
            awk -v target_schema="$target_schema" -v backup_name="$backup_name" '{
                print "delete from " target_schema "." $0 ";"
            }' "$DB_USER"/input/backup.txt
        } >> "$DB_USER"/output/backup_queries.sql
    fi

    echo -e "\nBackup queries generation is successful. Please check $DB_USER/output/backup_queries.sql\n"
else
    echo -e "\nFile is empty. Please insert tables into $DB_USER/input/backup.txt\n"
fi