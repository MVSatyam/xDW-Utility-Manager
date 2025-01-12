#!/bin/bash

generate_query_to_get_date_field() {
    schema_name=$1
    tot_tables=$(cat $DB_USER/input/refreshed_tables.txt | wc -l)

    query_to_get_date_field=$(awk -v schema_name="$schema_name" -v tot_tables="$tot_tables" 'BEGIN {
        print "SELECT"
        print "  table_name,"
        print "  column_name"
        print "FROM"
        print schema_name ".MD_Column"
        print "WHERE"
        print "  column_name IN ("
        printf "    \x27%s\x27%s", "from_date", ","
        printf "    \x27%s\x27\n", "process_date"
        print ")"
        print "  AND table_name IN ("
    } {
        printf "    \x27%s\x27", $1
        if (NR < tot_tables) {
            print ","
        } else {
            print ""
        }
    } END {print ")"}' "$DB_USER"/input/refreshed_tables.txt)
    echo "$query_to_get_date_field"
}

generate_queries_and_execute() {
    schema_name=$1
    query_to_get_date_field=$2

    # create temporary files
    sql_file=$DB_USER/output/refresh_checker.sql
    tmp_output_file=$DB_USER/output/refresh_checker_output.txt
    log_file=$DB_USER/output/teradata_log.txt

    touch "$sql_file"
    touch "$tmp_output_file"

    bteq <<EOF &>> "$log_file"
    .LOGON $DB_HOST/$DB_USER,$DB_PASSWORD;
    .SET WIDTH 200;
    .SET TITLEDASHES OFF;
    .EXPORT FILE = $sql_file;
    SELECT 'select ''' || table_name || ''' as table_name, max(' || column_name || ') as max_date, min(' || column_name || ') as min_date, count(*) as no_of_records from ' || table_name || ';' as sql_query FROM ($query_to_get_date_field) t;
    .EXPORT RESET;
    .LOGOFF;
    .QUIT;
EOF
    if [ $? -eq 0 ]; then
        # remove the first line
        sed -i '1d' "$sql_file"

        bteq <<EOF &>> "$log_file"
        .LOGON $DB_HOST/$DB_USER,$DB_PASSWORD;
        .RUN FILE = $sql_file;
        .EXPORT FILE = $tmp_output_file;
        .LOGOFF;
        .QUIT;
EOF
        if [ $? -eq 0 ]; then
            # process the temp output file to get the table name, max date, min date and no of records
            temp_output_file_size=$(stat -c %s "$tmp_output_file")
            if [ "$temp_output_file_size" -eq 0 ]; then
                echo -e "\nNo records found for the given schema\n"
                # remove temporary files
                rm -f "$sql_file" "$tmp_output_file"
                exit 1
            fi
            cols=$(head -1 "$tmp_output_file")
            rows=$(grep -iv 'table_name' "$tmp_output_file")
            {
                echo "$cols"
                echo "------------------------------------------------------------------------------------"
                echo "$rows"
            } > "$DB_USER"/output/prod_refresh_dates.txt

            echo -e "\nOutput is saved in $DB_USER/output/prod_refresh_dates.txt\n"
            echo -e "\Note: Please check $log_file file for the tables if missed\n"
        else
            echo -e "\nError in executing queries. Please check $log_file for more details\n"
        fi
    else
        echo -e "\nError in generating queries to get dates. Please check $log_file for more details\n"
    fi

    # remove temporary files
    rm -f "$sql_file" "$tmp_output_file"
}

check_edw_refresh() {
    # get schema name
    read -p "Enter schema (ew{e}vtbla): " schema_name

    # schema name validation
    # schema should be ew{e}vtbla or EW{e}VTBLA where {e} is the environment code, non-case sensitive and should be t1, t2, t3, t4, t5, t6, t7, t8, t9, u1, u2, u3, u4, u5, u6, u7, u8, u9
    if [[ ! "$schema_name" =~ ^[eE][wW][tTuU][1-9][vV][tT][bB][lL][aA]$ ]]; then
        echo -e "\nInvalid schema name. Please enter schema name in the format ew{e}vtbla or EW{e}VTBLA where {e} is the environment code\n"
        exit 1
    fi

    query_to_get_date_field=$(generate_query_to_get_date_field "$schema_name")
    generate_queries_and_execute "$schema_name" "$query_to_get_date_field"
}

check_sgdw_refresh() {
    # get schema name
    read -p "Enter schema: " schema_name

    # schema name validation
    # schema should be dw{e}vtbla or DW{e}VTBLA where {e} is the environment code, non-case sensitive and should be t1, t2, t3, t4, t5, t6, t7, t8, t9, u1, u2, u3, u4, u5, u6, u7, u8, u9
    if [[ ! "$schema_name" =~ ^[dD][wW][tTuU][1-9][vV][tT][bB][lL][aA]$ ]]; then
        echo -e "\nInvalid schema name. Please enter schema name in the format dw{e}vtbla or DW{e}VTBLA where {e} is the environment code\n"
        exit 1
    fi

    query_to_get_date_field=$(generate_query_to_get_date_field "$schema_name")
    generate_queries_and_execute "$schema_name" "$query_to_get_date_field"
}

check_wgdw_refresh() {
    # get schema name
    read -p "Enter schema: " schema_name

    # schema name validation
    # schema should be wd{e}vtbla or WD{e}VTBLA where {e} is the environment code, non-case sensitive and should be t1, t2, t3, t4, t5, t6, t7, t8, t9, u1, u2, u3, u4, u5, u6, u7, u8, u9
    if [[ ! "$schema_name" =~ ^[wW][dD][tTuU][1-9][vV][tT][bB][lL][aA]$ ]]; then
        echo -e "\nInvalid schema name. Please enter schema name in the format wd{e}vtbla or WD{e}VTBLA where {e} is the environment code\n"
        exit 1
    fi

    query_to_get_date_field=$(generate_query_to_get_date_field "$schema_name")
    generate_queries_and_execute "$schema_name" "$query_to_get_date_field"
}

# check the file size
file_size=$(stat -c %s "$DB_USER"/input/refreshed_tables.txt)

if [ "$file_size" -gt 0 ]; then
    # get warehouse code
    read -p "Enter warehouse code (EW/DW/WD): " warehouse_code

    case $warehouse_code in
        EW | ew)
            check_edw_refresh
            ;;
        DW | dw)
            check_sgdw_refresh
            ;;
        WD | wd)
            check_wgdw_refresh
            ;;
        *)
            echo "Invalid warehouse code"
            ;;
    esac
else
    echo -e "\nFile is empty. Please ensure $DB_USER/input/refreshed_tables.txt file has tables before proceeding\n"
fi