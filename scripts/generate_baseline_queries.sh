#!/bin/bash

file_size=$(stat -c %s "$DB_USER"/input/baseline.csv)

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
        }' "$DB_USER"/input/baseline.csv
    } > "$DB_USER"/output/baseline_queries.sql

    echo -e "\nBaseline queries generation is successful. Please check $DB_USER/output/baseline_queries.sql\n"
else
    echo -e "\nFile is empty. Please insert values into $DB_USER/input/baseline.csv\n"
fi