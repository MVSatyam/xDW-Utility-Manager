#!/bin/bash

USER=$(whoami)
read -p "Enter your password: " -s PASSWORD
echo -e "\n"

echo "Welcome $USER"

# function setup environment variables
setup_env() {
    export DB_USER="$USER"
    export DB_PASSWORD="$PASSWORD"
    export DB_HOST="your_db_host"
}

# function to create necessary directories and files
initialize_directories_and_files() {
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
}

# function to display the main menu
display_menu() {
    echo "1. Stream Setup"
    echo "2. ERR Stream Setup"
    echo "3. Generate Backup Queries"
    echo "4. Generate Baseline Queries"
    echo "5. Check Environment Space"
    echo "6. Check Table Space"
    echo "7. Check Prod Refresh Request Status"
    echo "8. Check Prod Refresh Dates"
    echo "9. Convert Fixed Length to Delimited File"
    echo "99. Exit"
}

# function to handle the main selection
handle_selection() {
    case $1 in
        1)
            ./scripts/stream_setup.sh
            ;;
        2)
            ./scripts/err_stream_setup.sh
            ;;
        3)
            ./scripts/generate_backup_queries.sh
            ;;
        4)
            ./scripts/generate_baseline_queries.sh
            ;;
        5)
            ./scripts/check_environment_space.sh
            ;;
        6)
            ./scripts/check_table_space.sh
            ;;
        7)
            ./scripts/check_prod_refresh_request_status.sh
            ;;
        8)
            ./scripts/check_prod_refresh_dates.sh
            ;;
        9)
            file_size=$(stat -c %s "$DB_USER"/input/fixed_length_to_delimited.txt)

            if [ "$file_size" -gt 0 ]; then
                # read the input file and extract the values
                src_file=$(awk -F '=' '/src_file/ {print $2}' "$DB_USER"/input/fixed_length_to_delimited.txt | tr -d '"')
                tgt_file=$(awk -F '=' '/tgt_file/ {print $2}' "$DB_USER"/input/fixed_length_to_delimited.txt | tr -d '"')
                widths=$(awk -F '=' '/widths/ {print $2}' "$DB_USER"/input/fixed_length_to_delimited.txt | tr -d '"')

                # validate any of the above values are empty
                if [ -z "$src_file" ] || [ -z "$tgt_file" ] || [ -z "$widths" ]; then
                    echo -e "\nPlease provide values for src_file, tgt_file, and widths in the input file\n"
                fi

                sh ./scripts/convert_fixed_length_to_delimited_file.sh "$src_file" "$tgt_file" "$widths"

                if [ $? -eq 0 ]; then
                    echo
                    echo "File conversion is successful. Please check $tgt_file"
                    echo
                else
                    echo -e "\nFile conversion failed\n"
                fi
            else
                echo -e "\nFile is empty. Please insert values into $DB_USER/input/fixed_length_to_delimited.txt\n"
            fi
            ;;
        10)
            ./scripts/create_query_from_structure.sh
            ;;
        99)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice"
            ;;
    esac
}

# main function
main() {
    setup_env
    initialize_directories_and_files

    while true; do
        display_menu
        read -p "Enter your choice: " choice
        handle_selection "$choice"
    done
}

# execute the main function
main